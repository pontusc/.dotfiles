"""Grow and prune the session the user is currently in."""

from __future__ import annotations

import re
import shutil
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import archive
import compose
import config
import layout
import persist
import repo
import ticket
import tmux
import ui
import worktree
from errors import WorkspaceError


def _session_ticket(session: str, pattern: re.Pattern[str]) -> ticket.Ticket | None:
    key = tmux.session_option(session, "@ticket_key")
    slug = tmux.session_option(session, "@ticket_slug")
    if not slug and pattern.fullmatch(session):
        slug = ui.prompt_line(f"Slug for {session} ❯ ").strip()
        if slug:
            tmux.set_session_option(session, "@ticket_slug", slug)
    return ticket.from_session(session, key or None, slug or None, pattern)


def add_repo() -> None:
    session = tmux.current_session()
    if session is None:
        raise WorkspaceError("not inside a tmux session")
    workspace_config = config.load()
    work_root = workspace_config.settings.work_root
    discovered = repo.discover(work_root)
    present: set[str] = set()
    for window in tmux.session_windows(session):
        owner = repo.owner_of(window.path, work_root, discovered)
        if owner is not None:
            present.add(owner)
    available = compose.prioritized(
        [name for name in discovered if name not in present], workspace_config.repos
    )
    if not available:
        raise WorkspaceError("every discovered repo is already open in this session")
    choice = ui.pick(
        compose.repo_lines(available, workspace_config.repos), "Add repo ❯ "
    )
    if choice is None:
        return
    session_ticket = _session_ticket(session, workspace_config.settings.ticket_pattern)
    if session_ticket is None:
        raise WorkspaceError(f"session {session} has no branch to add a worktree on")
    agent_dir = compose.agent_dir_for(
        workspace_config.settings, session_ticket, session
    )
    specs, failures, warnings = compose.prepare_windows(
        [compose.row_name(choice)],
        workspace_config,
        session_ticket,
        session,
        per_window_agent=agent_dir is None,
    )
    if failures:
        raise WorkspaceError("\n".join(failures))
    result = compose.ensure_windows(session, specs, agent_dir)
    persist.save_state()
    if result.skipped or warnings:
        ui.notice("\n".join(result.skipped + warnings))


def _delete_branch(repo_root: Path, branch: str) -> str:
    error = worktree.delete_branch(repo_root, branch)
    if error and ui.confirm(f"{error}\ndelete {branch} anyway?"):
        error = worktree.delete_branch(repo_root, branch, force=True)
    if error:
        return f"branch {branch} kept ({error})"
    return f"deleted branch {branch}"


def _remove_ticket_root(ticket_root: Path) -> str:
    """Delete the ticket root once nothing but the tool's link and loose files remain.

    A directory is never deleted here, it may be a worktree whose window is
    already gone.
    """
    leftovers = [
        entry
        for entry in ticket_root.iterdir()
        if entry.name != layout.AGENT_CONFIG_LINK
    ]
    names = ", ".join(sorted(entry.name for entry in leftovers))
    if any(entry.is_dir() for entry in leftovers):
        return f"{ticket_root.name}: kept, {names} still present"
    if leftovers and not ui.confirm(f"{ticket_root.name}: delete {names}?"):
        return f"{ticket_root.name}: kept {names}"
    shutil.rmtree(ticket_root)
    return f"{ticket_root.name}: ticket directory removed"


def _archive_target(session: str, settings: config.Settings) -> tuple[str, Path] | None:
    """The ticket key and archive repo when this session's close is archived."""
    if settings.archive_root is None or settings.agent != "session":
        return None
    key = tmux.session_option(session, "@ticket_key") or session
    if not settings.ticket_pattern.fullmatch(key):
        return None
    if not worktree.ticket_dir(settings.work_root, session).is_dir():
        return None
    if not (settings.archive_root / ".git").exists():
        raise WorkspaceError(
            f"archive_root {settings.archive_root} is not a git repo, create it or"
            " unset it in workspaces.toml"
        )
    return key, settings.archive_root


def _start_archive(
    session: str,
    key: str,
    archive_root: Path,
    work_root: Path,
    planned: list[archive.Worktree],
    windows: list[str],
    blocked: bool,
) -> str | None:
    """Schedule the archive and close the windows, or say why not.

    None when the ticket root is empty, there is nothing to archive.
    """
    if blocked:
        return f"{key}: archive needs every worktree clean and known, nothing removed"
    ticket_root = worktree.ticket_dir(work_root, session)
    planned_paths = {entry.path for entry in planned}
    leftovers = [
        entry
        for entry in ticket_root.iterdir()
        if entry.name != layout.AGENT_CONFIG_LINK and str(entry) not in planned_paths
    ]
    if not planned and not leftovers:
        return None
    directories = sorted(entry.name for entry in leftovers if entry.is_dir())
    if directories:
        return f"{key}: {', '.join(directories)} is not a live worktree window, nothing removed"
    archive.schedule(
        archive.Plan(
            key=key,
            ticket_root=str(ticket_root),
            archive_root=str(archive_root),
            client=tmux.current_client(),
            loose_files=sorted(entry.name for entry in leftovers),
            worktrees=planned,
        )
    )
    for window_id in windows:
        tmux.kill_window(window_id)
    agent = tmux.find_window_by_name(session, layout.AGENT_WINDOW)
    if agent is not None and not agent.tagged:
        tmux.kill_window(agent.window_id)
    return f"{key}: archiving in the background"


def _status_of(
    window: tmux.SessionWindow, progress: ui.Progress
) -> tuple[str, worktree.Status | None]:
    progress.update(window.name, "checking status")
    status = worktree.status(window.path)
    if status is None:
        progress.finish(window.name, "git status failed", ok=False)
    elif status.changes:
        progress.finish(window.name, "uncommitted changes", ok=False)
    elif status.ignored:
        progress.finish(window.name, "ignored files only", ok=True)
    else:
        progress.finish(window.name, "clean", ok=True)
    return window.window_id, status


def _statuses(
    windows: list[tmux.SessionWindow], repo_roots: set[Path]
) -> dict[str, worktree.Status | None]:
    """Git status per worktree window, gathered concurrently under a progress block."""
    checkouts = [
        window
        for window in windows
        if window.path not in repo_roots and window.path.is_dir()
    ]
    if not checkouts:
        return {}
    names = [window.name for window in checkouts]
    with ui.Progress(names) as progress, ThreadPoolExecutor() as pool:
        return dict(pool.map(lambda window: _status_of(window, progress), checkouts))


def cleanup_session() -> None:
    session = tmux.current_session()
    if session is None:
        raise WorkspaceError("not inside a tmux session")
    workspace_config = config.load()
    work_root = workspace_config.settings.work_root
    discovered = repo.discover(work_root)
    repo_roots = {work_root / name for name in discovered}
    archive_target = _archive_target(session, workspace_config.settings)
    planned: list[archive.Worktree] = []
    planned_windows: list[str] = []
    removed: list[str] = []
    kept: list[str] = []
    # Only @worktree-tagged windows are the tool's to close. A hand-made
    # window that happens to sit in a repo is not.
    windows = [window for window in tmux.session_windows(session) if window.tagged]
    statuses = _statuses(windows, repo_roots)
    for window in windows:
        if window.path in repo_roots:
            if not ui.confirm(f"{window.name}: close repo root window?"):
                kept.append(f"{window.name}: declined, kept")
                continue
            tmux.kill_window(window.window_id)
            removed.append(f"{window.name}: repo root window closed")
            continue
        if not window.path.is_dir():
            kept.append(f"{window.name}: {window.path} not found, kept")
            continue
        owner = repo.owner_of(window.path, work_root, discovered)
        if owner is None:
            kept.append(f"{window.name}: no discovered repo owns {window.path}, kept")
            continue
        status = statuses.get(window.window_id)
        if status is None:
            kept.append(f"{owner}: git status failed, kept")
            continue
        if status.changes:
            kept.append(f"{owner}: uncommitted changes, kept")
            continue
        branch = worktree.branch_at(window.path)
        if archive_target is not None:
            planned.append(
                archive.Worktree(
                    repo=owner,
                    repo_root=str(work_root / owner),
                    path=str(window.path),
                    branch=None if branch == "HEAD" else branch,
                )
            )
            planned_windows.append(window.window_id)
            continue
        error = worktree.remove(work_root / owner, window.path)
        if error:
            kept.append(f"{owner}: {error}, kept")
            continue
        tmux.kill_window(window.window_id)
        result = "removed worktree"
        if branch and branch != "HEAD":
            result += f", {_delete_branch(work_root / owner, branch)}"
        removed.append(f"{owner}: {result}")
    outcome = None
    if archive_target is not None:
        blocked = any(
            window.tagged
            and window.path not in repo_roots
            and window.window_id not in planned_windows
            for window in tmux.session_windows(session)
        )
        outcome = _start_archive(
            session,
            *archive_target,
            work_root,
            planned,
            planned_windows,
            blocked,
        )
        if outcome is not None:
            removed.append(outcome)
    if outcome is None and not any(
        window.tagged for window in tmux.session_windows(session)
    ):
        # The session's single agent window has nothing to lose and goes with
        # the last worktree, whichever agent mode is configured now.
        agent = tmux.find_window_by_name(session, layout.AGENT_WINDOW)
        if agent is not None and not agent.tagged:
            tmux.kill_window(agent.window_id)
            removed.append(f"{agent.name}: agent window closed")
        ticket_root = worktree.ticket_dir(work_root, session)
        if workspace_config.settings.agent == "session" and ticket_root.is_dir():
            removed.append(_remove_ticket_root(ticket_root))
    persist.save_state()
    if removed or kept:
        ui.notice("\n".join(removed + kept))

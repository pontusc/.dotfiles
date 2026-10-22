"""Grow and prune the session the user is currently in."""

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

_CACHE_DIRS = ("__pycache__", ".ruff_cache")


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
    specs, failures, warnings = compose.prepare_windows(
        [compose.row_name(choice)], workspace_config, session_ticket, session
    )
    if failures:
        raise WorkspaceError("\n".join(failures))
    skipped = compose.ensure_windows(
        session, specs, worktree.ticket_dir(work_root, session)
    )
    persist.save_state()
    if skipped or warnings:
        ui.notice("\n".join(skipped + warnings))


def _delete_branch(repo_root: Path, branch: str) -> str:
    error = worktree.delete_branch(repo_root, branch)
    if error and ui.confirm(f"{error}\ndelete {branch} anyway?"):
        error = worktree.delete_branch(repo_root, branch, force=True)
    if error:
        return f"branch {branch} kept ({error})"
    return f"deleted branch {branch}"


def _remove_ticket_root(ticket_root: Path) -> str:
    """Delete the ticket root once nothing but the tool's link and loose files remain.

    A checkout is never deleted here, it may be a worktree whose window is
    already gone.
    """
    leftovers = [
        entry
        for entry in ticket_root.iterdir()
        if entry.name not in (layout.AGENT_CONFIG_LINK, *_CACHE_DIRS)
    ]
    names = ", ".join(sorted(entry.name for entry in leftovers))
    if any(worktree.is_checkout(entry) for entry in leftovers):
        return f"{ticket_root.name}: kept, {names} still present"
    if leftovers and not ui.confirm(f"{ticket_root.name}: delete {names}?"):
        return f"{ticket_root.name}: kept {names}"
    shutil.rmtree(ticket_root)
    return f"{ticket_root.name}: ticket directory removed"


def _archive_target(session: str, settings: config.Settings) -> tuple[str, Path] | None:
    """The ticket key and archive repo when this session's close is archived."""
    if settings.archive_root is None:
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
        if entry.name not in (layout.AGENT_CONFIG_LINK, *_CACHE_DIRS)
        and str(entry) not in planned_paths
    ]
    if not planned and not leftovers:
        return None
    checkouts = sorted(entry.name for entry in leftovers if worktree.is_checkout(entry))
    if checkouts:
        return f"{key}: {', '.join(checkouts)} is not a live worktree window, nothing removed"
    for name in _CACHE_DIRS:
        cache = ticket_root / name
        if cache.is_symlink():
            cache.unlink()
        elif cache.is_dir():
            shutil.rmtree(cache)
    moved = sorted(entry.name for entry in leftovers if entry.is_dir())
    if not leftovers and not any(
        worktree.has_work(Path(entry.repo_root), Path(entry.path), entry.branch)
        for entry in planned
    ):
        return _close_without_archive(session, key, ticket_root, planned, windows)
    _close_agent_window(session)
    job = archive.queue(key, ticket_root, archive_root, tmux.current_client(), planned)
    lines: list[str] = []
    for entry, window_id in zip(planned, windows, strict=True):
        error = worktree.remove(Path(entry.repo_root), Path(entry.path))
        if error:
            lines.append(f"{entry.repo}: {error}, worktree kept")
            continue
        tmux.kill_window(window_id)
    archive.schedule(job)
    if not any(
        entry.name != layout.AGENT_CONFIG_LINK for entry in ticket_root.iterdir()
    ):
        shutil.rmtree(ticket_root)
    if moved:
        lines.insert(0, f"{key}: moved {', '.join(moved)} into the archive notes")
    lines.insert(0, f"{key}: archiving {job.name} in the background")
    return "\n".join(lines)


def _close_agent_window(session: str) -> str | None:
    agent = tmux.find_window_by_name(session, layout.AGENT_WINDOW)
    if agent is None or agent.tagged:
        return None
    tmux.kill_window(agent.window_id)
    return f"{agent.name}: agent window closed"


def _close_without_archive(
    session: str,
    key: str,
    ticket_root: Path,
    planned: list[archive.Worktree],
    windows: list[str],
) -> str:
    lines = [f"{key}: nothing to archive"]
    for entry, window_id in zip(planned, windows, strict=True):
        error = worktree.remove(Path(entry.repo_root), Path(entry.path))
        if error:
            lines.append(f"{entry.repo}: {error}, kept")
            continue
        tmux.kill_window(window_id)
        result = "removed worktree"
        if entry.branch:
            result += f", {_delete_branch(Path(entry.repo_root), entry.branch)}"
        lines.append(f"{entry.repo}: {result}")
    _close_agent_window(session)
    lines.append(_remove_ticket_root(ticket_root))
    return "\n".join(lines)


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
                    head=worktree.head_at(window.path),
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
        closed = _close_agent_window(session)
        if closed is not None:
            removed.append(closed)
        ticket_root = worktree.ticket_dir(work_root, session)
        if ticket_root.is_dir():
            removed.append(_remove_ticket_root(ticket_root))
    persist.save_state()
    if removed or kept:
        ui.notice("\n".join(removed + kept))

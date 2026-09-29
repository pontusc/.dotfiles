"""Grow and prune the session the user is currently in."""

from __future__ import annotations

import re
import shutil
from pathlib import Path

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
    agent_dir = compose.agent_dir_for(
        workspace_config.settings, session_ticket, session
    )
    specs, failures, warnings = compose.prepare_windows(
        [compose.row_name(choice)],
        work_root,
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


def cleanup_session() -> None:
    session = tmux.current_session()
    if session is None:
        raise WorkspaceError("not inside a tmux session")
    workspace_config = config.load()
    work_root = workspace_config.settings.work_root
    discovered = repo.discover(work_root)
    repo_roots = {work_root / name for name in discovered}
    removed: list[str] = []
    kept: list[str] = []
    for window in tmux.session_windows(session):
        # Only @worktree-tagged windows are the tool's to close. A hand-made
        # window that happens to sit in a repo is not.
        if not window.tagged:
            continue
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
        status = worktree.status(window.path)
        if status is None:
            kept.append(f"{owner}: git status failed, kept")
            continue
        if status.changes:
            kept.append(f"{owner}: uncommitted changes, kept")
            continue
        if status.ignored and not ui.confirm(
            f"{owner}: only ignored files ({', '.join(status.ignored)})\nremove anyway?"
        ):
            kept.append(f"{owner}: declined, kept")
            continue
        branch = worktree.branch_at(window.path)
        error = worktree.remove(work_root / owner, window.path)
        if error:
            kept.append(f"{owner}: {error}, kept")
            continue
        tmux.kill_window(window.window_id)
        outcome = "removed worktree"
        if branch and branch != "HEAD":
            outcome += f", {_delete_branch(work_root / owner, branch)}"
        removed.append(f"{owner}: {outcome}")
    # The session's single agent window has nothing to lose and goes with the
    # last worktree, whichever agent mode is configured now.
    if not any(window.tagged for window in tmux.session_windows(session)):
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

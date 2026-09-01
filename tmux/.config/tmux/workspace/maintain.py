"""Grow and prune the session the user is currently in."""

from __future__ import annotations

import re

import compose
import config
import persist
import repo
import ticket
import tmux
import ui
import worktree
from errors import WorkspaceError


def _session_ticket(session: str, pattern: re.Pattern[str]) -> ticket.Ticket | None:
    slug = tmux.session_option(session, "@ticket_slug")
    if not slug and pattern.fullmatch(session):
        slug = ui.prompt_line(f"Slug for {session} ❯ ").strip()
        if slug:
            tmux.set_session_option(session, "@ticket_slug", slug)
    return ticket.from_session(session, slug or None, pattern)


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
    specs, failures = compose.prepare_windows(
        [compose.row_name(choice)], work_root, session_ticket, session
    )
    if failures:
        raise WorkspaceError("\n".join(failures))
    skipped = compose.ensure_windows(session, specs)
    persist.save_state()
    if skipped:
        ui.notice("\n".join(skipped))


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
        branch = worktree.branch_at(window.path) or "unknown"
        error = worktree.remove(work_root / owner, window.path)
        if error:
            kept.append(f"{owner}: {error}, kept")
            continue
        tmux.kill_window(window.window_id)
        removed.append(f"{owner}: removed worktree (branch {branch} kept)")
    persist.save_state()
    if removed or kept:
        ui.notice("\n".join(removed + kept))

"""Save and restore the workspace's tmux tags across server restarts.

tmux-resurrect brings sessions and windows back but drops every user option,
so the tags (@slot, @ticket_key, @ticket_slug, @worktree) are mirrored to a
state file on each resurrect save and reapplied by session and window name
after a restore.
"""

from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path
from typing import TypedDict

import tmux

_STATE_PATH = (
    Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state")
    / "tmux-workspace"
    / "state.json"
)

StoredWorktrees = list[tuple[str, str]] | dict[str, str]


class SessionState(TypedDict, total=False):
    slot: int
    ticket_key: str
    ticket_slug: str
    worktrees: StoredWorktrees


def _session_state(session: str) -> SessionState:
    entry: SessionState = {}
    slot = tmux.session_option(session, "@slot")
    if slot:
        entry["slot"] = int(slot)
    key = tmux.session_option(session, "@ticket_key")
    if key:
        entry["ticket_key"] = key
    slug = tmux.session_option(session, "@ticket_slug")
    if slug:
        entry["ticket_slug"] = slug
    worktrees = [
        (window.name, str(window.path))
        for window in tmux.session_windows(session)
        if window.tagged
    ]
    if worktrees:
        entry["worktrees"] = worktrees
    return entry


def save_state() -> None:
    state = {
        info.name: entry
        for info in tmux.list_sessions()
        if (entry := _session_state(info.name))
    }
    _STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    handle, temp_name = tempfile.mkstemp(dir=_STATE_PATH.parent, prefix="state-")
    with os.fdopen(handle, "w") as stream:
        json.dump(state, stream)
    os.replace(temp_name, _STATE_PATH)


def _quarantine() -> None:
    _STATE_PATH.replace(_STATE_PATH.with_name(f"{_STATE_PATH.name}.corrupt"))


def _load_state() -> dict[str, SessionState]:
    # Runs from a tmux hook, where an exception is invisible, so an unusable
    # file is moved aside instead of raised.
    try:
        state = json.loads(_STATE_PATH.read_text())
    except FileNotFoundError:
        return {}
    except json.JSONDecodeError:
        _quarantine()
        return {}
    if not isinstance(state, dict):
        _quarantine()
        return {}
    return state


def _worktree_pairs(stored: StoredWorktrees) -> list[tuple[str, str]]:
    # State files written before the list format hold a name -> path mapping,
    # which collapses windows sharing a name.
    if isinstance(stored, dict):
        return list(stored.items())
    return [(name, path) for name, path in stored]


def _restore_worktrees(session: str, stored: StoredWorktrees) -> None:
    """Reapply @worktree by window name, spending each saved path once."""
    pairs = _worktree_pairs(stored)
    for window in tmux.session_windows(session):
        match = next(
            (index for index, pair in enumerate(pairs) if pair[0] == window.name), None
        )
        if match is None:
            continue
        path = pairs.pop(match)[1]
        if not window.tagged:
            tmux.set_window_option(window.window_id, "@worktree", path)


def restore_state() -> None:
    """Reapply saved tags to live sessions, never overwriting a live tag."""
    state = _load_state()
    live = tmux.list_sessions()
    taken = {
        int(raw) for info in live if (raw := tmux.session_option(info.name, "@slot"))
    }
    for info in live:
        entry = state.get(info.name)
        if entry is None:
            continue
        slot = entry.get("slot")
        if (
            slot is not None
            and slot not in taken
            and not tmux.session_option(info.name, "@slot")
        ):
            taken.add(slot)
            tmux.set_session_option(info.name, "@slot", str(slot))
        key = entry.get("ticket_key")
        if key and not tmux.session_option(info.name, "@ticket_key"):
            tmux.set_session_option(info.name, "@ticket_key", key)
        slug = entry.get("ticket_slug")
        if slug and not tmux.session_option(info.name, "@ticket_slug"):
            tmux.set_session_option(info.name, "@ticket_slug", slug)
        _restore_worktrees(info.name, entry.get("worktrees", []))

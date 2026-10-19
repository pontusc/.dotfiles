"""Save and restore the workspace's tmux tags across server restarts.

tmux-resurrect brings sessions and windows back but drops every user option,
so the tags (@slot, @ticket_key, @ticket_slug, @worktree) are mirrored to a
state file on each resurrect save and reapplied by session and window name
after a restore.
"""

import json
import os
import tempfile
from pathlib import Path
from typing import TypedDict

import tmux

STATE_DIR = (
    Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state")
    / "tmux-workspace"
)
_STATE_PATH = STATE_DIR / "state.json"

StoredWorktrees = list[tuple[str, str]] | dict[str, str]


class SessionState(TypedDict, total=False):
    slot: int
    ticket_key: str
    ticket_slug: str
    worktrees: StoredWorktrees


def _session_state(
    info: tmux.SessionInfo, windows: list[tmux.SessionWindow]
) -> SessionState:
    entry: SessionState = {}
    if info.slot is not None:
        entry["slot"] = info.slot
    if info.ticket_key:
        entry["ticket_key"] = info.ticket_key
    if info.ticket_slug:
        entry["ticket_slug"] = info.ticket_slug
    worktrees = [(window.name, str(window.path)) for window in windows if window.tagged]
    if worktrees:
        entry["worktrees"] = worktrees
    return entry


def save_state() -> None:
    snapshot = tmux.snapshot()
    state = {
        info.name: entry
        for info in snapshot.sessions
        if (entry := _session_state(info, snapshot.windows[info.name]))
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


def _worktree_updates(
    windows: list[tmux.SessionWindow], stored: StoredWorktrees
) -> list[tmux.WindowOptionUpdate]:
    """Reapply @worktree by window name, spending each saved path once."""
    pairs = _worktree_pairs(stored)
    updates: list[tmux.WindowOptionUpdate] = []
    for window in windows:
        match = next(
            (index for index, pair in enumerate(pairs) if pair[0] == window.name), None
        )
        if match is None:
            continue
        path = pairs.pop(match)[1]
        if not window.tagged:
            updates.append(tmux.WindowOptionUpdate(window.window_id, "@worktree", path))
    return updates


def restore_state() -> None:
    """Reapply saved tags to live sessions, never overwriting a live tag."""
    state = _load_state()
    snapshot = tmux.snapshot()
    taken = {info.slot for info in snapshot.sessions if info.slot is not None}
    updates: list[tmux.SessionOptionUpdate | tmux.WindowOptionUpdate] = []
    for info in snapshot.sessions:
        entry = state.get(info.name)
        if entry is None:
            continue
        slot = entry.get("slot")
        if slot is not None and slot not in taken and info.slot is None:
            taken.add(slot)
            updates.append(tmux.SessionOptionUpdate(info.name, "@slot", str(slot)))
        key = entry.get("ticket_key")
        if key and not info.ticket_key:
            updates.append(tmux.SessionOptionUpdate(info.name, "@ticket_key", key))
        slug = entry.get("ticket_slug")
        if slug and not info.ticket_slug:
            updates.append(tmux.SessionOptionUpdate(info.name, "@ticket_slug", slug))
        updates += _worktree_updates(
            snapshot.windows[info.name], entry.get("worktrees", [])
        )
    tmux.set_options(updates)

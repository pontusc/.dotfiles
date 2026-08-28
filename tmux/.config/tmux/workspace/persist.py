"""Save and restore the workspace's tmux tags across server restarts.

tmux-resurrect brings sessions and windows back but drops every user option,
so the tags (@slot, @ticket_slug, @worktree) are mirrored to a state file on
each resurrect save and reapplied by session and window name after a restore.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import TypedDict

import tmux

_STATE_PATH = (
    Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
    / "tmux-workspace"
    / "state.json"
)


class SessionState(TypedDict, total=False):
    slot: int
    ticket_slug: str
    worktrees: dict[str, str]


def _session_state(session: str) -> SessionState:
    entry: SessionState = {}
    slot = tmux.session_option(session, "@slot")
    if slot:
        entry["slot"] = int(slot)
    slug = tmux.session_option(session, "@ticket_slug")
    if slug:
        entry["ticket_slug"] = slug
    worktrees = {
        window.name: str(window.path)
        for window in tmux.session_windows(session)
        if window.tagged
    }
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
    _STATE_PATH.write_text(json.dumps(state))


def restore_state() -> None:
    """Reapply saved tags to live sessions, never overwriting a live tag."""
    try:
        state: dict[str, SessionState] = json.loads(_STATE_PATH.read_text())
    except FileNotFoundError:
        return
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
        slug = entry.get("ticket_slug")
        if slug and not tmux.session_option(info.name, "@ticket_slug"):
            tmux.set_session_option(info.name, "@ticket_slug", slug)
        worktrees = entry.get("worktrees", {})
        for window in tmux.session_windows(info.name):
            path = worktrees.get(window.name)
            if path and not window.tagged:
                tmux.set_window_option(window.window_id, "@worktree", path)

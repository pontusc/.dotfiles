"""The window layout the tool works in and the programs it starts there."""

from __future__ import annotations

import shlex
from pathlib import Path

import tmux


def arrange(window_id: str, cwd: Path, claude_session: str) -> None:
    """Split into nvim top-left, terminal bottom-left, claude right."""
    tmux.split_window(window_id, cwd, horizontal=True, size="34%")
    tmux.select_pane(window_id, "left")
    tmux.split_window(window_id, cwd, horizontal=False, size="30%")
    tmux.select_pane(window_id, "up")
    tmux.send_keys(window_id, "nvim")
    tmux.select_pane(window_id, "right")
    tmux.send_keys(window_id, f"claude -n {shlex.quote(claude_session)}")
    tmux.select_pane(window_id, "left")
    tmux.select_pane(window_id, "up")

"""The window layout the tool works in and the programs it starts there."""

from __future__ import annotations

import shlex
from pathlib import Path

import tmux


def arrange(
    window_id: str, cwd: Path, claude_session: str, extra_dir: Path | None = None
) -> None:
    """Split into nvim top-left, terminal bottom-left, claude right."""
    tmux.split_window(window_id, cwd, horizontal=True, size="34%")
    tmux.select_pane(window_id, "left")
    tmux.split_window(window_id, cwd, horizontal=False, size="30%")
    tmux.select_pane(window_id, "up")
    tmux.send_keys(window_id, "nvim")
    tmux.select_pane(window_id, "right")
    claude_args = ["claude", "--model", "opus", "-n", claude_session]
    if extra_dir is not None:
        # --add-dir is variadic in the claude CLI, so it must stay last.
        claude_args += ["--add-dir", str(extra_dir)]
    tmux.send_keys(window_id, shlex.join(claude_args))
    tmux.select_pane(window_id, "left")
    tmux.select_pane(window_id, "up")

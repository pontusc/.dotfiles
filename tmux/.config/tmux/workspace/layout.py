"""The window layouts the tool works in and the programs it starts there."""

from __future__ import annotations

import shlex
from collections.abc import Sequence
from pathlib import Path

import tmux
from errors import WorkspaceError

AGENT_WINDOW = "agent"


def claude_command(session_name: str, extra_dir: Path | None = None) -> list[str]:
    args = ["claude", "--model", "opus", "-n", session_name]
    if extra_dir is not None:
        # --add-dir is variadic in the claude CLI, so it must stay last.
        args += ["--add-dir", str(extra_dir)]
    return args


def arrange(window_id: str, cwd: Path, agent: Sequence[str] | None) -> None:
    """Three panes: nvim top-left, a terminal below it, the agent on the right.

    Without an agent the window is the two-pane side layout with nvim on the left.
    """
    if agent is None:
        arrange_side(window_id, cwd, "nvim")
        return
    tmux.split_window(window_id, cwd, horizontal=True, size="34%")
    tmux.select_pane(window_id, "left")
    tmux.split_window(window_id, cwd, horizontal=False, size="30%")
    tmux.select_pane(window_id, "up")
    tmux.send_keys(window_id, "nvim")
    tmux.select_pane(window_id, "right")
    tmux.send_keys(window_id, shlex.join(agent))
    tmux.select_pane(window_id, "left")
    tmux.select_pane(window_id, "up")


def arrange_side(window_id: str, cwd: Path, command: str) -> None:
    """Two panes: the command on the left, a terminal taking 40 percent on the right."""
    tmux.split_window(window_id, cwd, horizontal=True, size="40%")
    tmux.select_pane(window_id, "left")
    tmux.send_keys(window_id, command)


def start_agent(window_id: str, session: str, cwd: Path) -> None:
    """The session's single agent beside a terminal, in the ticket directory."""
    arrange_side(window_id, cwd, shlex.join(claude_command(session)))


def arrange_current_window() -> None:
    """Apply the dev layout to the current window; it must hold a single pane."""
    window = tmux.current_window()
    if window.panes != 1:
        raise WorkspaceError("dev layout needs a single pane")
    arrange(
        window.window_id,
        window.cwd,
        claude_command(f"{window.session}-{window.cwd.name}"),
    )

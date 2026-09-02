"""tmux session, window and pane plumbing."""

from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Literal, NamedTuple

from errors import WorkspaceError

PaneDirection = Literal["left", "right", "up", "down"]

_PANE_FLAGS: dict[PaneDirection, str] = {
    "left": "-L",
    "right": "-R",
    "up": "-U",
    "down": "-D",
}

_FORBIDDEN_NAME_CHARS = (".", ":")


class WindowRef(NamedTuple):
    window_id: str
    session: str


class SessionWindow(NamedTuple):
    window_id: str
    name: str
    path: Path
    tagged: bool


class SessionInfo(NamedTuple):
    name: str
    created: int


def _session_target(session: str) -> str:
    # "=" is exact-match (a bare name matches by prefix) and the trailing colon
    # is required: without it tmux reads the first "." in the name as the pane
    # separator, so a session called api.example.com never resolves.
    return f"={session}:"


def _run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["tmux", *args], capture_output=True, text=True, check=False)


def _failure(command: str, result: subprocess.CompletedProcess[str]) -> WorkspaceError:
    return WorkspaceError(
        f"tmux {command}: {result.stderr.strip() or f'exited {result.returncode}'}"
    )


def _output(*args: str) -> str:
    return _run(*args).stdout.strip()


def _lines(*args: str) -> list[str]:
    # Unlike _output this must not strip: a trailing field that is empty on the
    # last row would lose its separator and shift the split.
    return _run(*args).stdout.splitlines()


def _output_checked(*args: str) -> str:
    # An empty id would be passed on as "-t ''", which tmux resolves to the
    # current window, so the caller would split and type into the user's pane.
    result = _run(*args)
    value = result.stdout.strip()
    if result.returncode != 0 or not value:
        raise _failure(args[0], result)
    return value


def _run_checked(*args: str) -> None:
    result = _run(*args)
    if result.returncode != 0:
        raise _failure(args[0], result)


def _client_size_args() -> list[str]:
    # A detached session defaults to 80x24, so panes split now would rescale
    # badly on attach. Size it to the client that is about to switch to it.
    size = _output("display-message", "-p", "#{client_width}\t#{client_height}")
    if "\t" not in size:
        return []
    width, height = size.split("\t", 1)
    if not width or not height:
        return []
    return ["-x", width, "-y", height]


def validate_session_name(name: str) -> None:
    """Reject a name tmux will not carry: it reads "." and ":" as target separators."""
    if not name:
        raise WorkspaceError("session name is empty")
    if any(char in name for char in _FORBIDDEN_NAME_CHARS):
        forbidden = " and ".join(f"'{char}'" for char in _FORBIDDEN_NAME_CHARS)
        raise WorkspaceError(
            f"'{name}' cannot be a session name: tmux forbids {forbidden}"
        )


def session_exists(name: str) -> bool:
    return _run("has-session", "-t", _session_target(name)).returncode == 0


def list_session_names() -> list[str]:
    return [line for line in _lines("list-sessions", "-F", "#{session_name}") if line]


def list_sessions() -> list[SessionInfo]:
    # session_created is always numeric; session_name may hold anything but a
    # tab, so it goes last.
    output = _lines("list-sessions", "-F", "#{session_created}\t#{session_name}")
    sessions: list[SessionInfo] = []
    for line in output:
        if not line:
            continue
        created, name = line.split("\t", 1)
        sessions.append(SessionInfo(name=name, created=int(created)))
    return sessions


def session_worktrees(session: str) -> list[Path]:
    tagged = _lines(
        "list-windows", "-t", _session_target(session), "-F", "#{@worktree}"
    )
    return [Path(line) for line in tagged if line]


def find_window_by_worktree(path: Path) -> WindowRef | None:
    # Compared here rather than with a tmux format filter, which mis-parses a
    # path holding "," (matches nothing) or "}" (matches everything).
    listing = _lines(
        "list-windows",
        "-a",
        "-F",
        "#{window_id}\t#{session_name}\t#{@worktree}",
    )
    for line in listing:
        window_id, session, tagged = line.split("\t", 2)
        if tagged == str(path):
            return WindowRef(window_id=window_id, session=session)
    return None


def start_session(name: str, window_name: str, cwd: Path) -> str:
    """Create a detached session with one window, returning its window id."""
    return _output_checked(
        "new-session",
        "-d",
        *_client_size_args(),
        "-s",
        name,
        "-n",
        window_name,
        "-c",
        str(cwd),
        "-P",
        "-F",
        "#{window_id}",
    )


def start_empty_session(name: str) -> None:
    _run_checked("new-session", "-d", *_client_size_args(), "-s", name)


def new_window(session: str, name: str, cwd: Path) -> str:
    """Add a window to an existing session, returning its window id."""
    return _output_checked(
        "new-window",
        "-t",
        _session_target(session),
        "-n",
        name,
        "-c",
        str(cwd),
        "-P",
        "-F",
        "#{window_id}",
    )


def focus_session(session: str) -> None:
    _run("switch-client", "-t", _session_target(session))


def current_session() -> str | None:
    result = _run("display-message", "-p", "#S")
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def session_option(session: str, option: str) -> str:
    return _output("show-option", "-qv", "-t", _session_target(session), option)


def set_session_option(session: str, option: str, value: str) -> None:
    _run_checked("set-option", "-t", _session_target(session), option, value)


def set_window_option(window_id: str, option: str, value: str) -> None:
    _run_checked("set-option", "-w", "-t", window_id, option, value)


def flagged_sessions() -> dict[str, str]:
    """Session name to @claude flag ("ask" or "done"); "ask" outranks "done" for a session with both."""
    output = _lines("list-windows", "-a", "-F", "#{session_name}\t#{@claude}")
    flags: dict[str, str] = {}
    for line in output:
        if "\t" not in line:
            continue
        session, flag = line.split("\t", 1)
        if not flag:
            continue
        if flag == "ask" or session not in flags:
            flags[session] = flag
    return flags


def session_windows(session: str) -> list[SessionWindow]:
    # window_name is renameable and may contain tabs, so it goes last.
    output = _lines(
        "list-windows",
        "-t",
        _session_target(session),
        "-F",
        "#{window_id}\t#{@worktree}\t#{pane_current_path}\t#{window_name}",
    )
    windows: list[SessionWindow] = []
    for line in output:
        window_id, tagged, pane_path, name = line.split("\t", 3)
        windows.append(
            SessionWindow(
                window_id=window_id,
                name=name,
                path=Path(tagged or pane_path),
                tagged=bool(tagged),
            )
        )
    return windows


def kill_window(window_id: str) -> None:
    _run("kill-window", "-t", window_id)


def split_window(window_id: str, cwd: Path, *, horizontal: bool, size: str) -> None:
    _run(
        "split-window",
        "-t",
        window_id,
        "-h" if horizontal else "-v",
        "-l",
        size,
        "-c",
        str(cwd),
    )


def select_pane(window_id: str, direction: PaneDirection) -> None:
    _run("select-pane", "-t", window_id, _PANE_FLAGS[direction])


def send_keys(window_id: str, command: str) -> None:
    _run("send-keys", "-t", window_id, command, "Enter")

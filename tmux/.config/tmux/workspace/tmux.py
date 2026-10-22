"""tmux session, window and pane plumbing."""

import subprocess
from collections.abc import Sequence
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

_BATCH_SEPARATOR = "\x1f"

# The free-text field goes last, it may hold anything but a tab.
_SESSION_FORMAT = (
    "#{session_id}\t#{session_created}\t#{@slot}\t#{@ticket_key}\t#{@ticket_slug}"
    "\t#{session_name}"
)
_WINDOW_FORMAT = (
    "#{window_id}\t#{@claude}\t#{@worktree}\t#{pane_current_path}\t#{window_name}"
)


class WindowRef(NamedTuple):
    window_id: str
    session: str


class SessionWindow(NamedTuple):
    window_id: str
    name: str
    path: Path
    tagged: bool
    claude_flag: str


class SessionInfo(NamedTuple):
    session_id: str
    name: str
    created: int
    slot: int | None
    ticket_key: str
    ticket_slug: str


class Snapshot(NamedTuple):
    current: str
    sessions: list[SessionInfo]
    windows: dict[str, list[SessionWindow]]


class SessionOptionUpdate(NamedTuple):
    session: str
    option: str
    value: str


class WindowOptionUpdate(NamedTuple):
    window_id: str
    option: str
    value: str


class CurrentWindow(NamedTuple):
    window_id: str
    panes: int
    cwd: Path
    session: str


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


def _lines_checked(*args: str) -> list[str]:
    # Unlike _lines this must not swallow a nonzero return code: an empty list
    # from a failed query would otherwise read as "no sessions" instead of
    # "couldn't ask".
    result = _run(*args)
    if result.returncode != 0:
        raise _failure(args[0], result)
    return result.stdout.splitlines()


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


def _batch(*commands: Sequence[str]) -> list[list[str]]:
    """Run the commands over one tmux connection, returning each one's output lines.

    tmux stops at the first failing command, so any failure fails the batch.
    """
    if not commands:
        raise ValueError("tmux batch needs at least one command")
    args: list[str] = []
    for command in commands:
        if args:
            args += [";", "display-message", "-p", _BATCH_SEPARATOR, ";"]
        args += command
    result = _run(*args)
    if result.returncode != 0:
        raise _failure("/".join(command[0] for command in commands), result)
    outputs: list[list[str]] = [[]]
    for line in result.stdout.splitlines():
        if line == _BATCH_SEPARATOR:
            outputs.append([])
        else:
            outputs[-1].append(line)
    return outputs


def _parse_session(line: str) -> SessionInfo:
    session_id, created, slot, ticket_key, ticket_slug, name = line.split("\t", 5)
    return SessionInfo(
        session_id=session_id,
        name=name,
        created=int(created),
        slot=int(slot) if slot else None,
        ticket_key=ticket_key,
        ticket_slug=ticket_slug,
    )


def _parse_window(line: str) -> SessionWindow:
    window_id, claude_flag, tagged, pane_path, name = line.split("\t", 4)
    return SessionWindow(
        window_id=window_id,
        name=name,
        path=Path(tagged or pane_path),
        tagged=bool(tagged),
        claude_flag=claude_flag,
    )


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


def snapshot() -> Snapshot:
    """Current session, every session and every window, read in one tmux call."""
    current, session_lines, window_lines = _batch(
        ["display-message", "-p", "#S"],
        ["list-sessions", "-F", _SESSION_FORMAT],
        ["list-windows", "-a", "-F", f"#{{session_id}}\t{_WINDOW_FORMAT}"],
    )
    sessions = [_parse_session(line) for line in session_lines if line]
    names = {session.session_id: session.name for session in sessions}
    windows: dict[str, list[SessionWindow]] = {session.name: [] for session in sessions}
    for line in window_lines:
        session_id, window = line.split("\t", 1)
        windows[names[session_id]].append(_parse_window(window))
    return Snapshot(
        current=current[0] if current else "", sessions=sessions, windows=windows
    )


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


def current_client() -> str:
    return _output("display-message", "-p", "#{client_tty}")


def message(client: str, text: str) -> None:
    """Show text on a client named by tty, the caller has no pane of its own."""
    if client:
        _run("display-message", "-c", client, "-d", "15000", text)


def current_window() -> CurrentWindow:
    """The client's active window: id, pane count, pane cwd and session name."""
    window_id, panes, cwd, session = _output_checked(
        "display-message",
        "-p",
        "#{window_id}\t#{window_panes}\t#{pane_current_path}\t#{session_name}",
    ).split("\t", 3)
    return CurrentWindow(
        window_id=window_id, panes=int(panes), cwd=Path(cwd), session=session
    )


def session_option(session: str, option: str) -> str:
    return _output("show-option", "-qv", "-t", _session_target(session), option)


def set_session_option(session: str, option: str, value: str) -> None:
    _run_checked("set-option", "-t", _session_target(session), option, value)


def set_window_option(window_id: str, option: str, value: str) -> None:
    _run_checked("set-option", "-w", "-t", window_id, option, value)


def set_options(updates: Sequence[SessionOptionUpdate | WindowOptionUpdate]) -> None:
    commands = [
        ["set-option", "-w", "-t", update.window_id, update.option, update.value]
        if isinstance(update, WindowOptionUpdate)
        else [
            "set-option",
            "-t",
            _session_target(update.session),
            update.option,
            update.value,
        ]
        for update in updates
    ]
    if commands:
        _batch(*commands)


def session_windows(session: str) -> list[SessionWindow]:
    output = _lines(
        "list-windows", "-t", _session_target(session), "-F", _WINDOW_FORMAT
    )
    return [_parse_window(line) for line in output]


def find_window_by_name(session: str, name: str) -> SessionWindow | None:
    for window in session_windows(session):
        if window.name == name:
            return window
    return None


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

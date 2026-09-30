"""Interactive prompts, the fzf picker, and the popup-safe failure path."""

from __future__ import annotations

import codecs
import os
import select
import shutil
import subprocess
import sys
import termios
import threading
import time
import tty
from collections.abc import Sequence
from types import TracebackType
from typing import NoReturn, Self

from errors import Cancelled, WorkspaceError

# Terminal-default background and gutter, so fzf paints no opaque cells and
# the popup keeps the terminal's translucency.
_FZF_STYLE = ("--color=bg:-1,gutter:-1",)
_SPINNER = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
_FRAME_SECONDS = 0.1


class Progress:
    """One line per item, redrawn in place while the items run concurrently.

    Without a tty each state change prints as its own line instead.
    """

    def __init__(self, names: Sequence[str]) -> None:
        self._names = list(names)
        self._states = dict.fromkeys(self._names, "")
        self._finished: dict[str, tuple[bool, float]] = {}
        self._started = time.monotonic()
        self._lock = threading.Lock()
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._live = sys.stdout.isatty()
        self._drawn = 0
        self._width = max((len(name) for name in self._names), default=0)

    def update(self, name: str, state: str) -> None:
        with self._lock:
            self._states[name] = state.splitlines()[0] if state else ""
        if not self._live:
            print(f"{name}: {state}", flush=True)

    def finish(self, name: str, state: str, *, ok: bool) -> None:
        self.update(name, state)
        with self._lock:
            self._finished[name] = (ok, time.monotonic() - self._started)

    def __enter__(self) -> Self:
        if self._live:
            self._thread.start()
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc: BaseException | None,
        traceback: TracebackType | None,
    ) -> None:
        if not self._live:
            return
        self._stop.set()
        self._thread.join()
        self._render(0)

    def _loop(self) -> None:
        frame = 0
        while not self._stop.is_set():
            self._render(frame)
            frame += 1
            self._stop.wait(_FRAME_SECONDS)

    def _render(self, frame: int) -> None:
        columns = shutil.get_terminal_size().columns
        now = time.monotonic()
        with self._lock:
            lines = []
            for name in self._names:
                finished = self._finished.get(name)
                if finished is None:
                    mark = _SPINNER[frame % len(_SPINNER)]
                    elapsed = now - self._started
                else:
                    mark = "✔" if finished[0] else "✘"
                    elapsed = finished[1]
                line = f" {mark} {name:<{self._width}}  {self._states[name]}"
                clock = f"{elapsed:.1f}s"
                padding = columns - len(line) - len(clock) - 1
                if padding < 1:
                    line = line[: columns - len(clock) - 2]
                    padding = 1
                lines.append(line + " " * padding + clock)
        out = f"\x1b[{self._drawn}A" if self._drawn else ""
        out += "".join(f"\r\x1b[K{line}\n" for line in lines)
        sys.stdout.write(out)
        sys.stdout.flush()
        self._drawn = len(lines)


def _wait_for_keypress() -> None:
    # Runs inside a tmux display-popup that closes on exit, so callers hold
    # their message with this before exiting.
    if not sys.stdin.isatty():
        return
    descriptor = sys.stdin.fileno()
    saved = termios.tcgetattr(descriptor)
    try:
        tty.setraw(descriptor)
        os.read(descriptor, 1)
    finally:
        termios.tcsetattr(descriptor, termios.TCSADRAIN, saved)


def fail(message: str) -> NoReturn:
    print(message, file=sys.stderr)
    print("press any key to close", file=sys.stderr)
    _wait_for_keypress()
    raise SystemExit(1)


def notice(message: str) -> None:
    print(message)
    print("press any key to close")
    _wait_for_keypress()


def confirm(question: str) -> bool:
    """True only on an explicit yes: empty input and Escape both decline."""
    try:
        answer = prompt_line(f"{question} [y/N] ")
    except Cancelled:
        return False
    return answer.strip().lower() in ("y", "yes")


def _run_fzf(options: Sequence[str], *args: str) -> list[str]:
    result = subprocess.run(
        ["fzf", *_FZF_STYLE, *args],
        input="\n".join(options),
        capture_output=True,
        text=True,
        check=False,
    )
    # 1 is "no match", 130 is an abort: both mean the user picked nothing.
    if result.returncode in (1, 130):
        return []
    if result.returncode != 0:
        raise WorkspaceError(f"fzf exited {result.returncode}: {result.stderr.strip()}")
    return [line for line in result.stdout.splitlines() if line]


def pick(
    options: Sequence[str],
    prompt: str,
    binds: Sequence[str] = (),
    delimiter: str | None = None,
) -> str | None:
    """delimiter splits each option into a hidden return value and the text fzf displays."""
    args = ["--prompt", prompt]
    for bind in binds:
        args += ["--bind", bind]
    if delimiter is not None:
        args += ["--delimiter", delimiter, "--with-nth", "2.."]
    selected = _run_fzf(options, *args)
    return selected[0] if selected else None


_PICK_PROMPT = "Branch ❯ "
_NEW_PROMPT = "New branch ❯ "


def pick_or_new(options: Sequence[str]) -> str | None:
    """The typed query once something is typed, the hovered row once the cursor
    moved or nothing is typed. None when cancelled.

    The prompt names the mode, and the enter binding reads it back, since fzf
    keeps no other state across key presses. Rows may carry a description after
    a tab, only the first column is returned.
    """
    moved = f"change-prompt({_PICK_PROMPT})"
    typed = (
        f'transform:[ -n "$FZF_QUERY" ] && echo "change-prompt({_NEW_PROMPT})"'
        f' || echo "change-prompt({_PICK_PROMPT})"'
    )
    enter = (
        f'transform:case "$FZF_PROMPT" in "{_NEW_PROMPT}") echo print-query;;'
        " *) echo accept;; esac"
    )
    result = subprocess.run(
        [
            "fzf",
            *_FZF_STYLE,
            "--print-query",
            "--delimiter",
            "\t",
            "--nth",
            "1",
            "--bind",
            f"change:{typed}",
            "--bind",
            f"enter:{enter}",
            "--bind",
            ",".join(
                f"{key}:{action}+{moved}"
                for key, action in (
                    ("up", "up"),
                    ("down", "down"),
                    ("ctrl-p", "up"),
                    ("ctrl-n", "down"),
                    ("ctrl-k", "up"),
                    ("ctrl-j", "down"),
                )
            ),
            "--prompt",
            _PICK_PROMPT,
        ],
        input="\n".join(options),
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode == 130:
        return None
    if result.returncode not in (0, 1):
        raise WorkspaceError(f"fzf exited {result.returncode}: {result.stderr.strip()}")
    lines = result.stdout.splitlines()
    # accept prints the query and the row, print-query and accept without a
    # match print only the query.
    if len(lines) > 1 and lines[-1]:
        return lines[-1].split("\t")[0]
    return lines[0].strip() or None if lines else None


def pick_multi(options: Sequence[str], prompt: str) -> list[str]:
    return _run_fzf(
        options,
        "--multi",
        "--bind",
        "space:toggle,enter:select+accept",
        "--prompt",
        prompt,
    )


def _drain_escape_sequence(descriptor: int) -> bool:
    # A lone ESC byte is the Escape key. More bytes right behind it are an
    # arrow or function key sequence, swallowed so they don't land in the input.
    if not select.select([descriptor], [], [], 0.05)[0]:
        return False
    while select.select([descriptor], [], [], 0.01)[0]:
        os.read(descriptor, 1)
    return True


def prompt_line(prompt: str) -> str:
    """Read a line, raising Cancelled on Escape."""
    if not sys.stdin.isatty():
        return input(prompt)
    print(prompt, end="", flush=True)
    descriptor = sys.stdin.fileno()
    saved = termios.tcgetattr(descriptor)
    # Read the raw fd: a buffered read would swallow the whole arrow-key
    # sequence in one syscall, leaving nothing for the escape drain to see.
    decoder = codecs.getincrementaldecoder("utf-8")()
    entered: list[str] = []
    try:
        # setcbreak leaves ISIG on, so ctrl-c arrives as SIGINT, never as a byte.
        tty.setcbreak(descriptor)
        while True:
            byte = os.read(descriptor, 1)
            if not byte:
                print()
                raise EOFError
            if byte == b"\x1b":
                if _drain_escape_sequence(descriptor):
                    continue
                print()
                raise Cancelled
            if byte in (b"\r", b"\n"):
                print()
                return "".join(entered)
            if byte == b"\x04" and not entered:
                print()
                raise EOFError
            if byte in (b"\x7f", b"\x08"):
                if entered:
                    entered.pop()
                    print("\b \b", end="", flush=True)
                continue
            char = decoder.decode(byte)
            if char and char.isprintable():
                entered.append(char)
                print(char, end="", flush=True)
    finally:
        termios.tcsetattr(descriptor, termios.TCSADRAIN, saved)

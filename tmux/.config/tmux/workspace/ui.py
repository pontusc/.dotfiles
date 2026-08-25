"""Interactive prompts, the fzf picker, and the popup-safe failure path."""

from __future__ import annotations

import codecs
import os
import select
import subprocess
import sys
import termios
import tty
from collections.abc import Sequence
from typing import NoReturn

from errors import Cancelled, WorkspaceError

# Terminal-default background and gutter, so fzf paints no opaque cells and
# the popup keeps the terminal's translucency.
_FZF_STYLE = ("--color=bg:-1,gutter:-1",)


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


def pick(options: Sequence[str], prompt: str, binds: Sequence[str] = ()) -> str | None:
    args = ["--prompt", prompt]
    for bind in binds:
        args += ["--bind", bind]
    selected = _run_fzf(options, *args)
    return selected[0] if selected else None


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

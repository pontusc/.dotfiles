#!/usr/bin/env python3
"""Continue the claude conversation of a ticket root or one of its worktrees."""

import os
from pathlib import Path

import layout


def main() -> None:
    cwd = Path.cwd()
    if layout.is_ticket_root(cwd):
        args = layout.claude_command(cwd.name, ticket_plugin=True, resume=True)
    elif layout.is_ticket_root(cwd.parent):
        args = layout.claude_command(
            f"{cwd.parent.name}-{cwd.name}", cwd.parent, resume=True
        )
    else:
        raise SystemExit("resume: run from a ticket root or one of its worktrees")
    os.execvp(args[0], args)


if __name__ == "__main__":
    main()

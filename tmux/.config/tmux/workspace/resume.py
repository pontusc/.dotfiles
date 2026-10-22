#!/usr/bin/env python3
"""Continue the claude conversation of a ticket root."""

import os
from pathlib import Path

import layout


def main() -> None:
    cwd = Path.cwd()
    if not layout.is_ticket_root(cwd):
        raise SystemExit("resume: run from a ticket root")
    args = layout.claude_command(cwd.name, ticket_plugin=True, resume=True)
    os.execvp(args[0], args)


if __name__ == "__main__":
    main()

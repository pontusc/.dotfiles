#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Compose tmux ticket sessions from the repos discovered under the work root."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import compose
import maintain
import report
import ui
from errors import Cancelled, WorkspaceError


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="workspace",
        description=(
            "Compose tmux ticket sessions from the repos discovered under the work"
            " root. workspaces.toml only adds optional shortcuts and descriptions."
        ),
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    flow = subparsers.add_parser(
        "flow", help="run the picker and prompt popups (tmux keybinding target)"
    )
    flow.set_defaults(func=lambda _: compose.flow_workspace())

    open_workspace = subparsers.add_parser(
        "open", help="pick repos and templates and materialize a session"
    )
    open_workspace.add_argument(
        "--chain-out", type=Path, default=None, dest="chain_out", help=argparse.SUPPRESS
    )
    open_workspace.set_defaults(
        func=lambda args: compose.open_workspace(args.chain_out)
    )

    # Passing no help keeps materialize out of the listing: argparse renders
    # help=SUPPRESS literally for a subparser.
    materialize = subparsers.add_parser("materialize")
    materialize.add_argument("--repo", action="append", default=[], dest="repos")
    materialize.add_argument(
        "--template", action="append", default=[], dest="templates"
    )
    materialize.set_defaults(
        func=lambda args: compose.materialize_workspace(args.repos, args.templates)
    )

    add = subparsers.add_parser(
        "add", help="add a discovered repo to the current session"
    )
    add.set_defaults(func=lambda _: maintain.add_repo())

    cleanup = subparsers.add_parser(
        "cleanup", help="close current-session windows that lose nothing"
    )
    cleanup.set_defaults(func=lambda _: maintain.cleanup_session())

    listing = subparsers.add_parser(
        "list", help="show workspaces and materialized sessions"
    )
    listing.set_defaults(func=lambda _: report.list_workspaces())

    return parser


def main() -> None:
    args = _build_parser().parse_args()
    try:
        args.func(args)
    except WorkspaceError as error:
        ui.fail(str(error))
    except FileNotFoundError as error:
        ui.fail(f"required tool not found: {error.filename}")
    except (Cancelled, EOFError):
        raise SystemExit(0) from None
    except KeyboardInterrupt:
        print("interrupted", file=sys.stderr)
        raise SystemExit(130) from None


if __name__ == "__main__":
    main()

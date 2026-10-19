#!/usr/bin/env python3
"""Compose tmux ticket sessions from the repos discovered under the work root."""

import argparse
import sys
from pathlib import Path

import ui
from errors import Cancelled, WorkspaceError


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="workspace",
        description=(
            "Compose tmux ticket sessions from the repos discovered under the work"
            " root. workspaces.toml only adds optional descriptions."
        ),
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser(
        "flow", help="run the picker and prompt popups (tmux keybinding target)"
    )

    open_workspace = subparsers.add_parser(
        "open", help="pick repos and materialize a session"
    )
    open_workspace.add_argument(
        "--chain-out", type=Path, default=None, dest="chain_out", help=argparse.SUPPRESS
    )

    # Passing no help keeps materialize out of the listing: argparse renders
    # help=SUPPRESS literally for a subparser.
    materialize = subparsers.add_parser("materialize")
    materialize.add_argument("--repo", action="append", default=[], dest="repos")

    subparsers.add_parser("add", help="add a discovered repo to the current session")

    subparsers.add_parser("layout", help="apply the dev layout to the current window")

    subparsers.add_parser(
        "cleanup", help="close current-session windows that lose nothing"
    )

    archive_run = subparsers.add_parser("archive")
    archive_run.add_argument("plan", type=Path)

    subparsers.add_parser(
        "list", help="show discovered repos and materialized sessions"
    )

    subparsers.add_parser("switch", help="pick a session by slot number or fuzzy find")

    subparsers.add_parser(
        "state-save",
        help="write session and window tags to disk (tmux-resurrect save hook)",
    )

    subparsers.add_parser(
        "state-restore",
        help="reapply saved tags after a restore (tmux-resurrect restore hook)",
    )

    return parser


def _dispatch(args: argparse.Namespace) -> None:
    match args.command:
        case "flow":
            import compose

            compose.flow_workspace()
        case "open":
            import compose

            compose.open_workspace(args.chain_out)
        case "materialize":
            import compose

            compose.materialize_workspace(args.repos)
        case "add":
            import maintain

            maintain.add_repo()
        case "layout":
            import layout

            layout.arrange_current_window()
        case "cleanup":
            import maintain

            maintain.cleanup_session()
        case "archive":
            import archive

            archive.run(args.plan)
        case "list":
            import report

            report.list_workspaces()
        case "switch":
            import switch

            switch.switch_session()
        case "state-save":
            import persist

            persist.save_state()
        case "state-restore":
            import persist

            persist.restore_state()
        case _:
            raise AssertionError(f"no handler for subcommand {args.command}")


def main() -> None:
    args = _build_parser().parse_args()
    try:
        _dispatch(args)
    except WorkspaceError as error:
        ui.fail(str(error))
    except FileNotFoundError as error:
        ui.fail(f"required tool not found: {error.filename}")
    except Cancelled, EOFError:
        raise SystemExit(0) from None
    except KeyboardInterrupt:
        print("interrupted", file=sys.stderr)
        raise SystemExit(130) from None


if __name__ == "__main__":
    main()

"""Load and validate the workspace catalogue from workspaces.toml."""

from __future__ import annotations

import re
import tomllib
from dataclasses import dataclass
from pathlib import Path

from errors import WorkspaceError

CONFIG_PATH = Path.home() / ".config" / "tmux" / "workspaces.toml"
DEFAULT_WORK_ROOT = "~/Work"
DEFAULT_TICKET_PATTERN = "[A-Z]+-[0-9]+"


@dataclass(frozen=True)
class Settings:
    work_root: Path
    ticket_pattern: re.Pattern[str]
    ticket_prefix: str | None = None


@dataclass(frozen=True)
class Config:
    settings: Settings
    repos: dict[str, str]


def _parse_settings(table: object) -> Settings:
    if not isinstance(table, dict):
        raise WorkspaceError(f"{CONFIG_PATH}: [settings] must be a table")
    work_root = table.get("work_root", DEFAULT_WORK_ROOT)
    ticket_pattern = table.get("ticket_pattern", DEFAULT_TICKET_PATTERN)
    ticket_prefix = table.get("ticket_prefix")
    if not isinstance(work_root, str) or not isinstance(ticket_pattern, str):
        raise WorkspaceError(
            f"{CONFIG_PATH}: settings.work_root and settings.ticket_pattern"
            " must be strings"
        )
    if ticket_prefix is not None and not isinstance(ticket_prefix, str):
        raise WorkspaceError(f"{CONFIG_PATH}: settings.ticket_prefix must be a string")
    try:
        compiled = re.compile(ticket_pattern)
    except re.error as error:
        raise WorkspaceError(
            f"{CONFIG_PATH}: invalid settings.ticket_pattern: {error}"
        ) from error
    root = Path(work_root).expanduser()
    if not root.is_dir():
        raise WorkspaceError(
            f"{CONFIG_PATH}: settings.work_root does not exist: {root}"
        )
    return Settings(
        work_root=root, ticket_pattern=compiled, ticket_prefix=ticket_prefix
    )


def _parse_repos(table: object) -> dict[str, str]:
    if not isinstance(table, dict) or not all(
        isinstance(description, str) for description in table.values()
    ):
        raise WorkspaceError(
            f'{CONFIG_PATH}: [repos] must map "<dir>" to a description string'
        )
    return dict(table)


def load() -> Config:
    if not CONFIG_PATH.is_file():
        return Config(settings=_parse_settings({}), repos={})
    try:
        raw = tomllib.loads(CONFIG_PATH.read_text())
    except (OSError, tomllib.TOMLDecodeError) as error:
        raise WorkspaceError(f"cannot read {CONFIG_PATH}: {error}") from error
    return Config(
        settings=_parse_settings(raw.get("settings", {})),
        repos=_parse_repos(raw.get("repos", {})),
    )

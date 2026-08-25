"""The ticket a workspace can be materialized under."""

from __future__ import annotations

import re
from dataclasses import dataclass

from errors import WorkspaceError


@dataclass(frozen=True)
class Ticket:
    key: str | None
    slug: str

    @property
    def branch(self) -> str:
        return self.slug if self.key is None else f"{self.key}/{self.slug}"

    @property
    def session_name(self) -> str:
        return self.slug if self.key is None else self.key


def parse_key(raw: str, pattern: re.Pattern[str], prefix: str | None) -> str:
    """Expand a bare ticket number and check the result against the pattern."""
    if raw.isdigit():
        if prefix is None:
            raise WorkspaceError(
                f"'{raw}' is a bare ticket number but no ticket_prefix is configured"
            )
        key = f"{prefix}-{raw}"
    else:
        key = raw
    if not pattern.fullmatch(key):
        raise WorkspaceError(f"'{key}' does not match ticket pattern {pattern.pattern}")
    return key


def from_session(
    name: str, slug: str | None, pattern: re.Pattern[str]
) -> Ticket | None:
    """Read the ticket a live session stands for, given its resolved slug."""
    if pattern.fullmatch(name):
        if not slug:
            raise WorkspaceError("ticket session needs a slug")
        return Ticket(key=name, slug=slug)
    if slug:
        return Ticket(key=None, slug=slug)
    return None

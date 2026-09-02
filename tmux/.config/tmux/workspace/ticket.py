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


def _renamed(name: str, expected: str) -> WorkspaceError:
    return WorkspaceError(
        f"session '{name}' no longer carries its own ticket '{expected}': add derives"
        " the tickets/<session> worktree directory from the session name, so rename"
        f" the session back to '{expected}'"
    )


def from_session(
    name: str, key: str | None, slug: str | None, pattern: re.Pattern[str]
) -> Ticket | None:
    """Read the ticket a live session stands for, given its resolved tags."""
    if key:
        if name != key:
            raise _renamed(name, key)
        if not slug:
            raise WorkspaceError("ticket session needs a slug")
        return Ticket(key=key, slug=slug)
    if not slug:
        return None
    # Sessions materialized before @ticket_key existed carry the key in the name.
    if pattern.fullmatch(name):
        return Ticket(key=name, slug=slug)
    if name != slug:
        raise _renamed(name, slug)
    return Ticket(key=None, slug=slug)

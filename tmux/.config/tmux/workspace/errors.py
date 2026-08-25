"""Exceptions the CLI error boundary in main routes on."""

from __future__ import annotations


class WorkspaceError(Exception):
    """A failure the user has to see, reported through ui.fail."""


class Cancelled(Exception):
    """The user aborted a prompt or a picker."""

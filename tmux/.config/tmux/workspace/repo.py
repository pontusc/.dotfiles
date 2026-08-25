"""Repo discovery and identity under the work root: the repo universe is filesystem state,
never config.
"""

from __future__ import annotations

from pathlib import Path

from worktree import WORKTREES_SUFFIX


def discover(work_root: Path) -> list[str]:
    if not work_root.is_dir():
        return []
    return sorted(
        entry.name
        for entry in work_root.iterdir()
        if not entry.name.endswith(WORKTREES_SUFFIX)
        and entry.is_dir()
        and (entry / ".git").exists()
    )


def owner_of(path: Path, work_root: Path, repos: list[str]) -> str | None:
    for name in repos:
        repo_root = work_root / name
        if path == repo_root or path.is_relative_to(f"{repo_root}{WORKTREES_SUFFIX}"):
            return name
    return None

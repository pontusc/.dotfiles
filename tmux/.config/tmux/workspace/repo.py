"""Repo discovery and identity under the work root: the repo universe is filesystem state,
never config.
"""

from __future__ import annotations

from pathlib import Path

import worktree
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
    root = worktree.main_repo_root(path)
    if root is None:
        return None
    # git hands back a realpath, so the candidate is resolved too: either the
    # work root or the repo directory itself may be a symlink.
    if root.name in repos and (work_root / root.name).resolve() == root:
        return root.name
    return None

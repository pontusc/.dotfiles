"""Git worktree layout and lifecycle for a repo checkout."""

from __future__ import annotations

import contextlib
import subprocess
from pathlib import Path
from typing import NamedTuple

WORKTREES_SUFFIX = ".worktrees"
TICKETS_DIR = "tickets"


class Status(NamedTuple):
    changes: tuple[str, ...]
    ignored: tuple[str, ...]


def _git(cwd: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(cwd), *args],
        capture_output=True,
        text=True,
        check=False,
    )


def _ref_exists(repo_root: Path, ref: str) -> bool:
    return _git(repo_root, "show-ref", "--verify", "--quiet", ref).returncode == 0


def _base_ref(repo_root: Path) -> str:
    head = _git(
        repo_root, "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"
    )
    if head.returncode == 0 and head.stdout.strip():
        return head.stdout.strip()
    for branch in ("main", "master"):
        if _ref_exists(repo_root, f"refs/remotes/origin/{branch}"):
            return f"origin/{branch}"
        if _ref_exists(repo_root, f"refs/heads/{branch}"):
            return branch
    return "HEAD"


def path_for(work_root: Path, session: str, repo_name: str) -> Path:
    return work_root / TICKETS_DIR / session / repo_name


def main_repo_root(path: Path) -> Path | None:
    """The root of the main repo path belongs to, whether path is the main
    checkout or a linked worktree.
    """
    result = _git(path, "rev-parse", "--path-format=absolute", "--git-common-dir")
    if result.returncode != 0 or not result.stdout.strip():
        return None
    return Path(result.stdout.strip()).parent


def create(repo_root: Path, branch: str, path: Path) -> str | None:
    """Check out branch at path, returning an error message on failure."""
    if _ref_exists(repo_root, f"refs/heads/{branch}"):
        args = ["worktree", "add", str(path), branch]
    elif _ref_exists(repo_root, f"refs/remotes/origin/{branch}"):
        args = [
            "worktree",
            "add",
            "--track",
            "-b",
            branch,
            str(path),
            f"origin/{branch}",
        ]
    else:
        args = [
            "worktree",
            "add",
            "--no-track",
            "-b",
            branch,
            str(path),
            _base_ref(repo_root),
        ]
    result = _git(repo_root, *args)
    if result.returncode == 0:
        return None
    return result.stderr.strip() or f"git worktree add exited {result.returncode}"


def branch_at(path: Path) -> str | None:
    """The branch checked out at path, or None if it is not a git checkout."""
    result = _git(path, "rev-parse", "--abbrev-ref", "HEAD")
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def status(path: Path) -> Status | None:
    """What removing the worktree would lose, or None if git status failed."""
    result = _git(path, "status", "--porcelain", "--ignored")
    if result.returncode != 0:
        return None
    changes: list[str] = []
    ignored: list[str] = []
    for line in result.stdout.splitlines():
        if line.startswith("!! "):
            ignored.append(line[3:])
        elif line:
            changes.append(line[3:])
    return Status(changes=tuple(changes), ignored=tuple(ignored))


def remove(repo_root: Path, path: Path) -> str | None:
    """Remove a worktree, returning an error message on failure."""
    result = _git(repo_root, "worktree", "remove", str(path))
    if result.returncode != 0:
        return (
            result.stderr.strip() or f"git worktree remove exited {result.returncode}"
        )
    with contextlib.suppress(OSError):
        path.parent.rmdir()
    return None

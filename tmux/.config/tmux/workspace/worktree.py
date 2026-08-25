"""Git worktree layout and lifecycle for a repo checkout."""

from __future__ import annotations

import subprocess
from pathlib import Path

WORKTREES_SUFFIX = ".worktrees"


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


def path_for(repo_root: Path, branch: str) -> Path:
    return Path(f"{repo_root}{WORKTREES_SUFFIX}") / branch.replace("/", "-")


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


def is_clean(path: Path) -> bool:
    """True when removing the worktree loses nothing, ignored files included."""
    result = _git(path, "status", "--porcelain", "--ignored")
    return result.returncode == 0 and not result.stdout.strip()


def remove(repo_root: Path, path: Path) -> str | None:
    """Remove a worktree, returning an error message on failure."""
    result = _git(repo_root, "worktree", "remove", str(path))
    if result.returncode == 0:
        return None
    return result.stderr.strip() or f"git worktree remove exited {result.returncode}"

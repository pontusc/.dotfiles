"""Git worktree layout and lifecycle for a repo checkout."""

from __future__ import annotations

import contextlib
import shutil
import subprocess
from collections.abc import Callable
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


def base_ref(repo_root: Path) -> str:
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


def ticket_dir(work_root: Path, session: str) -> Path:
    return work_root / TICKETS_DIR / session


def path_for(work_root: Path, session: str, repo_name: str) -> Path:
    return ticket_dir(work_root, session) / repo_name


def main_repo_root(path: Path) -> Path | None:
    """The root of the main repo path belongs to, whether path is the main
    checkout or a linked worktree.
    """
    result = _git(path, "rev-parse", "--path-format=absolute", "--git-common-dir")
    if result.returncode != 0 or not result.stdout.strip():
        return None
    return Path(result.stdout.strip()).parent


def _refresh_base(repo_root: Path, base: str) -> str | None:
    """Fetch a remote-tracking base ref, returning a warning when that fails."""
    remote, _, name = base.partition("/")
    if remote != "origin" or not name:
        return None
    result = _git(
        repo_root, "fetch", "--quiet", remote, f"refs/heads/{name}:refs/remotes/{base}"
    )
    if result.returncode == 0:
        return None
    detail = result.stderr.strip() or f"git fetch exited {result.returncode}"
    return f"branched from stale {base}, fetch failed: {detail}"


class Created(NamedTuple):
    error: str | None
    warning: str | None


def create(
    repo_root: Path,
    branch: str,
    path: Path,
    report: Callable[[str], None] = lambda _: None,
) -> Created:
    """Check out branch at path, a new branch cut from the freshly fetched base, or an
    orphan branch when the repo has no commits yet.
    """
    warning = None
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
        base = base_ref(repo_root)
        report(f"fetching {base}")
        warning = _refresh_base(repo_root, base)
        if _git(repo_root, "rev-parse", "--verify", "--quiet", base).returncode == 0:
            args = ["worktree", "add", "--no-track", "-b", branch, str(path), base]
        else:
            args = ["worktree", "add", "--orphan", "-b", branch, str(path)]
    report("adding worktree")
    result = _git(repo_root, *args)
    if result.returncode == 0:
        return Created(error=None, warning=warning)
    error = result.stderr.strip() or f"git worktree add exited {result.returncode}"
    return Created(error=error, warning=None)


def branches(repo_root: Path) -> set[str]:
    """Local branches and origin branches as of the last fetch, remote prefix dropped."""
    result = _git(
        repo_root,
        "for-each-ref",
        "--format=%(refname:short)",
        "refs/heads",
        "refs/remotes/origin",
    )
    found: set[str] = set()
    for line in result.stdout.splitlines():
        name = line.removeprefix("origin/")
        if name and name != "HEAD":
            found.add(name)
    return found


def copy_into(repo_root: Path, path: Path, relative: str) -> str | None:
    """Copy a path from the main checkout into the worktree, an error message on failure."""
    source = repo_root / relative
    target = path / relative
    if not source.exists():
        return f"{relative} not found in {repo_root}"
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        if source.is_dir():
            shutil.copytree(source, target, symlinks=True)
        else:
            shutil.copy2(source, target)
    except OSError as error:
        return f"copying {relative} failed: {error}"
    return None


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


def delete_branch(repo_root: Path, branch: str, *, force: bool = False) -> str | None:
    """Delete a branch, returning git's own message when it refuses."""
    result = _git(
        repo_root,
        "-c",
        "advice.forceDeleteBranch=false",
        "branch",
        "-D" if force else "-d",
        branch,
    )
    if result.returncode == 0:
        return None
    return result.stderr.strip() or f"git branch delete exited {result.returncode}"

"""Archive a closed ticket's knowledge before its worktrees go.

The popup decides and records a plan, then a detached run of this module
digests the inputs, has an agent write the archive entry, commits it, and
only then removes the worktrees, branches and ticket root.
"""

from __future__ import annotations

import fcntl
import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import asdict, dataclass
from pathlib import Path

import layout
import persist
import tmux
import worktree
from errors import WorkspaceError

STATE_DIR = persist.STATE_DIR / "archive"
PROJECTS_DIR = Path.home() / ".claude" / "projects"
PROMPT_PATH = layout.AGENT_CONFIG_DIR / "archive.md"
ENTRIES_DIR = "tickets"
TAGS_FILE = "tags.md"
_AGENT_TIMEOUT_SECONDS = 1800
_DIGEST_BLOCK_CHARS = 2000
_FALLBACK_COMMITS = 50
_PATCH_CHARS = 300_000
_LINEAR_MCP = {
    "mcpServers": {
        "linear": {"type": "http", "url": "https://mcp.linear.app/mcp/readonly"}
    }
}


@dataclass(frozen=True)
class Worktree:
    repo: str
    repo_root: str
    path: str
    branch: str | None


@dataclass(frozen=True)
class Plan:
    key: str
    ticket_root: str
    archive_root: str
    client: str
    loose_files: list[str]
    worktrees: list[Worktree]


def log_path(key: str) -> Path:
    return STATE_DIR / f"{key}.log"


def plan_path(key: str) -> Path:
    return STATE_DIR / f"{key}.json"


def schedule(plan: Plan) -> None:
    """Hand the plan to a detached run that outlives the popup."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    env = {name: value for name, value in os.environ.items() if name != "TMUX_PANE"}
    # The run inherits the log as stdout and with it the lock, which a killed
    # run releases while a stale plan file would not.
    with log_path(plan.key).open("a") as log:
        try:
            fcntl.flock(log, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise WorkspaceError(
                f"{plan.key}: an archive run is already in progress"
            ) from None
        log.truncate(0)
        plan_path(plan.key).write_text(json.dumps(asdict(plan)))
        subprocess.Popen(
            [sys.argv[0], "archive", str(plan_path(plan.key))],
            stdin=subprocess.DEVNULL,
            stdout=log,
            stderr=subprocess.STDOUT,
            start_new_session=True,
            env=env,
        )


def _load(path: Path) -> Plan:
    raw = json.loads(path.read_text())
    raw["worktrees"] = [Worktree(**entry) for entry in raw["worktrees"]]
    return Plan(**raw)


def _log(message: str) -> None:
    print(f"{time.strftime('%H:%M:%S')} {message}", flush=True)


def _project_dirs(ticket_root: Path) -> list[Path]:
    encoded = re.sub(r"[^A-Za-z0-9]", "-", str(ticket_root))
    if not PROJECTS_DIR.is_dir():
        return []
    return sorted(
        entry
        for entry in PROJECTS_DIR.iterdir()
        if entry.name == encoded or entry.name.startswith(f"{encoded}-")
    )


def _tool_label(block: dict[str, object]) -> str:
    name = block.get("name", "")
    raw = block.get("input")
    detail = ""
    if isinstance(raw, dict):
        for field in ("description", "file_path", "skill", "command"):
            value = raw.get(field)
            if isinstance(value, str) and value:
                detail = value.splitlines()[0][:120]
                break
    return f"[tool {name}] {detail}".rstrip()


def _digest_line(record: dict[str, object]) -> list[str]:
    if record.get("isSidechain"):
        return []
    kind = record.get("type")
    if kind not in ("user", "assistant"):
        return []
    message = record.get("message")
    if not isinstance(message, dict):
        return []
    content = message.get("content")
    lines: list[str] = []
    if isinstance(content, str):
        if not content.startswith("<"):
            lines.append(f"## {kind}\n\n{content[:_DIGEST_BLOCK_CHARS]}")
        return lines
    if not isinstance(content, list):
        return []
    for block in content:
        if not isinstance(block, dict):
            continue
        if block.get("type") == "text":
            text = str(block.get("text", ""))
            if text and not text.startswith("<"):
                lines.append(f"## {kind}\n\n{text[:_DIGEST_BLOCK_CHARS]}")
        elif block.get("type") == "tool_use":
            lines.append(_tool_label(block))
    return lines


def _digest_transcripts(ticket_root: Path, inputs: Path) -> int:
    target = inputs / "transcripts"
    target.mkdir(parents=True, exist_ok=True)
    count = 0
    for project in _project_dirs(ticket_root):
        for transcript in sorted(
            project.glob("*.jsonl"), key=lambda p: p.stat().st_mtime
        ):
            lines: list[str] = []
            for raw in transcript.read_text(errors="replace").splitlines():
                try:
                    record = json.loads(raw)
                except json.JSONDecodeError:
                    continue
                if isinstance(record, dict):
                    lines.extend(_digest_line(record))
            if not lines:
                continue
            count += 1
            active = time.strftime(
                "%Y-%m-%d", time.localtime(transcript.stat().st_mtime)
            )
            (target / f"{count:02d}-{project.name}.md").write_text(
                f"# Session {transcript.stem} ({project.name}, last active {active})\n\n"
                + "\n\n".join(lines)
                + "\n"
            )
    return count


def _git(cwd: str, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", cwd, *args], capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        raise WorkspaceError(f"git {args[0]} in {cwd}: {result.stderr.strip()}")
    return result.stdout


def _has_commits(entry: Worktree) -> bool:
    result = subprocess.run(
        ["git", "-C", entry.path, "rev-parse", "--verify", "--quiet", "HEAD"],
        capture_output=True,
        check=False,
    )
    return result.returncode == 0


def _fork_point(entry: Worktree) -> str | None:
    base = worktree.base_ref(Path(entry.repo_root))
    if base == "HEAD":
        return None
    try:
        return _git(entry.path, "merge-base", "HEAD", base).strip() or None
    except WorkspaceError:
        return None


def _pull_requests(entry: Worktree, key: str) -> str:
    """Pull requests from the current branch and any mentioning the key, as JSON."""
    found: dict[str, dict[str, object]] = {}
    filters = [["--search", f"{key} in:title,body"]]
    if entry.branch:
        filters.append(["--head", entry.branch])
    for selector in filters:
        result = subprocess.run(
            [
                "gh",
                "pr",
                "list",
                "--state",
                "all",
                "--json",
                "url,state,title,mergedAt",
                *selector,
            ],
            cwd=entry.path,
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            return f"gh failed: {result.stderr.strip()}"
        for pull in json.loads(result.stdout or "[]"):
            found[str(pull["url"])] = pull
    return json.dumps(list(found.values()), indent=1)


def _git_report(entry: Worktree, key: str) -> tuple[str, str]:
    """The commit log with pull requests, and the patch, both since the branch forked."""
    header = f"# {entry.repo} on {entry.branch or 'detached HEAD'}\n\nWorktree: {entry.path}\n\n"
    pulls = f"## Pull requests\n\n{_pull_requests(entry, key)}\n\n"
    if not _has_commits(entry):
        return (
            f"{header}{pulls}## Commits\n\nnone, HEAD is unborn\n",
            f"{header}## Patch\n\nnone\n",
        )
    fork = _fork_point(entry)
    scope = [f"{fork}..HEAD"] if fork else ["-n", str(_FALLBACK_COMMITS)]
    log_format = "--format=%n%h %ad %an%n%s%n%n%b"
    log = _git(
        entry.path, "log", "--no-merges", "--stat", "--date=short", log_format, *scope
    )
    patch = _git(
        entry.path, "log", "--no-merges", "-p", "--date=short", log_format, *scope
    )
    if len(patch) > _PATCH_CHARS:
        patch = patch[:_PATCH_CHARS] + "\n\n[patch truncated]\n"
    since = f"since the fork at {fork[:10]}" if fork else f"last {_FALLBACK_COMMITS}"
    report = f"{header}{pulls}## Commits, {since}\n\n{log}"
    return report, f"{header}## Patch, {since}\n\n{patch}"


def _prepare_inputs(plan: Plan, inputs: Path) -> None:
    if inputs.exists():
        shutil.rmtree(inputs)
    git_dir = inputs / "git"
    git_dir.mkdir(parents=True)
    for index, entry in enumerate(plan.worktrees, start=1):
        report, patch = _git_report(entry, plan.key)
        (git_dir / f"{index:02d}-{entry.repo}.md").write_text(report)
        (git_dir / f"{index:02d}-{entry.repo}.patch").write_text(patch)
    (inputs / "mcp.json").write_text(json.dumps(_LINEAR_MCP))
    _log(f"git reports for {len(plan.worktrees)} worktrees")
    count = _digest_transcripts(Path(plan.ticket_root), inputs)
    _log(f"digested {count} transcripts")


def _run_agent(plan: Plan, inputs: Path) -> Path:
    prompt = (
        PROMPT_PATH.read_text()
        .replace("{key}", plan.key)
        .replace("{archive_root}", plan.archive_root)
        .replace("{inputs}", str(inputs))
        .replace("{ticket_root}", plan.ticket_root)
    )
    archive_root = plan.archive_root.lstrip("/")
    command = [
        "claude",
        "-p",
        "--model",
        "opus",
        "--tools",
        "Read,Grep,Glob,Edit,Write",
        "--setting-sources",
        "project",
        "--strict-mcp-config",
        "--mcp-config",
        str(inputs / "mcp.json"),
        "--permission-mode",
        "dontAsk",
        "--allowedTools",
        "Read",
        "Grep",
        "Glob",
        f"Edit(//{archive_root}/{ENTRIES_DIR}/**)",
        f"Edit(//{archive_root}/{TAGS_FILE})",
        "mcp__linear__get_issue",
        "mcp__linear__list_comments",
        "--add-dir",
        plan.archive_root,
        plan.ticket_root,
    ]
    _log("agent started")
    try:
        result = subprocess.run(
            command,
            cwd=inputs,
            input=prompt,
            capture_output=True,
            text=True,
            check=False,
            timeout=_AGENT_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as error:
        print(error.stdout or "", flush=True)
        raise WorkspaceError(
            f"agent timed out after {_AGENT_TIMEOUT_SECONDS}s"
        ) from error
    print(result.stdout, flush=True)
    if result.returncode != 0:
        raise WorkspaceError(
            f"agent exited {result.returncode}: {result.stderr.strip()}"
        )
    entry = Path(plan.archive_root) / ENTRIES_DIR / f"{plan.key}.md"
    if not entry.is_file():
        raise WorkspaceError(f"agent finished without writing {entry}")
    _log(f"entry written: {entry}")
    return entry


def _commit(plan: Plan, entry: Path) -> None:
    root = Path(plan.archive_root)
    paths = [str(entry.relative_to(root))]
    if (root / TAGS_FILE).exists():
        paths.append(TAGS_FILE)
    _git(plan.archive_root, "add", "--", *paths)
    if not _git(plan.archive_root, "status", "--porcelain", "--", *paths).strip():
        _log("archive unchanged, nothing to commit")
        return
    _git(plan.archive_root, "commit", "-q", "-m", f"Archive {plan.key}", "--", *paths)
    _log("archive committed")


def _clean(plan: Plan) -> list[str]:
    outcomes: list[str] = []
    for entry in plan.worktrees:
        if tmux.find_window_by_worktree(Path(entry.path)) is not None:
            outcomes.append(f"{entry.repo}: reopened in tmux, worktree kept")
            continue
        error = worktree.remove(Path(entry.repo_root), Path(entry.path))
        if error:
            outcomes.append(f"{entry.repo}: {error}, worktree kept")
            continue
        outcome = f"{entry.repo}: removed worktree"
        if entry.branch:
            error = worktree.delete_branch(Path(entry.repo_root), entry.branch)
            outcome += (
                f", branch {entry.branch} kept ({error})"
                if error
                else f", deleted branch {entry.branch}"
            )
        outcomes.append(outcome)
    ticket_root = Path(plan.ticket_root)
    if not ticket_root.is_dir():
        return outcomes
    remaining = {
        entry.name
        for entry in ticket_root.iterdir()
        if entry.name != layout.AGENT_CONFIG_LINK
    }
    # Only what the popup saw may go. Anything that appeared since, a reopened
    # session or a worktree whose removal failed keeps the directory.
    if remaining <= set(plan.loose_files) and not tmux.session_exists(plan.key):
        shutil.rmtree(ticket_root)
        outcomes.append(f"{plan.key}: ticket directory removed")
    else:
        outcomes.append(f"{plan.key}: ticket directory kept")
    return outcomes


def run(path: Path) -> None:
    try:
        _run(_load(path))
    finally:
        path.unlink(missing_ok=True)


def _run(plan: Plan) -> None:
    inputs = STATE_DIR / plan.key
    cleaning = False
    try:
        _prepare_inputs(plan, inputs)
        entry = _run_agent(plan, inputs)
        _commit(plan, entry)
        cleaning = True
        outcomes = _clean(plan)
        for line in outcomes:
            _log(line)
        kept = sum("kept" in line for line in outcomes)
        state = f"archived, {kept} kept, see log" if kept else "archived"
        tmux.message(plan.client, f"{plan.key} {state}")
    except Exception as error:
        _log(f"failed: {error!r}")
        state = (
            "cleanup failed after archiving"
            if cleaning
            else "archive failed, worktrees kept"
        )
        tmux.message(plan.client, f"{plan.key} {state}, see log")
        raise SystemExit(1) from error
    finally:
        shutil.rmtree(inputs, ignore_errors=True)

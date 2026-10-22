"""Compose a tmux session out of picked repos."""

import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
from collections.abc import Sequence
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import NamedTuple

import config
import layout
import persist
import repo
import ticket
import tmux
import ui
import worktree
from errors import WorkspaceError


@dataclass(frozen=True)
class WindowSpec:
    repo: str
    path: Path


class Prepared(NamedTuple):
    specs: list[WindowSpec]
    failures: list[str]
    warnings: list[str]


def repo_lines(repos: Sequence[str], descriptions: dict[str, str]) -> list[str]:
    """Picker rows: the repo name padded to a common width, then its description."""
    if not repos:
        return []
    width = max(len(name) for name in repos)
    return [f"{name:<{width}}  {descriptions.get(name, '')}".rstrip() for name in repos]


def prioritized(repos: list[str], descriptions: dict[str, str]) -> list[str]:
    # fzf shows the first input row closest to the prompt, so described
    # (config-listed) repos go first to sit at the top of the picker.
    described = [name for name in repos if name in descriptions]
    return described + [name for name in repos if name not in descriptions]


def row_name(row: str) -> str:
    """The name a picker row stands for, dropping padding and the description."""
    return row.split()[0]


class _Resolved(NamedTuple):
    spec: WindowSpec | None
    failure: str | None
    warning: str | None


def _prepare_worktree(
    repo_name: str,
    workspace_config: config.Config,
    branch: str,
    session: str,
    progress: ui.Progress,
) -> _Resolved:
    work_root = workspace_config.settings.work_root
    repo_root = work_root / repo_name
    path = worktree.path_for(work_root, session, repo_name)
    warnings: list[str] = []
    if path.is_dir():
        # The path is derived from the branch name, so an existing one is
        # only ours to reuse when it really is that branch's worktree.
        checked_out = worktree.branch_at(path)
        if checked_out != branch:
            failure = f"{path} is on {checked_out or 'no branch'}, expected {branch}"
            progress.finish(repo_name, failure, ok=False)
            return _Resolved(None, f"{repo_name}: {failure}", None)
        progress.finish(repo_name, "reusing worktree", ok=True)
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        created = worktree.create(
            repo_root,
            branch,
            path,
            report=lambda state: progress.update(repo_name, state),
        )
        if created.error:
            progress.finish(repo_name, created.error, ok=False)
            return _Resolved(None, f"{repo_name}: {created.error}", None)
        if created.warning:
            warnings.append(created.warning)
        for relative in workspace_config.copies.get(repo_name, ()):
            progress.update(repo_name, f"copying {relative}")
            error = worktree.copy_into(repo_root, path, relative)
            if error:
                warnings.append(error)
        progress.finish(repo_name, "worktree ready", ok=True)
    warning = f"{repo_name}: {', '.join(warnings)}" if warnings else None
    return _Resolved(WindowSpec(repo=repo_name, path=path), None, warning)


def prepare_windows(
    repos: list[str],
    workspace_config: config.Config,
    session_ticket: ticket.Ticket,
    session: str,
) -> Prepared:
    """Resolve each repo to the path its window opens at, per-repo failures apart."""
    branch = session_ticket.branch
    with ui.Progress(repos) as progress, ThreadPoolExecutor() as pool:
        resolved = list(
            pool.map(
                lambda repo_name: _prepare_worktree(
                    repo_name,
                    workspace_config,
                    branch,
                    session,
                    progress,
                ),
                repos,
            )
        )
    return Prepared(
        specs=[item.spec for item in resolved if item.spec is not None],
        failures=[item.failure for item in resolved if item.failure is not None],
        warnings=[item.warning for item in resolved if item.warning is not None],
    )


def _configure_window(window_id: str, spec: WindowSpec) -> None:
    tmux.set_window_option(window_id, "@worktree", str(spec.path))
    layout.arrange_side(window_id, spec.path, "nvim")


def ensure_windows(session: str, specs: list[WindowSpec], agent_dir: Path) -> list[str]:
    """Open a window per spec in session, returning the ones left alone.

    The session holds one agent window in agent_dir, created first so it keeps
    index 1, and only when the session does not have one yet.
    """
    pending: list[WindowSpec] = []
    skipped: list[str] = []
    layout.link_agent_config(agent_dir)
    for spec in specs:
        existing = tmux.find_window_by_worktree(spec.path)
        if existing is None:
            pending.append(spec)
        elif existing.session != session:
            skipped.append(
                f"{spec.repo}: already open in session {existing.session}, left alone"
            )
    if not tmux.session_exists(session):
        layout.start_agent(
            tmux.start_session(session, layout.AGENT_WINDOW, agent_dir),
            session,
            agent_dir,
        )
    elif tmux.find_window_by_name(session, layout.AGENT_WINDOW) is None:
        layout.start_agent(
            tmux.new_window(session, layout.AGENT_WINDOW, agent_dir), session, agent_dir
        )
    for spec in pending:
        _configure_window(tmux.new_window(session, spec.repo, spec.path), spec)
    return skipped


def _branch_rows(
    repos: list[str], work_root: Path, key: str | None, pattern: re.Pattern[str]
) -> list[str]:
    """Picker rows: the slug, a tab, and the repos that already have the branch.

    With a ticket only its branches, shown as slugs. Without one every branch
    that is not a ticket branch.
    """
    holders: dict[str, list[str]] = {}
    for repo_name in repos:
        for branch in worktree.branches(work_root / repo_name):
            prefix, _, slug = branch.partition("/")
            if key is not None:
                if prefix != key or not slug:
                    continue
                holders.setdefault(slug, []).append(repo_name)
            elif not (slug and pattern.fullmatch(prefix)):
                holders.setdefault(branch, []).append(repo_name)
    return [f"{slug}\t{' '.join(found)}" for slug, found in sorted(holders.items())]


def _resolve_ticket(
    repos: list[str], settings: config.Settings
) -> ticket.Ticket | None:
    raw = ui.prompt_line("Ticket ❯ ").strip()
    key = None
    if raw:
        key = ticket.parse_key(raw, settings.ticket_pattern, settings.ticket_prefix)
    rows = _branch_rows(repos, settings.work_root, key, settings.ticket_pattern)
    slug = ui.pick_or_new(rows)
    if slug is None:
        return None
    return ticket.Ticket(key=key, slug=slug)


def flow_workspace() -> None:
    # A display-popup opened from inside another popup modifies the popup that
    # is already up and ignores every other option (tmux(1), display-popup), so
    # the keybinding runs this server-side: it opens the picker popup, and open
    # hands its selection back through a file for the prompt popup to consume.
    handle, chain_name = tempfile.mkstemp(prefix="workspace-chain-")
    os.close(handle)
    chain_path = Path(chain_name)
    try:
        subprocess.run(
            [
                "tmux",
                "display-popup",
                "-E",
                "-s",
                "bg=terminal",
                "-w",
                "80",
                "-h",
                "24",
                shlex.join([sys.argv[0], "open", "--chain-out", str(chain_path)]),
            ],
            check=False,
        )
        handoff = chain_path.read_text().strip()
    finally:
        chain_path.unlink(missing_ok=True)
    if not handoff:
        return
    selection = json.loads(handoff)
    argv = [sys.argv[0], "materialize"]
    for repo_name in selection["repos"]:
        argv += ["--repo", repo_name]
    subprocess.run(
        [
            "tmux",
            "display-popup",
            "-E",
            "-s",
            "bg=terminal",
            "-w",
            "80",
            "-h",
            "24",
            shlex.join(argv),
        ],
        check=False,
    )


def open_workspace(chain_out: Path | None) -> None:
    workspace_config = config.load()
    work_root = workspace_config.settings.work_root
    discovered = repo.discover(work_root)
    options = repo_lines(
        prioritized(discovered, workspace_config.repos), workspace_config.repos
    )
    selection = ui.pick_multi(options, "Repos ❯ ")
    if not selection:
        return
    repos = sorted({row_name(row) for row in selection})
    missing = [
        str(work_root / repo_name)
        for repo_name in repos
        if not (work_root / repo_name).is_dir()
    ]
    if missing:
        raise WorkspaceError("missing repo directories:\n  " + "\n  ".join(missing))
    if chain_out is not None:
        chain_out.write_text(json.dumps({"repos": repos}))
        return
    materialize_workspace(repos)


def materialize_workspace(repos: list[str]) -> None:
    workspace_config = config.load()
    session_ticket = _resolve_ticket(repos, workspace_config.settings)
    if session_ticket is None:
        return
    session = session_ticket.session_name
    # Checked before prepare_windows: a name tmux rejects would otherwise leave
    # the freshly created branches and worktrees behind.
    tmux.validate_session_name(session)
    specs, failures, warnings = prepare_windows(
        repos, workspace_config, session_ticket, session
    )
    if failures and not specs:
        raise WorkspaceError("no repo could be prepared:\n  " + "\n  ".join(failures))
    skipped = ensure_windows(
        session,
        specs,
        worktree.ticket_dir(workspace_config.settings.work_root, session),
    )
    tmux.set_session_option(session, "@ticket_slug", session_ticket.slug)
    if session_ticket.key is not None:
        tmux.set_session_option(session, "@ticket_key", session_ticket.key)
    tmux.focus_session(session)
    persist.save_state()
    if failures or skipped:
        ui.notice("some repos were skipped:\n  " + "\n  ".join(failures + skipped))
    if warnings:
        ui.notice("\n".join(warnings))

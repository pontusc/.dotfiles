"""Compose a tmux session out of picked repos."""

from __future__ import annotations

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
    agent: list[str] | None


class ComposeResult(NamedTuple):
    skipped: list[str]
    session_live: bool


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


def agent_dir_for(
    settings: config.Settings, session_ticket: ticket.Ticket | None, session: str
) -> Path | None:
    """Where the session's single agent runs, None when each window gets its own."""
    if settings.agent != "session" or session_ticket is None:
        return None
    return worktree.ticket_dir(settings.work_root, session)


class _Resolved(NamedTuple):
    spec: WindowSpec | None
    failure: str | None
    warning: str | None


def _prepare_worktree(
    repo_name: str,
    workspace_config: config.Config,
    branch: str,
    session: str,
    per_window_agent: bool,
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
    agent = None
    if per_window_agent:
        agent = layout.claude_command(f"{session}-{repo_name}", path.parent)
    warning = f"{repo_name}: {', '.join(warnings)}" if warnings else None
    return _Resolved(WindowSpec(repo=repo_name, path=path, agent=agent), None, warning)


def prepare_windows(
    repos: list[str],
    workspace_config: config.Config,
    session_ticket: ticket.Ticket,
    session: str,
    per_window_agent: bool = True,
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
                    per_window_agent,
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
    layout.arrange(window_id, spec.path, spec.agent)


def ensure_windows(
    session: str, specs: list[WindowSpec], agent_dir: Path | None = None
) -> ComposeResult:
    """Open a window per spec in session, reporting the ones left alone.

    With agent_dir the session holds one agent window there, created first so
    it keeps index 1, and only when the session does not have one yet.
    """
    pending: list[WindowSpec] = []
    skipped: list[str] = []
    if agent_dir is not None:
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
        if agent_dir is not None:
            layout.start_agent(
                tmux.start_session(session, layout.AGENT_WINDOW, agent_dir),
                session,
                agent_dir,
            )
        elif pending:
            first = pending[0]
            _configure_window(
                tmux.start_session(session, first.repo, first.path), first
            )
            pending = pending[1:]
        elif skipped:
            return ComposeResult(skipped=skipped, session_live=False)
        else:
            tmux.start_empty_session(session)
    elif (
        agent_dir is not None
        and tmux.find_window_by_name(session, layout.AGENT_WINDOW) is None
    ):
        layout.start_agent(
            tmux.new_window(session, layout.AGENT_WINDOW, agent_dir), session, agent_dir
        )
    for spec in pending:
        _configure_window(tmux.new_window(session, spec.repo, spec.path), spec)
    return ComposeResult(skipped=skipped, session_live=True)


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
    agent_dir = agent_dir_for(workspace_config.settings, session_ticket, session)
    specs, failures, warnings = prepare_windows(
        repos,
        workspace_config,
        session_ticket,
        session,
        per_window_agent=agent_dir is None,
    )
    if failures and not specs:
        raise WorkspaceError("no repo could be prepared:\n  " + "\n  ".join(failures))
    result = ensure_windows(session, specs, agent_dir)
    if result.session_live:
        tmux.set_session_option(session, "@ticket_slug", session_ticket.slug)
        if session_ticket.key is not None:
            tmux.set_session_option(session, "@ticket_key", session_ticket.key)
        tmux.focus_session(session)
        persist.save_state()
    if failures or result.skipped:
        ui.notice(
            "some repos were skipped:\n  " + "\n  ".join(failures + result.skipped)
        )
    if warnings:
        ui.notice("\n".join(warnings))

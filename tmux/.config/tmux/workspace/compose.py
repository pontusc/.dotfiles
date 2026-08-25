"""Compose a tmux session out of picked repos and templates."""

from __future__ import annotations

import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path

import config
import layout
import repo
import ticket
import tmux
import ui
import worktree
from errors import WorkspaceError

_TEMPLATE_PREFIX = "◆ "


@dataclass(frozen=True)
class WindowSpec:
    repo: str
    path: Path
    claude_session: str


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
    return row.removeprefix(_TEMPLATE_PREFIX).split()[0]


def _template_row(name: str, members: Sequence[str]) -> str:
    return f"{_TEMPLATE_PREFIX}{name}  ({', '.join(members)})"


def prepare_windows(
    repos: list[str],
    work_root: Path,
    session_ticket: ticket.Ticket | None,
    session: str,
) -> tuple[list[WindowSpec], list[str]]:
    """Resolve each repo to the path its window opens at, per-repo failures apart."""
    specs: list[WindowSpec] = []
    failures: list[str] = []
    for repo_name in repos:
        repo_root = work_root / repo_name
        claude_session = f"{session}-{repo_name}"
        if session_ticket is None:
            specs.append(
                WindowSpec(
                    repo=repo_name, path=repo_root, claude_session=claude_session
                )
            )
            continue
        branch = session_ticket.branch
        path = worktree.path_for(repo_root, branch)
        if path.is_dir():
            # The path is derived from the branch name, so an existing one is
            # only ours to reuse when it really is that branch's worktree.
            checked_out = worktree.branch_at(path)
            if checked_out != branch:
                failures.append(
                    f"{repo_name}: {path} is on {checked_out or 'no branch'},"
                    f" expected {branch}"
                )
                continue
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            error = worktree.create(repo_root, branch, path)
            if error:
                failures.append(f"{repo_name}: {error}")
                continue
        specs.append(
            WindowSpec(repo=repo_name, path=path, claude_session=claude_session)
        )
    return specs, failures


def _configure_window(window_id: str, spec: WindowSpec) -> None:
    tmux.set_window_option(window_id, "@worktree", str(spec.path))
    layout.arrange(window_id, spec.path, spec.claude_session)


def ensure_windows(session: str, specs: list[WindowSpec]) -> list[str]:
    """Open a window per spec in session, returning the ones left alone."""
    pending: list[WindowSpec] = []
    skipped: list[str] = []
    for spec in specs:
        existing = tmux.find_window_by_worktree(spec.path)
        if existing is None:
            pending.append(spec)
        elif existing.session != session:
            skipped.append(
                f"{spec.repo}: already open in session {existing.session}, left alone"
            )
    if not tmux.session_exists(session):
        if pending:
            first = pending[0]
            _configure_window(
                tmux.start_session(session, first.repo, first.path), first
            )
            pending = pending[1:]
        else:
            tmux.start_empty_session(session)
    for spec in pending:
        _configure_window(tmux.new_window(session, spec.repo, spec.path), spec)
    return skipped


def _session_name(templates: list[str], repos: list[str]) -> str | None:
    if len(templates) == 1:
        return templates[0]
    if len(repos) == 1:
        return repos[0]
    return ui.prompt_line("Session name ❯ ").strip() or None


def _resolve_ticket(
    pattern: re.Pattern[str], prefix: str | None
) -> ticket.Ticket | None:
    raw = ui.prompt_line("Ticket ❯ ").strip()
    key = ticket.parse_key(raw, pattern, prefix) if raw else None
    branch = ui.prompt_line("Branch ❯ ").strip()
    if key is not None:
        if not branch:
            raise WorkspaceError("ticket needs a branch")
        return ticket.Ticket(key=key, slug=branch)
    if not branch:
        return None
    return ticket.Ticket(key=None, slug=branch)


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
    for template_name in selection["templates"]:
        argv += ["--template", template_name]
    subprocess.run(
        ["tmux", "display-popup", "-E", "-w", "64", "-h", "5", shlex.join(argv)],
        check=False,
    )


def open_workspace(chain_out: Path | None) -> None:
    workspace_config = config.load()
    work_root = workspace_config.settings.work_root
    discovered = repo.discover(work_root)
    options = [
        _template_row(name, workspace_config.workspaces[name].repos)
        for name in sorted(workspace_config.workspaces)
    ] + repo_lines(
        prioritized(discovered, workspace_config.repos), workspace_config.repos
    )
    selection = ui.pick_multi(options, "Repos ❯ ")
    if not selection:
        return
    templates: list[str] = []
    picked_repos: set[str] = set()
    for row in selection:
        name = row_name(row)
        if row.startswith(_TEMPLATE_PREFIX) and name in workspace_config.workspaces:
            templates.append(name)
        else:
            picked_repos.add(name)
    repos = sorted(
        picked_repos.union(
            repo_name
            for template_name in templates
            for repo_name in workspace_config.workspaces[template_name].repos
        )
    )
    missing = [
        str(work_root / repo_name)
        for repo_name in repos
        if not (work_root / repo_name).is_dir()
    ]
    if missing:
        raise WorkspaceError("missing repo directories:\n  " + "\n  ".join(missing))
    if chain_out is not None:
        chain_out.write_text(json.dumps({"repos": repos, "templates": templates}))
        return
    materialize_workspace(repos, templates)


def materialize_workspace(repos: list[str], templates: list[str]) -> None:
    workspace_config = config.load()
    work_root = workspace_config.settings.work_root
    session_ticket = _resolve_ticket(
        workspace_config.settings.ticket_pattern,
        workspace_config.settings.ticket_prefix,
    )
    if session_ticket is not None:
        session = session_ticket.session_name
    else:
        session = _session_name(templates, repos)
        if session is None:
            return
    specs, failures = prepare_windows(repos, work_root, session_ticket, session)
    if failures and not specs:
        raise WorkspaceError("no repo could be prepared:\n  " + "\n  ".join(failures))
    skipped = ensure_windows(session, specs)
    if session_ticket is not None:
        tmux.set_session_option(session, "@ticket_slug", session_ticket.slug)
    tmux.focus_session(session)
    if failures or skipped:
        ui.notice("some repos were skipped:\n  " + "\n  ".join(failures + skipped))

"""Read-only views of the catalogue and the sessions the tool has materialized."""

from __future__ import annotations

import compose
import config
import repo
import tmux


def list_workspaces() -> None:
    workspace_config = config.load()
    print("repos:")
    discovered = repo.discover(workspace_config.settings.work_root)
    for line in compose.repo_lines(discovered, workspace_config.repos):
        print(f"  {line}")
    sessions = [
        session
        for session in tmux.list_session_names()
        if tmux.session_worktrees(session)
    ]
    print(f"sessions: {', '.join(sessions) if sessions else '-'}")

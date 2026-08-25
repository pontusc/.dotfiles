---
description: List peer Claude Code sessions related to this worktree, grouped by ticket
disable-model-invocation: true
---

Show the user the current peer Claude Code sessions.

1. Call the ListAgents tool.
2. Read the `[repos]` table of `~/.config/tmux/workspaces.toml` (it maps repo directory name
   to a short description). If the file or the table is missing or unreadable, say so and
   continue without descriptions.
3. Derive this session's ticket key from the current working directory: the first
   substring matching `[A-Z]+-[0-9]+` in the path under `~/Work`, if any.
4. Present the peers as a short table: sessions whose name or path shares this ticket
   key first (with their repo description from `[repos]`), then other sessions in the
   same repo, then omit the rest. Include each session's idle/busy status.
5. Facts only. Do not add guidance about messaging unless the user asks.

# peer-roster

Makes Claude Code sessions in related git worktrees aware of each other. On session start it
injects a roster of peer sessions grouped by ticket key parsed from the worktree path. On
each prompt submit it injects a delta when a peer appears or exits. A `/peers` skill lists
the current roster on demand.

## Layout

```
peer-roster/
├── .claude-plugin/plugin.json
├── hooks/hooks.json
├── scripts/peer-roster.sh
└── skills/peers/SKILL.md
```

## Requirements

The `[repos]` table of the machine-local `~/.config/tmux/workspaces.toml` maps repo directory
name to a short description, used to label peers from other repos. It is not part of this
repo. Reading it needs `python3` 3.11+ on PATH for `tomllib`.

```toml
[repos]
dotfiles = "Personal dotfiles"
billing-service = "Billing microservice"
```

If the file or the table is missing or unreadable, the roster still works, just without
descriptions.

## Install

```
/plugin marketplace add /home/pontusc/dotfiles/claude-plugins
/plugin install peer-roster@dotfiles
```

## Development notes

Plugin files are copied to `~/.claude/plugins/cache` at install time, so editing the repo
copy has no effect until you reinstall. Use `claude --plugin-dir` to run against the repo
copy directly for live testing.

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

A machine-local file at `~/.claude/peers.json` maps repo directory name to a short
description, used to label peers from other repos. It is not part of this repo.

```json
{
  "dotfiles": "Personal dotfiles",
  "billing-service": "Billing microservice"
}
```

If the file is missing or malformed, the roster still works, just without descriptions.

## Install

```
/plugin marketplace add /home/pontusc/dotfiles/claude-plugins
/plugin install peer-roster@dotfiles
```

## Migration from loose hooks

If the SessionStart and UserPromptSubmit entries for `peer-roster.sh` remain in
`claude/.claude/settings.json` while this plugin is installed, both fire and the roster is
duplicated. The swap must be atomic: install the plugin, then delete those hook entries from
`settings.json` and remove `claude/.claude/hooks/peer-roster.sh`.

## Development notes

Plugin files are copied to `~/.claude/plugins/cache` at install time, so editing the repo
copy has no effect until you reinstall. Use `claude --plugin-dir` to run against the repo
copy directly for live testing.

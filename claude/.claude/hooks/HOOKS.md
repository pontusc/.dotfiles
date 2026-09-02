# Hooks

The sandbox is off. These hooks are the guardrails. Registered in `settings.json`, peer roster hooks live in the `peer-roster` plugin.

- `dcg` (PreToolUse, Bash): blocks destructive shell commands. Config in `~/.config/dcg/config.toml`.
- `guard-sensitive.sh` (PreToolUse, Read|Bash|Grep|Glob): blocks reads of secrets, keys, and credentials by path and basename pattern. Never name a hook with a word it blocks, or it blocks itself.
- `notify.sh` (Notification): the only desktop notifier. Permission prompts only, `Stop` is not registered because it fires at every turn end while subagents still run.

Exit 2 blocks with stderr as the message to the agent. Exit 0 passes. Exit 1 is ignored. Blocks do not notify, the agent fixes and retries.

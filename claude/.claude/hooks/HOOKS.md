# Hooks

The sandbox is off. These hooks are the guardrails. Registered in `settings.json`, peer roster hooks live in the `peer-roster` plugin.

- `dcg` (PreToolUse, Bash): blocks destructive shell commands. Config in `~/.config/dcg/config.toml`.
- `guard-sensitive.sh` (PreToolUse, Read|Bash|Grep|Glob): blocks reads of secrets, keys, and credentials by path and basename pattern. Never name a hook with a word it blocks, or it blocks itself.
- `notify.sh` (Notification permission_prompt, Stop, UserPromptSubmit, PostToolUse, PreToolUse AskUserQuestion and ExitPlanMode): sets the tmux window option `@claude` to `ask` or `done`, shown by the powerkit segment and the session picker, cleared on a prompt, an approved tool, or switching to its window. Stops flag only after 60 seconds of work, nothing flags while the pane is watched. Kitty OSC notifications stay filtered in kitty.conf.

Exit 2 blocks with stderr as the message to the agent. Exit 0 passes. Exit 1 is ignored. Blocks do not notify, the agent fixes and retries.

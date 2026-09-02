# Hooks

The sandbox is off. These hooks are the guardrails. Registered in `settings.json`, peer roster hooks live in the `peer-roster` plugin.

- `dcg` (PreToolUse, Bash): blocks destructive shell commands. Config in `~/.config/dcg/config.toml`.
- `guard-sensitive.sh` (PreToolUse, Read|Bash|Grep|Glob): blocks reads of secrets, keys, and credentials by path and basename pattern. Never name a hook with a word it blocks, or it blocks itself.
- `notify.sh` (Notification permission_prompt, Stop, UserPromptSubmit, PostToolUse): the only desktop notifier, kitty's built-in OSC notifications are filtered off in kitty.conf. Permission prompts persist, stops expire, a prompt or approved tool dismisses the popup through quickshell IPC.

Exit 2 blocks with stderr as the message to the agent. Exit 0 passes. Exit 1 is ignored. Blocks do not notify, the agent fixes and retries.

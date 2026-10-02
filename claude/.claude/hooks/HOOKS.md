# Hooks

The sandbox is off, real isolation would be a separate host. Secret files are guarded by the `Read(...)` deny rules in `settings.json`, which cover the Read, Grep and Glob tools, the Edit and Write tools, and reader commands such as cat, sed and head inside Bash. Reads through an interpreter or a redirect are not gated, dcg does not cover them either. These hooks are the remaining guardrails. Registered in `settings.json`.

- `dcg` (PreToolUse, Bash): blocks destructive shell commands. Config in `~/.config/dcg/config.toml`.
- `notify.sh` (Notification permission_prompt, Stop, UserPromptSubmit, PostToolUse, PreToolUse AskUserQuestion and ExitPlanMode): sets the tmux window option `@claude` to `ask` or `done`, shown by the powerkit segment and the session picker, cleared by this hook on a prompt or an approved tool, and by the tmux hooks in tmux.conf when the window gains focus. Stops flag only after 60 seconds of work, nothing flags while the pane is watched. Kitty OSC notifications stay filtered in kitty.conf.
- `markdown-punctuation.sh` (PostToolUse, Edit and Write): reports semicolons, em and en dashes and a spaced single or double hyphen in markdown lines outside fenced code. On Edit only lines overlapping the new text are reported. The write has already landed, the agent fixes the reported lines.

Exit 2 blocks with stderr as the message to the agent, on PostToolUse it only feeds the message back. Exit 0 passes. Exit 1 is ignored. Blocks do not notify, the agent fixes and retries.

# Hooks

The sandbox is off, real isolation would be a separate host. Secret files are guarded by the `Read(...)` deny rules in `settings.json`, which cover the Read, Grep and Glob tools, the Edit and Write tools, and reader commands such as cat, sed and head inside Bash. Reads through an interpreter or a redirect are not gated, dcg does not cover them either. These hooks are the remaining guardrails. Registered in `settings.json`.

- `dcg` (PreToolUse, Bash): blocks destructive shell commands. Config in `~/.config/dcg/config.toml`.
- `markdown-punctuation.sh` (PostToolUse, Edit and Write): reports semicolons, em and en dashes and a spaced single or double hyphen in markdown lines outside fenced code. On Edit only lines overlapping the new text are reported. The write has already landed, the agent fixes the reported lines.

Exit 2 blocks with stderr as the message to the agent, on PostToolUse it only feeds the message back. Exit 0 passes. Exit 1 is ignored. Blocks do not notify, the agent fixes and retries.

`~/.claude/skills/shell-guard` is a mod on `tool.call` for Bash. It runs above dcg, so its deny ends the call before dcg sees it.

`~/.claude/skills/tmux-attention` is a mod, not a settings hook. It sets the tmux window option `@claude` to `ask` or `done` for the powerkit segment and the session picker, the focus hooks in tmux.conf clear it, and Kitty OSC notifications stay filtered in kitty.conf.

- Mods must hook native events. The builtin cc-plugin-sec-default skips user tier mods on every classic event.
- A permission ask flags before the mode settles it, so in auto mode a call the classifier approves shows `ask` until the tool finishes.
- A session that started with the mods rollout switch served off loads no mod and sets no flags.
- The editor types come from `.claude-plugin/types`, which a session writes when it loads the mod. On a fresh clone start one session before opening the mod in an editor.

# Hooks

The sandbox is off, real isolation would be a separate host. Secret files are guarded by the `Read(...)` deny rules in `settings.json`, which cover the Read, Grep and Glob tools, the Edit and Write tools, reader commands such as cat, sed and head inside Bash, and redirect targets. A read that never names the file, such as `grep -r` from a parent directory, or one done by an interpreter script, is not gated, and dcg does not cover it either. These hooks are the remaining guardrails. Registered in `settings.json`.

- `dcg` (PreToolUse, Bash): blocks destructive shell commands. Config in `~/.config/dcg/config.toml`.
- `markdown-punctuation.sh` (PostToolUse, Edit and Write): reports semicolons, em and en dashes and a spaced single or double hyphen in markdown lines outside fenced code, skipping scratch and job paths. On Edit only lines overlapping the new text are reported. The write has already landed, the agent fixes the reported lines.
- `permission-attention.sh` (PermissionRequest): sets `@claude ask` on an unwatched tmux window while a permission dialog waits. The tmux.conf focus hooks clear it.

Exit 2 blocks with stderr as the message to the agent, on PostToolUse it only feeds the message back. Exit 0 passes. Exit 1 is ignored. Blocks do not notify, the agent fixes and retries.

Mods are convenience, a session can start without them. A guarantee lives in dcg or the deny list, never only in a mod.

`~/.claude/skills/shell-guard` is a mod on `tool.call` for Bash. It runs above dcg, so its deny ends the call before dcg sees it.

`~/.claude/skills/context-handoff` is a mod on `turn.step`. It only appends a note the model reads and toasts the user, it never blocks a turn.

`~/.claude/skills/dcg-approve` is a mod on `tool.call` and `turn.complete`. It reads the code from dcg's `approve it with: dcg allow-once <code>` denial line, a dcg wording change silently stops the suggestion.

`~/.claude/skills/tmux-attention` is a mod, not a settings hook. It sets the tmux window option `@claude` to `ask` or `done` for the powerkit segment and the session picker, the focus hooks in tmux.conf clear it, and Kitty OSC notifications stay filtered in kitty.conf.

- Mods must hook native events. The builtin cc-plugin-sec-default skips user tier mods on every classic event.
- A mod cannot see a permission dialog. `tool.check` answers `ask` for nearly every auto mode Bash and Agent call.
- `done` ignores background Bash and Monitor tasks, `$.agent.list()` holds only agents.
- A session that started with the mods rollout switch served off loads no mod and sets no flags.
- The editor types for every mod come from `tmux-attention/.claude-plugin/types`, which a session writes when it loads that mod. On a fresh clone start one session before opening a mod in an editor.

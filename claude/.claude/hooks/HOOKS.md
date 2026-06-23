# Claude Code Hooks

## Architecture

Hooks are shell scripts that run at lifecycle points in Claude Code tool calls.
Security is enforced via hooks rather than sandbox — the sandbox is disabled.

### Hook Types

| Event       | When                 | Exit 0       | Exit 2                                                 |
| ----------- | -------------------- | ------------ | ------------------------------------------------------ |
| PreToolUse  | Before tool executes | Allow        | Block (stderr sent to agent)                           |
| PostToolUse | After tool executes  | Pass through | Tool already ran; stderr shown, agent fixes & retries  |

### Active Hooks

| Hook                 | Event              | Matcher                  | Purpose                                          |
| -------------------- | ------------------ | ------------------------ | ------------------------------------------------ |
| `notify.sh`          | Notification, Stop | —                        | Single entry point for all desktop notifications |
| `guard-sensitive.sh` | PreToolUse         | `Read\|Bash\|Grep\|Glob` | Blocks access to sensitive files/dirs            |
| `format-and-lint.sh` | PostToolUse        | `Write\|Edit`            | Lints written files                              |
| `dcg` (binary)       | PreToolUse         | `Bash`                   | Blocks destructive shell commands                |

## Design Rules

### Exit Codes

- `0` — allow / pass
- `2` — block (PreToolUse) / feedback (PostToolUse, can't block — tool already ran). Only **stderr** is sent to the agent; stdout and JSON are ignored on exit 2
- `1` — avoid (ignored by Claude Code, neither blocks nor provides feedback)

### Input

Hooks receive JSON on stdin with `tool_name`, `tool_input`, and (PostToolUse only) `tool_output`.
Parse with `jq`. Always guard with `// empty` to handle missing fields.

### Notifications

`notify.sh` is registered for Claude Code `Notification` and `Stop` events only.
It surfaces attention-required events: permission prompts and task completion.

PreToolUse blocks (guard-sensitive, dcg) and PostToolUse lint failures do NOT
notify — they return `exit 2` with details on stderr, and the agent fixes and
retries on its own. Surfacing them would be noise.

Never call `notify-send` directly from a hook. If you need to add a new
attention event, route it through `notify.sh` and add a case branch there.

### Tool Resolution

Prefer Mason-installed binaries (`~/.local/share/nvim/mason/bin/`) for linters
to stay in sync with Neovim. Fall back to PATH. Missing tools should
soft-fail (warn, don't block) unless the tool is the linter itself.

### Self-Protection

Filenames matter — `guard-sensitive.sh` uses basename pattern matching (`*secret*`,
`*credentials*`). Avoid naming hooks with words that match blocked patterns, or
they will block reads of themselves and prevent the agent from editing them.

### Adding a New Hook

1. Write the script in `~/.claude/hooks/`
2. Register it in `~/.claude/settings.json` under `hooks.PreToolUse` or `hooks.PostToolUse`
3. Set the `matcher` to the tool names it should intercept (pipe-delimited: `Read|Bash|Grep`)
4. Pipe JSON to `notify.sh` for blocks/failures — never call `notify-send` directly
5. Use `set -euo pipefail` and parse stdin JSON with `jq`

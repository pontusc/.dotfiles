# Claude Code Hooks

## Architecture

Hooks are shell scripts that run at lifecycle points in Claude Code tool calls.
Security is enforced via hooks rather than sandbox — the sandbox is disabled.

### Hook Types

| Event | When | Exit 0 | Exit 2 |
|---|---|---|---|
| PreToolUse | Before tool executes | Allow | Block (error sent to agent) |
| PostToolUse | After tool executes | Pass through | Agent must fix and retry |

### Active Hooks

| Hook | Event | Matcher | Purpose |
|---|---|---|---|
| `guard-sensitive.sh` | PreToolUse | `Read\|Bash\|Grep\|Glob` | Blocks access to sensitive files/dirs |
| `format-and-lint.sh` | PostToolUse | `Write\|Edit` | Formats then lints written files |
| `dcg` (binary) | PreToolUse | `Bash` | Blocks destructive shell commands |

## Design Rules

### Exit Codes
- `0` — allow / pass
- `2` — block (stderr + stdout sent to agent as error)
- `1` — avoid (ignored by Claude Code, neither blocks nor provides feedback)

### Input
Hooks receive JSON on stdin with `tool_name`, `tool_input`, and (PostToolUse only) `tool_response`.
Parse with `jq`. Always guard with `// empty` to handle missing fields.

### Notifications
Hooks must send `notify-send` only on blocks and failures — never on success.
The user should see nothing when things work correctly.

```bash
# Blocked — critical, persistent notification
notify-send -u critical -a "Claude Code" \
  "hook-name: BLOCKED $TOOL" \
  "$FILE\nRule: $MATCH" 2>/dev/null || true

# Lint failure — normal urgency
notify-send -u normal -a "Claude Code" \
  "hook-name: FAILED" \
  "$FILE\nDetails" 2>/dev/null || true
```

Always append `2>/dev/null || true` so a missing `notify-send` never breaks the hook.

### Tool Resolution
Prefer Mason-installed binaries (`~/.local/share/nvim/mason/bin/`) for formatters
and linters to stay in sync with Neovim. Fall back to PATH. Missing tools should
soft-fail (warn, don't block) unless the tool is the linter itself.

### Self-Protection
Filenames matter — `guard-sensitive.sh` uses basename pattern matching (`*secret*`,
`*credentials*`). Avoid naming hooks with words that match blocked patterns, or
they will block reads of themselves and prevent the agent from editing them.

### Adding a New Hook
1. Write the script in `~/.claude/hooks/`
2. Register it in `~/.claude/settings.json` under `hooks.PreToolUse` or `hooks.PostToolUse`
3. Set the `matcher` to the tool names it should intercept (pipe-delimited: `Read|Bash|Grep`)
4. Include `notify-send` for blocks/failures only
5. Use `set -euo pipefail` and parse stdin JSON with `jq`

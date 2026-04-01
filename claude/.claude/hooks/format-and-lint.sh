#!/usr/bin/env bash
# format-and-lint — Claude Code PostToolUse hook (matcher: Write|Edit)
#
# ── How this connects to Claude Code ──────────────────────────────────────────
#
# Registered in ~/.claude/settings.json under hooks.PostToolUse with
# matcher "Write|Edit". Claude Code invokes this script AFTER every
# Write or Edit tool call. The script receives a JSON payload on stdin
# containing tool_name, tool_input (with file_path), and tool_response.
#
# Exit code contract:
#   0  → allow (tool result returned to agent normally)
#   2  → block  (stderr + stdout fed back to the agent as an error;
#                the agent must fix the issue and retry)
#   1  → ignored by Claude Code (does NOT block), avoid using
#
# Flow: formatter runs in-place on the written file → linter validates →
#       exit 0 on success, exit 2 with lint errors on failure so the
#       agent sees them and can self-correct.
#
# ── Tool resolution: Mason vs PATH ───────────────────────────────────────────
#
# Neovim's Mason package manager installs LSP servers, formatters, and
# linters into ~/.local/share/nvim/mason/bin/. This gives us a single
# managed toolchain shared between the editor and this hook — no version
# drift between what Neovim formats and what this hook checks.
#
# Resolution order:  Mason bin → system PATH → skip (soft fail)
# Missing formatter: warn on stderr, continue (formatting is best-effort)
# Missing linter:    warn on stderr, exit 0 (cannot block without a tool)
#
# ── Adding a new language ─────────────────────────────────────────────────────
#
# 1. Add a case branch matching the file extension(s)
# 2. Call run_fmt with the formatter name and flags (in-place write mode)
# 3. Call run_lint with the linter name and flags, capture into LINT_OUTPUT
# 4. If the linter needs a config file, pass it explicitly (see yml example)
# 5. Ensure both tools are installed via Mason (:MasonInstall <name>)
#
# ── Supported languages ──────────────────────────────────────────────────────
#
# Extension(s)   │ Formatter          │ Linter       │ Config
# ───────────────┼────────────────────┼──────────────┼──────────────────────
# .py            │ ruff format        │ ruff check   │ pyproject.toml
# .sh .bash .zsh │ shfmt -sr -w       │ shellcheck   │ —
# .yml .yaml     │ yamlfmt            │ yamllint     │ ~/.config/yamlfmt/
#                │                    │              │ ~/.config/yamllint/
# .yml .yaml     │ yamlfmt            │ yamllint +   │ (only .github/workflows/)
#  (GH Actions)  │                    │ actionlint   │
# .tf .tfvars    │ terraform fmt      │ —            │ —
# .hcl           │ terraform fmt      │ —            │ —
# .toml          │ taplo fmt          │ taplo lint   │ taplo.toml / .taplo.toml
# .json          │ prettier --write   │ jsonlint     │ —
# .js .ts .jsx   │ prettier --write   │ eslint_d     │ —
#   .tsx .mjs .cjs│                   │              │
# .md            │ prettier --write   │ —            │ —
# .go            │ gofmt              │ golangci-lint│ —
# .lua           │ stylua             │ —            │ stylua.toml
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

INPUT=$(cat)

# Guard: only process Write/Edit tool calls
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
[[ "$TOOL" == "Write" || "$TOOL" == "Edit" ]] || exit 0

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -n "$FILE" && -f "$FILE" ]] || exit 0

EXT="${FILE##*.}"

# ── Tool resolution ──────────────────────────────────────────────────────────
# Returns the absolute path to the tool binary, preferring Mason-installed
# versions to keep parity with Neovim's formatting. Returns empty string
# if the tool is not available anywhere.
mason_bin() {
  local name="$1"
  local mason="$HOME/.local/share/nvim/mason/bin/$name"
  if [[ -x "$mason" ]]; then
    echo "$mason"
  elif command -v "$name" &> /dev/null; then
    echo "$name"
  else
    echo ""
  fi
}

# Run a formatter in-place. Failure is non-fatal — formatting is best-effort
# so a missing formatter never blocks the agent.
run_fmt() {
  local fmt="$1"
  shift
  local tool
  tool=$(mason_bin "$fmt")
  if [[ -z "$tool" ]]; then
    echo "format-and-lint: formatter '$fmt' not found (Mason or PATH), skipping format" >&2
    return 0
  fi
  "$tool" "$@"
}

# Run a linter and capture output. Returns the linter's exit code so the
# caller can decide whether to block. A missing linter exits 0 (we cannot
# validate without the tool, so we let the write through).
run_lint() {
  local linter="$1"
  shift
  local tool
  tool=$(mason_bin "$linter")
  if [[ -z "$tool" ]]; then
    echo "format-and-lint: linter '$linter' not found (Mason or PATH)" >&2
    return 0
  fi
  local output
  if output=$("$tool" "$@" 2>&1); then
    return 0
  else
    echo "$output"
    return 1
  fi
}

# ── Path-based overrides ─────────────────────────────────────────────────────
# Some filetypes share an extension but need different linters based on path.
IS_GHACTION=false
if [[ "$FILE" == */.github/workflows/*.yml || "$FILE" == */.github/workflows/*.yaml ]]; then
  IS_GHACTION=true
fi

# ── Per-language dispatch ────────────────────────────────────────────────────
# Each branch: format in-place first, then lint the result.
# Formatter errors are swallowed (|| true) — we only block on lint failures.
LINT_OUTPUT=""
LINT_RC=0

case "$EXT" in
py)
  run_fmt ruff format "$FILE" 2> /dev/null || true
  LINT_OUTPUT=$(run_lint ruff check "$FILE") || LINT_RC=$?
  ;;
sh | bash | zsh)
  run_fmt shfmt -i 2 -sr -w "$FILE" 2> /dev/null || true
  LINT_OUTPUT=$(run_lint shellcheck "$FILE") || LINT_RC=$?
  ;;
yml | yaml)
  run_fmt yamlfmt -conf "$HOME/.config/yamlfmt/yamlfmt.yml" "$FILE" 2> /dev/null || true
  LINT_OUTPUT=$(run_lint yamllint -c "$HOME/.config/yamllint/config" "$FILE") || LINT_RC=$?
  if [[ "$IS_GHACTION" == true && "$LINT_RC" -eq 0 ]]; then
    LINT_OUTPUT=$(run_lint actionlint "$FILE") || LINT_RC=$?
  fi
  ;;
tf | tfvars | hcl)
  if formatted=$(terraform fmt - < "$FILE" 2> /dev/null); then
    printf '%s' "$formatted" > "$FILE"
  fi
  ;;
js | ts | jsx | tsx | mjs | cjs)
  run_fmt prettier --write "$FILE" 2> /dev/null || true
  LINT_OUTPUT=$(run_lint eslint_d "$FILE") || LINT_RC=$?
  ;;
md)
  run_fmt prettier --write "$FILE" 2> /dev/null || true
  ;;
go)
  if formatted=$(gofmt "$FILE" 2> /dev/null); then
    printf '%s' "$formatted" > "$FILE"
  fi
  LINT_OUTPUT=$(run_lint golangci-lint run "$FILE") || LINT_RC=$?
  ;;
lua)
  run_fmt stylua "$FILE" 2> /dev/null || true
  ;;
toml)
  run_fmt taplo fmt "$FILE" 2> /dev/null || true
  LINT_OUTPUT=$(run_lint taplo lint "$FILE") || LINT_RC=$?
  ;;
json)
  run_fmt prettier --write "$FILE" 2> /dev/null || true
  LINT_OUTPUT=$(run_lint jsonlint "$FILE") || LINT_RC=$?
  ;;
*)
  exit 0
  ;;
esac

# ── Result ───────────────────────────────────────────────────────────────────
if [[ "$LINT_RC" -ne 0 ]]; then
  jq -n \
    --arg type "hook_failure" \
    --arg title "format-and-lint: FAILED" \
    --arg message "$FILE\nLint errors found" \
    '{notification_type: $type, title: $title, message: $message}' |
    /home/pontusc/.claude/hooks/notify.sh || true
  echo "format-and-lint: lint failed for $FILE" >&2
  echo "$LINT_OUTPUT" >&2
  echo ""
  echo "Fix the lint errors above before this file can be written."
  exit 2
fi

echo "format-and-lint: $FILE passed (formatted + linted)"
exit 0

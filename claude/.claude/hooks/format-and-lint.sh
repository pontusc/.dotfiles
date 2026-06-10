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
# LINT-ONLY: this hook never rewrites files. Formatting belongs to the
# author/editor; the hook only validates and blocks (exit 2) on lint
# errors so the agent can self-correct.
#
# ── Tool resolution: Mason vs PATH ───────────────────────────────────────────
#
# Neovim's Mason package manager installs linters into
# ~/.local/share/nvim/mason/bin/ — a single managed toolchain shared
# between the editor and this hook, no version drift.
#
# Resolution order:  Mason bin → system PATH → skip (soft fail)
# Missing linter:    warn on stderr, exit 0 (cannot block without a tool)
#
# ── Adding a new language ─────────────────────────────────────────────────────
#
# 1. Add a case branch matching the file extension(s)
# 2. Call run_lint with the linter name and flags, capture into LINT_OUTPUT
# 3. If the linter needs a config file, pass it explicitly (see yml example)
# 4. Ensure the tool is installed via Mason (:MasonInstall <name>)
#
# ── Supported languages ──────────────────────────────────────────────────────
#
# Extension(s)     │ Linter         │ Config
# ─────────────────┼────────────────┼──────────────────────
# .py              │ ruff check     │ pyproject.toml
# .sh .bash .zsh   │ shellcheck     │ —
# .yml .yaml       │ yamllint       │ ~/.config/yamllint/config
#  (GH Actions)    │ + actionlint   │ (only .github/workflows/)
# .js .ts .jsx     │ eslint_d       │ —
#   .tsx .mjs .cjs │                │
# .go              │ golangci-lint  │ —
# .toml            │ taplo lint     │ taplo.toml / .taplo.toml
# .json            │ jsonlint       │ —
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
# versions to keep parity with Neovim. Returns empty string if the tool is
# not available anywhere.
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
LINT_OUTPUT=""
LINT_RC=0

case "$EXT" in
py)
  LINT_OUTPUT=$(run_lint ruff check "$FILE") || LINT_RC=$?
  ;;
sh | bash | zsh)
  LINT_OUTPUT=$(run_lint shellcheck "$FILE") || LINT_RC=$?
  ;;
yml | yaml)
  LINT_OUTPUT=$(run_lint yamllint -c "$HOME/.config/yamllint/config" "$FILE") || LINT_RC=$?
  if [[ "$IS_GHACTION" == true && "$LINT_RC" -eq 0 ]]; then
    LINT_OUTPUT=$(run_lint actionlint "$FILE") || LINT_RC=$?
  fi
  ;;
js | ts | jsx | tsx | mjs | cjs)
  LINT_OUTPUT=$(run_lint eslint_d "$FILE") || LINT_RC=$?
  ;;
go)
  # golangci-lint operates on packages, not single files — run from the file's dir
  GOLANGCI=$(mason_bin golangci-lint)
  if [[ -n "$GOLANGCI" ]]; then
    LINT_OUTPUT=$(cd "$(dirname "$FILE")" && "$GOLANGCI" run ./... 2>&1) || LINT_RC=$?
  else
    echo "format-and-lint: linter 'golangci-lint' not found (Mason or PATH)" >&2
  fi
  ;;
toml)
  LINT_OUTPUT=$(run_lint taplo lint "$FILE") || LINT_RC=$?
  ;;
json)
  LINT_OUTPUT=$(run_lint jsonlint "$FILE") || LINT_RC=$?
  ;;
*)
  exit 0
  ;;
esac

# ── Result ───────────────────────────────────────────────────────────────────
if [[ "$LINT_RC" -ne 0 ]]; then
  echo "format-and-lint: lint failed for $FILE" >&2
  echo "$LINT_OUTPUT" >&2
  echo ""
  echo "Fix the lint errors above before this file can be written."
  exit 2
fi

echo "format-and-lint: $FILE passed (lint)"
exit 0

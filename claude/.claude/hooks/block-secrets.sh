#!/usr/bin/env bash
# block-secrets — Claude Code PreToolUse hook (matcher: Read|Bash)
#
# ── Purpose ────────────────────────────────────────────────────────────────────
#
# Prevents the agent from reading files that may contain secrets, keys, or
# credentials. Intercepts Read tool calls and Bash commands (cat, head, tail,
# less, more) before execution, checks the target file path against a set of
# blocked patterns, and exits 2 to block if matched.
#
# ── Blocked patterns ──────────────────────────────────────────────────────────
#
# Files:
#   .env, .env.*, .env.local, etc.
#   *.pem, *.key, *.pfx, *.p12
#   *credentials*, *secret*
#   id_rsa, id_ed25519, id_ecdsa, id_dsa
#
# Directories (any file inside):
#   .secret/    — project-level secret stores
#   .ssh/       — SSH keys and config
#   .kube/      — Kubernetes credentials
#   .talos/     — Talos machine configs
#
# ── Exit codes ────────────────────────────────────────────────────────────────
#
#   0  → allow (file is not a secret)
#   2  → block (file matches a secret pattern; error shown to agent)
#
# ── Registration ──────────────────────────────────────────────────────────────
#
# Registered in ~/.claude/settings.json under hooks.PreToolUse with
# matcher "Read|Bash".

set -euo pipefail

INPUT=$(cat)

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# ── Extract file path based on tool type ──────────────────────────────────────
FILE=""
case "$TOOL" in
  Read)
    FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    ;;
  Bash)
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
    # Match common read commands and extract the last argument as file path.
    # Handles: cat FILE, head FILE, tail FILE, less FILE, more FILE
    # Also handles flags: cat -n FILE, head -20 FILE, tail -f FILE
    if [[ "$CMD" =~ ^(cat|head|tail|less|more)([[:space:]]|$) ]]; then
      # Extract last non-flag argument (simple heuristic: last word not starting with -)
      FILE=$(echo "$CMD" | awk '{for(i=NF;i>1;i--) if($i !~ /^-/) {print $i; exit}}')
    else
      # Not a read command — allow
      exit 0
    fi
    ;;
  *)
    exit 0
    ;;
esac

[[ -n "$FILE" ]] || exit 0

# Resolve to absolute path for consistent matching
if [[ "$FILE" != /* ]]; then
  FILE="$(pwd)/$FILE"
fi

# ── Basename and directory checks ─────────────────────────────────────────────
BASENAME=$(basename "$FILE")
DIRPATH="$FILE"

# Check if file is inside a blocked directory
is_blocked_dir() {
  case "$DIRPATH" in
    */.secret/* | */.ssh/* | */.kube/* | */.talos/*) return 0 ;;
    *) return 1 ;;
  esac
}

# Check if filename matches a blocked pattern
is_blocked_file() {
  case "$BASENAME" in
    .env | .env.*) return 0 ;;
    *.pem | *.key | *.pfx | *.p12) return 0 ;;
    *credentials* | *secret*) return 0 ;;
    id_rsa | id_ed25519 | id_ecdsa | id_dsa) return 0 ;;
    id_rsa.pub | id_ed25519.pub | id_ecdsa.pub | id_dsa.pub) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Decision ──────────────────────────────────────────────────────────────────
if is_blocked_dir || is_blocked_file; then
  echo "block-secrets: blocked read of $FILE" >&2
  echo ""
  echo "Access denied: this file may contain secrets and cannot be read."
  exit 2
fi

exit 0

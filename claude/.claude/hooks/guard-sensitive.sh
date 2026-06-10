#!/usr/bin/env bash
# guard-sensitive — Claude Code PreToolUse hook (matcher: Read|Bash|Grep|Glob)
#
# ── Purpose ────────────────────────────────────────────────────────────────────
#
# Prevents the agent from accessing files that may contain secrets, keys, or
# credentials. Intercepts Read, Grep, Glob, and Bash commands (cat, head, tail,
# less, more) before execution, checks the target file path against a set of
# blocked patterns, and exits 2 to block if matched.
#
# ── Blocked patterns ──────────────────────────────────────────────────────────
#
# Files:
#   .env, .env.*, .env.local, etc.
#   *.pem, *.key, *.pfx, *.p12, *.gpg, *.age
#   *credentials*, *secret*
#   id_rsa, id_ed25519, id_ecdsa, id_dsa (+ .pub variants)
#   authorized_keys
#   *.tfstate, *.tfstate.backup
#   *kubeconfig*
#   .npmrc, .netrc — auth tokens / FTP-HTTP credentials
#
# Directories (any file inside):
#   .secret/    — project-level secret stores
#   .ssh/       — SSH keys and config
#   .kube/      — Kubernetes credentials
#   .talos/     — Talos machine configs
#   .gnupg/     — GPG keyrings
#   .aws/       — AWS credentials and config
#   .terragrunt-cache/ — generated files (never edit)
#
# ── Exit codes ────────────────────────────────────────────────────────────────
#
#   0  → allow (file is not a secret)
#   2  → block (file matches a secret pattern; error shown to agent)
#
# ── Registration ──────────────────────────────────────────────────────────────
#
# Registered in ~/.claude/settings.json under hooks.PreToolUse with
# matcher "Read|Bash|Grep|Glob".

set -euo pipefail

INPUT=$(cat)

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# ── Extract file path based on tool type ──────────────────────────────────────
FILE=""
case "$TOOL" in
Read)
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  ;;
Grep)
  FILE=$(echo "$INPUT" | jq -r '.tool_input.path // empty')
  ;;
Glob)
  # Glob passes a path (directory to search in) — block discovery in sensitive dirs
  FILE=$(echo "$INPUT" | jq -r '.tool_input.path // empty')
  # Also check the pattern itself for sensitive directory references
  if [[ -z "$FILE" ]]; then
    PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // empty')
    # Extract directory prefix from glob patterns like /home/user/.ssh/**/*
    FILE=$(echo "$PATTERN" | sed -n 's|\(/[^*?{}\[]*\).*|\1|p')
  fi
  ;;
Bash)
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  [[ -n "$CMD" ]] || exit 0

  # Scan the FULL command string for any reference to a forbidden path or
  # filename. Catches reads via any tool: sed, awk, cp, python, tar,
  # redirection (`< .env`), heredocs, etc. — not just the cat/head/tail
  # family that the old whitelist covered.
  #
  # Boundary classes (L = before, R = after) ensure 'process.env.FOO' is NOT
  # matched (preceded by 's' — alphanumeric, not a boundary), while
  # 'cat .env', '/etc/.env', '--file=.env' ARE.
  # Boundary chars: start/end of string, whitespace, < > | & ; = , ( ) " ' / \
  # (Square brackets are intentionally excluded — Rust regex rejects POSIX's
  # "first ] is literal" trick, and shell rarely places tokens adjacent to [].)
  # Backslash is included to catch escape-quoted paths like .env\" inside
  # nested strings (e.g. python -c "open(\"/etc/.env\")").
  L='(^|[[:space:]<>|&;=,(/\\"'\''])'
  R='($|[[:space:]<>|&;=,)/\\"'\''])'

  PATTERNS=(
    "${L}\.ssh/"
    "${L}\.kube/"
    "${L}\.talos/"
    "${L}\.gnupg/"
    "${L}\.aws/"
    "${L}\.secret/"
    "${L}\.terragrunt-cache/"
    "${L}\.env(\.[A-Za-z0-9_-]+)?${R}"
    "${L}\.npmrc${R}"
    "${L}\.netrc${R}"
    "${L}id_(rsa|ed25519|ecdsa|dsa)(\.pub)?${R}"
    "${L}authorized_keys${R}"
    "${L}[^[:space:]]*\.tfstate(\.backup)?${R}"
    "${L}[^[:space:]]*kubeconfig[^[:space:]]*${R}"
    "${L}[^[:space:]]*credentials[^[:space:]]*\.[A-Za-z0-9_-]{1,12}${R}"
    "${L}[^[:space:]]*\.(pem|key|pfx|p12|gpg|age)${R}"
  )
  LABELS=(
    ".ssh/ directory"
    ".kube/ directory"
    ".talos/ directory"
    ".gnupg/ directory"
    ".aws/ directory"
    ".secret/ directory"
    ".terragrunt-cache/ (generated)"
    ".env file"
    ".npmrc"
    ".netrc"
    "SSH key"
    "authorized_keys"
    "Terraform state"
    "kubeconfig"
    "credentials file"
    "certificate/key extension"
  )

  # ripgrep if present (faster, consistent regex), else grep -E.
  if command -v rg > /dev/null 2>&1; then
    SCAN=(rg -q -e)
  else
    SCAN=(grep -Eq -e)
  fi

  for i in "${!PATTERNS[@]}"; do
    if printf '%s' "$CMD" | "${SCAN[@]}" "${PATTERNS[$i]}"; then
      LABEL="${LABELS[$i]}"
      echo "guard-sensitive [Bash]: BLOCKED command" >&2
      echo "  matched: $LABEL" >&2
      echo ""
      echo "Access denied: this command references a path that may contain secrets."
      echo "Command: $CMD"
      echo "Rule: $LABEL"
      exit 2
    fi
  done

  exit 0
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
  */.secret | */.secret/*)
    echo "directory rule: .secret/"
    return 0
    ;;
  */.ssh | */.ssh/*)
    echo "directory rule: .ssh/"
    return 0
    ;;
  */.kube | */.kube/*)
    echo "directory rule: .kube/"
    return 0
    ;;
  */.talos | */.talos/*)
    echo "directory rule: .talos/"
    return 0
    ;;
  */.gnupg | */.gnupg/*)
    echo "directory rule: .gnupg/"
    return 0
    ;;
  */.aws | */.aws/*)
    echo "directory rule: .aws/"
    return 0
    ;;
  */.terragrunt-cache | */.terragrunt-cache/*)
    echo "directory rule: .terragrunt-cache/ (generated)"
    return 0
    ;;
  *) return 1 ;;
  esac
}

# Check if filename matches a blocked pattern
is_blocked_file() {
  case "$BASENAME" in
  .env | .env.*)
    echo "file rule: .env*"
    return 0
    ;;
  *.pem | *.key | *.pfx | *.p12)
    echo "file rule: certificate/key extension"
    return 0
    ;;
  *.gpg | *.age)
    echo "file rule: encrypted file"
    return 0
    ;;
  *credentials*)
    echo "file rule: credentials in name"
    return 0
    ;;
  *kubeconfig*)
    echo "file rule: kubeconfig"
    return 0
    ;;
  *.tfstate | *.tfstate.backup)
    echo "file rule: Terraform state (contains secrets)"
    return 0
    ;;
  authorized_keys)
    echo "file rule: SSH authorized_keys"
    return 0
    ;;
  .npmrc)
    echo "file rule: .npmrc (auth tokens)"
    return 0
    ;;
  .netrc)
    echo "file rule: .netrc (HTTP/FTP credentials)"
    return 0
    ;;
  id_rsa | id_ed25519 | id_ecdsa | id_dsa)
    echo "file rule: SSH private key"
    return 0
    ;;
  id_rsa.pub | id_ed25519.pub | id_ecdsa.pub | id_dsa.pub)
    echo "file rule: SSH public key"
    return 0
    ;;
  *) return 1 ;;
  esac
}

# ── Decision ──────────────────────────────────────────────────────────────────
MATCH=""
MATCH=$(is_blocked_dir) || MATCH=$(is_blocked_file) || true

if [[ -n "$MATCH" ]]; then
  echo "guard-sensitive [$TOOL]: BLOCKED $FILE" >&2
  echo "  matched: $MATCH" >&2
  echo ""
  echo "Access denied: this file may contain secrets and cannot be read."
  echo "Tool: $TOOL | File: $FILE | Rule: $MATCH"
  exit 2
fi

exit 0

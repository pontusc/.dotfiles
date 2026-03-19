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
#
# Directories (any file inside):
#   .secret/    — project-level secret stores
#   .ssh/       — SSH keys and config
#   .kube/      — Kubernetes credentials
#   .talos/     — Talos machine configs
#   .gnupg/     — GPG keyrings
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
	*credentials* | *secret*)
		echo "file rule: credentials/secret in name"
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
	jq -n \
		--arg type "hook_block" \
		--arg title "guard-sensitive: BLOCKED $TOOL" \
		--arg message "$FILE\nRule: $MATCH" \
		'{notification_type: $type, title: $title, message: $message}' |
		/home/pontusc/.claude/hooks/notify.sh || true
	echo "guard-sensitive [$TOOL]: BLOCKED $FILE" >&2
	echo "  matched: $MATCH" >&2
	echo ""
	echo "Access denied: this file may contain secrets and cannot be read."
	echo "Tool: $TOOL | File: $FILE | Rule: $MATCH"
	exit 2
fi

exit 0

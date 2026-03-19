#!/usr/bin/env bash
# notify — Claude Code Notification hook + internal notification helper
#
# ── Purpose ────────────────────────────────────────────────────────────────────
#
# Single entry point for all desktop notifications. Registered as a
# Notification hook so Claude Code routes system events (permission prompts,
# idle, etc.) here. Internal hooks (guard-sensitive, format-and-lint) also
# pipe JSON to this script so all notify-send calls live in one place.
#
# ── Input ─────────────────────────────────────────────────────────────────────
#
# JSON on stdin with fields:
#   notification_type  — see urgency mapping below
#   message            — notification body (required, exits 0 if empty)
#   title              — notification title (default: "Claude Code")
#
# ── Urgency mapping ───────────────────────────────────────────────────────────
#
#   hook_block         → normal     (guard-sensitive / dcg blocked a tool call)
#   hook_failure       → normal     (format-and-lint lint failure)
#   permission_prompt  → normal     (Claude needs user approval)
#   elicitation_dialog → normal     (MCP server needs user input)
#   idle_prompt        → low        (Claude finished, waiting for input)
#   auth_success       → suppressed (success — never notify on success)
#   *                  → normal
#
# ── Registration ──────────────────────────────────────────────────────────────
#
# Registered in ~/.claude/settings.json under hooks.Notification (no matcher).
# Internal hooks call it directly: ... | /home/pontusc/.claude/hooks/notify.sh

set -euo pipefail

INPUT=$(cat)
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty')
MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')

[[ -n "$MESSAGE" ]] || exit 0

case "$NOTIFICATION_TYPE" in
hook_block | hook_failure | permission_prompt | elicitation_dialog)
	URGENCY="normal"
	;;
idle_prompt)
	URGENCY="low"
	;;
auth_success)
	exit 0
	;;
*)
	URGENCY="normal"
	;;
esac

notify-send -u "$URGENCY" -a "Claude Code" "$TITLE" "$MESSAGE" 2> /dev/null || true
pw-play /usr/share/sounds/freedesktop/stereo/bell.oga 2> /dev/null || true
exit 0

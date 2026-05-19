#!/usr/bin/env bash
# notify — Claude Code notification entry point.
#
# ── Purpose ───────────────────────────────────────────────────────────────────
#
# Single relay for all desktop notifications. Receives JSON on stdin and
# dispatches to notify-send with appropriate urgency and icon based on the
# event source.
#
# ── Input shapes ──────────────────────────────────────────────────────────────
#
# 1) Claude Code native event (registered as Notification / Stop hook):
#      { "hook_event_name": "Notification", "message": "...", ... }
#      { "hook_event_name": "Stop", ... }
#
# 2) Custom call piped from another hook (PreToolUse block, PostToolUse fail):
#      { "notification_type": "hook_block|hook_failure",
#        "title": "...", "message": "..." }
#
# ── Event routing ─────────────────────────────────────────────────────────────
#
#   Source              │ Urgency  │ Icon              │ Message
#   ────────────────────┼──────────┼───────────────────┼──────────────────────
#   Notification        │ normal   │ dialog-question   │ event.message
#   Stop                │ low      │ dialog-information│ "Task complete ❇️"
#   SubagentStop        │ (skipped — too noisy)
#   hook_block          │ critical │ dialog-error      │ payload.message
#   hook_failure        │ normal   │ dialog-warning    │ payload.message
#
# ── Exit codes ────────────────────────────────────────────────────────────────
#
# Always exits 0. Notifications are best-effort and must never block the agent.

set -uo pipefail

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty')

URGENCY="normal"
ICON="dialog-information"
TITLE="Claude Code"
MESSAGE=""

if [[ -n "$EVENT" ]]; then
  case "$EVENT" in
  Notification)
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "Attention needed"')
    URGENCY="normal"
    ICON="dialog-question"
    ;;
  Stop)
    MESSAGE="Task complete ❇️"
    URGENCY="low"
    ;;
  SubagentStop)
    # Subagent completions are too frequent to surface
    exit 0
    ;;
  *)
    TITLE="Claude Code: $EVENT"
    MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')
    ;;
  esac
elif [[ -n "$TYPE" ]]; then
  TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
  MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')
  case "$TYPE" in
  hook_block)
    URGENCY="critical"
    ICON="dialog-error"
    ;;
  hook_failure)
    URGENCY="normal"
    ICON="dialog-warning"
    ;;
  esac
else
  exit 0
fi

[[ -n "$MESSAGE" ]] || exit 0

notify-send -u "$URGENCY" -i "$ICON" "$TITLE" "$MESSAGE" 2> /dev/null || true
exit 0

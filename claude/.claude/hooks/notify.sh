#!/usr/bin/env bash
# notify — Claude Code notification entry point.
#
# ── Purpose ───────────────────────────────────────────────────────────────────
#
# Single relay for desktop notifications. Surfaces ONLY events that need the
# user's attention — permission prompts and task completion. Hook blocks
# (PreToolUse) and lint failures (PostToolUse) deliberately do not notify;
# they go back to the agent which fixes and retries on its own.
#
# ── Input ─────────────────────────────────────────────────────────────────────
#
# Claude Code native event JSON on stdin:
#   { "hook_event_name": "Notification", "message": "...", ... }
#   { "hook_event_name": "Stop", ... }
#
# ── Event routing ─────────────────────────────────────────────────────────────
#
#   Event         │ Urgency  │ Icon              │ Message
#   ──────────────┼──────────┼───────────────────┼──────────────────────────
#   Notification  │ normal   │ dialog-question   │ event.message
#   Stop          │ low      │ dialog-information│ "Task complete ❇️"
#   SubagentStop  │ (skipped — too noisy)
#
# ── Exit ──────────────────────────────────────────────────────────────────────
#
# Always 0. Notifications are best-effort and must never block the agent.

set -uo pipefail

INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
[[ -n "$EVENT" ]] || exit 0

URGENCY="normal"
ICON="dialog-information"
TITLE="Claude Code"
MESSAGE=""

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
  # Unknown event — best-effort relay
  TITLE="Claude Code: $EVENT"
  MESSAGE=$(echo "$INPUT" | jq -r '.message // empty')
  ;;
esac

[[ -n "$MESSAGE" ]] || exit 0

notify-send -u "$URGENCY" -i "$ICON" "$TITLE" "$MESSAGE" 2> /dev/null || true
exit 0

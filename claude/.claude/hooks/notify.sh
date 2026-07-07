#!/usr/bin/env bash
# notify — Claude Code notification entry point.
#
# ── Purpose ───────────────────────────────────────────────────────────────────
#
# Single relay for desktop notifications. Surfaces ONLY permission prompts —
# the one Notification subtype that needs the user to act. idle_prompt ("waiting
# for input") is deliberately dropped: this is a global hook, so it fires at
# every turn end for every concurrent session, and an unanswered permission
# prompt itself degrades into an idle_prompt after the idle threshold — both are
# pure noise. Stop/SubagentStop and PreToolUse blocks likewise stay silent.
#
# ── Input ─────────────────────────────────────────────────────────────────────
#
# Claude Code native event JSON on stdin:
#   { "hook_event_name": "Notification", "notification_type": "...", "message": "...", ... }
#
# ── Event routing ──────────────────────────────────────────────────────────────
#
#   notification_type │ Urgency  │ Icon           │ Timeout  │ Message
#   ──────────────────┼──────────┼────────────────┼──────────┼────────────────
#   permission_prompt │ critical │ dialog-warning │ 0 (stay) │ event.message
#   (all others)      │ (silent — exit 0, no notification)
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
TIMEOUT="" # notify-send -t (ms); empty leaves the daemon default

case "$EVENT" in
Notification)
  case "$(echo "$INPUT" | jq -r '.notification_type // empty')" in
  permission_prompt)
    # Approval required — high priority, persists until manually dismissed.
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "Approval needed"')
    URGENCY="critical"
    ICON="dialog-warning"
    TIMEOUT=0
    ;;
  *)
    # idle_prompt and every other subtype are noise across concurrent
    # sessions — stay silent. Only actionable permission prompts notify.
    exit 0
    ;;
  esac
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

# Append tmux location when running inside tmux (best-effort, no-op otherwise).
if [[ -n "${TMUX:-}" ]] && command -v tmux &> /dev/null; then
  LOCATION=$(tmux display-message -p -t "${TMUX_PANE:-}" '#S:#{=12:window_name}' 2> /dev/null)
  [[ -n "$LOCATION" ]] && TITLE="$TITLE — $LOCATION"
fi

NOTIFY_ARGS=(-u "$URGENCY" -i "$ICON")
[[ -n "$TIMEOUT" ]] && NOTIFY_ARGS+=(-t "$TIMEOUT")
notify-send "${NOTIFY_ARGS[@]}" "$TITLE" "$MESSAGE" 2> /dev/null || true
exit 0

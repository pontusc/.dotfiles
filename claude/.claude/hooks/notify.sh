#!/usr/bin/env bash
# notify — Claude Code notification entry point.
#
# ── Purpose ───────────────────────────────────────────────────────────────────
#
# Single relay for desktop notifications. Surfaces ONLY the two Notification
# subtypes that need the user's attention — permission prompts and the idle
# "waiting for input" ping. Stop/SubagentStop deliberately do not notify: Stop
# fires at every turn end, so with background subagents it would ping "done"
# while work is still running. Hook blocks (PreToolUse) likewise stay silent;
# they go back to the agent which fixes and retries on its own.
#
# ── Input ─────────────────────────────────────────────────────────────────────
#
# Claude Code native event JSON on stdin:
#   { "hook_event_name": "Notification", "notification_type": "...", "message": "...", ... }
#
# ── Event routing ──────────────────────────────────────────────────────────────
#
#   notification_type │ Urgency  │ Icon               │ Timeout  │ Message
#   ──────────────────┼──────────┼────────────────────┼──────────┼────────────────
#   permission_prompt │ critical │ dialog-warning     │ 0 (stay) │ event.message
#   idle_prompt       │ normal   │ dialog-information  │ 10s      │ "Task complete…"
#   (other)           │ normal   │ dialog-question    │ default  │ event.message
#   Stop/SubagentStop │ (not registered / skipped)
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
  idle_prompt)
    # Task finished, Claude is waiting for input — brief, auto-dismiss.
    MESSAGE="Task complete — waiting for input ❇️"
    TIMEOUT=10000
    ;;
  *)
    # Other notification subtypes — best-effort relay.
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "Attention needed"')
    ICON="dialog-question"
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

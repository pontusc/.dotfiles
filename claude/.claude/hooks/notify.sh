#!/usr/bin/env bash
set -euo pipefail
# Claude Code notification relay, the only desktop notifier. Registered in settings.json for
# Notification (permission_prompt), Stop, UserPromptSubmit, and PostToolUse. Hook event JSON
# on stdin. Notifies on prompts and stops, dismisses the session's popup when the user responds.

INPUT="$(cat)"
EVENT="$(jq -r '.hook_event_name // empty' <<<"$INPUT")"
SESSION_ID="$(jq -r '.session_id // "unknown"' <<<"$INPUT")"
MARK_DIR="${XDG_RUNTIME_DIR:-/tmp}/claude-notify"
MARK="${MARK_DIR}/${SESSION_ID}"
QS_SHELL=/usr/share/omarchy/shell

LOCATION="${SESSION_ID:0:8}"
if [[ -n "${TMUX:-}" ]]; then
  LOCATION="$(tmux display-message -p -t "${TMUX_PANE:-}" '#S:#{=12:window_name}' 2>/dev/null || printf '%s' "$LOCATION")"
fi
TITLE="Claude Code, ${LOCATION}"

dismiss() {
  [[ -f "$MARK" ]] || return 0
  rm -f "$MARK"
  if [[ -d "$QS_SHELL" ]] && command -v qs >/dev/null; then
    qs -p "$QS_SHELL" ipc call notifications dismiss "$LOCATION" >/dev/null 2>&1 || true
  fi
}

notify() {
  dismiss
  mkdir -p "$MARK_DIR"
  : >"$MARK"
  notify-send -u "$1" -t "$2" "$TITLE" "$3" 2>/dev/null || true
}

case "$EVENT" in
  Notification) notify critical 0 "$(jq -r '.message // "Approval needed"' <<<"$INPUT")" ;;
  Stop) notify normal 8000 "Waiting for input" ;;
  UserPromptSubmit | PostToolUse) dismiss ;;
esac
exit 0

#!/usr/bin/env bash
set -euo pipefail
# Claude Code hook relay: flags the tmux window hosting the Claude pane instead of sending
# a desktop notification. Registered in settings.json for UserPromptSubmit, PostToolUse,
# PreToolUse (AskUserQuestion, ExitPlanMode), Notification, and Stop. Hook JSON arrives on stdin.

DONE_AFTER=60

INPUT="$(cat)"
EVENT="$(jq -r '.hook_event_name // empty' <<<"$INPUT")"
SESSION_ID="$(jq -r '.session_id // "unknown"' <<<"$INPUT")"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/claude-notify"
STATE_FILE="${STATE_DIR}/${SESSION_ID}"

[[ -n "${TMUX_PANE:-}" ]] || exit 0
tmux display -p -t "$TMUX_PANE" >/dev/null 2>&1 || exit 0

clear_flag() {
  tmux set-option -w -t "$TMUX_PANE" -u @claude
}

raise_flag() {
  local flag="$1" message="$2"
  local pane_active window_active session_attached session_name window_name
  IFS=$'\t' read -r pane_active window_active session_attached session_name window_name \
    < <(tmux display -p -t "$TMUX_PANE" -F $'#{pane_active}\t#{window_active}\t#{session_attached}\t#{session_name}\t#{window_name}')

  local client_flags
  readarray -t client_flags < <(tmux list-clients -t "$session_name" -F '#{client_flags}' 2>/dev/null)
  local focused=0 flags
  for flags in "${client_flags[@]}"; do
    [[ "$flags" == *focused* ]] && focused=1
  done

  if [[ "$pane_active" -eq 1 && "$window_active" -eq 1 && "$session_attached" -eq 1 && "$focused" -eq 1 ]]; then
    return 0
  fi

  tmux set-option -w -t "$TMUX_PANE" @claude "$flag"
  local clients client
  readarray -t clients < <(tmux list-clients -F '#{client_name}' 2>/dev/null)
  for client in "${clients[@]}"; do
    tmux display-message -c "$client" "${message}, ${session_name}:${window_name}"
  done
}

case "$EVENT" in
  UserPromptSubmit)
    mkdir -p "$STATE_DIR"
    date +%s >"$STATE_FILE"
    clear_flag
    ;;
  PostToolUse)
    clear_flag
    ;;
  PreToolUse)
    raise_flag "ask" "Claude asks"
    ;;
  Notification)
    raise_flag "ask" "$(jq -r '.message // "Approval needed"' <<<"$INPUT")"
    ;;
  Stop)
    if [[ ! -f "$STATE_FILE" ]] || (( $(date +%s) - $(<"$STATE_FILE") >= DONE_AFTER )); then
      raise_flag "done" "Claude finished"
    fi
    ;;
esac

exit 0

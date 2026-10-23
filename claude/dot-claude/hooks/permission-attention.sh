#!/usr/bin/env bash
set -euo pipefail
# PermissionRequest hook. Flags the tmux window with @claude ask while a permission dialog
# waits in a pane nobody watches. The tmux.conf focus hooks clear it.

[[ -n "${TMUX_PANE:-}" ]] || exit 0

IFS=$'\t' read -r PANE_ACTIVE WINDOW_ACTIVE SESSION_ATTACHED SESSION_NAME < <(
  tmux display -p -t "$TMUX_PANE" -F '#{pane_active}	#{window_active}	#{session_attached}	#{session_name}'
)
if [[ "$PANE_ACTIVE" == 1 && "$WINDOW_ACTIVE" == 1 && "$SESSION_ATTACHED" != 0 ]] &&
  tmux list-clients -t "$SESSION_NAME" -F '#{client_flags}' | grep -q focused; then
  exit 0
fi

tmux set-option -w -t "$TMUX_PANE" @claude ask

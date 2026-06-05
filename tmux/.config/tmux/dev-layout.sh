#!/usr/bin/env bash
# dev-layout.sh [target_window]
# Build the dev layout: nvim (top-left) | claude (right 34%) + terminal (bottom-left).
# No arg -> the current window (leader+A). A window id/name -> that window (leader+W).
win="${1:-}"
if [ -n "$win" ]; then T=(-t "$win"); else T=(); fi

pane_count=$(tmux list-panes "${T[@]}" | wc -l)
if [ "$pane_count" -ne 1 ]; then
  tmux display-message "Dev layout requires a single pane"
  exit 0
fi

dir=$(tmux display-message "${T[@]}" -p "#{pane_current_path}")

# Claude split (right)
tmux split-window "${T[@]}" -h -l 34% -c "$dir"
tmux select-pane "${T[@]}" -L
# Terminal split (bottom-left)
tmux split-window "${T[@]}" -v -l 30% -c "$dir"
tmux select-pane "${T[@]}" -U
tmux send-keys "${T[@]}" "nvim" Enter
tmux select-pane "${T[@]}" -R
tmux send-keys "${T[@]}" "claude" Enter
tmux select-pane "${T[@]}" -L
tmux select-pane "${T[@]}" -U

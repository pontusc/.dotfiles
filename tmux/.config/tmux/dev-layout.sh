#!/usr/bin/env bash
pane_count=$(tmux list-panes -t : | wc -l)
if [ "$pane_count" -ne 1 ]; then
  tmux display-message "Dev layout requires a single pane"
  exit 0
fi

dir=$(tmux display-message -p "#{pane_current_path}")

tmux split-window -h -l 30% -c "$dir"
tmux select-pane -L
tmux split-window -v -l 30% -c "$dir"
tmux select-pane -U
tmux send-keys "nvim" Enter
tmux select-pane -R
tmux send-keys "claude" Enter
tmux select-pane -L
tmux select-pane -U

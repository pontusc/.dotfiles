#!/usr/bin/env bash
# worktree-new.sh — create (or focus) a git worktree for a branch and open a
# new tmux window running the dev layout in it.
# Triggered from a pane inside a repo (leader+W); cwd is that pane's directory.
set -euo pipefail

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  tmux display-message "worktree: not inside a git repo"
  exit 0
fi

# Main repo root — correct even when invoked from inside an existing worktree.
common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
repo_root=$(dirname "$common_dir")
repo_name=$(basename "$repo_root")
wt_parent="${repo_root}.worktrees" # ~/Work/<repo>.worktrees

# Default base for NEW branches: the repo's main line (origin/HEAD -> origin/main),
# falling back to local/remote main or master, then the current HEAD.
base_ref() {
  local b
  b=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2> /dev/null) && {
    printf '%s\n' "$b"
    return
  }
  for b in main master; do
    git show-ref --verify --quiet "refs/remotes/origin/$b" && {
      printf 'origin/%s\n' "$b"
      return
    }
    git show-ref --verify --quiet "refs/heads/$b" && {
      printf '%s\n' "$b"
      return
    }
  done
  printf 'HEAD\n'
}
base=$(base_ref)

# Pick an existing branch, or type a name to create one (new branches fork off "$base").
branch=$(
  git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin |
    sed 's#^origin/##' | grep -vxE 'HEAD|origin' | sort -u |
    fzf --print-query --prompt "Repository: $repo_name ❯ " |
    tail -1
) || true
[ -z "${branch:-}" ] && exit 0 # cancelled

safe=${branch//\//-} # feat/foo -> feat-foo (path + window name)
wt_path="${wt_parent}/${safe}"

add_worktree() {
  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    git worktree add "$wt_path" "$branch" # existing local branch
  elif git show-ref --verify --quiet "refs/remotes/origin/${branch}"; then
    git worktree add --track -b "$branch" "$wt_path" "origin/${branch}" # remote branch -> track
  else
    git worktree add --no-track -b "$branch" "$wt_path" "$base" # new branch off base, no upstream
  fi
}

if [ ! -d "$wt_path" ]; then
  mkdir -p "$wt_parent"
  if ! add_worktree; then
    echo
    echo "git worktree add failed — press any key to close"
    read -rsn1
    exit 1
  fi
fi

# Short window name: ticket number + truncated tail (the path stays full & unique).
#   ALC-679/oauth-login-iat -> 679:oauth-log
#   add-grafana-md-service  -> add-grafa
tail_max=9
if [[ $branch =~ ^[A-Za-z]+-([0-9]+)/(.+)$ ]]; then
  num="${BASH_REMATCH[1]}"
  tail="${BASH_REMATCH[2]//\//-}"
  wname="${num}:${tail:0:tail_max}"
else
  wname="${safe:0:tail_max}"
fi

# De-dupe by worktree PATH (short names may collide), across ALL sessions, via the
# @worktree window option set when the window is created.
match=$(tmux list-windows -a -f "#{==:#{@worktree},${wt_path}}" \
  -F '#{window_id} #{session_name}' | head -n1)
if [ -n "$match" ]; then
  win_id=${match%% *}
  sess=${match#* }
  tmux switch-client -t "$sess"   # bring that session to the front
  tmux select-window -t "$win_id" # focus the existing worktree window
else
  win=$(tmux new-window -P -F '#{window_id}' -n "$wname" -c "$wt_path")
  tmux set-option -w -t "$win" @worktree "$wt_path" # tag for path-based de-dupe
  ~/.config/tmux/dev-layout.sh "$win"               # build the dev layout in it
fi

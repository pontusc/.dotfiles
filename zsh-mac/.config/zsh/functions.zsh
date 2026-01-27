# Launch tmux in default session if exists, make if not
tmux() {
  if [ $# -eq 0 ]; then
    command tmux attach -t default || command tmux new -s default
  else
    command tmux "$@"
  fi
}

function copy() {
  # 1. Get the absolute path
  local fullpath
  fullpath="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"

  # 2. Use AppleScript to set the clipboard to that file object
  osascript -e "set the clipboard to POSIX file \"$fullpath\""

  echo "Copied to clipboard: $fullpath"
}

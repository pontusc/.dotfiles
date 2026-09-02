#!/usr/bin/env bash
set -euo pipefail
# Claude flag segments for the powerkit external plugin, invoked as
# #(~/.config/tmux/claude-flags.sh). One slanted two-tone segment per window carrying
# the tmux @claude option, styled like the window tabs. Prints nothing when none are flagged.

SLANT=$'\xee\x82\xba'

palette() {
  readarray -t pairs < <(tmux show -gv "$1" | grep -oE 'fg=#[0-9a-f]{6},bg=#[0-9a-f]{6}')
  [[ ${#pairs[@]} -ge 3 ]] || return 1
  local fg="${pairs[0]#fg=}"
  printf '%s %s %s\n' "${fg%%,*}" "${pairs[0]##*bg=}" "${pairs[2]##*bg=}"
}

readarray -t LINES < <(tmux list-windows -a -F '#{?@claude,#{@claude} #S:#W,}' 2>/dev/null)
read -r ASK_FG ASK_MARK_BG ASK_NAME_BG < <(palette window-status-current-format) || exit 0
read -r DONE_FG DONE_MARK_BG DONE_NAME_BG < <(palette window-status-format) || exit 0
PREV_BG="$(tmux show -gv status-style | grep -oE 'bg=#[0-9a-f]{6}' | cut -c4-)"

OUT=""
for line in "${LINES[@]}"; do
  [[ -z "$line" ]] && continue
  case "${line%% *}" in
    ask) mark="?" fg="$ASK_FG" mark_bg="$ASK_MARK_BG" name_bg="$ASK_NAME_BG" ;;
    done) mark="✓" fg="$DONE_FG" mark_bg="$DONE_MARK_BG" name_bg="$DONE_NAME_BG" ;;
    *) continue ;;
  esac
  OUT+="#[fg=${mark_bg},bg=${PREV_BG}]${SLANT}#[fg=${fg},bg=${mark_bg}] ${mark} "
  OUT+="#[fg=${name_bg},bg=${mark_bg}]${SLANT}#[fg=${fg},bg=${name_bg}] ${line#* } "
  PREV_BG="$name_bg"
done

[[ -n "$OUT" ]] && printf '%s\n' "$OUT"
exit 0

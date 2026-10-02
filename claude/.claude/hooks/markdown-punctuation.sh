#!/usr/bin/env bash
set -euo pipefail
# PostToolUse hook for Edit and Write on markdown files. Reports lines outside fenced code
# that contain a semicolon, an em or en dash, or a spaced single or double hyphen used as a
# dash. Hook JSON arrives on stdin, exit 2 returns the offending lines to the agent.

INPUT="$(cat)"
TOOL="$(jq -r '.tool_name // empty' <<<"$INPUT")"
FILE="$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")"

[[ "$FILE" == *.md && -f "$FILE" ]] || exit 0

readarray -t hits < <(
  awk '
    /^[[:space:]]*(```|~~~)/ { in_fence = !in_fence; next }
    in_fence { next }
    {
      line = $0
      gsub(/`[^`]*`/, "", line)
      gsub(/https?:\/\/[^[:space:])>]*/, "", line)
      sub(/^[[:space:]]*(>[[:space:]]*)*- /, "", line)
      if (line ~ /;|\xe2\x80\x94|\xe2\x80\x93|(^|[^-]) --? ([^-]|$)/) print FILENAME ":" NR ": " $0
    }
  ' "$FILE"
)

if [[ "$TOOL" == Edit ]]; then
  readarray -t new_lines < <(jq -r '.tool_input.new_string // empty' <<<"$INPUT" | grep -v '^[[:space:]]*$')
  readarray -t hits < <(
    for hit in "${hits[@]}"; do
      text="${hit#*:*: }"
      for new_line in "${new_lines[@]}"; do
        if [[ "$text" == *"$new_line"* ]]; then
          printf '%s\n' "$hit"
          break
        fi
      done
    done
  )
fi

if (( ${#hits[@]} == 0 )); then exit 0; fi

printf 'Plain punctuation in markdown: no semicolons, no em or en dashes, no spaced hyphen as a dash.\n' >&2
printf '%s\n' "${hits[@]}" >&2
exit 2

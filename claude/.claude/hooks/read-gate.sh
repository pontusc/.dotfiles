#!/usr/bin/env bash
set -euo pipefail
# Claude Code PreToolUse hook for Read and Bash: blocks whole-file reads of files longer than
# READ_GATE_MAX_LINES (default 350) so bulk reading goes to scout. Hook JSON arrives on stdin,
# exit 2 with the reason on stderr blocks the call. Agents in READ_GATE_EXEMPT_AGENTS pass.

MAX_LINES="${READ_GATE_MAX_LINES:-350}"
EXEMPT_AGENTS="${READ_GATE_EXEMPT_AGENTS:-scout}"
readonly MAX_LINES EXEMPT_AGENTS

INPUT="$(cat)"
readonly INPUT

field() {
  jq -r "$1 // empty" <<<"$INPUT"
}

TOOL="$(field '.tool_name')"
AGENT_TYPE="$(field '.agent_type')"
CWD="$(field '.cwd')"
readonly TOOL AGENT_TYPE CWD

block() {
  printf '%s\n' "$1" >&2
  exit 2
}

line_count() {
  local path="$1"
  [[ "$path" == /* ]] || path="${CWD:-.}/$path"
  [[ -f "$path" && -r "$path" ]] || return 1
  wc -l <"$path"
}

if [[ -n "$AGENT_TYPE" ]]; then
  for exempt in ${EXEMPT_AGENTS//,/ }; do
    [[ "$AGENT_TYPE" == "$exempt" ]] && exit 0
  done
fi

case "$TOOL" in
  Read)
    FILE_PATH="$(field '.tool_input.file_path')"
    LIMIT="$(field '.tool_input.limit')"
    LINES="$(line_count "$FILE_PATH" || echo 0)"
    if (( LINES > MAX_LINES )) && { [[ -z "$LIMIT" ]] || (( LIMIT > MAX_LINES )); }; then
      block "Read blocked: ${FILE_PATH} has ${LINES} lines, limit is ${MAX_LINES}. Delegate to scout for pointers, then Read with offset and a limit of at most ${MAX_LINES}."
    fi
    ;;
  Bash)
    COMMAND="$(field '.tool_input.command')"
    # Each match is one reader invocation up to the next pipe or separator.
    READER_RE='(^|[|;&(]|&&|\|\|)[[:space:]]*(cat|less|more|head|tail)([^|;&()]*)'
    rest="$COMMAND"
    while [[ "$rest" =~ $READER_RE ]]; do
      reader="${BASH_REMATCH[2]}"
      args="${BASH_REMATCH[3]}"
      rest="${rest#*"${BASH_REMATCH[0]}"}"
      requested=""
      if [[ "$reader" == head || "$reader" == tail ]]; then
        if [[ "$args" =~ (-n[[:space:]]*|-)([0-9]+) ]]; then
          requested="${BASH_REMATCH[2]}"
        else
          requested=10
        fi
        (( requested <= MAX_LINES )) && continue
      fi
      for word in $args; do
        [[ "$word" == -* ]] && continue
        lines="$(line_count "$word" || true)"
        [[ -n "$lines" ]] || continue
        if (( lines > MAX_LINES )); then
          block "Bash read blocked: ${reader} on ${word} (${lines} lines, limit ${MAX_LINES}). Delegate bulk reading to scout, or use sed -n 'a,bp' or grep for a range under ${MAX_LINES} lines."
        fi
      done
    done
    ;;
esac

exit 0

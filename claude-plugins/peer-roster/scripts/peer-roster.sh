#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' EXIT

# peer-roster — injects a roster of related Claude Code sessions into context.
#
# Invoked two ways by Claude Code hooks:
#   peer-roster.sh session-start   (SessionStart)
#   peer-roster.sh prompt-submit   (UserPromptSubmit)
#
# Reads the undocumented ~/.claude/sessions/*.json registry, matches each
# live peer's cwd against $CC_PEER_ROOT to find sessions on the same ticket
# (siblings) or the same repo, and emits a full roster on session start or a
# delta of peers that appeared/exited since the last prompt.
#
# Must always exit 0: a UserPromptSubmit hook exiting 2 erases the prompt.
# work_root, self_repo, self_ticket, and peers_json are set once in main()
# and read by the functions below via bash's dynamic scoping.

# Extracts repo, ticket, and branch label from a cwd. Prints fields joined by
# \x1f (repo, ticket, branch); returns 1 if the path isn't under work_root.
resolve_context() {
  local path="$1"
  case "$path" in
    "${work_root}"/*) ;;
    *) return 1 ;;
  esac

  local relative="${path#"${work_root}"/}"
  local repo="${relative%%/*}"
  repo="${repo%.worktrees}"

  local ticket=""
  if [[ "$relative" =~ [A-Z]+-[0-9]+ ]]; then
    ticket="${BASH_REMATCH[0]}"
  fi

  local branch="repo root"
  if [[ "$relative" == *".worktrees/"* ]]; then
    branch="${relative#*.worktrees/}"
    branch="${branch%%/*}"
  fi

  printf '%s\x1f%s\x1f%s\n' "$repo" "$ticket" "$branch"
}

# True if pid is still the same process that wrote procStart (defeats pid reuse).
peer_is_live() {
  local pid="$1" expected_start="$2"
  local stat_line
  if ! stat_line="$(< "/proc/${pid}/stat")"; then
    return 1
  fi

  # comm (field 2) can contain spaces/parens, so strip through the last ")"
  # before splitting the rest on whitespace; starttime is field 22 overall,
  # i.e. field 20 of what remains.
  local rest="${stat_line##*) }"
  local -a fields
  read -r -a fields <<<"$rest"
  [[ "${fields[19]:-}" == "$expected_start" ]]
}

# Prints this process's pid and every ancestor pid, space-separated. The
# Claude process that spawned this hook is among them at unknown depth
# (hook commands may run under intermediate shells), so self-exclusion
# matches on ancestry rather than direct parent. Ppid is stat field 4
# overall, field 2 after stripping comm.
self_ancestor_pids() {
  local pid=$$ stat_line rest
  local -a fields
  while (( pid > 1 )); do
    printf '%s ' "$pid"
    stat_line="$(< "/proc/${pid}/stat")" || return 0
    rest="${stat_line##*) }"
    read -r -a fields <<<"$rest"
    pid="${fields[1]:-1}"
  done
}

# Classifies a peer cwd against self_repo/self_ticket. Prints fields joined
# by \x1f (kind, label, detail1, detail2; kind: sibling|same_repo); returns 1
# if the peer doesn't qualify. Two sessions are siblings only when both
# tickets are non-empty and equal.
classify_peer() {
  local peer_cwd="$1"
  local context
  context="$(resolve_context "$peer_cwd")" || return 1
  local repo ticket branch
  IFS=$'\x1f' read -r repo ticket branch <<<"$context"

  if [[ -n "$ticket" && -n "$self_ticket" && "$ticket" == "$self_ticket" ]]; then
    local note
    note="$(jq -r --arg repo "$repo" '.[$repo] // empty' <<<"$peers_json")"
    printf 'sibling\x1f%s\x1f%s\x1f%s\n' "$self_ticket" "$repo" "$note"
    return 0
  fi
  if [[ "$repo" == "$self_repo" ]]; then
    printf 'same_repo\x1f%s\x1f%s\x1f%s\n' "$repo" "$branch" ""
    return 0
  fi
  return 1
}

# Formats one prompt-submit delta line for an added or removed
# "sessionId\x1fname\x1fcwd" entry, or prints nothing if the peer no longer
# classifies.
describe_change() {
  local action="$1" entry="$2"
  local peer_name peer_cwd
  IFS=$'\x1f' read -r _ peer_name peer_cwd <<<"$entry"
  local classification
  classification="$(classify_peer "$peer_cwd")" || return 0
  local kind label detail1 detail2
  IFS=$'\x1f' read -r kind label detail1 detail2 <<<"$classification"

  if [[ "$action" == removed ]]; then
    printf '[peers] %s: %s exited\n' "$label" "$peer_name"
    return 0
  fi
  case "$kind" in
    sibling)
      if [[ -n "$detail2" ]]; then
        printf '[peers] %s: new sibling %s (%s, %s)\n' "$label" "$peer_name" "$detail1" "$detail2"
      else
        printf '[peers] %s: new sibling %s (%s)\n' "$label" "$peer_name" "$detail1"
      fi
      ;;
    same_repo)
      printf '[peers] %s: new branch %s (%s)\n' "$label" "$peer_name" "$detail1"
      ;;
  esac
}

# Streams a possibly-empty string as newline-terminated lines, for feeding
# comm via process substitution without an empty-input artifact line.
lines_stream() {
  local content="$1"
  if [[ -n "$content" ]]; then
    printf '%s\n' "$content"
  fi
}

# Prints a describe_change line per entry to stdout, for each
# "sessionId\x1fname\x1fcwd" entry passed after the added|removed action.
append_changes() {
  local action="$1"
  shift
  local entry change
  for entry in "$@"; do
    change="$(describe_change "$action" "$entry")"
    if [[ -n "$change" ]]; then
      printf '%s\n' "$change"
    fi
  done
}

# Joins args with a tab, indented 4 spaces, for building render_group input.
table_row() {
  local IFS=$'\t'
  printf '    %s\n' "$*"
}

# Renders one roster section: a "  header" line followed by its rows,
# column-aligned 3 spaces apart. Emits nothing when there are no rows, and
# falls back to the raw tab-separated rows when column is unavailable.
render_group() {
  local header="$1" row_lines="$2"
  row_lines="${row_lines%$'\n'}"
  if [[ -z "$row_lines" ]]; then
    return 0
  fi
  local aligned
  if ! aligned="$(column -t -s $'\t' -o '   ' <<<"$row_lines" 2>/dev/null)" || [[ -z "$aligned" ]]; then
    aligned="$row_lines"
  fi
  printf '  %s\n%s\n' "$header" "$aligned"
}

main() {
  local mode="${1:-}"
  case "$mode" in
    session-start | prompt-submit) ;;
    *) return 0 ;;
  esac

  local input
  input="$(cat)" || return 0
  local session_id cwd
  session_id="$(jq -r '.session_id // empty' <<<"$input" 2>/dev/null)" || return 0
  cwd="$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)" || return 0
  if [[ -z "$session_id" || -z "$cwd" ]]; then
    return 0
  fi

  local config_root="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  local work_root="${CC_PEER_ROOT:-$HOME/Work}"
  work_root="${work_root%/}"

  local self_context
  self_context="$(resolve_context "$cwd")" || return 0
  local self_repo self_ticket
  IFS=$'\x1f' read -r self_repo self_ticket _ <<<"$self_context"

  local registry_dir="${config_root}/sessions"
  local peers_file="${config_root}/peers.json"
  local snapshot_dir
  if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    snapshot_dir="${XDG_RUNTIME_DIR}/cc-peer-roster"
  else
    snapshot_dir="/tmp/cc-peer-roster-${UID}"
  fi
  local snapshot_usable=0
  if mkdir -p "$snapshot_dir" 2>/dev/null \
    && [[ ! -L "$snapshot_dir" && -d "$snapshot_dir" && -O "$snapshot_dir" ]] \
    && chmod 700 "$snapshot_dir"; then
    snapshot_usable=1
  fi
  local snapshot_file="${snapshot_dir}/${session_id}"
  local warned_marker="${snapshot_dir}/${session_id}.warned"

  local peers_json="{}" peers_status="ok"
  if [[ -f "$peers_file" ]]; then
    local loaded
    if loaded="$(jq -e -c 'if type == "object" then . else empty end' "$peers_file" 2>/dev/null)" && [[ -n "$loaded" ]]; then
      peers_json="$loaded"
    else
      peers_status="malformed"
    fi
  else
    peers_status="missing"
  fi

  local -a sibling_name=() sibling_repo=() sibling_note=() sibling_status=()
  local -a same_repo_name=() same_repo_branch=() same_repo_status=()
  local current_set=""

  if [[ -d "$registry_dir" ]]; then
    local ancestor_pids
    ancestor_pids="$(self_ancestor_pids)"
    local registry_file
    for registry_file in "$registry_dir"/*.json; do
      if [[ ! -e "$registry_file" ]]; then
        continue
      fi

      local rec_line
      rec_line="$(jq -r '[.pid,.sessionId,.cwd,.name,.status,.waitingFor,.procStart] | map(. // "") | join("\u001f")' "$registry_file" 2>/dev/null)" || continue
      local rec_pid rec_session_id rec_cwd rec_name rec_status rec_waiting_for rec_proc_start
      IFS=$'\x1f' read -r rec_pid rec_session_id rec_cwd rec_name rec_status rec_waiting_for rec_proc_start <<<"$rec_line"

      if [[ -z "$rec_pid" || -z "$rec_session_id" || -z "$rec_cwd" || -z "$rec_name" ]]; then
        continue
      fi
      if [[ "$rec_session_id" == "$session_id" || " ${ancestor_pids} " == *" ${rec_pid} "* ]]; then
        continue
      fi
      if [[ ! -d "/proc/${rec_pid}" ]]; then
        continue
      fi
      if [[ -n "$rec_proc_start" ]] && ! peer_is_live "$rec_pid" "$rec_proc_start"; then
        continue
      fi

      local classification
      classification="$(classify_peer "$rec_cwd")" || continue
      local kind detail1 detail2
      IFS=$'\x1f' read -r kind _ detail1 detail2 <<<"$classification"

      local display_status="$rec_status"
      if [[ -n "$rec_waiting_for" ]]; then
        if [[ -n "$rec_status" ]]; then
          display_status="${rec_status}: ${rec_waiting_for}"
        else
          display_status="$rec_waiting_for"
        fi
      fi

      case "$kind" in
        sibling)
          sibling_name+=("$rec_name")
          sibling_repo+=("$detail1")
          sibling_note+=("$detail2")
          sibling_status+=("$display_status")
          ;;
        same_repo)
          same_repo_name+=("$rec_name")
          same_repo_branch+=("$detail1")
          same_repo_status+=("$display_status")
          ;;
      esac

      current_set+="${rec_session_id}"$'\x1f'"${rec_name}"$'\x1f'"${rec_cwd}"$'\n'
    done
  fi

  local current_sorted
  current_sorted="$(printf '%s' "$current_set" | sort)"

  local body=""

  if [[ "$mode" == "session-start" ]]; then
    if [[ ${#sibling_name[@]} -gt 0 ]]; then
      local sibling_rows="" index
      for index in "${!sibling_name[@]}"; do
        sibling_rows+="$(table_row "${sibling_name[index]}" "${sibling_repo[index]}" "${sibling_note[index]}" "${sibling_status[index]}")"
        sibling_rows+=$'\n'
      done
      body+="$(render_group "$self_ticket" "$sibling_rows")"$'\n'
    fi

    if [[ ${#same_repo_name[@]} -gt 0 ]]; then
      local same_repo_rows="" index
      for index in "${!same_repo_name[@]}"; do
        same_repo_rows+="$(table_row "${same_repo_name[index]}" "${same_repo_branch[index]}" "${same_repo_status[index]}")"
        same_repo_rows+=$'\n'
      done
      body+="$(render_group "${self_repo}, other branches" "$same_repo_rows")"$'\n'
    fi

    body="${body%$'\n'}"
    if [[ -n "$body" ]]; then
      body="Peer Claude Code sessions (address by name with SendMessage):"$'\n'"$body"
    fi
  elif [[ "$snapshot_usable" -eq 1 && -f "$snapshot_file" ]]; then
    local previous_sorted
    previous_sorted="$(< "$snapshot_file")" || previous_sorted=""

    local added removed
    added="$(comm -13 <(lines_stream "$previous_sorted") <(lines_stream "$current_sorted"))"
    removed="$(comm -23 <(lines_stream "$previous_sorted") <(lines_stream "$current_sorted"))"

    local -a added_entries=() removed_entries=()
    if [[ -n "$added" ]]; then
      readarray -t added_entries <<<"$added"
    fi
    if [[ -n "$removed" ]]; then
      readarray -t removed_entries <<<"$removed"
    fi

    local added_changes removed_changes
    added_changes="$(append_changes added "${added_entries[@]}")"
    removed_changes="$(append_changes removed "${removed_entries[@]}")"

    body="$added_changes"
    if [[ -n "$body" && -n "$removed_changes" ]]; then
      body+=$'\n'
    fi
    body+="$removed_changes"
  fi

  if [[ "$snapshot_usable" -eq 1 ]]; then
    printf '%s' "$current_sorted" > "$snapshot_file" || true
  fi

  local warning=""
  if [[ "$peers_status" != "ok" ]]; then
    local should_warn=1
    if [[ "$mode" == "prompt-submit" && "$snapshot_usable" -eq 1 && -f "$warned_marker" ]]; then
      should_warn=0
    fi
    if [[ "$should_warn" -eq 1 ]]; then
      if [[ "$peers_status" == "malformed" ]]; then
        warning="peer-roster: ${peers_file} is malformed - peer repo descriptions unavailable. It must be a JSON object mapping repo directory name to a short description."
      else
        warning="peer-roster: ${peers_file} not found - peer repo descriptions unavailable. Create it as a JSON object mapping repo directory name to a short description."
      fi
      if [[ "$mode" == "prompt-submit" && "$snapshot_usable" -eq 1 ]]; then
        : > "$warned_marker" || true
      fi
    fi
  fi

  if [[ -z "$body" && -z "$warning" ]]; then
    return 0
  fi

  local hook_event_name="UserPromptSubmit"
  if [[ "$mode" == "session-start" ]]; then
    hook_event_name="SessionStart"
  fi

  jq -n \
    --arg event "$hook_event_name" \
    --arg context "$body" \
    --arg warning "$warning" \
    '{}
      + (if $context != "" then {hookSpecificOutput: {hookEventName: $event, additionalContext: $context}} else {} end)
      + (if $warning != "" then {systemMessage: $warning} else {} end)'
}

main "$@"
exit 0

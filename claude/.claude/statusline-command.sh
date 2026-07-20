#!/usr/bin/env bash
set -euo pipefail
# Claude Code status line — starship-inspired (cyan, minimal, git-aware).
# Invoked by Claude Code with a JSON session payload on stdin; prints a single
# ANSI-colored line:
#   <dir> <branch> | <model> <effort> <ctx%> | <5h%> (HH:MM) | <7d%> (Day) | <Model N%>
# The last segment (model-scoped weekly limit) comes from the OAuth usage API,
# cached on disk — see Section 4.

INPUT="$(cat)"

CWD="$(echo "$INPUT" | jq -r '.workspace.current_dir // .cwd // ""')"
MODEL_NAME="$(echo "$INPUT" | jq -r '.model.display_name // ""')"
AGENT_NAME="$(echo "$INPUT" | jq -r '.agent.name // empty')"
USED_PCT="$(echo "$INPUT" | jq -r '.context_window.used_percentage // empty')"
EFFORT_LEVEL="$(echo "$INPUT" | jq -r '.effort.level // empty')"
FIVE_HOUR_PCT="$(echo "$INPUT" | jq -r '.rate_limits.five_hour.used_percentage // empty')"
FIVE_HOUR_RESET="$(echo "$INPUT" | jq -r '.rate_limits.five_hour.resets_at // empty')"
SEVEN_DAY_PCT="$(echo "$INPUT" | jq -r '.rate_limits.seven_day.used_percentage // empty')"
SEVEN_DAY_RESET="$(echo "$INPUT" | jq -r '.rate_limits.seven_day.resets_at // empty')"

# --- Directory: last path segment only, capped to 20 chars ---
truncated_dir() {
  local d="$1"
  d="${d/#$HOME/\~}"
  local base="${d##*/}"
  if [[ "${#base}" -gt 20 ]]; then
    base="${base:0:19}…"
  fi
  echo "$base"
}

DIR="$(truncated_dir "$CWD")"

# --- Git info (skip locks to avoid interference) ---
GIT_BRANCH=""
if git -C "$CWD" rev-parse --git-dir > /dev/null 2>&1; then
  GIT_BRANCH="$(GIT_OPTIONAL_LOCKS=0 git -C "$CWD" symbolic-ref --short HEAD 2> /dev/null ||
    GIT_OPTIONAL_LOCKS=0 git -C "$CWD" rev-parse --short HEAD 2> /dev/null)"

  # Cap branch name to 24 chars to keep the status line short
  if [[ "${#GIT_BRANCH}" -gt 24 ]]; then
    GIT_BRANCH="${GIT_BRANCH:0:23}…"
  fi
fi

# --- ANSI colors ---
CYAN="\033[36m"
BOLD_CYAN="\033[1;36m"
DIM_CYAN="\033[2;36m"
DIM_ITALIC_CYAN="\033[2;3;36m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"
readonly CYAN BOLD_CYAN DIM_CYAN DIM_ITALIC_CYAN YELLOW RED RESET

# Color a percentage by usage threshold: dim <50, yellow ≥50, red ≥80.
# $1 = integer percent, $2 = optional label prefix rendered inside the color.
colorize_pct() {
  local pct="$1" prefix="${2:-}"
  local color="$DIM_CYAN"
  if [[ "$pct" -ge 80 ]]; then
    color="$RED"
  elif [[ "$pct" -ge 50 ]]; then
    color="$YELLOW"
  fi
  printf '%s' "${color}${prefix}${pct}%${RESET}"
}

# --- Section 1: directory + git (bold/dim-italic cyan) ---
SEC1="${BOLD_CYAN}${DIR}${RESET}"
if [[ -n "$GIT_BRANCH" ]]; then
  SEC1+=" ${DIM_ITALIC_CYAN}${GIT_BRANCH}${RESET}"
fi

# --- Section 2: model / agent, effort, context usage ---
MODEL_SEG=""
if [[ -n "$AGENT_NAME" ]]; then
  MODEL_SEG="${CYAN}${MODEL_NAME}:${AGENT_NAME}${RESET}"
elif [[ -n "$MODEL_NAME" ]]; then
  MODEL_SEG="${CYAN}${MODEL_NAME}${RESET}"
fi

EFFORT_SEG=""
if [[ -n "$EFFORT_LEVEL" ]]; then
  EFFORT_SEG="${DIM_CYAN}${EFFORT_LEVEL}${RESET}"
fi

CTX_SEG=""
if [[ -n "$USED_PCT" ]]; then
  CTX_SEG="$(colorize_pct "${USED_PCT%.*}")"
fi

SEC2=""
for SEG in "$MODEL_SEG" "$EFFORT_SEG" "$CTX_SEG"; do
  if [[ -n "$SEG" ]]; then
    [[ -n "$SEC2" ]] && SEC2+=" "
    SEC2+="$SEG"
  fi
done

# --- Section 3: rate limit usage (5h / 7d, subscription plans only — skip if data absent) ---
FIVE_SEG=""
if [[ -n "$FIVE_HOUR_PCT" && "$FIVE_HOUR_PCT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  FIVE_SEG="$(colorize_pct "${FIVE_HOUR_PCT%.*}")"
  if [[ -n "$FIVE_HOUR_RESET" ]]; then
    FIVE_SEG+="${DIM_CYAN} ($(date -d "@${FIVE_HOUR_RESET}" +%H:%M))${RESET}"
  fi
fi

SEVEN_SEG=""
if [[ -n "$SEVEN_DAY_PCT" && "$SEVEN_DAY_PCT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  SEVEN_SEG="$(colorize_pct "${SEVEN_DAY_PCT%.*}")"
  if [[ -n "$SEVEN_DAY_RESET" ]]; then
    SEVEN_SEG+="${DIM_CYAN} ($(date -d "@${SEVEN_DAY_RESET}" +%a))${RESET}"
  fi
fi

SEC3=""
if [[ -n "$FIVE_SEG" && -n "$SEVEN_SEG" ]]; then
  SEC3="${FIVE_SEG}${DIM_CYAN} | ${RESET}${SEVEN_SEG}"
else
  SEC3="${FIVE_SEG}${SEVEN_SEG}"
fi

# --- Section 4: model-scoped weekly limit (Fable etc.) from the OAuth usage API ---
# The statusline stdin payload only carries account-level rate limits; the per-model
# weekly bucket (limits[].kind == "weekly_scoped") only exists on this endpoint.
# Cached with a TTL because the statusline re-renders constantly and the endpoint
# rate-limits aggressively. On fetch failure the previous cache is kept, but its
# mtime is bumped so a broken token/endpoint backs off instead of retrying per render.
USAGE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline-usage.json"
CREDS_FILE="$HOME/.claude/.credentials.json"
USAGE_CACHE_TTL=300
readonly USAGE_CACHE CREDS_FILE USAGE_CACHE_TTL

USAGE_TMP=""
trap 'rm -f "${USAGE_TMP:-}"' EXIT

refresh_usage_cache() {
  local token version
  token="$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE" 2> /dev/null)" || return 0
  [[ -n "$token" ]] || return 0
  # Endpoint requires a claude-code User-Agent; take the version from the payload
  version="$(echo "$INPUT" | jq -r '.version // "2.0.0"')"
  USAGE_TMP="$(mktemp "${USAGE_CACHE}.XXXXXX")" || return 0
  if curl -s --max-time 2 https://api.anthropic.com/api/oauth/usage \
    -H "Authorization: Bearer ${token}" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "User-Agent: claude-code/${version}" \
    -o "$USAGE_TMP" \
    && jq -e '.limits' "$USAGE_TMP" > /dev/null 2>&1; then
    mv "$USAGE_TMP" "$USAGE_CACHE"
  else
    rm -f "$USAGE_TMP"
    touch "$USAGE_CACHE" 2> /dev/null || true
  fi
  USAGE_TMP=""
}

SCOPED_SEG=""
if [[ -f "$CREDS_FILE" ]]; then
  mkdir -p "${USAGE_CACHE%/*}"
  CACHE_MTIME="$(stat -c %Y "$USAGE_CACHE" 2> /dev/null || echo 0)"
  if [[ $(($(date +%s) - CACHE_MTIME)) -ge "$USAGE_CACHE_TTL" ]]; then
    refresh_usage_cache || true
  fi
  SCOPED_JSON="$(jq -c '[.limits[]? | select(.kind == "weekly_scoped")][0] // empty' "$USAGE_CACHE" 2> /dev/null || true)"
  if [[ -n "$SCOPED_JSON" ]]; then
    SCOPED_LABEL="$(echo "$SCOPED_JSON" | jq -r '.scope.model.display_name // "model"')"
    SCOPED_PCT="$(echo "$SCOPED_JSON" | jq -r '.percent // empty')"
    if [[ "$SCOPED_PCT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      SCOPED_SEG="$(colorize_pct "${SCOPED_PCT%.*}" "${SCOPED_LABEL} ")"
    fi
  fi
fi

# --- Join non-empty sections with a dim pipe divider ---
OUTPUT=""
for SEC in "$SEC1" "$SEC2" "$SEC3" "$SCOPED_SEG"; do
  if [[ -n "$SEC" ]]; then
    [[ -n "$OUTPUT" ]] && OUTPUT+="${DIM_CYAN} | ${RESET}"
    OUTPUT+="$SEC"
  fi
done

printf "%b" "$OUTPUT"

#!/usr/bin/env bash
# Claude Code status line — starship-inspired (cyan, minimal, git-aware)

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model_name=$(echo "$input" | jq -r '.model.display_name // ""')
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
effort_level=$(echo "$input" | jq -r '.effort.level // empty')
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- Directory: last path segment only, capped to 20 chars ---
truncated_dir() {
	local d="$1"
	local home="$HOME"
	d="${d/#$home/\~}"
	local base="${d##*/}"
	if [ "${#base}" -gt 20 ]; then
		base="${base:0:19}…"
	fi
	echo "$base"
}

dir=$(truncated_dir "$cwd")

# --- Git info (skip locks to avoid interference) ---
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
	git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2> /dev/null ||
		GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2> /dev/null)

	# Cap branch name to 24 chars to keep the status line short
	if [ "${#git_branch}" -gt 24 ]; then
		git_branch="${git_branch:0:23}…"
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

# --- Section 1: directory + git (bold/dim-italic cyan) ---
sec1="${BOLD_CYAN}${dir}${RESET}"
if [ -n "$git_branch" ]; then
	sec1+=" ${DIM_ITALIC_CYAN}${git_branch}${RESET}"
fi

# --- Section 2: model / agent, effort, context usage ---
model_seg=""
if [ -n "$agent_name" ]; then
	model_seg="${CYAN}${model_name}:${agent_name}${RESET}"
elif [ -n "$model_name" ]; then
	model_seg="${CYAN}${model_name}${RESET}"
fi

effort_seg=""
if [ -n "$effort_level" ]; then
	effort_seg="${DIM_CYAN}${effort_level}${RESET}"
fi

ctx_seg=""
if [ -n "$used_pct" ]; then
	used_int=${used_pct%.*}
	if [ "$used_int" -ge 80 ]; then
		ctx_seg="${RED}${used_int}%${RESET}"
	elif [ "$used_int" -ge 50 ]; then
		ctx_seg="${YELLOW}${used_int}%${RESET}"
	else
		ctx_seg="${DIM_CYAN}${used_int}%${RESET}"
	fi
fi

sec2=""
for seg in "$model_seg" "$effort_seg" "$ctx_seg"; do
	if [ -n "$seg" ]; then
		[ -n "$sec2" ] && sec2+=" "
		sec2+="$seg"
	fi
done

# --- Section 3: rate limit usage (5h / 7d, subscription plans only — skip if data absent) ---
five_seg=""
if [[ -n "$five_hour_pct" && "$five_hour_pct" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
	five_hour_int=${five_hour_pct%.*}
	if [ "$five_hour_int" -ge 80 ]; then
		five_seg="${RED}${five_hour_int}%${RESET}"
	elif [ "$five_hour_int" -ge 50 ]; then
		five_seg="${YELLOW}${five_hour_int}%${RESET}"
	else
		five_seg="${DIM_CYAN}${five_hour_int}%${RESET}"
	fi
	[ -n "$five_hour_reset" ] && five_seg+="${DIM_CYAN} ($(date -d "@${five_hour_reset}" +%H:%M))${RESET}"
fi

seven_seg=""
if [[ -n "$seven_day_pct" && "$seven_day_pct" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
	seven_day_int=${seven_day_pct%.*}
	if [ "$seven_day_int" -ge 80 ]; then
		seven_seg="${RED}${seven_day_int}%${RESET}"
	elif [ "$seven_day_int" -ge 50 ]; then
		seven_seg="${YELLOW}${seven_day_int}%${RESET}"
	else
		seven_seg="${DIM_CYAN}${seven_day_int}%${RESET}"
	fi
	[ -n "$seven_day_reset" ] && seven_seg+="${DIM_CYAN} ($(date -d "@${seven_day_reset}" +%a))${RESET}"
fi

sec3=""
if [ -n "$five_seg" ] && [ -n "$seven_seg" ]; then
	sec3="${five_seg}${DIM_CYAN} | ${RESET}${seven_seg}"
else
	sec3="${five_seg}${seven_seg}"
fi

# --- Join non-empty sections with a dim pipe divider ---
output=""
for sec in "$sec1" "$sec2" "$sec3"; do
	if [ -n "$sec" ]; then
		[ -n "$output" ] && output+="${DIM_CYAN} | ${RESET}"
		output+="$sec"
	fi
done

printf "%b" "$output"

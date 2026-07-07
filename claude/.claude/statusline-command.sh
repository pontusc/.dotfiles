#!/usr/bin/env bash
# Claude Code status line — starship-inspired (cyan, minimal, git-aware)

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model_name=$(echo "$input" | jq -r '.model.display_name // ""')
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# --- Directory: last path segment only, capped to 24 chars ---
truncated_dir() {
	local d="$1"
	local home="$HOME"
	d="${d/#$home/\~}"
	local base="${d##*/}"
	if [ "${#base}" -gt 24 ]; then
		base="${base:0:23}…"
	fi
	echo "$base"
}

dir=$(truncated_dir "$cwd")

# --- Git info (skip locks to avoid interference) ---
git_branch=""
git_status_str=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
	git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2> /dev/null ||
		GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2> /dev/null)

	# Cap branch name to 20 chars to keep the status line short
	if [ "${#git_branch}" -gt 20 ]; then
		git_branch="${git_branch:0:19}…"
	fi

	ahead=0
	behind=0
	modified=0
	untracked=0
	staged=0
	conflicted=0
	while IFS= read -r status_line; do
		xy="${status_line:0:2}"
		case "$xy" in
		"##"*)
			if [[ "$status_line" =~ ahead\ ([0-9]+) ]]; then ahead="${BASH_REMATCH[1]}"; fi
			if [[ "$status_line" =~ behind\ ([0-9]+) ]]; then behind="${BASH_REMATCH[1]}"; fi
			;;
		"AA" | "DD" | "AU" | "UA" | "DU" | "UD" | "UU") ((conflicted++)) ;;
		" M" | "MM" | " D") ((modified++)) ;;
		"M " | "A " | "D " | "R " | "C ") ((staged++)) ;;
		"??") ((untracked++)) ;;
		esac
	done < <(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" status --porcelain=v1 -b 2> /dev/null)

	git_flags=""
	[ "$conflicted" -gt 0 ] && git_flags+=" "
	[ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ] && git_flags+="⇕⇡${ahead}⇣${behind} "
	[ "$ahead" -gt 0 ] && [ "$behind" -eq 0 ] && git_flags+="⇡${ahead} "
	[ "$behind" -gt 0 ] && [ "$ahead" -eq 0 ] && git_flags+="⇣${behind} "
	[ "$modified" -gt 0 ] && git_flags+=" "
	[ "$staged" -gt 0 ] && git_flags+=""
	[ "$untracked" -gt 0 ] && git_flags+="? "
	[ -z "$git_flags" ] && git_flags=" "

	git_status_str="$git_flags"
fi

# --- ANSI colors ---
CYAN="\033[36m"
BOLD_CYAN="\033[1;36m"
ITALIC_CYAN="\033[3;36m"
DIM_CYAN="\033[2;36m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

output=""

# Directory (bold cyan)
output+="${BOLD_CYAN}${dir}${RESET}"

# Git branch + status (italic / regular cyan)
if [ -n "$git_branch" ]; then
	output+=" ${ITALIC_CYAN}${git_branch}${RESET}"
	output+=" ${CYAN}${git_status_str}${RESET}"
fi

# Model / Agent
if [ -n "$agent_name" ]; then
	output+=" ${CYAN}${model_name}:${agent_name}${RESET}"
elif [ -n "$model_name" ]; then
	output+=" ${CYAN}${model_name}${RESET}"
fi

# Context usage (always show, color-coded by severity)
if [ -n "$used_pct" ]; then
	used_int=${used_pct%.*}
	if [ "$used_int" -ge 80 ]; then
		output+=" ${RED}${used_int}%${RESET}"
	elif [ "$used_int" -ge 50 ]; then
		output+=" ${YELLOW}${used_int}%${RESET}"
	else
		output+=" ${DIM_CYAN}${used_int}%${RESET}"
	fi
fi

# Usage cost
if [ -n "$cost_usd" ]; then
	cost_fmt=$(printf '$%.2f' "$cost_usd")
	output+=" ${DIM_CYAN}${cost_fmt}${RESET}"
fi

printf "%b" "$output"

#!/usr/bin/env bash
# PostToolUse hook for Write|Edit. When the skill matching the edited file's
# language/filetype has not been invoked in the current context window, tells the
# agent to load it and re-check the edit. Reads the hook JSON on stdin and answers
# on stdout with additionalContext — this hook never blocks.
set -euo pipefail

INPUT="$(cat)"
readonly INPUT

FILE_PATH="$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")"
PARENT_TRANSCRIPT="$(jq -r '.transcript_path // empty' <<<"$INPUT")"
AGENT_ID="$(jq -r '.agent_id // empty' <<<"$INPUT")"
readonly FILE_PATH PARENT_TRANSCRIPT AGENT_ID

[[ -n "$FILE_PATH" && -f "$PARENT_TRANSCRIPT" ]] || exit 0

# A subagent is handed the parent's transcript but records its own Skill calls in
# its own file, so look there instead. Stay silent until that file exists — its
# absence says nothing about what the agent loaded.
if [[ -n "$AGENT_ID" ]]; then
  TRANSCRIPT="${PARENT_TRANSCRIPT%.jsonl}/subagents/agent-${AGENT_ID}.jsonl"
  [[ -f "$TRANSCRIPT" ]] || exit 0
else
  TRANSCRIPT="$PARENT_TRANSCRIPT"
fi
readonly TRANSCRIPT

case "$FILE_PATH" in /tmp/*) exit 0 ;; esac

case "$FILE_PATH" in
  */.github/workflows/*.yml|*/.github/workflows/*.yaml) REQUIRED_SKILLS=(github-ci coding-principles) ;;
  *.md)                                     REQUIRED_SKILLS=(markdown) ;;
  *.tf|*.tfvars|*.hcl)                      REQUIRED_SKILLS=(terraform coding-principles) ;;
  *.sh|*.bash)                              REQUIRED_SKILLS=(bash coding-principles) ;;
  *.py)                                     REQUIRED_SKILLS=(python coding-principles) ;;
  *.go)                                     REQUIRED_SKILLS=(go coding-principles) ;;
  *.rs)                                     REQUIRED_SKILLS=(rust coding-principles) ;;
  *.lua)                                    REQUIRED_SKILLS=(lua coding-principles) ;;
  */Dockerfile|*/Dockerfile.*|*/Containerfile) REQUIRED_SKILLS=(docker coding-principles) ;;
  */Makefile|*/makefile|*/GNUmakefile|*.mk) REQUIRED_SKILLS=(makefile coding-principles) ;;
  *)                                        exit 0 ;;
esac
readonly REQUIRED_SKILLS

# A compaction drops the obligation from context, so only entries after the most
# recent compact summary count as "still loaded".
WINDOW_START=$(($(awk '/"isCompactSummary":true/ {line=NR} END {print line+0}' "$TRANSCRIPT") + 1))
readonly WINDOW_START

MISSING=()
for SKILL in "${REQUIRED_SKILLS[@]}"; do
  # A skill is in context via a Skill tool call or a frontmatter preload (a
  # <command-message> meta entry). The optional prefix covers directory-scoped
  # names like claude:markdown; both markers stay quote-anchored so the same
  # strings quoted inside file content (JSON-escaped) never match.
  PATTERN="\"skill\":\"([^\"]*:)?${SKILL}\"|\"text\":\"<command-message>([^\"]*:)?${SKILL}</command-message>"
  # Process substitution keeps grep's early exit from tripping pipefail on tail.
  if ! grep -qE "$PATTERN" < <(tail -n "+${WINDOW_START}" "$TRANSCRIPT"); then
    MISSING+=("$SKILL")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  jq -n --arg skills "${MISSING[*]}" --arg file "$FILE_PATH" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: ("You just edited \($file) without loading the \($skills) skill(s), which CLAUDE.md requires before editing a file of this type. Invoke \($skills) now, then re-read what you just wrote and fix anything that violates it before moving on.")}}'
fi

# Tool initialization

# Starship prompt
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

# Zoxide (smarter cd)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

# fzf key bindings and completion
if command -v fzf &>/dev/null; then
  eval "$(fzf --bash)"
fi

# dcg: warn if hook was silently removed from Claude Code settings
if command -v dcg &>/dev/null && command -v jq &>/dev/null; then
  if [ -f "$HOME/.claude/settings.json" ] && \
     ! jq -e '.hooks.PreToolUse[]? | select(.hooks[]?.command | test("dcg$"))' \
       "$HOME/.claude/settings.json" &>/dev/null; then
    printf '\033[1;33m[dcg] Hook missing from ~/.claude/settings.json — run: dcg install\033[0m\n'
  fi
fi

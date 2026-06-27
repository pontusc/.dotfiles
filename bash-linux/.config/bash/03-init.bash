# Tool initialization (previously handled by the Omarchy framework)

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

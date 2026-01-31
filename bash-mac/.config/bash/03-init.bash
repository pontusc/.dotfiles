# mise (polyglot runtime manager)
if command -v mise &> /dev/null; then
  eval "$(mise activate bash)"
fi

# starship (cross-shell prompt)
if command -v starship &> /dev/null; then
  eval "$(starship init bash)"
fi

# zoxide (smarter cd command)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init bash)"
fi

# fzf (fuzzy finder) - Homebrew paths
if command -v fzf &> /dev/null; then
  # Try Apple Silicon path first, then Intel Mac path
  if [[ -f /opt/homebrew/opt/fzf/shell/completion.bash ]]; then
    source /opt/homebrew/opt/fzf/shell/completion.bash
  elif [[ -f /usr/local/opt/fzf/shell/completion.bash ]]; then
    source /usr/local/opt/fzf/shell/completion.bash
  fi

  if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.bash ]]; then
    source /opt/homebrew/opt/fzf/shell/key-bindings.bash
  elif [[ -f /usr/local/opt/fzf/shell/key-bindings.bash ]]; then
    source /usr/local/opt/fzf/shell/key-bindings.bash
  fi
fi

# Google Cloud SDK - bash-specific files
if [[ -f "$HOME/google-cloud-sdk/path.bash.inc" ]]; then
  source "$HOME/google-cloud-sdk/path.bash.inc"
fi
if [[ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]]; then
  source "$HOME/google-cloud-sdk/completion.bash.inc"
fi

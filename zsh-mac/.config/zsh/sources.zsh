# Initialize Zsh Completion System
autoload -Uz compinit
compinit

# Use the Zsh specific .inc files if they exist
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
    source "$HOME/google-cloud-sdk/path.zsh.inc"
fi
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
    source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

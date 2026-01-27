# Initialize Homebrew Completions (Zsh specific)
if type brew &> /dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

source <(sesh completion zsh)
source <(kubectl completion zsh)
# Allows 'k' to complete like 'kubectl'
compdef k=kubectl

# Initialize the autocompletion
autoload -Uz compinit && compinit -i

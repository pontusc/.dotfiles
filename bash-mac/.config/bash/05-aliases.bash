# File system (replicate Omarchy eza aliases)
if command -v eza &> /dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

# Fuzzy file finder
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

# Zoxide-enhanced cd (replicate Omarchy zd function)
if command -v zoxide &> /dev/null; then
  alias cd="zd"
  zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && return
    elif [ -d "$1" ]; then
      builtin cd "$1"
    else
      z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
  }
fi

# Shorthands
alias bsource="source ~/.bashrc"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias vi='nvim'

# Python virtual environment
alias ve="python3 -m venv ./venv"
alias va="source ./venv/bin/activate"
alias da="deactivate"

# Kubernetes
alias k="kubectl"
alias kns="kubectl config set-context --current --namespace"
alias mkube="minikube"
alias t="talosctl"

# Config files (note: no hconf for macOS)
alias nconf="nvim -c \"cd ~/.config/nvim/\""
alias bconf="nvim ~/.bashrc"
alias tconf="nvim ~/.config/tmux/tmux.conf"

# Lazy tools
alias lgt="lazygit"
alias ldk="lazydocker"

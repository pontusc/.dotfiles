# Shorthands
alias bsource="source ~/.bashrc"
alias vi='nvim'
alias unstow='stow --delete'

# Fix watch command and aliases
alias watch='watch ' # the trailing space forces bash to expand next word apparently

# Navigation (zd defined in 04-functions.bash, zoxide init in 03-init.bash)
command -v zoxide &>/dev/null && alias cd="zd"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# eza-backed ls replacements
if command -v eza &>/dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='eza -lah --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

# Python virtual environment
alias ve="python3 -m venv ./venv"
alias va="source ./venv/bin/activate"
alias da="deactivate"

# Terraform
alias tf="terraform"
alias tg="terragrunt"

# Kubernetes (kns/kcs are fzf-backed functions in 04-functions.bash)
alias k="kubectl"
alias mkube="minikube"
alias t="talosctl"
alias hubble="kubectl exec -it -n gke-managed-dpv2-observability deployment/hubble-relay -c hubble-cli -- hubble"

# Config files
alias nconf="nvim -c \"cd ~/.config/nvim/\""
alias bconf="nvim ~/.config/bash"
alias hconf="nvim ~/.config/hypr/"
alias tconf="nvim ~/.config/tmux/tmux.conf"
alias sconf="nvim ~/.ssh/config"

# Lazy tools
alias lgt="lazygit"
alias ldk="lazydocker"

# IP check
alias whatsmyip="curl -s https://ifconfig.me"

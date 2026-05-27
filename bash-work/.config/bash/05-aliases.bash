# Shorthands
alias bsource="source ~/.bashrc"
alias vi='nvim'
alias unstow='stow --delete'

# Fix watch command and aliases
alias watch='watch ' # the trailing space forces bash to expand next word apparently

# Python virtual environment
alias ve="python3 -m venv ./venv"
alias va="source ./venv/bin/activate"
alias da="deactivate"

# Terraform
alias tf="terraform"
alias tg="terragrunt"

# Kubernetes
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

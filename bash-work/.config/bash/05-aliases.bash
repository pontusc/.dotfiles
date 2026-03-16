# Shorthands
alias bsource="source ~/.bashrc"
alias vi='nvim'

# Python virtual environment
alias ve="python3 -m venv ./venv"
alias va="source ./venv/bin/activate"
alias da="deactivate"

# Terraform
alias tf="terraform"
alias tg="terragrunt"

# Kubernetes
alias k="kubectl"
alias kns="kubectl config set-context --current --namespace"
alias mkube="minikube"
alias t="talosctl"

# Config files
alias nconf="nvim -c \"cd ~/.config/nvim/\""
alias bconf="nvim ~/.config/bash"
alias hconf="nvim ~/.config/hypr/"
alias tconf="nvim ~/.config/tmux/tmux.conf"

# Lazy tools
alias lgt="lazygit"
alias ldk="lazydocker"

# IP check
alias whatsmyip="curl -s https://ifconfig.me"

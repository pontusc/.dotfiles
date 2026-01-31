# Shorthands
alias bsource="source ~/.bashrc"

# Python virtual environment
alias ve="python3 -m venv ./venv"
alias va="source ./venv/bin/activate"
alias da="deactivate"

# Kubernetes
alias k="kubectl"
alias mkube="minikube"
alias kubeseal="kubeseal --controller-name sealed-secrets --controller-namespace utils"

# Config files
alias nconf="nvim -c \"cd ~/.config/nvim/\""
alias bconf="nvim ~/.bashrc"
alias hconf="nvim ~/.config/hypr/"
alias tconf="nvim ~/.config/tmux/tmux.conf"

# Lazy tools
alias lgt="lazygit"
alias ldk="lazydocker"

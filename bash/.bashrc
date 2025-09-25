# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# --- aliases
# python
alias ve="python3 -m venv ./venv"
alias va="source ./venv/bin/activate"
alias da="deactivate"

# Kubernetes
alias kube="kubectl"
alias mkube="minikube"

# Neovim
alias nconf="nvim ~/.config/nvim/"
alias bconf="nvim ~/.bashrc"
alias hconf="nvim ~/.config/hypr/"

# Lazy
alias lgt="lazygit"
alias ldk="lazydocker"

# --- exports
export KUBECONFIG=$HOME/.kube/config

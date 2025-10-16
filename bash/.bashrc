# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# --- aliases
# python
alias ve="python3 -m venv ./venv"
alias va="source ./venv/bin/activate"
alias da="deactivate"

# Kubernetes
alias k="kubectl"
alias mkube="minikube"
alias kubeseal="kubeseal --controller-name sealed-secrets --controller-namespace utils"

# Configfiles
alias nconf="nvim -c \"cd ~/.config/nvim/\""
alias bconf="nvim ~/.bashrc"
alias hconf="nvim ~/.config/hypr/"
alias tconf="nvim ~/.config/tmux/tmux.conf"

# Lazy
alias lgt="lazygit"
alias ldk="lazydocker"

# --- exports
# Editor
export EDITOR="/usr/bin/nvim"
export SUDO_EDITOR="$EDITOR"

# Kubernetes
export KUBECONFIG=$HOME/.kube/config

# --- completions
source <(kubectl completion bash)
complete -o default -F __start_kubectl k

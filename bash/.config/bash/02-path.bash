# Custom binary paths
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Mason-managed tools (LSPs, formatters, linters) — appended so system packages win
export PATH="$PATH:$HOME/.local/share/nvim/mason/bin"

# Krew (kubectl plugin manager; only present on k8s machines)
[[ -d "${KREW_ROOT:-$HOME/.krew}/bin" ]] && export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/pontusc/google-cloud-sdk/path.bash.inc' ]; then . '/home/pontusc/google-cloud-sdk/path.bash.inc'; fi

# Kubernetes
export KUBECONFIG=$HOME/.kube/config

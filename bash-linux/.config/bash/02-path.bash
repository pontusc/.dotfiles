# Custom binary paths
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/pontusc/google-cloud-sdk/path.bash.inc' ]; then . '/home/pontusc/google-cloud-sdk/path.bash.inc'; fi

# Kubernetes
export KUBECONFIG=$HOME/.kube/config

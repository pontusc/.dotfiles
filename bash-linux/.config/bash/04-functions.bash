# Launch tmux in default session if exists, make if not
tmux() {
    if [ $# -eq 0 ]; then
        command tmux attach -t default || command tmux new -s default
    else
        command tmux "$@"
    fi
}

kds() {
  if [ -z "$1" ]; then
    echo "Usage: kds <secret-name> [-n <namespace>]"
    return 1
  fi
  
  # Extracts the secret name
  local secret_name=$1
  # Shifts the arguments so any remaining flags (like -n argocd) are passed to kubectl
  shift
  
  kubectl get secret "$secret_name" "$@" -o json | jq '.data | map_values(@base64d)'
}

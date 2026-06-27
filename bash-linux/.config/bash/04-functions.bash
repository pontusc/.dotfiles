# Launch tmux in default session if exists, make if not
tmux() {
  if [ $# -eq 0 ]; then
    command tmux new-session -A -s default
  else
    command tmux "$@"
  fi
}

# zoxide-backed cd: builtin cd for real paths, zoxide jump otherwise
zd() {
  if (( $# == 0 )); then
    builtin cd ~ || return
  elif [[ -d $1 ]]; then
    builtin cd "$1" || return
  else
    if ! z "$@"; then
      echo "Error: Directory not found"
      return 1
    fi

    printf "\U000F17A9 "
    pwd
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

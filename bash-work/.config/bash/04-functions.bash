# Launch tmux in default session if exists, make if not
tmux() {
  if [ $# -eq 0 ]; then
    command tmux new-session -A -s default
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

kgl() {
  if [ -z "$1" ]; then
    echo "Usage: kgl <pod-name> [-n <namespace>]"
    return 1
  fi

  # Extracts the pod name
  local pod_name=$1
  # Shifts so any remaining flags (like -n argocd) pass through to kubectl
  shift

  local json
  json=$(kubectl get pod "$pod_name" "$@" -o json) || return 1

  echo "--- LABELS ---"
  echo "$json" | jq -r '.metadata.labels // {} | to_entries[] | "\(.key)=\(.value)"'

  local annotations
  annotations=$(echo "$json" | jq -r '.metadata.annotations // {} | to_entries[] | "\(.key): \(.value)"')
  if [[ -n "$annotations" ]]; then
    echo "--- ANNOTATIONS ---"
    echo "$annotations"
  fi
}

kcs() {
  kubectl config use-context "$(kubectl config get-contexts -o name | fzf)"
}

kns() {
  kubectl config set-context --current --namespace "$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | fzf)"
}

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

kpvc() {
  local pvc_rows usage_rows

  if [[ "$1" != "-A" && "$1" != "--all-namespaces" && -n "$1" ]]; then
    # Single PVC in the current namespace
    local pvc=$1
    pvc_rows=$(kubectl get pvc "$pvc" -o json |
      jq -r '"\(.metadata.namespace)\t\(.metadata.name)\t\(.status.phase)\t\(.status.capacity.storage // "?")"') || return 1
    # kubectl's NotFound goes to stderr but the pipe exits 0 via jq; bail on empty
    [[ -z "$pvc_rows" ]] && return 1

    # Find the node hosting the pod that mounts this PVC, then query only that node
    local node
    node=$(kubectl get pod -o json |
      jq -r --arg pvc "$pvc" 'first(.items[] |
        select(.spec.volumes[]?.persistentVolumeClaim.claimName == $pvc) | .spec.nodeName)')

    if [[ -n "$node" && "$node" != "null" ]]; then
      usage_rows=$(kubectl get --raw "/api/v1/nodes/${node}/proxy/stats/summary" 2> /dev/null |
        jq -r --arg pvc "$pvc" '.pods[].volume[]? | select(.pvcRef.name == $pvc) |
          "\(.pvcRef.namespace)\t\(.pvcRef.name)\t\(.usedBytes)\t\(.capacityBytes)"')
    fi
  else
    # List mode: current namespace (default), or all namespaces with -A
    local scope=()
    [[ "$1" == "-A" || "$1" == "--all-namespaces" ]] && scope=(-A)
    pvc_rows=$(kubectl get pvc "${scope[@]}" -o json |
      jq -r '.items[] | "\(.metadata.namespace)\t\(.metadata.name)\t\(.status.phase)\t\(.status.capacity.storage // "?")"') || return 1

    # Bail before the node scan if there are no PVCs to report on
    if [[ -z "$pvc_rows" ]]; then
      echo "No PVCs found"
      return 0
    fi

    # Pull every node's kubelet summary once
    usage_rows=$(
      for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
        kubectl get --raw "/api/v1/nodes/${node}/proxy/stats/summary" 2> /dev/null
      done | jq -r '.pods[].volume[]? | select(.pvcRef != null) |
        "\(.pvcRef.namespace)\t\(.pvcRef.name)\t\(.usedBytes)\t\(.capacityBytes)"'
    )
  fi

  {
    printf 'NAMESPACE\tPVC\tSTATUS\tUSED\tCAPACITY\tUSE%%\n'
    awk -F'\t' '
      function human(b,   s, i, units) {
        if (b == "" || b == "null") return "-"
        split("Ki Mi Gi Ti Pi", units, " ")
        if (b + 0 < 1024) return b "B"
        s = b + 0; i = 0
        while (s >= 1024 && i < 5) { s = s / 1024; i++ }
        return sprintf("%.1f%s", s, units[i])
      }
      NR == FNR { u[$1"/"$2] = $3; c[$1"/"$2] = $4; next }
      {
        key = $1"/"$2
        if (key in u && c[key] + 0 > 0) {
          printf "%s\t%s\t%s\t%s\t%s\t%.0f%%\n", \
            $1, $2, $3, human(u[key]), human(c[key]), u[key] / c[key] * 100
        } else {
          printf "%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, "-", $4, "-"
        }
      }
    ' <(echo "$usage_rows") <(echo "$pvc_rows" | sort -t$'\t' -k1,1 -k2,2)
  } | column -t -s $'\t'
}

kcs() {
  kubectl config use-context "$(kubectl config get-contexts -o name | fzf)"
}

kns() {
  kubectl config set-context --current --namespace "$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | fzf)"
}

# Launch a temporary network testing pod in Kubernetes
kube-netshell() {
  local namespace="${1:-}"
  if [[ -z "$namespace" ]]; then
    read -rp "Namespace (empty for default): " namespace
  fi
  local ns_args=()
  [[ -n "$namespace" ]] && ns_args=(-n "$namespace")
  kubectl run tmp-shell --rm -it --restart=Never --image=nicolaka/netshoot "${ns_args[@]}" -- bash
}

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

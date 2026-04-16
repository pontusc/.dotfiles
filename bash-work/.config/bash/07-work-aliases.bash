# OpenVPN Shortcuts
# OpenVPN configuration is located at /etc/openvpn/client/alchemy.conf
alias vpn-up='sudo systemctl start openvpn-client@alchemy && echo "VPN Starting..." && sleep 2 && curl -s https://ifconfig.me && echo ""'
alias vpn-down='sudo systemctl stop openvpn-client@alchemy && echo "VPN Stopped."'
alias vpn-stat='systemctl status openvpn-client@alchemy'

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

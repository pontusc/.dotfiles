# shellcheck disable=SC1090,SC1091

# Sesh completions
if command -v sesh &> /dev/null; then
  source <(sesh completion bash)
fi

# Talosctl completions
if command -v talosctl &> /dev/null; then
  source <(talosctl completion bash)
  complete -o default -F __start_talosctl t
fi

# Kubectl completions
if command -v kubectl &> /dev/null; then
  source <(kubectl completion bash)
  complete -o default -F __start_kubectl k
fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/pontusc/google-cloud-sdk/completion.bash.inc' ]; then . '/home/pontusc/google-cloud-sdk/completion.bash.inc'; fi

# Terraform completions
if command -v terraform &> /dev/null; then
  complete -o nospace -C terraform tf
fi

# Terraform completions
if command -v netbird &> /dev/null; then
  source <(netbird completion bash)
fi

# kgl: complete pod names in the current namespace
_kgl_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  mapfile -t COMPREPLY < <(compgen -W "$(kubectl get pods -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)" -- "$cur")
}
complete -F _kgl_completions kgl

# kds: complete secret names in the current namespace
_kds_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  mapfile -t COMPREPLY < <(compgen -W "$(kubectl get secrets -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)" -- "$cur")
}
complete -F _kds_completions kds

# kpvc: complete PVC names in the current namespace
_kpvc_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  mapfile -t COMPREPLY < <(compgen -W "$(kubectl get pvc -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)" -- "$cur")
}
complete -F _kpvc_completions kpvc

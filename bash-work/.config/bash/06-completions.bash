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

# Sesh completions
if command -v sesh &> /dev/null; then
  source <(sesh completion bash)
fi

# Kubectl completions
if command -v kubectl &> /dev/null; then
  source <(kubectl completion bash)
  complete -o default -F __start_kubectl k
fi

# Editor
export EDITOR="/usr/bin/nvim"
export GIT_EDITOR="$EDITOR"
export SUDO_EDITOR="$EDITOR"

# Terraform
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# ArgoCD CLI
export ARGOCD_OPTS="--grpc-web"

# lazygit
# A missing file in LG_CONFIG_FILE aborts lazygit at startup.
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
omarchy_lazygit_theme="$HOME/.local/state/omarchy/current/theme/lazygit.yml"
if [[ -f $omarchy_lazygit_theme ]]; then
  LG_CONFIG_FILE="$LG_CONFIG_FILE,$omarchy_lazygit_theme"
fi
unset omarchy_lazygit_theme

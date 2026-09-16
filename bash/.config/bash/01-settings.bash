# Editor
export EDITOR="/usr/bin/nvim"
export GIT_EDITOR="$EDITOR"
export SUDO_EDITOR="$EDITOR"

# Terraform
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# ArgoCD CLI
export ARGOCD_OPTS="--grpc-web"

# lazygit
# A missing path in LG_CONFIG_FILE aborts lazygit at startup, so each entry is added only when present.
lazygit_configs=""
for lazygit_config in "$HOME/.config/lazygit/config.yml" \
  "$HOME/.local/state/omarchy/current/theme/lazygit.yml"; do
  if [[ -f $lazygit_config ]]; then
    lazygit_configs="${lazygit_configs:+$lazygit_configs,}$lazygit_config"
  fi
done
if [[ -n $lazygit_configs ]]; then
  export LG_CONFIG_FILE="$lazygit_configs"
fi
unset lazygit_config lazygit_configs

# starship
# Unset, starship reads ~/.config/starship.toml, which carries the same prompt
# in the stock cyan.
omarchy_starship_config="$HOME/.local/state/omarchy/current/theme/starship.toml"
if [[ -f $omarchy_starship_config ]]; then
  export STARSHIP_CONFIG="$omarchy_starship_config"
fi
unset omarchy_starship_config

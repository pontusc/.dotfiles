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

# starship
# Unset, starship reads ~/.config/starship.toml, which carries the same prompt
# in the stock cyan.
omarchy_starship_config="$HOME/.local/state/omarchy/current/theme/starship.toml"
if [[ -f $omarchy_starship_config ]]; then
  export STARSHIP_CONFIG="$omarchy_starship_config"
fi
unset omarchy_starship_config

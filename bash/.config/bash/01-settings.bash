# Editor
export EDITOR="/usr/bin/nvim"
export GIT_EDITOR="$EDITOR"
export SUDO_EDITOR="$EDITOR"

# Terraform
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# ArgoCD CLI
export ARGOCD_OPTS="--grpc-web"

# Claude Code
export CLAUDE_CODE_TMPDIR=/var/tmp

# gh-enhance, a bubbletint palette id, no custom colors and no omarchy follow
export ENHANCE_THEME="monokai_pro_filter_ristretto"

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

# fzf
# A missing path in FZF_DEFAULT_OPTS_FILE aborts fzf at startup.
omarchy_fzf_config="$HOME/.local/state/omarchy/current/theme/fzfrc"
if [[ -f $omarchy_fzf_config ]]; then
  export FZF_DEFAULT_OPTS_FILE="$omarchy_fzf_config"
fi
unset omarchy_fzf_config

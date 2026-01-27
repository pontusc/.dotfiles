# Set the directory where your modules live
export ZSH_CONFIG_DIR="$HOME/.config/zsh"

source "$ZSH_CONFIG_DIR"/00-antidote.zsh

# Source all .zsh files in the directory
if [[ -d "$ZSH_CONFIG_DIR" ]]; then
  for config_file in "$ZSH_CONFIG_DIR"/*.zsh; do
    source "$config_file"
  done
fi

unset config_file

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

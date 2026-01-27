# Set the directory where your modules live
export ZSH_CONFIG_DIR="$HOME/.config/zsh"

# Setup plugin manager
source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
antidote load ~/.config/zsh_plugins/zsh_plugins.txt

# Source all .zsh files in the directory
if [[ -d "$ZSH_CONFIG_DIR" ]]; then
  for config_file in "$ZSH_CONFIG_DIR"/*.zsh; do
    source "$config_file"
  done
fi

echo "zsh"
unset config_file

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

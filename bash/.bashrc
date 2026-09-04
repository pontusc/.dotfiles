# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Source all config files in order
export BASH_CONFIG_DIR="$HOME/.config/bash"
if [[ -d "$BASH_CONFIG_DIR" ]]; then
  for config_file in "$BASH_CONFIG_DIR"/*.bash; do
    [[ -f "$config_file" ]] && source "$config_file"
  done
fi
unset config_file

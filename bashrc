#!/bin/bash
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Use bash-completion, if available
[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && \
    . /usr/share/bash-completion/bash_completion

# --- Editor
export VISUAL="/opt/nvim-linux-x86_64/bin/nvim"
export EDITOR="$VISUAL"
export SUDO_EDITOR="$VISUAL"

# --- Add programs to path
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

# --- Global program settings & envvars
# Add settings to FZF to show .dotfiles but hide gitignored files
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
# LS
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"
# Yamllint
export YAMLLINT_CONFIG_FILE=$HOME/.config/nvim/.yamllint.yml

# --- User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi

# Source computer (e.g. homelab vs laptop) specific shell settings
if [ -d ~/.bashrc.d/settings ]; then
    for opts in ~/.bashrc.d/settings/*; do
        if [ -f "$opts" ]; then
            . "$opts"
        fi
    done
fi

# Source bashcompletion sources and related scripts
if [ -d ~/.bash_completion ]; then
    for bcomp in ~/.bash_completion/*; do
        if [ -f "$bcomp" ]; then
            . "$bcomp"
        fi
    done
fi

# --- Fin

# Print TODO-list if not empty
grep -v '^#' ~/notes/TODO | cat

# Prompt
eval "$(starship init bash)"

complete -C /usr/bin/terraform terraform

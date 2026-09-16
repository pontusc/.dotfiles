# Dotfiles

Managed using GNU Stow

## Reminders

Structure: "name-of-package"/path-to/destination
stow "package-to-install" to set up symlinks
stow -D "package-to-uninstall" to remove symlinks

## OMP on Omarchy

Install both packages with `stow omp omarchy`, then apply an Omarchy theme to generate the OMP palette. Restart OMP once after setup so it starts with the custom theme's file watcher. Subsequent Omarchy theme switches update OMP live. Changing the theme through Appearance settings alone does not start the watcher in the current OMP runtime.

## Required tools

- stow
- kitty
- tmux and TPM
- starship
- lazygit
- lazydocker
- fzf
- ripgrep
- zoxide
- eza
- uv
- stylua
- dcg, from github.com/Dicklesworthstone/destructive_command_guard, and jq
- shellcheck and lua-language-server, installed by nvim through Mason

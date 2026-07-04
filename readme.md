# Dotfiles

Managed using GNU Stow

## Reminders

Structure: "name-of-package"/path-to/destination  
stow "package-to-install" to set up symlinks  
stow -D "packate-to-uninstall" to remove symlinks

## Required tools

kitty  
neovim (config: ssh clone of github.com/pontusc/nvim into ~/.config/nvim)  
tmux & plugin manager (tpm: git clone into ~/.tmux/plugins/tpm)  
starship  
lazygit  
lazydocker  
fzf  
ripgrep  
zoxide  
eza  
dcg — destructive command guard for the Claude Code Bash hook (github.com/Dicklesworthstone/destructive_command_guard); install the release binary to ~/.local/bin/dcg (the `claude` package registers the hook and provides ~/.config/dcg/config.toml — skip the installer's --easy-mode, it rewrites settings.json)

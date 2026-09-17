# Dotfiles

Managed using GNU Stow

## Reminders

Structure: "name-of-package"/path-to/destination
stow "package-to-install" to set up symlinks
stow -D "package-to-uninstall" to remove symlinks

## OMP on Omarchy

Install both packages with `stow omp omarchy`, then apply an Omarchy theme to generate the OMP palette. Restart OMP once after setup so it starts with the custom theme's file watcher. Subsequent Omarchy theme switches update OMP live. Changing the theme through Appearance settings alone does not start the watcher in the current OMP runtime.

## Vivaldi on Omarchy

Install the packages and browser UI modification from the repository root as your desktop user:

```bash
make install-vivaldi
```

The target runs Stow, prompts for sudo to patch Vivaldi's system resources, and reapplies the current Omarchy theme. Stow alone is not sufficient. Restart Vivaldi once after it completes. Subsequent theme switches update its interface within about a second, without a debugging port or local server. The integration selects its own Omarchy theme and disables Vivaldi's theme scheduling.

Run `make install-vivaldi` again after Vivaldi updates, then restart the browser. The modification uses Vivaldi's internal API and may need changes when that API changes. The installation supports one desktop user and shares that user's palette with every Vivaldi profile using this installation.

To stop syncing, remove the `omarchy-theme.js` script tag from `/opt/vivaldi/resources/vivaldi/window.html`, restart Vivaldi, and select your preferred theme and scheduling settings.

## Required tools

- stow
- make
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

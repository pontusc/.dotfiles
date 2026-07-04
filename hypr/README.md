# hypr — shared Hyprland Lua config

Fresh, custom Hyprland config (native Lua) meant to be the one hypr package for
all hosts. Currently laptop-only; host branching comes with `config/host.lua`
(Phase 3), multimonitor/clamshell in Phase 5. Full plan and phase log:
`docs/hypr-lua-migration.md`.

(Stow ignores this README by default — it never gets symlinked into `~`.)

## Required packages

```
sudo pacman -S --needed stow waybar walker mako hyprpolkitagent hyprlock playerctl \
    tmux brightnessctl grim slurp wl-clipboard kitty ttf-jetbrains-mono-nerd \
    vivaldi dolphin btop
```

What each is for:

| Package | Role |
|---|---|
| waybar | bar (config in the `waybar/` stow package) |
| walker | launcher / clipboard / emoji (config in the `walker/` stow package) |
| mako | notifications (config in the `mako/` stow package) |
| hyprpolkitagent | polkit auth dialogs (started via its systemd user unit) |
| hyprlock | lock screen — SUPER+CTRL+L (`hyprlock.conf` in this package) |
| playerctl, brightnessctl, wpctl (wireplumber) | hardware keys in `config/binds.lua` |
| grim, slurp, wl-clipboard | screenshot binds |
| kitty, vivaldi, dolphin, btop, tmux | `config/defaults.lua` default apps + terminal binds (kitty config: the `kitty/` stow package) |
| stow | deploys these packages (repo-wide prerequisite) |

Walker needs **elephant** (its provider daemon) which is AUR-only — the CachyOS
walker package doesn't declare it. Install paru (`sudo pacman -S paru`, it's in
the cachyos repo) and then the providers the walker config uses:

```
paru -S --needed elephant-bin elephant-desktopapplications-bin \
    elephant-websearch-bin elephant-providerlist-bin elephant-files-bin \
    elephant-symbols-bin elephant-calc-bin elephant-clipboard-bin \
    elephant-menus-bin

# elephant installs its own *user* unit (no packaged unit file exists):
elephant service enable
systemctl --user start elephant.service
```

Deferred (Phase 4, add when set up): `hypridle hyprpaper hyprsunset`.

## Install on a new host

```sh
# 1. Get the stock config out of the way (keep it as reference)
mv ~/.config/hypr ~/.config/hypr.stock

# 2. Stow this package + its companions from the repo root
cd ~/dotfiles && stow hypr waybar walker kitty mako

# 3. Reload (or just log out/in)
hyprctl reload
```

Autostart is done from `config/autostart.lua`, not XDG autostart or uwsm —
the CachyOS Hyprland session has no uwsm, so XDG autostart entries never run.

## Removing Noctalia (CachyOS installs)

Noctalia provides bar, launcher, OSD, notifications, lock, polkit agent — all
stock keybinds are `qs ... ipc call` and die with it. Install the packages
above and stow *before* removing:

```sh
sudo pacman -Rns noctalia-shell noctalia-qs cachyos-hypr-noctalia
```

## Where things live

- Keybinds: `config/binds.lua` — notable choices: SUPER+W close,
  SUPER+SHIFT+W force-kill mode (`hyprctl kill`), SUPER+Escape power menu
  (walker on the custom elephant menu in the `walker/` package;
  SUPER+SHIFT+Escape deliberately unbound), SUPER+F fullscreen, SUPER+E file
  manager, SUPER+O pop window out (float+pin toggle), SUPER+C/V universal
  copy/paste (CTRL+Insert / SHIFT+Insert to the focused window),
  SUPER+CTRL+V walker clipboard history, SUPER+Space walker, SUPER+comma
  dismiss notification, SUPER+P screenshot region → clipboard (no Print key
  on the laptop keyboard).
- Default apps (terminal/browser/file manager): `config/defaults.lua`.
- Bar: the `waybar/` stow package. Launcher: the `walker/` stow package.
- Autostarted daemons (waybar, mako, hyprpolkitagent, walker service):
  `config/autostart.lua`. Elephant runs as a systemd user service instead.

## Gotchas

- With the Lua config, `hyprctl dispatch` takes Lua, not conf syntax:
  `hyprctl dispatch 'hl.dsp.exec_cmd("waybar")'`.
- mako and hyprpolkitagent silently lose their D-Bus/polkit registration race
  if another shell (e.g. Noctalia) is still running — kill it first, then
  restart them.
- elephant only scans `~/.config/elephant/menus/` at provider setup — after
  adding or renaming a menu file, `systemctl --user restart elephant`
  (`elephant listproviders` should then show `menus:<name>`).

## Manual system steps (not stowable)

- **Clamshell (Phase 5, not yet done):** logind must ignore the lid so
  Hyprland can handle it — `/etc/systemd/logind.conf.d/lid.conf` with
  `HandleLidSwitch=ignore` etc. Document the exact file here when done.

## Rollback

```sh
cd ~/dotfiles && stow -D hypr waybar walker kitty mako
mv ~/.config/hypr.stock ~/.config/hypr
hyprctl reload
```

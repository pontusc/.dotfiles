# hypr — shared Hyprland Lua config

Hyprland config meant to be centralized for all consumers. Differing config should be gated behind a module checking hostname.

## Required packages

What each is for:

| Package                                       | Role                                |
| --------------------------------------------- | ----------------------------------- |
| waybar                                        | bar                                 |
| walker                                        | launcher / clipboard / emoji        |
| mako                                          | notifications                       |
| hyprpolkitagent                               | polkit auth dialogs                 |
| hyprlock                                      | lock screen                         |
| hypridle                                      | idle chain                          |
| hyprpaper                                     | wallpaper                           |
| hyprshutdown                                  | graceful logout                     |
| playerctl, brightnessctl, wpctl (wireplumber) | hardware keys in `config/binds.lua` |
| grim, slurp, wl-clipboard                     | screenshot binds                    |

### Setup

```sh
sudo pacman -S --needed - < packages.txt
```

```sh
paru -S --needed $(< packages-aur.txt)
```

## Install on a new host

```sh
# 1. Get the stock config out of the way (keep it as reference)
mv ~/.config/hypr ~/.config/hypr.stock

# 2. Stow this package from the repo root
cd ~/dotfiles && stow hypr

# 3. Reload (or just log out/in)
hyprctl reload
```

Autostart is done from `config/autostart.lua`, not XDG autostart or uwsm —
the CachyOS Hyprland session has no uwsm, so XDG autostart entries never run.

## Removing Noctalia (CachyOS installs)

Noctalia provides bar, launcher, OSD, notifications, lock, polkit agent — all
stock keybinds are `qs ... ipc call` and die with it. Install the packages
above and stow _before_ removing:

```sh
sudo pacman -Rns noctalia-shell noctalia-qs cachyos-hypr-noctalia
```

## Gotchas

- With the Lua config, `hyprctl dispatch` takes Lua, not conf syntax:
  `hyprctl dispatch 'hl.dsp.exec_cmd("waybar")'`.
- mako and hyprpolkitagent silently lose their D-Bus/polkit registration race
  if another shell (e.g. Noctalia) is still running — kill it first, then
  restart them.
- Units `WantedBy=graphical-session.target` (elephant, and most
  session-scoped user units) never start in this session: without uwsm
  nothing activates that target, and it refuses manual starts. Such units
  must be started explicitly from `config/autostart.lua`.

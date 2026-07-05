# hypr — shared Hyprland Lua config

Hyprland config meant to be centralized for all consumers. Differing config should be gated behind a module checking hostname.

## Required packages

```sh
sudo pacman -S --needed - < packages.txt
```

(`packages.txt`, `packages-aur.txt`, `CLAUDE.md`, `TODO.md` and this README are
kept out of `$HOME` by `.stow-local-ignore`.)

What each is for:

| Package                                       | Role                                                                                                                       |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| waybar                                        | bar (config: `.config/waybar/`)                                                                                            |
| walker                                        | launcher / clipboard / emoji (config: `.config/walker/`)                                                                   |
| mako                                          | notifications (config: `.config/mako/`)                                                                                    |
| hyprpolkitagent                               | polkit auth dialogs (started via its systemd user unit)                                                                    |
| hyprlock                                      | lock screen — SUPER+CTRL+L (`hyprlock.conf` in this package)                                                               |
| hypridle                                      | idle chain — 10min lock, 11min kbd backlight off, 12min display off, lock before suspend (`hypridle.conf` in this package) |
| hyprpaper                                     | wallpaper — omarchy tokyo-night images vendored in `wallpapers/` (`hyprpaper.conf` in this package)                        |
| hyprshutdown                                  | graceful logout — the power menu's Logout entry (no keybind)                                                               |
| playerctl, brightnessctl, wpctl (wireplumber) | hardware keys in `config/binds.lua`                                                                                        |
| grim, slurp, wl-clipboard                     | screenshot binds                                                                                                           |
| kitty, vivaldi, dolphin, btop, tmux           | `config/defaults.lua` default apps + terminal binds (kitty config: the `kitty/` stow package)                              |
| stow                                          | deploys these packages (repo-wide prerequisite)                                                                            |

Walker needs **elephant** (its provider daemon) which is AUR-only — the CachyOS
walker package doesn't declare it. paru (installed above, it's in the cachyos
repo) builds the providers the walker config uses:

```sh
paru -S --needed $(< packages-aur.txt)

# elephant installs its own *user* unit (no packaged unit file exists):
elephant service enable
systemctl --user start elephant.service
```

## Install on a new host

```sh
# 1. Get the stock config out of the way (keep it as reference)
mv ~/.config/hypr ~/.config/hypr.stock

# 2. Stow this package + kitty from the repo root
cd ~/dotfiles && stow hypr kitty

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

## Where things live

- Keybinds: `config/binds.lua` — notable choices: SUPER+W close,
  SUPER+SHIFT+W force-kill mode (`hyprctl kill`), SUPER+Escape power menu
  (walker on the custom elephant menu in `.config/elephant/menus/`;
  SUPER+SHIFT+Escape deliberately unbound), SUPER+F fullscreen, SUPER+E file
  manager, SUPER+O pop window out (float+pin toggle), SUPER+C/V universal
  copy/paste (CTRL+Insert / SHIFT+Insert to the focused window),
  SUPER+CTRL+V walker clipboard history, SUPER+Space walker, SUPER+comma
  dismiss notification, SUPER+P screenshot region → clipboard (no Print key
  on the laptop keyboard).
- Default apps (terminal/browser/file manager): `config/defaults.lua`.
- Bar: `.config/waybar/`. Launcher: `.config/walker/` (its elephant menus:
  `.config/elephant/`).
- Autostarted daemons (waybar, mako, hyprpolkitagent, hypridle, hyprpaper,
  elephant, walker service): `config/autostart.lua`. Elephant is a systemd
  user service, but it still needs the explicit `systemctl --user start`
  from autostart.lua — see Gotchas.

## Gotchas

- With the Lua config, `hyprctl dispatch` takes Lua, not conf syntax:
  `hyprctl dispatch 'hl.dsp.exec_cmd("waybar")'`.
- mako and hyprpolkitagent silently lose their D-Bus/polkit registration race
  if another shell (e.g. Noctalia) is still running — kill it first, then
  restart them.
- elephant only scans `~/.config/elephant/menus/` at provider setup — after
  adding or renaming a menu file, `systemctl --user restart elephant`
  (`elephant listproviders` should then show `menus:<name>`).
- Units `WantedBy=graphical-session.target` (elephant, and most
  session-scoped user units) never start in this session: without uwsm
  nothing activates that target, and it refuses manual starts. Such units
  must be started explicitly from `config/autostart.lua`.

## Manual system steps (not stowable)

- **SDDM login theme:** sddm-astronaut-theme (AUR:
  `paru -S sddm-astronaut-theme`), `pixel_sakura` variant. Two root-owned
  steps:

  ```sh
  # pick the variant (the theme's own mechanism — a line in its metadata)
  sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/pixel_sakura.conf|' \
      /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop

  # point SDDM at the theme
  sudo mkdir -p /etc/sddm.conf.d
  printf '[Theme]\nCurrent=sddm-astronaut-theme\n' | sudo tee /etc/sddm.conf.d/10-theme.conf
  ```

  Caveat: `metadata.desktop` belongs to the package, so a theme update resets
  the variant to `astronaut` — re-run the first command after upgrades.
  Preview variants without root: copy the theme dir somewhere user-owned,
  edit `ConfigFile=` in the copy's `metadata.desktop`, then
  `sddm-greeter-qt6 --test-mode --theme <copy>`.

- **Clamshell (Phase 5, done 2026-07-04):** NO logind config — the old
  `HandleLidSwitch=ignore` drop-in idea was wrong. Stock defaults already do
  the sleep policy (`HandleLidSwitch=suspend`, `HandleLidSwitchDocked=ignore`,
  docked = more than one display connected — logind.conf(5)): lid close
  undocked suspends, lid close with an external doesn't. The display side
  (eDP-1 off/on, lid-closed-at-startup, hotplug-while-closed, SUPER+M mirror
  toggle) is all native Lua in `config/monitors.lua`.

## Rollback

```sh
cd ~/dotfiles && stow -D hypr kitty
mv ~/.config/hypr.stock ~/.config/hypr
hyprctl reload
```

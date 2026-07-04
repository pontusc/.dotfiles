# Fresh Hyprland Lua config — migration plan

**Goal:** a fresh, custom Hyprland config in one `hypr/` stow package, written in
Hyprland's native Lua config, replacing Noctalia with walker + waybar. Gradual migration:
get the core working first, structure for multi-host after, hardware niceties last.

**Not the goal:** porting the old setup 1:1. The old packages (`hypr-work` foremost) are
*reference material* — see §Reference at the bottom for where things live. When a behavior
is wanted, reimplement it simply. No Omarchy structure or scripts carry over: every host
ends up on plain CachyOS Hyprland.

**Host:** this laptop (CachyOS, Hyprland 0.55.4, eDP-1 1920x1200). Desktop/work hosts
come later via the host-structure step; `hypr-laptop` is stale — retire it.

---

## Phase 1 — remove Noctalia ✅ done 2026-07-03

Noctalia is more than the bar. What it currently provides and what covers it after:

| Noctalia role | Replacement |
|---|---|
| bar | waybar (new `waybar/` stow package, minimal fresh config) |
| launcher / emoji / clipboard UI | walker (existing `walker/` package) |
| volume/brightness OSD + keys | rebind to `wpctl` / `brightnessctl` directly; OSD optional later (swayosd) |
| media keys | `playerctl` |
| notifications | mako (or defer; no notifications is livable short-term) |
| lock screen / idle | hyprlock + hypridle (can defer past Phase 2) |
| polkit agent | the polkit-agent plugin dies with Noctalia — run a standalone agent (e.g. hyprpolkitagent) |
| wallpaper | hyprpaper/swaybg, or nothing for now |
| night light | hyprsunset, later |

Steps:
1. Install replacements first: `waybar walker mako hyprpolkitagent` (+ `hyprlock
   hypridle hyprpaper` when wanted).
2. Remove `noctalia-shell noctalia-qs` (and `cachyos-hypr-noctalia` to stop skel churn).
3. The stock CachyOS keybinds are full of `qs -c noctalia-shell ipc call` — they all go
   dead at this point. Phase 2 replaces them; do Phases 1–2 in one sitting.

## Phase 2 — base functionality (core things) ✅ done 2026-07-03 (setup guide: hypr/README.md)

Minimal fresh Lua config, laptop-only, no host logic yet. Keep the CachyOS module
layout style (`hyprland.lua` requiring small `config/*.lua` files) — it's already right.

- **monitors**: eDP-1 1920x1200@60 + `,preferred,auto,auto` fallback. Nothing more yet.
- **input**: keyboard us,se + altgr-intl + compose:caps, repeat 40/600, numlock, flat
  mouse accel, touchpad natural scroll — write fresh, glance at `hypr-work/input.conf`
  as the checklist.
- **layouts/looknfeel**: dwindle, minimal gaps (work taste: gaps_in 0 / gaps_out 1),
  `middle_click_paste = false`. Fresh, small.
- **bindings**: write from muscle memory, `hypr-work/bindings.conf` as the reminder list.
  Core set: SUPER+Return terminal, vim-HJKL focus/swap/resize, workspace 1-10 switch/move,
  SUPER+Q close, float/fullscreen toggles, SUPER+TAB group-next, SUPER+CTRL+L lock (once
  hyprlock exists), SUPER+Space walker, volume/brightness/media hardware keys via
  wpctl/brightnessctl/playerctl. No unbind dance — we own the whole file now.
- **autostart**: waybar, mako, polkit agent, `dbus-update-activation-environment`.
- **waybar**: new `waybar/` package, start near-default; make it pretty later.
- **walker**: stow the existing package; verify it still fits current walker version.

Deploy: `mv ~/.config/hypr ~/.config/hypr.cachyos-stock && cd ~/dotfiles && stow hypr
waybar walker`. Rollback = unstow + move back.

## Phase 3 — structure the Lua for hosts

Once the laptop works, refactor (no behavior change):

- `config/host.lua`: detect host from `/etc/hostname` (`laptop` today; confirm desktop/
  work names). Expose `host.name` and `host.is(...)`.
- Host-varying config becomes Lua tables keyed by hostname (monitors, per-host
  windowrules, envs like the desktop's NVIDIA block) — data branches, not file copies.
- Keep modules small; a host earns its own file only when its block gets big.

## Phase 4 — testdrive, iterate

Daily-drive it. Fix what annoys. Candidates in likely order:

- **central theming**: scheme is Tokyo Night (night); the single source of truth is
  folke/tokyonight.nvim, as a *convention*, not a tool: vendor its official extra
  verbatim where one exists (kitty ✅ done 2026-07-04, byte-identical to upstream;
  extras also cover fzf/btop/lazygit/eza/tmux for later), hand-port its hex where none
  does (mako ✅ done 2026-07-04, new `mako/` package, colors from the dunst extra).
  tmux and starship as configured in this repo are already correct — leave them.
  hyprlock ✅ done 2026-07-04 (ad-hoc `#111826`/`#82dccc` → canonical night values,
  blue `#7aa2f7` accent; background now `path = screenshot` + 3 blur passes so it
  follows the live wallpaper); waybar ✅ done 2026-07-04, see its bullet below;
  walker's tokyonight theme is already canonical. btop ✅ done 2026-07-04: new
  `btop/` package ships folke's extra verbatim (`themes/tokyonight_night.theme`);
  `btop.conf` stays host-local (btop rewrites it on exit — would fight a symlink).
  lazygit ✅ done 2026-07-04: new `lazygit/` package, folke's extra verbatim as the
  entire `config.yml` (it's a complete standalone config). dolphin ✅ RESOLVED by
  replacement 2026-07-04: **dropped for yazi** (folke ships an official
  `extras/yazi` theme). Rationale: theming dolphin properly needed
  `plasma-integration` + `breeze`, which hard-pulls `xdg-desktop-portal-kde` →
  `plasma-workspace` → kwin/kscreenlocker — ~62 packages / ~275 MiB for one file
  manager; the gtk3 route tested-failed (no dark GTK theme installed; omarchy is
  no template — zero Qt6/Dolphin theming, kvantum is Qt5-only, its Nautilus is
  plain Adwaita-dark). New `yazi/` package ships folke's
  `extras/yazi/tokyonight_night.toml` verbatim as `theme.toml`, stowed (folded:
  `~/.config/yazi` → repo; one local patch: `name =` → `url =` in `[filetype]`
  rules — key renamed in yazi 25.x, folke's extra not yet updated). Super+E
  opens it via `FILE_MANAGER = TERMINAL .. " -e yazi"` in `defaults.lua`.
  Removed: `dolphin/` package (its salvaged
  `TokyoNight.colors` is gone with it), host `~/.config/kdeglobals`, and
  `~/.local/share/color-schemes/`. User runs: `sudo pacman -S yazi` and
  `sudo pacman -Rns dolphin` (cascades baloo/baloo-widgets/kio-extras — all
  dependency-installed, nothing else needs them), then orphan sweep
  `pacman -Qdtq`. Remaining Qt6 apps (hyprpolkitagent, btrfs-assistant, CachyOS
  tools) stay on the gtk3 platform theme, unthemed-tolerable; `qt6ct` (0.7 MiB,
  zero deps) is the escape hatch if that ever bothers. uwsm detour
  (same day, reverted): `~/.config/uwsm/env` turned out to be dead config — SDDM
  `Session=hyprland` runs CachyOS's `start-hyprland` binary, uwsm never runs, the
  file was never sourced (its `BROWSER=firefox` + session-wide `TERM` were wrong
  anyway). Deleted; session env now lives in new `config/envs.lua`
  (`QT_QPA_PLATFORM`, `QT_QPA_PLATFORMTHEME=gtk3`,
  `ELECTRON_OZONE_PLATFORM_HINT`) with cursor vars in `looknfeel.lua` — Hyprland
  exports `env =` to the systemd user environment at startup (verified via
  `systemctl --user show-environment`), so hl.env reaches services too; `env` is
  startup-only → relogin, not reload. Noctalia leftovers purged (btop/KDE
  schemes, `~/.config/qt6ct` + `qt5ct`). A template engine
  (wallust — evaluated 2026-07-04, deferred) only earns its place if scheme-switching
  across the hand-ported configs is ever wanted; don't generate what upstream ships.
  Wallpaper ✅ done 2026-07-04: hyprpaper with omarchy's six tokyo-night
  backgrounds vendored in `hypr/.config/hypr/wallpapers/` (~12.7MB),
  `1-sunset-lake.png` as fallback-for-all-monitors default. Gotcha: hyprpaper
  0.8+ dropped the old `preload =`/`wallpaper = mon,path` lines for
  `wallpaper {}` blocks (old syntax parses but sets no target — daemon runs,
  no wallpaper); runtime switch via `hyprctl hyprpaper wallpaper ', <path>'`.
- **login screen**: stay on SDDM (decided 2026-07-04 — no official hyprwm DM exists,
  wiki has no DM recommendation, SDDM is the CachyOS convention and actively
  maintained; greeter can run on Wayland via `DisplayServer=wayland`). Theme decided
  2026-07-04: **sddm-astronaut-theme** (Keyitdev, actively maintained; installed
  2026-07-04 from AUR) using a **premade variant** (decided 2026-07-04 — no custom
  tokyonight.conf; pick from the ten shipped `Themes/*.conf` when implementing) —
  chosen over the ready-made but archived siddrs/tokyo-night-sddm. Variant picked
  2026-07-04: **pixel_sakura** (animated; `pixel_sakura_static` is the fallback),
  previewed via a user-owned theme copy + `sddm-greeter-qt6 --test-mode`. Both
  root-owned steps (variant `ConfigFile=` edit + `/etc/sddm.conf.d/10-theme.conf`
  drop-in) are documented in hypr/README.md "Manual system steps", incl. the
  caveat that theme package updates reset the variant. Remaining: user runs the
  two sudo commands, then verify the greeter after logout.
- **hypridle idle chain** ✅ done 2026-07-04: `hypridle.conf` in the hypr
  package (10min lock → 11min kbd-backlight off → 12min dpms off), wiki-pattern
  general block (`lock_cmd = pidof hyprlock || hyprlock`, `before_sleep_cmd =
  loginctl lock-session` — fixes suspend-resumes-unlocked via sleep inhibition,
  `after_sleep_cmd` dpms enable), autostarted from `config/autostart.lua`,
  README package list updated. Old hypr-work timings kept but its mechanics
  were broken here: `hyprctl dispatch dpms off` is conf syntax and errors on
  the Lua config — listeners use `hl.dsp.dpms({ action = "…" })` (verified
  live). hyprlock itself done 2026-07-04 (SUPER+CTRL+L, `hyprlock.conf` in
  the package).
- **power menu** ✅ done 2026-07-04 on SUPER+Escape via **walker menus**: custom
  elephant menu at `walker/.config/elephant/menus/power.toml` (lock / suspend /
  logout via `hyprshutdown` / reboot / shutdown; menu-level `action = "%VALUE%"`,
  entries run via `sh -c`), opened with `walker -m menus:power`. Window-kill
  (`hyprctl kill`) moved to SUPER+SHIFT+W; SUPER+SHIFT+Escape deliberately unbound
  (decided 2026-07-04) — hyprshutdown (installed 2026-07-04, cachyos repo; graceful
  close-all-apps-then-exit tool) exists only as the menu's logout entry. Gotcha:
  elephant scans the menus dir only at provider setup — restart elephant.service
  after adding menu files.
- **waybar omarchy look** ✅ done 2026-07-04: copied omarchy's bar verbatim-ish
  (basecamp/omarchy `config/waybar/` — height 26, JetBrainsMono Nerd Font 12px,
  flat/borderless, icon-only modules, persistent workspaces 1–5 with 󱓻 active
  dot, tray behind expander arrow), omarchy-only modules dropped (logo, weather,
  updater, voxtype, indicators), our window-title + backlight modules dropped
  (decided 2026-07-04), cpu + bluetooth added. Clicks remapped: network →
  `$TERMINAL nmtui`, cpu → `$TERMINAL btop`, battery → `walker -m menus:power`,
  volume → wpctl mute toggle. Colors hardcoded tokyonight-night bg `#1a1b26` /
  fg_dark `#a9b1d6` (folke ships NO waybar extra — confirmed; omarchy's
  tokyo-night theme feeds waybar these same two values, nothing more). One
  deviation: `battery.critical` = tokyonight red (no notifier daemon here).
  Same day: `config/defaults.lua` now exports TERMINAL/BROWSER via `hl.env()` —
  session-wide app defaults, nothing hardcodes the terminal anymore.
  Same day: `hyprland/language` module added (EN/SE between pulseaudio and cpu,
  click cycles layout) — the compositor side (us,se + `grp:alts_toggle` Alt+Alt
  switch) was already in `config/input.lua`; only the indicator was missing.
- **looknfeel polish** ✅ done 2026-07-04 (`config/looknfeel.lua`, chosen from
  stock-CachyOS vs omarchy side-by-side): solid blue active border `#7aa2f7` /
  inactive fg_gutter `#3b4261`, border_size 2, rounding 0 (rounded corners
  leave wallpaper slivers with gaps_in 0), opaque windows + light blur 2/2 for
  translucent layers, shadow off, animations minimal (global speed 2 on `quick`
  bezier, `workspaces` leaf disabled → workspace + special swap instant).
- window rules (Bitwarden float, YT-Music workspace; terminal scroll_touchpad done).
- **omarchy-style per-window opacity** (revisit, noted 2026-07-04): omarchy makes
  every window translucent via tag-based window rules, not decoration settings —
  all windows tagged `default-opacity` → `opacity 0.97 0.9`, chromium/firefox
  browsers opt out to `1.0 0.97`, media apps (mpv/vlc/OBS/Zoom/YT webapp) pinned
  `1 1` (see `dev:default/hypr/windows.lua` + `apps/browser.lua`). Global blur
  2/2 is already in place here, so porting is just the rule set in
  `config/windowrules.lua` — natural to fold into the window-rules task above.
- webapp-style launchers if missed (simple `$BROWSER --app=URL` bind), waybar polish.

Add each as a small commit when it earns it.

## Phase 5 — multimonitor & clamshell

- External monitor arrangement + workspace pinning for the laptop (and later the
  desktop's 3-monitor layout as a host table entry).
- Clamshell: lid `bindswitch` disables/re-enables eDP-1 with the mode parameterized per
  host; autostart lid-state check (libinput only sends edge events). Requires logind to
  ignore the lid: `/etc/systemd/logind.conf.d/lid.conf` — system-level, manual step,
  document it here when done. The work machine solved eDP-recovery with
  `~/.local/bin/hypr-edp-recover` (exists only on that machine, not in the repo) —
  reimplement simply if the problem actually shows up here.

## Later / cleanup

- Migrate desktop and work hosts onto the package as they move to CachyOS Hyprland
  (this is a full migration off Omarchy — no compatibility layer). Old conf packages
  keep working until then.
- ~~Delete `hypr-laptop` now (stale, superseded)~~ deleted 2026-07-03; delete `hypr-shared`/`hypr-desktop`/
  `hypr-work` as their hosts migrate; then update `CLAUDE.md` and `readme.md`.

---

## Operational notes (laptop, living section)

- **hyprpolkitagent.service ✅ fixed 2026-07-04**: it was `failed
  (start-limit-hit)` — the systemd user manager survives relogins keeping the
  previous session's stale `WAYLAND_DISPLAY`, and autostart raced the async
  `dbus-update-activation-environment` against `systemctl --user start
  hyprpolkitagent`; the agent (plus 5 instant `Restart=on-failure` retries)
  SIGABRTed on the dead socket before the env import landed, and nothing ever
  retried. Fix in `autostart.lua`: env import and service start chained in one
  `sh -c '… && …'`. Verified: manual start with fresh env stays active.
  `elephant.service` is started unchained — it doesn't connect to the
  compositor, so the stale-env race doesn't apply.
- **Stale `HYPRLAND_INSTANCE_SIGNATURE` after relogin**: shells/sessions started
  before a relogin can't reach hyprctl (`Couldn't connect to … .socket.sock`).
  Fix: `export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr/ | head -1)`.
- **Stale binds after git churn**: Hyprland auto-reloads on config change, so a
  checkout/stash that briefly reverts `binds.lua` can leave the *old* bind set
  loaded (seen 2026-07-04: SUPER+Escape dead, SUPER+SHIFT+Escape back). Fix:
  `hyprctl reload`.
- **Walker service is unsupervised**: started fire-and-forget from
  `config/autostart.lua`; the `walker-service.desktop` XDG autostart entry only
  serves the KDE hosts (`xdg-desktop-autostart.target` never activates here). It
  died once (2026-07-04, cause unknown) — walker then still works per-invocation,
  just slower. If it recurs: give it a systemd user unit like elephant's (but see
  the graphical-session.target caveat below).
- **`graphical-session.target` never activates here** (reboot test 2026-07-04):
  without uwsm nothing pulls it in, and it's `RefuseManualStart=yes` — so user
  units `WantedBy=graphical-session.target` (elephant) stay dead at login. Fix:
  explicit `systemctl --user start` from `config/autostart.lua`. Everything else
  in the autostart chain (waybar, mako, hypridle, hyprpaper, hyprpolkitagent,
  walker, wallpaper on both monitors) came up clean on reboot.
- **Stock-config backups**: `~/.config/{hypr,alacritty,kitty}.cachyos-stock`,
  `~/.bashrc.cachyos-stock`, `~/.claude/settings.json.pre-stow`.
- **nvim is cloned, not stowed**: `~/.config/nvim` ← github.com/pontusc/nvim
  (ssh), deliberately outside stow.
- **Omarchy bind extras deliberately declined** (don't re-propose):
  former-workspace toggle, alt-tab window cycle, group extras, move-into-group.
- **Waybar clock shows Swedish day names**: deliberate — system locale is
  `LANG=en_GB` + `LC_TIME=sv_SE` and the clock format's `L` honors LC_TIME.
  Left as-is 2026-07-04; bar-only fix if ever wanted: clock `"locale"` option.

## Reference — where the old stuff lives (look, don't copy)

| What | Where |
|---|---|
| Most current personal prefs (binds, input, clamshell, idle chain) | `hypr-work/` in this repo |
| Desktop hardware config (monitors, NVIDIA envs, game windowrules) | `hypr-desktop/` + `hypr-shared/constraints…` in this repo |
| Shared windowrules (Bitwarden float, YT-Music ws, btop) | `hypr-shared/`, `hypr-desktop/constraints.conf` |
| Stock CachyOS Lua config (working `hl.*` API examples) | `~/.config/hypr.cachyos-stock` after Phase 2, pristine in `/etc/skel/.config/hypr/` |
| `hypr-edp-recover` script | work machine `~/.local/bin/` only |
| Old envs to *not* lift blindly | `QT_QPA_PLATFORM=xcb` (TS3 workaround), desktop `render_unfocused_fps` |

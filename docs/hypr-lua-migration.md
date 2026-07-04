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

- **central theming**: one palette as the single source of truth feeding kitty (Tokyo
  Night today), waybar + hyprlock (ad-hoc dark theme today), mako, walker, starship —
  pick the scheme once, wire every config to it. Wallpaper (hyprpaper) belongs here.
- **login screen**: SDDM is the DM and only stock themes are installed
  (elarun/maldives/maya) — install/configure a theme matching the central theme.
- hypridle idle chain (10min lock → 11min kbd-backlight off → 12min dpms off);
  hyprlock itself done 2026-07-04 (SUPER+CTRL+L, `hyprlock.conf` in the package).
- power menu on SUPER+Escape via walker (shutdown/reboot/logout/lock — walker menus
  provider; move window-kill elsewhere or drop it).
- window rules (Bitwarden float, YT-Music workspace; terminal scroll_touchpad done).
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

## Reference — where the old stuff lives (look, don't copy)

| What | Where |
|---|---|
| Most current personal prefs (binds, input, clamshell, idle chain) | `hypr-work/` in this repo |
| Desktop hardware config (monitors, NVIDIA envs, game windowrules) | `hypr-desktop/` + `hypr-shared/constraints…` in this repo |
| Shared windowrules (Bitwarden float, YT-Music ws, btop) | `hypr-shared/`, `hypr-desktop/constraints.conf` |
| Stock CachyOS Lua config (working `hl.*` API examples) | `~/.config/hypr.cachyos-stock` after Phase 2, pristine in `/etc/skel/.config/hypr/` |
| `hypr-edp-recover` script | work machine `~/.local/bin/` only |
| Old envs to *not* lift blindly | `QT_QPA_PLATFORM=xcb` (TS3 workaround), desktop `render_unfocused_fps` |

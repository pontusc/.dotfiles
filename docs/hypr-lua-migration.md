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
  caveat that theme package updates reset the variant. ✅ deployed and working
  (both root steps verified live 2026-07-04: drop-in sets
  `Current=sddm-astronaut-theme`, `metadata.desktop` → `pixel_sakura.conf`).
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
- **window rules + omarchy per-window opacity** ✅ done 2026-07-04
  (`config/windowrules.lua`): Bitwarden float, YT-Music webapp → ws5 silent +
  opaque, PiP pinned overlay top-right (omarchy verbatim), suppress
  self-maximize, XWayland drag-fix `no_focus`, screen-share "…is sharing…" pill
  → special silent, mpv/vlc opaque. Opacity is omarchy's tag scheme from
  `dev:default/hypr/windows.lua` + `apps/browser.lua`: all windows tagged
  `+default-opacity`, browsers opt out to `1.0 0.97`
  (chromium-based/firefox-based tags), media opt out to `1 1`, then
  `match tag=default-opacity → opacity "0.97 0.9"` applied as the LAST rule —
  rules are order-dependent (last match wins), keep opt-outs above it. Gotcha:
  omarchy's browser regex has `Vivaldi-stable` capitalized but the class here
  is lowercase `vivaldi-stable` — fixed to `[vV]ivaldi-stable` (verified via
  `hyprctl clients` tags). Desktop rules (games/steam/discord workspaces) wait
  for the Phase 3 host tables.
- ~~webapp-style launchers, waybar polish~~ closed 2026-07-04: webapps declined
  (not wanted after all — don't re-propose), waybar judged clean as-is.

Add each as a small commit when it earns it.

## Phase 5 — multimonitor & clamshell

- Monitor arrangement: laptop keeps the anonymous catch-all (auto placement is
  right; decided 2026-07-04). Explicit per-host layouts (desktop's 3 monitors,
  workspace pinning) wait for the Phase 3 host tables.
- Clamshell + lid sleep ✅ done 2026-07-04, all in `config/monitors.lua`
  (including the SUPER+ALT+SHIFT+M mirror-to-external toggle — bind lives
  there, not in binds.lua, because it shares the eDP rule and monitor
  helpers):
  - **Sleep policy = stock logind, zero config.** The old "logind must ignore
    the lid" assumption was WRONG — verified against logind.conf(5): defaults
    are `HandleLidSwitch=suspend` (fires undocked, charger or not — user chose
    Mac semantics) + `HandleLidSwitchDocked=ignore` (docked = >1 display
    connected). Nothing in Hyprland/hypridle holds a lid inhibitor, so suspend
    really fires; hypridle `before_sleep_cmd` locks first.
  - Display side is native Lua, no scripts: `switch:on/off:Lid Switch` binds
    with Lua callbacks (both `{ locked = true }`), `monitor.added` (plug while
    closed → clamshell), `monitor.removed` (last external gone → eDP-1 back
    instantly), `hyprland.start` lid check (edge events only). Lid state read
    via `io.open("/proc/acpi/button/lid/LID/state")` — config Lua is
    unsandboxed (verified in 0.55.4 source: `luaL_openlibs`, only
    `debug.set/gethook` stripped).
  - **Load-bearing guard**: never disable eDP-1 unless an enabled external
    exists — 0.55.4 predates the zero-monitor FALLBACK output (PR #14547,
    file 404s at the v0.55.4 tag), so zero monitors is still a crash path.
    Re-check when Hyprland is upgraded past 0.55.x; the guard stays correct
    either way. The work machine's `hypr-edp-recover` stays unported —
    the `monitor.removed` restore covers that failure mode.
  - Verified live on 0.55.4 before writing (via `hyprctl eval`):
    disable→re-enable eDP-1 works (PR #14447 is in); `hl.get_monitors()`
    lists only enabled monitors and is already updated inside
    `monitor.removed` (guards race-free); `monitor.removed` fires ~3× per
    unplug (handlers idempotent); mirror clears only with explicit
    `mirror = "none"` (omitting the key does NOT clear it); multiple `hl.on`
    handlers per event coexist (autostart.lua's `hyprland.start` unaffected);
    when a mirror's source monitor is removed the compositor un-mirrors and
    keeps the panel enabled by itself; a monitor that is MIRRORING leaves
    `hl.get_monitors()` entirely (externals() == 0 during mirror — handlers
    account for it). `hyprctl keyword monitor "…"` is a silent no-op under
    Lua config — `hyprctl eval 'hl.monitor({...})'` is the runtime mechanism.
  - Mirror direction reworked 2026-07-05 after live testing: the EXTERNAL
    mirrors the panel, not the other way round. First cut (panel mirrors
    external) pulled eDP-1 out of the layout and the user-facing screen lost
    waybar + wallpaper mid-mirror — known open upstream bugs when outputs
    leave the layout (Alexays/Waybar #4759, hyprwm/hyprpaper #54). With the
    panel as layout monitor its bar/wallpaper stay put and the clone carries
    their image.
  - Workspace→monitor pinning declared 2026-07-05: ws 1-2 → eDP-1 (1
    default), ws 3-4 → HDMI-A-1 (3 default), rest unmanaged; external name
    hardcoded until Phase 3 host tables (desktop layout comes then too).
    `hl.workspace_rule` verified in 0.55.4 source; upstream is known-flaky
    about snapping bound workspaces back on reconnect (#9580, #5464) — if it
    shows, add a `moveworkspacetomonitor` fallback.
  - Mirror toggle physically verified working 2026-07-05 (post direction
    flip). Bind descriptions now mandatory on every `hl.bind` incl. switch
    binds — convention recorded in `hypr/CLAUDE.md`.
  - Physical tests still pending (need hands on the lid): close lid w/ HDMI →
    clamshell; open → panel back; close lid w/o external → suspend+lock;
    unplug HDMI while closed → panel back on (and note whether logind then
    suspends — Mac would; decide if we add that, e.g. `systemctl suspend` in
    the `monitor.removed` handler); SUPER+ALT+SHIFT+M mirror toggle both ways
    (visually confirm waybar/wallpaper survive, incl. after exit); workspace
    1-4 placement after replugging HDMI (upstream flakiness above); boot
    docked with lid closed → panel off.

## Phase 3 — structure the Lua for hosts

**NEXT** (decided 2026-07-05): Phase 5 implementation is done (only physical
lid tests + reboot-for-locale remain as loose ends above); this refactor is
the next work item.

Moved to the end 2026-07-04 (do after Phase 5; "Phase 3" name kept so existing
cross-references like "Phase 3 host tables" stay valid). Refactor, no behavior
change:

- `config/host.lua`: detect host from `/etc/hostname` (`laptop` today; confirm desktop/
  work names). Expose `host.name` and `host.is(...)`.
- Host-varying config becomes Lua tables keyed by hostname (monitors, per-host
  windowrules, envs like the desktop's NVIDIA block) — data branches, not file copies.
- Keep modules small; a host earns its own file only when its block gets big.

## Later / cleanup

- **Proper session initialization (revisit — current autostart is a band-aid)**:
  the `dbus-update ; reset-failed ; restart` chain in `autostart.lua` papers over
  a structural problem — nothing manages session lifecycle, so the user manager
  keeps stale env across relogins, units dbus-activate before the compositor is
  up, and `graphical-session.target` never activates. Research the official way
  (uwsm, or Hyprland's own systemd integration / `hyprland-session.target` if it
  exists by then, official Hyprland + systemd docs) and adopt it; the chain and
  its ops-note bullets below then collapse into it.
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
  `elephant.service` was assumed safe unchained — **wrong, see next bullet**.
- **walker Logout broken — stale env in elephant.service ✅ fixed 2026-07-04**:
  power-menu entries are executed *by elephant*, a systemd user service that
  survives relogin, so it spawned `hyprshutdown` (CachyOS ELF binary; resolves
  the compositor socket from `HYPRLAND_INSTANCE_SIGNATURE`) with the previous
  session's signature → dead instance → silent no-op. Proven live: elephant
  (started 19:01) held the pre-relogin signature while Hyprland (19:59) had a
  new one. Fix in `autostart.lua`: elephant folded into the chained env-import
  command as `restart` (not `start`) — every login force-respawns it with
  fresh env. Verified: signatures match after restart. (Lock/Suspend/Reboot
  never needed the signature; a mid-rebase config checkout separately caused a
  one-off broken state that a manual `hyprctl reload` cleared.)
- **walker Logout broke AGAIN (2026-07-04, next relogin) — `&&` chain was
  fragile ✅ fixed**: something dbus-activated hyprpolkitagent at 20:50:41,
  *before* Hyprland was up (20:50:46) → ABRT crash-loop ×6 → start-limit-hit.
  When the autostart chain ran at 20:50:47 its `systemctl start hyprpolkitagent`
  failed on the start limit, and the `&&` short-circuited the elephant restart —
  elephant (respawned during logout with the dying session's env) kept the stale
  signature. Polkit prompts were dead too. Lesson: units can be in
  `start-limit-hit` before autostart runs, so the chain must not use `&&`.
  Fix in `autostart.lua`: `dbus-update … ; reset-failed both ; restart both`
  (`;` so no step vetoes the rest; reset-failed clears prior crash-loops;
  restart is idempotent and force-respawns stale survivors). End-to-end proof
  pending next relogin.
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
- **Locale**: ✅ fixed 2026-07-04 — was installer default `LANG=en_GB` + all
  `LC_*=sv_SE` (Swedish day names in waybar/journal, decimal comma from
  LC_NUMERIC). Now `/etc/locale.conf` = `LANG=en_GB.UTF-8` with sv_SE kept only
  for MONETARY/PAPER/ADDRESS/TELEPHONE/MEASUREMENT. System file, not stowed —
  reapply on a new host with:
  `sudo localectl set-locale LANG=en_GB.UTF-8 LC_TIME=en_GB.UTF-8 LC_NUMERIC=en_GB.UTF-8 LC_NAME=en_GB.UTF-8 LC_IDENTIFICATION=en_GB.UTF-8 LC_MONETARY=sv_SE.UTF-8 LC_PAPER=sv_SE.UTF-8 LC_MEASUREMENT=sv_SE.UTF-8 LC_ADDRESS=sv_SE.UTF-8 LC_TELEPHONE=sv_SE.UTF-8`
  (set-locale *merges* — it can't unset, so unwanted vars are set equal to LANG,
  which systemd then strips from the file). ~~Effective at next login~~ — WRONG,
  verified 2026-07-04 post-relogin: the old `LC_*` set was still live in the
  user manager AND the whole session (`date +%A` → lördag). PID1 and SDDM read
  locale.conf at *boot* and the session inherits SDDM's env at login, so a
  relogin re-inherits the stale values. **Effective at next reboot** (same
  stale-env-survivor family as the autostart band-aid — another datapoint for
  the session-init revisit).

## Reference — where the old stuff lives (look, don't copy)

| What | Where |
|---|---|
| Most current personal prefs (binds, input, clamshell, idle chain) | `hypr-work/` in this repo |
| Desktop hardware config (monitors, NVIDIA envs, game windowrules) | `hypr-desktop/` + `hypr-shared/constraints…` in this repo |
| Shared windowrules (Bitwarden float, YT-Music ws, btop) | `hypr-shared/`, `hypr-desktop/constraints.conf` |
| Stock CachyOS Lua config (working `hl.*` API examples) | `~/.config/hypr.cachyos-stock` after Phase 2, pristine in `/etc/skel/.config/hypr/` |
| `hypr-edp-recover` script | work machine `~/.local/bin/` only |
| Old envs to *not* lift blindly | `QT_QPA_PLATFORM=xcb` (TS3 workaround), desktop `render_unfocused_fps` |

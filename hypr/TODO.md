# hypr Lua migration plan

## Phases

1. **This package.** `hypr/` reaches 1:1 parity with the `hypr-work` conf overlay on the
   quattro Lua contract. Undeployed until Omarchy 4 ships.
2. **Desktop/laptop host ports.** Port `hypr-desktop` (triple monitor, gaming rules) into
   `hosts/desktop.lua` and `hypr-laptop` into `hosts/laptop.lua`, replacing the stub headers.
3. **Daemon confs + retirement.** Absorb `hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf`,
   and `xdph.conf` (currently left as `.conf` in `hypr-work`) into this package, move
   `omarchy-reminder-at` from `hypr-work/.local/bin` into `hypr/.local/bin` and restow, then
   retire `hypr-work`, `hypr-desktop`, `hypr-laptop`, and `hypr-shared`.

## Cutover checklist

- [ ] Omarchy 4 (quattro) released
- [ ] `omarchy update`
- [ ] Diff `reference/quattro/` against the installed templates for contract drift
- [ ] Re-verify every `hl.unbind` target in `bindings.lua` and `hosts/pc-framework.lua`
      against the installed quattro defaults (defaults have already moved once between
      omarchy 3.8.4 and this pinned quattro snapshot — see known risks)
- [ ] If `~/.local/state/omarchy/preinstalls-removed` exists, re-verify the five `hl.unbind`
      targets in `bindings.lua` that are only bound upstream when preinstalled bindings are
      enabled (`o.preinstalled_bindings_enabled()`, `default/hypr/bindings/applications.lua`)
- [ ] Verify `hl.dsp.pass`'s argument shape for the Youtube Music media-key binds — it fails
      at keypress-time, not load-time, so a bad shape won't surface until then
- [ ] Re-check whether Hyprland 0.56 ships a crash-safe fallback output (see
      `hosts/pc-framework.lua`'s header)
- [ ] Verify the mirror-guard assumptions in `hosts/pc-framework.lua` against the installed
      quattro mirror toggle: that its state file is
      `~/.local/state/omarchy/toggles/hypr/internal-monitor-mirror.conf` and that a mirrored
      external really disappears from `hl.get_monitors()`
- [ ] Kill the legacy `hypr-edp-recover` daemon (untracked at `~/.local/bin/hypr-edp-recover`,
      exec-once'd by the live `autostart.conf`) — it would fight `hosts/pc-framework.lua`'s
      `hl.on` monitor handlers if left running
- [ ] Remove the `^/\.config(/|$)` guard from `.stow-local-ignore`
- [ ] `stow hypr`
- [ ] `Hyprland --verify-config`
- [ ] `hyprctl reload`
- [ ] Verify binds, monitors, and theme
- [ ] Retire `hypr-work` (and `hypr-desktop`/`hypr-laptop`/`hypr-shared` once phases 2-3 land)

## Known risks

- quattro is pre-release and actively churning. `reference/quattro/COMMIT` pins the exact
  commit this package was ported against; anything ported here can drift before Omarchy 4
  ships.
- `default/hypr/bindings/tiling-v2.lua` does not exist at the pinned commit — it's been
  renamed/split into `tiling.lua` plus separate `applications.lua`, `clipboard.lua`,
  `media.lua`, and `voxtype.lua` modules. `bindings.lua` was ported against that split;
  re-diff at cutover in case the module layout changes again.
- `hl.dsp.pass`'s argument shape isn't documented in `/usr/share/hypr/stubs/hl.meta.lua`
  (`fun(...): HL.Dispatcher`). The Youtube Music media-key pass-through binds in
  `bindings.lua` use a best-guess `{ class = ... }` table and need live verification.
- `SUPER + L` ("Toggle workspace layout") and `SUPER + ALT + <arrow>` ("Move window into
  group in this direction") already existed in omarchy 3.8.4's `tiling-v2.conf` — they are
  not new to quattro. `bindings.lua` unbinds both to free the keys for the vim-style
  rebinds, with no replacement wired for either — decide at cutover whether either needs a
  new home.
- Quattro's genuine new collisions are `SUPER + ALT + K` ("Tmux keybindings") and
  `SUPER + CTRL + K` ("Herdr keybindings"), introduced after 3.8.4. `bindings.lua` unbinds
  both before reusing the keys for the vim-style resize bind and the displaced
  keybindings-menu bind — handled.
- `hosts/pc-framework.lua`'s clamshell state machine is adapted from
  `dotfiles.worktrees/lua/hypr/.config/hypr/config/monitors.lua`, verified live there only on
  Hyprland 0.55.4. Re-verify monitor-event ordering and `hl.unbind`-then-`hl.bind` semantics
  for the lid switch on 0.56 before relying on it.

## Parity table

Source (`hypr-work/.config/hypr/...`) → destination in this package. Entries marked `—` are
intentionally not ported, with the reason given.

| Source | Destination | Note |
|---|---|---|
| `hyprland.conf:1-26` | `hyprland.lua` (quattro template, unmodified) | Structural sourcing (defaults + 5 overrides + toggles) already covered by quattro's require chain; no unique overrides to port |
| `bindings.conf:1` (`$browser`) | — | Unused/dead variable in `hypr-work`, never referenced |
| `bindings.conf:3-4` (Lock comment + unbind) | `bindings.lua` (folded into the `SUPER + L` unbind) | Quattro already binds Lock to `SUPER + CTRL + L` by default (`utilities.lua:126`) — no separate action needed for Lock itself |
| `bindings.conf:7` | `bindings.lua` | Terminal opens in cwd (unbind default, `o.launch` port) |
| `bindings.conf:8` | `bindings.lua` | Tmux opens in cwd (unbind default, `o.launch` port) |
| `bindings.conf:9` | `bindings.lua` | New `SUPER + B` Browser bind (no default collision) |
| `bindings.conf:10` | `bindings.lua` | `SUPER + SHIFT + B` → Browser (private) (unbind default Browser bind) |
| `bindings.conf:11` | — | `SUPER + SHIFT + F` File manager already matches the default (`applications.lua:4`) |
| `bindings.conf:12` | — | `SUPER + ALT + SHIFT + F` File manager (cwd) already matches the default (`applications.lua:5`) |
| `bindings.conf:13` | — | `SUPER + SHIFT + N` Editor already matches the default (`applications.lua:8`) |
| `bindings.conf:14` | `bindings.lua` | `SUPER + SHIFT + SLASH` → Bitwarden (unbind default 1Password bind) |
| `bindings.conf:15` | `bindings.lua` | `SUPER + SHIFT + A` → Claude (unbind default ChatGPT bind) |
| `bindings.conf:16` | `bindings.lua` | `SUPER + SHIFT + C` → Google Calendar (unbind default hey.com bind) |
| `bindings.conf:17` | `bindings.lua` | `SUPER + SHIFT + E` → Gmail (unbind default hey.com bind) |
| `bindings.conf:19` | `bindings.lua` | New `SUPER + M` Youtube Music bind (no default collision) |
| `bindings.conf:20-27` | `hosts/pc-framework.lua` | Lid switch unbind/rebind relocated (monitor state, not a keybinding choice); rewritten as a docked-aware clamshell state machine |
| `bindings.conf:29-30` | — | Inactive instructional comment (mirrors quattro's own template) |
| `bindings.conf:34-44` | `bindings.lua` | Vim-style focus nav (H/J/K/L), replacing `SUPER + Arrow` |
| `bindings.conf:46-54` | `bindings.lua` | Vim-style window swap (H/J/K/L), replacing `SUPER + SHIFT + Arrow` |
| `bindings.conf:56-64` | `bindings.lua` | Vim-style window resize (H/J/K/L), replacing `SUPER + ALT + Arrow` |
| `bindings.conf:66-68` | `bindings.lua` | Displaced defaults → `SUPER + CTRL + J/K` |
| `bindings.conf:71-73` | `bindings.lua` | Youtube Music media-key pass-through (unverified `hl.dsp.pass` shape, see known risks) |
| `bindings.conf:76-78` | — | Already commented out in the source |
| `bindings.conf:80` | `bindings.lua` | `SUPER + SLASH` disabled, no replacement |
| `bindings.conf:83-86` | — | Duplicate of the `bindings.conf:57-60` unbind; redundant in the source, not duplicated here |
| `bindings.conf:89-92` | `bindings.lua` | `SUPER + TAB` repurposed to cycle group windows |
| `bindings.conf:94-96` | — | Commented out in the source |
| `bindings.conf:98-100` | `bindings.lua` | Reminder bind carryover (required) |
| `input.conf:4-44` (active settings) | `input.lua` | `hl.config({ input = ... })` port |
| `input.conf:48-49` | `input.lua` | `o.window` scroll_touchpad rules |
| `input.conf:51-57` | — | Commented-out gesture examples, not active |
| `looknfeel.conf:4-12` | `looknfeel.lua` | `general.gaps_in` / `gaps_out` |
| `looknfeel.conf:37-39` | `looknfeel.lua` | `misc.middle_click_paste` |
| `looknfeel.conf` (remaining) | — | Commented out, not active |
| `autostart.conf:4-7` | `hosts/pc-framework.lua` | Startup lid-state check → `hl.on("hyprland.start", ...)` |
| `autostart.conf:9-12` | `hosts/pc-framework.lua` | `hypr-edp-recover` daemon → `hl.on("monitor.added"/"monitor.removed", ...)` |
| `monitors.conf:5` | `hosts/pc-framework.lua` | `GDK_SCALE` env |
| `monitors.conf:8` | `hosts/pc-framework.lua` | Ultrawide monitor rule |
| `monitors.conf:11` | `hosts/pc-framework.lua` | eDP-1 monitor rule (folded into `edp_rule`) |
| `monitors.conf:14` | `hosts/pc-framework.lua` | Fallback monitor rule |
| `hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf`, `xdph.conf` | — | Phase 3 (absorb daemon confs); untouched for now |
| `.local/bin/omarchy-reminder-at` | — | Script unchanged, stays in `hypr-work/.local/bin`; referenced by path from `bindings.lua`'s reminder bind |

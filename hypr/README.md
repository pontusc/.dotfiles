# hypr

Lua Hyprland config for Omarchy's unreleased **quattro** branch (Omarchy 4), targeting
Hyprland's native Lua config (`hl.*`/`o.*` API). It ports `hypr-work`'s conf overlay
1:1 onto the quattro contract; see `TODO.md` for the phase plan and the full parity
table, and `reference/quattro/` for the pinned upstream templates this package layers on.

**Do not `stow` this package yet.** quattro is pre-release: `require("default.hypr.omarchy")`
and the `hl.*` Lua API it depends on don't exist on the omarchy 3.8.4 / conf-based install
this machine currently runs. Stowing would coexist conflict-free with the live
`~/.config/hypr` (per-entry symlinks land beside the existing `.conf` files) — the real
hazard is that Hyprland 0.56 prefers `hyprland.lua` over `hyprland.conf` with no fallback on
Lua error, so this package's contract-mismatched Lua would take priority and drop Hyprland
into emergency mode on reload. `.stow-local-ignore` blocks the package's `.config` tree for
this reason; the guard must be removed at cutover (see `TODO.md`).

## Deploy (once Omarchy 4 / quattro ships)

1. Diff `reference/quattro/` against the installed templates for contract drift (quattro is
   still churning — see `TODO.md`'s known risks).
2. Remove the `^/\.config(/|$)` guard from `.stow-local-ignore`.
3. `stow hypr`
4. `Hyprland --verify-config`
5. `hyprctl reload`
6. Verify binds, monitors, and theme per `TODO.md`'s cutover checklist.

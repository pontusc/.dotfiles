# hypr

Lua Hyprland config for Omarchy 4 (quattro), layered on the `hl.*`/`o.*` defaults.
Deployed with `stow hypr`.

Per-host monitor rules live in `.config/hypr/hosts/<hostname>.lua`, resolved at load by
`monitors.lua` from `/etc/hostname`. A host without a module falls back to the baseline
rule and gets a notification.

Lid/clamshell handling is Omarchy native (`switch:*:Lid Switch` binds plus the
`omarchy-hyprland-monitor-watch` daemon). Host modules must not rebind the lid switch or
duplicate monitor enable/disable logic.

`reference/quattro/` pins the upstream templates the overrides were ported against. Diff it
against `/usr/share/omarchy/default/hypr` and `config/hypr` after an `omarchy update` to
spot contract drift before it bites.

After any config change: `hyprctl reload && hyprctl configerrors`. Quality gate:
`stylua --check .config/hypr/`.

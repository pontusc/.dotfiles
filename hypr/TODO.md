# hypr Lua migration

Cutover to Omarchy 4 completed 2026-08-20 on pc-framework. Phase 1 (parity port of the
hypr-work conf overlay) and phase 3 (daemon confs absorbed, `omarchy-reminder-at` moved,
`hypr-work` retired) are done. The old confs and the line-by-line parity table live in git
history before this commit.

## Remaining

- [ ] Phase 2: port the retired `hypr-desktop` (triple monitor, gaming rules) into
      `hosts/desktop.lua` and `hypr-laptop` into `hosts/laptop.lua`. Both packages are
      deleted from the tree, recover their confs from git history.
- [ ] Consider replacing `~/.local/bin/omarchy-reminder-at` with Omarchy 4's native
      `omarchy reminder` if the day/time scheduling it adds is no longer worth the custom
      script.

## Cutover notes that outlive the migration

- `omarchy-hyprland-monitor-clamshell` resolves the internal panel's scale from
  `~/.config/hypr/monitors.lua` only. Host modules are invisible to it, so it falls back
  to `~/.local/state/omarchy/toggles/hypr/internal-monitor-scale`. That file is
  re-captured from the live monitor on every clamshell disable and must agree with the
  host module's eDP scale. See `hosts/pc-framework.lua`.
- The quattro mirror toggle assumed in the original plan does not exist. Omarchy 4 ships
  `internal-monitor-mirror` and `internal-monitor-disable` toggle files managed by
  `omarchy-hyprland-monitor-internal`, and the clamshell flag at
  `~/.local/state/omarchy/toggles/hypr/internal-monitor-clamshell.lua`.

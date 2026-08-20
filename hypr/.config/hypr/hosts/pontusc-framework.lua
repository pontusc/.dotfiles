-- pontusc-framework: Samsung Odyssey G95C ultrawide as the primary external.
--
-- Lid/clamshell handling is Omarchy 4 native and must not be duplicated here:
-- the default switch:*:Lid Switch binds drive omarchy-hyprland-monitor-clamshell,
-- and the omarchy-hyprland-monitor-watch daemon re-syncs it on monitor hotplug,
-- at startup, and via a reconciliation poll while docked — so this file carries
-- monitor rules and env only.
--
-- Caveat: omarchy-hyprland-monitor-clamshell resolves the internal panel's
-- scale from ~/.config/hypr/monitors.lua only (host modules are invisible to
-- it), falling back to ~/.local/state/omarchy/toggles/hypr/internal-monitor-scale.
-- That state file is re-captured from the live monitor on every clamshell
-- disable, so it stays correct as long as it agrees with eDP's rule below (1).

hl.env("GDK_SCALE", "1")

-- Ultrawide first, pinned at 0x0 (never auto): eDP's position is "auto-left",
-- computed relative to whatever monitors are already placed, so the
-- ultrawide's absolute rule must land before eDP's relative one.
hl.monitor({ output = "desc:Samsung Electric Company Odyssey G95C", mode = "5120x1440@60", position = "0x0", scale = 1 })
hl.monitor({ output = "eDP-1", mode = "2256x1504@60", position = "auto-left", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

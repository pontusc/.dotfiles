-- General window rules for all hosts, then the per-host dispatch (silent
-- when the host has no module — unlike monitors, no windowrules module is
-- the normal case).
--
-- Hyprland evaluates window rules in definition order, and this file loads
-- after Omarchy's defaults. That is what lets these rules win, but it also
-- means Omarchy's { tag = "floating-window" } -> float/center/size rules have
-- already been evaluated by the time this file runs: setting that tag here is a
-- silent no-op. Set float/center/size directly instead.

-- Bitwarden extension popout. Matched on initial_title because title tracks the
-- focused tab: a title match would also float a normal browser window whenever
-- a Bitwarden tab is in front. Only the popout is born with this title.
o.window({ initial_title = "^Bitwarden( .*)?$" }, { float = true, size = { 500, 706 } })

require("hypr.host").load("windowrules", false)

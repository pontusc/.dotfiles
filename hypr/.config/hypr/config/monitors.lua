-- Monitors. Laptop-only for now; per-host tables come with the host.lua
-- refactor (Phase 3), external monitors + clamshell in Phase 5.

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1200@60",
    position = "auto",
    scale    = 1,
})

-- Anything unnamed: just light it up until Phase 5 arranges it properly
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

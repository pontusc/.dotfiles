-- Layout and look — tokyonight-night (folke canonical values), decided 2026-07-04:
-- solid blue borders, square corners, opaque windows (blur only serves
-- translucent layers: walker, mako), near-instant animations.

hl.config({
    general = {
        layout           = "dwindle",
        gaps_in          = 0,
        gaps_out         = 1,
        border_size      = 2,
        resize_on_border = true,
        col = {
            active_border   = "rgba(7aa2f7ff)",   -- blue #7aa2f7
            inactive_border = "rgba(3b4261ff)",   -- fg_gutter #3b4261
        },
    },
    dwindle = {
        preserve_split = true,
    },
    decoration = {
        rounding = 0,
        blur = {
            enabled = true,
            size    = 2,
            passes  = 2,
            special = true,
        },
        shadow = {
            enabled = false,    -- invisible anyway with 0 gaps and square tiles
        },
    },
    animations = {
        enabled = true,
    },
    misc = {
        middle_click_paste = false,
    },
    ecosystem = {
        no_update_news   = true,
        no_donation_nag  = true,
    },
})

-- Minimal: one quick curve, ~200ms everything, workspace switch instant
-- (specialWorkspace inherits the disabled workspaces leaf).
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "workspaces", enabled = false })

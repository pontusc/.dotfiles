-- Keyboard, mouse, touchpad

hl.config({
    input = {
        kb_layout  = "us,se",
        kb_variant = "altgr-intl",
        kb_options = "compose:caps,grp:alts_toggle",

        repeat_rate  = 40,
        repeat_delay = 600,

        numlock_by_default = true,

        accel_profile  = "flat",
        force_no_accel = true,
        sensitivity    = 0.0,

        touchpad = {
            natural_scroll = true,
            scroll_factor  = 0.4,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

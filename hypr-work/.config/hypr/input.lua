-- Control your input devices.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
  input = {
    -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
    kb_layout = "us,se",
    kb_variant = "altgr-intl",
    kb_options = "compose:caps,grp:alts_toggle",

    -- Change speed of keyboard repeat.
    repeat_rate = 40,
    repeat_delay = 600,

    -- Start with numlock on by default.
    numlock_by_default = true,

    -- Turn off mouse acceleration (default: adaptive).
    force_no_accel = true,
    accel_profile = "flat",
    sensitivity = 0.0,

    touchpad = {
      -- Use natural (inverse) scrolling.
      natural_scroll = true,

      -- Control the speed of your scrolling.
      scroll_factor = 0.4,
    },
  },
})

-- Scroll nicely in the terminal.
o.window("(Alacritty|kitty)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Personal input overrides, layered on Omarchy's defaults.

hl.config({
  input = {
    kb_layout = "us,se",
    kb_variant = "altgr-intl",
    kb_options = "compose:caps ,grp:alts_toggle",

    repeat_rate = 40,
    repeat_delay = 600,

    numlock_by_default = true,

    force_no_accel = true,
    accel_profile = "flat",
    sensitivity = 0.0,

    touchpad = {
      natural_scroll = true,
      scroll_factor = 0.4,
    },
  },
})

-- Scroll nicely in the terminal.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and resolutions possible: hyprctl monitors all
-- Format: hl.monitor({ output, mode, position, scale })

hl.env("GDK_SCALE", "1")

-- External ultrawide (Samsung Odyssey G95C) — at origin so lid close doesn't reorient.
hl.monitor({ output = "desc:Samsung Electric Company Odyssey G95C", mode = "5120x1440@60", position = "0x0", scale = 1 })

-- Laptop display to the left of external (adjust scale to preference: 1, 1.5, or 2).
hl.monitor({ output = "eDP-1", mode = "2256x1504@60", position = "auto-left", scale = 1 })

-- Fallback for any other external monitor.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

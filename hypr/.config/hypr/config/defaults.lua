-- Default applications: globals for the other modules, and exported into the
-- session environment so everything Hyprland spawns (waybar on-click,
-- scripts) resolves the same defaults instead of hardcoding them.

TERMINAL     = "kitty"
BROWSER      = "vivaldi"
FILE_MANAGER = TERMINAL .. " -e yazi"

hl.env("TERMINAL", TERMINAL)
hl.env("BROWSER", BROWSER)

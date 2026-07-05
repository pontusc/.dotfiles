-- Session-wide defaults: globals for the other modules. The application
-- defaults are also exported into the session environment so everything
-- Hyprland spawns (waybar on-click, scripts) resolves the same defaults
-- instead of hardcoding them.

TERMINAL = "kitty"
BROWSER = "vivaldi"
FILE_MANAGER = TERMINAL .. " -e yazi"

hl.env("TERMINAL", TERMINAL)
hl.env("BROWSER", BROWSER)

-- Bind modifier for the config/binds/* modules (not exported: nothing
-- outside the compositor needs it).
MOD = "SUPER"

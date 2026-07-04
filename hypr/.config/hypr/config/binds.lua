local mod = "SUPER"

------------------
---- Apps --------
------------------

hl.bind(mod .. " + Return",       hl.dsp.exec_cmd(TERMINAL))
hl.bind(mod .. " + ALT + Return", hl.dsp.exec_cmd(TERMINAL .. " -e sh -c 'tmux attach || tmux new -s Work'"))
hl.bind(mod .. " + B",            hl.dsp.exec_cmd(BROWSER))
hl.bind(mod .. " + SHIFT + B",    hl.dsp.exec_cmd(BROWSER .. " --incognito"))
hl.bind(mod .. " + E",            hl.dsp.exec_cmd(FILE_MANAGER))
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(TERMINAL .. " -e btop"))

------------------
---- Launcher ----
------------------

hl.bind(mod .. " + Space",          hl.dsp.exec_cmd("walker"))
hl.bind(mod .. " + CONTROL + V",    hl.dsp.exec_cmd("walker -m clipboard"))

-- Universal copy/paste (omarchy-style): sends CTRL+Insert / SHIFT+Insert to
-- the focused window so copy/paste behave the same in terminals.
-- send_key_state + timer instead of send_shortcut to avoid stuck synthetic
-- keys (hyprwm/Hyprland#14099).
local function send_shortcut_once(mods, key)
    return function()
        hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down", window = "activewindow" }))
        hl.timer(function()
            hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up", window = "activewindow" }))
        end, { timeout = 50, type = "oneshot" })
    end
end

hl.bind(mod .. " + C", send_shortcut_once("CTRL", "Insert"))
hl.bind(mod .. " + V", send_shortcut_once("SHIFT", "Insert"))

---------------------------
---- Window management ----
---------------------------

hl.bind(mod .. " + W",           hl.dsp.window.close())
hl.bind(mod .. " + F",           hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))

-- Pop window out (omarchy-style): float + center + pin so it stays on top
-- across workspaces; press again to re-tile. Shelled out via hyprctl because
-- querying window state from inside a bind function would block Hyprland's
-- own event loop.
local popOut  = [[hyprctl dispatch "hl.dsp.window.float({ action = \"toggle\" })" && hyprctl dispatch "hl.dsp.window.resize({ x = 1300, y = 900 })" && hyprctl dispatch "hl.dsp.window.center({})" && hyprctl dispatch "hl.dsp.window.pin({})"]]
local popBack = [[hyprctl dispatch "hl.dsp.window.pin({})" && hyprctl dispatch "hl.dsp.window.float({ action = \"toggle\" })"]]
hl.bind(mod .. " + O", hl.dsp.exec_cmd("sh -c 'if hyprctl activewindow | grep -q \"pinned: 1\"; then " .. popBack .. "; else " .. popOut .. "; fi'"))
hl.bind(mod .. " + CONTROL + J", hl.dsp.layout("togglesplit"))
-- TODO: SUPER+Escape should become a walker power menu (walker -m menus +
-- custom elephant menu: shutdown/reboot/logout/lock/suspend) instead of
-- window kill. SUPER+SHIFT+Escape should become `hyprshutdown` (graceful
-- close-all-apps + exit) once installed — cachyos repo.
hl.bind(mod .. " + Escape",         hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exit())

-- Vim-style focus / swap / resize
local vim = {
    H = { dir = "left",  d = "l", resize = { x = -30, y = 0 } },
    J = { dir = "down",  d = "d", resize = { x = 0, y = 30 } },
    K = { dir = "up",    d = "u", resize = { x = 0, y = -30 } },
    L = { dir = "right", d = "r", resize = { x = 30, y = 0 } },
}
for key, v in pairs(vim) do
    hl.bind(mod .. " + " .. key,            hl.dsp.focus({ direction = v.dir }))
    hl.bind(mod .. " + SHIFT + " .. key,    hl.dsp.window.swap({ direction = v.d }))
    hl.bind(mod .. " + ALT + " .. key,      hl.dsp.window.resize({ x = v.resize.x, y = v.resize.y, relative = true }), { repeating = true })
end

-- Groups
hl.bind(mod .. " + G",         hl.dsp.group.toggle())
hl.bind(mod .. " + TAB",       hl.dsp.group.next())
hl.bind(mod .. " + ALT + G",   hl.dsp.window.move({ out_of_group = true }))

-- Move & resize with mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Lock (config: hyprlock.conf in this package)
hl.bind(mod .. " + CONTROL + L", hl.dsp.exec_cmd("hyprlock"))

--------------------
---- Workspaces ----
--------------------

for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
    hl.bind(mod .. " + ALT + " .. key,   hl.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind(mod .. " + CONTROL + Right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mod .. " + CONTROL + Left",  hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mod .. " + mouse_down",      hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",        hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad
hl.bind(mod .. " + S",           hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mod .. " + SHIFT + S",   hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

---------------------------
---- Hardware controls ----
---------------------------

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true })

-- Media
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })

-----------------------
---- Notifications ----
-----------------------

hl.bind(mod .. " + comma",         hl.dsp.exec_cmd("makoctl dismiss"))
hl.bind(mod .. " + SHIFT + comma", hl.dsp.exec_cmd("makoctl dismiss -a"))

---------------------
---- Screenshots ----
---------------------

-- SUPER+P variants because this keyboard has no Print key
local shotRegionToClip = [[sh -c 'grim -g "$(slurp)" - | wl-copy']]
local shotRegionToFile = [[sh -c 'mkdir -p ~/Pictures/screenshots && grim -g "$(slurp)" ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png']]

hl.bind(mod .. " + P",           hl.dsp.exec_cmd(shotRegionToClip))
hl.bind(mod .. " + SHIFT + P",   hl.dsp.exec_cmd(shotRegionToFile))
hl.bind("Print",                 hl.dsp.exec_cmd(shotRegionToClip))
hl.bind(mod .. " + Print",       hl.dsp.exec_cmd(shotRegionToFile))

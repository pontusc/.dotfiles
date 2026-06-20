-- Application bindings.
o.bind("SUPER + RETURN", "Terminal", o.launch([[xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"]]))
o.bind("SUPER + ALT + RETURN", "Tmux", o.launch([[xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" bash -c "tmux attach || tmux new -s Work"]]))
o.bind("SUPER + B", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + B", "Browser (private)", "omarchy-launch-browser --private")
o.bind("SUPER + SHIFT + F", "File manager", o.launch("nautilus --new-window"))
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", o.launch([[nautilus --new-window "$(omarchy-cmd-terminal-cwd)"]]))
o.bind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + SHIFT + SLASH", "Passwords", o.launch("bitwarden"))

-- Web app bindings.
o.bind("SUPER + SHIFT + A", "Claude", { webapp = "https://claude.com" })
o.bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://calendar.google.com/calendar", focus = true })
o.bind("SUPER + SHIFT + E", "Email", o.launch_webapp_sole("Gmail", "https://mail.google.com/mail/"))
o.bind("SUPER + M", "Youtube Music", o.launch_webapp_sole("youtube", "https://music.youtube.com"))

-- Clamshell mode: lid close disables laptop screen, lid open re-enables it.
-- Unbind omarchy defaults (bindings/utilities) so its
-- omarchy-hyprland-monitor-internal helper doesn't also fire and write a
-- wildcard `monitor=,disable` toggle when $INTERNAL resolves empty.
hl.unbind("switch:on:Lid Switch")
hl.unbind("switch:off:Lid Switch")
o.bind("switch:on:Lid Switch", nil, [[hyprctl keyword monitor "eDP-1, disable"]], { locked = true })
o.bind("switch:off:Lid Switch", nil, [[hyprctl keyword monitor "eDP-1, 2256x1504@60, auto-left, 1"]], { locked = true })

-- --- Window management

-- Focus navigation (vim-style, replaces arrows and unbinds default homes).
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
o.bind("SUPER + H", "Move window focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Move window focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Move window focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Move window focus right", hl.dsp.focus({ direction = "r" }))

-- Window swap (vim-style, replaces arrows).
hl.unbind("SUPER + SHIFT + LEFT")
hl.unbind("SUPER + SHIFT + RIGHT")
hl.unbind("SUPER + SHIFT + UP")
hl.unbind("SUPER + SHIFT + DOWN")
o.bind("SUPER + SHIFT + H", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window right", hl.dsp.window.swap({ direction = "r" }))

-- Window resize (vim-style, replaces arrows; default Alt+arrows move into groups).
hl.unbind("SUPER + ALT + LEFT")
hl.unbind("SUPER + ALT + RIGHT")
hl.unbind("SUPER + ALT + UP")
hl.unbind("SUPER + ALT + DOWN")
o.bind("SUPER + ALT + H", "Resize window left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
o.bind("SUPER + ALT + L", "Resize window right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
o.bind("SUPER + ALT + K", "Resize window up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
o.bind("SUPER + ALT + J", "Resize window down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })

-- Displaced omarchy defaults → new homes.
o.bind("SUPER + CTRL + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + CTRL + K", "Show key bindings", "omarchy-menu-keybindings")

-- Single set of grouped windows: cycle with SUPER + TAB.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + ALT + TAB")
hl.unbind("SUPER + ALT + SHIFT + TAB")
o.bind("SUPER + TAB", "Next window in group", hl.dsp.group.next())

-- Media keys: also forward to the YouTube Music web app when it is open.
hl.bind("XF86AudioNext", hl.dsp.pass({ window = "class:^.*-music\\.youtube.*$" }))
hl.bind("XF86AudioPause", hl.dsp.pass({ window = "class:^.*-music\\.youtube.*$" }))
hl.bind("XF86AudioPlay", hl.dsp.pass({ window = "class:^.*-music\\.youtube.*$" }))

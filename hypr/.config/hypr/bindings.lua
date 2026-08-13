-- Personal keybinding overrides layered on Omarchy's quattro defaults.

-- Terminal / tmux open in the focused window's cwd instead of $HOME.
hl.unbind("SUPER + RETURN")
o.bind("SUPER + RETURN", "Terminal", o.launch('xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"'))

hl.unbind("SUPER + ALT + RETURN")
o.bind(
  "SUPER + ALT + RETURN",
  "Tmux",
  o.launch('xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" bash -c "tmux attach || tmux new -s Work"')
)

-- Regular browser gets its own key; SUPER+SHIFT+B becomes the private window
-- (quattro's default private-browsing bind stays put at SUPER+SHIFT+ALT+B).
o.bind("SUPER + B", "Browser", { omarchy = "browser" })
hl.unbind("SUPER + SHIFT + B")
o.bind("SUPER + SHIFT + B", "Browser (private)", { omarchy = "browser --private" })

o.bind("SUPER + M", "Youtube", { webapp = "https://music.youtube.com", focus = true })

hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "Claude", { webapp = "https://claude.com" })

hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://calendar.google.com/calendar", focus = true })

hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Gmail", { webapp = "https://mail.google.com/mail/", focus = true })

hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "bitwarden" })

-- Pass Youtube Music's media keys straight to its window. Quattro's global
-- media-key handlers stay bound too — both fire.
local youtube_music_class = "^.*-music\\.youtube.*$"
o.bind("XF86AudioNext", "Pass to Youtube Music", hl.dsp.pass({ class = youtube_music_class }))
o.bind("XF86AudioPause", "Pass to Youtube Music", hl.dsp.pass({ class = youtube_music_class }))
o.bind("XF86AudioPlay", "Pass to Youtube Music", hl.dsp.pass({ class = youtube_music_class }))

-- Vim-style window focus/swap/resize, replacing SUPER+Arrow. (Lid switch
-- rebinding lives in hosts/pc-framework.lua — it's monitor state, not a
-- keybinding choice.)
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

hl.unbind("SUPER + SHIFT + LEFT")
hl.unbind("SUPER + SHIFT + RIGHT")
hl.unbind("SUPER + SHIFT + UP")
hl.unbind("SUPER + SHIFT + DOWN")

o.bind("SUPER + SHIFT + H", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window right", hl.dsp.window.swap({ direction = "r" }))

hl.unbind("SUPER + ALT + LEFT")
hl.unbind("SUPER + ALT + RIGHT")
hl.unbind("SUPER + ALT + UP")
hl.unbind("SUPER + ALT + DOWN")

o.bind(
  "SUPER + ALT + H",
  "Resize window left",
  hl.dsp.window.resize({ x = -30, y = 0, relative = true }),
  { repeating = true }
)
o.bind(
  "SUPER + ALT + L",
  "Resize window right",
  hl.dsp.window.resize({ x = 30, y = 0, relative = true }),
  { repeating = true }
)
hl.unbind("SUPER + ALT + K") -- quattro default: Tmux keybindings menu
o.bind(
  "SUPER + ALT + K",
  "Resize window up",
  hl.dsp.window.resize({ x = 0, y = -30, relative = true }),
  { repeating = true }
)
o.bind(
  "SUPER + ALT + J",
  "Resize window down",
  hl.dsp.window.resize({ x = 0, y = 30, relative = true }),
  { repeating = true }
)

-- Omarchy defaults displaced by the vim-style rebinds above.
o.bind("SUPER + CTRL + J", "Toggle window split", hl.dsp.layout("togglesplit"))
hl.unbind("SUPER + CTRL + K") -- quattro default: Herdr keybindings menu
o.bind("SUPER + CTRL + K", "Keybindings", "omarchy-menu-keybindings")

hl.unbind("SUPER + SLASH") -- default: monitor scaling up; disabled, no replacement

hl.unbind("SUPER + ALT + TAB") -- default: next window in group
hl.unbind("SUPER + ALT + SHIFT + TAB") -- default: previous window in group
hl.unbind("SUPER + TAB") -- default: next workspace
o.bind("SUPER + TAB", "Next window in group", hl.dsp.group.next())

-- Reminder flow uses a custom day/time scheduler instead of Omarchy's
-- minutes-from-now prompt.
hl.unbind("SUPER + CTRL + R")
hl.unbind("SUPER + CTRL + ALT + R")
hl.unbind("SUPER + SHIFT + CTRL + R")
o.bind("SUPER + CTRL + R", "Set reminder", "~/.local/bin/omarchy-reminder-at")
o.bind("SUPER + CTRL + ALT + R", "Show reminders", "~/.local/bin/omarchy-reminder-at show")
o.bind("SUPER + SHIFT + CTRL + R", "Clear reminders", "~/.local/bin/omarchy-reminder-at clear")

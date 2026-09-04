-- Workspace numbers follow monitors/pontusc-desktop.lua: 1-3 DP-1, 4-5 DP-3, 6-7 HDMI-A-1.

o.window("^steam_app_[0-9]+$", { tag = "+game" })
o.window("^stellaris$", { tag = "+game" })
o.window({ initial_title = "^World of Warcraft$", xwayland = true }, { tag = "+game" })
o.window({ tag = "game" }, { workspace = "3 silent", fullscreen = true, render_unfocused = true, opacity = "1 1" })

o.window({ initial_class = "^steam$" }, { workspace = "2 silent", no_initial_focus = true })
o.window({ class = "^steam_app_default$", initial_title = "^$", xwayland = true }, {
  workspace = "2 silent",
  no_initial_focus = true,
})
-- Must follow the game rule: Battle.net's class carries the +game tag and this rule overrides it.
o.window({ class = "^steam_app_(0|battlenet)$", initial_title = "^Battle\\.net.*$" }, {
  workspace = "2 silent",
  no_initial_focus = true,
  float = true,
  fullscreen = false,
})

o.window("^bolt-launcher$", { workspace = "2 silent", no_initial_focus = true, float = true })
-- The launcher window becomes the client by changing its class, and Swing popups reuse that class,
-- so match on title: the client is "RuneLite ...", every popup is "win<N>".
-- Match patterns must cover the whole value, hence the trailing ".*$".
o.window({ class = "^net-runelite-client-RuneLite$", title = "^RuneLite.*$" }, {
  workspace = "3 silent",
  float = true,
  size = { 1470, 1260 },
  move = { 30, 60 },
  opacity = "1 1",
})

-- Vivaldi hands new windows to its running instance, so exec rules never reach them.
local runelite_browser_pending = false

hl.on("window.open", function(window)
  if
    window.class == "net-runelite-client-RuneLite"
    and #hl.get_windows({ class = "vivaldi-stable", workspace = 3 }) == 0
  then
    runelite_browser_pending = true
    hl.exec_cmd(o.launch("vivaldi --new-window"))
  elseif runelite_browser_pending and window.class == "vivaldi-stable" then
    runelite_browser_pending = false
    hl.dispatch(hl.dsp.window.move({ workspace = "3", follow = false, window = window }))
    hl.dispatch(hl.dsp.window.float({ action = "on", window = window }))
    hl.dispatch(hl.dsp.window.resize({ x = 1050, y = 1410, window = window }))
    hl.dispatch(hl.dsp.window.move({ x = 1510, y = 30, window = window }))
  end
end)

o.window("^.*-music\\.youtube.*$", { workspace = "5 silent" })
o.window("^discord$", { workspace = "6 silent" })
o.window("^TeamSpeak 3$", { workspace = "6 silent" })

-- Workspace numbers follow monitors/pontusc-desktop.lua: 1-3 DP-1, 4-5 DP-3, 6-7 HDMI-A-1.

o.window("^steam_app_[0-9]+$", { tag = "+game" })
o.window("^stellaris$", { tag = "+game" })
o.window({ initial_title = "^World of Warcraft$", xwayland = true }, { tag = "+game" })
o.window({ tag = "game" }, { workspace = "3 silent", fullscreen = true, render_unfocused = true })

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

o.window("^bolt-launcher$", { float = true })
o.window("^net-runelite-client-RuneLite$", { float = true })

o.window("^.*-music\\.youtube.*$", { workspace = "5 silent" })
o.window("^discord$", { workspace = "6 silent" })
o.window("^TeamSpeak 3$", { workspace = "6 silent" })

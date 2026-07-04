-- Window rules. Evaluated top to bottom, last match wins — the default-opacity
-- rule at the bottom must stay after every opt-out.
-- Old rules for reference: hypr-shared/ and hypr-desktop/constraints.conf.

-- Scroll nicely in terminals
hl.window_rule({ match = { class = "^(Alacritty|kitty)$" }, scroll_touchpad = 1.5 })

-- Apps don't get to maximize themselves (fullscreen requests and SUPER+F
-- are separate events and unaffected)
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- XWayland drag-and-drop ghost windows must not steal focus (omarchy)
hl.window_rule({
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Every window starts translucent (omarchy port); apps opt out below by
-- dropping the tag. The opacity itself is applied at the bottom of this file.
hl.window_rule({ match = { class = ".*" }, tag = "+default-opacity" })

-- Browsers: fully opaque when focused, page content tolerates no translucency
hl.window_rule({
    match = { class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|[vV]ivaldi-stable|helium)" },
    tag = "+chromium-based-browser",
})
hl.window_rule({ match = { class = "([fF]irefox|zen|librewolf)" }, tag = "+firefox-based-browser" })
hl.window_rule({ match = { tag = "chromium-based-browser" }, tag = "-default-opacity", tile = true, opacity = "1.0 0.97" })
hl.window_rule({ match = { tag = "firefox-based-browser" }, tag = "-default-opacity", opacity = "1.0 0.97" })

-- Bitwarden float
hl.window_rule({ match = { initial_class = "^Bitwarden$" }, float = true })

-- YT Music webapp: workspace 5, fully opaque (media)
hl.window_rule({
    match = { class = "^.*-music\\.youtube.*$" },
    workspace = "5 silent", tag = "-default-opacity", opacity = "1 1",
})

-- Local video players: fully opaque (media)
hl.window_rule({ match = { class = "^(mpv|vlc)$" }, tag = "-default-opacity", opacity = "1 1" })

-- Picture-in-picture: pinned floating overlay top-right, opaque (omarchy)
hl.window_rule({ match = { title = "(Picture.?in.?[Pp]icture)" }, tag = "+pip" })
hl.window_rule({
    match = { tag = "pip" },
    tag = "-default-opacity",
    float = true,
    pin = true,
    size = { 600, 338 },
    keep_aspect_ratio = true,
    border_size = 0,
    opacity = "1 1",
    move = { "(monitor_w-window_w-40)", "(monitor_h*0.04)" },
})

-- Hide screen-sharing indicator windows (Chrome/Zoom "… is sharing …" pill)
hl.window_rule({ match = { title = ".*is sharing.*" }, workspace = "special silent" })

-- Default opacity, applied last so every opt-out above has already run
hl.window_rule({ match = { tag = "default-opacity" }, opacity = "0.97 0.9" })

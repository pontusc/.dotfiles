-- System binds: audio, media, brightness, notifications, screenshot,
-- copy/paste, lock.

local actions = require("config.actions")

-- Universal copy/paste
hl.bind(MOD .. " + C", actions.send_shortcut_once("CTRL", "Insert"), { description = "Universal copy" })
hl.bind(MOD .. " + V", actions.send_shortcut_once("SHIFT", "Insert"), { description = "Universal paste" })

-- Audio
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true, description = "Volume up" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true, description = "Volume down" }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, description = "Mute audio" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, description = "Mute microphone" }
)

-- Media
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play / pause" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play / pause" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })

-- Brightness
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightnessctl set 5%+"),
	{ repeating = true, description = "Brightness up" }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl set 5%-"),
	{ repeating = true, description = "Brightness down" }
)

-- Notifications
hl.bind(MOD .. " + comma", hl.dsp.exec_cmd("makoctl dismiss"), { description = "Dismiss last notification" })
hl.bind(MOD .. " + SHIFT + comma", hl.dsp.exec_cmd("makoctl dismiss -a"), { description = "Dismiss all notifications" })

-- Screenshot
hl.bind("Print", actions.screenshot_region, { description = "Screenshot region (save + clipboard)" })

-- Lock (config: hyprlock.conf in this package)
hl.bind(MOD .. " + CONTROL + L", hl.dsp.exec_cmd("hyprlock"), { description = "Lock system" })

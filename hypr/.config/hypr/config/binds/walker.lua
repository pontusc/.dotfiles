-- Walker binds: launcher, clipboard, keybindings menu, power menu.

hl.bind(MOD .. " + Space", hl.dsp.exec_cmd("walker"), { description = "Launch apps" })
hl.bind(MOD .. " + CONTROL + V", hl.dsp.exec_cmd("walker -m clipboard"), { description = "Clipboard history" })
hl.bind(
	MOD .. " + CONTROL + K",
	hl.dsp.exec_cmd("~/.local/bin/hypr-menu-keybindings"),
	{ description = "Show key bindings" }
)
-- Power menu (custom elephant menu, .config/elephant/menus/power.toml in this
-- package). SUPER+SHIFT+Escape stays deliberately unbound.
hl.bind(MOD .. " + Escape", hl.dsp.exec_cmd("walker -m menus:power"), { description = "Power menu" })

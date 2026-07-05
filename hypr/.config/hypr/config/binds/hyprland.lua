-- Compositor binds: window navigation / interaction, workspaces.

-- Windows
hl.bind(MOD .. " + W", hl.dsp.window.close(), { description = "Close window" })
hl.bind(MOD .. " + SHIFT + W", hl.dsp.exec_cmd("hyprctl kill"), { description = "Force-kill window (click)" }) -- force-kill mode (click a window)
hl.bind(MOD .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Full screen" })
hl.bind(MOD .. " + O", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle window floating" })
hl.bind(MOD .. " + CONTROL + J", hl.dsp.layout("togglesplit"), { description = "Toggle window split" })

-- Vim-style focus / swap / resize
hl.bind(MOD .. " + H", hl.dsp.focus({ direction = "left" }), { description = "Focus left" })
hl.bind(MOD .. " + J", hl.dsp.focus({ direction = "down" }), { description = "Focus down" })
hl.bind(MOD .. " + K", hl.dsp.focus({ direction = "up" }), { description = "Focus up" })
hl.bind(MOD .. " + L", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })
hl.bind(MOD .. " + SHIFT + H", hl.dsp.window.swap({ direction = "l" }), { description = "Swap window left" })
hl.bind(MOD .. " + SHIFT + J", hl.dsp.window.swap({ direction = "d" }), { description = "Swap window down" })
hl.bind(MOD .. " + SHIFT + K", hl.dsp.window.swap({ direction = "u" }), { description = "Swap window up" })
hl.bind(MOD .. " + SHIFT + L", hl.dsp.window.swap({ direction = "r" }), { description = "Swap window right" })
hl.bind(
	MOD .. " + ALT + H",
	hl.dsp.window.resize({ x = -30, y = 0, relative = true }),
	{ repeating = true, description = "Resize window left" }
)
hl.bind(
	MOD .. " + ALT + J",
	hl.dsp.window.resize({ x = 0, y = 30, relative = true }),
	{ repeating = true, description = "Resize window down" }
)
hl.bind(
	MOD .. " + ALT + K",
	hl.dsp.window.resize({ x = 0, y = -30, relative = true }),
	{ repeating = true, description = "Resize window up" }
)
hl.bind(
	MOD .. " + ALT + L",
	hl.dsp.window.resize({ x = 30, y = 0, relative = true }),
	{ repeating = true, description = "Resize window right" }
)

-- Groups
hl.bind(MOD .. " + G", hl.dsp.group.toggle(), { description = "Toggle group" })
hl.bind(MOD .. " + TAB", hl.dsp.group.next(), { description = "Cycle group windows" })
hl.bind(MOD .. " + ALT + G", hl.dsp.window.move({ out_of_group = true }), { description = "Move window out of group" })

-- Move & resize with mouse
hl.bind(MOD .. " + mouse:272", hl.dsp.window.drag(), { description = "Move window" })
hl.bind(MOD .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

-- Workspaces: switch / move window / move window silently (key 0 = workspace 10)
for i = 1, 10 do
	local key = i % 10
	hl.bind(MOD .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
	hl.bind(
		MOD .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i, follow = true }),
		{ description = "Move window to workspace " .. i }
	)
	hl.bind(
		MOD .. " + ALT + " .. key,
		hl.dsp.window.move({ workspace = i, follow = false }),
		{ description = "Move window silently to workspace " .. i }
	)
end

-- Scratchpad
hl.bind(MOD .. " + S", hl.dsp.workspace.toggle_special("scratchpad"), { description = "Toggle scratchpad" })
hl.bind(
	MOD .. " + SHIFT + S",
	hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }),
	{ description = "Move window to scratchpad" }
)

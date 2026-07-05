-- Declared actions for the bind modules: long commands and helper functions
-- live here so the keymaps stay flat lists of binds. Required by the
-- config/binds/* modules only — not part of hyprland.lua's require chain.

local M = {}

M.terminal_tmux = hl.dsp.exec_cmd(TERMINAL .. " -e sh -c 'tmux attach || tmux new -s Work'")

-- Universal copy/paste (omarchy-style): sends CTRL+Insert / SHIFT+Insert to
-- the focused window so copy/paste behave the same in terminals.
-- send_key_state + timer instead of send_shortcut to avoid stuck synthetic
-- keys (hyprwm/Hyprland#14099).
function M.send_shortcut_once(mods, key)
	return function()
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down", window = "activewindow" }))
		hl.timer(function()
			hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up", window = "activewindow" }))
		end, { timeout = 50, type = "oneshot" })
	end
end

-- Region screenshot: tee splits grim's stdout so the shot is saved to file
-- AND put on the clipboard in one go.
M.screenshot_region = hl.dsp.exec_cmd(
	[[sh -c 'mkdir -p ~/Pictures/screenshots && grim -g "$(slurp)" - | tee ~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy']]
)

return M

-- App-launch shortcuts.

local actions = require("config.actions")

hl.bind(MOD .. " + Return", hl.dsp.exec_cmd(TERMINAL), { description = "Terminal" })
hl.bind(MOD .. " + ALT + Return", actions.terminal_tmux, { description = "Terminal (tmux)" })
hl.bind(MOD .. " + B", hl.dsp.exec_cmd(BROWSER), { description = "Browser" })
hl.bind(MOD .. " + SHIFT + B", hl.dsp.exec_cmd(BROWSER .. " --incognito"), { description = "Browser (incognito)" })
hl.bind(MOD .. " + E", hl.dsp.exec_cmd(FILE_MANAGER), { description = "File manager" })
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(TERMINAL .. " -e btop"), { description = "System monitor" })

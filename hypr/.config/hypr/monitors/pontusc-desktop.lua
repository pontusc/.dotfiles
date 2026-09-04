hl.env("GDK_SCALE", "1")

hl.monitor({ output = "DP-1", mode = "2560x1440@165", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "-1080x0", scale = 1, transform = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080@60", position = "2560x0", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.workspace_rule({ workspace = "1", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1" })
hl.workspace_rule({ workspace = "3", monitor = "DP-1" })

hl.workspace_rule({ workspace = "4", monitor = "DP-3", default = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-3" })

hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-1" })

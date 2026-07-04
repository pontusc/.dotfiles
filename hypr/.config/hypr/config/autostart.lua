-- Autostart. This session does not use uwsm (CachyOS default), so XDG
-- autostart entries do not run — start everything from here.

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpaper")
    -- elephant's unit is WantedBy=graphical-session.target, which never
    -- activates without uwsm — start it here (before walker, its consumer)
    hl.exec_cmd("systemctl --user start elephant.service")
    hl.exec_cmd("walker --gapplication-service")
end)

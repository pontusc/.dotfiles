-- Autostart. This session does not use uwsm (CachyOS default), so XDG
-- autostart entries do not run — start everything from here.

hl.on("hyprland.start", function()
    -- The env import must complete before systemd services that use the session
    -- env start: the user manager survives relogins with the previous session's
    -- WAYLAND_DISPLAY/HYPRLAND_INSTANCE_SIGNATURE — hyprpolkitagent crash-loops
    -- on the dead socket, and a stale-env elephant spawns power-menu actions
    -- (hyprshutdown) against the dead instance. Sequence with `;`, never `&&`:
    -- units can crash-loop into start-limit-hit *before* this runs (seen
    -- 2026-07-04: polkitagent dbus-activated pre-compositor, ABRT x6), so
    -- reset-failed first and don't let one unit's failure block the other.
    -- *restart* (not start) forces a fresh-env respawn of survivors.
    -- (elephant's unit is WantedBy=graphical-session.target, which never
    -- activates without uwsm — it must be started here anyway.)
    hl.exec_cmd("sh -c 'dbus-update-activation-environment --systemd --all;"
        .. " systemctl --user reset-failed hyprpolkitagent.service elephant.service;"
        .. " systemctl --user restart hyprpolkitagent.service elephant.service'")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("walker --gapplication-service")
end)

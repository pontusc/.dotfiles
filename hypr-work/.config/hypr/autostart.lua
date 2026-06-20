-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Apply lid state at startup. libinput only emits edge events, so if the lid
-- was already closed when Hyprland came up the switch:on:Lid Switch binding
-- never fired and eDP-1 stays enabled.
o.exec_on_start([[sh -c 'grep -q closed /proc/acpi/button/lid/*/state && hyprctl keyword monitor "eDP-1, disable"']])

-- Re-enable eDP-1 when the last external monitor is unplugged. Replaces the
-- omarchy-hyprland-monitor-internal recover safeguard that we lose by setting
-- clamshell via hyprctl keyword instead of the omarchy toggle conf file.
o.launch_on_start("/home/pontusc/.local/bin/hypr-edp-recover")

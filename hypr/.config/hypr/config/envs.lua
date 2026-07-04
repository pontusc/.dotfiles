-- Session environment. Hyprland exports env vars to the systemd user
-- environment at startup (verified: `systemctl --user show-environment`), so
-- this reaches services too — no uwsm involved (SDDM runs start-hyprland
-- directly). NOTE: env is startup-only; changes here need a relogin, not a
-- hyprctl reload. Cursor theme vars live in looknfeel.lua.

hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- Qt apps borrow the GTK palette. Only utility apps remain on Qt (hyprpolkitagent,
-- btrfs-assistant, CachyOS tools) — dolphin was dropped for yazi, 2026-07-04.
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

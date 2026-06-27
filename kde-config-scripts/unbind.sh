#!/usr/bin/env bash
set -euo pipefail
#
# Clears stock Plasma shortcuts that collide with our custom binds.
# Single home for every "unbind a default" entry.
#
# Setting a shortcut to "none,none,<name>" disables the active binding while
# keeping the friendly name, so it still appears (unbound) in System Settings.

readonly FILE="kglobalshortcutsrc"

# unbind <group> <key> <friendlyName>
unbind() {
  kwriteconfig6 --file "${FILE}" --group "$1" --key "$2" "none,none,$3"
}

# unbind_launch <desktop-id>  ->  [services][<id>] _launch=none
# App-launch defaults ship in the app's .desktop (X-KDE-Shortcuts); they live
# under [services] with a plain value, so "none" disables them (not a triple).
unbind_launch() {
  kwriteconfig6 --file "${FILE}" --group services --group "$1" --key "_launch" "none"
}

# Free Meta+Space for walker — KRunner's activation lives in this group/key
# (verified live via kglobalaccel: component org.kde.krunner.desktop).
unbind "org.kde.krunner.desktop" "_launch" "KRunner"

# Free Meta+Escape for the logout-screen bind (keybinds.sh) — System Monitor ships
# X-KDE-Shortcuts=Meta+Esc in its .desktop and otherwise wins the key.
unbind_launch "org.kde.plasma-systemmonitor.desktop"

# Free Meta+V for kitty's paste (kitty.conf) — Plasma 6 folds Klipper into
# plasmashell, which binds Meta+V to "Show Clipboard Items at Mouse Position".
unbind "plasmashell" "show-on-mouse-pos" "Show Clipboard Items at Mouse Position"

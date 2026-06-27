#!/usr/bin/env bash
set -euo pipefail
#
# Clears stock Plasma shortcuts that collide with our custom binds.
# Single home for every "unbind a default" entry.
#
# Setting a shortcut to "none,none,<name>" disables the active binding while
# keeping the friendly name, so it still appears (unbound) in System Settings.

readonly FILE="kglobalshortcutsrc"
readonly GAMING_HOST="desktop"   # only this host gets the Meta+1..5 unbinds

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

# Free Meta+1..5 for the monitor-bound-workspaces KWin script (desktop host
# only) — Plasma binds these to "Activate Task Manager Entry N" by default.
# Hostname captured on its own line so a hostnamectl failure trips set -e.
host="$(hostnamectl --static hostname)"
readonly host
if [[ "${host}" == "${GAMING_HOST}" ]]; then
  for n in 1 2 3 4 5; do
    unbind plasmashell "activate task manager entry ${n}" "Activate Task Manager Entry ${n}"
  done
fi

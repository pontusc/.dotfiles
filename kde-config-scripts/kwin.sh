#!/usr/bin/env bash
set -euo pipefail
#
# Declares KWin settings in kwinrc.
# Run standalone to write, or via apply.sh to also apply live.
#
# Note: the [Tiling] section is keyed by per-machine UUIDs holding JSON
# layouts and is intentionally NOT managed here (not portable).

readonly FILE="kwinrc"

# kw <group> <key> <value>
kw() {
  kwriteconfig6 --file "${FILE}" --group "$1" --key "$2" "$3"
}

readonly GAMING_HOST="desktop"   # only this host gets monitor-bound workspaces

# Captured on its own line so a hostnamectl failure trips set -e instead of
# silently yielding "" inside the if-condition (where set -e is suppressed).
host="$(hostnamectl --static hostname)"
readonly host

kw Plugins  shakecursorEnabled false
kw Plugins  zoomEnabled        false
kw Plugins  slideEnabled       false   # instant desktop switching, no slide animation
kw Input    TabletMode         off
kw Xwayland Scale              1
kw Desktops Rows               1

# Per-screen virtual desktops + the monitor-bound-workspaces KWin script are
# wanted only on the multi-monitor desktop; other machines keep one desktop.
if [[ "${host}" == "${GAMING_HOST}" ]]; then
  # KWin auto-creates the missing Id_2..Id_5 desktop UUIDs from Number on load.
  kw Desktops Number             5
  kw Desktops Name_3             Games
  kw Windows  PerOutputVirtualDesktops true   # per-screen desktops (6.7+, Wayland)
  kw Plugins  monitorworkspacesEnabled  true  # enable the stowed KWin script
else
  kw Desktops Number             1
fi

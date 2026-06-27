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

kw Plugins  shakecursorEnabled false
kw Plugins  zoomEnabled        false
kw Input    TabletMode         off
kw Xwayland Scale              1
kw Desktops Number             1
kw Desktops Rows               1

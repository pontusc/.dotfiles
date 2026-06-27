#!/usr/bin/env bash
set -euo pipefail
#
# Entry point: applies every KDE config concern, then reloads the relevant
# Plasma daemons so changes take effect without a full logout where possible.
#
# Usage: ./apply.sh   (run on a fresh machine, or after editing a concern script)

HERE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly HERE

# Concern scripts, applied in order (unbind defaults before setting new binds).
for script in unbind keybinds kwin window-rules; do
  echo "==> applying ${script}"
  "${HERE}/${script}.sh"
done

# Apply live where supported; ignore failures (e.g. run outside a Plasma session).
echo "==> reloading Plasma config"
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true   # kwinrc applies live

# On Plasma Wayland the global-shortcuts server is embedded in KWin, which reads
# kglobalshortcutsrc only at session start. There is no live-reload, and the
# standalone kglobalacceld exits as a no-op (KWin owns org.kde.kglobalaccel), so
# keybind changes require a log out / back in to register.
echo
echo "Done. kwinrc applied live. Keybind changes need a LOG OUT / BACK IN to take effect."

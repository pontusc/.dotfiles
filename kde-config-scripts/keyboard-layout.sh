#!/usr/bin/env bash
set -euo pipefail
#
# Declares the keyboard-layout switch shortcut in kxkbrc.
# LayoutList / variants are left as-is (managed via System Settings); this only
# sets the xkb switching option.
#
#   grp:alts_toggle = press Both Alts together to cycle layouts.

readonly FILE="kxkbrc"

kwriteconfig6 --file "${FILE}" --group Layout --key Options "grp:alts_toggle"
# KWin only pushes custom Options into the compiled keymap when this is set.
kwriteconfig6 --file "${FILE}" --group Layout --key ResetOldOptions --type bool true

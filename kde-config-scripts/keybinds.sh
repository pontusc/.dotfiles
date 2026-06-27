#!/usr/bin/env bash
set -euo pipefail
#
# Declares KDE global shortcuts in kglobalshortcutsrc.
# Run standalone to write the keys, or via apply.sh to also reload daemons.
#
# kglobalshortcutsrc value format:  "current,default,friendlyName"
#   - current  = active binding ("none" means unbound)
#   - default  = factory default, kept so "Reset to defaults" works
#   - multiple keys are tab-separated; rebind by editing the current field.
#
# Seeded from the live config; values match the current setup so a first
# run is a no-op. Change the first (current) field to rebind.

readonly FILE="kglobalshortcutsrc"

# sc <group> <key> <value-triple>
sc() {
  kwriteconfig6 --file "${FILE}" --group "$1" --key "$2" "$3"
}

# launch <desktop-id> <key>  ->  [services][<desktop-id>] _launch=<key>
# App launches use a nested [services][...] group and a plain key (no triple).
launch() {
  kwriteconfig6 --file "${FILE}" --group services --group "$1" --key "_launch" "$2"
}

# --- KWin (window manager) ---
sc kwin "Overview"        "none,Meta+W,Toggle Overview"
sc kwin "Grid View"       "Meta+G,Meta+G,Toggle Grid View"
sc kwin "Show Desktop"    "Meta+D,Meta+D,Peek at Desktop"
sc kwin "Edit Tiles"      "Meta+T,Meta+T,Toggle Tiles Editor"
sc kwin "Window Close"      "Meta+W,Alt+F4,Close Window"
sc kwin "Window Maximize"   "Meta+F,none,Maximize Window"
sc kwin "Window Fullscreen" "Meta+Shift+F,none,Make Window Fullscreen"

# Directional window focus (Hyprland-style vim nav). Replaces the Meta+Alt+Arrow
# defaults with Meta+h/j/k/l; the default field keeps the factory arrow bind.
sc kwin "Switch Window Left"  "Meta+H,Meta+Alt+Left,Switch to Window to the Left"
sc kwin "Switch Window Down"  "Meta+J,Meta+Alt+Down,Switch to Window Below"
sc kwin "Switch Window Up"    "Meta+K,Meta+Alt+Up,Switch to Window Above"
sc kwin "Switch Window Right" "Meta+L,Meta+Alt+Right,Switch to Window to the Right"

# --- App launchers ---
# walker via a hidden walker.desktop (shipped in the walker stow package);
# Meta+Space is freed by unbind.sh first.
launch "walker.desktop" "Meta+Space"
# Terminal TUIs via hidden launchers shipped in the kde-launchers stow package.
launch "launch-btop.desktop" "Meta+Shift+T"      # btop
launch "launch-tmux.desktop" "Meta+Alt+Return"   # tmux session
# Browser: Super+B uses the system vivaldi-stable.desktop directly; Super+Shift+B
# needs --incognito, so it goes through a hidden launcher (kde-launchers package).
launch "vivaldi-stable.desktop" "Meta+B"               # browser
launch "launch-browser-private.desktop" "Meta+Shift+B" # browser, incognito
# Terminal & file manager via their system .desktop entries (no args, launched directly).
launch "kitty.desktop" "Meta+Return"                   # terminal
launch "org.kde.dolphin.desktop" "Meta+E"              # file manager

# --- Session / power ---
# Super+Escape -> walker power menu (launch-power-menu.desktop runs ~/.local/bin/power-menu).
# System Monitor's default Meta+Esc is cleared in unbind.sh; the native ksmserver
# logout screen is left on its Ctrl+Alt+Del default.
sc ksmserver "Log Out" "Ctrl+Alt+Del,Ctrl+Alt+Del,Show Logout Screen"
# Lock moved off the default Meta+L to Meta+Ctrl+L (keeps the XF86Screensaver key).
# Tab separates the two binds; $'...' yields a real tab that KConfig escapes to \t.
sc ksmserver "Lock Session" $'Screensaver\tMeta+Ctrl+L,Screensaver\tMeta+L,Lock Session'
launch "launch-power-menu.desktop" "Meta+Escape"

#!/usr/bin/env bash
set -euo pipefail
#
# Sets the desktop wallpaper and the plasmalogin (login screen) background from
# a shared image library.
#
# WALLPAPERS maps a local filename to a source URL. On run, any file missing
# from WALLPAPER_DIR is downloaded from its URL. DESKTOP_PICK and LOGIN_PICK
# then each choose any filename from that library (they may be the same).
# Leave a pick empty to skip that target.
#
# The desktop wallpaper is applied rootless via plasma-apply-wallpaperimage.
# The login background lives under /var/lib/plasmalogin/ and is configured in
# /etc/plasmalogin.conf, both root-owned -- so ONLY the login half uses sudo.
# This script is intentionally NOT part of apply.sh (which runs rootless).

# --- Config -----------------------------------------------------------------

WALLPAPER_DIR="${HOME}/.local/share/wallpapers"

# Shared library: local filename => source URL. Add as many as you like; any
# file not already present in WALLPAPER_DIR is downloaded from its URL.
declare -A WALLPAPERS=(
    ["wallhaven-qr3175.jpg"]="https://w.wallhaven.cc/full/qr/wallhaven-qr3175.jpg"
    ["wallhaven-e7wvrr.png"]="https://w.wallhaven.cc/full/e7/wallhaven-e7wvrr.png"
)

# Pick any filename from WALLPAPERS for each target. Leave empty to skip.
DESKTOP_PICK="wallhaven-qr3175.jpg"
LOCK_PICK="wallhaven-qr3175.jpg"
LOGIN_PICK="wallhaven-e7wvrr.png"

# Desktop fill mode passed to plasma-apply-wallpaperimage. preserveAspectFit
# shows the whole image (letterboxed); preserveAspectCrop (KDE default) fills
# the screen but crops; also: stretch, tile, tileVertically, tileHorizontally.
DESKTOP_FILL_MODE="preserveAspectCrop"

# plasmalogin paths (root-owned).
LOGIN_DEST_DIR="/var/lib/plasmalogin/wallpapers"
LOGIN_CONF="/etc/plasmalogin.conf"

# --- Library download -------------------------------------------------------

# Download every library entry whose local file is missing.
download_library() {
    mkdir -p "${WALLPAPER_DIR}"
    local name url path
    for name in "${!WALLPAPERS[@]}"; do
        url="${WALLPAPERS[$name]}"
        path="${WALLPAPER_DIR}/${name}"
        if [[ -f "${path}" ]]; then
            continue
        fi
        if [[ -z "${url}" ]]; then
            echo "no URL for missing ${name}; skipping" >&2
            continue
        fi
        echo "downloading ${name}"
        curl -fL --retry 3 -o "${path}" "${url}"
    done
}

download_library

# --- Desktop wallpaper (rootless) -------------------------------------------

if [[ -n "${DESKTOP_PICK}" ]]; then
    desktop_path="${WALLPAPER_DIR}/${DESKTOP_PICK}"
    if [[ ! -f "${desktop_path}" ]]; then
        echo "desktop pick ${DESKTOP_PICK} not found in ${WALLPAPER_DIR}" >&2
    elif command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
        plasma-apply-wallpaperimage --fill-mode "${DESKTOP_FILL_MODE}" "${desktop_path}"
    else
        echo "plasma-apply-wallpaperimage not found; skipping desktop wallpaper" >&2
    fi
fi

# --- Lock screen (kscreenlockerrc, rootless, applies at next lock) ----------

if [[ -n "${LOCK_PICK}" ]]; then
    lock_path="${WALLPAPER_DIR}/${LOCK_PICK}"
    if [[ ! -f "${lock_path}" ]]; then
        echo "lock pick ${LOCK_PICK} not found in ${WALLPAPER_DIR}" >&2
    else
        kwriteconfig6 --file kscreenlockerrc \
            --group Greeter --group Wallpaper --group org.kde.image --group General \
            --key Image "file://${lock_path}"
        echo "lock screen background set; applies at next lock."
    fi
fi

# --- Login background (plasmalogin, needs root) -----------------------------

if [[ -n "${LOGIN_PICK}" ]]; then
    login_path="${WALLPAPER_DIR}/${LOGIN_PICK}"
    if [[ ! -f "${login_path}" ]]; then
        echo "login pick ${LOGIN_PICK} not found in ${WALLPAPER_DIR}" >&2
    else
        dest="${LOGIN_DEST_DIR}/${LOGIN_PICK}"
        echo "installing login background (sudo) -> ${dest}"
        sudo mkdir -p "${LOGIN_DEST_DIR}"
        sudo install -m 644 "${login_path}" "${dest}"
        sudo kwriteconfig6 --file "${LOGIN_CONF}" \
            --group Greeter --group Wallpaper --group org.kde.image --group General \
            --key Image "file://${dest}"
        echo "login background set; takes effect at next login."
    fi
fi

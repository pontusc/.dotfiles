#!/usr/bin/env bash
set -euo pipefail
#
# Declares session-manager settings in ksmserverrc.
#
# loginMode controls the "On Login" behaviour (System Settings > Session):
#   restorePreviousLogout (default) | restoreSavedSession | emptySession
# emptySession starts a clean session instead of reopening the previous
# session's windows. Takes effect from the next logout / login.

readonly FILE="ksmserverrc"

kwriteconfig6 --file "${FILE}" --group General --key loginMode emptySession

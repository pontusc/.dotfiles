#!/usr/bin/env bash
set -euo pipefail
#
# Declares KWin window rules in kwinrulesrc: pins TeamSpeak3 and Discord to the
# left (portrait) monitor at fixed positions/sizes, both FORCED (rule type 2).
#
# Position is in global desktop coordinates; the left output (HDMI-A-1) spans
# (0,0)-(1080,1920), so forcing position alone places the windows there without
# relying on the unstable KWin screen index.
#
# kwinrulesrc layout: [General] count + rules list, then one [<id>] group per
# rule. Rule-type ints: 0=unused 1=do-not-affect 2=force 3=apply-initially.

readonly FILE="kwinrulesrc"

# wr <group> <key> <value>
wr() { kwriteconfig6 --file "${FILE}" --group "$1" --key "$2" "$3"; }

wr General count 3
wr General rules "1,2,3"

# --- 1: TeamSpeak 3 -> top strip of left monitor, below the top panel
#        (1080x620 @ 0,30). The y-offset clears the docked (non-floating)
#        top panel (30px thickness) that would otherwise cover its top. ---
wr 1 Description "TeamSpeak 3 - left monitor, top strip"
wr 1 wmclass "TeamSpeak 3"
wr 1 wmclassmatch 1           # exact
wr 1 wmclasscomplete false    # match resourceClass only
wr 1 position 0,30
wr 1 positionrule 2           # force
wr 1 size 1080,620
wr 1 sizerule 2

# --- 2: Discord -> rest of left monitor (1080x1270 @ 0,650) ---
wr 2 Description "Discord - left monitor, bottom"
wr 2 wmclass discord
wr 2 wmclassmatch 1
wr 2 wmclasscomplete false
wr 2 position 0,650
wr 2 positionrule 2
wr 2 size 1080,1270
wr 2 sizerule 2

# --- 3: Steam games -> force real fullscreen ---
# Proton/Steam titles get resourceClass "steam_app_<appid>" (both WM_CLASS
# strings are the appid), so a SUBSTRING match on the shared prefix covers every
# game with one rule. Same prefix the monitorworkspaces KWin script keys off
# (GAME_PREFIXES in kde-kwin-scripts/.../main.js).
#
# Why: a game's "windowed fullscreen" mode maps a MAXIMIZED undecorated window
# (_NET_WM_STATE_MAXIMIZED_{VERT,HORZ}), not _NET_WM_STATE_FULLSCREEN. KWin's
# Window::belongsToLayer() only promotes to ActiveLayer when isActiveFullScreen()
# is true, so a maximized game stays in NormalLayer -- below the panel's
# AboveLayer -- and the top bar is drawn over it. Forcing the fullscreen state
# puts the game in ActiveLayer, above the panel.
#
# Caveat: any launcher/config window a game opens under the same steam_app_
# class is forced fullscreen too. Add a narrower exact-match rule for that appid
# if it ever bites.
wr 3 Description "Steam games - force fullscreen"
wr 3 wmclass "steam_app_"
wr 3 wmclassmatch 2           # substring (0=unimportant 1=exact 2=substring 3=regex)
wr 3 wmclasscomplete false    # match resourceClass only
wr 3 fullscreen true
wr 3 fullscreenrule 2         # force

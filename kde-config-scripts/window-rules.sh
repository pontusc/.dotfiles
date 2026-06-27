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

wr General count 2
wr General rules "1,2"

# --- 1: TeamSpeak 3 -> top strip of left monitor (1080x500 @ 0,0) ---
wr 1 Description "TeamSpeak 3 - left monitor, top strip"
wr 1 wmclass "TeamSpeak 3"
wr 1 wmclassmatch 1           # exact
wr 1 wmclasscomplete false    # match resourceClass only
wr 1 position 0,0
wr 1 positionrule 2           # force
wr 1 size 1080,650
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

#!/usr/bin/env bash
set -euo pipefail
#
# Puts one bar on every screen, each laid out as:
#   Pager (left) | spacer | Digital Clock (center) | spacer | System Tray (right)
#
# A bar per monitor is required for the workspace highlight to work: under
# per-output virtual desktops each pager reflects only ITS screen's current
# desktop, so a single bar can never light up desktops bound to other monitors.
#
# Uses the Plasma Shell JS scripting API (evaluateScript), NOT kwriteconfig6 on
# plasma-org.kde.plasma.desktop-appletsrc: plasmashell holds that file in memory
# and rewrites it, so direct edits get clobbered. evaluateScript applies live,
# persists, and needs no plasmashell restart.
#
# Idempotent: removes every existing panel and recreates one per screen from
# scratch, so every run yields the same result (matching existing panels by
# screen proved unreliable). Screen count is read live (screenCount), so it
# adapts: one bar on a laptop, three on the multi-monitor desktop.

read -r -d '' JS <<'EOF' || true
// widget.index is a no-op stub in Plasma's scripting engine, so widget order can
// only be controlled by the sequence of addWidget() calls — hence the full
// teardown + rebuild in buildBar().

// Pull a reference system-tray visibility config from any existing tray, so all
// bars get an identical tray instead of fresh defaults on the new screens.
function readRefTray() {
    var all = panels();
    for (var i = 0; i < all.length; i++) {
        var ws = all[i].widgets();
        for (var j = 0; j < ws.length; j++) {
            if (ws[j].type == "org.kde.plasma.systemtray") {
                ws[j].currentConfigGroup = ["General"];
                return {
                    shown:  ws[j].readConfig("shownItems",  ""),
                    hidden: ws[j].readConfig("hiddenItems", ""),
                    extra:  ws[j].readConfig("extraItems",  "")
                };
            }
        }
    }
    return { shown: "", hidden: "", extra: "" };
}

function buildBar(p, ref) {
    var ws = p.widgets();
    for (var i = 0; i < ws.length; i++) ws[i].remove();

    // Rebuild: pager | spacer | clock | spacer | tray
    var pager = p.addWidget("org.kde.plasma.pager");
    pager.currentConfigGroup = ["General"];
    pager.writeConfig("displayedText", 0);            // 0=Number, 1=Name, 2=None
    pager.writeConfig("showWindowOutlines", false);   // clean "1 2 3 4 5" look
    pager.writeConfig("showWindowIcons", false);
    pager.reloadConfig();

    var left = p.addWidget("org.kde.plasma.panelspacer");
    left.currentConfigGroup = ["General"];
    left.writeConfig("expanding", true);              // expand to push clock center
    left.reloadConfig();

    p.addWidget("org.kde.plasma.digitalclock");

    var right = p.addWidget("org.kde.plasma.panelspacer");
    right.currentConfigGroup = ["General"];
    right.writeConfig("expanding", true);
    right.reloadConfig();

    var tray = p.addWidget("org.kde.plasma.systemtray");
    tray.currentConfigGroup = ["General"];
    if (ref.shown)  tray.writeConfig("shownItems",  ref.shown);
    if (ref.hidden) tray.writeConfig("hiddenItems", ref.hidden);
    if (ref.extra)  tray.writeConfig("extraItems",  ref.extra);
    tray.reloadConfig();
}

var ref = readRefTray();

// Remove all existing panels (we manage them wholesale), then create one bar
// per screen. panel.screen is writable since Plasma 6.3; new panels are forced
// to screen 0 at creation, so it must be set explicitly afterwards.
var existing = panels();
for (var i = 0; i < existing.length; i++) existing[i].remove();

// Opacity is NOT set here: the scripting `opacity`/`panel.opacity` property is a
// no-op in Plasma 6.7 (set returns the unchanged value). We emit the new panel
// ids instead and write panelOpacity directly to plasmashellrc from bash below.
var ids = [];
for (var s = 0; s < screenCount; s++) {
    var panel = new Panel;
    panel.screen = s;
    panel.location = "top";
    panel.floating = false;          // dock flush to the edge (no floating gap)
    buildBar(panel, ref);
    ids.push(panel.id);
}
print(ids.join(" "));
EOF

# evaluateScript only works against a live plasmashell; skip cleanly otherwise
# so apply.sh doesn't abort on a non-Plasma machine.
if qdbus6 org.kde.plasmashell >/dev/null 2>&1; then
  # evaluateScript echoes the script's print() output, i.e. the new panel ids.
  ids="$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "${JS}")"

  # Force the bars translucent. The scripting opacity property is a no-op in
  # Plasma 6.7, so write panelOpacity straight to plasmashellrc for each panel
  # (OpacityMode enum: 0=Adaptive, 1=Opaque, 2=Translucent). KConfig merges the
  # key while plasmashell runs; it renders translucent after plasmashell next
  # re-reads its config (log out / back in, or reboot).
  for id in ${ids}; do
    kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel ${id}" \
      --key panelOpacity 2
  done
else
  echo "plasmashell not reachable; skipping panel layout" >&2
fi

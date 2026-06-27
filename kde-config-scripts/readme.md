# kde-config-scripts

Imperative scripts that declare KDE Plasma config. Run `./apply.sh` to apply
everything and reload the relevant daemons; each concern script can also be run
standalone.

| Script | Concern | Mechanism |
|--------|---------|-----------|
| `unbind.sh` | Clear stock shortcuts that collide with ours | `kwriteconfig6` on `kglobalshortcutsrc` |
| `keybinds.sh` | Custom global shortcuts | `kwriteconfig6` on `kglobalshortcutsrc` |
| `kwin.sh` | KWin settings, virtual desktops, per-output desktops | `kwriteconfig6` on `kwinrc` |
| `window-rules.sh` | Per-window placement rules | `kwriteconfig6` on `kwinrc` |
| `panel.sh` | One bar per screen (pager · clock · tray) | Plasma JS scripting API via `evaluateScript` |

## Why `panel.sh` is different

Panel layout (`plasma-org.kde.plasma.desktop-appletsrc`) is **not** edited with
`kwriteconfig6`: plasmashell holds that file in memory and rewrites it, so direct
edits get clobbered. Instead `panel.sh` drives the official Plasma JS scripting
API through `qdbus6 org.kde.plasmashell /PlasmaShell evaluateScript`, which
applies live and persists without a plasmashell restart.

It must run inside a live Plasma session; on a headless / non-Plasma machine it
self-skips. Output of `evaluateScript` is not echoed over this qdbus path —
verify results by inspecting the appletsrc, not the command's stdout.

## Plasma / KWin scripting gotchas (hard-won)

- **`widget.index` is a no-op stub.** In Plasma's scripting engine `setIndex` is
  commented out and the getter returns `-1`. Widget left-to-right order can only
  be controlled by the **sequence of `addWidget()` calls** — so reordering means
  tearing the panel down and rebuilding it in order (what `panel.sh` does).
- **`location` enum: `3` = top edge, `4` = bottom edge** (Plasma `Location`:
  Floating 0, Desktop 1, FullScreen 2, TopEdge 3, BottomEdge 4, Left 5, Right 6).
  Easy to mislabel when reading the raw config.
- **`panel.screen` is writable** (since Plasma 6.3). A `new Panel` is forced onto
  screen 0 at creation, so the target screen must be set explicitly afterwards.
  The scripting screen index matches `lastScreen` in the appletsrc.
- **Per-output virtual desktops + Pager:** each Pager reflects only *its own*
  screen's current desktop, so one shared bar can never highlight desktops bound
  to other monitors. Hence one bar per screen.
- **Built-in Pager has no width control** — cells are monitor-aspect thumbnails.
  Narrow numbered buttons require a third-party Virtual Desktop Bar widget.

## Companion: KWin script

The monitor-bound workspace switching + game routing lives in a separate KWin
script package under `../kde-kwin-scripts/` (stowed, host-gated to `desktop`).
`kwin.sh` enables it via `monitorworkspacesEnabled`.

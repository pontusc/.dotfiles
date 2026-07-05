# Session initialization — issues & fix plan

Distilled from the (deleted) hypr-lua-migration plan, 2026-07-05. This is the
one open structural problem in the Hyprland setup: **nothing manages session
lifecycle**. The autostart chain in `hypr/.config/hypr/config/autostart.lua`
papers over it and works, but every bug below is the same root cause wearing a
different hat.

## The plan

Research the official way to run a systemd-integrated Hyprland session — uwsm,
or Hyprland's own systemd integration (`hyprland-session.target` or whatever
exists by then; official Hyprland + systemd docs, verified live, not from
memory) — and adopt it. The band-aid chain and most of the notes below then
collapse into it.

## Current state (the band-aid)

- SDDM `Session=hyprland` runs CachyOS's `start-hyprland` binary directly —
  **no uwsm anywhere**. A `~/.config/uwsm/env` found earlier was dead config,
  never sourced (deleted 2026-07-04).
- Because of that, XDG autostart entries never run and
  `graphical-session.target` never activates (nothing pulls it in, and it's
  `RefuseManualStart=yes`) — user units `WantedBy=graphical-session.target`
  (elephant) stay dead at login unless started explicitly.
- So everything starts from `config/autostart.lua` on `hyprland.start`, with
  this load-bearing chain (sequenced `;`, never `&&`):

  ```
  dbus-update-activation-environment --systemd --all;
  systemctl --user reset-failed hyprpolkitagent.service elephant.service;
  systemctl --user restart hyprpolkitagent.service elephant.service
  ```

## Evidence trail (why the chain looks like that)

All from 2026-07-04, verified live:

- **The systemd user manager survives relogin holding the previous session's
  env** (`WAYLAND_DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE`). Consequences seen:
  - hyprpolkitagent SIGABRTed on the dead socket ×6 (`Restart=on-failure`)
    into `start-limit-hit` before the env import landed; polkit prompts dead.
  - elephant (survives relogin) spawned power-menu actions — `hyprshutdown`
    resolves the compositor socket from `HYPRLAND_INSTANCE_SIGNATURE` — against
    the dead instance: walker Logout was a silent no-op. Proven by comparing
    unit start time vs compositor signature.
- **Units can be in `start-limit-hit` before autostart even runs**: something
  dbus-activated hyprpolkitagent 5s *before* Hyprland was up → crash-loop →
  the original `&&` chain short-circuited and elephant kept its stale
  signature. Hence: `;` not `&&`, `reset-failed` first, `restart` (not
  `start`) to force fresh-env respawns of survivors.
- **Locale changes need a reboot, not a relogin**: PID1 and SDDM read
  `/etc/locale.conf` at boot and the session inherits SDDM's env, so a relogin
  re-inherits stale `LC_*`. Same stale-env-survivor family.
- **Hyprland `hl.env()` exports to the systemd user environment at startup**
  (verified via `systemctl --user show-environment`) — reaches services, no
  uwsm needed for that. Startup-only: changes need relogin, not reload.
- **Walker service is unsupervised** (fire-and-forget from autostart.lua);
  died once, cause unknown — walker still works per-invocation, just slower.
  If it recurs, give it a user unit like elephant's — which then hits the
  graphical-session.target caveat above, another push toward the real fix.
- Shell nuisance: shells from before a relogin can't reach hyprctl — fix
  `export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr/ | head -1)`.

## Pending proof

- End-to-end proof of the `;`-chain fix: next relogin.
- Locale fix (`date +%A` → Saturday) and full autostart health: next reboot.

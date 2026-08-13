-- pc-framework: Samsung Odyssey G95C ultrawide as the primary external,
-- eDP-1 clamshell-aware so a docked lid close never drops to zero enabled
-- monitors. UNVERIFIED: Hyprland 0.56 may already ship a crash-safe fallback
-- output for that case — re-check at cutover (see TODO.md).

local EDP = "eDP-1"

-- mirror = "none" and disabled = false are both load-bearing: re-applying
-- this rule without a key does not clear that key's current state — only an
-- explicit value does.
local edp_rule =
  { output = EDP, mode = "2256x1504@60", position = "auto-left", scale = 1, disabled = false, mirror = "none" }

hl.env("GDK_SCALE", "1")

-- Ultrawide first, pinned at 0x0 (never auto): eDP's position is "auto-left",
-- computed relative to whatever monitors are already placed, so the
-- ultrawide's absolute rule must land before eDP's relative one.
hl.monitor({ output = "desc:Samsung Electric Company Odyssey G95C", mode = "5120x1440@60", position = "0x0", scale = 1 })
hl.monitor(edp_rule)
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

local function lid_closed()
  local file = io.popen("cat /proc/acpi/button/lid/*/state 2>/dev/null")
  if not file then
    return false
  end

  local state = file:read("*a")
  file:close()
  return state:find("closed") ~= nil
end

local function external_count()
  local count = 0
  for _, monitor in ipairs(hl.get_monitors()) do
    if monitor.name ~= EDP then
      count = count + 1
    end
  end
  return count
end

-- Quattro's SUPER+CTRL+ALT+Delete mirror toggle marks its state in this
-- file; a mirroring external disappears from hl.get_monitors(), so
-- external_count() reads 0 while mirrored and must not trigger edp_reset().
local function mirroring()
  local file =
    io.open((os.getenv("HOME") or "") .. "/.local/state/omarchy/toggles/hypr/internal-monitor-mirror.conf", "r")
  if not file then
    return false
  end

  file:close()
  return true
end

local function clamshell()
  if external_count() > 0 then
    hl.monitor({ output = EDP, disabled = true })
  end
  -- No external connected: leave eDP-1 alone. logind's HandleLidSwitch=ignore
  -- drop-in means lid close does not suspend, and disabling the only monitor
  -- crashes this Hyprland version.
end

local function edp_reset()
  hl.monitor(edp_rule)
end

-- Bypass Omarchy's default lid handlers: omarchy-hyprland-monitor-internal
-- writes a wildcard `monitor=,disable` when its $INTERNAL detection resolves
-- empty, which would disable every monitor instead of just eDP-1.
hl.unbind("switch:on:Lid Switch")
hl.unbind("switch:off:Lid Switch")

hl.bind("switch:on:Lid Switch", clamshell, { locked = true, description = "Lid closed: disable eDP-1 if docked" })
hl.bind("switch:off:Lid Switch", edp_reset, { locked = true, description = "Lid opened: re-enable eDP-1" })

-- An external plugged in while the lid is already closed (e.g. waking into a
-- dock) never fires the lid switch edge, so re-apply clamshell on hotplug too.
hl.on("monitor.added", function()
  if lid_closed() then
    clamshell()
  end
end)

-- Last external unplugged while clamshelled: bring eDP-1 back immediately,
-- or the session hits the zero-monitor crash path.
hl.on("monitor.removed", function()
  if external_count() == 0 and not mirroring() then
    edp_reset()
  end
end)

-- Booted or relogged with the lid already closed: the edge event never
-- fired, so check state directly once at startup.
hl.on("hyprland.start", function()
  if lid_closed() then
    clamshell()
  end
end)

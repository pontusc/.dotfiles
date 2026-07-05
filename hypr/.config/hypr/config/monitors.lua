-- Monitors + clamshell. Per-host tables come with the host.lua refactor
-- (Phase 3) — the eDP mode and the lid device name get parameterized there.
--
-- Sleep policy is stock logind, no drop-in: HandleLidSwitch=suspend fires on
-- lid close unless "docked" (= more than one display connected), which logind
-- ignores by default. This file only handles the displays.
--
-- Verified live on Hyprland 0.55.4 (2026-07-04):
--   - hl.get_monitors() lists only ENABLED monitors, and in monitor.removed
--     the dead monitor is already gone — the externals() guards are race-free.
--   - monitor.removed fires several times per unplug: handlers must be
--     idempotent (re-applying the same rule is a no-op).
--   - A monitor that is mirroring another leaves the layout AND
--     hl.get_monitors(), so externals() is 0 while the external mirrors the
--     panel — every handler below must stay correct under that.
--   - hyprctl reload drops runtime-applied monitor rules (a mirroring
--     external falls back to the catch-all and un-mirrors), so the mirror
--     toggle state resetting on reload matches what the compositor does.
--   - 0.55.4 predates the zero-monitor FALLBACK output (hyprwm/Hyprland
--     PR #14547): zero enabled monitors is a crash path. Never disable eDP-1
--     unless an external is present — clamshell() guards this.

local EDP = "eDP-1"

-- mirror = "none" is load-bearing: re-applying a rule *without* the key does
-- not clear an active mirror, only an explicit "none" does (verified live)
local edp_rule = { output = EDP, mode = "1920x1200@60", position = "auto", scale = 1, disabled = false, mirror = "none" }

hl.monitor(edp_rule)

-- Anything unnamed: just light it up until the Phase 3 host tables arrange it
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Workspaces 1-2 live on the panel, 3-4 on the external; the rest go wherever
-- Hyprland puts them. External name hardcoded until the Phase 3 host tables.
-- Upstream is known-flaky about moving bound workspaces back on reconnect
-- (hyprwm/Hyprland #9580, #5464) — if it shows, add a moveworkspacetomonitor
-- fallback rather than fighting the rules.
hl.workspace_rule({ workspace = "1", monitor = EDP, default = true })
hl.workspace_rule({ workspace = "2", monitor = EDP })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1" })

-- The lid switch only emits edge events, so the binds below never fire for a
-- lid that is already closed — startup and hotplug read the state directly
local function lid_closed()
    local f = io.open("/proc/acpi/button/lid/LID/state")
    if not f then return false end
    local state = f:read("*a")
    f:close()
    return state:find("closed") ~= nil
end

local function externals()
    local n = 0
    for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= EDP then n = n + 1 end
    end
    return n
end

-- Mirroring: the EXTERNAL mirrors the panel (panel stays the layout monitor,
-- keeping its waybar/wallpaper — the other direction rips the panel out of
-- the layout and both waybar and hyprpaper are known to mishandle that:
-- Alexays/Waybar #4759, hyprwm/hyprpaper #54). Toggle state is a local
-- because querying is_mirror back is broken upstream (#14645).
local mirroring = false
local mirror_target = nil
local function mirror_off()
    if mirror_target then
        -- back to the catch-all's arrangement; mirror = "none" is
        -- load-bearing — re-applying a rule without the key does NOT clear
        -- an active mirror (verified live). Applying it to an unplugged
        -- target is harmless and clears the sticky named rule so a replug
        -- doesn't resume mirroring.
        hl.monitor({ output = mirror_target, mode = "preferred", position = "auto", scale = "auto", mirror = "none" })
    end
    mirroring = false
    mirror_target = nil
end

local function edp_reset()
    hl.monitor(edp_rule)
end

local function clamshell()
    if externals() > 0 then
        hl.monitor({ output = EDP, disabled = true })
    end
    -- no external: leave eDP-1 alone — logind suspends on lid close anyway,
    -- and zero enabled monitors crashes this Hyprland version
end

-- Lid close with an external → clamshell; without one, logind suspends.
-- Lid open → panel back (and mirror off — you get the extended desktop).
-- locked: must fire under hyprlock, e.g. opening the lid after a resume.
hl.bind("switch:on:Lid Switch", clamshell, { locked = true, description = "Lid closed: clamshell if docked" })
hl.bind("switch:off:Lid Switch", edp_reset, { locked = true, description = "Lid opened: panel back on" })

-- External plugged in while the lid is closed (incl. waking a suspended
-- laptop into a dock) → clamshell
hl.on("monitor.added", function()
    if lid_closed() then clamshell() end
end)

-- Last external unplugged in clamshell → panel back on immediately, or the
-- session dies on the zero-monitor crash path. `not mirroring` matters:
-- the external entering mirror mode also fires monitor.removed with
-- externals() == 0, and that must not touch anything. (An external unplugged
-- WHILE mirroring keeps the flag; the toggle bind still exits cleanly.)
hl.on("monitor.removed", function()
    if externals() == 0 and not mirroring then
        edp_reset()
    end
end)

-- Booted or relogged with the lid already closed (docked): the edge event
-- never fired, so check once
hl.on("hyprland.start", function()
    if lid_closed() then clamshell() end
end)

-- Toggle mirroring the panel onto the first external
hl.bind("SUPER + ALT + SHIFT + M", function()
    if mirroring then
        mirror_off()
        return
    end
    -- no-op in clamshell: mirroring a disabled panel would leave the only
    -- visible output showing nothing
    local edp_on = false
    for _, m in ipairs(hl.get_monitors()) do
        if m.name == EDP then edp_on = true end
    end
    if not edp_on then return end
    for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= EDP then
            -- flag first: entering mirror fires monitor.removed for the
            -- external, and that handler must already see mirroring = true
            mirroring = true
            mirror_target = m.name
            hl.monitor({ output = m.name, mode = "preferred", position = "auto", scale = "auto", mirror = EDP })
            return
        end
    end
end, { description = "Mirror laptop screen to external" })

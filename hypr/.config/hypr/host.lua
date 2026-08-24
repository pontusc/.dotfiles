-- The single place the hostname is resolved. Per-host modules live in
-- monitors/<hostname>.lua and windowrules/<hostname>.lua; callers ask this
-- module to load theirs rather than reading /etc/hostname themselves.

local function hostname()
  local file = io.open("/etc/hostname", "r")
  if not file then
    return nil
  end

  local name = file:read("*l")
  file:close()
  if not name then
    return nil
  end

  name = name:match("^%s*(.-)%s*$")
  return name ~= "" and name or nil
end

local function notify(message)
  hl.notification.create({ text = message, timeout = 8000 })
end

-- Resolved once at load: the hostname cannot change mid-session.
local host = { name = hostname() }

-- Loads hypr.<namespace>.<hostname>. A load error always notifies. Whether a
-- MISSING module notifies is the caller's call: monitors has no baseline
-- layout fallback, so missing must be loud; windowrules is optional per host,
-- so missing must be silent.
function host.load(namespace, notify_if_missing)
  if not host.name then
    return
  end

  local module = "hypr." .. namespace .. "." .. host.name
  if package.searchpath(module, package.path) then
    local ok, err = pcall(require, module)
    if not ok then
      notify("hypr: " .. module .. " failed to load: " .. tostring(err))
    end
  elseif notify_if_missing then
    notify("hypr: no " .. namespace .. " module for host '" .. host.name .. "'")
  end
end

return host

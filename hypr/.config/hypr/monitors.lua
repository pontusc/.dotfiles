-- Per-host monitor and clamshell/lid handling lives in hosts/<hostname>.lua;
-- this file only resolves which one applies. Quattro's own template ships no
-- fallback monitor defaults, so the baseline below runs first — a host with
-- no module still gets a usable display — and host modules load after to
-- override it.

hl.env("GDK_SCALE", "2")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

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

local host = hostname()
if host then
  local module = "hypr.hosts." .. host
  if package.searchpath(module, package.path) then
    local ok, err = pcall(require, module)
    if not ok then
      notify("hypr: " .. module .. " failed to load: " .. tostring(err))
    end
  else
    notify("hypr: no monitor module for host '" .. host .. "'")
  end
end

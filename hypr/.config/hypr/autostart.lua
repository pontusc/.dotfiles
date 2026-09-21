-- Autostart processes for all hosts, then the per-host dispatch (silent when
-- the host has no module: extra autostarts are optional). Each launches only
-- where its binary is installed.
if o.cmd_present("discord") then
  o.launch_on_start("discord")
end

require("hypr.host").load("autostart", false)

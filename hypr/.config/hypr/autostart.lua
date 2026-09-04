-- Extra autostart processes. Each launches only where its binary is installed.
if o.cmd_present("netbird-ui") then
  o.launch_on_start("env WEBKIT_DISABLE_DMABUF_RENDERER=1 netbird-ui --daemon-addr unix:///var/run/netbird/main.sock")
end

if o.cmd_present("slack") then
  o.launch_on_start("slack --gtk-version=3 -s --startup")
end

if o.cmd_present("discord") then
  o.launch_on_start("discord")
end

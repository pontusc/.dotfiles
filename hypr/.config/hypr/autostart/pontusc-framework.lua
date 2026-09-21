-- Host-specific autostart for pontusc-framework: the work laptop, so the VPN
-- tray and Slack start here and nowhere else.
if o.cmd_present("netbird-ui") then
  o.launch_on_start("env WEBKIT_DISABLE_DMABUF_RENDERER=1 netbird-ui --daemon-addr unix:///var/run/netbird/main.sock")
end

if o.cmd_present("slack") then
  o.launch_on_start("slack --gtk-version=3 -s --startup")
end

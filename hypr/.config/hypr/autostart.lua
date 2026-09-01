-- Extra autostart processes.
o.launch_on_start("env WEBKIT_DISABLE_DMABUF_RENDERER=1 netbird-ui --daemon-addr unix:///var/run/netbird/main.sock")
o.launch_on_start("slack --gtk-version=3 -s --startup")

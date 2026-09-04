-- Per-host monitor and clamshell/lid handling lives in monitors/<hostname>.lua;
-- this file only resolves which one applies. Quattro's own template ships no
-- fallback monitor defaults, so the baseline below runs first — a host with
-- no module still gets a usable display — and host modules load after to
-- override it.

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

require("hypr.host").load("monitors", true)

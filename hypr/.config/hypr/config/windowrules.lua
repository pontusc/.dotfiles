-- Window rules. Deliberately sparse — app rules (Bitwarden float, YT-Music
-- workspace, PiP, ...) get added in Phase 4 as they earn it.
-- Old rules for reference: hypr-shared/ and hypr-desktop/constraints.conf.

-- Scroll nicely in terminals
hl.window_rule({ match = { class = "^(Alacritty|kitty)$" }, scroll_touchpad = 1.5 })

-- Layout and look. Near-default on purpose: dwindle, no gaps, no eye candy.
-- Theming is a Phase 4 concern.

hl.config({
    general = {
        layout           = "dwindle",
        gaps_in          = 0,
        gaps_out         = 1,
        resize_on_border = true,
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        middle_click_paste = false,
    },
    ecosystem = {
        no_update_news   = true,
        no_donation_nag  = true,
    },
})

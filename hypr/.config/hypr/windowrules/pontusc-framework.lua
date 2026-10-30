-- Host-specific window rules for pontusc-framework. Loaded after
-- windowrules.lua, so rules here override the general layer; the same
-- rule-order constraint from windowrules.lua applies.
--
-- Display context (see monitors/pontusc-framework.lua): Samsung Odyssey G95C
-- 5120x1440 ultrawide as the primary external, plus the eDP-1 2256x1504
-- internal panel. Host-specific sizing would key off those dimensions.

-- Tab Slack into the main browser's group. No-op when no Vivaldi window is grouped.
hl.on("window.open", function(window)
  if window.class ~= "slack" or window.floating or window.group then
    return
  end
  for _, other in ipairs(hl.get_windows()) do
    if other.class == "vivaldi-stable" and other.group then
      other.group:add(window)
      return
    end
  end
end)

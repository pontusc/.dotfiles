# Source this file, it is not meant to be executed directly.

declare -gA THEME_COLORS=(
  [background]="{{ background }}"

  [statusbar-bg]="{{ lighter_background }}"
  [statusbar-fg]="{{ foreground }}"

  [session-bg]="{{ cyan }}"
  [session-fg]="{{ background }}"
  [session-prefix-bg]="{{ yellow }}"
  [session-copy-bg]="{{ bright_cyan }}"
  [session-search-bg]="{{ green }}"
  [session-command-bg]="{{ magenta }}"

  [window-active-base]="{{ accent }}"
  [window-active-style]="bold"
  [window-inactive-base]="{{ selection }}"
  [window-inactive-style]="none"
  [window-activity-style]="italics"
  [window-bell-style]="bold"
  [window-zoomed-bg]="{{ bright_cyan }}"

  [pane-border-active]="{{ accent }}"
  [pane-border-inactive]="{{ selection }}"

  [ok-base]="{{ blue }}"
  [good-base]="{{ green }}"
  [info-base]="{{ cyan }}"
  [warning-base]="{{ yellow }}"
  [error-base]="{{ red }}"
  [disabled-base]="{{ muted }}"

  [message-bg]="{{ lighter_background }}"
  [message-fg]="{{ foreground }}"

  [popup-bg]="{{ lighter_background }}"
  [popup-fg]="{{ foreground }}"
  [popup-border]="{{ accent }}"

  [menu-bg]="{{ lighter_background }}"
  [menu-fg]="{{ foreground }}"
  [menu-selected-bg]="{{ accent }}"
  [menu-selected-fg]="{{ background }}"
  [menu-border]="{{ accent }}"
)

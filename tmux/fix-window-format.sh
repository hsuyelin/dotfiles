#!/usr/bin/env bash

# Rebuild window-status-format after catppuccin.tmux.
#
# catppuccin builds window-status-format with -gF, which expands
# @_ctp_status_bg at build time. With @catppuccin_status_background "none",
# @_ctp_status_bg = "none" -> tmux treats fg=none as black (color 0) ->
# rounded separator backgrounds appear black.
#
# Fix: rebuild the format using explicit fg=<tab_color>, bg=default for the
# separator characters (same approach the right-side status modules use).
# The separator character is rendered in the tab's color against a transparent
# background, so it correctly blends with the transparent status bar.

LSEP=$'\xee\x82\xb6'  # U+E0B6 – left soft divider (rounded left edge)
RSEP=$'\xee\x82\xb4'  # U+E0B4 – right soft divider (rounded right edge)

# These options hold #{@thm_*} format strings that are evaluated lazily at
# render time, so color changes in @catppuccin_flavor are automatically picked up.
NC=$(tmux show-option -gv @catppuccin_window_number_color)
TC=$(tmux show-option -gv @catppuccin_window_text_color)
CNC=$(tmux show-option -gv @catppuccin_window_current_number_color)
CTC=$(tmux show-option -gv @catppuccin_window_current_text_color)

# Inactive window
fmt="#[fg=${NC},bg=default]${LSEP}"
fmt+="#[fg=#{@thm_crust},bg=${NC}]#{E:@catppuccin_window_number} "
fmt+="#[fg=#{@thm_fg},bg=${TC}]#{E:@catppuccin_window_text}"
fmt+="#[fg=${TC},bg=default]${RSEP}"
tmux set -g window-status-format "$fmt"

# Active (current) window
cfmt="#[fg=${CNC},bg=default]${LSEP}"
cfmt+="#[fg=#{@thm_crust},bg=${CNC}]#{E:@catppuccin_window_number} "
cfmt+="#[fg=#{@thm_fg},bg=${CTC}]#{E:@catppuccin_window_current_text}"
cfmt+="#[fg=${CTC},bg=default]${RSEP}"
tmux set -g window-status-current-format "$cfmt"

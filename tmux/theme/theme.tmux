#!/usr/bin/env bash
# Tmux theme — Catppuccin Mocha, auto dark/light

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]]; then
  source "$CURRENT_DIR/colors/dark.sh"
else
  source "$CURRENT_DIR/colors/light.sh"
fi

get_tmux_option() {
  local option=$1
  tmux show-option -gqv "$option"
}

thm_bg=$(get_tmux_option "@thm_bg")
thm_bg_dark=$(get_tmux_option "@thm_bg_dark")
thm_bg_highlight=$(get_tmux_option "@thm_bg_highlight")
thm_fg=$(get_tmux_option "@thm_fg")
thm_fg_dark=$(get_tmux_option "@thm_fg_dark")
thm_fg_gutter=$(get_tmux_option "@thm_fg_gutter")
thm_cyan=$(get_tmux_option "@thm_cyan")
thm_black=$(get_tmux_option "@thm_black")
thm_black4=$(get_tmux_option "@thm_black4")
thm_magenta=$(get_tmux_option "@thm_magenta")
thm_pink=$(get_tmux_option "@thm_pink")
thm_red=$(get_tmux_option "@thm_red")
thm_green=$(get_tmux_option "@thm_green")
thm_yellow=$(get_tmux_option "@thm_yellow")
thm_blue=$(get_tmux_option "@thm_blue")
thm_blue6=$(get_tmux_option "@thm_blue6")
thm_blue7=$(get_tmux_option "@thm_blue7")
thm_orange=$(get_tmux_option "@thm_orange")
thm_purple=$(get_tmux_option "@thm_purple")
thm_teal=$(get_tmux_option "@thm_teal")

# ── Layout ────────────────────────────────────────────────────────────────────
tmux set -g status-position top
tmux set -g status-bg "default"
tmux set -g status-justify "left"
tmux set -g status-left-length 100
tmux set -g status-right-length 100

# ── Messages ──────────────────────────────────────────────────────────────────
tmux set -g message-style         "fg=${thm_cyan},bg=${thm_fg_gutter},align=centre"
tmux set -g message-command-style "fg=${thm_cyan},bg=${thm_fg_gutter},align=centre"

# ── Pane borders ──────────────────────────────────────────────────────────────
tmux set-window-option -g pane-active-border-style "fg=${thm_purple},bg=default"
tmux set-window-option -g pane-border-style        "fg=${thm_fg_gutter},bg=default"
tmux set-window-option -g pane-border-lines simple

# ── Window status ─────────────────────────────────────────────────────────────
tmux setw -g window-status-activity-style "fg=${thm_fg},none"
tmux setw -g window-status-separator " #[fg=${thm_fg_gutter}]│ "
tmux set  -g status-style "bg=default,fg=${thm_fg}"

# Powerline separators
tm_sep_l=""
tm_sep_r=""

# ── Status left: session name ─────────────────────────────────────────────────
tmux set -g status-left \
  "#[bg=${thm_purple},fg=${thm_bg},bold]  #S #[bg=default,fg=${thm_purple}]${tm_sep_l}#[bg=default,fg=default] "

# ── Status right: git branch · date/time ─────────────────────────────────────
# git branch via inline command (no external script needed)
tm_git="#(cd #{pane_current_path} && git rev-parse --abbrev-ref HEAD 2>/dev/null)"
tmux set -g status-right \
  "#[bg=default,fg=${thm_blue}]${tm_sep_r}#[bg=${thm_blue},fg=${thm_bg}]  ${tm_git} #[bg=default,fg=${thm_blue}]${tm_sep_l} #[bg=default,fg=${thm_fg_gutter}]${tm_sep_r}#[bg=${thm_fg_gutter},fg=${thm_fg}]  %H:%M #[bg=default,fg=${thm_fg_gutter}]${tm_sep_l}#[bg=default,fg=default]"

# ── Window formats ────────────────────────────────────────────────────────────
tmux setw -g window-status-format \
  "#[fg=${thm_black4}]#{?#{window_name},#W,#{b:pane_current_path}}"
tmux setw -g window-status-current-format \
  "#[fg=${thm_magenta},bold]#{?#{window_name},#W,#{b:pane_current_path}}"

# ── Clock ─────────────────────────────────────────────────────────────────────
tmux setw -g clock-mode-colour "${thm_blue}"

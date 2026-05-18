# -----------------------------
# tmux helpers
# -----------------------------

# tn [name...]: create session(s).
#   tn          create one session named after current dir, then switch/attach
#   tn foo      create session "foo", then switch/attach (attach if exists)
#   tn a b c    create all named sessions in background; skip any that already exist
tn() {
  if (( $# > 1 )); then
    local created=() skipped=()
    for name in "$@"; do
      if tmux has-session -t "=$name" 2>/dev/null; then
        skipped+=("$name")
      else
        tmux new-session -d -s "$name" -c "$PWD"
        created+=("$name")
      fi
    done
    tmux list-sessions
    return 0
  fi

  local name="${1:-$(basename "$PWD")}"
  if tmux has-session -t "=$name" 2>/dev/null; then
    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "$name"
    else
      tmux attach-session -t "$name"
    fi
    return
  fi
  if [[ -n "$TMUX" ]]; then
    tmux new-session -d -s "$name" -c "$PWD" \; switch-client -t "$name"
  else
    tmux new-session -s "$name" -c "$PWD"
  fi
}

# _ta_fzf: inline fzf at 40% height, renders below cursor in both contexts.
_ta_fzf() {
  fzf --height=40% "$@"
}

# ta: fzf picker — attach or switch to a session.
#   space      toggle selection + move down
#   ctrl-x     kill selected; if only current session selected, kill it directly;
#              if current mixed with others, skip current (show warning) and kill the rest
#   ctrl-r     rename focused session, reload list
#   enter      attach/switch to the last selected session in list order
ta() {
  if ! tmux list-sessions &>/dev/null; then
    echo "no tmux sessions. use: tn [name]"
    return 1
  fi
  local session
  session=$(
    tmux list-sessions -F "#{session_name}" \
      | _ta_fzf --multi --border --reverse \
            --prompt="session> " \
            --preview="tmux list-windows -t {} \
              -F '  #{window_index}  #{window_name}  #{?window_active,(active),}'" \
            --preview-window=right:45% \
            --bind="space:toggle+down" \
            --bind="ctrl-x:execute-silent(cur=\$(tmux display-message -p '#S' 2>/dev/null); set -- {+}; count=\$#; total=\$(tmux list-sessions 2>/dev/null | wc -l | xargs); if [ \"\$count\" -eq \"\$total\" ]; then for s in \"\$@\"; do [ -n \"\$s\" ] || continue; [ \"\$s\" = \"\$cur\" ] && continue; tmux kill-session -t \"\$s\"; done; tmux kill-session -t \"\$cur\"; elif [ \"\$count\" -eq 1 ] && [ \"\$1\" = \"\$cur\" ]; then tmux kill-session -t \"\$cur\"; else for s in \"\$@\"; do [ -n \"\$s\" ] || continue; if [ \"\$s\" = \"\$cur\" ]; then tmux display-message -d 3000 \"⚠  session '\$cur' is active, skipped\"; else tmux kill-session -t \"\$s\"; fi; done; fi)+reload(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)" \
            --bind="ctrl-r:execute(new=\$(echo | fzf --print-query --no-info --height=5 --border --prompt='rename: ' --query='{}' 2>/dev/null | head -1); [ -n \"\$new\" ] && tmux rename-session -t '{}' \"\$new\")+reload(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)+clear-screen" \
    | tail -1
  )
  [[ -z "$session" ]] && return 0
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$session"
  else
    tmux attach-session -t "$session"
  fi
}

# tk: detach from the current session.
tk() {
  if [[ -z "$TMUX" ]]; then
    echo "not in a tmux session."
    return 0
  fi
  tmux detach-client
}

# tq: quit and kill the current session immediately (use-and-discard).
tq() {
  if [[ -z "$TMUX" ]]; then
    echo "not in a tmux session."
    return 0
  fi
  tmux kill-session
}

# Option+R: session picker via ta().
_tmux_session_picker_widget() {
    if [[ -n "$TMUX" ]]; then
        zle -I
        ta
        zle reset-prompt
    else
        zle push-line
        BUFFER="ta"
        zle accept-line
    fi
}
zle -N _tmux_session_picker_widget
bindkey '\er' _tmux_session_picker_widget

# tl: list sessions at a glance.
alias tl='tmux list-sessions 2>/dev/null || echo "no tmux sessions."'

# thelp: print all tmux helper aliases and their usage.
thelp() {
    local bold='\033[1m'
    local cyan='\033[0;36m'
    local yellow='\033[0;33m'
    local reset='\033[0m'

    echo ""
    printf "${bold}Tmux Helpers Cheatsheet${reset}\n"
    echo "────────────────────────────────────────────────────"

    _thelp_section() { printf "\n${yellow}  %-12s${reset}\n" "$1"; }
    _thelp_row()     { printf "  ${cyan}%-12s${reset}  %s\n" "$1" "$2"; }

    _thelp_section "Sessions"
    _thelp_row "tn"     "create session named after cwd, then switch/attach"
    _thelp_row "tn foo" "create session 'foo', then switch/attach (attach if exists)"
    _thelp_row "tn a b" "create multiple sessions in background, skip existing"
    _thelp_row "ta"     "fzf picker — switch / attach to a session"
    _thelp_row "tl"     "list all sessions"
    _thelp_row "tk"     "detach from current session (keep it running)"
    _thelp_row "tq"     "kill current session immediately"

    _thelp_section "ta  (fzf picker keys)"
    _thelp_row "enter"  "switch to focused session"
    _thelp_row "space"  "toggle selection + move down"
    _thelp_row "ctrl-x" "kill selected; if only current session → kill directly;"
    _thelp_row ""       "if current mixed with others → skip current + warn"
    _thelp_row "ctrl-r" "rename focused session"

    _thelp_section "Option+R"
    _thelp_row ""       "same as ta — forwards M-r to pane zsh widget"

    echo ""
    echo "────────────────────────────────────────────────────"
    echo ""

    unfunction _thelp_section _thelp_row
}

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
        zle clear-screen        # clear screen + redraw prompt at top
        zle push-line           # save any typed buffer; restored after ta exits
        # shellcheck disable=SC2034
        BUFFER="ta"
        zle accept-line         # hand ta back to shell so tmux can own the tty
    fi
}
zle -N _tmux_session_picker_widget
bindkey '\er' _tmux_session_picker_widget

# tl: list sessions at a glance.
alias tl='tmux list-sessions 2>/dev/null || echo "no tmux sessions."'

# thelp: print all tmux shortcuts and helper aliases.
thelp() {
    local bold='\033[1m'
    local cyan='\033[0;36m'
    local yellow='\033[0;33m'
    local dim='\033[2m'
    local reset='\033[0m'
    local sep='────────────────────────────'

    _thelp_section() { printf '\n%s  %-16s%s\n' "$yellow" "$1" "$reset"; }
    _thelp_row()     { printf '  %s%-16s%s  %s\n' "$cyan" "$1" "$reset" "$2"; }
    # shellcheck disable=SC2329
    _thelp_note()    { printf '  %s%-16s  %s%s\n' "$dim" "" "$1" "$reset"; }

    echo ""
    printf '%sTmux Cheatsheet%s  ' "$bold" "$reset"
    printf '%sprefix = Ctrl+a%s\n' "$dim" "$reset"
    echo "$sep"

    _thelp_section "Panes"
    _thelp_row "prefix + |"    "split right (vertical divider)"
    _thelp_row "prefix + -"    "split down (horizontal divider)"
    _thelp_row "prefix + q"    "close current pane (no confirm)"
    _thelp_row "Ctrl + h/j/k/l" "navigate left/down/up/right"
    _thelp_row "prefix + H/J/K/L" "resize pane"
    _thelp_row "prefix + ="    "tile all panes evenly"
    _thelp_row "prefix + P"    "rename current pane"

    _thelp_section "Windows (tabs)"
    _thelp_row "prefix + c"    "new window"
    _thelp_row "prefix + Q"    "close window (no confirm)"
    _thelp_row "prefix + 1-9"  "jump to window by number"
    _thelp_row "prefix + n"    "next window"
    _thelp_row "prefix + p"    "previous window"
    _thelp_row "prefix + T"    "toggle status bar"

    _thelp_section "Sessions"
    _thelp_row "prefix + s"    "session tree (built-in chooser)"
    _thelp_row "Option + R"    "fzf session picker (= ta)"
    _thelp_row "tn"            "new session (named after cwd)"
    _thelp_row "tn <name>"     "new session with name"
    _thelp_row "ta"            "fzf picker — switch / attach"
    _thelp_row "tl"            "list all sessions"
    _thelp_row "tk"            "detach (keep session running)"
    _thelp_row "tq"            "kill current session"

    _thelp_section "ta (fzf keys)"
    _thelp_row "enter"         "switch to focused session"
    _thelp_row "space"         "toggle select + move down"
    _thelp_row "ctrl-x"        "kill selected session(s)"
    _thelp_row "ctrl-r"        "rename focused session"

    _thelp_section "Copy mode"
    _thelp_row "prefix + Esc"  "enter copy mode"
    _thelp_row "v"             "begin selection"
    _thelp_row "V"             "select line"
    _thelp_row "Ctrl + v"      "rectangle selection"
    _thelp_row "y"             "copy to system clipboard"
    _thelp_row "drag / dblclick" "mouse select → auto copy"
    _thelp_row "prefix + p"    "paste"

    _thelp_section "Misc"
    _thelp_row "prefix + g"    "lazygit popup"
    _thelp_row "prefix + r"    "reload tmux config"
    _thelp_row "Shift + Enter" "insert newline (no submit)"

    echo ""
    echo "$sep"
    echo ""

    unfunction _thelp_section _thelp_row _thelp_note
}

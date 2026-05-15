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

# ta: fzf picker — attach or switch to a session.
#   space      toggle selection + move down
#   d          kill all selected sessions (no selection = kill focused), reload list
#   r          rename focused session, reload list
#   enter      attach/switch to the last selected session in list order
ta() {
  if ! tmux list-sessions &>/dev/null; then
    echo "no tmux sessions. use: tn [name]"
    return 1
  fi
  local session
  session=$(
    tmux list-sessions -F "#{session_name}" \
      | fzf --multi --height=40% --border --reverse \
            --prompt="session> " \
            --preview="tmux list-windows -t {} \
              -F '  #{window_index}  #{window_name}  #{?window_active,(active),}'" \
            --preview-window=right:45% \
            --bind="space:toggle+down" \
            --bind="d:execute-silent(for s in {+}; do tmux kill-session -t \$s; done)+reload(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)" \
            --bind="r:execute(printf 'rename \"{}\"\nnew name: '; read -r n; [ -n \"\$n\" ] && tmux rename-session -t '{}' \"\$n\")+reload(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)" \
    | tail -1
  )
  [[ -z "$session" ]] && return 0
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$session"
  else
    tmux attach-session -t "$session"
  fi
}

# Alt+R: pop up ta with a clean screen, restore prompt on exit.
_ta_widget() {
  clear
  ta
  zle reset-prompt
}
zle -N _ta_widget
bindkey '\er' _ta_widget

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

# tl: list sessions at a glance.
alias tl='tmux list-sessions 2>/dev/null || echo "no tmux sessions."'

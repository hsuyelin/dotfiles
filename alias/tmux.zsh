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
#   ctrl-a     select all sessions
#   ctrl-x     kill selected; if only current session selected, kill it directly;
#              if current mixed with others, skip current (show warning) and kill the rest
#   ctrl-r     rename focused session, reload list
#   ctrl-s     save selected sessions to resurrect file (no selection = no-op)
#   ctrl-d     drop selected sessions from resurrect file (no selection = no-op)
#   enter      attach/switch to the last selected session in list order
ta() {
  local _rta="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/resurrect-ta.sh"
  local _rdir="$HOME/.local/share/tmux/resurrect"

  # Auto-restore when no server is running and a resurrect save exists.
  # Starts the server, fakes $TMUX so restore.sh can locate the socket,
  # then runs a full restore (sessions + windows + panes). Errors from
  # display-message / switch-client are suppressed — they need a client.
  if ! tmux list-sessions &>/dev/null 2>&1 && \
     [[ -L "${_rdir}/last" && -f "${_rdir}/last" ]]; then
    local _sock="/tmp/tmux-$(id -u)/default"
    local _rsc="${HOME}/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh"
    tmux start-server 2>/dev/null
    TMUX="${_sock},0,0" bash "$_rsc" 2>/dev/null
  fi

  if ! tmux list-sessions &>/dev/null; then
    echo "no tmux sessions. use: tn [name]"
    return 1
  fi
  local session
  session=$(
    tmux list-sessions -F "#{session_name}" \
      | _ta_fzf --multi --border --reverse \
            --prompt="session> " \
            --preview="f=\"${_rdir}/last\"; \
              if [ -f \"\$f\" ]; then \
                rf=\$(realpath \"\$f\"); \
                awk -F'\t' -v s={} '\$2==s{x=1}END{exit !x}' \"\$rf\" 2>/dev/null \
                  && echo '  [saved]' || echo '  [not saved]'; \
              else \
                echo '  [no save file]'; \
              fi; \
              echo; \
              tmux list-windows -t {} \
                -F '  #{window_index}  #{window_name}  #{?window_active,(active),}' 2>/dev/null" \
            --preview-window=right:45% \
            --bind="space:toggle+down" \
            --bind="ctrl-a:select-all+refresh-preview" \
            --bind="ctrl-x:execute-silent(cur=\$(tmux display-message -p '#S' 2>/dev/null); set -- {+}; count=\$#; total=\$(tmux list-sessions 2>/dev/null | wc -l | xargs); if [ \"\$count\" -eq \"\$total\" ]; then for s in \"\$@\"; do [ -n \"\$s\" ] || continue; [ \"\$s\" = \"\$cur\" ] && continue; tmux kill-session -t \"\$s\"; done; tmux kill-session -t \"\$cur\"; elif [ \"\$count\" -eq 1 ] && [ \"\$1\" = \"\$cur\" ]; then tmux kill-session -t \"\$cur\"; else for s in \"\$@\"; do [ -n \"\$s\" ] || continue; if [ \"\$s\" = \"\$cur\" ]; then tmux display-message -d 3000 \"⚠  session '\$cur' is active, skipped\"; else tmux kill-session -t \"\$s\"; fi; done; fi)+reload(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)" \
            --bind="ctrl-r:execute(new=\$(echo | fzf --print-query --no-info --height=5 --border --prompt='rename: ' --query='{}' 2>/dev/null | head -1); [ -n \"\$new\" ] && tmux rename-session -t '{}' \"\$new\")+reload(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)+clear-screen" \
            --bind="ctrl-s:execute-silent(set -- {+}; _f={}; if [ \$# -gt 1 ] || [ \"\$1\" != \"\$_f\" ]; then \"${_rta}\" save-merge \"\$@\"; fi)+deselect-all+refresh-preview" \
            --bind="ctrl-d:execute-silent(set -- {+}; _f={}; if [ \$# -gt 1 ] || [ \"\$1\" != \"\$_f\" ]; then \"${_rta}\" drop \"\$@\"; fi)+deselect-all+refresh-preview" \
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
        zle push-line           # save any typed buffer; restored after ta exits
        # shellcheck disable=SC2034
        BUFFER="ta"
        zle accept-line         # hand ta back to shell so tmux can own the tty
    fi
}
zle -N _tmux_session_picker_widget
bindkey '\er' _tmux_session_picker_widget

# trl: reload tmux config from the shell (works inside or outside tmux).
alias trl='tmux source "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf" && echo "tmux config reloaded"'

# tl: list sessions at a glance.
alias tl='tmux list-sessions 2>/dev/null || echo "no tmux sessions."'

# ── Session persistence hints (tmux-resurrect) ────────────────────────────────
# Use tmux key bindings or ta() fzf picker instead of these shell commands.

# tps: hint — save via prefix + Ctrl-s, or ctrl-s in ta() fzf picker.
alias tps='echo "save sessions: prefix + Ctrl-s  (or ctrl-s in ta fzf picker)"'

# tpr: hint — restore via prefix + Ctrl-r.
alias tpr='echo "restore sessions: prefix + Ctrl-r"'

# tpd: hint — drop a session via ctrl-d in ta() fzf picker.
alias tpd='echo "drop session from save: ctrl-d in ta fzf picker"'

# thelp: Tmux keymap reference.
# Usage: thelp [list | show [--module <id>] [--lang zh]] [--help]
thelp() {
    local _i18n="${XDG_CONFIG_HOME}/alias/i18n/tmux.json"
    case "$1" in
        list)      shift; _help_list "$_i18n" "$@" ;;
        --help|-h) _help_usage "thelp" ;;
        show)      shift; _help_show "$_i18n" "$@" ;;
        *)         _help_show "$_i18n" "$@" ;;
    esac
}

if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh --cmd z)"

  # 'zi' conflicts with the zi plugin manager; rename to 'zf'.
  functions[zf]=$functions[zi]
  unfunction zi

  # Override zoxide's built-in completion so fzf-tab sees history entries.
  _z_fzf_completion() {
    local -a results
    local query="${(j: :)words[2,-1]}"
    if [[ -n "$query" ]]; then
      results=("${(@f)$(zoxide query --list -- ${=query} 2>/dev/null)}")
    else
      results=("${(@f)$(zoxide query --list 2>/dev/null)}")
    fi
    if (( ${#results[@]} )); then
      compadd -U -a results
    else
      _cd -/
    fi
  }
  compdef _z_fzf_completion z

  # Restore buffer to "z" (no autosuggestion) when fzf is dismissed with Esc.
  typeset -gi _z_cancelled=0

  _z_clear_suggestion_once() {
    if (( _z_cancelled )); then
      _z_cancelled=0
      POSTDISPLAY=""
    fi
  }
  autoload -Uz add-zle-hook-widget
  add-zle-hook-widget line-pre-redraw _z_clear_suggestion_once

  # Capture the original Tab binding exactly once.
  # Guard: if Tab is already bound to _z_tab_complete (re-source case), keep
  # the previously captured value so we don't create a self-referential cycle.
  local _z_cur_tab="${$(bindkey '\t')##* }"
  [[ "$_z_cur_tab" != "_z_tab_complete" ]] && typeset -g _z_orig_tab="$_z_cur_tab"
  unset _z_cur_tab

  # shellcheck disable=SC1009,SC1073,SC1056,SC1072,SC1141
  _z_tab_complete() {
    if [[ "$BUFFER" != 'z' && "$BUFFER" != 'z '* ]]; then
      zle "$_z_orig_tab"
      return
    fi

    local query="${${BUFFER#z}## }"

    # Use temp files instead of $(...|fzf) pipelines.
    # Pipelines inside ZLE widgets create background jobs that fill the ZLE
    # job table, causing "job table full" errors.  Redirected external commands
    # are foreground execs and do not consume job table slots.
    local tmpbase="${TMPDIR:-/tmp}/.z_cmp_${$}_${RANDOM}"

    {
      zoxide query --list > "${tmpbase}_all" 2>/dev/null
      [[ -s "${tmpbase}_all" ]] || return

      # OR-filter by typed keywords — pure zsh, no subshells.
      if [[ -n "$query" ]]; then
        local -a kws=( ${(z)query} )
        local entry kw
        while IFS= read -r entry; do
          local low="${entry:l}"
          for kw in "${kws[@]}"; do
            if [[ "$low" == *"${kw:l}"* ]]; then
              print -r -- "$entry"
              break
            fi
          done
        done < "${tmpbase}_all" > "${tmpbase}_cands"
      else
        mv "${tmpbase}_all" "${tmpbase}_cands"
      fi

      [[ -s "${tmpbase}_cands" ]] || return

      # fzf reads from file and writes selection to file — no pipe, no subshell.
      # fzf detects stdout is not a tty and draws its UI directly on /dev/tty.
      fzf \
        --height=40% --layout=reverse --border --info=inline \
        --query="$query" \
        --bind='tab:down,btab:up,ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
        --preview='command -v eza >/dev/null && eza -1 --color=always --group-directories-first -- {} 2>/dev/null || ls -1 -- {}' \
        --preview-window=right:40% \
        < "${tmpbase}_cands" > "${tmpbase}_sel" 2>/dev/null

      if [[ -s "${tmpbase}_sel" ]]; then
        local selected=$(<"${tmpbase}_sel")
        BUFFER="z ${selected}"
        CURSOR=${#BUFFER}
      else
        BUFFER='z'
        CURSOR=1
        _z_cancelled=1
      fi
      zle reset-prompt
    } always {
      rm -f "${tmpbase}_all" "${tmpbase}_cands" "${tmpbase}_sel"
    }
  }

  zle -N _z_tab_complete
  bindkey '\t' _z_tab_complete
fi

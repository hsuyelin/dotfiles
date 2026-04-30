if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh --cmd z)"

  # 'zi' (zoxide interactive mode) conflicts with the zi plugin manager; rename to 'zf'
  functions[zf]=$functions[zi]
  unfunction zi

  # Override zoxide's built-in completion: the default only does _cd -/ (local dirs).
  # This version queries the zoxide database so fzf-tab can show matching history.
  _z_fzf_completion() {
    local -a results
    local query="${(j: :)words[2,-1]}"
    if [[ -n "$query" ]]; then
      results=("${(@f)$(zoxide query --list -- ${=query} 2>/dev/null)}")
    else
      results=("${(@f)$(zoxide query --list 2>/dev/null)}")
    fi
    if (( ${#results[@]} )); then
      # -U: skip zsh's own prefix filtering (results are full paths, not prefixed by query)
      compadd -U -a results
    else
      _cd -/
    fi
  }
  compdef _z_fzf_completion z

  # When fzf is dismissed (Esc), restore buffer to "z" with no autosuggestion.
  # Problem: autosuggestions writes its hint into POSTDISPLAY via a line-pre-redraw
  # hook. Since we load AFTER autosuggestions, our hook is appended later in the
  # FIFO queue and therefore runs after autosuggestions' hook — letting us clear
  # POSTDISPLAY once without disabling autosuggestions for subsequent keystrokes.
  typeset -g  _z_orig_tab="${$(bindkey '\t')##* }"
  typeset -gi _z_cancelled=0

  _z_clear_suggestion_once() {
    if (( _z_cancelled )); then
      _z_cancelled=0
      POSTDISPLAY=""
    fi
  }
  autoload -Uz add-zle-hook-widget
  add-zle-hook-widget line-pre-redraw _z_clear_suggestion_once

  _z_tab_complete() {
    if [[ "$BUFFER" == 'z' || "$BUFFER" == 'z '* ]]; then
      local query="${BUFFER#z}"
      query="${query## }"

      # Load all zoxide entries, then OR-filter by keywords (case-insensitive).
      # fzf's --query uses AND logic so "work github" only matches paths that
      # contain both words; pre-filtering with OR gives the expected behaviour.
      local _z_raw
      _z_raw=$(zoxide query --list 2>/dev/null)

      if [[ -n "$_z_raw" ]]; then
        local -a all_entries candidates
        all_entries=("${(@f)_z_raw}")

        if [[ -n "$query" ]]; then
          local -a kws
          kws=(${(z)query})          # split on whitespace
          local entry kw
          for entry in "${all_entries[@]}"; do
            local low="${entry:l}"   # lowercase for case-insensitive compare
            for kw in "${kws[@]}"; do
              if [[ "$low" == *"${kw:l}"* ]]; then
                candidates+=("$entry")
                break
              fi
            done
          done
        else
          candidates=("${all_entries[@]}")
        fi

        local selected
        selected=$(printf '%s\n' "${candidates[@]}" | fzf \
          --height=40% --layout=reverse --border --info=inline \
          --bind='tab:down,btab:up,ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
          --preview='command -v eza >/dev/null && eza -1 --color=always --group-directories-first -- {} 2>/dev/null || ls -1 -- {}' \
          --preview-window=right:40% \
          2>/dev/null)
        if [[ -n "$selected" ]]; then
          BUFFER="z $selected"
          CURSOR=${#BUFFER}
        else
          # fzf opened but user pressed Esc — restore to bare "z"
          BUFFER='z'
          CURSOR=1
          _z_cancelled=1
        fi
        zle reset-prompt
      fi
      # Empty zoxide database: leave buffer untouched
    else
      zle "$_z_orig_tab"
    fi
  }
  zle -N _z_tab_complete
  bindkey '\t' _z_tab_complete
fi

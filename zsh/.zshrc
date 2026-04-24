# ============================================================
# Terminal detection
# ============================================================
# Ghostty inside tmux does not always keep TERM_PROGRAM=ghostty,
# so fall back to the active tmux client terminal name.
_is_ghostty_session() {
  [[ "${TERM_PROGRAM:-}" == "ghostty" ]] && return 0
  [[ "${TERM:-}" == "xterm-ghostty" ]] && return 0

  if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
    local client_termname
    client_termname="$(tmux display-message -p '#{client_termname}' 2>/dev/null)"
    [[ "$client_termname" == *ghostty* ]] && return 0
  fi

  return 1
}

# ============================================================
# Powerlevel10k Instant Prompt
# ============================================================
# Must stay near the top of ~/.zshrc. Any code that may require console input
# (password prompts, [y/n] confirmations, etc.) must go above this block.
# Skipped in Ghostty — starship is used there instead (see bottom of file).
if ! _is_ghostty_session && [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================
# ZI Initialization
# ============================================================
setopt AUTO_CD

typeset -A ZI
ZI[HOME_DIR]="${XDG_CONFIG_HOME}/zi"
ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"


export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
export HISTSIZE=20000
export SAVEHIST=20000
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

if [[ ! -f "${ZI[BIN_DIR]}/zi.zsh" ]]; then
  print -P "%F{33}▓▒░ %F{160}Installing (%F{33}z-shell/zi%F{160})…%f"
  command mkdir -p "${ZI[HOME_DIR]}" && command chmod go-rwX "${ZI[HOME_DIR]}"
  command git clone -q --depth=1 --branch "main" https://github.com/z-shell/zi "${ZI[BIN_DIR]}" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi
source "${ZI[BIN_DIR]}/zi.zsh"

autoload -Uz _zi
(( ${+_comps} )) && _comps[zi]=_zi

zstyle ':completion:*' menu no
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
zstyle ':completion:*:*:cp:*' file-sort size
zstyle ':completion:*' file-sort modification

# ============================================================
# FZF Core
# ============================================================
export FZF_ALT_C_OPTS=$'
--walker=dir,follow,hidden
--walker-skip=.git,node_modules,target
--height=40%
--layout=reverse
--border
--info=inline
--preview "
  if command -v eza >/dev/null; then
    eza -T --level=2 --color=always --group-directories-first --icons -- {}
  else
    tree -C -L 2 {}
  fi
"
--preview-window=right:60%
'

ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
  fzf-history-widget
  fzf-file-widget
  fzf-cd-widget
  accept-line
)

# ============================================================
# ZI Theme
# ============================================================
# In Ghostty: skip p10k, use starship (initialized at bottom of file)
! _is_ghostty_session && zi light "romkatv/powerlevel10k"

# ============================================================
# ZI Initiative Plugins
# ============================================================
zi ice wait lucid
zi light "zdharma-continuum/fast-syntax-highlighting"

zi ice lucid atload'_zsh_autosuggest_start'
zi light "zsh-users/zsh-autosuggestions"

bindkey '^H' backward-delete-char
bindkey '^?' backward-delete-char

zi ice lucid
zi light "zsh-users/zsh-completions"

# ============================================================
# ZI Passive Plugins
# ============================================================
zi light "z-shell/zsh-eza"

# ============================================================
# ZI Snippets
# ============================================================
zi snippet OMZP::git
zi snippet OMZL::completion.zsh
zi snippet OMZL::key-bindings.zsh

# Override OMZ's prefix-filtered search with plain history cycling.
# Bind all variants: VT100 (^[[A), ANSI app mode (^[OA), and terminfo-based.
# This must come after zi snippet OMZL::key-bindings.zsh to win the race.
autoload -Uz up-line-or-history down-line-or-history
for _km in emacs viins vicmd; do
  bindkey -M $_km '^[[A' up-line-or-history
  bindkey -M $_km '^[OA' up-line-or-history
  bindkey -M $_km '^[[B' down-line-or-history
  bindkey -M $_km '^[OB' down-line-or-history
  [[ -n "${terminfo[kcuu1]}" ]] && bindkey -M $_km "${terminfo[kcuu1]}" up-line-or-history
  [[ -n "${terminfo[kcud1]}" ]] && bindkey -M $_km "${terminfo[kcud1]}" down-line-or-history
done
unset _km

# ============================================================
# Environment Setup
# ============================================================

# bash profile compatibility (if you keep bash config in XDG)
[[ -f "${XDG_CONFIG_HOME}/bash/.bash_profile" ]] && source "${XDG_CONFIG_HOME}/bash/.bash_profile"

# Aliases (XDG)
[[ -f "${XDG_CONFIG_HOME}/alias/.aliases" ]] && source "${XDG_CONFIG_HOME}/alias/.aliases"

# AI env (XDG)
[[ -f "${XDG_CONFIG_HOME}/bash/.ai" ]] && source "${XDG_CONFIG_HOME}/bash/.ai"

# Powerlevel10k config (XDG) — skipped in Ghostty
! _is_ghostty_session && [[ -f "${XDG_CONFIG_HOME}/zsh/.p10k.zsh" ]] && source "${XDG_CONFIG_HOME}/zsh/.p10k.zsh"

# ============================================================
# Antigravity / RVM
# ============================================================

# Added by Antigravity
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && path+=("$HOME/.antigravity/antigravity/bin")

# RVM (keep this near the end of the file; last PATH mutation)
[[ -d "$HOME/.rvm/bin" ]] && path+=("$HOME/.rvm/bin")

# ============================================================
# Bin modules
# ============================================================

# Secrets (XDG)
[[ -f "${XDG_CONFIG_HOME}/secrets/.env.secrets" ]] && source "${XDG_CONFIG_HOME}/secrets/.env.secrets"

# Cargo env (rustup/cargo may drop an env helper here)
[[ -s "${CARGO_HOME}/env" ]] && source "${CARGO_HOME}/env"

# ============================================================
# Completions Init (must run before fzf-tab and zoxide so compdef works)
# ============================================================
autoload -Uz compinit && compinit -C

# ============================================================
# Fzf Setup
# ============================================================
[[ -f "${XDG_CONFIG_HOME}/fzf/fzf.zsh" ]] && source "${XDG_CONFIG_HOME}/fzf/fzf.zsh"

zi ice lucid
zi light "Aloxaf/fzf-tab"

zstyle ':fzf-tab:complete:cd:*' fzf-preview '
  [[ -n "$realpath" && -e "$realpath" ]] && (command -v eza >/dev/null && eza -1 --color=always --group-directories-first -- "$realpath" || ls -1 -- "$realpath")
'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview '
  git log --oneline --graph --decorate --color=always -- "$word" 2>/dev/null | head -80
'
zstyle ':fzf-tab:complete:kill:*' fzf-preview '
  pid="${word##*:}"
  ps -p "$pid" -o pid,%cpu,%mem,comm -c 2>/dev/null
'
zstyle ':fzf-tab:complete:z:*' fzf-preview '
  [[ -n "$realpath" && -d "$realpath" ]] && (command -v eza >/dev/null && eza -1 --color=always --group-directories-first -- "$realpath" || ls -1 -- "$realpath")
'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':fzf-tab:*' fzf-flags '--bind=ctrl-d:preview-page-down,ctrl-u:preview-page-up,tab:down,btab:up'

# ============================================================
# Zoxide (replaces agkozak/zsh-z)
# ============================================================
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh --cmd z)"
  # 'zi' (zoxide interactive mode) conflicts with the zi plugin manager
  # rename it to 'zf' (z + fzf)
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
      # Extract all keywords after "z" as the query (multi-keyword support)
      local query="${BUFFER#z}"
      query="${query## }"

      # Load all zoxide entries, then OR-filter by keywords (case-insensitive).
      # fzf's --query uses AND logic so "zepp github" only matches paths that
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

# ============================================================
# Ghostty: starship prompt (replaces p10k when in Ghostty)
# config: ~/.config/starship/starship.toml
# ============================================================
if _is_ghostty_session; then
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"
  eval "$(starship init zsh)"
fi

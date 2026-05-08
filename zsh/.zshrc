# ============================================================
# ZI Initialization
# ============================================================
setopt AUTO_CD

typeset -A ZI
ZI[HOME_DIR]="${XDG_CONFIG_HOME}/zi"
ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"

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
# ZI Plugins
# ============================================================
zi ice wait lucid
zi light "zdharma-continuum/fast-syntax-highlighting"

zi ice lucid atload'_zsh_autosuggest_start'
zi light "zsh-users/zsh-autosuggestions"

bindkey '^H' backward-delete-char
bindkey '^?' backward-delete-char

zi ice lucid
zi light "zsh-users/zsh-completions"

zi light "z-shell/zsh-eza"

# Override OMZ's prefix-filtered search with plain history cycling.
# Bind all variants: VT100 (^[[A), ANSI app mode (^[OA), and terminfo-based.
# This must come after zi snippet OMZL::key-bindings.zsh to win the race.
autoload -Uz up-line-or-history down-line-or-history

# Tracks whether we have entered history navigation (guards ↓ from clearing on fresh line).
typeset -g _hist_nav_active=0

# ↑: accept autosuggestion if visible; otherwise go up in history.
#    At the oldest entry, clear the buffer and reset position so next ↑ restarts from newest.
_up-or-autosuggest-accept() {
  if [[ -n "$POSTDISPLAY" ]]; then
    zle autosuggest-accept
    _hist_nav_active=0
    return
  fi
  local before=$HISTNO
  zle up-line-or-history
  if [[ $HISTNO -eq $before ]]; then
    zle kill-whole-line
    HISTNO=$HISTCMD
    _hist_nav_active=0
  else
    _hist_nav_active=1
  fi
}
zle -N _up-or-autosuggest-accept

# ↓: go down in history.
#    At the newest entry (only after having navigated up), clear the buffer and reset position.
_down-or-clear() {
  local before=$HISTNO
  zle down-line-or-history
  if [[ $HISTNO -eq $before ]]; then
    if (( _hist_nav_active )); then
      zle kill-whole-line
      HISTNO=$HISTCMD
    fi
    _hist_nav_active=0
  else
    _hist_nav_active=1
  fi
}
zle -N _down-or-clear

for _km in emacs viins vicmd; do
  bindkey -M $_km '^[[A' _up-or-autosuggest-accept
  bindkey -M $_km '^[OA' _up-or-autosuggest-accept
  bindkey -M $_km '^[[B' _down-or-clear
  bindkey -M $_km '^[OB' _down-or-clear
  [[ -n "${terminfo[kcuu1]}" ]] && bindkey -M $_km "${terminfo[kcuu1]}" _up-or-autosuggest-accept
  [[ -n "${terminfo[kcud1]}" ]] && bindkey -M $_km "${terminfo[kcud1]}" _down-or-clear
done
unset _km

# ============================================================
# Environment Setup
# ============================================================
[[ -f "${XDG_CONFIG_HOME}/bash/.bash_profile" ]] && source "${XDG_CONFIG_HOME}/bash/.bash_profile"
[[ -f "${XDG_CONFIG_HOME}/alias/aliases.zsh" ]] && source "${XDG_CONFIG_HOME}/alias/aliases.zsh"
[[ -f "${XDG_CONFIG_HOME}/alias/git.zsh" ]] && source "${XDG_CONFIG_HOME}/alias/git.zsh"
[[ -f "${XDG_CONFIG_HOME}/private/xcode.zsh" ]] && source "${XDG_CONFIG_HOME}/private/xcode.zsh"
[[ -f "${XDG_CONFIG_HOME}/bash/ai.zsh" ]] && source "${XDG_CONFIG_HOME}/bash/ai.zsh"

# ============================================================
# Antigravity / RVM
# ============================================================
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && path+=("$HOME/.antigravity/antigravity/bin")
[[ -d "$HOME/.rvm/bin" ]] && path+=("$HOME/.rvm/bin")

# ============================================================
# Secrets / Cargo
# ============================================================
[[ -f "${XDG_CONFIG_HOME}/secrets/.env.secrets" ]] && source "${XDG_CONFIG_HOME}/secrets/.env.secrets"
[[ -s "${CARGO_HOME}/env" ]] && source "${CARGO_HOME}/env"

# ============================================================
# Completions (must run before fzf-tab and zoxide)
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
# Zoxide
# ============================================================
[[ -f "${XDG_CONFIG_HOME}/zsh/zoxide-completion.zsh" ]] && source "${XDG_CONFIG_HOME}/zsh/zoxide-completion.zsh"

# ============================================================
# Terminal Integration
# ============================================================
[[ -f "${XDG_CONFIG_HOME}/ghostty/ghostty.zsh" ]] \
    && source "${XDG_CONFIG_HOME}/ghostty/ghostty.zsh"
[[ -n "$KITTY_WINDOW_ID" && -f "${XDG_CONFIG_HOME}/kitty/kitty.zsh" ]] \
    && source "${XDG_CONFIG_HOME}/kitty/kitty.zsh"

# ============================================================
# RTK (Rust Token Killer)
# ============================================================
[[ -f "${XDG_CONFIG_HOME}/rtk/rtk.zsh" ]] && source "${XDG_CONFIG_HOME}/rtk/rtk.zsh"

# ============================================================
# Starship Prompt
# ============================================================
export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"
eval "$(starship init zsh)"

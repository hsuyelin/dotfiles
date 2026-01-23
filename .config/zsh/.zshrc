# ============================================================
# Powerlevel10k Instant Prompt
# ============================================================
# Must stay near the top of ~/.zshrc. Any code that may require console input
# (password prompts, [y/n] confirmations, etc.) must go above this block.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================
# ZI Initialization
# ============================================================
setopt AUTO_CD

typeset -A ZI
ZI[HOME_DIR]="${XDG_CONFIG_HOME}/zi"
ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"

# ============================================================
# z (agkozak/zsh-z) State (XDG)
# ============================================================
export _Z_DATA="$XDG_STATE_HOME/z/z"

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

setopt NO_AUTO_MENU
zstyle ':completion:*' menu select
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
)

# ============================================================
# ZI Theme
# ============================================================
zi light "romkatv/powerlevel10k"

# ============================================================
# ZI Initiative Plugins
# ============================================================
zi ice wait lucid atinit='zpcompinit'
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
zi light "agkozak/zsh-z"
zi light "z-shell/zsh-eza"
zi light "DarrinTisdale/zsh-aliases-exa"

# ============================================================
# ZI Snippets
# ============================================================
zi snippet OMZP::git
zi snippet OMZP::autojump
zi snippet OMZL::completion.zsh
zi snippet OMZL::key-bindings.zsh

# ============================================================
# Environment Setup
# ============================================================

# bash profile compatibility (if you keep bash config in XDG)
[[ -f "${XDG_CONFIG_HOME}/bash/.bash_profile" ]] && source "${XDG_CONFIG_HOME}/bash/.bash_profile"

# Aliases (XDG)
[[ -f "${XDG_CONFIG_HOME}/alias/.aliases" ]] && source "${XDG_CONFIG_HOME}/alias/.aliases"

# AI env (XDG)
[[ -f "${XDG_CONFIG_HOME}/bash/.ai" ]] && source "${XDG_CONFIG_HOME}/bash/.ai"

# Powerlevel10k config (XDG)
[[ -f "${XDG_CONFIG_HOME}/zsh/.p10k.zsh" ]] && source "${XDG_CONFIG_HOME}/zsh/.p10k.zsh"

# ============================================================
# Antigravity / RVM
# ============================================================

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# RVM (keep this near the end of the file; last PATH mutation)
export PATH="$PATH:$HOME/.rvm/bin"

# ============================================================
# Env modules
# ============================================================
for f in "$ZDOTDIR"/env/*.zsh; do
  [[ -r "$f" ]] && source "$f"
done

# ============================================================
# Bin modules
# ============================================================

# Secrets (XDG)
[[ -f "${XDG_CONFIG_HOME}/secrets/.env.secrets" ]] && source "${XDG_CONFIG_HOME}/secrets/.env.secrets"

# Cargo env (rustup/cargo may drop an env helper here)
[[ -s "${CARGO_HOME}/env" ]] && source "${CARGO_HOME}/env"

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
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':fzf-tab:*' fzf-flags '--bind=ctrl-d:preview-page-down,ctrl-u:preview-page-up'

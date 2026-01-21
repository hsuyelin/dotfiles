# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -------------------------------------------------------------------
# ZI Initialization
# -------------------------------------------------------------------
typeset -A ZI
ZI[HOME_DIR]="${HOME}/.config/zi"
ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"

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

# =========================
# FZF Core
# =========================

export FZF_ALT_C_OPTS='
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

# -------------------------------------------------------------------
# ZI Theme
# -------------------------------------------------------------------
zi light "romkatv/powerlevel10k"

# -------------------------------------------------------------------
# ZI Initiative Plugins
# -------------------------------------------------------------------
zi ice wait lucid atinit='zpcompinit'
zi light "zdharma-continuum/fast-syntax-highlighting"

zi ice lucid atload'_zsh_autosuggest_start'
zi light "zsh-users/zsh-autosuggestions"
bindkey '^H' backward-delete-char
bindkey '^?' backward-delete-char

zi ice lucid
zi light "zsh-users/zsh-completions"

# -------------------------------------------------------------------
# ZI Passive Plugins
# -------------------------------------------------------------------
zi light "agkozak/zsh-z"
zi light "z-shell/zsh-eza"
zi light "DarrinTisdale/zsh-aliases-exa"

# -------------------------------------------------------------------
# ZI Snippets
# -------------------------------------------------------------------
zi snippet OMZP::git
zi snippet OMZP::autojump
zi snippet OMZL::completion.zsh
zi snippet OMZL::key-bindings.zsh

# -------------------------------------------------------------------
# Environment Setup
# -------------------------------------------------------------------
# To customize user config
[[ ! -f "$HOME/.config/bash/.bash_profile" ]] || source "$HOME/.config/bash/.bash_profile"

# Auto load alias
[[ ! -f "$HOME/.config/alias/.aliases" ]] || source "$HOME/.config/alias/.aliases"

# Auto ai env
[[ ! -f "$HOME/.config/bash/.ai" ]] || source "$HOME/.config/bash/.ai"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Add Rvm (RVM loading line should be near the end of the file)
# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# -------------------------------------------------------------------
# Fzf Setup
# -------------------------------------------------------------------
[ ! -f ~/.fzf.zsh ] || source ~/.fzf.zsh

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
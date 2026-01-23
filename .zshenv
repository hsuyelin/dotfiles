# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path, plus other important environment variables.
# .zshenv' should not contain commands that produce output or assume the shell is attached to a tty.

# ============================================================
# XDG
# ============================================================

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}/$UID"

# ============================================================
# Homebrew
# ============================================================

export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

# ============================================================
# Zsh
# ============================================================

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

mkdir -p "$XDG_STATE_HOME/zsh"
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=10000
export SAVEHIST=10000

# ============================================================
# Dotfiles
# ============================================================

export DOTFILES="${DOTFILES:-${0:A:h:h:h}}"

# ============================================================
# Dirs
# ============================================================

export DATADIR="$XDG_DATA_HOME"
export VIM_TMPDIR="$XDG_CACHE_HOME/vim"
mkdir -p "$DATADIR" "$VIM_TMPDIR"

# ============================================================
# Editors
# ============================================================

export EDITOR='subl'
export GIT_EDITOR='nvim'

# ============================================================
# fpath
# ============================================================

fpath=(
  "$DOTFILES/config/zsh/functions"
  "$HOMEBREW_PREFIX/share/zsh/site-functions"
  $fpath
)

# ============================================================
# PATH
# ============================================================

typeset -aU path

# ============================================================
# Local overrides
# ============================================================

[[ -f "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
[[ -f "$HOME/.localrc"   ]] && source "$HOME/.localrc"


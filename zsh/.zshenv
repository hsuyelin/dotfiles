# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path, plus other important environment variables.
# .zshenv should not contain commands that produce output or assume the shell is attached to a tty.

# ============================================================
# XDG
# ============================================================

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-$HOME/.local/xdg-runtime}"

# ============================================================
# Homebrew
# ============================================================

export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

# ============================================================
# Zsh
# ============================================================

export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"

mkdir -p "$XDG_STATE_HOME/zsh"
export HISTFILE="$XDG_STATE_HOME/zsh/history"
# HISTSIZE/SAVEHIST are set in .zshrc (interactive shells only) where
# history opts (INC_APPEND, SHARE, IGNORE_DUPS…) are also configured.

# ============================================================
# Dotfiles
# ============================================================

export DOTFILES="${DOTFILES:-${0:A:h:h:h}}"

# ============================================================
# Dirs
# ============================================================

export DATADIR="$XDG_DATA_HOME"
mkdir -p "$DATADIR"

# ============================================================
# Editors
# ============================================================

if command -v nvim >/dev/null 2>&1; then
    export EDITOR='nvim'
elif command -v subl >/dev/null 2>&1; then
    export EDITOR='subl'
else
    export EDITOR='vi'
fi
export GIT_EDITOR='nvim'
export TERMINAL='/Applications/Ghostty.app/Contents/MacOS/ghostty'

# ============================================================
# fpath
# ============================================================

# shellcheck disable=SC2206
fpath=(
  "$DOTFILES/config/zsh/functions"
  "$HOMEBREW_PREFIX/share/zsh/site-functions"
  $fpath
)

# ============================================================
# PATH
# ============================================================

# shellcheck disable=SC2034
typeset -aU path

# ============================================================
# Env modules
# ============================================================

for f in "$ZDOTDIR"/env/*.zsh; do
  # shellcheck disable=SC1090
  [[ -r "$f" ]] && source "$f"
done

# ============================================================
# Local overrides
# ============================================================

# shellcheck disable=SC1091
[[ -f "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
# shellcheck disable=SC1091
[[ -f "$HOME/.localrc"   ]] && source "$HOME/.localrc"

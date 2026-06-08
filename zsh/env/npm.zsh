# ============================================================
# npm (XDG)
# ============================================================

export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NPM_CONFIG_PREFIX="$XDG_DATA_HOME/npm"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"

# Ensure global npm binaries are on PATH
typeset -aU path
# shellcheck disable=SC2128,SC2206
path=("$XDG_DATA_HOME/npm/bin" $path)
export PATH

# ============================================================
# nvm (Linux only — XDG style)
# ============================================================
# On Linux, redirect nvm from its default $HOME/.nvm to XDG_DATA_HOME.
# Set NVM_DIR before sourcing so the official install script respects it.
if [[ "$(uname -s)" == "Linux" ]]; then
    export NVM_DIR="${XDG_DATA_HOME}/nvm"
    # nvm is incompatible with NPM_CONFIG_PREFIX; the prefix is already
    # declared in npmrc so unsetting the env var here is safe.
    unset NPM_CONFIG_PREFIX
    # shellcheck disable=SC1090,SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    # shellcheck disable=SC1090,SC1091
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
fi

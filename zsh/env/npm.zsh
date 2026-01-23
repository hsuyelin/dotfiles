# ============================================================
# npm (XDG)
# ============================================================

export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NPM_CONFIG_PREFIX="$XDG_DATA_HOME/npm"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"

# Ensure global npm binaries are on PATH
typeset -aU path
path=("$XDG_DATA_HOME/npm/bin" $path)
export PATH

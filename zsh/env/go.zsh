# ============================================================
# Go (XDG)
# ============================================================

export GOPATH="$XDG_DATA_HOME/go"

# Ensure Go workspace binaries are on PATH.
typeset -aU path
# shellcheck disable=SC2128,SC2206
path=("$GOPATH/bin" $path)
export PATH

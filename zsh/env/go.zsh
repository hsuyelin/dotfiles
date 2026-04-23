# ============================================================
# Go (XDG)
# ============================================================

export GOPATH="$XDG_DATA_HOME/go"

# Ensure Go workspace binaries are on PATH.
typeset -aU path
path=("$GOPATH/bin" $path)
export PATH

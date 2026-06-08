# ============================================================
# Linux-only environment
# ============================================================

[[ "$(uname -s)" == "Linux" ]] || return 0

# Nvim: AppImage / manual install drops the binary under /opt/nvim/
if [[ -d /opt/nvim ]]; then
    typeset -aU path
    # shellcheck disable=SC2128,SC2206
    path=($path /opt/nvim)
    export PATH
fi

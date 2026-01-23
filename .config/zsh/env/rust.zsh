# ============================================================
# Rust (XDG)
# ============================================================

export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

# Ensure cargo/rustup binaries are on PATH
typeset -aU path
path=("$CARGO_HOME/bin" $path)
export PATH

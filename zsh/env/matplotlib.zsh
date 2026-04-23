# ============================================================
# Matplotlib (XDG)
# ============================================================

# On macOS Matplotlib defaults to ~/.matplotlib, so pin it explicitly.
export MPLCONFIGDIR="$XDG_CONFIG_HOME/matplotlib"

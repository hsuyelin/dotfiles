# ============================================================
# Codex (XDG-ish)
# ============================================================

# Codex currently uses a single home directory for config, auth, logs, cache,
# sessions, and skills. Keep it out of $HOME even though it is not perfectly
# split across XDG config/data/cache/state directories.
export CODEX_HOME="$XDG_DATA_HOME/codex"

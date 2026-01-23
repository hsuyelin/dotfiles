# ============================================================
# Ruby / Bundler (XDG)
# ============================================================

# Bundler config directory (preferred)
export BUNDLE_APP_CONFIG="$XDG_CONFIG_HOME/bundle"

# Bundler cache / plugins
export BUNDLE_USER_CACHE="$XDG_CACHE_HOME/bundle"
export BUNDLE_USER_PLUGIN="$XDG_DATA_HOME/bundle"

# Avoid ambiguous variable (some versions treat it as a file path)
unset BUNDLE_USER_CONFIG

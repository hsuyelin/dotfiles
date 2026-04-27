# ============================================================
# Ghostty Shaders (auto-clone if missing)
# ============================================================
_ghostty_shaders="${XDG_CONFIG_HOME}/ghostty/shaders"
[[ -d "$_ghostty_shaders" ]] || git clone -q --depth=1 \
  https://github.com/sahaj-b/ghostty-cursor-shaders "$_ghostty_shaders"
unset _ghostty_shaders

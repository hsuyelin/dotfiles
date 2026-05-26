# ============================================================
# Ghostty Shaders (auto-clone if missing)
# ============================================================
_ghostty_shaders="${XDG_CONFIG_HOME}/ghostty/shaders"
[[ -d "$_ghostty_shaders" ]] || git clone -q --depth=1 \
  https://github.com/sahaj-b/ghostty-cursor-shaders "$_ghostty_shaders"
unset _ghostty_shaders

# ============================================================
# Ghostty Aliases
# ============================================================

_GHOSTTY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"

# Reload config
alias ghrl='ghostty +reload-config'

# ghtt: switch titlebar to "tabs" (tab bar integrated into titlebar)
ghtt() {
  # Comment out the currently active titlebar-style line
  sed -i '' 's/^macos-titlebar-style = /#macos-titlebar-style = /' "$_GHOSTTY_CONFIG"
  # Uncomment the "tabs" variant
  sed -i '' 's/^#macos-titlebar-style = tabs$/macos-titlebar-style = tabs/' "$_GHOSTTY_CONFIG"
  ghostty +reload-config
  echo "ghostty: titlebar-style → tabs"
}

# ghth: switch titlebar to "hidden" (compact frame, traffic lights visible)
ghth() {
  # Comment out the currently active titlebar-style line
  sed -i '' 's/^macos-titlebar-style = /#macos-titlebar-style = /' "$_GHOSTTY_CONFIG"
  # Uncomment the "hidden" variant
  sed -i '' 's/^#macos-titlebar-style = hidden$/macos-titlebar-style = hidden/' "$_GHOSTTY_CONFIG"
  ghostty +reload-config
  echo "ghostty: titlebar-style → hidden"
}

# ghhelp: print all ghostty aliases
ghhelp() {
  local bold=$'\033[1m'
  local cyan=$'\033[0;36m'
  local yellow=$'\033[0;33m'
  local reset=$'\033[0m'
  local sep='────────────────────────────'

  _ghhelp_section() { printf '\n%s  %-16s%s\n' "$yellow" "$1" "$reset"; }
  _ghhelp_row()     { printf '  %s%-16s%s  %s\n' "$cyan" "$1" "$reset" "$2"; }

  echo ""
  printf '%sGhostty Aliases%s\n' "$bold" "$reset"
  echo "$sep"

  _ghhelp_section "Config"
  _ghhelp_row "ghrl"    "reload ghostty config"

  _ghhelp_section "Titlebar"
  _ghhelp_row "ghtt"    "titlebar-style = tabs   (tab bar in titlebar)"
  _ghhelp_row "ghth"    "titlebar-style = hidden (compact frame)"

  echo ""
  echo "$sep"
  echo ""

  unfunction _ghhelp_section _ghhelp_row
}

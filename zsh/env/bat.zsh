# ============================================================
# bat
# ============================================================
# Set Catppuccin Mocha theme only when bat's binary cache has been built.
# Without `bat cache --build`, bat won't recognise custom themes and will
# print a warning then fall back to the default theme.
#
# Cache paths (no subprocess required):
#   macOS : ~/Library/Caches/bat/bat.bin
#   Linux : $XDG_CACHE_HOME/bat/bat.bin

if [[ "$(uname -s)" == "Darwin" ]]; then
    _bat_cache="${HOME}/Library/Caches/bat/bat.bin"
else
    _bat_cache="${XDG_CACHE_HOME:-${HOME}/.cache}/bat/bat.bin"
fi

_bat_theme_src="${XDG_CONFIG_HOME:-${HOME}/.config}/bat/themes/Catppuccin Mocha.tmTheme"

if [[ -f "$_bat_theme_src" && -f "$_bat_cache" ]]; then
    export BAT_THEME="Catppuccin Mocha"
fi

unset _bat_cache _bat_theme_src

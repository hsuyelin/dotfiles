# nhelp: Neovim keymap reference.
# Usage: nhelp [list | show [--module <id>] [--lang zh]] [--help]
nhelp() {
    local _i18n="${XDG_CONFIG_HOME}/alias/i18n/nvim.json"
    case "$1" in
        list)      shift; _help_list "$_i18n" "$@" ;;
        --help|-h) _help_usage "nhelp" ;;
        show)      shift; _help_show "$_i18n" "$@" ;;
        *)         _help_show "$_i18n" "$@" ;;
    esac
}

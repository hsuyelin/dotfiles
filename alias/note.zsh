# notehelp: note-taking keymap reference (obsidian.nvim + markdown tools).
# workspace: ~/notes   inbox: ~/notes/inbox   daily: ~/notes/daily
# Usage: notehelp [list | show [--module <id>] [--lang zh]] [--help]
notehelp() {
    local _i18n="${XDG_CONFIG_HOME}/alias/i18n/note.json"
    case "$1" in
        list)      shift; _help_list "$_i18n" "$@" ;;
        --help|-h) _help_usage "notehelp" ;;
        show)      shift; _help_show "$_i18n" "$@" ;;
        *)         _help_show "$_i18n" "$@" ;;
    esac
}

# h3r: Short alias for Herdr CLI.
h3r() {
    local _status

    HERDR_REATTACH_COMMAND="h3r" herdr "$@"
    _status=$?

    if (( _status == 0 )) && { (( $# == 0 )) || [[ "$1 $2" == "session attach" ]]; }; then
        printf '\033[2J\033[H'
    fi

    return $_status
}

# hhelp: Herdr keymap reference.
# Usage: hhelp [list | show [--module <id>] [--lang zh]] [--help]
hhelp() {
    local _i18n="${XDG_CONFIG_HOME}/alias/i18n/herdr.json"
    case "$1" in
        list)      shift; _help_list "$_i18n" "$@" ;;
        --help|-h) _help_usage "hhelp" ;;
        show)      shift; _help_show "$_i18n" "$@" ;;
        *)         _help_show "$_i18n" "$@" ;;
    esac
}

# hremote: Manage local herdr-remote relay and Telegram bot.
hremote() {
    "${XDG_CONFIG_HOME}/herdr/remote/local/herdr-remote.sh" "$@"
}

alias hremote-install='hremote install'
alias hremote-uninstall='hremote uninstall'
alias hremote-resume='hremote resume'
alias hremote-pause='hremote pause'
alias hremote-stop='hremote stop'
alias hremote-status='hremote status'

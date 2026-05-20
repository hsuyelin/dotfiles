# Auto-notify on long-running command completion.
# Fires after any command that took longer than $_NOTIFY_MIN_DURATION seconds.

typeset -g _NOTIFY_MIN_DURATION=${_NOTIFY_MIN_DURATION:-10}

_notify_preexec() {
    _notify_cmd_start=$EPOCHSECONDS
    _notify_last_cmd="${1%% *}"
}

_notify_precmd() {
    local exit_code=$?
    [[ -z "${_notify_cmd_start:-}" ]] && return
    local elapsed=$(( EPOCHSECONDS - _notify_cmd_start ))
    unset _notify_cmd_start
    (( elapsed < _NOTIFY_MIN_DURATION )) && return

    local label
    if (( exit_code == 0 )); then
        label="Finished in ${elapsed}s"
    else
        label="Failed (exit ${exit_code}) in ${elapsed}s"
    fi

    command notify "${_notify_last_cmd}" "$label" 2>/dev/null || true
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _notify_preexec
add-zsh-hook precmd _notify_precmd

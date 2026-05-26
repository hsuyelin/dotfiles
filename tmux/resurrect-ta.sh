#!/usr/bin/env bash
# Helper for ta() fzf resurrect bindings.
# Usage: resurrect-ta.sh save [session...]
#          save all sessions; if sessions given, remove unlisted ones from save file
#        resurrect-ta.sh drop [session...]
#          remove named sessions from the save file

RESURRECT_DIR="${HOME}/.local/share/tmux/resurrect"
SAVE_SCRIPT="${XDG_CONFIG_HOME:-${HOME}/.config}/tmux/plugins/tmux-resurrect/scripts/save.sh"

_drop_sessions() {
    local actual="$1"; shift
    for s in "$@"; do
        [ -n "$s" ] || continue
        awk -F'\t' -v ss="$s" '$2 != ss' "$actual" > "${actual}.tmp" \
            && mv "${actual}.tmp" "$actual"
    done
}

case "$1" in
    save)
        shift
        if [ ! -x "$SAVE_SCRIPT" ]; then
            tmux display-message -d 2000 '⚠  tmux-resurrect not installed'
            exit 1
        fi
        "$SAVE_SCRIPT" 2>/dev/null
        save_file="${RESURRECT_DIR}/last"
        [ -f "$save_file" ] || exit 0
        actual=$(realpath "$save_file")
        if [ "$#" -gt 0 ]; then
            tmp=$(mktemp)
            awk -F'\t' '/^(pane|window)/{print $2}' "$actual" | sort -u > "$tmp"
            while IFS= read -r sess; do
                keep=0
                for s in "$@"; do [ "$s" = "$sess" ] && keep=1 && break; done
                [ "$keep" -eq 0 ] && _drop_sessions "$actual" "$sess"
            done < "$tmp"
            rm -f "$tmp"
            tmux display-message -d 2000 "  saved: $*"
        else
            tmux display-message -d 2000 '  all sessions saved'
        fi
        ;;
    drop)
        shift
        save_file="${RESURRECT_DIR}/last"
        if [ ! -f "$save_file" ]; then
            tmux display-message -d 2000 '⚠  no save file'
            exit 0
        fi
        actual=$(realpath "$save_file")
        _drop_sessions "$actual" "$@"
        tmux display-message -d 2000 "  dropped: $*"
        ;;
esac

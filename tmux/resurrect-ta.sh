#!/usr/bin/env bash
# Helper for ta() fzf resurrect bindings.
# Usage:
#   resurrect-ta.sh save
#       Save all sessions.
#   resurrect-ta.sh save-merge session [session ...]
#       Refresh save data for the listed sessions only; preserve all others as-is.
#   resurrect-ta.sh drop session [session ...]
#       Remove the listed sessions from the save file.

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
        if [ ! -x "$SAVE_SCRIPT" ]; then
            tmux display-message -d 2000 '  tmux-resurrect not installed'
            exit 1
        fi
        "$SAVE_SCRIPT" 2>/dev/null
        tmux display-message -d 2000 '  all sessions saved'
        ;;

    save-merge)
        shift
        if [ ! -x "$SAVE_SCRIPT" ]; then
            tmux display-message -d 2000 '  tmux-resurrect not installed'
            exit 1
        fi

        # Build a temp file listing the sessions to update.
        tmp_sel=$(mktemp)
        for s in "$@"; do printf '%s\n' "$s"; done > "$tmp_sel"

        # Snapshot non-selected sessions from the existing save file (if any).
        old_nonsel=""
        save_file="${RESURRECT_DIR}/last"
        if [ -f "$save_file" ]; then
            old_actual=$(realpath "$save_file")
            old_nonsel=$(awk -F'\t' \
                'NR==FNR{sel[$1]=1;next} ($1=="pane"||$1=="window") && !sel[$2]' \
                "$tmp_sel" "$old_actual")
        fi

        # Run a full save — creates a new timestamped file and updates last.
        "$SAVE_SCRIPT" 2>/dev/null
        save_file="${RESURRECT_DIR}/last"
        if [ ! -f "$save_file" ]; then
            rm -f "$tmp_sel"
            exit 0
        fi
        new_actual=$(realpath "$save_file")

        # From new file: rows for selected sessions + all non-session metadata.
        new_sel=$(awk -F'\t' \
            'NR==FNR{sel[$1]=1;next} ($1=="pane"||$1=="window") && sel[$2]' \
            "$tmp_sel" "$new_actual")
        new_meta=$(awk -F'\t' '$1!="pane" && $1!="window"' "$new_actual")
        rm -f "$tmp_sel"

        # Merge: metadata (fresh) + selected sessions (fresh) + others (preserved).
        {
            printf '%s\n' "$new_meta"
            printf '%s\n' "$new_sel"
            printf '%s\n' "$old_nonsel"
        } | grep -v '^[[:space:]]*$' > "${new_actual}.tmp" \
            && mv "${new_actual}.tmp" "$new_actual"

        tmux display-message -d 2000 "  saved: $*"
        ;;

    drop)
        shift
        save_file="${RESURRECT_DIR}/last"
        if [ ! -f "$save_file" ]; then
            tmux display-message -d 2000 '  no save file'
            exit 0
        fi
        actual=$(realpath "$save_file")
        _drop_sessions "$actual" "$@"
        tmux display-message -d 2000 "  dropped: $*"
        ;;
esac

# ============================================================
# Baseline PATH (existence-gated, platform-aware)
# ============================================================
# All entries are checked for directory existence before being added.
# typeset -aU guarantees no duplicates regardless of source order.

typeset -aU path

# Prepend $1 (higher priority — user / tool paths go to the front)
_path_pre()  { [[ -d "$1" ]] && path=("$1" $path) }
# Append $1 (lower priority — standard system paths go to the back)
_path_post() { [[ -d "$1" ]] && path+=("$1") }

# ── User / XDG paths ────────────────────────────────────────
_path_pre "${XDG_CONFIG_HOME:-$HOME/.config}/bin"
_path_pre "$HOME/.local/bin"
_path_pre "$HOME/.rvm/bin"

# ── Homebrew (macOS) ────────────────────────────────────────
if [[ "$(uname -s)" == "Darwin" ]]; then
    _path_pre "/opt/homebrew/bin"
    _path_post "/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources"
fi

# ── Standard system paths ───────────────────────────────────
_path_post "/usr/local/bin"
_path_post "/usr/local/sbin"
_path_post "/bin"
_path_post "/sbin"
_path_post "/usr/sbin"
_path_post "/usr/bin"

# ── Linux-specific system paths ─────────────────────────────
if [[ "$(uname -s)" == "Linux" ]]; then
    _path_post "/root/bin"
fi

# ── Android SDK ─────────────────────────────────────────────
if [[ -n "${ANDROID_SDK:-}" ]]; then
    _path_post "$ANDROID_SDK/platform-tools"
    _path_post "$ANDROID_SDK/tools"
fi

unset -f _path_pre _path_post

export PATH

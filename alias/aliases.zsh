# -----------------------------
# Proxy helpers
# -----------------------------
proxy_off() {
  unset https_proxy http_proxy all_proxy
  echo "Proxy disabled."
}

proxy_on() {
  local http_port="${PROXY_PORT_HTTP:-6152}"
  local socks_port="${PROXY_PORT_SOCKS:-6153}"
  export https_proxy="http://127.0.0.1:${http_port}"
  export http_proxy="http://127.0.0.1:${http_port}"
  export all_proxy="socks5://127.0.0.1:${socks_port}"
  echo "Proxy enabled (http=${http_port}, socks5=${socks_port})."
}

proxy_status() {
  echo "http_proxy=${http_proxy:-<unset>}"
  echo "https_proxy=${https_proxy:-<unset>}"
  echo "all_proxy=${all_proxy:-<unset>}"
}

# -----------------------------
# Bash profile shortcuts
# -----------------------------
alias bash-reload='source "${XDG_CONFIG_HOME}/bash/.bash_profile"'
alias bash-edit='subl "${XDG_CONFIG_HOME}/bash/.bash_profile"'

# -----------------------------
# Tool shortcuts
# -----------------------------
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  alias bat='batcat'
fi

if command -v bat >/dev/null 2>&1; then
  alias batp='bat -p'       # plain style (no decorations)
  alias batP='bat -P'       # no paging
  alias batpp='bat -p -P'   # plain style + no paging (cat-like)

fi

alias rvminstall='"$HOME/.rvm/.rvminstall.sh"'
alias rubyfmt='rubocop -A'

if [[ "$(uname -s)" == "Darwin" ]]; then
  alias carthage_build='"${XDG_CONFIG_HOME}/bin/carthage_build.sh"'
  alias brew_export='"${XDG_CONFIG_HOME}/bin/brew_export.sh"'
  alias xcode='"${XDG_CONFIG_HOME}/bin/xcode.sh"'
fi

# omni-app-id: list managed apps or filter by an application-name keyword.
omni-app-id() {
  if ! command -v omniwmctl >/dev/null 2>&1; then
    printf 'omni-app-id: omniwmctl is not available.\n' >&2
    return 127
  fi

  if (( $# == 0 )); then
    omniwmctl query apps --format table
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    printf 'omni-app-id: jq is not available.\n' >&2
    return 127
  fi

  local keyword="$*"
  omniwmctl query apps --format json | jq --arg keyword "$keyword" '
    .result.payload.apps[]
    | select(.appName | ascii_downcase | contains($keyword | ascii_downcase))
    | {appName, bundleId}
  '
}


# -----------------------------
# eza / git helpers
# - If eza exists, use it. Otherwise fall back to system ls.
# -----------------------------
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first --hyperlink'
  alias l='eza -l --icons --git --header --group-directories-first --color-scale --hyperlink'
  alias ll='eza -la --icons --git --header --group-directories-first --color-scale --hyperlink'
  alias la='eza -a --icons --group-directories-first --hyperlink'
  alias lr='eza -l --sort=modified --icons --git --header --group-directories-first --color-scale --hyperlink'
  alias lb='eza -l --sort=size --icons --git --header --group-directories-first --color-scale --hyperlink'
  alias lt='eza --tree --level=2 --icons --group-directories-first --hyperlink'
  alias lta='eza --tree -a --level=2 --icons --group-directories-first --hyperlink'
else
  alias l='ls -lh'
  alias ll='ls -lah'
  alias la='ls -A'
fi

command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'

alias rrm='command rm'


# -----------------------------
# System helpers
# -----------------------------
if [[ "$(uname -s)" == "Darwin" ]]; then
  alias dns:flush='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

  # disk: fast disk usage report powered by dust.
  # See: $XDG_CONFIG_HOME/bin/disktop.sh
  alias disk='"${XDG_CONFIG_HOME}/bin/disktop.sh"'

  # pwtop: energy-sorted process monitor with Catppuccin Mocha styling.
  # See: $XDG_CONFIG_HOME/powermetrics/pwtop.sh
  alias pwtop='"${XDG_CONFIG_HOME}/powermetrics/pwtop.sh"'
fi


# -----------------------------
# Applications (macOS-only)
# -----------------------------
if [[ "$(uname -s)" == "Darwin" ]]; then
  alias chrome="open -a \"Google Chrome\" --args --variations-override-country=us"

  # sign_app: strip quarantine attributes and re-sign a macOS .app bundle.
  # Usage: sign_app <app>
  # <app> can be:
  #   - absolute path:  /Applications/Paste.app
  #   - name with ext:  Paste.app  (or paste.app)
  #   - name only:      paste
  sign_app() {
    local input="$1"

    local _bold=$'\033[1m'
    local _green=$'\033[0;32m'
    local _yellow=$'\033[0;33m'
    local _red=$'\033[0;31m'
    local _cyan=$'\033[0;36m'
    local _reset=$'\033[0m'

    if [[ -z "$input" ]]; then
      printf '%sUsage:%s sign_app <app-path|app-name>\n' "$_yellow" "$_reset"
      return 1
    fi

    local app_path

    if [[ "$input" == /* ]]; then
      app_path="$input"
    else
      local name="${input%.[aA][pP][pP]}"
      local found
      found="$(find /Applications -maxdepth 1 -iname "${name}.app" -print -quit 2>/dev/null)"
      if [[ -z "$found" ]]; then
        printf '%serror:%s cannot find '"'"'%s%s.app%s'"'"' in /Applications\n' \
            "$_red" "$_reset" "$_bold" "$name" "$_reset" >&2
        return 1
      fi
      app_path="$found"
    fi

    if [[ ! -d "$app_path" ]]; then
      printf '%serror:%s '"'"'%s%s%s'"'"' does not exist or is not a directory\n' \
          "$_red" "$_reset" "$_bold" "$app_path" "$_reset" >&2
      return 1
    fi

    printf '%s  Found%s %s%s%s\n' "$_cyan" "$_reset" "$_bold" "$app_path" "$_reset"
    printf '%sProceed with signing?%s [y/N] ' "$_yellow" "$_reset"
    local reply
    read -r reply
    if [[ "$reply" != [yY] ]]; then
      printf '%sAborted.%s\n' "$_yellow" "$_reset"
      return 0
    fi

    local _sudo=''
    [[ "$EUID" -ne 0 ]] && _sudo='sudo'

    printf '%sStripping%s quarantine attributes ...\n' "$_cyan" "$_reset"
    $_sudo xattr -cr "$app_path" || { printf '%serror:%s xattr failed\n' "$_red" "$_reset" >&2; return 1; }

    printf '%s Signing%s %s%s%s ...\n' "$_cyan" "$_reset" "$_bold" "$app_path" "$_reset"
    $_sudo codesign -fs - --deep "$app_path" || { printf '%serror:%s codesign failed\n' "$_red" "$_reset" >&2; return 1; }

    printf '%s   Done%s %s%s%s\n' "$_green" "$_reset" "$_bold" "$app_path" "$_reset"
  }
fi


# -----------------------------
# Safer rm wrapper
# - Keeps -f semantics: if -f provided, missing targets won't warn.
# - Uses safe-trash if available; otherwise falls back to /bin/rm.
# -----------------------------
rm() {
  local targets=()
  local force=false

  for arg in "$@"; do
    case "$arg" in
      -*)
        [[ "$arg" == *"f"* ]] && force=true
        ;;
      *)
        targets+=("$arg")
        ;;
    esac
  done

  if [ ${#targets[@]} -eq 0 ]; then
    /bin/rm "$@"
    return $?
  fi

  for target in "${targets[@]}"; do
    if [ -e "$target" ]; then
      if command -v safe-trash >/dev/null 2>&1; then
        safe-trash "$target"
      else
        /bin/rm -rf -- "$target"
      fi
    else
      if [ "$force" = false ]; then
        echo "rm: $target: No such file or directory"
      fi
    fi
  done
}


# -----------------------------
# fix: convert `cmd` => $(cmd) in clipboard content (macOS only)
# -----------------------------
if [[ "$(uname -s)" == "Darwin" ]]; then
  fix() {
    local clipboard_content fixed_content

    clipboard_content="$(pbpaste)"
    # shellcheck disable=SC2016
    fixed_content="$(echo "$clipboard_content" | sed -E 's/\`([^\`]+)\`/$(\1)/g')"

    echo "$fixed_content" | pbcopy
    echo -e "Fixed command copied to clipboard. Output:\n\n$fixed_content\n"
  }
fi


# -----------------------------
# rd: ratatui directory picker
# -----------------------------
rd() {
  local RATATUI_BETTER_CD="rd-better-cd"
  local TEMP_FILE="${TMPDIR:-/tmp}/rd_selected_dir"
  local SELECTED_DIR

  if ! command -v "$RATATUI_BETTER_CD" >/dev/null 2>&1; then
    echo "Error: '$RATATUI_BETTER_CD' not found." >&2
    return 1
  fi

  command rm -rf "$TEMP_FILE"
  "$RATATUI_BETTER_CD"

  [ -f "$TEMP_FILE" ] || return 0

  read -r SELECTED_DIR < "$TEMP_FILE"
  command rm -rf "$TEMP_FILE"

  if [ -n "$SELECTED_DIR" ] && [ -d "$SELECTED_DIR" ]; then
    cd "$SELECTED_DIR" || return 1
  else
    echo "Invalid directory: $SELECTED_DIR" >&2
    return 1
  fi
}


# -----------------------------
# ipshow: show local / public ip (macOS only)
# -----------------------------
if [[ "$(uname -s)" == "Darwin" ]]; then
  ipshow() {
    local iface
    iface="$(route get default 2>/dev/null | awk '/interface:/{print $2}')"

    case "$1" in
      --local|-l)
        echo "LAN: $(ipconfig getifaddr "$iface")"
        ;;
      --public|-p)
        echo "WAN: $(curl -s ifconfig.me)"
        ;;
      "")
        echo "LAN: $(ipconfig getifaddr "$iface")"
        echo "WAN: $(curl -s ifconfig.me)"
        ;;
      *)
        echo "Usage: ipshow [--local|-l | --public|-p]"
        ;;
    esac
  }
fi

# -----------------------------
# git & fzf
# -----------------------------
alias gba='git branch -a | fzf --height=40% --border --preview "git log --oneline --color=always -- {} | head -80" | sed "s/.* //" | xargs git checkout'


# -----------------------------
# Yazi file manager
# - On exit, automatically cd to the last directory navigated inside Yazi.
# - Uses yazi's --cwd-file mechanism (official shell integration).
# - Defined as a function (not an alias) so it can call `builtin cd`;
#   zero startup overhead — yazi only launches when you call yy.
# -----------------------------
yy() {
    if ! command -v yazi &>/dev/null; then
        printf 'yy: yazi not installed. Install it via your system package manager.\n' >&2
        return 1
    fi
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return 1
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd" || return 1
    fi
    rm -f -- "$tmp"
}


# -----------------------------
# video-h265: compress video to HEVC MP4, without audio by default.
# Usage: video-h265 [--audio] <video-file>
# --audio keeps all source audio tracks, encoding them as MP4-compatible AAC.
# -----------------------------
video-h265() (
    local keep_audio=false
    if [[ "$1" == --audio ]]; then
        keep_audio=true
        shift
    fi
    if (( $# != 1 )) || [[ "$1" == -* ]]; then
        printf 'Usage: video-h265 [--audio] <video-file>\n' >&2
        return 2
    fi

    if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
        printf 'video-h265: ffmpeg and ffprobe are required.\n' >&2
        return 127
    fi

    local input name stem output tmp vcodec acodec
    local -a audio_args
    input="${1:a}"
    if [[ ! -f "$input" || ! -r "$input" ]]; then
        printf 'video-h265: not a readable file: %s\n' "$input" >&2
        return 1
    fi
    vcodec="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 "$input")"
    if [[ "$vcodec" != video* ]]; then
        printf 'video-h265: no readable video stream: %s\n' "$input" >&2
        return 1
    fi
    if [[ "$keep_audio" == true ]]; then
        if [[ -z "$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 "$input")" ]]; then
            printf 'video-h265: --audio requested but source has no audio track: %s\n' "$input" >&2
            return 1
        fi
        audio_args=(-map 0:a -c:a aac -b:a 192k)
    else
        audio_args=(-an)
    fi

    name="${input##*/}"
    stem="${name%.*}"
    [[ -n "$stem" ]] || stem="$name"
    if [[ "$keep_audio" == true ]]; then
        output="${input%/*}/${stem}_H265_有音频.mp4"
    else
        output="${input%/*}/${stem}_H265_无音频.mp4"
    fi
    if [[ -e "$output" || -L "$output" ]]; then
        printf 'video-h265: output already exists: %s\n' "$output" >&2
        return 1
    fi

    tmp="$(mktemp "${output}.tmp.XXXXXXXX")" || return 1
    local umask_bits=$(( 8#$(umask) ))
    chmod "$(printf '%o' $(( 8#666 & ~umask_bits )))" "$tmp"
    trap 'command rm -f -- "$tmp"' EXIT
    if ! ffmpeg -hide_banner -nostdin -loglevel error -stats_period 30 -stats \
        -i "$input" -map 0:v:0 "${audio_args[@]}" -sn -dn -fps_mode passthrough \
        -c:v libx265 -preset slow -crf 21 -pix_fmt yuv420p \
        -tag:v hvc1 -movflags +faststart -x265-params log-level=error \
        -f mp4 -y "$tmp"; then
        printf 'video-h265: encoding failed: %s\n' "$input" >&2
        return 1
    fi
    vcodec="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$tmp")" || return 1
    if [[ "$keep_audio" == true ]]; then
        acodec="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$tmp")" || return 1
        if [[ "$acodec" != aac* ]]; then
            printf 'video-h265: output has no AAC audio track: %s\n' "$input" >&2
            return 1
        fi
    elif [[ -n "$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$tmp")" ]]; then
        printf 'video-h265: output unexpectedly contains audio: %s\n' "$input" >&2
        return 1
    fi
    if [[ "$vcodec" != hevc* ]] || ! ffmpeg -hide_banner -nostdin -v error -i "$tmp" -map 0 -f null -; then
        printf 'video-h265: output verification failed: %s\n' "$input" >&2
        return 1
    fi
    if ! command ln "$tmp" "$output"; then
        printf 'video-h265: could not create output (possibly exists): %s\n' "$output" >&2
        return 1
    fi
    printf 'video-h265: %s\n' "$output"
)


# -----------------------------
# SSH
# -----------------------------
alias ssh='TERM=xterm-256color ssh'
alias ssh-reset='ssh-keygen -R'

# -----------------------------
# shelp: shell tools & zsh line-editing reference.
# Usage: shelp [list | show [--module <id>] [--lang zh]] [--help]
# -----------------------------
shelp() {
    local _i18n="${XDG_CONFIG_HOME}/alias/i18n/shell.json"
    case "$1" in
        list)      shift; _help_list "$_i18n" "$@" ;;
        --help|-h) _help_usage "shelp" ;;
        show)      shift; _help_show "$_i18n" "$@" ;;
        *)         _help_show "$_i18n" "$@" ;;
    esac
}

# -----------------------------
# System Improve
# -----------------------------
# Fast copy powered by xcp.
# Usage:
#   fcp source destination
#   fcp -r source destination
#   fcp -R source destination
#   fcp -f source destination
#   fcp -rf source destination
fcp() {
    if ! command -v xcp &>/dev/null; then
        command cp "$@"
        return
    fi

    local args=()
    local arg

    for arg in "$@"; do
        if [[ "$arg" == -[!-]* ]]; then
            args+=("${arg//R/r}")
        else
            args+=("$arg")
        fi
    done

    command xcp "${args[@]}"
}

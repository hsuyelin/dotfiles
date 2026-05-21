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
if command -v bat >/dev/null 2>&1; then
  alias batp='bat -p'       # plain style (no decorations)
  alias batP='bat -P'       # no paging
  alias batpp='bat -p -P'   # plain style + no paging (cat-like)

  bathelp() {
    local bold='\033[1m'
    local cyan='\033[0;36m'
    local yellow='\033[0;33m'
    local reset='\033[0m'
    local sep='────────────────────────────'

    echo ""
    printf "${bold}Bat Aliases Cheatsheet${reset}\n"
    echo "$sep"

    _bathelp_section() { printf "\n${yellow}  %-12s${reset}\n" "$1"; }
    _bathelp_row()     { printf "  ${cyan}%-12s${reset}  %s\n" "$1" "$2"; }

    _bathelp_section "Aliases"
    _bathelp_row "batp"  "bat -p    (plain style, no decorations)"
    _bathelp_row "batP"  "bat -P    (no paging)"
    _bathelp_row "batpp" "bat -p -P (plain style + no paging, cat-like)"

    echo ""
    echo "$sep"
    echo ""

    unfunction _bathelp_section _bathelp_row
  }
fi

alias rvminstall='"$HOME/.rvm/.rvminstall.sh"'
alias carthage_build='"${XDG_CONFIG_HOME}/bin/carthage_build.sh"'
alias brew_export='"${XDG_CONFIG_HOME}/bin/brew_export.sh"'
alias xcode='"${XDG_CONFIG_HOME}/bin/xcode.sh"'
alias rubyfmt='rubocop -A'


# -----------------------------
# eza / git helpers
# - If eza exists, use it. Otherwise fall back to system ls.
# -----------------------------
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias l='eza -l --icons --git --header --group-directories-first --color-scale'
  alias ll='eza -la --icons --git --header --group-directories-first --color-scale'
  alias la='eza -a --icons --group-directories-first'
  alias lr='eza -l --sort=modified --icons --git --header --group-directories-first --color-scale'
  alias lb='eza -l --sort=size --icons --git --header --group-directories-first --color-scale'
  alias lt='eza --tree --level=2 --icons --group-directories-first'
  alias lta='eza --tree -a --level=2 --icons --group-directories-first'
else
  alias l='ls -lh'
  alias ll='ls -lah'
  alias la='ls -A'
fi

command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'

alias real-rm='\rm'


# -----------------------------
# System helpers
# -----------------------------
alias dns:flush='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'


# -----------------------------
# Applications
# -----------------------------
alias chrome="open -a \"Google Chrome\" --args --variations-override-country=us"

# sign_app: strip quarantine attributes and re-sign a macOS .app bundle.
# Usage: sign_app <app>
# <app> can be:
#   - absolute path:  /Applications/Paste.app
#   - name with ext:  Paste.app  (or paste.app)
#   - name only:      paste
sign_app() {
  local input="$1"

  local _bold='\033[1m'
  local _green='\033[0;32m'
  local _yellow='\033[0;33m'
  local _red='\033[0;31m'
  local _cyan='\033[0;36m'
  local _reset='\033[0m'

  if [[ -z "$input" ]]; then
    printf "${_yellow}Usage:${_reset} sign_app <app-path|app-name>\n"
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
      printf "${_red}error:${_reset} cannot find '${_bold}${name}.app${_reset}' in /Applications\n" >&2
      return 1
    fi
    app_path="$found"
  fi

  if [[ ! -d "$app_path" ]]; then
    printf "${_red}error:${_reset} '${_bold}${app_path}${_reset}' does not exist or is not a directory\n" >&2
    return 1
  fi

  printf "${_cyan}  Found${_reset} ${_bold}${app_path}${_reset}\n"
  printf "${_yellow}Proceed with signing?${_reset} [y/N] "
  local reply
  read -r reply
  if [[ "$reply" != [yY] ]]; then
    printf "${_yellow}Aborted.${_reset}\n"
    return 0
  fi

  local _sudo=''
  [[ "$EUID" -ne 0 ]] && _sudo='sudo'

  printf "${_cyan}Stripping${_reset} quarantine attributes ...\n"
  $_sudo xattr -cr "$app_path" || { printf "${_red}error:${_reset} xattr failed\n" >&2; return 1; }

  printf "${_cyan} Signing${_reset} ${_bold}${app_path}${_reset} ...\n"
  $_sudo codesign -fs - --deep "$app_path" || { printf "${_red}error:${_reset} codesign failed\n" >&2; return 1; }

  printf "${_green}   Done${_reset} ${_bold}${app_path}${_reset}\n"
}


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
# fix: convert `cmd` => $(cmd) in clipboard content
# -----------------------------
fix() {
  local clipboard_content fixed_content

  clipboard_content="$(pbpaste)"
  fixed_content="$(echo "$clipboard_content" | sed -E 's/\`([^\`]+)\`/$(\1)/g')"

  echo "$fixed_content" | pbcopy
  echo -e "Fixed command copied to clipboard. Output:\n\n$fixed_content\n"
}


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

  real-rm -rf "$TEMP_FILE"
  "$RATATUI_BETTER_CD"

  [ -f "$TEMP_FILE" ] || return 0

  read -r SELECTED_DIR < "$TEMP_FILE"
  real-rm -rf "$TEMP_FILE"

  if [ -n "$SELECTED_DIR" ] && [ -d "$SELECTED_DIR" ]; then
    cd "$SELECTED_DIR" || return 1
  else
    echo "Invalid directory: $SELECTED_DIR" >&2
    return 1
  fi
}


# -----------------------------
# ipshow: show local / public ip
# -----------------------------
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
        printf 'yy: yazi not installed. Run: brew install yazi\n' >&2
        return 1
    fi
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return 1
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}


# -----------------------------
# SSH
# -----------------------------
alias ssh='TERM=xterm-256color ssh'

#!/usr/bin/env bash

# ============================================================
# pkg_install.sh — Cross-platform package installer
# ============================================================
# Usage:
#   bash pkg_install.sh [--dry-run] [--terminal=ghostty|kitty|iterm2]
#
# macOS  — installs via Homebrew from:
#   ~/.config/brew/brew_formulae.txt
#   ~/.config/brew/brew_casks.txt
#
# Linux  — maps formulae/casks to Arch (pacman) or Debian/Ubuntu (apt)
#   equivalents and installs them; packages with no mapping are skipped.
#
# Safe to re-run: already-installed packages are skipped.
# The AeroSpace tap (nikitabobko/tap) is added automatically on macOS.
# Non-full ffmpeg / imagemagick are removed before install on macOS
# because Yazi requires the -full variants.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"
readonly DOTFILES_DIR

# ── Platform detection ────────────────────────────────────────────────────────
_IS_MACOS=false
[[ "$(uname -s)" == "Darwin" ]] && _IS_MACOS=true
readonly _IS_MACOS

# Detect Homebrew prefix by probing known locations (Apple Silicon → Intel → PATH).
if   [[ -x /opt/homebrew/bin/brew ]]; then HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -x /usr/local/bin/brew ]];    then HOMEBREW_PREFIX="/usr/local"
elif command -v brew &>/dev/null;      then HOMEBREW_PREFIX="$(brew --prefix)"
else                                       HOMEBREW_PREFIX=""
fi
readonly HOMEBREW_PREFIX

# Detect Linux distro family: arch | debian | ubuntu | unknown.
_LINUX_DISTRO="unknown"
if [[ "${_IS_MACOS}" != "true" && -f /etc/os-release ]]; then
    _ld_id="$(. /etc/os-release 2>/dev/null && printf '%s' "${ID:-}")"
    _ld_like="$(. /etc/os-release 2>/dev/null && printf '%s' "${ID_LIKE:-}")"
    case "${_ld_id}" in
        arch)   _LINUX_DISTRO="arch" ;;
        debian) _LINUX_DISTRO="debian" ;;
        ubuntu) _LINUX_DISTRO="ubuntu" ;;
        *)
            case "${_ld_like}" in
                *arch*)   _LINUX_DISTRO="arch" ;;
                *ubuntu*) _LINUX_DISTRO="ubuntu" ;;
                *debian*) _LINUX_DISTRO="debian" ;;
            esac ;;
    esac
    unset _ld_id _ld_like
fi
readonly _LINUX_DISTRO

# ── Colors ───────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    readonly BOLD='\033[1m'
    readonly RED='\033[0;31m'
    readonly YELLOW='\033[0;33m'
    readonly GREEN='\033[0;32m'
    readonly CYAN='\033[0;36m'
    readonly NC='\033[0m'
else
    readonly BOLD='' RED='' YELLOW='' GREEN='' CYAN='' NC=''
fi

log_step() {    printf "${BOLD}${GREEN}%12s${NC} %s\n"  "$1" "$2"; }
log_info() {    printf "${BOLD}${CYAN}%12s${NC} %s\n"   "Info" "$1"; }
log_warn() {    printf "${BOLD}${YELLOW}%12s${NC} %s\n" "Warning" "$1"; }
log_error() {   printf "${BOLD}${RED}%12s${NC} %s\n"    "Error" "$1" >&2; }
log_success() { printf "${BOLD}${GREEN}%12s${NC} %s\n"  "Finished" "$1"; }
die() {         log_error "$1"; exit 1; }

# ── Flag parsing ──────────────────────────────────────────────────────────────
DRY_RUN=false
TERMINAL_CHOICE=""

for _arg in "$@"; do
    case "${_arg}" in
        --dry-run)   DRY_RUN=true ;;
        --terminal=*)
            _term="$(echo "${_arg#--terminal=}" | tr '[:upper:]' '[:lower:]')"
            case "${_term}" in
                ghostty)      TERMINAL_CHOICE="ghostty" ;;
                kitty)        TERMINAL_CHOICE="kitty"   ;;
                iterm2|iterm) TERMINAL_CHOICE="iterm2"  ;;
            esac
            ;;
        -h|--help)
            printf 'Usage: %s [--dry-run] [--terminal=ghostty|kitty|iterm2]\n\n' \
                "$(basename "$0")"
            printf 'Installs all Homebrew packages from ~/.config/brew/.\n\n'
            printf 'Options:\n'
            printf '  --dry-run              Print actions without executing.\n'
            printf '  --terminal=ghostty     Install Ghostty (default).\n'
            printf '  --terminal=kitty       Install kitty.\n'
            printf '  --terminal=iterm2      Install iTerm2.\n'
            printf '  -h, --help             Show this help.\n'
            exit 0
            ;;
        *)
            printf '%s: unknown argument: %s\n' "$(basename "$0")" "${_arg}" >&2
            exit 1
            ;;
    esac
done
unset _arg _term
readonly DRY_RUN

run() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] $*"
    else
        "$@"
    fi
}

# ── Linux package management ──────────────────────────────────────────────────
# Maps a brew formula name to the distro-native package name.
# Entry format: "brew_formula:arch_pkg:deb_pkg"
# An empty field means the package is not in that distro's standard repos.
_linux_pkg_for_formula() {
    local formula="$1" distro="$2"
    # brew_formula            : arch package      : debian/ubuntu package
    local -a _fmap=(
        "aria2:aria2:aria2"
        "autoconf:autoconf:autoconf"
        "automake:automake:automake"
        "bat:bat:bat"
        "btop:btop:btop"
        "eza:eza:eza"
        "fastfetch:fastfetch:fastfetch"
        "fd:fd:fd-find"
        "ffmpeg-full:ffmpeg:ffmpeg"
        "fzf:fzf:fzf"
        "gh:github-cli:gh"
        "git-delta:git-delta:"           # not in Debian/Ubuntu standard repos
        "git-filter-repo:git-filter-repo:git-filter-repo"
        "git-lfs:git-lfs:git-lfs"
        "glow:glow:"                     # not in Debian/Ubuntu standard repos
        "gnupg:gnupg:gnupg"
        "go:go:golang"
        "imagemagick-full:imagemagick:imagemagick"
        "jq:jq:jq"
        "lazygit:lazygit:"               # not in Debian/Ubuntu standard repos
        "lua:lua:lua5.4"
        "luajit:luajit:luajit"
        "luarocks:luarocks:luarocks"
        "m4:m4:m4"
        "nano:nano:nano"
        "neovim:neovim:neovim"
        "node:nodejs:nodejs"
        "pandoc:pandoc:pandoc"
        "pkgconf:pkgconf:pkg-config"
        "python@3.13:python:python3"
        "ripgrep:ripgrep:ripgrep"
        "sevenzip:7zip:7zip"
        "sqlite:sqlite:sqlite3"
        "starship:starship:starship"
        "stylua:stylua:"                 # not in standard repos
        "tealdeer:tealdeer:tealdeer"
        "tmux:tmux:tmux"
        "trash:trash-cli:trash-cli"
        "tree-sitter-cli:tree-sitter-cli:"  # not in standard repos
        "unar:unar:unar"
        "xz:xz:xz-utils"
        "yapf:yapf:yapf"
        "yazi:yazi:"                     # not in Debian/Ubuntu standard repos
        "zoxide:zoxide:zoxide"
        "zstd:zstd:zstd"
    )
    local entry bname rest arch_pkg deb_pkg
    for entry in "${_fmap[@]}"; do
        bname="${entry%%:*}"; rest="${entry#*:}"
        arch_pkg="${rest%%:*}"; deb_pkg="${rest##*:}"
        if [[ "${bname}" == "${formula}" ]]; then
            case "${distro}" in
                arch)          printf '%s' "${arch_pkg}" ;;
                debian|ubuntu) printf '%s' "${deb_pkg}" ;;
            esac
            return 0
        fi
    done
    return 1
}

# Maps a brew cask name to the distro-native package (GUI apps where available).
# Casks with no Linux equivalent return empty string.
_linux_pkg_for_cask() {
    local cask="$1" distro="$2"
    # brew_cask                         : arch package             : debian/ubuntu package
    local -a _cmap=(
        "db-browser-for-sqlite:sqlitebrowser:sqlitebrowser"
        "font-fira-code:ttf-fira-code:fonts-firacode"
        "font-fira-code-nerd-font:ttf-firacode-nerd:"   # Arch only
        "font-symbols-only-nerd-font:ttf-nerd-fonts-symbols:"  # Arch only
        "kitty:kitty:kitty"
        "oracle-jdk@25:jdk-openjdk:default-jdk"
        # font-lxgw-wenkai: AUR only, skipped
        # ghostty: AUR only, skipped
        # aerospace/orbstack/applite/etc.: macOS-only, no Linux equivalent
    )
    local entry bname rest arch_pkg deb_pkg
    for entry in "${_cmap[@]}"; do
        bname="${entry%%:*}"; rest="${entry#*:}"
        arch_pkg="${rest%%:*}"; deb_pkg="${rest##*:}"
        if [[ "${bname}" == "${cask}" ]]; then
            case "${distro}" in
                arch)          printf '%s' "${arch_pkg}" ;;
                debian|ubuntu) printf '%s' "${deb_pkg}" ;;
            esac
            return 0
        fi
    done
    return 1
}

# Installs one package via the distro's native package manager.
# Respects DRY_RUN. Returns 0 on success, 1 on failure or unsupported distro.
_APT_UPDATED=false
_linux_install_pkg() {
    local pkg="$1"
    [[ -z "${pkg}" ]] && return 1
    case "${_LINUX_DISTRO}" in
        arch)
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[dry-run] sudo pacman -S --noconfirm --needed ${pkg}"; return 0
            fi
            sudo pacman -S --noconfirm --needed "${pkg}"
            ;;
        debian|ubuntu)
            if [[ "${_APT_UPDATED}" != "true" ]]; then
                if [[ "${DRY_RUN}" == "true" ]]; then
                    log_info "[dry-run] sudo apt-get update"
                else
                    sudo apt-get update -qq \
                        || log_warn "apt-get update failed — package list may be stale"
                fi
                _APT_UPDATED=true
            fi
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[dry-run] sudo apt-get install -y ${pkg}"; return 0
            fi
            sudo apt-get install -y --no-install-recommends "${pkg}"
            ;;
        *) return 1 ;;
    esac
}

# Reads brew_formulae.txt and installs each entry via the native package manager.
_linux_install_formulae() {
    local list="${DOTFILES_DIR}/brew/brew_formulae.txt"
    if [[ ! -f "${list}" ]]; then
        log_warn "Formula list not found: ${list} (skipped)"; return 0
    fi
    log_step "Installing" "formulae via ${_LINUX_DISTRO} package manager"

    local formula pkg
    local _installed=0 _nomap=0 _failed=0
    while IFS= read -r formula; do
        [[ -z "${formula}" || "${formula}" == \#* ]] && continue
        # Use || true to prevent set -e from aborting when the formula has no mapping.
        pkg="$(_linux_pkg_for_formula "${formula}" "${_LINUX_DISTRO}")" || true
        if [[ -z "${pkg}" ]]; then
            (( _nomap++ )) || true
            log_info "no Linux mapping for formula: ${formula} — skipping"
            continue
        fi
        if _linux_install_pkg "${pkg}"; then
            (( _installed++ )) || true
        else
            log_warn "failed to install ${pkg} (formula: ${formula}) — skipping"
            (( _failed++ )) || true
        fi
    done < "${list}"

    local _summary="installed/updated ${_installed}"
    [[ ${_nomap}   -gt 0 ]] && _summary+=", ${_nomap} no mapping"
    [[ ${_failed}  -gt 0 ]] && _summary+=", ${_failed} failed"
    log_step "Done" "formulae — ${_summary}"
}

# Reads brew_casks.txt and installs available Linux GUI equivalents.
# Handles claude-code@latest and codex specially via npm.
_linux_install_casks() {
    local list="${DOTFILES_DIR}/brew/brew_casks.txt"
    if [[ ! -f "${list}" ]]; then
        log_warn "Cask list not found: ${list} (skipped)"; return 0
    fi
    log_step "Installing" "cask equivalents via ${_LINUX_DISTRO} package manager"

    local cask pkg
    local _installed=0 _nomap=0 _failed=0
    while IFS= read -r cask; do
        [[ -z "${cask}" || "${cask}" == \#* ]] && continue

        # claude-code@latest and codex → npm install
        case "${cask}" in
            claude-code@latest)
                if command -v npm &>/dev/null; then
                    if command -v claude &>/dev/null; then
                        log_info "claude already installed (skipped)"
                    elif [[ "${DRY_RUN}" == "true" ]]; then
                        log_info "[dry-run] npm install -g @anthropic-ai/claude-code"
                        (( _installed++ )) || true
                    else
                        log_step "npm" "install -g @anthropic-ai/claude-code"
                        if npm install -g @anthropic-ai/claude-code; then
                            (( _installed++ )) || true
                        else
                            log_warn "Failed to install claude-code via npm"
                            (( _failed++ )) || true
                        fi
                    fi
                else
                    log_warn "npm not found — skipping claude-code@latest (install nodejs first)"
                    (( _nomap++ )) || true
                fi
                continue
                ;;
            codex)
                if command -v npm &>/dev/null; then
                    if command -v codex &>/dev/null; then
                        log_info "codex already installed (skipped)"
                    elif [[ "${DRY_RUN}" == "true" ]]; then
                        log_info "[dry-run] npm install -g @openai/codex"
                        (( _installed++ )) || true
                    else
                        log_step "npm" "install -g @openai/codex"
                        if npm install -g @openai/codex; then
                            (( _installed++ )) || true
                        else
                            log_warn "Failed to install codex via npm"
                            (( _failed++ )) || true
                        fi
                    fi
                else
                    log_warn "npm not found — skipping codex (install nodejs first)"
                    (( _nomap++ )) || true
                fi
                continue
                ;;
        esac

        # Use || true to prevent set -e from aborting when the cask has no mapping.
        pkg="$(_linux_pkg_for_cask "${cask}" "${_LINUX_DISTRO}")" || true
        if [[ -z "${pkg}" ]]; then
            (( _nomap++ )) || true
            log_info "no Linux equivalent for cask: ${cask} — skipping"
            continue
        fi
        if _linux_install_pkg "${pkg}"; then
            (( _installed++ )) || true
        else
            log_warn "failed to install ${pkg} (cask: ${cask}) — skipping"
            (( _failed++ )) || true
        fi
    done < "${list}"

    local _summary="installed/updated ${_installed}"
    [[ ${_nomap}   -gt 0 ]] && _summary+=", ${_nomap} no Linux equivalent"
    [[ ${_failed}  -gt 0 ]] && _summary+=", ${_failed} failed"
    log_step "Done" "casks — ${_summary}"
}

# ── Terminal selection ────────────────────────────────────────────────────────
select_terminal() {
    [[ -n "${TERMINAL_CHOICE}" ]] && { log_info "terminal pre-selected: ${TERMINAL_CHOICE}"; return 0; }

    if [[ -d "/Applications/Ghostty.app" ]]; then
        TERMINAL_CHOICE="ghostty"
        log_info "Ghostty already installed — using ghostty"
        return 0
    fi
    if [[ -d "/Applications/kitty.app" ]]; then
        TERMINAL_CHOICE="kitty"
        log_info "kitty already installed — using kitty"
        return 0
    fi
    if [[ -d "/Applications/iTerm.app" ]]; then
        TERMINAL_CHOICE="iterm2"
        log_info "iTerm2 already installed — using iterm2"
        return 0
    fi

    if [[ ! -t 0 ]]; then
        log_info "Non-interactive session — defaulting to Ghostty"
        TERMINAL_CHOICE="ghostty"
        return 0
    fi

    printf '\n'
    printf '    %s\n' "Select a terminal emulator to install:"
    printf '    %s\n' "  [1] Ghostty  (default)"
    printf '    %s\n' "  [2] kitty"
    printf '    %s\n' "  [3] iTerm2"
    printf '\n'
    printf '    %s' "Choice [1/2/3] (auto-selects Ghostty in 30 s): "

    local choice=""
    if read -t 30 -r choice 2>/dev/null; then
        :
    else
        printf '\n'
        log_info "Timeout — defaulting to Ghostty"
    fi

    case "${choice}" in
        2) TERMINAL_CHOICE="kitty"   ; log_step "Selected" "kitty" ;;
        3) TERMINAL_CHOICE="iterm2"  ; log_step "Selected" "iTerm2" ;;
        *) TERMINAL_CHOICE="ghostty" ; log_step "Selected" "Ghostty (default)" ;;
    esac
}

# ── Preflight: remove non-full ffmpeg / imagemagick ───────────────────────────
# Yazi requires ffmpeg-full and imagemagick-full.
# The plain (non-full) variants conflict with the -full taps.
preflight_brew_conflicts() {
    log_step "Checking" "for conflicting non-full packages"

    local -a pairs=("ffmpeg:ffmpeg-full" "imagemagick:imagemagick-full")

    for pair in "${pairs[@]}"; do
        local plain="${pair%%:*}"
        local full="${pair##*:}"

        if brew list "${plain}" &>/dev/null 2>&1; then
            log_warn "${plain} is installed — ${full} is required for Yazi"
            log_step "Removing" "brew uninstall --ignore-dependencies ${plain}"
            run brew uninstall --ignore-dependencies "${plain}" \
                || log_warn "Failed to remove ${plain} — continuing anyway"
        else
            log_info "${plain} not present — no conflict"
        fi
    done
}

# ── Claude Code preflight ─────────────────────────────────────────────────────
# If claude is installed but NOT via claude-code@latest, offer to reinstall.
# Defaults to No; times out to No so the script never hangs in non-interactive
# or unattended runs.
preflight_claude_code() {
    log_step "Checking" "Claude Code installation"

    if ! command -v claude &>/dev/null; then
        log_info "claude not found — will be installed from cask list"
        return 0
    fi

    if brew list --cask claude-code@latest &>/dev/null 2>&1; then
        log_info "claude-code@latest already installed"
        return 0
    fi

    local current_version
    current_version="$(claude --version 2>/dev/null | head -1 || echo "unknown")"

    log_warn "claude (${current_version}) is installed, but not via claude-code@latest"
    printf '\n'
    printf '    %s\n' "claude-code@latest always tracks the newest release automatically."
    printf '    %s\n' "Note: Claude Code updates very frequently."
    printf '\n'

    if [[ ! -t 0 ]]; then
        log_info "Non-interactive session — skipping Claude Code reinstall"
        return 0
    fi

    printf '    %s' "Reinstall via claude-code@latest? [y/N] (auto-selects N in 30 s): "

    local choice=""
    if ! read -t 30 -r choice 2>/dev/null; then
        printf '\n'
        log_info "Timeout — skipping Claude Code reinstall"
        return 0
    fi
    printf '\n'

    case "${choice}" in
        [yY]|[yY][eE][sS])
            log_step "Removing" "existing Claude Code installations"
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[dry-run] npm uninstall -g @anthropic-ai/claude-code"
                log_info "[dry-run] brew uninstall --cask claude"
                log_info "[dry-run] brew uninstall --cask claude-code"
                log_info "[dry-run] brew cleanup --prune=all"
                log_info "[dry-run] brew install --cask claude-code@latest"
            else
                npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
                brew uninstall --cask claude      2>/dev/null || true
                brew uninstall --cask claude-code 2>/dev/null || true
                brew cleanup --prune=all
                log_step "Installing" "claude-code@latest"
                brew install --cask claude-code@latest \
                    || log_warn "Failed to install claude-code@latest"
            fi
            ;;
        *)
            log_info "Skipped — keeping current Claude Code installation"
            ;;
    esac
}

# ── Package list installer ────────────────────────────────────────────────────
_brew_install_list() {
    local kind="$1"
    local list="$2"

    if [[ ! -f "${list}" ]]; then
        log_warn "Package list not found: ${list} (skipped)"
        return 0
    fi

    log_step "Installing" "Homebrew ${kind}s from $(basename "${list}")"

    local -a _skip_casks=()
    if [[ "${kind}" == "cask" ]]; then
        local -a _all_terminals=("ghostty" "kitty" "iterm2")
        local _t
        for _t in "${_all_terminals[@]}"; do
            [[ "${_t}" != "${TERMINAL_CHOICE}" ]] && _skip_casks+=("${_t}")
        done
    fi

    local _list_flag="--formula"
    local _install_flag=""
    if [[ "${kind}" == "cask" ]]; then
        _list_flag="--cask"
        _install_flag="--cask"
    fi

    local pkg _skip _s
    local _skipped=0 _already=0 _installed=0 _failed=0
    while IFS= read -r pkg; do
        [[ -z "${pkg}" || "${pkg}" == \#* ]] && continue

        _skip=false
        if [[ ${#_skip_casks[@]} -gt 0 ]]; then
            for _s in "${_skip_casks[@]}"; do
                [[ "${pkg}" == "${_s}" ]] && _skip=true && break
            done
        fi
        if [[ "${_skip}" == "true" ]]; then
            (( _skipped++ )) || true
            continue
        fi

        if brew list "${_list_flag}" "${pkg}" &>/dev/null 2>&1; then
            (( _already++ )) || true
        elif [[ "${DRY_RUN}" == "true" ]]; then
            log_info "[dry-run] brew install ${_install_flag:+${_install_flag} }${pkg}"
        else
            log_step "brew" "install ${_install_flag:+${_install_flag} }${pkg}"
            if brew install ${_install_flag:+${_install_flag}} "${pkg}"; then
                (( _installed++ )) || true
            else
                log_warn "failed to install ${kind}: ${pkg} (skipping)"
                (( _failed++ )) || true
            fi
        fi
    done < "${list}"

    local _summary="installed ${_installed}, skipped ${_already} already-installed"
    [[ ${_skipped}  -gt 0 ]] && _summary+=", ${_skipped} excluded"
    [[ ${_failed}   -gt 0 ]] && _summary+=", ${_failed} failed"
    log_step "Done" "${_summary}"
}

# ── Main — Linux ──────────────────────────────────────────────────────────────
_main_linux() {
    printf '\n'
    log_step "Starting" "Linux package installation (distro: ${_LINUX_DISTRO})"
    [[ "${DRY_RUN}" == "true" ]] && log_warn "Dry-run mode — no changes will be made"

    if [[ "${_LINUX_DISTRO}" == "unknown" ]]; then
        log_warn "Could not detect Linux distro — automatic installation not supported"
        log_info "Manually install the tools listed in brew/brew_formulae.txt"
        return 0
    fi

    _linux_install_formulae
    _linux_install_casks

    log_success "Linux packages processed — restart your shell if PATH changed"
}

# ── Main — macOS ───────────────────────────────────────────────────────────────
main() {
    if [[ "${_IS_MACOS}" != "true" ]]; then
        _main_linux
        return 0
    fi

    printf '\n'
    log_step "Starting" "Homebrew package installation"
    [[ "${DRY_RUN}" == "true" ]] && log_warn "Dry-run mode — no changes will be made"

    if ! command -v brew &>/dev/null; then
        if [[ -n "${HOMEBREW_PREFIX}" && -x "${HOMEBREW_PREFIX}/bin/brew" ]]; then
            eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
        else
            die "Homebrew not found. Install it first: https://brew.sh"
        fi
    fi

    run brew update --quiet || log_warn "brew update failed — continuing with cached formula list"

    if ! brew tap | grep -q "nikitabobko/tap"; then
        log_step "brew" "tap nikitabobko/tap  (required for aerospace)"
        run brew tap nikitabobko/tap \
            || log_warn "tap nikitabobko/tap failed — aerospace install may fail"
    else
        log_info "tap nikitabobko/tap already active"
    fi

    preflight_brew_conflicts
    preflight_claude_code
    select_terminal

    _brew_install_list "formula" "${DOTFILES_DIR}/brew/brew_formulae.txt"
    _brew_install_list "cask"    "${DOTFILES_DIR}/brew/brew_casks.txt"

    log_success "all packages installed — restart your shell if PATH changed"
}

main "$@"

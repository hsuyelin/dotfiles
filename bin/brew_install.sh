#!/usr/bin/env bash

# ============================================================
# brew_install.sh — Standalone Homebrew package installer
# ============================================================
# Usage:
#   bash brew_install.sh [--dry-run] [--terminal=ghostty|kitty|iterm2]
#
# Installs all formulae and casks declared in:
#   ~/.config/brew/brew_formulae.txt
#   ~/.config/brew/brew_casks.txt
#
# Safe to re-run: already-installed packages are skipped.
# The AeroSpace tap (nikitabobko/tap) is added automatically.
# Non-full ffmpeg / imagemagick are removed before install
# because Yazi requires the -full variants.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"
readonly DOTFILES_DIR
readonly HOMEBREW_PREFIX="/opt/homebrew"

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
    local _install_flag="--formula"
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
            log_info "[dry-run] brew install ${_install_flag} ${pkg}"
        else
            log_step "brew" "install ${_install_flag} ${pkg}"
            if brew install "${_install_flag}" "${pkg}"; then
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

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    printf '\n'
    log_step "Starting" "Homebrew package installation"
    [[ "${DRY_RUN}" == "true" ]] && log_warn "Dry-run mode — no changes will be made"
    printf '\n'

    if ! command -v brew &>/dev/null; then
        if [[ -x "${HOMEBREW_PREFIX}/bin/brew" ]]; then
            eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
        else
            die "Homebrew not found. Install it first: https://brew.sh"
        fi
    fi

    run brew update --quiet

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

    printf '\n'
    log_success "all packages installed — restart your shell if PATH changed"
    printf '\n'
}

main "$@"

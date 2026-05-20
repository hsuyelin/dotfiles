#!/usr/bin/env bash
# ============================================================
# bootstrap.sh — Full system setup for macOS (Apple Silicon)
# ============================================================
# Usage:
#   bash bootstrap.sh [--dry-run] [--skip-rvm]
#
# On a brand-new machine:
#   curl -fsSL <raw-url>/bootstrap.sh | bash
# Or after manually placing this file:
#   bash bootstrap.sh
#
# Environment variables (optional, set before running):
#   DOTFILES_REPO   Git URL of the dotfiles repository.
#                   Required only when ~/.config is not yet a git repo.
#                   Example: DOTFILES_REPO=https://github.com/you/dotfiles
#
# Steps:
#   1.  Verify platform is macOS on Apple Silicon (ARM64)
#   2.  Check bootstrap prerequisites (curl, git)
#   3.  Install Xcode Command Line Tools
#   4.  Install Homebrew
#   5.  Clone dotfiles repository to ~/.config (if not present)
#   6.  Run install.sh (XDG dirs, zshenv, placeholders, plugins)
#   7.  Install Homebrew formulae from brew/brew_formulae.txt
#   8.  Install Homebrew casks from brew/brew_casks.txt
#   9.  Install RVM (Ruby Version Manager)
#   10. Print next steps

set -euo pipefail

# ── Script location ──────────────────────────────────────────────────────────
# When executed via pipe (curl | bash) or process substitution (bash <(...)),
# BASH_SOURCE[0] is empty, "bash", or a pseudo-filesystem path (/dev/fd/N,
# /dev/stdin, /proc/self/fd/N, etc.). Resolve the directory first, then
# reject any path under /dev or /proc and fall back to the canonical location.
_detect_script_dir() {
    local src="${BASH_SOURCE[0]:-}"
    [[ -z "${src}" || "${src}" == "bash" ]] && { printf '%s' "${HOME}/.config"; return; }
    local dir
    dir="$(cd "$(dirname "${src}")" 2>/dev/null && pwd)" \
        || { printf '%s' "${HOME}/.config"; return; }
    case "${dir}" in
        /dev/*|/proc/*) printf '%s' "${HOME}/.config" ;;
        *)              printf '%s' "${dir}" ;;
    esac
}
SCRIPT_DIR="$(_detect_script_dir)"
unset -f _detect_script_dir
readonly SCRIPT_DIR
readonly DOTFILES_DIR="${SCRIPT_DIR}"

# ── Runtime constants ────────────────────────────────────────────────────────
HOMEBREW_PREFIX="/opt/homebrew"
readonly HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly DOTFILES_TARGET="${HOME}/.config"
readonly INSTALL_SCRIPT="${DOTFILES_TARGET}/install.sh"

# ── Colors (disabled when stdout is not a TTY) ───────────────────────────────
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

# ── Logging (cargo-style: 12-char right-aligned verb) ────────────────────────
log_step() {    printf "${BOLD}${GREEN}%12s${NC} %s\n"  "$1" "$2"; }
log_info() {    printf "${BOLD}${CYAN}%12s${NC} %s\n"   "Info" "$1"; }
log_warn() {    printf "${BOLD}${YELLOW}%12s${NC} %s\n" "Warning" "$1"; }
log_error() {   printf "${BOLD}${RED}%12s${NC} %s\n"    "Error" "$1" >&2; }
log_success() { printf "${BOLD}${GREEN}%12s${NC} %s\n"  "Finished" "$1"; }
die() {         log_error "$1"; exit 1; }

# ── Dry-run support ───────────────────────────────────────────────────────────
DRY_RUN=false
SKIP_RVM=false
TERMINAL_CHOICE=""   # empty = prompt at runtime; set via --terminal=ghostty|kitty|iterm2

for _arg in "$@"; do
    case "${_arg}" in
        --dry-run)           DRY_RUN=true ;;
        --skip-rvm)          SKIP_RVM=true ;;
        --terminal=*)
            _term="$(echo "${_arg#--terminal=}" | tr '[:upper:]' '[:lower:]')"
            case "${_term}" in
                ghostty)      TERMINAL_CHOICE="ghostty" ;;
                kitty)        TERMINAL_CHOICE="kitty" ;;
                iterm2|iterm) TERMINAL_CHOICE="iterm2" ;;
            esac
            ;;
        -h|--help)
            printf 'Usage: %s [--dry-run] [--skip-rvm] [--terminal=ghostty|kitty|iterm2]\n\n' \
                "$(basename "$0")"
            printf 'Full system setup for macOS (Apple Silicon).\n\n'
            printf 'Options:\n'
            printf '  --dry-run              Print what would happen without executing.\n'
            printf '  --skip-rvm             Skip the RVM installation step.\n'
            printf '  --terminal=ghostty     Install Ghostty (default).\n'
            printf '  --terminal=kitty       Install kitty instead of Ghostty.\n'
            printf '  --terminal=iterm2      Install iTerm2 instead of Ghostty.\n'
            printf '  -h, --help             Show this help message.\n'
            exit 0
            ;;
        *)
            printf '%s: unknown argument: %s\n' "$(basename "$0")" "${_arg}" >&2
            exit 1
            ;;
    esac
done
unset _arg _term
readonly DRY_RUN SKIP_RVM

run() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] $*"
    else
        "$@"
    fi
}

# ── Early XDG environment ─────────────────────────────────────────────────────
# Export XDG vars now so any tool invoked later (rustup, cargo, go, pip…)
# writes to the correct XDG locations rather than $HOME dot-directories.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-${HOME}/.local/xdg-runtime}"

# Rust — point cargo/rustup at XDG before any rustup invocation
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"

# Go — point workspace at XDG
export GOPATH="${XDG_DATA_HOME}/go"

# CocoaPods — XDG home
export CP_HOME_DIR="${XDG_DATA_HOME}/cocoapods"

# ── Step 1: Platform check ────────────────────────────────────────────────────
check_platform() {
    log_step "Checking" "platform"

    if [[ "$(uname)" != "Darwin" ]]; then
        die "This script targets macOS only (detected: $(uname))"
    fi

    local arch
    arch="$(uname -m)"
    if [[ "${arch}" != "arm64" ]]; then
        die "Expected Apple Silicon (arm64), detected: ${arch}. Exiting."
    fi

    log_info "macOS $(sw_vers -productVersion) on ${arch}"
}

# ── Step 2: Bootstrap prerequisites ──────────────────────────────────────────
# Only curl is required before Xcode CLT is installed — it ships with every
# macOS release at /usr/bin/curl. git is provided by Xcode CLT, which is
# installed in the next step, so we must not require it here.
check_prerequisites() {
    log_step "Checking" "bootstrap prerequisites"

    if command -v curl &>/dev/null; then
        log_info "curl available: $(command -v curl)"
    else
        die "curl not found — this is unexpected on macOS. Investigate manually."
    fi
}

# ── Step 3: Xcode Command Line Tools ─────────────────────────────────────────
install_xcode_clt() {
    log_step "Checking" "Xcode Command Line Tools"

    if xcode-select -p &>/dev/null; then
        log_info "Already installed at $(xcode-select -p)"
        return 0
    fi

    log_step "Installing" "Xcode Command Line Tools (interactive)"
    log_warn "A system dialog will appear — click Install and wait for it to finish."

    # Trigger the GUI installer
    xcode-select --install 2>/dev/null || true

    # Poll until the tools are available (installation is async)
    log_info "Waiting for installation to complete..."
    local timeout=600  # 10 minutes
    local elapsed=0
    until xcode-select -p &>/dev/null; do
        sleep 5
        elapsed=$((elapsed + 5))
        if [[ ${elapsed} -ge ${timeout} ]]; then
            die "Timed out waiting for Xcode CLT. Re-run bootstrap.sh after installation."
        fi
    done

    log_step "Installed" "Xcode CLT at $(xcode-select -p)"
}

# ── Step 4: Homebrew ──────────────────────────────────────────────────────────
install_homebrew() {
    log_step "Checking" "Homebrew"

    if command -v brew &>/dev/null; then
        log_info "Already installed at $(command -v brew)"
        # Ensure the current shell session can find brew (Apple Silicon path)
        eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv 2>/dev/null)" || true
        return 0
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] would install Homebrew from ${HOMEBREW_INSTALL_URL}"
        return 0
    fi

    log_step "Installing" "Homebrew"
    /bin/bash -c "$(curl -fsSL "${HOMEBREW_INSTALL_URL}")"

    # Add Homebrew to PATH for the remainder of this session
    eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
    log_step "Installed" "Homebrew $(brew --version | head -1)"
}

# ── Step 5: Clone dotfiles ────────────────────────────────────────────────────
# Detection strategy: a .dotfiles-marker file in the repo root is the canonical
# signal that ~/.config is already this dotfiles installation. Any ~/.config
# directory without that marker is treated as the user's pre-existing config
# and is renamed to ~/.config.bak before cloning.
clone_dotfiles() {
    log_step "Checking" "dotfiles at ${DOTFILES_TARGET}"

    # Case 1: marker present → already installed, nothing to do.
    if [[ -f "${DOTFILES_TARGET}/.dotfiles-marker" ]]; then
        log_info "Dotfiles already installed (marker found) — skipping clone"
        return 0
    fi

    # Case 2: ~/.config exists but belongs to someone else → back it up.
    if [[ -d "${DOTFILES_TARGET}" ]]; then
        local backup="${HOME}/.config.bak"
        if [[ -e "${backup}" ]]; then
            die "${backup} already exists. Remove it manually, then re-run."
        fi
        log_warn "~/.config exists but is not this dotfiles install."
        log_step "Backing up" "~/.config → ~/.config.bak"
        run mv "${DOTFILES_TARGET}" "${backup}"
    fi

    # Case 3: ~/.config does not exist → clone fresh.
    local repo="${DOTFILES_REPO:-}"
    if [[ -z "${repo}" ]]; then
        log_warn "DOTFILES_REPO is not set — cannot clone automatically."
        log_warn "Clone your dotfiles to ~/.config manually, then re-run."
        log_warn "  git clone <your-repo-url> ~/.config"
        return 0
    fi

    log_step "Cloning" "${repo} → ${DOTFILES_TARGET}"
    run git clone --quiet "${repo}" "${DOTFILES_TARGET}"
}

# ── Terminal selection ────────────────────────────────────────────────────────
# Runs before install.sh and brew cask installation so both can use the result.
select_terminal() {
    log_step "Selecting" "terminal emulator"

    if [[ -n "${TERMINAL_CHOICE}" ]]; then
        log_info "Terminal pre-selected via flag: ${TERMINAL_CHOICE}"
        return 0
    fi

    if [[ -d "/Applications/Ghostty.app" ]]; then
        log_info "Ghostty already installed — skipping selection"
        TERMINAL_CHOICE="ghostty"; return 0
    fi
    if [[ -d "/Applications/kitty.app" ]]; then
        log_info "kitty already installed — skipping selection"
        TERMINAL_CHOICE="kitty"; return 0
    fi
    if [[ -d "/Applications/iTerm.app" ]]; then
        log_info "iTerm2 already installed — skipping selection"
        TERMINAL_CHOICE="iterm2"; return 0
    fi

    if [[ ! -t 0 ]]; then
        log_info "Non-interactive session — defaulting to Ghostty"
        TERMINAL_CHOICE="ghostty"; return 0
    fi

    printf '\n'
    printf '    %s\n' "Select a terminal emulator:"
    printf '    %s\n' "  [1] Ghostty  (default — cursor shaders, quick terminal, full feature set)"
    printf '    %s\n' "  [2] kitty    (alternative — Catppuccin Mocha, compatible keybinds)"
    printf '    %s\n' "  [3] iTerm2   (classic — import iterm2/Catppuccin-Mocha.itermcolors)"
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

# ── Step 5: Run install.sh ────────────────────────────────────────────────────
run_install_sh() {
    if [[ ! -f "${INSTALL_SCRIPT}" ]]; then
        log_warn "install.sh not found at ${INSTALL_SCRIPT} — skipping dotfiles setup"
        return 0
    fi

    log_step "Running" "install.sh"

    local args=()
    [[ "${DRY_RUN}" == "true" ]] && args+=("--dry-run")
    # Pass the terminal choice so install.sh skips its own prompt
    [[ -n "${TERMINAL_CHOICE}" ]] && args+=("--terminal=${TERMINAL_CHOICE}")

    bash "${INSTALL_SCRIPT}" "${args[@]+"${args[@]}"}"
}

# ── Step 7 & 8: Homebrew packages ────────────────────────────────────────────
# Reads line-by-line from a text file, skipping blank lines and # comments.
_brew_install_list() {
    local kind="$1"   # formula | cask
    local list="$2"   # path to text file

    if [[ ! -f "${list}" ]]; then
        log_warn "Package list not found: ${list} (skipped)"
        return 0
    fi

    log_step "Installing" "Homebrew ${kind}s from $(basename "${list}")"

    # When installing casks, only install the selected terminal emulator.
    # Collect the set of skipped terminals so the loop can skip them.
    local -a _skip_casks=()
    if [[ "${kind}" == "cask" ]]; then
        local _all_terminals=("ghostty" "kitty" "iterm2")
        local _t
        for _t in "${_all_terminals[@]}"; do
            [[ "${_t}" != "${TERMINAL_CHOICE}" ]] && _skip_casks+=("${_t}")
        done
    fi

    local pkg
    while IFS= read -r pkg; do
        # Skip blank lines and comment lines
        [[ -z "${pkg}" || "${pkg}" == \#* ]] && continue

        # Skip terminals that were not selected (install.sh handles the chosen one)
        local _skip=false
        local _s
        for _s in "${_skip_casks[@]+"${_skip_casks[@]}"}"; do
            [[ "${pkg}" == "${_s}" ]] && _skip=true && break
        done
        if [[ "${_skip}" == "true" ]]; then
            log_info "skipped (not selected terminal): ${pkg}"
            continue
        fi

        if brew list "${pkg}" &>/dev/null 2>&1; then
            log_info "already installed: ${pkg}"
        else
            log_step "brew" "install ${kind:+--${kind} }${pkg}"
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[dry-run] brew install ${kind:+--${kind} }${pkg}"
            elif [[ "${kind}" == "cask" ]]; then
                brew install --cask "${pkg}" \
                    || log_warn "failed to install cask: ${pkg} (skipping)"
            else
                brew install "${pkg}" \
                    || log_warn "failed to install formula: ${pkg} (skipping)"
            fi
        fi
    done < "${list}"
}

_preflight_brew_conflicts() {
    log_step "Checking" "for conflicting non-full packages"

    # Yazi requires ffmpeg-full and imagemagick-full.
    # The plain variants conflict with the -full formulae at link time.
    local -a pairs=("ffmpeg:ffmpeg-full" "imagemagick:imagemagick-full")

    for pair in "${pairs[@]}"; do
        local plain="${pair%%:*}"
        local full="${pair##*:}"
        if brew list "${plain}" &>/dev/null 2>&1; then
            log_warn "${plain} installed — ${full} is required for Yazi"
            log_step "Removing" "brew uninstall --ignore-dependencies ${plain}"
            run brew uninstall --ignore-dependencies "${plain}" \
                || log_warn "Failed to remove ${plain} — continuing"
        else
            log_info "no conflict: ${plain} not present"
        fi
    done
}

install_brew_packages() {
    log_step "Checking" "Homebrew package lists"

    if ! command -v brew &>/dev/null; then
        log_warn "brew not found — skipping package installation"
        return 0
    fi

    run brew update --quiet

    # aerospace (tiling WM) lives in a third-party tap
    if ! brew tap | grep -q "nikitabobko/tap"; then
        log_step "brew" "tap nikitabobko/tap (required for aerospace)"
        run brew tap nikitabobko/tap || log_warn "tap nikitabobko/tap failed (skipping)"
    fi

    _preflight_brew_conflicts

    _brew_install_list "formula" "${DOTFILES_DIR}/brew/brew_formulae.txt"
    _brew_install_list "cask"    "${DOTFILES_DIR}/brew/brew_casks.txt"
}

# ── Step 9: RVM ───────────────────────────────────────────────────────────────
install_rvm() {
    log_step "Checking" "RVM"

    if [[ "${SKIP_RVM}" == "true" ]]; then
        log_info "Skipped (--skip-rvm)"
        return 0
    fi

    local rvm_install="${DOTFILES_DIR}/rvm/install_rvm.sh"
    if [[ ! -f "${rvm_install}" ]]; then
        log_warn "rvm/install_rvm.sh not found — skipping RVM setup"
        return 0
    fi

    log_step "Running" "rvm/install_rvm.sh"
    local args=()
    [[ "${DRY_RUN}" == "true" ]] && args+=("--dry-run")
    bash "${rvm_install}" "${args[@]+"${args[@]}"}"
}

# ── Step 10: Next steps ───────────────────────────────────────────────────────
print_next_steps() {
    printf '\n'
    log_success "bootstrap complete — restart your terminal to load the new shell"
    printf '\n'
    printf '%s\n' "  Next steps:"
    printf '%s\n' "  ─────────────────────────────────────────────────────────"
    printf '%s\n' "  ☐  Set up SSH keys for GitHub / work remotes"
    printf '%s\n' "  ☐  Add a remote to your dotfiles repo:"
    printf '%s\n' "       cd ~/.config && git remote add origin <url>"
    printf '%s\n' "  ☐  Fill in ~/.config/private/git.config   (name, email)"
    printf '%s\n' "  ☐  Fill in ~/.config/secrets/.env.secrets (env secrets)"
    printf '%s\n' "  ☐  Fill in ~/.config/secrets/.ai.secrets  (AI keys)"
    printf '%s\n' "  ☐  Install a Ruby version: rvminstall <version>"
    printf '%s\n' "       Example: rvminstall 3.3.7"
    printf '%s\n' "  ☐  Open tmux and press <prefix>+I to install plugins"
    printf '%s\n' "  ☐  Open Neovim — plugins install automatically on first run"
    printf '%s\n' "       (vim.pack built-in manager; Neovim ≥ 0.11)"
    printf '%s\n' "       Force resync: nvim -c 'lua vim.pack.update()'"
    if [[ "${TERMINAL_CHOICE}" == "kitty" ]]; then
        printf '%s\n' "  ☐  Open kitty — config lives in ~/.config/kitty/"
    elif [[ "${TERMINAL_CHOICE}" == "iterm2" ]]; then
        printf '%s\n' "  ☐  Open iTerm2 → Preferences → Profiles → Colors → Color Presets…"
        printf '%s\n' "       Import: ~/.config/iterm2/Catppuccin-Mocha.itermcolors"
    else
        printf '%s\n' "  ☐  Open Ghostty — cursor shaders load from ghostty/shaders/"
    fi
    printf '%s\n' "  ☐  Sign in to Homebrew services (e.g. mas, 1Password)"
    printf '\n'
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    printf '\n'
    log_step "Starting" "bootstrap (macOS Apple Silicon)"
    [[ "${DRY_RUN}" == "true" ]] && log_warn "Dry-run mode — no changes will be made"
    [[ "${SKIP_RVM}" == "true" ]] && log_info "RVM install skipped (--skip-rvm)"

    check_platform
    install_xcode_clt   # must run before check_prerequisites: git lives in CLT
    check_prerequisites
    install_homebrew
    clone_dotfiles
    select_terminal
    install_brew_packages
    run_install_sh
    install_rvm
    print_next_steps
}

main "$@"

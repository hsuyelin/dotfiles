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
# When bootstrap.sh is piped from curl, BASH_SOURCE[0] is empty.
# In that case we fall back to the dotfiles canonical location.
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="${HOME}/.config"
fi
readonly SCRIPT_DIR
readonly DOTFILES_DIR="${SCRIPT_DIR}"

# ── Runtime constants ────────────────────────────────────────────────────────
readonly HOMEBREW_PREFIX="/opt/homebrew"
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

for _arg in "$@"; do
    case "${_arg}" in
        --dry-run)  DRY_RUN=true ;;
        --skip-rvm) SKIP_RVM=true ;;
        -h|--help)
            printf 'Usage: %s [--dry-run] [--skip-rvm]\n\n' "$(basename "$0")"
            printf 'Full system setup for macOS (Apple Silicon).\n\n'
            printf 'Options:\n'
            printf '  --dry-run   Print what would happen without executing.\n'
            printf '  --skip-rvm  Skip the RVM installation step.\n'
            printf '  -h, --help  Show this help message.\n'
            exit 0
            ;;
        *)
            printf '%s: unknown argument: %s\n' "$(basename "$0")" "${_arg}" >&2
            exit 1
            ;;
    esac
done
unset _arg
readonly DRY_RUN SKIP_RVM

run() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] $*"
    else
        "$@"
    fi
}

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
clone_dotfiles() {
    log_step "Checking" "dotfiles at ${DOTFILES_TARGET}"

    if [[ -d "${DOTFILES_TARGET}/.git" ]]; then
        log_info "Already present — skipping clone"
        return 0
    fi

    local repo="${DOTFILES_REPO:-}"
    if [[ -z "${repo}" ]]; then
        log_warn "DOTFILES_REPO is not set — cannot clone automatically."
        log_warn "Clone your dotfiles to ~/.config manually, then re-run."
        log_warn "  git clone <your-repo-url> ~/.config"
        return 0
    fi

    if [[ -d "${DOTFILES_TARGET}" ]]; then
        die "${DOTFILES_TARGET} exists but is not a git repo. Remove or back it up first."
    fi

    log_step "Cloning" "${repo} → ${DOTFILES_TARGET}"
    run git clone --quiet "${repo}" "${DOTFILES_TARGET}"
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

    bash "${INSTALL_SCRIPT}" "${args[@]}"
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

    local pkg
    while IFS= read -r pkg; do
        # Skip blank lines and comment lines
        [[ -z "${pkg}" || "${pkg}" == \#* ]] && continue

        if brew list "${pkg}" &>/dev/null 2>&1; then
            log_info "already installed: ${pkg}"
        else
            log_step "brew" "install ${kind:+--${kind} }${pkg}"
            if [[ "${kind}" == "cask" ]]; then
                run brew install --cask "${pkg}"
            else
                run brew install "${pkg}"
            fi
        fi
    done < "${list}"
}

install_brew_packages() {
    log_step "Checking" "Homebrew package lists"

    if ! command -v brew &>/dev/null; then
        log_warn "brew not found — skipping package installation"
        return 0
    fi

    run brew update --quiet

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
    bash "${rvm_install}" "${args[@]}"
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
    printf '%s\n' "  ☐  Sign in to Homebrew services (e.g. mas, 1Password)"
    printf '\n'
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    printf '\n'
    log_step "Starting" "bootstrap (macOS Apple Silicon)"
    [[ "${DRY_RUN}" == "true" ]] && log_warn "Dry-run mode — no changes will be made"
    [[ "${SKIP_RVM}" == "true" ]] && log_info "RVM install skipped (--skip-rvm)"
    printf '\n'

    check_platform
    install_xcode_clt   # must run before check_prerequisites: git lives in CLT
    check_prerequisites
    install_homebrew
    clone_dotfiles
    run_install_sh
    install_brew_packages
    install_rvm
    print_next_steps
}

main "$@"

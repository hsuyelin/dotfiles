#!/usr/bin/env bash

set -euo pipefail

# Install RVM (Ruby Version Manager) on macOS.
# Idempotent: safe to run multiple times.
#
# Usage:
#   bash install_rvm.sh [--dry-run]
#
# Prerequisites:
#   - curl  (ships with macOS)
#   - gpg   (brew install gnupg)

readonly RVM_INSTALL_URL="https://get.rvm.io"
readonly RVM_GPG_KEY_MPAPIS="https://rvm.io/mpapis.asc"
readonly RVM_GPG_KEY_PKU="https://rvm.io/pkuczynski.asc"

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

log_step()    { printf "${BOLD}${GREEN}%12s${NC} %s\n"  "$1" "$2"; }
log_info()    { printf "${BOLD}${CYAN}%12s${NC} %s\n"   "Info" "$1"; }
log_warn()    { printf "${BOLD}${YELLOW}%12s${NC} %s\n" "Warning" "$1"; }
log_error()   { printf "${BOLD}${RED}%12s${NC} %s\n"    "Error" "$1" >&2; }
log_success() { printf "${BOLD}${GREEN}%12s${NC} %s\n"  "Finished" "$1"; }
die()         { log_error "$1"; exit 1; }

DRY_RUN=false

for _arg in "$@"; do
    case "${_arg}" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            printf 'Usage: %s [--dry-run]\n\n' "$(basename "$0")"
            printf 'Install RVM (Ruby Version Manager) on macOS.\n'
            printf 'Idempotent: safe to run multiple times.\n\n'
            printf 'Options:\n'
            printf '  --dry-run   Print what would happen without executing.\n'
            printf '  -h, --help  Show this help message.\n\n'
            printf 'Prerequisites:\n'
            printf '  brew install gnupg\n'
            exit 0
            ;;
        *) die "Unknown argument: ${_arg}" ;;
    esac
done
unset _arg
readonly DRY_RUN

run() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] $*"
    else
        "$@"
    fi
}

check_prerequisites() {
    log_step "Checking" "prerequisites"

    local missing=false
    local cmd
    for cmd in curl gpg; do
        if command -v "${cmd}" &>/dev/null; then
            log_info "${cmd} available: $(command -v "${cmd}")"
        else
            log_error "required command not found: ${cmd}"
            missing=true
        fi
    done

    if [[ "${missing}" == "true" ]]; then
        die "Install gnupg first: brew install gnupg"
    fi
}

import_gpg_keys() {
    log_step "Importing" "RVM GPG signing keys"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] would import mpapis and pkuczynski GPG keys"
        return 0
    fi

    # If GNUPGHOME points to a non-existent directory (e.g. XDG path not yet
    # created), gpg cannot initialise its keyring and all imports fail.
    if [[ -n "${GNUPGHOME:-}" && ! -d "${GNUPGHOME}" ]]; then
        mkdir -p "${GNUPGHOME}"
        chmod 700 "${GNUPGHOME}"
        log_info "Created GNUPGHOME at ${GNUPGHOME}"
    fi

    curl -sSL "${RVM_GPG_KEY_MPAPIS}" | gpg --import - || \
        log_warn "mpapis key import failed — continuing anyway"
    curl -sSL "${RVM_GPG_KEY_PKU}"    | gpg --import - || \
        log_warn "pkuczynski key import failed — continuing anyway"
}

install_rvm() {
    log_step "Checking" "RVM at ${HOME}/.rvm"

    if [[ -s "${HOME}/.rvm/scripts/rvm" ]]; then
        log_info "RVM already installed — skipped"
        return 0
    fi

    log_step "Installing" "RVM stable"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] would run: curl -sSL ${RVM_INSTALL_URL} | bash -s stable"
        return 0
    fi

    \curl -sSL "${RVM_INSTALL_URL}" | bash -s stable
    log_success "RVM installed — open a new shell or: source ~/.rvm/scripts/rvm"
}

main() {
    printf '\n'
    log_step "Starting" "RVM installer"
    [[ "${DRY_RUN}" == "true" ]] && log_warn "Dry-run mode — no changes will be made"
    printf '\n'

    check_prerequisites
    if [[ -s "${HOME}/.rvm/scripts/rvm" ]]; then
        log_info "RVM already installed — skipping GPG key import and installation"
    else
        import_gpg_keys
        install_rvm
    fi

    printf '\n'
    log_success "RVM setup complete"
    printf '\n'
    printf '%s\n' "  Next steps:"
    printf '%s\n' "  ─────────────────────────────────────────────────────────"
    printf '%s\n' "  1. Open a new shell (or: source ~/.rvm/scripts/rvm)"
    printf '%s\n' "  2. Install a Ruby version:  rvminstall <version>"
    printf '%s\n' "     Example:                 rvminstall 3.3.7"
    printf '\n'
}

main "$@"

#!/usr/bin/env bash

set -euo pipefail

# Install a specific Ruby version via RVM, using Homebrew-supplied OpenSSL and
# libyaml. Idempotent: skips installation if the requested version is already
# present.
#
# Usage:
#   rvminstall <version> [--dry-run]
#   rvminstall --help
#
# Example:
#   rvminstall 3.3.7

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

TARGET_RUBY_VERSION=""
DRY_RUN=false

parse_args() {
    for _arg in "$@"; do
        case "${_arg}" in
            --dry-run) DRY_RUN=true ;;
            -h|--help)
                printf 'Usage: %s <version> [--dry-run]\n\n' "$(basename "$0")"
                printf 'Install a Ruby version via RVM with Homebrew-supplied OpenSSL and libyaml.\n\n'
                printf 'Arguments:\n'
                printf '  <version>   Ruby version to install (e.g. 3.3.7)\n\n'
                printf 'Options:\n'
                printf '  --dry-run   Print what would happen without executing.\n'
                printf '  -h, --help  Show this help message.\n\n'
                printf 'Example:\n'
                printf '  rvminstall 3.3.7\n'
                exit 0
                ;;
            -*)
                die "Unknown option: ${_arg}"
                ;;
            *)
                if [[ -n "${TARGET_RUBY_VERSION}" ]]; then
                    die "Unexpected argument: ${_arg}"
                fi
                TARGET_RUBY_VERSION="${_arg}"
                ;;
        esac
    done
    unset _arg
    readonly DRY_RUN TARGET_RUBY_VERSION
}

run() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] $*"
    else
        "$@"
    fi
}

check_prerequisites() {
    log_step "Checking" "prerequisites"

    if ! command -v brew &>/dev/null; then
        die "Homebrew is not installed. See: https://brew.sh"
    fi

    if ! command -v rvm &>/dev/null; then
        die "RVM is not installed. Run: bash ~/.config/rvm/install_rvm.sh"
    fi

    log_info "brew  $(brew --version | head -1)"
    log_info "rvm   $(rvm --version 2>&1 | head -1)"
}

ensure_brew_deps() {
    log_step "Checking" "Homebrew dependencies"

    local pkg
    for pkg in openssl@3 libyaml; do
        if brew list "${pkg}" &>/dev/null 2>&1; then
            log_info "${pkg} already installed"
        else
            log_step "Installing" "${pkg} via Homebrew"
            run brew install "${pkg}"
        fi
    done
}

install_ruby() {
    local version="$1"
    local openssl_dir libyaml_dir

    log_step "Checking" "Ruby ${version}"

    if rvm list 2>/dev/null | grep -q "${version}"; then
        log_info "Ruby ${version} already installed — skipped"
        log_info "Switch with: rvm use ${version}"
        return 0
    fi

    openssl_dir="$(brew --prefix openssl@3)"
    libyaml_dir="$(brew --prefix libyaml)"

    log_step "Configuring" "compiler environment"
    export PATH="${openssl_dir}/bin:${PATH}"
    export LDFLAGS="-L${openssl_dir}/lib -L${libyaml_dir}/lib"
    export CPPFLAGS="-I${openssl_dir}/include -I${libyaml_dir}/include"
    export PKG_CONFIG_PATH="${openssl_dir}/lib/pkgconfig:${libyaml_dir}/lib/pkgconfig"
    # Required for Ruby builds against modern Apple Clang on macOS.
    export RUBY_CFLAGS="-DUSE_FFI_CLOSURE_ALLOC"
    export optflags="-Wno-error=implicit-function-declaration"

    # Disable autolibs so RVM uses our manually specified Homebrew paths rather
    # than attempting to install system libraries itself.
    run rvm autolibs disable

    log_step "Installing" "Ruby ${version}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] would run: rvm install ${version} \\"
        log_info "         --with-libyaml-dir=${libyaml_dir} \\"
        log_info "         --with-openssl-dir=${openssl_dir}"
        return 0
    fi

    if rvm install "${version}" \
        --with-libyaml-dir="${libyaml_dir}" \
        --with-openssl-dir="${openssl_dir}"; then
        log_success "Ruby ${version} installed"
        log_info "Switch with: rvm use ${version}"
    else
        die "Ruby ${version} installation failed — check the output above"
    fi
}

main() {
    parse_args "$@"

    if [[ -z "${TARGET_RUBY_VERSION}" ]]; then
        log_error "No Ruby version specified."
        printf 'Usage: %s <version> [--dry-run]\n' "$(basename "$0")"
        printf 'Example: %s 3.3.7\n' "$(basename "$0")"
        exit 1
    fi

    # Load RVM into this shell session if not already active.
    # RVM shell functions reference unbound variables throughout — disable -u
    # for the remainder of this script once rvm is sourced.
    if [[ -s "${HOME}/.rvm/scripts/rvm" ]]; then
        set +u
        # shellcheck disable=SC1091
        source "${HOME}/.rvm/scripts/rvm"
    fi

    log_step "Starting" "Ruby ${TARGET_RUBY_VERSION} install via RVM"
    [[ "${DRY_RUN}" == "true" ]] && log_warn "Dry-run mode — no changes will be made"

    check_prerequisites
    ensure_brew_deps
    install_ruby "${TARGET_RUBY_VERSION}"

    log_success "Done"
}

main "$@"

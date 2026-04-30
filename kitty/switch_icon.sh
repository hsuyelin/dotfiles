#!/usr/bin/env bash
# ============================================================
# switch_icon.sh — Toggle kitty application icon (light / dark)
# ============================================================
# Usage:
#   bash switch_icon.sh [light|dark] [--dry-run] [--help]
#
# Without an argument, shows an interactive menu.
# Requires write access to /Applications/kitty.app (will use sudo if needed).

set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="${SCRIPT_DIR}/icons"
KITTY_APP="/Applications/kitty.app"
KITTY_ICON_TARGET="${KITTY_APP}/Contents/Resources/kitty.icns"

ICON_LIGHT="${ICONS_DIR}/kitty-light.icns"
ICON_DARK="${ICONS_DIR}/kitty-dark.icns"

# ── Colors ───────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
    YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'
else
    BOLD=''; GREEN=''; CYAN=''; YELLOW=''; RED=''; NC=''
fi

log_step() {  printf "${BOLD}${GREEN}%12s${NC} %s\n"  "$1" "$2"; }
log_info() {  printf "${BOLD}${CYAN}%12s${NC} %s\n"   "Info" "$1"; }
log_warn() {  printf "${BOLD}${YELLOW}%12s${NC} %s\n" "Warning" "$1"; }
log_error() { printf "${BOLD}${RED}%12s${NC} %s\n"    "Error" "$1" >&2; }
die() {       log_error "$1"; exit 1; }

# ── Flags ────────────────────────────────────────────────────────────────────
DRY_RUN=false
CHOICE=""

for _arg in "$@"; do
    case "${_arg}" in
        light|dark)   CHOICE="${_arg}" ;;
        --dry-run)    DRY_RUN=true ;;
        -h|--help)
            printf 'Usage: %s [light|dark] [--dry-run]\n\n' "$(basename "$0")"
            printf 'Switch the kitty application icon.\n\n'
            printf 'Arguments:\n'
            printf '  light       Install the light-mode icon.\n'
            printf '  dark        Install the dark-mode icon.\n'
            printf '  (none)      Show an interactive menu.\n\n'
            printf 'Options:\n'
            printf '  --dry-run   Show what would be done without making changes.\n'
            printf '  -h, --help  Show this help message.\n'
            exit 0
            ;;
        *)
            die "Unknown argument: ${_arg}. Run with --help for usage."
            ;;
    esac
done
unset _arg

run() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] $*"
    else
        "$@"
    fi
}

# ── Validation ───────────────────────────────────────────────────────────────
check_prerequisites() {
    [[ -d "${KITTY_APP}" ]] || die "kitty.app not found at ${KITTY_APP}"
    [[ -f "${ICON_LIGHT}" ]] || die "Missing icon: ${ICON_LIGHT}"
    [[ -f "${ICON_DARK}"  ]] || die "Missing icon: ${ICON_DARK}"
}

# ── Interactive menu ──────────────────────────────────────────────────────────
select_icon() {
    [[ -n "${CHOICE}" ]] && return 0

    printf '\n'
    printf '    %s\n' "Select kitty icon:"
    printf '    %s\n' "  [1] Dark   (matches dark desktop / Catppuccin Mocha)"
    printf '    %s\n' "  [2] Light  (matches light desktop)"
    printf '\n'
    printf '    %s' "Choice [1/2]: "

    local input=""
    read -r input
    case "${input}" in
        2) CHOICE="light" ;;
        *) CHOICE="dark"  ;;
    esac
}

# ── Apply icon ────────────────────────────────────────────────────────────────
apply_icon() {
    local src=""
    case "${CHOICE}" in
        light) src="${ICON_LIGHT}" ;;
        dark)  src="${ICON_DARK}"  ;;
        *)     die "Invalid choice: ${CHOICE}" ;;
    esac

    log_step "Applying" "${CHOICE} icon → ${KITTY_ICON_TARGET}"

    # Write access check — use sudo only if needed
    if [[ -w "${KITTY_APP}/Contents/Resources" ]]; then
        run cp -f "${src}" "${KITTY_ICON_TARGET}"
    else
        log_info "Requesting sudo to write into kitty.app bundle"
        if [[ "${DRY_RUN}" == "true" ]]; then
            log_info "[dry-run] sudo cp -f ${src} ${KITTY_ICON_TARGET}"
        else
            sudo cp -f "${src}" "${KITTY_ICON_TARGET}"
        fi
    fi

    # Refresh Dock / LaunchServices icon cache
    log_step "Refreshing" "icon cache"
    run touch "${KITTY_APP}"
    run /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -f "${KITTY_APP}" 2>/dev/null || true

    log_step "Done" "kitty icon switched to: ${CHOICE}"
    log_info "You may need to restart the Dock: killall Dock"
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    [[ "${DRY_RUN}" == "true" ]] && log_info "Dry-run mode — no changes will be made"
    check_prerequisites
    select_icon
    apply_icon
}

main

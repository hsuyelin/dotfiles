#!/usr/bin/env bash

# disktop.sh — fast, polished disk usage reports powered by dust.
# It is intentionally read-only: no deletion, no sudo, no cleanup side effects.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

LIMIT=25
DEPTH=2
MODE="all"
TARGET_MODE="auto"
MIN_SIZE=""
THREADS=""
DRY_RUN=false
NO_COLOR=false
NO_SPINNER=false
CROSS_FILESYSTEMS=false
FOLLOW_LINKS=false
APPARENT_SIZE=false
IGNORE_HIDDEN=false
SHOW_ERRORS=false
SHOW_HELP=false

BOLD=""
RED=""
YELLOW=""
GREEN=""
CYAN=""
MAGENTA=""
DIM=""
NC=""

TARGETS=()
TEMP_FILES=()
DUST_ARGS=()

FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
MESSAGES=(
    "Moonwalking..."
    "Spelunking..."
    "Cogitating..."
    "Ruminating..."
    "Percolating..."
    "Musing..."
    "Noodling..."
    "Tinkering..."
    "Synthesizing..."
    "Orchestrating..."
    "Wrangling..."
    "Unraveling..."
    "Marinating..."
    "Simmering..."
    "Brewing..."
    "Choreographing..."
    "Harmonizing..."
    "Orbiting..."
    "Crystallizing..."
    "Quantumizing..."
    "Recombobulating..."
    "Discombobulating..."
    "Flibbertigibbeting..."
    "Smooshing..."
    "Moseying..."
    "Wibbling..."
)

setup_colors() {
    if [[ "${NO_COLOR}" == "true" || ! -t 1 ]]; then
        return
    fi

    BOLD='\033[1m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    DIM='\033[2m'
    NC='\033[0m'
}

log_step() {
    printf "${BOLD}${GREEN}%12s${NC} %s\n" "$1" "$2"
}

log_info() {
    printf "${BOLD}${CYAN}%12s${NC} %s\n" "Info" "$1"
}

log_warn() {
    printf "${BOLD}${YELLOW}%12s${NC} %s\n" "Warning" "$1" >&2
}

log_error() {
    printf "${BOLD}${RED}%12s${NC} %s\n" "Error" "$1" >&2
}

log_success() {
    printf "${BOLD}${GREEN}%12s${NC} %s\n" "Finished" "$1"
}

die() {
    log_error "$1"
    exit 1
}

usage() {
    printf '%b%s%b — fast disk usage reports powered by dust\n\n' \
        "${BOLD}" "${SCRIPT_NAME}" "${NC}"
    printf 'Usage:\n'
    printf '  %s [OPTIONS] [PATH ...]\n\n' "${SCRIPT_NAME}"
    printf 'Target selection:\n'
    printf '  %-24s %s\n' '--system' 'Scan common system storage targets.'
    printf '  %-24s %s\n' '--root' 'Scan /. Explicit full-root scan.'
    printf '  %-24s %s\n' 'PATH ...' 'Scan one or more paths.'
    printf '\nOutput:\n'
    printf '  %-24s %s\n' '-n, --limit N' 'Entries to show. Default: 25.'
    printf '  %-24s %s\n' '-d, --depth N' 'Directory depth. Default: 2.'
    printf '  %-24s %s\n' '-s, --min-size SIZE' 'Hide entries smaller than SIZE.'
    printf '  %-24s %s\n' '--dirs' 'Show directories only.'
    printf '  %-24s %s\n' '--files' 'Show files only.'
    printf '  %-24s %s\n' '--all' 'Show files and directories. Default.'
    printf '\nTraversal:\n'
    printf '  %-24s %s\n' '--threads N' 'Pass thread count to dust.'
    printf '  %-24s %s\n' '--cross-filesystems' 'Allow crossing filesystem boundaries.'
    printf '  %-24s %s\n' '--follow' 'Follow symlinks.'
    printf '  %-24s %s\n' '--apparent-size' 'Use apparent size instead of disk usage.'
    printf '  %-24s %s\n' '--ignore-hidden' 'Hide hidden files and directories.'
    printf '  %-24s %s\n' '--show-errors' 'Show dust permission/read errors.'
    printf '\nUX:\n'
    printf '  %-24s %s\n' '--no-color' 'Disable color output.'
    printf '  %-24s %s\n' '--no-spinner' 'Disable spinner.'
    printf '  %-24s %s\n' '--dry-run' 'Print dust command without scanning.'
    printf '  %-24s %s\n' '-h, --help' 'Show this help.'
    printf '\nExamples:\n'
    printf '  %s\n' "${SCRIPT_NAME}"
    printf '  %s ~/Downloads\n' "${SCRIPT_NAME}"
    printf '  %s --limit 10 --depth 1 ~/Library\n' "${SCRIPT_NAME}"
    printf '%s\n' "  ${SCRIPT_NAME} --files --min-size 1G \"\$HOME\""
}

is_positive_integer() {
    [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

require_value() {
    local option="$1"
    local value="${2:-}"

    [[ -n "${value}" ]] || die "${option} requires a value."
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --system)
                TARGET_MODE="system"
                shift
                ;;
            --root)
                TARGET_MODE="root"
                shift
                ;;
            -n|--limit)
                require_value "$1" "${2:-}"
                is_positive_integer "$2" || die "$1 must be a positive integer."
                LIMIT="$2"
                shift 2
                ;;
            -d|--depth)
                require_value "$1" "${2:-}"
                is_positive_integer "$2" || die "$1 must be a positive integer."
                DEPTH="$2"
                shift 2
                ;;
            -s|--min-size)
                require_value "$1" "${2:-}"
                MIN_SIZE="$2"
                shift 2
                ;;
            --threads)
                require_value "$1" "${2:-}"
                is_positive_integer "$2" || die "$1 must be a positive integer."
                THREADS="$2"
                shift 2
                ;;
            --dirs)
                MODE="dirs"
                shift
                ;;
            --files)
                MODE="files"
                shift
                ;;
            --all)
                MODE="all"
                shift
                ;;
            --cross-filesystems)
                CROSS_FILESYSTEMS=true
                shift
                ;;
            --follow)
                FOLLOW_LINKS=true
                shift
                ;;
            --apparent-size)
                APPARENT_SIZE=true
                shift
                ;;
            --ignore-hidden)
                IGNORE_HIDDEN=true
                shift
                ;;
            --show-errors)
                SHOW_ERRORS=true
                shift
                ;;
            --no-color)
                NO_COLOR=true
                shift
                ;;
            --no-spinner)
                NO_SPINNER=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                SHOW_HELP=true
                shift
                ;;
            --)
                shift
                while [[ $# -gt 0 ]]; do
                    TARGETS+=("$1")
                    shift
                done
                ;;
            -*)
                die "Unknown option: $1"
                ;;
            *)
                TARGETS+=("$1")
                shift
                ;;
        esac
    done
}

require_dust() {
    command -v dust >/dev/null 2>&1 || {
        die "dust is required. Install it with: brew install dust"
    }
}

add_target_if_exists() {
    local target="$1"
    local existing

    [[ -e "${target}" ]] || return
    if [[ ${#TARGETS[@]} -gt 0 ]]; then
        for existing in "${TARGETS[@]}"; do
            [[ "${existing}" == "${target}" ]] && return
        done
    fi
    TARGETS+=("${target}")
}

resolve_system_targets() {
    add_target_if_exists "${HOME}"
    add_target_if_exists "/Applications"
    add_target_if_exists "/Library"
    add_target_if_exists "/opt/homebrew"
    add_target_if_exists "/usr/local"
}

resolve_targets() {
    if [[ "${TARGET_MODE}" == "root" ]]; then
        TARGETS=("/")
        return
    fi

    if [[ ${#TARGETS[@]} -gt 0 ]]; then
        return
    fi

    resolve_system_targets
}

validate_targets() {
    local target

    [[ ${#TARGETS[@]} -gt 0 ]] || die "No scan targets found."
    for target in "${TARGETS[@]}"; do
        [[ -e "${target}" ]] || die "Target does not exist: ${target}"
    done
}

join_targets() {
    local target
    local joined=""

    for target in "${TARGETS[@]}"; do
        if [[ -z "${joined}" ]]; then
            joined="${target}"
        else
            joined="${joined}, ${target}"
        fi
    done
    printf '%s' "${joined}"
}

quote_command() {
    local arg
    local first=true

    for arg in "$@"; do
        if [[ "${first}" == "true" ]]; then
            first=false
        else
            printf ' '
        fi
        printf '%q' "${arg}"
    done
}

build_dust_args() {
    DUST_ARGS=(
        dust
        --depth "${DEPTH}"
        --number-of-lines "${LIMIT}"
        --reverse
        --full-paths
        --no-progress
    )

    if [[ "${CROSS_FILESYSTEMS}" != "true" ]]; then
        DUST_ARGS+=(--limit-filesystem)
    fi
    if [[ "${NO_COLOR}" == "true" ]]; then
        DUST_ARGS+=(--no-colors)
    fi
    if [[ -n "${MIN_SIZE}" ]]; then
        DUST_ARGS+=(--min-size "${MIN_SIZE}")
    fi
    if [[ -n "${THREADS}" ]]; then
        DUST_ARGS+=(--threads "${THREADS}")
    fi
    if [[ "${FOLLOW_LINKS}" == "true" ]]; then
        DUST_ARGS+=(--dereference-links)
    fi
    if [[ "${APPARENT_SIZE}" == "true" ]]; then
        DUST_ARGS+=(--apparent-size)
    fi
    if [[ "${IGNORE_HIDDEN}" == "true" ]]; then
        DUST_ARGS+=(--ignore-hidden)
    fi
    case "${MODE}" in
        dirs)  DUST_ARGS+=(--only-dir) ;;
        files) DUST_ARGS+=(--only-file) ;;
    esac

    DUST_ARGS+=("${TARGETS[@]}")
}

new_temp_file() {
    local file

    file="$(mktemp)"
    TEMP_FILES+=("${file}")
    printf '%s' "${file}"
}

cleanup() {
    local file

    [[ ${#TEMP_FILES[@]} -gt 0 ]] || return 0
    for file in "${TEMP_FILES[@]}"; do
        [[ -n "${file}" && -e "${file}" ]] && rm -f -- "${file}"
    done
}

spinner_enabled() {
    [[ "${NO_SPINNER}" != "true" && -t 2 ]]
}

spin_until_done() {
    local pid="$1"
    local i=0
    local message_index=0
    local frame
    local message

    while kill -0 "${pid}" 2>/dev/null; do
        frame="${FRAMES[$((i % ${#FRAMES[@]}))]}"
        message="${MESSAGES[$((message_index % ${#MESSAGES[@]}))]}"
        printf '\r  %b%s%b  %b%s%b   ' \
            "${MAGENTA}" "${frame}" "${NC}" \
            "${DIM}" "${message}" "${NC}" >&2
        sleep 0.08
        i=$((i + 1))
        if (( i % 18 == 0 )); then
            message_index=$((message_index + 1))
        fi
    done
    printf '\r%80s\r' '' >&2
}

run_dust() {
    local -a command=("$@")
    local output_file
    local error_file
    local status=0
    local pid

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] $(quote_command "${command[@]}")"
        return 0
    fi

    output_file="$(new_temp_file)"
    error_file="$(new_temp_file)"

    "${command[@]}" >"${output_file}" 2>"${error_file}" &
    pid=$!

    if spinner_enabled; then
        spin_until_done "${pid}"
    fi

    if wait "${pid}"; then
        status=0
    else
        status=$?
    fi

    if [[ -s "${error_file}" ]]; then
        if [[ "${SHOW_ERRORS}" == "true" ]]; then
            printf '%s\n' "${YELLOW}dust warnings:${NC}" >&2
            cat "${error_file}" >&2
        else
            log_warn "Some paths were unreadable. Re-run with --show-errors."
        fi
    fi

    if [[ ${status} -ne 0 ]]; then
        [[ -s "${error_file}" ]] && cat "${error_file}" >&2
        die "dust exited with status ${status}."
    fi

    cat "${output_file}"
}

print_separator() {
    printf '%b%s%b\n' "${DIM}" \
        '────────────────────────────────────────────────────────' "${NC}"
}

render_report() {
    local target_label

    target_label="$(join_targets)"
    build_dust_args

    log_step "Scanning" "Disk usage targets"
    log_info "Targets: ${target_label}"
    log_info "Depth: ${DEPTH}, Limit: ${LIMIT}, Mode: ${MODE}"

    printf '\n%bTop storage usage%b\n' "${BOLD}${CYAN}" "${NC}"
    print_separator
    run_dust "${DUST_ARGS[@]}"
    printf '\n'

    log_success "Scan completed"
}

main() {
    trap cleanup EXIT INT TERM

    parse_args "$@"
    setup_colors

    if [[ "${SHOW_HELP}" == "true" ]]; then
        usage
        exit 0
    fi

    require_dust
    resolve_targets
    validate_targets
    render_report
}

main "$@"

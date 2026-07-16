#!/usr/bin/env bash

# Bootstrap the approved Herdr plugins for this dotfiles profile.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly STATE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/herdr"
readonly STATE_FILE="${STATE_DIR}/bootstrap-plugins.state"

readonly -a APPROVED_PLUGINS=(
    "herdr-lazygit|JacquesvanWyk/herdr-lazygit"
    "copy-search|qq88976321/herdr-copy-search"
    "jt.command-palette|JanTvrdik/herdr-command-palette"
    "herdr-focus-notify|yankewei/herdr-focus-notify"
    "persiyanov.reviewr|persiyanov/herdr-reviewr"
    "tdi.worktree-from-pr|tdi/herdr-worktree-from-pr"
    "herdr-jira|a2u/herdr-jira"
    "ramarivera.pretty-which|ramarivera/herdr-pretty-which"
    "herdr-floax|Tyru5/herdr-floax"
    "edi.layout-tools|edouard-andrei/herdr-layout-tools"
    "trapple.herdr-focus|trapple/herdr-focus"
    "vim-herdr-navigation|paulbkim-dev/vim-herdr-navigation"
)

DRY_RUN=false
ASSUME_YES=false
LAST_COMPLETED_STEP=0

declare -a INSTALLED_PLUGIN_IDS=()
declare -a MISSING_PLUGINS=()

COLOR_GREEN=""
COLOR_YELLOW=""
COLOR_RED=""
COLOR_RESET=""

setup_colors() {
    if [[ -t 1 ]]; then
        COLOR_GREEN=$'\033[32m'
        COLOR_YELLOW=$'\033[33m'
        COLOR_RED=$'\033[31m'
        COLOR_RESET=$'\033[0m'
    fi
}

log_status() {
    local label="$1"
    local message="$2"
    local color="${3:-${COLOR_GREEN}}"

    printf '%b%12s%b %s\n' "${color}" "${label}" "${COLOR_RESET}" "${message}"
}

log_error() {
    local message="$1"

    printf '%berror:%b %s\n' "${COLOR_RED}" "${COLOR_RESET}" "${message}" >&2
}

print_help() {
    cat <<EOF
Bootstrap the approved Herdr plugins for this dotfiles profile.

Usage:
  ${SCRIPT_NAME} [--dry-run] [--yes] [--help]

Options:
  --dry-run    Show missing plugins without installing anything.
  --yes        Install missing plugins without an interactive confirmation.
  --help, -h   Show this help message.

Safety:
  This script only installs the explicit allowlist stored in the script.
  It never runs from shell startup and never installs arbitrary plugins.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;
            --yes|-y)
                ASSUME_YES=true
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                log_error "unknown option: $1"
                print_help >&2
                exit 2
                ;;
        esac
        shift
    done
}

require_command() {
    local command_name="$1"

    if ! command -v "${command_name}" >/dev/null 2>&1; then
        log_error "required command not found: ${command_name}"
        exit 1
    fi
}

check_dependencies() {
    log_status "Checking" "required commands"
    require_command herdr
    require_command jq
}

ensure_state_dir() {
    mkdir -p "${STATE_DIR}"
}

is_non_negative_integer() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

load_resume_state() {
    local key
    local value
    local approved_count=""

    [[ -f "${STATE_FILE}" ]] || return 0

    while IFS='=' read -r key value; do
        case "${key}" in
            last_completed_step)
                if is_non_negative_integer "${value}"; then
                    LAST_COMPLETED_STEP="${value}"
                fi
                ;;
            approved_plugin_count)
                approved_count="${value}"
                ;;
        esac
    done <"${STATE_FILE}"

    if [[ "${approved_count}" != "${#APPROVED_PLUGINS[@]}" ]]; then
        LAST_COMPLETED_STEP=0
        log_status "Planning" "state file ignored after allowlist changed"
        return
    fi

    if (( LAST_COMPLETED_STEP > 0 )); then
        log_status "Resuming" "after completed step ${LAST_COMPLETED_STEP}"
    fi
}

write_state() {
    local step_index="$1"
    local plugin_id="$2"

    ensure_state_dir
    {
        printf 'last_completed_step=%s\n' "${step_index}"
        printf 'last_completed_plugin=%s\n' "${plugin_id}"
        printf 'approved_plugin_count=%s\n' "${#APPROVED_PLUGINS[@]}"
    } >"${STATE_FILE}"
}

clear_state() {
    [[ -e "${STATE_FILE}" ]] || return 0
    rm -f -- "${STATE_FILE}"
}

load_installed_plugins() {
    local plugin_id
    local plugin_ids
    local plugins_json

    log_status "Checking" "installed Herdr plugins"
    if ! plugins_json="$(herdr plugin list --json)"; then
        log_error "failed to list installed Herdr plugins"
        exit 1
    fi

    if ! plugin_ids="$(printf '%s\n' "${plugins_json}" \
        | jq -r '.result.plugins[].plugin_id')"; then
        log_error "failed to parse installed Herdr plugins"
        exit 1
    fi

    while IFS= read -r plugin_id; do
        [[ -z "${plugin_id}" ]] && continue
        INSTALLED_PLUGIN_IDS+=("${plugin_id}")
    done <<<"${plugin_ids}"
}

plugin_is_installed() {
    local plugin_id="$1"
    local installed_plugin_id

    if (( ${#INSTALLED_PLUGIN_IDS[@]} == 0 )); then
        return 1
    fi

    for installed_plugin_id in "${INSTALLED_PLUGIN_IDS[@]}"; do
        [[ "${installed_plugin_id}" == "${plugin_id}" ]] && return 0
    done
    return 1
}

collect_missing_plugins() {
    local record
    local plugin_id

    MISSING_PLUGINS=()
    for record in "${APPROVED_PLUGINS[@]}"; do
        plugin_id="${record%%|*}"
        if plugin_is_installed "${plugin_id}"; then
            log_status "Fresh" "${plugin_id} is already installed"
            continue
        fi
        MISSING_PLUGINS+=("${record}")
        log_status "Missing" "${plugin_id}" "${COLOR_YELLOW}"
    done
}

print_missing_plan() {
    local record
    local plugin_id
    local source

    if (( ${#MISSING_PLUGINS[@]} == 0 )); then
        log_status "Finished" "all approved Herdr plugins are installed"
        return
    fi

    log_status "Planning" "plugins to install: ${#MISSING_PLUGINS[@]}"
    for record in "${MISSING_PLUGINS[@]}"; do
        plugin_id="${record%%|*}"
        source="${record#*|}"
        printf '  - %s (%s)\n' "${plugin_id}" "${source}"
    done
}

confirm_installation() {
    local answer

    if [[ "${DRY_RUN}" == "true" ||
          "${ASSUME_YES}" == "true" ||
          ${#MISSING_PLUGINS[@]} -eq 0 ]]; then
        return
    fi

    printf 'Install these Herdr plugins now? [y/N] '
    read -r answer
    if [[ ! "${answer}" == [Yy]* ]]; then
        log_status "Aborted" "no plugins were installed" "${COLOR_YELLOW}"
        exit 0
    fi
}

install_plugin() {
    local step_index="$1"
    local record="$2"
    local plugin_id="${record%%|*}"
    local source="${record#*|}"

    log_status "Installing" "${plugin_id} from ${source}"
    herdr plugin install "${source}" --yes
    write_state "${step_index}" "${plugin_id}"
}

skip_completed_step() {
    local step_index="$1"
    local plugin_id="$2"

    if (( step_index > LAST_COMPLETED_STEP )); then
        return 1
    fi

    if plugin_is_installed "${plugin_id}"; then
        log_status "Skipping" "${plugin_id} completed in previous run"
        return 0
    fi

    log_status "Planning" "state for ${plugin_id} is stale; checking again"
    return 1
}

install_missing_plugins() {
    local record
    local plugin_id
    local source
    local step_index=0

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_status "Dry-run" "no plugins were installed" "${COLOR_YELLOW}"
        return
    fi

    for record in "${APPROVED_PLUGINS[@]}"; do
        (( step_index += 1 ))
        plugin_id="${record%%|*}"
        source="${record#*|}"

        if skip_completed_step "${step_index}" "${plugin_id}"; then
            continue
        fi
        if plugin_is_installed "${plugin_id}"; then
            write_state "${step_index}" "${plugin_id}"
            continue
        fi
        install_plugin "${step_index}" "${plugin_id}|${source}"
    done

    clear_state
    log_status "Finished" "Herdr plugin bootstrap completed"
}

main() {
    setup_colors
    parse_args "$@"
    check_dependencies
    load_resume_state
    load_installed_plugins
    collect_missing_plugins
    print_missing_plan
    confirm_installation
    install_missing_plugins
}

main "$@"

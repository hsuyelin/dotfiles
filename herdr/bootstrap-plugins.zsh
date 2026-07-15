#!/usr/bin/env zsh

# Bootstrap the approved Herdr plugins for this dotfiles profile.

emulate -L zsh
set -o errexit
set -o nounset
set -o pipefail

readonly SCRIPT_NAME="${0:t}"
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

typeset -g DRY_RUN=0
typeset -g ASSUME_YES=0
typeset -gA INSTALLED_PLUGIN_IDS=()
typeset -ga MISSING_PLUGINS=()

setup_colors() {
    if [[ -t 1 ]]; then
        typeset -gr COLOR_GREEN=$'\033[32m'
        typeset -gr COLOR_YELLOW=$'\033[33m'
        typeset -gr COLOR_RED=$'\033[31m'
        typeset -gr COLOR_RESET=$'\033[0m'
    else
        typeset -gr COLOR_GREEN=""
        typeset -gr COLOR_YELLOW=""
        typeset -gr COLOR_RED=""
        typeset -gr COLOR_RESET=""
    fi
}

log_status() {
    local label="$1"
    local message="$2"
    local color="${3:-${COLOR_GREEN}}"

    printf '%b%12s%b %s\n' "$color" "$label" "$COLOR_RESET" "$message"
}

log_error() {
    local message="$1"

    printf '%berror:%b %s\n' "$COLOR_RED" "$COLOR_RESET" "$message" >&2
}

print_help() {
    cat <<'EOF'
Bootstrap the approved Herdr plugins for this dotfiles profile.

Usage:
  bootstrap-plugins.zsh [--dry-run] [--yes] [--help]

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
    while (( $# > 0 )); do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                ;;
            --yes|-y)
                ASSUME_YES=1
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

    if ! command -v "$command_name" >/dev/null 2>&1; then
        log_error "required command not found: ${command_name}"
        exit 1
    fi
}

check_dependencies() {
    log_status "Checking" "required commands"
    require_command herdr
    require_command jq
}

load_installed_plugins() {
    local plugin_id

    log_status "Checking" "installed Herdr plugins"
    while IFS= read -r plugin_id; do
        [[ -z "$plugin_id" ]] && continue
        INSTALLED_PLUGIN_IDS[$plugin_id]=1
    done < <(herdr plugin list --json | jq -r '.result.plugins[].plugin_id')
}

collect_missing_plugins() {
    local record
    local plugin_id

    MISSING_PLUGINS=()
    for record in "${APPROVED_PLUGINS[@]}"; do
        plugin_id="${record%%|*}"
        if [[ -n "${INSTALLED_PLUGIN_IDS[$plugin_id]:-}" ]]; then
            log_status "Fresh" "$plugin_id is already installed"
            continue
        fi
        MISSING_PLUGINS+=("$record")
        log_status "Missing" "$plugin_id" "$COLOR_YELLOW"
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
        printf '  - %s (%s)\n' "$plugin_id" "$source"
    done
}

confirm_installation() {
    local answer

    if (( DRY_RUN == 1 || ASSUME_YES == 1 || ${#MISSING_PLUGINS[@]} == 0 )); then
        return
    fi

    printf 'Install these Herdr plugins now? [y/N] '
    read -r answer
    if [[ ! "$answer" == [Yy]* ]]; then
        log_status "Aborted" "no plugins were installed" "$COLOR_YELLOW"
        exit 0
    fi
}

ensure_state_dir() {
    mkdir -p "$STATE_DIR"
}

write_state() {
    local step_index="$1"
    local plugin_id="$2"

    ensure_state_dir
    {
        printf 'last_completed_step=%s\n' "$step_index"
        printf 'last_completed_plugin=%s\n' "$plugin_id"
        printf 'approved_plugin_count=%s\n' "${#APPROVED_PLUGINS[@]}"
    } >| "$STATE_FILE"
}

clear_state_if_complete() {
    if (( ${#MISSING_PLUGINS[@]} == 0 )); then
        return
    fi

    write_state "${#APPROVED_PLUGINS[@]}" "complete"
}

install_plugin() {
    local step_index="$1"
    local record="$2"
    local plugin_id="${record%%|*}"
    local source="${record#*|}"

    log_status "Installing" "${plugin_id} from ${source}"
    herdr plugin install "$source" --yes
    write_state "$step_index" "$plugin_id"
}

install_missing_plugins() {
    local record
    local plugin_id
    local source
    local step_index=0

    if (( DRY_RUN == 1 )); then
        log_status "Dry-run" "no plugins were installed" "$COLOR_YELLOW"
        return
    fi

    for record in "${APPROVED_PLUGINS[@]}"; do
        (( step_index += 1 ))
        plugin_id="${record%%|*}"
        source="${record#*|}"
        if [[ -n "${INSTALLED_PLUGIN_IDS[$plugin_id]:-}" ]]; then
            write_state "$step_index" "$plugin_id"
            continue
        fi
        install_plugin "$step_index" "${plugin_id}|${source}"
    done

    clear_state_if_complete
    log_status "Finished" "Herdr plugin bootstrap completed"
}

main() {
    setup_colors
    parse_args "$@"
    check_dependencies
    load_installed_plugins
    collect_missing_plugins
    print_missing_plan
    confirm_installation
    install_missing_plugins
}

main "$@"

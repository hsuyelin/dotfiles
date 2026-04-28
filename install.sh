#!/usr/bin/env bash
# ============================================================
# install.sh — Dotfiles installer for macOS (Apple Silicon)
# ============================================================
# Usage:
#   bash install.sh [--dry-run]
#
# Idempotent: safe to run multiple times. Existing secrets and
# private configs are never overwritten.
#
# Steps:
#   1.  Verify platform (macOS, ARM64)
#   2.  Verify git is available
#   3.  Back up conflicting shell config files
#   4.  Create XDG base directory tree
#   5.  Write ~/.zshenv to bootstrap ZDOTDIR
#   6.  Create placeholder files for secrets/ and private/
#   7.  Initialize tmux plugin manager (TPM)
#   8.  Clone Ghostty cursor shaders (if missing)
#   9.  Set executable permissions on bin/ scripts
#   10. Print post-install checklist

set -euo pipefail

# ── Script location ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly DOTFILES_DIR="${SCRIPT_DIR}"

# ── Runtime constants ────────────────────────────────────────────────────────
BACKUP_TIMESTAMP="$(date +%Y_%m_%d)"
readonly BACKUP_TIMESTAMP
readonly BACKUP_DIR="${HOME}/.zsh_backup_${BACKUP_TIMESTAMP}"
readonly ZSHENV_HOME="${HOME}/.zshenv"

# XDG directories to create (relative to $HOME)
readonly XDG_DIRS=(
    ".local/share"
    ".local/state"
    ".local/state/zsh"
    ".cache"
    ".local/xdg-runtime"
)

# Shell config files that may conflict on a pre-XDG machine
readonly CONFLICT_FILES=(
    "${HOME}/.zshrc"
    "${HOME}/.zprofile"
    "${HOME}/.bash_profile"
    "${HOME}/.bashrc"
)

# Placeholder files: path (relative to DOTFILES_DIR) and content marker
# Format: "rel_path|type"  type = zsh | gitconfig | ini | plain
readonly PLACEHOLDER_SPECS=(
    "secrets/.env.secrets|zsh"
    "secrets/.ai.secrets|zsh"
    "private/git.config|gitconfig"
    "private/zsh.zprofile|zsh"
    "private/spicetify.ini|ini"
)

# External repos to auto-clone when missing
readonly GHOSTTY_SHADERS_REPO="https://github.com/sahaj-b/ghostty-cursor-shaders"
readonly GHOSTTY_SHADERS_DIR="${DOTFILES_DIR}/ghostty/shaders"
readonly TPM_REPO="https://github.com/tmux-plugins/tpm"
readonly TPM_DIR="${DOTFILES_DIR}/tmux/plugins/tpm"

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

# ── Flag parsing ──────────────────────────────────────────────────────────────
DRY_RUN=false
INSTALL_RTK=true
UNINSTALL_RTK=false

for _arg in "$@"; do
    case "${_arg}" in
        --dry-run)      DRY_RUN=true ;;
        --skip-rtk)     INSTALL_RTK=false ;;
        --uninstall-rtk) UNINSTALL_RTK=true ;;
    esac
done
unset _arg

readonly DRY_RUN INSTALL_RTK UNINSTALL_RTK

# Runs a command, or prints it when in dry-run mode.
run() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] $*"
    else
        "$@"
    fi
}

# ── Step 1: Platform check ────────────────────────────────────────────────────
check_platform() {
    log_step "Checking" "platform requirements"

    if [[ "$(uname)" != "Darwin" ]]; then
        die "This script targets macOS only (detected: $(uname))"
    fi

    local arch
    arch="$(uname -m)"
    if [[ "${arch}" != "arm64" ]]; then
        log_warn "Expected Apple Silicon (arm64), detected: ${arch}"
        log_warn "Homebrew prefix /opt/homebrew may not exist on this arch."
    fi

    log_info "macOS $(sw_vers -productVersion) on ${arch}"
}

# ── Step 2: Prerequisites ─────────────────────────────────────────────────────
# Required: script cannot proceed without these.
# Optional: dotfiles will work but some features will be degraded; logged as warnings.
check_prerequisites() {
    log_step "Checking" "required tools"

    local missing_required=false

    # ── Required commands ────────────────────────────────────────────────────
    local req
    for req in git zsh curl; do
        if command -v "${req}" &>/dev/null; then
            log_info "${req} $(${req} --version 2>&1 | head -1)"
        else
            log_error "required command not found: ${req}"
            missing_required=true
        fi
    done

    if [[ "${missing_required}" == "true" ]]; then
        die "Missing required commands. Install Xcode CLT: xcode-select --install"
    fi

    # ── Optional commands (warn but do not abort) ────────────────────────────
    local opt
    for opt in brew starship fzf eza zoxide tmux nvim; do
        if ! command -v "${opt}" &>/dev/null; then
            log_warn "optional command not found: ${opt} (some features will be unavailable)"
        fi
    done
}

# ── Step 3: Back up conflicting files ────────────────────────────────────────
# ~/.zshenv is handled separately: we only back it up when it does NOT already
# contain our XDG bootstrap (to avoid nuking a correctly configured machine).
zshenv_is_ours() {
    [[ -f "${ZSHENV_HOME}" ]] \
        && grep -q 'ZDOTDIR' "${ZSHENV_HOME}" \
        && grep -q 'XDG_CONFIG_HOME' "${ZSHENV_HOME}"
}

backup_conflicts() {
    log_step "Checking" "for conflicting shell config files"

    local backed_up=false

    # Back up ~/.zshenv only when it exists and is not ours
    if [[ -f "${ZSHENV_HOME}" ]] && ! zshenv_is_ours; then
        if [[ "${DRY_RUN}" != "true" ]]; then
            mkdir -p "${BACKUP_DIR}"
        fi
        run cp -P "${ZSHENV_HOME}" "${BACKUP_DIR}/zshenv"
        log_step "Backed up" "${ZSHENV_HOME} → ${BACKUP_DIR}/zshenv"
        backed_up=true
    fi

    # Back up any remaining conflicting files that exist
    local file
    for file in "${CONFLICT_FILES[@]}"; do
        if [[ -f "${file}" || -L "${file}" ]]; then
            if [[ "${backed_up}" == "false" && "${DRY_RUN}" != "true" ]]; then
                mkdir -p "${BACKUP_DIR}"
            fi
            local name
            name="$(basename "${file}")"
            run cp -P "${file}" "${BACKUP_DIR}/${name}"
            log_step "Backed up" "${file} → ${BACKUP_DIR}/${name}"
            backed_up=true
        fi
    done

    if [[ "${backed_up}" == "true" ]]; then
        log_info "Backup directory: ${BACKUP_DIR}"
    else
        log_info "No conflicting files found"
    fi
}

# ── Step 4: XDG directory tree ────────────────────────────────────────────────
create_xdg_dirs() {
    log_step "Creating" "XDG base directories"

    local dir
    for dir in "${XDG_DIRS[@]}"; do
        run mkdir -p "${HOME}/${dir}"
    done

    log_info "XDG tree ready under ${HOME}/.local"
}

# ── Step 5: Write ~/.zshenv ───────────────────────────────────────────────────
# This file is not inside the dotfiles repo — it lives at $HOME and is the
# single entry point that sets ZDOTDIR before zsh loads anything else.
write_zshenv() {
    log_step "Checking" "~/.zshenv"

    if zshenv_is_ours; then
        log_info "~/.zshenv already configured correctly (skipped)"
        return 0
    fi

    log_step "Writing" "~/.zshenv → XDG + ZDOTDIR bootstrap"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] would write XDG bootstrap to ~/.zshenv"
        return 0
    fi

    cat > "${ZSHENV_HOME}" << 'ZSHENV'
# XDG base directory specification bootstrap.
# Managed by ~/.config/install.sh — customize in ~/.config/zsh/.zshenv instead.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-$HOME/.local/xdg-runtime}"
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"

[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
ZSHENV

    log_info "Wrote ${ZSHENV_HOME}"
}

# ── Step 6: Placeholder files for secrets and private configs ─────────────────
# These files are gitignored and must be populated manually. The install script
# creates empty-but-valid stubs so that shell sourcing does not produce errors
# on a fresh clone. Existing files are never overwritten.
_placeholder_content() {
    local type="$1"
    case "${type}" in
        zsh)
            printf '%s\n' \
                '# This file is private and not tracked in version control.' \
                '# Fill in your values. It is sourced by zsh at startup.' \
                '#' \
                '# Example:' \
                '#   export MY_SECRET_KEY=""'
            ;;
        gitconfig)
            printf '%s\n' \
                '; Private git identity — required by ~/.config/git/config.' \
                '; Fill in your details. Keep this file out of version control.' \
                ';' \
                '; [user]' \
                ';     name  = Your Name' \
                ';     email = your@email.com'
            ;;
        ini)
            printf '%s\n' \
                '# Private configuration — fill in your values.' \
                '# Keep this file out of version control.'
            ;;
        plain | *)
            printf '%s\n' \
                '# Private configuration — fill in your values.' \
                '# Keep this file out of version control.'
            ;;
    esac
}

create_placeholder_secrets() {
    log_step "Checking" "secret and private placeholder files"

    local spec
    for spec in "${PLACEHOLDER_SPECS[@]}"; do
        local rel_path="${spec%%|*}"
        local type="${spec##*|}"
        local target="${DOTFILES_DIR}/${rel_path}"

        if [[ -f "${target}" ]]; then
            log_info "exists: ${rel_path} (skipped)"
            continue
        fi

        if [[ "${DRY_RUN}" == "true" ]]; then
            log_info "[dry-run] would create placeholder: ${rel_path}"
            continue
        fi

        mkdir -p "$(dirname "${target}")"
        _placeholder_content "${type}" > "${target}"
        log_step "Created" "placeholder ${rel_path}"
    done
}

# ── Step 7: tmux plugin manager (TPM) ────────────────────────────────────────
init_tpm() {
    log_step "Checking" "tmux plugin manager (TPM)"

    if [[ -d "${TPM_DIR}" ]]; then
        log_info "TPM already present (skipped)"
        return 0
    fi

    log_step "Cloning" "TPM → ${TPM_DIR}"
    run git clone --depth=1 --quiet "${TPM_REPO}" "${TPM_DIR}"
    log_info "Run <prefix>+I inside tmux to install plugins"
}

# ── Step 8: Ghostty cursor shaders ───────────────────────────────────────────
clone_ghostty_shaders() {
    log_step "Checking" "Ghostty cursor shaders"

    if [[ -d "${GHOSTTY_SHADERS_DIR}" ]]; then
        log_info "Shaders already present (skipped)"
        return 0
    fi

    log_step "Cloning" "cursor shaders → ${GHOSTTY_SHADERS_DIR}"
    run git clone --depth=1 --quiet "${GHOSTTY_SHADERS_REPO}" \
        "${GHOSTTY_SHADERS_DIR}"
}

# ── Step 9: Executable permissions ───────────────────────────────────────────
set_permissions() {
    log_step "Permissions" "chmod +x on scripts"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] would chmod +x bin/*.sh, install.sh, bootstrap.sh"
        return 0
    fi

    local script
    while IFS= read -r -d '' script; do
        chmod +x "${script}"
    done < <(find "${DOTFILES_DIR}/bin" -type f -name "*.sh" -print0 2>/dev/null)

    [[ -f "${DOTFILES_DIR}/install.sh" ]]   && chmod +x "${DOTFILES_DIR}/install.sh"
    [[ -f "${DOTFILES_DIR}/bootstrap.sh" ]] && chmod +x "${DOTFILES_DIR}/bootstrap.sh"
}

# ── Step: RTK (Rust Token Killer) ────────────────────────────────────────────
# Installs RTK via Homebrew, runs `rtk init -g` (Claude Code hook), and
# symlinks ~/Library/Application Support/rtk → $XDG_CONFIG_HOME/rtk so the
# macOS config path is satisfied without duplicating files.
install_rtk() {
    log_step "Checking" "RTK (Rust Token Killer)"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] would brew install rtk && rtk init -g"
        return 0
    fi

    if ! command -v brew &>/dev/null; then
        log_warn "brew not found — skipping RTK install"
        return 0
    fi

    if ! brew list rtk &>/dev/null 2>&1; then
        log_step "Installing" "rtk via Homebrew"
        brew install rtk
    else
        log_info "rtk already installed"
    fi

    # Symlink macOS app-support path → XDG config so config.toml is found.
    local mac_support="${HOME}/Library/Application Support/rtk"
    local xdg_rtk="${XDG_CONFIG_HOME:-${HOME}/.config}/rtk"
    if [[ ! -e "${mac_support}" ]]; then
        mkdir -p "$(dirname "${mac_support}")"
        ln -sf "${xdg_rtk}" "${mac_support}"
        log_step "Linked" "~/Library/Application Support/rtk → ${xdg_rtk}"
    else
        log_info "~/Library/Application Support/rtk already exists (skipped symlink)"
    fi

    # Install Claude Code hook (idempotent).
    if command -v rtk &>/dev/null; then
        log_step "Init" "rtk Claude Code hook (rtk init -g --auto-patch)"
        rtk init -g --auto-patch
    fi
}

uninstall_rtk() {
    log_step "Uninstalling" "RTK"

    if command -v rtk &>/dev/null; then
        log_step "Removing" "Claude Code hook"
        rtk init -g --uninstall || true
    fi

    local mac_support="${HOME}/Library/Application Support/rtk"
    if [[ -L "${mac_support}" ]]; then
        unlink "${mac_support}"
        log_step "Removed" "symlink ~/Library/Application Support/rtk"
    fi

    if brew list rtk &>/dev/null 2>&1; then
        log_step "Uninstalling" "rtk via Homebrew"
        brew uninstall rtk
    fi

    log_success "RTK uninstalled. XDG config kept at: ${XDG_CONFIG_HOME:-${HOME}/.config}/rtk"
    log_info "To also remove the config: rm -rf \"\${XDG_CONFIG_HOME}/rtk\""
}

# ── Step 10: Post-install checklist ──────────────────────────────────────────
print_checklist() {
    printf '\n'
    log_success "dotfiles installed — open a new shell to load the configuration"
    printf '\n'
    printf '%s\n' "  Post-install checklist:"
    printf '%s\n' "  ─────────────────────────────────────────────────────────"
    printf '%s\n' "  ☐  Fill in private/git.config   (user.name, user.email)"
    printf '%s\n' "  ☐  Fill in secrets/.env.secrets (environment secrets)"
    printf '%s\n' "  ☐  Fill in secrets/.ai.secrets  (AI API keys)"
    printf '%s\n' "  ☐  Open tmux and press <prefix>+I to install plugins"
    printf '%s\n' "  ☐  Open Neovim — plugins install automatically on first run"
    printf '%s\n' "  ☐  Open Ghostty — cursor shaders load from ghostty/shaders/"
    printf '\n'
    printf '%s\n' "  Backup location (if any files were moved):"
    printf '%s\n' "    ${BACKUP_DIR}"
    printf '\n'
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    # Fast path: uninstall RTK only.
    if [[ "${UNINSTALL_RTK}" == "true" ]]; then
        uninstall_rtk
        return 0
    fi

    printf '\n'
    log_step "Starting" "dotfiles installer (DOTFILES_DIR=${DOTFILES_DIR})"
    [[ "${DRY_RUN}" == "true" ]] && log_warn "Dry-run mode enabled — no changes will be made"
    [[ "${INSTALL_RTK}" == "false" ]] && log_info "RTK install skipped (--skip-rtk)"
    printf '\n'

    check_platform
    check_prerequisites
    backup_conflicts
    create_xdg_dirs
    write_zshenv
    create_placeholder_secrets
    init_tpm
    clone_ghostty_shaders
    set_permissions
    [[ "${INSTALL_RTK}" == "true" ]] && install_rtk
    print_checklist
}

main "$@"

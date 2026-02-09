#!/usr/bin/env bash
# =============================================================================
# install.sh — Bootstrap script for a fresh Mac (Apple Silicon / Intel)
#
# Usage:
#     chmod +x install.sh && ./install.sh
#
# This script is idempotent: every step checks current state before acting,
# so re-running it is safe.
# =============================================================================

set -uo pipefail

# =============================================================================
# Constants
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_CONFIG="$SCRIPT_DIR/.config"
DOTFILES_ZSHENV="$SCRIPT_DIR/.zshenv"
BREW_FORMULAE="$DOTFILES_CONFIG/brew/brew_formulae.txt"
BREW_CASKS="$DOTFILES_CONFIG/brew/brew_casks.txt"
RVMINSTALL_SRC="$SCRIPT_DIR/.rvminstall.sh"
RUBY_VERSION="3.3.7"
ITERM_APP_V2="/Applications/iTerm2.app"
ITERM_APP_V1="/Applications/iTerm.app"
STATE_DIR="${TMPDIR:-/tmp}/dotfiles-install"
mkdir -p "$STATE_DIR"

# =============================================================================
# Color & formatting helpers
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# =============================================================================
# State helpers — track progress, detect failures, resume on re-run
# =============================================================================

step_done() {
    [[ -f "$STATE_DIR/$1.done" ]]
}

mark_done() {
    touch "$STATE_DIR/$1.done"
    # Clear any previous failure for this step
    rm -f "$STATE_DIR/$1.failed"
}

mark_failed() {
    local step="$1"
    local reason="${2:-unknown error}"
    echo "$reason" > "$STATE_DIR/$step.failed"
}

clear_state() {
    rm -rf "$STATE_DIR"
}

# Run a step with automatic success/failure tracking
run_step() {
    local step_id="$1"
    local step_fn="$2"

    if step_done "$step_id"; then
        return 0
    fi

    if "$step_fn"; then
        mark_done "$step_id"
    else
        mark_failed "$step_id" "$step_fn returned non-zero"
        log_error "step '${step_id}' failed (${step_fn})"
        return 1
    fi
}

# Detect previous failed run and prompt user
check_previous_run() {
    local has_progress=false
    local failed_step=""
    local failed_reason=""

    # Check if any .done or .failed files exist
    for f in "$STATE_DIR"/*.done "$STATE_DIR"/*.failed; do
        [[ -f "$f" ]] && has_progress=true && break
    done

    if [[ "$has_progress" != true ]]; then
        return 0
    fi

    # Find the failed step (if any)
    for f in "$STATE_DIR"/*.failed; do
        if [[ -f "$f" ]]; then
            failed_step="$(basename "$f" .failed)"
            failed_reason="$(cat "$f")"
            break
        fi
    done

    echo ""
    log_warn "a previous run was detected"

    # List completed steps
    local completed=()
    for f in "$STATE_DIR"/*.done; do
        [[ -f "$f" ]] && completed+=("$(basename "$f" .done)")
    done

    if [[ ${#completed[@]} -gt 0 ]]; then
        log_info "completed steps:"
        for s in "${completed[@]}"; do
            echo -e "     ${GREEN}✓${RESET} ${s}"
        done
    fi

    if [[ -n "$failed_step" ]]; then
        echo ""
        log_error "last failure: step '${failed_step}'"
        log_error "reason: ${failed_reason}"
    fi

    echo ""
    while true; do
        echo -e "     ${CYAN}Y = resume, n = start fresh, q = quit${RESET}"
        echo -en "     ${BOLD}Your choice [Y/n/q]:${RESET} "
        read -r answer
        case "$answer" in
            [yY]|[yY][eE][sS]|"")
                log_info "resuming from last checkpoint..."
                echo ""
                return 0
                ;;
            [nN]|[nN][oO])
                log_info "clearing state, starting from scratch..."
                clear_state
                mkdir -p "$STATE_DIR"
                echo ""
                return 0
                ;;
            [qQ]|[qQ][uU][iI][tT])
                log_info "exiting — run ./install.sh again when ready"
                exit 0
                ;;
            *)
                log_warn "please enter Y, n, or q"
                ;;
        esac
    done
}

# =============================================================================
# Homebrew shell env helper — avoid hardcoding /opt/homebrew everywhere
# =============================================================================

ensure_brew_env() {
    if command -v brew &>/dev/null; then
        eval "$(brew shellenv)" 2>/dev/null || true
    elif [[ -x "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon default path
        eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
    elif [[ -x "/usr/local/bin/brew" ]]; then
        # Intel Mac default path
        eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null || true
    fi
}

log_step() {
    echo -e "${GREEN}${BOLD}===> ${1}${RESET}"
}

log_info() {
    echo -e "     ${CYAN}${1}${RESET}"
}

log_warn() {
    echo -e "     ${YELLOW}warning:${RESET} ${1}"
}

log_error() {
    echo -e "     ${RED}error:${RESET} ${1}"
}

log_success() {
    echo -e "     ${GREEN}✓${RESET} ${1}"
}

log_skip() {
    echo -e "     ${YELLOW}→${RESET} already done, skipping"
}

# =============================================================================
# Pre-check: Detect existing user configs on a non-fresh machine
# =============================================================================

preflight_check() {
    log_step "Scanning for existing configurations"

    local targets=(
        # Home-level dotfiles
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.zprofile"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
        "$HOME/.tmux.conf"
        "$HOME/.gitconfig"
        "$HOME/.vimrc"
        "$HOME/.npmrc"
        "$HOME/.gemrc"
        "$HOME/.rvmrc"
        "$HOME/.swiftlint.yml"
        "$HOME/.p10k.zsh"
        # XDG config directories (matching this repo)
        "$HOME/.config/nvim"
        "$HOME/.config/zsh"
        "$HOME/.config/tmux"
        "$HOME/.config/git"
        "$HOME/.config/aerospace"
        "$HOME/.config/bash"
        "$HOME/.config/alias"
        "$HOME/.config/bin"
        "$HOME/.config/fzf"
        "$HOME/.config/lazygit"
        "$HOME/.config/btop"
        "$HOME/.config/borders"
        "$HOME/.config/glow"
        "$HOME/.config/vim"
        "$HOME/.config/swiftformat"
        "$HOME/.config/iterm2"
        "$HOME/.config/zi"
        # Runtime directories
        "$HOME/.rvm"
    )

    local found=()
    for target in "${targets[@]}"; do
        if [[ -e "$target" ]]; then
            found+=("$target")
        fi
    done

    if [[ ${#found[@]} -eq 0 ]]; then
        log_success "no existing configs detected — looks like a fresh machine"
        return
    fi

    echo ""
    log_warn "this does NOT look like a fresh machine"
    log_warn "the following configs were found and may be OVERWRITTEN:"
    echo ""
    for f in "${found[@]}"; do
        echo -e "     ${YELLOW}•${RESET} ${f}"
    done
    echo ""
    log_info "please back up these files before proceeding, for example:"
    echo ""
    echo -e "     ${CYAN}mkdir -p ~/dotfiles-backup/\$(date +%Y%m%d)${RESET}"
    for f in "${found[@]}"; do
        echo -e "     ${CYAN}cp -a ${f} ~/dotfiles-backup/\$(date +%Y%m%d)/${RESET}"
    done
    echo ""

    while true; do
        echo -en "     ${BOLD}Auto-backup and continue? [y/N]:${RESET} "
        read -r answer
        case "$answer" in
            [yY]|[yY][eE][sS])
                local backup_dir="$HOME/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
                mkdir -p "$backup_dir"
                log_info "backing up to ${backup_dir} ..."
                for f in "${found[@]}"; do
                    cp -a "$f" "$backup_dir/" 2>/dev/null && \
                        log_success "backed up ${f}" || \
                        log_warn "failed to back up ${f}"
                done
                echo ""
                log_success "backup complete, proceeding with installation..."
                echo ""
                return
                ;;
            [nN]|[nN][oO]|"")
                echo ""
                log_info "no worries — see you next time :)"
                echo ""
                exit 0
                ;;
            *)
                log_warn "please enter y or n"
                ;;
        esac
    done
}

# =============================================================================
# Step 0: Check iTerm2 and offer to install / switch
# =============================================================================

check_iterm2() {
    log_step "Checking iTerm2"

    local iterm_app=""
    if [[ -d "$ITERM_APP_V2" ]]; then
        iterm_app="$ITERM_APP_V2"
    elif [[ -d "$ITERM_APP_V1" ]]; then
        iterm_app="$ITERM_APP_V1"
    fi

    if [[ -n "$iterm_app" ]]; then
        log_success "iTerm2 is installed (${iterm_app})"
        return
    fi

    log_info "iTerm2 is not installed"
    echo ""

    while true; do
        echo -en "     ${BOLD}Would you like to install iTerm2? [y/N]:${RESET} "
        read -r answer
        case "$answer" in
            [yY]|[yY][eE][sS])
                break
                ;;
            [nN]|[nN][oO]|"")
                log_info "skipping iTerm2 installation, continuing in current terminal"
                return
                ;;
            *)
                log_warn "please enter y or n"
                ;;
        esac
    done

    # Install iTerm2 (Homebrew may not be available yet, use curl as fallback)
    if command -v brew &>/dev/null; then
        log_info "installing iTerm2 via Homebrew..."
        brew install iterm2
    else
        log_info "Homebrew not available yet, downloading iTerm2 directly..."
        local tmpdir
        tmpdir="$(mktemp -d)"
        local zip_path="$tmpdir/iTerm2.zip"
        curl -fsSL "https://iterm2.com/downloads/stable/latest" -o "$zip_path"
        unzip -q "$zip_path" -d "$tmpdir"
        mv "$tmpdir/iTerm.app" "$ITERM_APP_V2"
        rm -rf "$tmpdir"
    fi

    # Normalize name: rename iTerm.app → iTerm2.app if needed
    if [[ -d "$ITERM_APP_V1" ]] && [[ ! -d "$ITERM_APP_V2" ]]; then
        mv "$ITERM_APP_V1" "$ITERM_APP_V2"
    fi

    # Detect final installed path
    if [[ -d "$ITERM_APP_V2" ]]; then
        iterm_app="$ITERM_APP_V2"
    elif [[ -d "$ITERM_APP_V1" ]]; then
        iterm_app="$ITERM_APP_V1"
    fi

    local iterm_name
    iterm_name="$(basename "$iterm_app" .app)"
    log_success "iTerm2 installed to ${iterm_app}"
    echo ""

    while true; do
        echo -en "     ${BOLD}Open iTerm2 and re-run this script there? [y/N]:${RESET} "
        read -r answer
        case "$answer" in
            [yY]|[yY][eE][sS])
                echo ""
                log_info "opening iTerm2..."
                log_info "please re-run the script with:"
                echo ""
                echo -e "     ${CYAN}cd $(printf '%q' "$SCRIPT_DIR") && ./install.sh${RESET}"
                echo ""
                open -a "$iterm_name"
                exit 0
                ;;
            [nN]|[nN][oO]|"")
                log_info "continuing in current terminal"
                return
                ;;
            *)
                log_warn "please enter y or n"
                ;;
        esac
    done
}

# =============================================================================
# Step 1: Check architecture
# =============================================================================

check_architecture() {
    log_step "Checking architecture"

    local arch
    arch="$(uname -m)"

    if [[ "$arch" == "arm64" ]]; then
        log_success "Apple Silicon (arm64) detected"
    elif [[ "$arch" == "x86_64" ]]; then
        echo ""
        log_warn "Intel (x86_64) architecture detected."
        log_warn "This dotfiles setup is primarily tested on Apple Silicon."
        log_warn "Most features should work, but some paths or behaviours may differ."
        echo ""
        while true; do
            echo -en "     ${BOLD}Continue anyway? [y/N]:${RESET} "
            read -r answer
            case "$answer" in
                [yY]|[yY][eE][sS])
                    log_success "proceeding on Intel Mac..."
                    echo ""
                    break
                    ;;
                [nN]|[nN][oO]|"")
                    echo ""
                    log_info "no worries — see you next time :)"
                    echo ""
                    exit 0
                    ;;
                *)
                    log_warn "please enter y or n"
                    ;;
            esac
        done
    else
        log_error "Unsupported architecture: ${arch}. Exiting."
        exit 1
    fi
}

# =============================================================================
# Step 1.5: Ensure essential CLI tools (git, curl) are available
# =============================================================================

ensure_cli_essentials() {
    log_step "Checking essential CLI tools"

    # curl is required for Homebrew install; it ships with macOS
    if ! command -v curl &>/dev/null; then
        log_error "curl is not available — cannot proceed without it"
        exit 1
    fi
    log_success "curl available"

    # git: if missing, install Homebrew first (next step), then install git via brew
    if command -v git &>/dev/null; then
        log_success "git available ($(git --version 2>/dev/null | head -1))"
    else
        log_warn "git not found — it will be installed via Homebrew"
    fi
}

# =============================================================================
# Step 2: Copy .config and .zshenv to HOME
# =============================================================================

copy_dotfiles() {
    log_step "Copying dotfiles to \$HOME"

    # Copy .config
    if [[ -d "$HOME/.config" ]]; then
        log_info "~/.config already exists, merging contents..."
    fi
    mkdir -p "$HOME/.config"
    rsync -a --ignore-existing "$DOTFILES_CONFIG/" "$HOME/.config/"
    log_success ".config synced to ~/.config"

    # Copy .zshenv
    if [[ -f "$HOME/.zshenv" ]]; then
        if diff -q "$DOTFILES_ZSHENV" "$HOME/.zshenv" &>/dev/null; then
            log_skip
        else
            local backup="$HOME/.zshenv.backup.$(date +%Y%m%d%H%M%S)"
            cp "$HOME/.zshenv" "$backup"
            log_warn "existing .zshenv backed up to ${backup}"
            cp "$DOTFILES_ZSHENV" "$HOME/.zshenv"
            log_success ".zshenv copied to ~/.zshenv"
        fi
    else
        cp "$DOTFILES_ZSHENV" "$HOME/.zshenv"
        log_success ".zshenv copied to ~/.zshenv"
    fi
}

# =============================================================================
# Step 3: Create XDG directories and source .zshenv
# =============================================================================

setup_xdg() {
    log_step "Setting up XDG directories"

    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
    local xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
    local xdg_cache="${XDG_CACHE_HOME:-$HOME/.cache}"
    local xdg_state="${XDG_STATE_HOME:-$HOME/.local/state}"

    local dirs=(
        "$xdg_config"
        "$xdg_data"
        "$xdg_cache"
        "$xdg_state"
        "$xdg_state/zsh"
        "$xdg_cache/vim"
    )

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            continue
        fi
        mkdir -p "$dir"
        log_info "created ${dir}"
    done

    log_success "XDG directories ready"

    log_info "setting XDG variables from ~/.zshenv..."
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
    export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
    if [[ "$(uname -m)" == "arm64" ]]; then
        export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
    else
        export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/usr/local}"
    fi
    log_success "XDG variables set (full .zshenv will be sourced by zsh on next login)"
}

# =============================================================================
# Step 4: Install Homebrew
# =============================================================================

install_homebrew() {
    log_step "Checking Homebrew"

    if command -v brew &>/dev/null; then
        log_skip
        return
    fi

    log_info "Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Ensure brew is available in the current session
    ensure_brew_env
    log_success "Homebrew installed"
}

# =============================================================================
# Step 4.5: Ensure git is available (install via Homebrew if missing)
# =============================================================================

ensure_git() {
    log_step "Checking Git"

    ensure_brew_env

    if command -v git &>/dev/null; then
        log_success "git available ($(git --version 2>/dev/null | head -1))"
        return
    fi

    log_info "git not found, installing via Homebrew..."
    brew install git
    log_success "git installed ($(git --version 2>/dev/null | head -1))"
}

# =============================================================================
# Step 5: Install brew packages (formulae + casks)
# =============================================================================

install_brew_packages() {
    log_step "Installing Homebrew packages"

    ensure_brew_env

    # --- Formulae ---
    if [[ -f "$BREW_FORMULAE" ]]; then
        log_info "reading formulae from brew_formulae.txt..."
        local total=0 failed=0

        while IFS= read -r pkg || [[ -n "$pkg" ]]; do
            pkg="$(echo "$pkg" | xargs)"
            [[ -z "$pkg" || "$pkg" == \#* ]] && continue
            ((total++))

            log_info "installing formula: ${pkg}"
            if ! brew install "$pkg"; then
                log_warn "failed to install formula: ${pkg}"
                ((failed++))
            fi
        done < "$BREW_FORMULAE"

        log_success "formulae: ${total} total, ${failed} failed"
    else
        log_warn "brew_formulae.txt not found, skipping formulae"
    fi

    # --- Casks ---
    if [[ -f "$BREW_CASKS" ]]; then
        log_info "reading casks from brew_casks.txt..."
        local ctotal=0 cfailed=0

        while IFS= read -r pkg || [[ -n "$pkg" ]]; do
            pkg="$(echo "$pkg" | xargs)"
            [[ -z "$pkg" || "$pkg" == \#* ]] && continue
            ((ctotal++))

            log_info "installing cask: ${pkg}"
            if ! brew install "$pkg"; then
                log_warn "failed to install cask: ${pkg}"
                ((cfailed++))
            fi
        done < "$BREW_CASKS"

        log_success "casks: ${ctotal} total, ${cfailed} failed"
    else
        log_warn "brew_casks.txt not found, skipping casks"
    fi

    # All packages installed; now safe to source .zshenv under zsh
    if [[ -f "$HOME/.zshenv" ]]; then
        local zsh_bin
        zsh_bin="$(command -v zsh || echo /bin/zsh)"
        log_info "sourcing ~/.zshenv via ${zsh_bin}..."
        "$zsh_bin" -c "source '$HOME/.zshenv'" 2>/dev/null || true
        log_success ".zshenv sourced"
    fi

}

# =============================================================================
# Step 5.5: Symlink swiftlint to /usr/local/bin for Xcode compatibility
# =============================================================================

symlink_swiftlint() {
    log_step "Checking SwiftLint symlink"

    ensure_brew_env

    local swiftlint_bin
    swiftlint_bin="$(command -v swiftlint 2>/dev/null || true)"

    if [[ -z "$swiftlint_bin" ]]; then
        log_warn "swiftlint not found, skipping symlink"
        return
    fi

    if [[ -e /usr/local/bin/swiftlint ]]; then
        log_success "swiftlint already in /usr/local/bin"
        return
    fi

    log_info "symlinking ${swiftlint_bin} → /usr/local/bin/swiftlint"
    sudo mkdir -p /usr/local/bin
    sudo ln -s "$swiftlint_bin" /usr/local/bin/swiftlint
    log_success "swiftlint symlinked"
}

# =============================================================================
# Step 6: Ensure Zsh is installed and set as default shell
# =============================================================================

setup_zsh() {
    log_step "Checking Zsh"

    ensure_brew_env

    # Install zsh via brew if not already available
    if ! command -v zsh &>/dev/null; then
        log_info "zsh not found, installing via Homebrew..."
        brew install zsh
    fi

    # Resolve the actual zsh path (brew or system)
    local target_zsh
    target_zsh="$(command -v zsh)"
    log_success "zsh available at ${target_zsh}"

    # Add to /etc/shells if missing
    if ! grep -qx "$target_zsh" /etc/shells; then
        log_info "adding ${target_zsh} to /etc/shells (requires sudo)..."
        echo "$target_zsh" | sudo tee -a /etc/shells >/dev/null
        log_success "added to /etc/shells"
    fi

    # Set default shell
    local current_shell
    current_shell="$(dscl . -read /Users/"$USER" UserShell | awk '{print $2}')"
    if [[ "$current_shell" != "$target_zsh" ]]; then
        log_info "changing default shell to ${target_zsh} (requires sudo)..."
        sudo chsh -s "$target_zsh" "$USER"
        log_success "default shell set to ${target_zsh}"
    else
        log_success "default shell is already ${target_zsh}"
    fi

    log_warn "shell change takes effect in a new terminal session"

    # Source .zshenv via zsh to validate config
    log_info "sourcing .zshenv via zsh..."
    "$target_zsh" -c "source '$HOME/.zshenv'" 2>/dev/null || true
    log_success ".zshenv sourced"
}

# =============================================================================
# Step 6.5: Install zi (zsh plugin manager) and source .zshrc
# =============================================================================

install_zi() {
    log_step "Checking zi (zsh plugin manager)"

    local zi_home="${XDG_CONFIG_HOME:-$HOME/.config}/zi/bin"

    if [[ -d "$zi_home" ]] && [[ -f "$zi_home/zi.zsh" ]]; then
        log_success "zi already installed at ${zi_home}"
    else
        log_info "installing zi via official script..."
        sh -c "$(curl -fsSL get.zshell.dev)" --
        log_success "zi installed"
    fi

    # Source .zshrc via zsh to initialize zi and load plugins
    local zshrc="$HOME/.config/zsh/.zshrc"
    if [[ -f "$zshrc" ]]; then
        local zsh_bin
        zsh_bin="$(command -v zsh || echo /bin/zsh)"
        log_info "sourcing .zshrc via zsh to initialize plugins..."
        "$zsh_bin" -c "source '$HOME/.zshenv'; source '$zshrc'" 2>/dev/null || true
        log_success ".zshrc sourced, plugins initialized"
    else
        log_warn "${zshrc} not found, skipping"
    fi
}

# =============================================================================
# Step 7: Install RVM and copy .rvminstall.sh
# =============================================================================

install_rvm() {
    log_step "Checking RVM"

    if command -v rvm &>/dev/null; then
        log_success "rvm already installed"
    else
        # Ensure gnupg is available for GPG key verification
        if ! command -v gpg &>/dev/null; then
            log_info "gnupg not found, installing via Homebrew..."
            brew install gnupg
        fi

        # Import RVM official GPG keys
        log_info "importing RVM GPG keys..."
        gpg --keyserver keyserver.ubuntu.com \
            --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
                        7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
            2>/dev/null || {
            log_warn "GPG key import from keyserver failed, trying fallback..."
            curl -sSL https://rvm.io/mpapis.asc | gpg --import - 2>/dev/null || true
            curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - 2>/dev/null || true
        }
        log_success "GPG keys imported"

        # Install RVM
        log_info "installing rvm via official script..."
        curl -sSL https://get.rvm.io | bash -s stable
        log_success "rvm installed"
    fi

    # Source rvm into current session
    # shellcheck disable=SC1091
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

    # Copy .rvminstall.sh
    if [[ -f "$RVMINSTALL_SRC" ]]; then
        local dest="$HOME/.rvm/.rvminstall.sh"
        mkdir -p "$HOME/.rvm"
        cp "$RVMINSTALL_SRC" "$dest"
        chmod +x "$dest"
        log_success ".rvminstall.sh copied to ${dest} (executable)"
    else
        log_warn ".rvminstall.sh not found in repo, skipping copy"
    fi

    # Source .profile if it exists (rvm may have added entries there)
    if [[ -f "$HOME/.profile" ]]; then
        # shellcheck disable=SC1091
        source "$HOME/.profile" 2>/dev/null || true
        log_success "sourced ~/.profile"
    else
        log_warn "~/.profile not found, some rvm paths may not be loaded until next login"
    fi
}

# =============================================================================
# Step 8: Source shell configs
# =============================================================================

source_shell_configs() {
    log_step "Sourcing shell configurations"

    # Source rvm in the current bash session
    # shellcheck disable=SC1091
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" 2>/dev/null || true
    log_success "rvm sourced"

    # .zshrc contains zsh-specific syntax (zi, fpath, etc.) and cannot be
    # sourced in bash. Use a zsh subshell to validate it instead.
    local zshrc="$HOME/.config/zsh/.zshrc"
    if [[ -f "$zshrc" ]]; then
        local zsh_bin
        zsh_bin="$(command -v zsh || echo /bin/zsh)"
        "$zsh_bin" -c "source '$HOME/.zshenv'; source '$zshrc'" 2>/dev/null || true
        log_success "validated ${zshrc} via zsh"
    else
        log_warn "${zshrc} not found, skipping"
    fi
}

# =============================================================================
# Step 9: Install Ruby via rvminstall alias
# =============================================================================

install_ruby() {
    log_step "Installing Ruby ${RUBY_VERSION}"

    # Source rvm
    # shellcheck disable=SC1091
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

    # Check if already installed
    if rvm list strings 2>/dev/null | grep -q "ruby-${RUBY_VERSION}"; then
        log_skip
        return
    fi

    local rvminstall_script="$HOME/.rvm/.rvminstall.sh"
    if [[ -x "$rvminstall_script" ]]; then
        log_info "running rvminstall ${RUBY_VERSION}..."
        bash "$rvminstall_script" "$RUBY_VERSION"
        log_success "Ruby ${RUBY_VERSION} installed"
    else
        log_warn "rvminstall script not found, falling back to rvm install"
        rvm install "$RUBY_VERSION"
        log_success "Ruby ${RUBY_VERSION} installed"
    fi
}

# =============================================================================
# Step 10: Install CocoaPods
# =============================================================================

install_cocoapods() {
    log_step "Installing CocoaPods"

    # Source rvm
    # shellcheck disable=SC1091
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

    # Use the installed ruby version
    rvm use "$RUBY_VERSION" --default 2>/dev/null || true

    if gem list -i cocoapods &>/dev/null; then
        log_skip
        return
    fi

    log_info "installing cocoapods via gem..."
    gem install cocoapods
    log_success "cocoapods installed"
}

# =============================================================================
# Step 11: Verify environment
# =============================================================================

verify_environment() {
    log_step "Verifying environment"

    local has_error=false

    local checks=(
        "brew:Homebrew"
        "zsh:Zsh"
        "git:Git"
        "nvim:Neovim"
        "tmux:tmux"
        "rvm:RVM"
        "ruby:Ruby"
        "pod:CocoaPods"
        "node:Node.js"
        "go:Go"
        "fzf:fzf"
        "rg:ripgrep"
        "delta:git-delta"
    )

    local max_len=0
    for entry in "${checks[@]}"; do
        local name="${entry#*:}"
        local len=${#name}
        (( len > max_len )) && max_len=$len
    done

    echo ""
    for entry in "${checks[@]}"; do
        local cmd="${entry%%:*}"
        local name="${entry#*:}"
        local padded
        padded=$(printf "%-${max_len}s" "$name")

        if command -v "$cmd" &>/dev/null; then
            local ver
            ver="$("$cmd" --version 2>/dev/null | head -1 || echo "ok")"
            echo -e "     ${GREEN}✓${RESET} ${padded}  ${CYAN}${ver}${RESET}"
        else
            echo -e "     ${RED}✗${RESET} ${padded}  ${RED}not found${RESET}"
            has_error=true
        fi
    done

    echo ""

    if [[ "$has_error" == true ]]; then
        log_warn "some tools are missing; they may need manual setup"
    else
        log_success "all checks passed"
    fi
}

# =============================================================================
# Request sudo upfront
# =============================================================================

request_sudo() {
    log_step "Requesting administrator privileges"
    log_info "some steps require sudo (e.g. changing default shell)"
    sudo -v

    # Keep sudo alive in background
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

# =============================================================================
# Post-check: Prompt to install Xcode via Xcodes
# =============================================================================

prompt_xcode() {
    log_step "Checking Xcode"

    # Detect Xcode.app in common locations
    if [[ -d "/Applications/Xcode.app" ]] || [[ -d "$HOME/Applications/Xcode.app" ]]; then
        log_success "Xcode is installed"
        return
    fi

    log_warn "Xcode is not installed"
    log_info "Xcode is required for iOS/macOS development"

    # Check if Xcodes app is available
    local xcodes_app="/Applications/Xcodes.app"
    if [[ ! -d "$xcodes_app" ]]; then
        log_info "Xcodes app not found either — you can install Xcode manually from the App Store"
        return
    fi

    echo ""
    while true; do
        echo -en "     ${BOLD}Open Xcodes to install Xcode? [y/N]:${RESET} "
        read -r answer
        case "$answer" in
            [yY]|[yY][eE][sS])
                log_info "opening Xcodes..."
                open -a Xcodes
                log_success "Xcodes launched — please select and install your preferred Xcode version"
                return
                ;;
            [nN]|[nN][oO]|"")
                log_info "skipping Xcode installation"
                return
                ;;
            *)
                log_warn "please enter y or n"
                ;;
        esac
    done
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo -e "${BOLD}╔════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}║          Dotfiles Bootstrap — macOS                ║${RESET}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Detect previous run and let user choose: resume / restart / quit
    check_previous_run

    # Each step is tracked: completed steps are skipped, failures are recorded
    run_step "check_iterm2"       check_iterm2
    run_step "check_architecture" check_architecture
    run_step "ensure_cli"         ensure_cli_essentials
    run_step "preflight_check"    preflight_check

    # sudo is always requested (credential cache expires)
    request_sudo

    run_step "copy_dotfiles"      copy_dotfiles
    run_step "setup_xdg"          setup_xdg
    run_step "install_homebrew"   install_homebrew
    run_step "ensure_git"         ensure_git
    run_step "install_brew_pkgs"  install_brew_packages
    run_step "symlink_swiftlint"  symlink_swiftlint
    run_step "setup_zsh"          setup_zsh
    run_step "install_zi"         install_zi
    run_step "install_rvm"        install_rvm
    run_step "source_configs"     source_shell_configs
    run_step "install_ruby"       install_ruby
    run_step "install_cocoapods"  install_cocoapods

    verify_environment
    prompt_xcode

    # Clean up state files after successful completion
    clear_state

    echo ""
    log_step "Bootstrap complete"
    echo ""
    log_warn "Please close this terminal and open a new one to apply all changes."
    log_info "Your new default shell is Zsh. All configs are loaded from ~/.config."
    echo ""
}

main "$@"

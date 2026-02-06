#!/usr/bin/env bash
# =============================================================================
# install.sh — Bootstrap script for a fresh Apple Silicon Mac
#
# Usage:
#     chmod +x install.sh && ./install.sh
#
# This script is idempotent: every step checks current state before acting,
# so re-running it is safe.
# =============================================================================

set -euo pipefail

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

# =============================================================================
# Color & formatting helpers
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

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
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.zprofile"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.tmux.conf"
        "$HOME/.gitconfig"
        "$HOME/.vimrc"
        "$HOME/.config/nvim"
        "$HOME/.config/zsh"
        "$HOME/.config/tmux"
        "$HOME/.config/git"
        "$HOME/.config/aerospace"
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
        echo -en "     ${BOLD}Continue with installation? [y/N]:${RESET} "
        read -r answer
        case "$answer" in
            [yY]|[yY][eE][sS])
                log_success "user confirmed, proceeding..."
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
# Step 1: Check architecture (Apple Silicon only)
# =============================================================================

check_architecture() {
    log_step "Checking architecture"

    local arch
    arch="$(uname -m)"

    if [[ "$arch" != "arm64" ]]; then
        log_error "This script requires Apple Silicon (arm64)."
        log_error "Detected: ${arch}. Exiting."
        exit 1
    fi

    log_success "Apple Silicon (arm64) detected"
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

    log_info "sourcing ~/.zshenv (errors ignored)..."
    # shellcheck disable=SC1091
    source "$HOME/.zshenv" 2>/dev/null || true
    log_success ".zshenv sourced"
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
    eval "$(/opt/homebrew/bin/brew shellenv)"
    log_success "Homebrew installed"
}

# =============================================================================
# Step 4.5: Ensure git is available (install via Homebrew if missing)
# =============================================================================

ensure_git() {
    log_step "Checking Git"

    # Ensure brew is in PATH
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true

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

    # Ensure brew is in PATH
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true

    local installed_formulae
    installed_formulae="$(brew list --formula 2>/dev/null || true)"

    local installed_casks
    installed_casks="$(brew list --cask 2>/dev/null || true)"

    # --- Formulae ---
    if [[ -f "$BREW_FORMULAE" ]]; then
        log_info "reading formulae from brew_formulae.txt..."
        local total=0 skipped=0 installed=0

        while IFS= read -r pkg || [[ -n "$pkg" ]]; do
            pkg="$(echo "$pkg" | xargs)"
            [[ -z "$pkg" || "$pkg" == \#* ]] && continue
            ((total++))

            if echo "$installed_formulae" | grep -qx "$pkg" 2>/dev/null; then
                ((skipped++))
                continue
            fi

            log_info "installing formula: ${pkg}"
            if brew install "$pkg" 2>/dev/null; then
                ((installed++))
            else
                log_warn "failed to install formula: ${pkg}"
            fi
        done < "$BREW_FORMULAE"

        log_success "formulae: ${installed} installed, ${skipped} skipped, ${total} total"
    else
        log_warn "brew_formulae.txt not found, skipping formulae"
    fi

    # --- Casks ---
    if [[ -f "$BREW_CASKS" ]]; then
        log_info "reading casks from brew_casks.txt..."
        local ctotal=0 cskipped=0 cinstalled=0

        while IFS= read -r pkg || [[ -n "$pkg" ]]; do
            pkg="$(echo "$pkg" | xargs)"
            [[ -z "$pkg" || "$pkg" == \#* ]] && continue
            ((ctotal++))

            if echo "$installed_casks" | grep -qx "$pkg" 2>/dev/null; then
                ((cskipped++))
                continue
            fi

            log_info "installing cask: ${pkg}"
            if brew install --cask "$pkg" 2>/dev/null; then
                ((cinstalled++))
            else
                log_warn "failed to install cask: ${pkg}"
            fi
        done < "$BREW_CASKS"

        log_success "casks: ${cinstalled} installed, ${cskipped} skipped, ${ctotal} total"
    else
        log_warn "brew_casks.txt not found, skipping casks"
    fi
}

# =============================================================================
# Step 6: Ensure Zsh is installed and set as default shell
# =============================================================================

setup_zsh() {
    log_step "Checking Zsh"

    # Ensure brew is in PATH
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true

    local brew_zsh="/opt/homebrew/bin/zsh"

    # Install zsh via brew if not present
    if [[ ! -x "$brew_zsh" ]]; then
        log_info "installing zsh via Homebrew..."
        brew install zsh
    else
        log_success "zsh already installed at ${brew_zsh}"
    fi

    # Add brew zsh to /etc/shells if missing
    if ! grep -qx "$brew_zsh" /etc/shells; then
        log_info "adding ${brew_zsh} to /etc/shells (requires sudo)..."
        echo "$brew_zsh" | sudo tee -a /etc/shells >/dev/null
        log_success "added to /etc/shells"
    fi

    # Set default shell
    local current_shell
    current_shell="$(dscl . -read /Users/"$USER" UserShell | awk '{print $2}')"
    if [[ "$current_shell" != "$brew_zsh" ]]; then
        log_info "changing default shell to ${brew_zsh} (requires sudo)..."
        sudo chsh -s "$brew_zsh" "$USER"
        log_success "default shell set to ${brew_zsh}"
    else
        log_success "default shell is already ${brew_zsh}"
    fi

    log_warn "shell change takes effect in a new terminal session"
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
}

# =============================================================================
# Step 8: Source shell configs
# =============================================================================

source_shell_configs() {
    log_step "Sourcing shell configurations"

    # shellcheck disable=SC1091
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" 2>/dev/null || true

    local zshrc="$HOME/.config/zsh/.zshrc"
    if [[ -f "$zshrc" ]]; then
        # shellcheck disable=SC1090
        source "$zshrc" 2>/dev/null || true
        log_success "sourced ${zshrc}"
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
# Main
# =============================================================================

main() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}║       Dotfiles Bootstrap — Apple Silicon Mac    ║${RESET}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
    echo ""

    check_architecture
    ensure_cli_essentials
    preflight_check
    request_sudo
    copy_dotfiles
    setup_xdg
    install_homebrew
    ensure_git
    install_brew_packages
    setup_zsh
    install_rvm
    source_shell_configs
    install_ruby
    install_cocoapods
    verify_environment

    echo ""
    log_step "Bootstrap complete"
    echo ""
    log_warn "Please close this terminal and open a new one to apply all changes."
    log_info "Your new default shell is Zsh. All configs are loaded from ~/.config."
    echo ""
}

main "$@"

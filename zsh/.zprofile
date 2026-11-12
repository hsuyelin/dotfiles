# Zsh Profile
# Machine-specific configurations are sourced from private/zsh.zprofile

# macOS /etc/zprofile runs path_helper after .zshenv; restore our PATH ordering.
# Keep machine-specific overrides below this baseline.
# shellcheck disable=SC1091
[[ "$(uname -s)" == "Darwin" ]] && source "$ZDOTDIR/env/path.zsh"

# Source private zprofile if exists
# shellcheck disable=SC1091
[[ -f "${XDG_CONFIG_HOME}/private/zsh.zprofile" ]] && source "${XDG_CONFIG_HOME}/private/zsh.zprofile"

# OrbStack still installs its shell init under ~/.orbstack.
# Source it from the real ZDOTDIR-managed profile instead of ~/.zprofile.
# shellcheck disable=SC1091
[[ -f "$HOME/.orbstack/shell/init.zsh" ]] && source "$HOME/.orbstack/shell/init.zsh"

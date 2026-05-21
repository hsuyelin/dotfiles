# Zsh Profile
# Machine-specific configurations are sourced from private/zsh.zprofile

# Source private zprofile if exists
# shellcheck disable=SC1091
[[ -f "${XDG_CONFIG_HOME}/private/zsh.zprofile" ]] && source "${XDG_CONFIG_HOME}/private/zsh.zprofile"

# OrbStack still installs its shell init under ~/.orbstack.
# Source it from the real ZDOTDIR-managed profile instead of ~/.zprofile.
# shellcheck disable=SC1091
[[ -f "$HOME/.orbstack/shell/init.zsh" ]] && source "$HOME/.orbstack/shell/init.zsh"

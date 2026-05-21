# AI API Configuration
# Secrets are stored in ${XDG_CONFIG_HOME}/secrets/.ai.secrets
# shellcheck disable=SC1091
[[ -f "${XDG_CONFIG_HOME}/secrets/.ai.secrets" ]] && source "${XDG_CONFIG_HOME}/secrets/.ai.secrets"

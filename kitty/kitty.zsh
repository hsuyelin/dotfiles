# Kitty shell integration — sourced only when running inside kitty.
# Equivalent of Ghostty's built-in shell-integration = zsh.
[[ -z "$KITTY_INSTALLATION_DIR" ]] && return

export KITTY_SHELL_INTEGRATION="enabled"
autoload -Uz -- "$KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration"
kitty-integration
unfunction kitty-integration

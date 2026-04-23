# Setup fzf
# ---------
if [[ ! "$PATH" == *"${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/bin"* ]]; then
  PATH="${PATH:+${PATH}:}${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/bin"
fi

source <(fzf --zsh)

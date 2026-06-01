# Setup fzf
# ---------
if [[ ! "$PATH" == *"${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/bin"* ]]; then
  PATH="${PATH:+${PATH}:}${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/bin"
fi

# shellcheck disable=SC1090
source <(fzf --zsh)

# Catppuccin Mocha theme for fzf
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a \
  --multi"

export FZF_CTRL_R_OPTS="
  --height=40%
  --layout=reverse
  --border
  --info=inline
"

# ============================================================
# zoxide (z with completion)
# ============================================================

# export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
# export _ZO_FZF_OPTS="--height=40% --layout=reverse --border --with-nth 2.. --preview 'echo {2..}' --no-sort"

# # define `j` (and its completion)
# eval "$(zoxide init zsh --cmd j)"

# # interactive jump (fzf)
# function ji() {
#     local dir=$(zoxide query -l | fzf --height=40% --layout=reverse --border --preview 'echo {}')
#     if [ -n "$dir" ]; then
#         cd "$dir"
#     fi
# }
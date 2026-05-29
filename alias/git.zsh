# Status
alias gst='git status'
alias gss='git status -s'

# Add / Reset / Commit
alias ga='git add'
alias gaa='git add .'
alias gam='git add -p'
alias grh='git reset HEAD'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gcane='git commit --amend --no-edit'
alias gcam='git commit -a -m'

# WIP
alias gwip='git add -A && git commit -m "WIP [skip ci]"'
alias gunwip='git log -1 --format=%s | grep -q "WIP" && git reset HEAD~1'

# Branch
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcmain='git checkout main'
alias gcf='git checkout -f'
alias gbr='git branch'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gbmv='git branch -m'

# Fetch
alias gf='git fetch'
alias gfa='git fetch --all --prune'

# Merge / Rebase
alias gm='git merge'
alias gma='git merge --abort'
alias gmt='git mergetool'
alias grb='git rebase'
alias grbi='git rebase -i'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbs='git rebase --skip'

# Cherry-pick
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'

# Conflict resolution
alias gcrf='git add'
alias gcrall='git add -u'
alias gours='git checkout --ours'
alias gtheirs='git checkout --theirs'

# Pull / Push
alias gpl='git pull'
alias gpr='git pull --rebase'
alias gps='git push'
alias gpf='git push --force'
alias gpo='git push origin'

# Log / Diff
alias gl='git log --oneline --graph --decorate'
alias gloa='git log --oneline --graph --decorate --all'
alias glg='git log --stat'
alias gd='git diff'
alias gds='git diff --staged'
alias gdc='git diff --cached'
alias gdt='git difftool'

# Blame
alias gbl='git blame'

# Clone
alias gcl='git clone'

# Stash
alias gsta='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'

# Show / Tag
alias gsh='git show'
alias gtag='git tag'

# Reset / Clean
alias grhs='git reset --soft HEAD~1'
alias grhh='git reset --hard'
alias gclean='git clean -dfx'
# shellcheck disable=SC2139  # alias length exceeds 100 chars by necessity
alias gnuke='git reset --hard && git clean -dfx && git submodule foreach --recursive "git reset --hard; git clean -fd" && git submodule update --init --recursive --force'
alias gsnuke='git submodule foreach --recursive "git reset --hard; git clean -fd" && git submodule update --init --recursive --force'

# Gerrit
gpgnv() { git push origin HEAD:refs/for/"$(git rev-parse --abbrev-ref HEAD)" --no-verify; }

# ghelp: Git alias reference.
# Usage: ghelp [list | show [--module <id>] [--lang zh]] [--help]
ghelp() {
    local _i18n="${XDG_CONFIG_HOME}/alias/i18n/git.json"
    case "$1" in
        list)      shift; _help_list "$_i18n" "$@" ;;
        --help|-h) _help_usage "ghelp" ;;
        show)      shift; _help_show "$_i18n" "$@" ;;
        *)         _help_show "$_i18n" "$@" ;;
    esac
}

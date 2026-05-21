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

# Help — print all git aliases
ghelp() {
    local bold='\033[1m'
    local cyan='\033[0;36m'
    local yellow='\033[0;33m'
    local reset='\033[0m'
    local sep='────────────────────────────'

    echo ""
    printf '%sGit Aliases Cheatsheet%s\n' "$bold" "$reset"
    echo "$sep"

    _ghelp_section() { printf '\n%s  %-12s%s\n' "$yellow" "$1" "$reset"; }
    _ghelp_row()     { printf '  %s%-12s%s  %s\n' "$cyan" "$1" "$reset" "$2"; }

    _ghelp_section "Status"
    _ghelp_row "gst"    "git status"
    _ghelp_row "gss"    "git status -s"

    _ghelp_section "Add / Reset / Commit"
    _ghelp_row "ga"     "git add <file>"
    _ghelp_row "gaa"    "git add ."
    _ghelp_row "gam"    "git add -p  (interactive patch)"
    _ghelp_row "grh"    "git reset HEAD"
    _ghelp_row "gcm"    "git commit -m <msg>"
    _ghelp_row "gca"    "git commit --amend"
    _ghelp_row "gcane"  "git commit --amend --no-edit"
    _ghelp_row "gcam"   "git commit -a -m <msg>"

    _ghelp_section "WIP"
    _ghelp_row "gwip"   "git add -A && git commit -m 'WIP [skip ci]'"
    _ghelp_row "gunwip" "undo last commit if it is a WIP"

    _ghelp_section "Branch"
    _ghelp_row "gco"    "git checkout <branch>"
    _ghelp_row "gcb"    "git checkout -b <branch>"
    _ghelp_row "gcmain" "git checkout main"
    _ghelp_row "gcf"    "git checkout -f"
    _ghelp_row "gbr"    "git branch"
    _ghelp_row "gbd"    "git branch -d <branch>"
    _ghelp_row "gbD"    "git branch -D <branch>"
    _ghelp_row "gbmv"   "git branch -m <old> <new>"

    _ghelp_section "Fetch"
    _ghelp_row "gf"     "git fetch"
    _ghelp_row "gfa"    "git fetch --all --prune"

    _ghelp_section "Merge / Rebase"
    _ghelp_row "gm"     "git merge <branch>"
    _ghelp_row "gma"    "git merge --abort"
    _ghelp_row "gmt"    "git mergetool"
    _ghelp_row "grb"    "git rebase <branch>"
    _ghelp_row "grbi"   "git rebase -i <base>"
    _ghelp_row "grba"   "git rebase --abort"
    _ghelp_row "grbc"   "git rebase --continue"
    _ghelp_row "grbs"   "git rebase --skip"

    _ghelp_section "Cherry-pick"
    _ghelp_row "gcp"     "git cherry-pick <commit>"
    _ghelp_row "gcpa"    "git cherry-pick --abort"
    _ghelp_row "gcpc"    "git cherry-pick --continue"

    _ghelp_section "Conflict"
    _ghelp_row "gcrf"    "mark file as resolved  (git add <file>)"
    _ghelp_row "gcrall"  "mark all conflicts resolved  (git add -u)"
    _ghelp_row "gours"   "keep ours version  (git checkout --ours <file>)"
    _ghelp_row "gtheirs" "keep theirs version  (git checkout --theirs <file>)"

    _ghelp_section "Pull / Push"
    _ghelp_row "gpl"    "git pull"
    _ghelp_row "gpr"    "git pull --rebase"
    _ghelp_row "gps"    "git push"
    _ghelp_row "gpf"    "git push --force"
    _ghelp_row "gpo"    "git push origin"
    _ghelp_row "gpgnv"  "git push origin HEAD:refs/for/<branch> --no-verify  (Gerrit)"

    _ghelp_section "Log / Diff"
    _ghelp_row "gl"     "git log --oneline --graph --decorate"
    _ghelp_row "gloa"   "git log --oneline --graph --decorate --all"
    _ghelp_row "glg"    "git log --stat"
    _ghelp_row "gd"     "git diff"
    _ghelp_row "gds"    "git diff --staged"
    _ghelp_row "gdc"    "git diff --cached"
    _ghelp_row "gdt"    "git difftool"

    _ghelp_section "Blame"
    _ghelp_row "gbl"    "git blame <file>"

    _ghelp_section "Clone"
    _ghelp_row "gcl"    "git clone <url>"

    _ghelp_section "Stash"
    _ghelp_row "gsta"   "git stash"
    _ghelp_row "gstp"   "git stash pop"
    _ghelp_row "gstl"   "git stash list"

    _ghelp_section "Show / Tag"
    _ghelp_row "gsh"    "git show"
    _ghelp_row "gtag"   "git tag"

    _ghelp_section "Reset / Clean"
    _ghelp_row "grhs"   "git reset --soft HEAD~1  (undo last commit, keep staged)"
    _ghelp_row "grhh"   "git reset --hard"
    _ghelp_row "gclean" "git clean -dfx"
    _ghelp_row "gnuke"  "reset --hard + clean -dfx + nuke all submodules"
    _ghelp_row "gsnuke" "nuke all submodules only (reset --hard + clean + update)"

    echo ""
    echo "$sep"
    echo ""

    unfunction _ghelp_section _ghelp_row
}

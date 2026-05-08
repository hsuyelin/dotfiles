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

# Branch
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcmain='git checkout main'
alias gcf='git checkout -f'
alias gbr='git branch'
alias gbd='git branch -d'
alias gbD='git branch -D'

# Merge / Rebase
alias gm='git merge'
alias gmt='git mergetool'
alias grb='git rebase'
alias grbi='git rebase -i'

# Pull / Push
alias gpl='git pull'
alias gpr='git pull --rebase'
alias gps='git push'
alias gpf='git push --force'
alias gpo='git push origin'

# Log / Diff
alias gl='git log --oneline --graph --decorate'
alias glg='git log --stat'
alias gd='git diff'
alias gds='git diff --staged'
alias gdc='git diff --cached'
alias gdt='git difftool'

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
alias grhh='git reset --hard'
alias gclean='git clean -dfx'
alias gnuke='git reset --hard && git clean -dfx'

# Gerrit
gpgnv() { git push origin HEAD:refs/for/$(git rev-parse --abbrev-ref HEAD) --no-verify }

# Help — print all git aliases
ghelp() {
    local bold='\033[1m'
    local cyan='\033[0;36m'
    local yellow='\033[0;33m'
    local reset='\033[0m'

    echo ""
    printf "${bold}Git Aliases Cheatsheet${reset}\n"
    echo "────────────────────────────────────────────────────"

    _ghelp_section() { printf "\n${yellow}  %-12s${reset}\n" "$1"; }
    _ghelp_row()     { printf "  ${cyan}%-12s${reset}  %s\n" "$1" "$2"; }

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

    _ghelp_section "Branch"
    _ghelp_row "gco"    "git checkout <branch>"
    _ghelp_row "gcb"    "git checkout -b <branch>"
    _ghelp_row "gcmain" "git checkout main"
    _ghelp_row "gcf"    "git checkout -f"
    _ghelp_row "gbr"    "git branch"
    _ghelp_row "gbd"    "git branch -d <branch>"
    _ghelp_row "gbD"    "git branch -D <branch>"

    _ghelp_section "Merge / Rebase"
    _ghelp_row "gm"     "git merge <branch>"
    _ghelp_row "gmt"    "git mergetool"
    _ghelp_row "grb"    "git rebase <branch>"
    _ghelp_row "grbi"   "git rebase -i <base>"

    _ghelp_section "Pull / Push"
    _ghelp_row "gpl"    "git pull"
    _ghelp_row "gpr"    "git pull --rebase"
    _ghelp_row "gps"    "git push"
    _ghelp_row "gpf"    "git push --force"
    _ghelp_row "gpo"    "git push origin"
    _ghelp_row "gpgnv"  "git push origin HEAD:refs/for/<branch> --no-verify  (Gerrit)"

    _ghelp_section "Log / Diff"
    _ghelp_row "gl"     "git log --oneline --graph --decorate"
    _ghelp_row "glg"    "git log --stat"
    _ghelp_row "gd"     "git diff"
    _ghelp_row "gds"    "git diff --staged"
    _ghelp_row "gdc"    "git diff --cached"
    _ghelp_row "gdt"    "git difftool"

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
    _ghelp_row "grhh"   "git reset --hard"
    _ghelp_row "gclean" "git clean -dfx"
    _ghelp_row "gnuke"  "git reset --hard && git clean -dfx"

    echo ""
    echo "────────────────────────────────────────────────────"
    echo ""

    unfunction _ghelp_section _ghelp_row
}

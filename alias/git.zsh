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

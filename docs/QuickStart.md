# Quick Start Guide

A quick reference for common commands and operations in this configuration.

---

## 1. Proxy

```bash
# Enable proxy
proxy_on

# Disable proxy
proxy_off

# Check proxy status
proxy_status
```

## 2. Git Aliases

Provided by the Oh My Zsh git plugin (`OMZP::git`).

**Stage & Commit**

```bash
ga .                # git add .
gaa                 # git add --all
gcmsg "feat: xxx"   # git commit -m "feat: xxx"
gc!                 # git commit --amend
```

**Pull & Push**

```bash
gl                  # git pull
gpr                 # git pull --rebase
gpra                # git pull --rebase --autostash
gp                  # git push
gpsup               # git push --set-upstream origin <current-branch>
```

**Branch**

```bash
gb                  # git branch
gba                 # git branch -a (fzf-enhanced branch switcher)
gco <branch>        # git checkout <branch>
gcb <new-branch>    # git checkout -b <new-branch>
gsw <branch>        # git switch <branch>
gswc <new-branch>   # git switch -c <new-branch>
```

**Status & Log**

```bash
gst                 # git status
gss                 # git status -s
glog                # git log --oneline --decorate --graph
gloga               # git log --oneline --decorate --graph --all
```

**Stash**

```bash
gsta                # git stash push
gstp                # git stash pop
gstl                # git stash list
```

**Reset**

```bash
grh                 # git reset
grhh                # git reset --hard
gpristine           # git reset --hard && git clean -dfx
```

**Lazygit**

```bash
lg                  # open lazygit
```

## 3. Xcode

```bash
# Build with xcodebuild (params required)
xbuild --workspace your_workspace --scheme your_scheme --configuration Debug

# Clean
xclean --workspace your_workspace --scheme your_scheme --configuration Release

# Archive
xarchive --workspace your_workspace --scheme your_scheme --configuration Release --archive-path ./build/your_scheme.xcarchive

# Carthage build
carthage_build --package-name your_package_name
```

## 4. File Listing (eza)

```bash
ls                  # eza with icons
l                   # long format + git status
ll                  # long format + hidden files
la                  # list all (including hidden)
lt                  # tree view (2 levels)
lr                  # sort by modification time
lb                  # sort by file size
```

## 5. Shell Operations

**Directory Navigation**

```bash
z <keyword>         # zoxide smart jump (frequency-based)
cd <dir>            # AUTO_CD enabled, just type the directory name
rd                  # ratatui directory picker
```

**Search & Completion**

```bash
Ctrl+R              # fzf history search
Ctrl+T              # fzf file search
Alt+C               # fzf directory jump
Tab                 # fzf-tab enhanced completion (with preview)
```

Inside `fzf-tab` completion:
- `,` / `.` switch groups
- `/` continuous selection
- `Ctrl+D` / `Ctrl+U` scroll preview

**IP Info**

```bash
ipshow              # show both LAN + WAN IP
ipshow -l           # LAN only
ipshow -p           # WAN only
```

**DNS Flush**

```bash
dns:flush           # flush macOS DNS cache
```

**Safe Delete**

```bash
rm <file>           # uses safe-trash (recycle bin), not direct delete
real-rm <file>      # actual /bin/rm
```

**Brew Export**

```bash
brew_export         # export current brew package list
```

## 6. Neovim

Leader key is `Space`.

**Basic Editing (Vim native)**

| Action | Key |
|---|---|
| Search | `/keyword` then Enter |
| Next match | `n` |
| Previous match | `N` |
| Clear highlight | `<Space>an` |
| Yank a line | `yy` |
| Paste | `p` (after cursor) / `P` (before cursor) |
| Yank from cursor to end of line | `y$` |
| Visual select and yank | `v` → move cursor → `y` |
| Jump to file start | `gg` |
| Jump to file end | `G` |
| Jump to line start | `0` (absolute) / `^` (first non-blank) |
| Jump to line end | `$` |
| Exit insert mode | `jk` |

**File & Search**

| Action | Key |
|---|---|
| Find file | `Ctrl+F` |
| Global search | `<Space>as` |
| Recent files | `<Space>fr` |
| File explorer | `<Space>fl` |
| Toggle sidebar | `<Space>fh` |
| Save file | `<Space>fw` |

**Buffer & Tab**

| Action | Key |
|---|---|
| List buffers | `Ctrl+B` or `<Space>bb` |
| Previous buffer | `{` |
| Next buffer | `}` |
| Close current buffer | `Ctrl+C` or `<Space>bc` |
| Close other buffers | `<Space>bo` |
| New tab | `<Space>tn` |
| Close tab | `<Space>tc` |
| List tabs | `<Space>tt` |
| Go to tab N | `<Space>t1` ~ `<Space>t9` |

**Window / Split Navigation**

| Action | Key |
|---|---|
| Navigate left / down / up / right | `Ctrl+H` / `Ctrl+J` / `Ctrl+K` / `Ctrl+L` |

**Git (inside Neovim)**

| Action | Key |
|---|---|
| Open Neogit | `<Space>gg` |
| Open Lazygit | `<Space>gG` |
| Stage hunk | `<Space>gs` |
| Stage buffer | `<Space>gS` |
| Next / prev hunk | `<Space>gj` / `<Space>gk` |
| Preview hunk | `<Space>gh` |
| Blame | `<Space>gb` |
| Diff | `<Space>gdd` |

**LSP**

| Action | Key |
|---|---|
| Rename | `<Space>rn` or `<Space>ln` |
| Code action | `ca` or `<Space>la` |
| Type definition | `gD` |
| Implementation | `gi` |
| Workspace symbols | `go` |
| Document symbols | `gl` |

**Debug (DAP)**

| Action | Key |
|---|---|
| Toggle breakpoint | `<Space>db` |
| Start / continue | `<Space>dc` |
| Step over | `<Space>dn` |
| Step into | `<Space>di` |
| Step out | `<Space>do` |
| Terminate | `<Space>dq` |
| Toggle DAP UI | `<Space>du` |

**Other**

| Action | Key |
|---|---|
| Fold / unfold | `Tab` |
| All commands | `<Space><Space>` |
| View keymaps | `<Space>ak` |
| Switch colorscheme | `<Space>ac` |
| Package manager (Lazy) | `<Space>P` |
| Switch project | `<Space>pp` |
| Zoxide jump | `<Space>z` |

## 7. tmux

Prefix key is `Ctrl+A`.

**Session**

```bash
# New session
tmux new -s <name>

# List sessions
tmux ls

# Attach to session
tmux a -t <name>

# Session picker (inside tmux)
Ctrl+A s
```

**Window & Pane**

| Action | Key |
|---|---|
| New window | `Ctrl+A c` |
| Horizontal split | `Ctrl+A \|` |
| Vertical split | `Ctrl+A -` |
| Navigate panes | `Ctrl+H/J/K/L` (shared with Neovim) |
| Resize pane | `Ctrl+A H/J/K/L` |
| Sync input to all panes | `Ctrl+A y` |

**Copy Mode**

| Action | Key |
|---|---|
| Enter copy mode | `Ctrl+A Esc` |
| Begin selection | `v` |
| Yank selection | `y` |
| Paste | `Ctrl+A p` |

**Shortcuts**

| Action | Key |
|---|---|
| Lazygit popup | `Ctrl+A g` |
| claude-dashboard | `Ctrl+A y` |
| Toggle status bar | `Ctrl+A T` |
| Reload config | `Ctrl+A r` |

**Plugins**

- `tmux-resurrect`: session persistence (survives restart)
- `tmux-continuum`: auto-save & auto-restore

## 8. Claude (AI CLI)

```bash
# Interactive chat
claude

# Direct question
claude "how to optimize this code"

# Pipe input
cat error.log | claude "analyze this error"

# Open dashboard in tmux
Ctrl+A y
```

## 9. Ruby & CocoaPods

```bash
# Install a specific Ruby version (via rvminstall script)
rvminstall 3.3.7

# Switch Ruby version
rvm use 3.3.7

# Install CocoaPods
gem install cocoapods

# Common pod operations
pod install
pod update
pod repo update
```

## 10. Disable Neovim AI Features

AI plugins are in `~/.config/nvim/lua/plugins/ai.lua`:

- `neocodeium` — code completion (Copilot-like)
- `sidekick.nvim` — Claude / Codex sidebar
- `aicommits.nvim` — AI-generated commit messages

**Option A: Disable entirely (recommended)**

Rename or delete the file; Lazy won't load plugins from a missing file:

```bash
mv ~/.config/nvim/lua/plugins/ai.lua ~/.config/nvim/lua/plugins/ai.lua.bak
```

**Option B: Disable individual plugins**

Edit `ai.lua` and add `enabled = false` to each plugin you want to skip:

```lua
return {
    {
        "monkoose/neocodeium",
        enabled = false,  -- disable AI completion
        -- ...
    },
    {
        "folke/sidekick.nvim",
        enabled = false,  -- disable Claude / Codex sidebar
        -- ...
    },
    {
        "404pilo/aicommits.nvim",
        enabled = false,  -- disable AI commit
    },
}
```

Restart Neovim and run `:Lazy` to confirm plugins are no longer loaded.

## 11. Other Commands

```bash
# Ruby code formatting
rubyfmt
```

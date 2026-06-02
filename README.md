<p align="center">
  <img src="assets/logo.svg" alt="Dotfiles" width="120" />
</p>

<p align="center">
  <strong>Dotfiles</strong>
  <br />
  Personal configuration for Apple Silicon macOS — experimental Linux support (Arch / Debian / Ubuntu) —<br/>
  one-command bootstrap, XDG-compliant layout, unified <a href="https://github.com/catppuccin/catppuccin">Catppuccin Mocha</a> theme.
</p>

<p align="center">
  <a href="https://github.com/catppuccin/catppuccin"><img src="https://img.shields.io/badge/Theme-Catppuccin%20Mocha-cba6f7?style=flat-square&labelColor=1e1e2e" alt="Catppuccin Mocha" /></a>
</p>

<p align="center">
  <a href="https://github.com/zsh-users/zsh"><img src="https://img.shields.io/badge/Shell-Zsh%2FBash-4EAA25?style=flat-square&logo=gnu-bash" alt="Shell" /></a>
  <a href="https://github.com/neovim/neovim"><img src="https://img.shields.io/badge/Lua-Neovim-2C2D72?style=flat-square&logo=lua" alt="Lua" /></a>
  <a href="https://github.com/ruby/ruby"><img src="https://img.shields.io/badge/Ruby-Tooling-CC342D?style=flat-square&logo=ruby" alt="Ruby" /></a>
  <a href="https://github.com/swiftlang/swift"><img src="https://img.shields.io/badge/Swift-Apple-F05138?style=flat-square&logo=swift" alt="Swift" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-primary-000000?style=flat-square&logo=apple" alt="macOS" />
  <img src="https://img.shields.io/badge/Arch_Linux-experimental-1793D1?style=flat-square&logo=arch-linux&logoColor=white" alt="Arch Linux" />
  <img src="https://img.shields.io/badge/Debian-experimental-A81D33?style=flat-square&logo=debian&logoColor=white" alt="Debian" />
  <img src="https://img.shields.io/badge/Ubuntu-experimental-E95420?style=flat-square&logo=ubuntu&logoColor=white" alt="Ubuntu" />
</p>

---

## Platform

### Primary: macOS

Developed and tested on:

| | |
|---|---|
| **OS** | macOS Tahoe 26.3.1 |
| **Hardware** | Apple M4 (arm64) |
| **Architecture** | ARM64 — any Apple Silicon Mac (M1 and later) should work |

Intel Macs are **allowed but untested** — the installer prompts for confirmation before proceeding on x86_64.

### Experimental: Linux

Arch Linux, Debian, and Ubuntu are supported on a best-effort basis. macOS-only features (AeroSpace, JankyBorders, Ghostty shaders, `osascript` notifications, Xcode tooling) are automatically skipped. The package installer maps Homebrew formulae and casks to native equivalents where available; unrecognized packages are skipped with a warning.

### Tool Versions

| Tool | Version |
|---|---|
| zsh | 5.9 |
| [Ghostty](https://ghostty.org) *(default terminal)* | 1.3.1 |
| [kitty](https://sw.kovidgoyal.net/kitty/) *(alternative terminal)* | 0.46.2 |
| [Starship](https://starship.rs) | 1.25.0 |
| [Neovim](https://neovim.io) | 0.12.2 |
| [tmux](https://github.com/tmux/tmux) | 3.6a |
| [lazygit](https://github.com/jesseduffield/lazygit) | 0.61.1 |
| [eza](https://github.com/eza-community/eza) | 0.23.4 |
| [bat](https://github.com/sharkdp/bat) | 0.26.1 |
| [fzf](https://github.com/junegunn/fzf) | 0.72.0 |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | 0.9.9 |
| [delta](https://github.com/dandavison/delta) | 0.19.2 |
| [btop](https://github.com/aristocratos/btop) | 1.4.6 |
| [Yazi](https://github.com/sxyazi/yazi) | 26.5.6 |

---

## Previews

<table>
  <tbody>
    <tr>
      <td align="center" width="50%">
        <video src="https://github.com/user-attachments/assets/1a1e6e53-c6d6-4536-a2a9-12e7e285cf34" controls width="100%"></video>
        <br/>
        <strong>Ghostty — Terminal</strong><br/>
        <sub>Catppuccin Mocha · background blur · cursor warp shader</sub>
      </td>
      <td align="center" width="50%">
        <video src="https://github.com/user-attachments/assets/5dd613dc-d6b5-471e-8efa-d0f6a799a6de" controls width="100%"></video>
        <br/>
        <strong>kitty — Terminal (alt)</strong><br/>
        <sub>Catppuccin Mocha · same font + keybinds as Ghostty</sub>
      </td>
    </tr>
    <tr>
      <td align="center" width="50%">
        <img src="https://raw.githubusercontent.com/hsuyelin/dotfiles/refs/heads/main/assets/screenshots/starship.png" width="100%" alt="Starship prompt" />
        <br/>
        <strong>Starship — Prompt</strong><br/>
        <sub>Catppuccin Mocha palette · git status · clock</sub>
      </td>
      <td align="center" width="50%">
        <video src="https://github.com/user-attachments/assets/2d5f83ed-4d26-426b-b02d-a6641253369a" controls width="100%"></video>
        <br/>
        <strong>Neovim — Editor</strong><br/>
        <sub>vim.pack · LSP · Treesitter</sub>
      </td>
    </tr>
    <tr>
      <td align="center" width="50%">
        <video src="https://github.com/user-attachments/assets/991d2c8c-5c27-4be9-beda-8240b82d6379" controls width="100%"></video>
        <br/>
        <strong>AeroSpace — Window Manager</strong><br/>
        <sub>Tiling · JankyBorders · vim-style workspace navigation</sub>
      </td>
      <td align="center" width="50%">
        <img src="https://raw.githubusercontent.com/hsuyelin/dotfiles/refs/heads/main/assets/screenshots/btop.png" width="100%" alt="btop system monitor" />
        <br/>
        <strong>btop — System Monitor</strong><br/>
        <sub>Catppuccin Mocha theme</sub>
      </td>
    </tr>
    <tr>
      <td align="center" width="50%">
        <video src="https://github.com/user-attachments/assets/5811ce6d-8731-4ec0-b319-ad223cf49e1b" controls width="100%"></video>
        <br/>
        <strong>lazygit — Git TUI</strong><br/>
        <sub>Delta diff pager · full keyboard workflow</sub>
      </td>
      <td align="center" width="50%">
        <video src="https://github.com/user-attachments/assets/2ba9881e-f32f-4e03-a338-c458d28c9624" controls width="100%"></video>
        <br/>
        <strong>Yazi — File Manager</strong><br/>
        <sub>Catppuccin Mocha · image/video/PDF/archive preview</sub>
      </td>
    </tr>
  </tbody>
</table>

---

## Stack

| Layer | Tool | Notes |
|---|---|---|
| Shell | [zsh](https://www.zsh.org) + [zi](https://github.com/z-shell/zi) | XDG-compliant · lazy plugin loading |
| Plugins | fast-syntax-highlighting · zsh-autosuggestions · fzf-tab · zsh-eza | All lazy-loaded via zi |
| Prompt | [Starship](https://starship.rs) | Catppuccin Mocha palette |
| Terminal | [Ghostty](https://ghostty.org) *(default)* | Blur · CJK font map · cursor warp shader · quick terminal |
| Terminal (alt) | [kitty](https://sw.kovidgoyal.net/kitty/) | Same theme + keybinds; no cursor shader or quick terminal |
| Editor | [Neovim](https://neovim.io) | vim.pack · LSP · Treesitter |
| Window Manager | [AeroSpace](https://github.com/nikitabobko/AeroSpace) | Tiling · vim-style keybinds |
| Window Borders | [JankyBorders](https://github.com/FelixKratz/JankyBorders) | Auto-launched by AeroSpace |
| File manager | [Yazi](https://github.com/sxyazi/yazi) | `yy` alias · Catppuccin Mocha · image/video/PDF/archive preview |
| File listing | [eza](https://github.com/eza-community/eza) | Replaces `ls` · icons · git status |
| Fuzzy finder | [fzf](https://github.com/junegunn/fzf) + [zoxide](https://github.com/ajeetdsouza/zoxide) | `z` for directory jumping |
| Diff pager | [delta](https://github.com/dandavison/delta) | Syntax-highlighted git diffs |
| Git TUI | [lazygit](https://github.com/jesseduffield/lazygit) | `lg` alias |
| Syntax highlight | [bat](https://github.com/sharkdp/bat) | Catppuccin Mocha theme |
| System monitor | [btop](https://github.com/aristocratos/btop) | Catppuccin Mocha theme |
| Markdown reader | [glow](https://github.com/charmbracelet/glow) | Terminal markdown renderer |
| Package manager | [Homebrew](https://brew.sh) | Formulae + casks declared in `brew/` |
| AI assistant | [Claude Code](https://claude.ai/code) + RTK | Catppuccin Mocha/Latte custom themes · RTK token-optimizer hook |

---

## Install

### One-command bootstrap (fresh machine)

```bash
DOTFILES_REPO=https://github.com/hsuyelin/dotfiles \
  bash <(curl -fsSL https://raw.githubusercontent.com/hsuyelin/dotfiles/main/bootstrap.sh)
```

`bootstrap.sh` runs these steps in order:

1. Verify platform (macOS, ARM64)
2. Install Xcode Command Line Tools
3. Install Homebrew
4. Clone this repo to `~/.config`
5. **Prompt: select terminal** — Ghostty or kitty (30 s timeout → Ghostty)
6. Run `install.sh`
7. Install Homebrew formulae and casks from `brew/`
8. Install RVM

### Already have `~/.config` cloned?

```bash
bash ~/.config/install.sh
```

Idempotent — safe to re-run on an existing machine. Also prompts for terminal selection if neither Ghostty nor kitty is installed.

### Linux (experimental)

`bootstrap.sh` is macOS-only. On Linux, clone and run the installer directly:

```bash
git clone https://github.com/hsuyelin/dotfiles ~/.config
bash ~/.config/install.sh
```

Then install packages:

```bash
bash ~/.config/bin/brew_install.sh
```

`install.sh` detects Arch / Debian / Ubuntu automatically. macOS-only steps (Homebrew, AeroSpace, Ghostty shaders, Xcode) are skipped. `brew_install.sh` maps Homebrew formulae and casks to native package manager equivalents; packages with no Linux mapping are skipped with a warning.

### Terminal selection

During install, you will see:

```
Select a terminal emulator:
  [1] Ghostty  (default — cursor shaders, quick terminal, full feature set)
  [2] kitty    (alternative — same Catppuccin Mocha theme, compatible keybinds)
  [3] iTerm2   (classic — import iterm2/Catppuccin-Mocha.itermcolors)

Choice [1/2/3] (auto-selects Ghostty in 30 s):
```

Press `Enter` or wait 30 seconds to accept Ghostty. To skip the prompt entirely:

```bash
# Force Ghostty (non-interactive / CI-friendly)
bash bootstrap.sh --terminal=ghostty

# Force kitty
bash bootstrap.sh --terminal=kitty

# Force iTerm2
bash bootstrap.sh --terminal=iterm2
```

The `--terminal` flag is case-insensitive (`--terminal=iTerm2` also works).

To switch terminals after install, re-run with the desired flag — then follow the two-line swap in `aerospace/aerospace.toml` (instructions are in the file header).

### Options

| Flag | Applies to | Effect |
|---|---|---|
| `--dry-run` | both | Print what would happen, make no changes |
| `--terminal=ghostty` | both | Install Ghostty, skip other terminals |
| `--terminal=kitty` | both | Install kitty, skip other terminals |
| `--terminal=iterm2` | both | Install iTerm2, skip other terminals |
| `--skip-rvm` | `bootstrap.sh` | Skip RVM installation |
| `--skip-rtk` | `install.sh` | Skip RTK (Rust Token Killer) |

---

## Post-Install Checklist

Fill in the gitignored private files created as stubs by `install.sh`:

```
~/.config/private/git.config       # git user.name, user.email, github.user
~/.config/secrets/.env.secrets     # environment secrets
~/.config/secrets/.ai.secrets      # AI API keys
```

Then:

- Open **tmux** → `<prefix>+I` to install plugins via TPM
- Open **Neovim** — vim.pack installs plugins automatically on first launch
- Open **Ghostty** — cursor shader loads from `ghostty/shaders/`
- Open **Yazi** — run `yy` to launch; exits back to the directory you navigated to
- Install a Ruby version: `rvminstall 3.x.x`

---

## Directory Layout

```
~/.config/
├── .github/         # CI/CD — tag-based release workflow + asset cleanup
├── aerospace/       # AeroSpace tiling WM
├── alias/           # Shell aliases
├── assets/          # Repository assets (logo, screenshots)
├── bash/            # bash_profile, AI shell helpers
├── bat/             # bat syntax highlighter — Catppuccin Mocha theme
├── bin/             # Utility scripts (brew export, Carthage, Xcode helpers)
├── borders/         # JankyBorders config
├── brew/            # Homebrew formulae + casks
├── btop/            # System monitor — Catppuccin Mocha theme
├── bundle/          # Bundler config
├── claude/          # Claude Code — Catppuccin Mocha / Latte custom themes
├── fzf/             # Fuzzy finder shell integration
├── ghostty/         # Ghostty terminal — cursor shaders (default terminal)
├── git/             # Global git config + commit template
├── glow/            # Glow markdown renderer config
├── iterm2/          # iTerm2 color preset (Catppuccin Mocha)
├── kitty/           # kitty terminal config (alternative, mirrors Ghostty)
├── lazygit/         # lazygit TUI config
├── npm/             # npm XDG config
├── nvim/            # Neovim — vim.pack · LSP · Treesitter
├── yazi/            # Yazi file manager — Catppuccin Mocha · image/video/PDF/archive preview
├── rtk/             # RTK (Rust Token Killer) — Claude Code hook config
├── rvm/             # RVM install helper
├── starship/        # Starship prompt — Catppuccin Mocha palette
├── swiftformat/     # SwiftFormat rules
├── tmux/            # tmux config + TPM plugins
├── zsh/             # .zshrc · .zprofile · env/ · zi plugin config
├── private/         # gitignored — personal identity (git name / email)
├── secrets/         # gitignored — API keys, tokens
├── bootstrap.sh     # One-command machine setup (run once on new hardware)
└── install.sh       # Dotfiles installer — idempotent, safe to re-run
```

---

## Yazi

[Yazi](https://github.com/sxyazi/yazi) is configured as a full-featured terminal file manager. Launch with `yy` — the shell exits back to whatever directory you navigated to.

### Preview support

| Format | Backend |
|---|---|
| Images (PNG/JPG/GIF/WebP) | Kitty image protocol (native, zero deps) |
| SVG · HEIC · JPEG XL · Fonts | `imagemagick` |
| Video thumbnails | `ffmpegthumbnailer` |
| PDF | `poppler` (`pdftoppm`) |
| Archives (zip/tar/7z/rar/…) | `unar` |
| JSON | built-in |
| Code (Swift · ObjC · Python · Go · Bash · Rust · Ruby · …) | built-in syntect + Catppuccin Mocha `.tmTheme` |
| Markdown | built-in |

### Keybindings (custom additions)

| Key | Action |
|---|---|
| `z` | Jump to directory via **zoxide** |
| `<C-f>` | Jump to directory via **fzf** |
| `/` | Find by filename (**fd**) |
| `<C-s>` | Search file content (**ripgrep**) |
| `e` | Open in `$EDITOR` |
| `E` | Open with interactive picker |
| `R` | Reveal in Finder |
| `<C-u>` / `<C-d>` | Scroll half-page up / down |
| `V` / `<C-a>` | Select all |
| `T` | New tab in current directory |
| `gs` / `gS` / `gm` | Sort: natural / size-desc / mtime-desc |

All default vim-style bindings (`h/j/k/l`, `y/d/p/D/r/a`, `gg/G`, `.`, `q`, …) are preserved.

### Theme

Uses the [Catppuccin Mocha](https://github.com/catppuccin/yazi) flavor, stored at `yazi/flavors/catppuccin-mocha.yazi/flavor.toml`. The code previewer reuses the same `.tmTheme` file as `bat` for identical colors in both tools.

---

## Design Notes

**XDG compliance** — Everything lives under `~/.config`. A single `~/.zshenv` bootstraps `ZDOTDIR`; no scattered dotfiles in `$HOME`.

**Private by default** — `private/git.config` holds identity; `secrets/` holds credentials. Both are gitignored and stubbed by `install.sh`. The repo contains zero personal data.

**Theme consistency** — [Catppuccin](https://github.com/catppuccin/catppuccin) is the single theme family applied uniformly across every tool: Ghostty, Starship, bat, btop, Neovim, lazygit, and Yazi all use **Mocha** (dark). Claude Code ships two custom themes — **Mocha** (dark) and **Latte** (light) — selectable via `/theme`. Colors, contrast, and accent palette are identical everywhere — no visual context-switching between tools.

**Idempotency** — Every script is safe to re-run. Existing files are never overwritten; completed steps are logged and skipped.

---

## License

[MIT](LICENSE) © 2026 hsuyelin

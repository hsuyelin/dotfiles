# Repository Structure

This repository is a personal dotfiles collection for **macOS**.

<p align="center">
  <a href="STRUCTURE.md">English</a> · <a href="STRUCTURE_CN.md">中文</a>
</p>

## Top-level directories

- `aerospace/`: AeroSpace window manager configuration.
- `alias/`: Shell aliases and helper functions.
- `bash/`: Bash profile and environment setup (loads `secrets/` and `private/` when present).
- `bin/`: Local scripts (brew export, xcode helpers, etc.).
- `borders/`: Window border configuration.
- `brew/`: Homebrew package lists.
- `btop/`: btop configuration and theme.
- `crossnote/`: Crossnote markdown preview configuration.
- `git/`: Git configuration (includes private user config via `private/git.config`).
- `iterm2/`: iTerm2 configuration.
- `lazygit/`: lazygit configuration.
- `nvim/`: Neovim configuration (Lua).
- `spicetify/`: Spicetify configuration.
- `swiftformat/`: SwiftFormat configuration.
- `swiftpm/`: SwiftPM configuration.
- `tmux/`: tmux configuration.
- `vim/`: Vim configuration.
- `zsh/`: Zsh configuration.

## Ignored directories

- `secrets/`: API keys/tokens (never committed).
- `private/`: personal/company info and machine-specific paths (never committed).
- `zi/plugins/`, `tmux/plugins/`, `vim/.vim/plugged/`: third-party plugin installs managed at runtime.

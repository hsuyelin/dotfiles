# Dotfiles

Personal dotfiles for **macOS**.

## Scope and Compatibility

**NOTE (current machine):** validated on **macOS 26.1** (Build **25B78**), **Apple M4 (Mac mini)**, **16 GB RAM**, **zsh 5.9**, **Neovim 0.11.5**, **tmux 3.6a**, **git 2.39.5**.

- These configs are tuned for the environment above.
- Other macOS machines may require adjustments.
- Other operating systems should treat this repo as a reference only.

## What’s Included

- `zsh/`: Zsh setup using **zi** and Powerlevel10k.
- `nvim/`: Neovim (Lua) configuration.
- `tmux/`: tmux configuration (TPM-based workflow, session persistence).
- `aerospace/`: window management via AeroSpace.
- `git/`: global Git configuration and aliases.
- `alias/`, `bash/`, `bin/`: shell helpers and scripts.

## Privacy / Open Source Safety

This repository is structured so you can publish it to GitHub without leaking:

- `secrets/` is **gitignored** and intended for tokens/keys.
- `private/` is **gitignored** and intended for personal/company identifiers and machine-specific paths.

### Required local files

Create these files locally (they are ignored by git):

- `~/.config/secrets/.ai.secrets`
- `~/.config/secrets/.env.secrets`
- `~/.config/private/git.config`
- `~/.config/private/zsh.zprofile`

See `docs/STRUCTURE.md` for details.

## Quick Start

1. Clone this repo into `~/.config`.
2. Create the local `secrets/` and `private/` files.
3. Restart your shell or source configs as needed.

## Documentation

- `docs/STRUCTURE.md`

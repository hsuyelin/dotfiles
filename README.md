<p align="center">
  <img src="assets/logo.svg" alt="Dotfiles" width="120" />
</p>

<p align="center">
  <strong>Dotfiles</strong>
  <br />
  A fast, opinionated macOS setup for terminal + editor.
  <br />
  <a href="README.md">English</a> · <a href="README_CN.md">中文</a>
</p>

---

## Highlights

- Zsh + zi + Powerlevel10k
- Neovim (Lua) with LSP/DAP/quality-of-life plugins
- tmux workflow with session persistence
- AeroSpace tiling + workspace routing
- Git aliases + delta diff

## Scope and Compatibility

**NOTE (current machine):** validated on **macOS 26.1** (Build **25B78**), **Apple M4 (Mac mini)**, **16 GB RAM**, **zsh 5.9**, **Neovim 0.11.5**, **tmux 3.6a**, **git 2.39.5**.

- These configs are tuned for the environment above.
- Other macOS machines may require adjustments.
- Other operating systems should treat this repo as a reference only.

## What’s Inside

- `zsh/`: Zsh setup using **zi** and Powerlevel10k.
- `nvim/`: Neovim (Lua) configuration.
- `tmux/`: tmux configuration (TPM-based workflow, session persistence).
- `aerospace/`: window management via AeroSpace.
- `git/`: global Git configuration and aliases.
- `alias/`, `bash/`, `bin/`: shell helpers and scripts.

## Private Stuff

This repo is safe to publish: personal/company info and tokens are **not** committed.

- Create your own local files under `secrets/` and `private/` (both are gitignored).

## Quick Start

1. Clone this repo into `~/.config`.
2. Create the local `secrets/` and `private/` files.
3. Restart your shell or source configs as needed.

## Documentation

- `docs/STRUCTURE.md`

<p align="center">
  <img src="assets/logo.svg" alt="Dotfiles" width="120" />
</p>

<p align="center">
  <strong>Dotfiles</strong>
  <br />
  A personal macOS setup shared for reference and reuse.
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/Shell-Zsh%2FBash-4EAA25?style=flat-square&logo=gnu-bash" alt="Shell" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Lua-Neovim-2C2D72?style=flat-square&logo=lua" alt="Lua" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Ruby-Tooling-CC342D?style=flat-square&logo=ruby" alt="Ruby" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Vim%20Script-Vim-019733?style=flat-square&logo=vim" alt="Vim Script" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Swift-Apple-F05138?style=flat-square&logo=swift" alt="Swift" /></a>
  <br />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License" /></a>
</p>

---

<p align="center">
  <a href="README.md">English</a> · <a href="README_CN.md">中文</a>
</p>

> [!NOTE]
> * This repo is a production-tested personal setup. It’s published for reference and reuse, not as a one-size-fits-all installer.
> * Some parts are inspired by other great GitHub dotfiles, and others are based on my personal understanding. They may not be the most optimal or advanced, so please take them as a reference.

## Audience

This repo is for developers who want a reproducible macOS CLI stack with high leverage:

- A cohesive Zsh + tmux + Neovim workflow
- A consistent visual and interaction model across the terminal stack
- A pragmatic setup you can iterate on without losing track

If you want a general-purpose “one script installs everything for everyone” project, use this repo as a reference, not a drop-in solution.

## Reference machine

![Environment](assets/env.png)

This is the machine these configs are primarily tuned and iterated on:

| Item | Value |
| --- | --- |
| OS | macOS 26.1 (Build 25B78) |
| Hardware | Apple M4 (Mac mini), 16 GB RAM |
| Shell | zsh 5.9 |
| Editor | Neovim 0.11.5 |
| Multiplexer | tmux 3.6a |
| Git | git 2.39.5 |

## Preview (iTerm2)

![iTerm2 Preview](assets/preview.png)

## What’s included

- **Shell**: Zsh + `zi` + Powerlevel10k
- **Editor**: Neovim (Lua) with LSP/DAP and day-to-day plugins
- **Multiplexer**: tmux workflow + session persistence
- **Window management**: AeroSpace tiling + workspace routing
- **Git UX**: aliases + `delta` diffs

## Philosophy

- Keep the terminal stack consistent (fonts, colors, keybindings)
- Prefer simple, composable tools over “magic”
- Make it easy to adopt incrementally (copy what you need)

## Repo layout

- `zsh/` — Zsh config (zi + Powerlevel10k)
- `nvim/` — Neovim (Lua)
- `tmux/` — tmux config
- `aerospace/` — AeroSpace config
- `git/` — Git config + aliases
- `alias/`, `bash/`, `bin/` — helpers and scripts

For the complete list of directories, see [`docs/STRUCTURE.md`](docs/STRUCTURE.md).

## Compatibility

Designed for macOS; other OSes should treat this repo as a reference.

## Privacy

Keep anything personal or environment-specific in `secrets/` and `private/`.
Both are gitignored, so you won’t see my actual structure in this repo.
If you want a reference, see:

<p>
  <img src="assets/private.png" alt="private" width="48%" />
  <img src="assets/secrets.png" alt="secrets" width="48%" />
</p>

## Getting started

1. Clone this repo into `~/.config`.
2. Create any local-only files under `secrets/` and `private/`.
3. Restart your shell (or source configs) and iterate.

## How to reference this repo

If you want to borrow parts of this setup rather than adopt it wholesale:

1. **Scan the layout**: start with [`docs/STRUCTURE.md`](docs/STRUCTURE.md) to locate the area you care about.
2. **Pick one surface**: shell, editor, tmux, or git — adopt a single layer at a time.
3. **Copy configs, not assumptions**: port the files you need, then adjust paths, fonts, and plugin lists for your system.
4. **Keep secrets local**: anything machine-specific belongs in `secrets/` or `private/`.
5. **Iterate in small steps**: apply a change, reload, and validate before moving on.

## Backup and XDG setup

Before adopting any configs, archive your existing setup:

1. **Create a snapshot**: move your current config into a dated backup folder.
2. **Identify common targets**: `~/.zshrc`, `~/.zprofile`, `~/.tmux.conf`, `~/.gitconfig`, and `~/.config/nvim`.
3. **Preserve local secrets**: SSH keys, tokens, and machine-specific files should stay outside the repo.

Suggested backup commands:

```bash
mkdir -p ~/dotfiles-backup/$(date +%Y%m%d)
mv ~/.zshrc ~/.zprofile ~/.tmux.conf ~/.gitconfig ~/dotfiles-backup/$(date +%Y%m%d)/ 2>/dev/null
mv ~/.config/nvim ~/dotfiles-backup/$(date +%Y%m%d)/ 2>/dev/null
```

XDG base directory variables help tools resolve configs from `~/.config`:

```bash
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
```

Place these in your shell profile (e.g. `~/.zprofile`) to ensure tools load configs from `~/.config`.

## Benefits & trade-offs

Benefits:

- A cohesive, production-grade terminal workflow with minimal drift over time
- Clear separation between shared configs and local secrets
- Incremental adoption; copy only what you need
 - Easy to audit; everything is plain text and versioned

Trade-offs:

- Opinionated defaults; you will likely want to tune keybindings and plugins
- macOS-first; other OSes should treat this as a reference
- Existing configs can be overwritten if you merge without care
 - Some tools assume Homebrew, so expect minor adjustments elsewhere

## Reference

- Structure overview: [`docs/STRUCTURE.md`](docs/STRUCTURE.md)

## License

This repo is licensed under the MIT License. Use, copy, and modify freely. Please respect the MIT terms. See [`LICENSE`](LICENSE) for details.

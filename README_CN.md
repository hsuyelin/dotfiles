<p align="center">
  <img src="assets/logo.svg" alt="Dotfiles" width="120" />
</p>

<p align="center">
  <strong>Dotfiles</strong>
  <br />
  面向自用的 macOS 终端与编辑器配置分享。
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
> 该仓库主要用于个人备份与同步，仅供参考；并非面向所有人的“一键即用”方案。

## 适合谁用？

如果你想要一个可复用的 macOS CLI 环境，这个仓库适合你：

- 统一的 Zsh + tmux + Neovim 工作流
- 终端栈的外观与交互保持一致
- 配置可逐步演进、可控且不容易“失控”

如果你更偏好“一个脚本给所有人装全套”的项目，这里更适合作为参考模板。

## 参考环境

![电脑配置](assets/env.png)

这些配置主要在以下机器上长期迭代与微调：

| 项目 | 配置 |
| --- | --- |
| 系统 | macOS 26.1（Build 25B78） |
| 硬件 | Apple M4（Mac mini），16 GB 内存 |
| Shell | zsh 5.9 |
| 编辑器 | Neovim 0.11.5 |
| 复用会话 | tmux 3.6a |
| Git | git 2.39.5 |

## 预览（iTerm2）

![iTerm2 预览](assets/preview.png)

## 包含内容

- **Shell**：Zsh + `zi` + Powerlevel10k
- **编辑器**：Neovim（Lua）+ LSP/DAP 与常用增强插件
- **复用会话**：tmux 工作流 + 会话持久化
- **窗口管理**：AeroSpace 平铺 + 工作区分流
- **Git 体验**：aliases + `delta` diff

## 理念

- 终端栈尽可能保持一致（字体、配色、按键习惯）
- 倾向简单可组合的工具，而不是“黑盒魔法”
- 便于按需取用（从一小部分开始逐步接入）

## 仓库结构

- `zsh/`：Zsh 配置（zi + Powerlevel10k）
- `nvim/`：Neovim（Lua）
- `tmux/`：tmux 配置
- `aerospace/`：AeroSpace 配置
- `git/`：Git 配置与别名
- `alias/`、`bash/`、`bin/`：常用别名与脚本

完整目录清单见：`docs/STRUCTURE.md`。

## 兼容性

面向 macOS；其他系统请仅作为参考。

## 隐私

该仓库可以直接开源：个人/公司信息与 token 不会被提交。

- 建议把机器相关 / 敏感内容放到 `secrets/`、`private/`（两者均已 gitignore）。

## 快速开始

1. 将仓库克隆到 `~/.config`。
2. 在 `secrets/`、`private/` 下创建你的本地文件。
3. 重启 shell（或按需 source）并逐步微调。

## 如何作为参考使用

如果你只是想“借用”其中一部分而非全量采用，建议按以下方式操作：

1. **先看结构**：从 `docs/STRUCTURE.md` 了解目录与配置入口。
2. **先选一个层级**：优先从 shell / editor / tmux / git 中选一块开始。
3. **复制配置，不复制假设**：移植对应文件后再根据你的路径、字体、插件做调整。
4. **本地化私密内容**：机器相关或敏感信息统一放在 `secrets/`、`private/`。
5. **小步迭代**：每次改动后 reload 并验证，避免一次性大改。

## 备份与 XDG 设置

在迁移之前，建议先把旧配置打包归档：

1. **建立快照**：将现有配置移动到带日期的备份目录。
2. **关注常见文件**：`~/.zshrc`、`~/.zprofile`、`~/.tmux.conf`、`~/.gitconfig`、`~/.config/nvim`。
3. **保留私密信息**：SSH 密钥、token、机器相关文件请放在仓库之外。

备份示例命令：

```bash
mkdir -p ~/dotfiles-backup/$(date +%Y%m%d)
mv ~/.zshrc ~/.zprofile ~/.tmux.conf ~/.gitconfig ~/dotfiles-backup/$(date +%Y%m%d)/ 2>/dev/null
mv ~/.config/nvim ~/dotfiles-backup/$(date +%Y%m%d)/ 2>/dev/null
```

XDG 目录变量用于让工具从 `~/.config` 读取配置：

```bash
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
```

将以上变量写入你的 shell profile（例如 `~/.zprofile`），确保相关工具优先读取 `~/.config`。

## 参考

- 目录结构说明：`docs/STRUCTURE.md`

## 许可说明

本仓库采用 MIT License，可自由使用、复制与修改，但不提供任何担保。详见 `LICENSE`。

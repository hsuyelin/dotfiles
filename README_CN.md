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
> * 该仓库主要用于个人备份与同步，仅供参考；并非面向所有人的“一键即用”方案。
> * 部分配置参考了其他优秀的 GitHub 仓库，也有不少是基于个人理解的实践，并非最优或最高级配置，请多包涵。

## 适合谁用？

如果你想要一个可复用的 macOS CLI 环境，尤其是觉得配置开发环境既无聊又费时（例如 iOS / macOS 开发者）——这个仓库也许能帮你省不少事。它提供了：

- 开箱即用的 Zsh + tmux + Neovim 工作流
- 终端栈的外观与交互保持一致（字体、配色、快捷键）
- 一键引导脚本（`install.sh`）—— Homebrew、软件包、Shell、Ruby 工具链一步到位
- 内置 Git 别名、模糊搜索、智能目录跳转、安全删除，提升日常效率
- Neovim 预配置 LSP / DAP、文件浏览器和 AI 插件
- Zsh 使用 [Zi](https://wiki.zshell.dev) 管理插件——快速、功能丰富，替代 Oh My Zsh
- 可复用、可逐步演进，长期维护也不会变得混乱

> **为什么用 Zi 而不是 Oh My Zsh？** Oh My Zsh 在启动时加载所有插件，随着插件增多会明显拖慢 shell 启动。[Zi](https://wiki.zshell.dev) 支持懒加载、turbo 模式和对每个插件的细粒度控制，可将 Zsh 启动速度提升 50–80%，同时兼容绝大部分 Oh My Zsh 插件和 Prezto 模块。

如果你更偏好“一个脚本给所有人装全套”的项目，这里更适合作为参考模板。

## 参考环境

![电脑配置](assets/env.png)

这些配置主要在以下机器上长期迭代与微调：

| 项目 | 配置 |
| --- | --- |
| 系统 | macOS 26.1（Build 25B78） |
| 硬件 | Apple M4（Mac mini），16 GB 内存 |
| Shell | zsh 5.9 |
| 编辑器 | Neovim 0.11.6 |
| 复用会话 | tmux 3.6a |
| Git | git 2.39.5 |

## 预览（iTerm2）

![iTerm2 预览](assets/preview.png)

日常工作流：常用工具版本、二进制路径，以及 `z`（zoxide + fzf）目录跳转效果：

![开发预览](assets/dev.png)

Neovim：Neo-tree 侧边栏、Buffer 标签页、LSP 编辑界面：

![Neovim 预览](assets/nvim.png)

## iTerm2 配置

仓库中包含两个 iTerm2 相关资源：

| 文件 | 说明 |
| --- | --- |
| [`iTerm2-template.json`](iTerm2-template.json) | 完整 Profile（字体、窗口、快捷键、配色等） |
| [`one-dark-pro.itermcolors`](one-dark-pro.itermcolors) | 独立的 One Dark Pro 配色方案文件 |

Profile 主要参数：

| 配置项 | 值 |
| --- | --- |
| 配色方案 | One Dark Pro |
| 字体 | Fira Code Nerd Font Mono, 16pt |
| 窗口大小 | 110 列 x 35 行 |
| 透明度 | ~20%，启用模糊 |

**导入完整 Profile：**

1. 打开 iTerm2 → **Settings** → **Profiles**。
2. 点击左下角 **Other Actions...** → **Import JSON Profiles...**。
3. 选择 `iTerm2-template.json`，按需设为 **Default**。

**仅导入配色方案：**

如果你已有自己的 iTerm2 Profile，只想使用 One Dark Pro 配色：

1. 打开 iTerm2 → **Settings** → **Profiles** → **Colors** 标签页。
2. 点击右下角 **Color Presets...** → **Import...**。
3. 选择 `one-dark-pro.itermcolors`，然后从预设列表中选择 **One Dark Pro**。

<details>
<summary><strong>One Dark Pro 色板参考</strong></summary>

| 角色 | Hex | 色块 |
| --- | --- | --- |
| 背景 | `#282C34` | ![#282C34](https://img.shields.io/badge/-%23282C34-282C34?style=flat-square) |
| 前景 | `#ABB2BF` | ![#ABB2BF](https://img.shields.io/badge/-%23ABB2BF-ABB2BF?style=flat-square) |
| 黑色 (ANSI 0) | `#21252B` | ![#21252B](https://img.shields.io/badge/-%2321252B-21252B?style=flat-square) |
| 红色 (ANSI 1) | `#E06C75` | ![#E06C75](https://img.shields.io/badge/-%23E06C75-E06C75?style=flat-square) |
| 绿色 (ANSI 2) | `#98C379` | ![#98C379](https://img.shields.io/badge/-%2398C379-98C379?style=flat-square) |
| 黄色 (ANSI 3) | `#E5C07B` | ![#E5C07B](https://img.shields.io/badge/-%23E5C07B-E5C07B?style=flat-square) |
| 蓝色 (ANSI 4) | `#61AFEF` | ![#61AFEF](https://img.shields.io/badge/-%2361AFEF-61AFEF?style=flat-square) |
| 品红 (ANSI 5) | `#C678DD` | ![#C678DD](https://img.shields.io/badge/-%23C678DD-C678DD?style=flat-square) |
| 青色 (ANSI 6) | `#56B6C2` | ![#56B6C2](https://img.shields.io/badge/-%2356B6C2-56B6C2?style=flat-square) |
| 白色 (ANSI 7) | `#ABB2BF` | ![#ABB2BF](https://img.shields.io/badge/-%23ABB2BF-ABB2BF?style=flat-square) |
| 选中背景 | `#323844` | ![#323844](https://img.shields.io/badge/-%23323844-323844?style=flat-square) |

</details>

> [!TIP]
> 配色方案同时内嵌在 Profile JSON 中。如果你想换一套主题，可以导入新的 `.itermcolors` 文件，或者直接替换 JSON 中的 `Ansi *` / `Background` / `Foreground` 颜色值。

## 包含内容

- **Shell**：Zsh + [`zi`](https://wiki.zshell.dev) + [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- **编辑器**：[Neovim](https://neovim.io)（Lua）+ LSP/DAP 与常用增强插件
- **复用会话**：[tmux](https://github.com/tmux/tmux) 工作流 + 会话持久化（`tmux-resurrect` / `tmux-continuum`）
- **窗口管理**：[AeroSpace](https://github.com/nikitabobko/AeroSpace) 平铺 + 工作区分流
- **Git 体验**：aliases + [`delta`](https://github.com/dandavison/delta) diff + [`lazygit`](https://github.com/jesseduffield/lazygit)
- **文件列表**：[`eza`](https://github.com/eza-community/eza) 带图标和 Git 状态
- **模糊搜索**：[`fzf`](https://github.com/junegunn/fzf) + `fzf-tab` 搜索历史、文件和补全
- **目录跳转**：[`zoxide`](https://github.com/ajeetdsouza/zoxide) — 基于访问频率的智能 `cd`
- **Ruby 工具链**：[RVM](https://rvm.io) + CocoaPods（面向 iOS / macOS 开发）

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
- `brew/`：Homebrew 包和 cask 清单
- `docs/`：[目录结构](docs/STRUCTURE.md) 与 [快速上手指南](docs/QuickStart.md)
- `install.sh`：全新 Apple Silicon Mac 一键引导脚本

完整目录清单见：[`STRUCTURE.md`](docs/STRUCTURE.md)。

## 兼容性

面向 **Apple Silicon 的 macOS**。引导脚本（`install.sh`）仅支持 `arm64` 架构。其他系统或 Intel Mac 请仅作为参考，自行适配。

## 隐私

和自己相关的隐私文件、环境变量等请按需放在 `secrets/`、`private/`。
这两个目录已在 gitignore 中忽略，因此你无法直接看到我的结构。
如果需要参考，请查看：

<p>
  <img src="assets/private.png" alt="private" width="48%" />
  <img src="assets/secrets.png" alt="secrets" width="48%" />
</p>

## 快速开始

1. 将仓库克隆到 `~/.config`。
2. 在 `secrets/`、`private/` 下创建你的本地文件。
3. 重启 shell（或按需 source）并逐步微调。

### 全新机器设置

如果你使用的是全新 Apple Silicon Mac，将仓库克隆到 `~/.config` **以外**的任意目录（脚本会自动将 dotfiles 复制到 `~/.config`）：

```bash
git clone https://github.com/hsuyelin/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh && ./install.sh
```

脚本按顺序执行完整的安装流程：架构检测、iTerm2 安装、dotfiles 复制、XDG 目录创建、Homebrew、软件包安装、Zsh、zi、RVM、Ruby、CocoaPods。脚本具有**幂等性** —— 每个步骤运行前都会检查当前状态，内置的断点恢复机制可以让你在失败后从上次中断处继续。详见 [`install.sh`](install.sh)。

### 快速上手

环境就绪后，参考 **[快速上手指南](docs/QuickStart.md)** 查看常用 alias、快捷键和命令速查表，覆盖 Git、Neovim、tmux、fzf、Ruby 等。

## 如何作为参考使用

如果你只是想“借用”其中一部分而非全量采用，建议按以下方式操作：

1. **先看结构**：从 [`STRUCTURE.md`](docs/STRUCTURE.md) 了解目录与配置入口。
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

[XDG Base Directory](https://wiki.archlinux.org/title/XDG_Base_Directory) 是 freedesktop.org 制定的规范，用于统一应用存放配置、数据、状态和缓存文件的位置。它避免了各类 dotfile 散落在 `$HOME` 中，让配置集中、易于备份和版本管理。

本仓库依赖以下 XDG 变量：

```bash
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
```

将以上变量写入你的 shell profile（例如 `~/.zprofile`），确保相关工具优先读取 `~/.config`。

你可以使用 [`xdg-ninja`](https://github.com/b3nj5m1n/xdg-ninja) 检测 `$HOME` 下哪些文件可以迁移到 XDG 规范路径：

```bash
brew install xdg-ninja
xdg-ninja
```

![xdg-ninja](assets/xdg-ninja.png)

> [!CAUTION]
> `xdg-ninja` 的建议**仅供参考**。盲目将所有配置迁移到 XDG 路径可能会导致部分工具出现意想不到的问题。迁移前请务必查阅对应工具的社区文档或上游 issue。

## 优势与取舍

优势：

- 终端工作流相对稳定，长期使用不易出现配置漂移
- 公共配置与个人隐私内容边界清晰，便于维护
- 支持按模块渐进式接入，无需一次性全量迁移
- 全部为文本配置，便于审阅与版本管理

取舍：

- 默认配置较为主观，通常需要调整键位与插件
- 以 macOS 为主，其他系统需作为参考使用
- 合并时如不谨慎可能覆盖既有配置
- 部分工具依赖 Homebrew，需做少量适配

## 参考

- 目录结构说明：[`STRUCTURE.md`](docs/STRUCTURE.md)
- 快速上手指南：[`QUICKSTART.md`](docs/QuickStart.md)
- 引导安装脚本：[`install.sh`](install.sh)

## 许可说明

本仓库采用 MIT License，可自由使用、复制与修改，请尊重 MIT 相关规范。详见 [`LICENSE`](LICENSE)。

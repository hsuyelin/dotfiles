# 仓库结构

本仓库是面向 **macOS** 的个人 dotfiles 集合。

<p align="center">
  <a href="STRUCTURE.md">English</a> · <a href="STRUCTURE_CN.md">中文</a>
</p>

## 顶层目录

- `aerospace/`：AeroSpace 窗口管理器配置。
- `alias/`：Shell 别名和辅助函数。
- `bash/`：Bash profile 和环境设置（存在时加载 `secrets/` 和 `private/`）。
- `bin/`：本地脚本（brew 导出、xcode 辅助等）。
- `borders/`：窗口边框配置。
- `brew/`：Homebrew 包列表。
- `btop/`：btop 配置和主题。
- `crossnote/`：Crossnote Markdown 预览配置。
- `git/`：Git 配置（通过 `private/git.config` 包含私有用户配置）。
- `iterm2/`：iTerm2 配置。
- `lazygit/`：lazygit 配置。
- `nvim/`：Neovim 配置（Lua）。
- `spicetify/`：Spicetify 配置。
- `swiftformat/`：SwiftFormat 配置。
- `swiftpm/`：SwiftPM 配置。
- `tmux/`：tmux 配置。
- `vim/`：Vim 配置。
- `zsh/`：Zsh 配置。

## 忽略的目录

- `secrets/`：API 密钥/令牌（永不提交）。
- `private/`：个人/公司信息和机器特定路径（永不提交）。
- `zi/plugins/`、`tmux/plugins/`、`vim/.vim/plugged/`：运行时管理的第三方插件安装。

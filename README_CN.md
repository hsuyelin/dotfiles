<p align="center">
  <img src="assets/logo.svg" alt="Dotfiles" width="120" />
</p>

<p align="center">
  <strong>Dotfiles</strong>
  <br />
  面向 macOS 的终端 + 编辑器偏好配置集合。
  <br />
  <a href="README.md">English</a> · <a href="README_CN.md">中文</a>
</p>

---

## 亮点

- Zsh + zi + Powerlevel10k
- Neovim（Lua）+ LSP/DAP/常用增强插件
- tmux 工作流 + 会话持久化
- AeroSpace 平铺 + 工作区分流
- Git aliases + delta diff

## 适用范围与兼容性

**NOTE（当前电脑环境）：** 已在 **macOS 26.1**（Build **25B78**）、**Apple M4（Mac mini）**、**16 GB 内存**、**zsh 5.9**、**Neovim 0.11.5**、**tmux 3.6a**、**git 2.39.5** 下验证。

- 这些配置针对上述环境做了偏好设置。
- 其他 macOS 设备可能需要微调。
- 其他操作系统仅供参考，不保证可直接使用。

## 包含内容

- `zsh/`：Zsh 配置（使用 **zi** + Powerlevel10k）。
- `nvim/`：Neovim（Lua）配置。
- `tmux/`：tmux 配置（TPM 工作流、会话持久化）。
- `aerospace/`：AeroSpace 窗口管理。
- `git/`：Git 全局配置与别名。
- `alias/`、`bash/`、`bin/`：常用命令别名与脚本。

## 隐私（开源友好）

该仓库可以直接开源：个人/公司信息与 token 不会被提交。

- 请自行在本地创建 `secrets/`、`private/` 下的文件（两者均已 gitignore）。

目录结构说明见：`docs/STRUCTURE.md`。

## 快速使用

1. 将仓库放到 `~/.config`。
2. 创建本地 `secrets/`、`private/` 文件。
3. 重启 shell 或按需 source。

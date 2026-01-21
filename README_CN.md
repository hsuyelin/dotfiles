<p align="center">
  <img src="assets/logo.svg" alt="Dotfiles" width="120" />
</p>

<p align="center">
  <strong>Dotfiles</strong>
  <br />
  个人 dotfiles（主要面向 <strong>macOS</strong>）。
  <br />
  <a href="README.md">English</a> | <a href="README_CN.md">中文</a>
</p>

---

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

## 隐私与开源

为避免开源泄露隐私，本仓库将敏感内容拆分为两类并默认忽略：

- `secrets/`：API Key/Token（**不提交**）。
- `private/`：个人/公司标识、机器路径等（**不提交**）。

### 需要在本地创建的文件

（以下文件会被 git 忽略，请自行创建）

- `~/.config/secrets/.ai.secrets`
- `~/.config/secrets/.env.secrets`
- `~/.config/private/git.config`
- `~/.config/private/zsh.zprofile`

更多目录结构说明见：`docs/STRUCTURE.md`。

## 快速使用

1. 将仓库放到 `~/.config`。
2. 创建本地 `secrets/`、`private/` 文件。
3. 重启 shell 或按需 source。

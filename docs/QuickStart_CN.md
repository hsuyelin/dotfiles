# 快速上手指南

常用命令和操作的快速参考。

<p align="center">
  <a href="QuickStart.md">English</a> · <a href="QuickStart_CN.md">中文</a>
</p>

---

## 1. 代理

```bash
# 启用代理
proxy_on

# 关闭代理
proxy_off

# 查看代理状态
proxy_status
```

## 2. Git 别名

由 Oh My Zsh git 插件 (`OMZP::git`) 提供。

**暂存与提交**

```bash
ga .                # git add .
gaa                 # git add --all
gcmsg "feat: xxx"   # git commit -m "feat: xxx"
gc!                 # git commit --amend
```

**拉取与推送**

```bash
gl                  # git pull
gpr                 # git pull --rebase
gpra                # git pull --rebase --autostash
gp                  # git push
gpsup               # git push --set-upstream origin <当前分支>
```

**分支**

```bash
gb                  # git branch
gba                 # git branch -a（fzf 增强的分支切换器）
gco <分支>          # git checkout <分支>
gcb <新分支>        # git checkout -b <新分支>
gsw <分支>          # git switch <分支>
gswc <新分支>       # git switch -c <新分支>
```

**状态与日志**

```bash
gst                 # git status
gss                 # git status -s
glog                # git log --oneline --decorate --graph
gloga               # git log --oneline --decorate --graph --all
```

**暂存**

```bash
gsta                # git stash push
gstp                # git stash pop
gstl                # git stash list
```

**重置**

```bash
grh                 # git reset
grhh                # git reset --hard
gpristine           # git reset --hard && git clean -dfx
```

**Lazygit**

```bash
lg                  # 打开 lazygit
```

## 3. Xcode

```bash
# 使用 xcodebuild 构建（需要参数）
xbuild --workspace your_workspace --scheme your_scheme --configuration Debug

# 清理
xclean --workspace your_workspace --scheme your_scheme --configuration Release

# 归档
xarchive --workspace your_workspace --scheme your_scheme --configuration Release --archive-path ./build/your_scheme.xcarchive

# Carthage 构建
carthage_build --package-name your_package_name
```

## 4. 文件列表 (eza)

```bash
ls                  # 带图标的 eza
l                   # 长格式 + git 状态
ll                  # 长格式 + 隐藏文件
la                  # 列出所有（包括隐藏文件）
lt                  # 树形视图（2 层）
lr                  # 按修改时间排序
lb                  # 按文件大小排序
```

## 5. Shell 操作

**目录导航**

```bash
z <关键词>          # zoxide 智能跳转（基于频率）
cd <目录>           # 启用 AUTO_CD，直接输入目录名即可
```

**搜索与补全**

```bash
Ctrl+R              # fzf 历史搜索
Ctrl+T              # fzf 文件搜索
Alt+C               # fzf 目录跳转
Tab                 # fzf-tab 增强补全（带预览）
```

`fzf-tab` 补全内部：
- `,` / `.` 切换分组
- `/` 连续选择
- `Ctrl+D` / `Ctrl+U` 滚动预览

**IP 信息**

```bash
ipshow              # 显示局域网 + 公网 IP
ipshow -l           # 仅局域网
ipshow -p           # 仅公网
```

**DNS 刷新**

```bash
dns-flush           # 刷新 macOS DNS 缓存
```

**安全删除**

```bash
rm <文件>           # 使用 safe-trash（回收站），不是直接删除
real-rm <文件>      # 实际的 /bin/rm
```

**Brew 导出**

```bash
brew_export         # 导出当前 brew 包列表
```

## 6. Neovim

Leader 键为 `Space`。

完整的 Neovim 配置文档请参见 **[Neovim 配置指南](Neovim_CN.md)**。

**基础编辑 (Vim 原生)**

| 操作 | 快捷键 |
|---|---|
| 搜索 | `/关键词` 然后回车 |
| 下一个匹配 | `n` |
| 上一个匹配 | `N` |
| 清除高亮 | `<Space>an` |
| 复制一行 | `yy` |
| 粘贴 | `p`（光标后）/ `P`（光标前） |
| 复制从光标到行尾 | `y$` |
| 可视选择并复制 | `v` → 移动光标 → `y` |
| 跳转到文件开头 | `gg` |
| 跳转到文件结尾 | `G` |
| 跳转到行首 | `0`（绝对）/ `^`（第一个非空字符） |
| 跳转到行尾 | `$` |
| 退出插入模式 | `jk` |

**文件与搜索**

| 操作 | 快捷键 |
|---|---|
| 查找文件 | `Ctrl+F` |
| 全局搜索 | `<Space>as` |
| 最近文件 | `<Space>fr` |
| 文件浏览器 | `<Space>fl` |
| 切换侧边栏 | `<Space>fh` |
| 保存文件 | `<Space>fw` |

**缓冲区与标签页**

| 操作 | 快捷键 |
|---|---|
| 列出缓冲区 | `Ctrl+B` 或 `<Space>bb` |
| 上一个缓冲区 | `{` |
| 下一个缓冲区 | `}` |
| 关闭当前缓冲区 | `Ctrl+C` 或 `<Space>bc` |
| 关闭其他缓冲区 | `<Space>bo` |
| 新建标签页 | `<Space>tn` |
| 关闭标签页 | `<Space>tc` |
| 列出标签页 | `<Space>tt` |
| 切换到标签页 N | `<Space>t1` ~ `<Space>t9` |

**窗口/分屏导航**

| 操作 | 快捷键 |
|---|---|
| 向左/下/上/右导航 | `Ctrl+H` / `Ctrl+J` / `Ctrl+K` / `Ctrl+L` |

**Git (Neovim 内)**

| 操作 | 快捷键 |
|---|---|
| 打开 Neogit | `<Space>gg` |
| 打开 Lazygit | `<Space>gG` |
| 暂存当前块 | `<Space>gs` |
| 暂存整个文件 | `<Space>gS` |
| 下/上一个块 | `<Space>gj` / `<Space>gk` |
| 预览块 | `<Space>gh` |
| 追溯 | `<Space>gb` |
| 差异 | `<Space>gdd` |

**LSP**

| 操作 | 快捷键 |
|---|---|
| 跳转到定义 | `gd` |
| 类型定义 | `gD` |
| 跳转到引用 | `gr` |
| 实现 | `gi` |
| 悬停文档 | `K` |
| 重命名 | `<Space>rn` 或 `<Space>ln` |
| 代码操作 | `ca` 或 `<Space>la` |
| 工作区符号 | `go` |
| 文档符号 | `gl` |

支持的 LSP 服务器：`lua_ls`、`sourcekit-lsp` (Swift/ObjC)、`clangd` (C/C++/ObjC)、`rust_analyzer`、`gopls`、`pyright`、`bashls`、`ts_ls`、`dartls`。

**调试 (DAP)**

| 操作 | 快捷键 |
|---|---|
| 切换断点 | `<Space>db` |
| 启动/继续 | `<Space>dc` |
| 步过 | `<Space>dn` |
| 步入 | `<Space>di` |
| 步出 | `<Space>do` |
| 终止 | `<Space>dq` |
| 切换 DAP UI | `<Space>du` |

**Flash 跳转（光标移动）**

| 操作 | 快捷键 |
|---|---|
| Flash 跳转 | `r` 然后输入目标 |
| Treesitter 搜索 | `R` |
| Treesitter 选择 | `Ctrl+R` |

**标记与书签**

| 操作 | 快捷键 |
|---|---|
| 设置标记 (a-z) | `m` + 字母 |
| 跳转到标记 | `'` + 字母 |
| 删除标记 | `dm` + 字母 |
| 设置下一个可用标记 | `m,` |
| 切换当前行标记 | `m;` |
| 下一个标记 | `m]` |
| 上一个标记 | `m[` |
| 预览标记 | `m:` |
| 删除缓冲区所有标记 | `dm-` |

**其他**

| 操作 | 快捷键 |
|---|---|
| 折叠/展开 | `Tab` |
| 所有命令 | `<Space><Space>` |
| 查看键位映射 | `<Space>ak` |
| 切换主题 | `<Space>ac` |
| 包管理器 (Lazy) | `<Space>P` |
| 切换项目 | `<Space>pp` |
| Zoxide 跳转 | `<Space>z` |

**Todo 注释**

高亮 `TODO`、`FIXME`、`HACK`、`WARN`、`NOTE`、`PERF` 等注释关键词，使用不同颜色和图标。由 `todo-comments.nvim` 驱动。

```
-- TODO: 重构这个函数
-- FIXME: nil 输入时崩溃
-- HACK: 临时解决方案
-- WARN: 已弃用的 API
-- NOTE: 参见 RFC 1234
-- PERF: O(n^2) — 需要优化
```

| 操作 | 快捷键 |
|---|---|
| 搜索所有 TODO (Telescope) | `<Space>at` |
| 诊断 TODO 列表 | `:TodoTrouble` |
| 快速修复 TODO 列表 | `:TodoQuickFix` |

**Markdown**

两个插件协同工作用于 Markdown 编辑：

- `render-markdown.nvim` — 在编辑器内**内联**渲染 Markdown（标题、粗体、代码块、表格等）
- `peek.nvim` — 打开**实时浏览器预览**，随输入实时更新

| 操作 | 快捷键 |
|---|---|
| 打开浏览器预览 | `<Space>mp` |
| 关闭浏览器预览 | `<Space>mc` |

> **注意：** `peek.nvim` 需要安装 [Deno](https://deno.land/)（`brew install deno`）。预览在默认浏览器中打开，默认使用浅色主题。

## 7. tmux

前缀键为 `Ctrl+A`。

**会话**

```bash
# 新建会话
tmux new -s <名称>

# 列出会话
tmux ls

# 连接到会话
tmux a -t <名称>

# 会话选择器（tmux 内）
Ctrl+A s
```

**窗口与面板**

| 操作 | 快捷键 |
|---|---|
| 新建窗口 | `Ctrl+A c` |
| 水平分割 | `Ctrl+A \|` |
| 垂直分割 | `Ctrl+A -` |
| 面板导航 | `Ctrl+H/J/K/L`（与 Neovim 共享） |
| 调整面板大小 | `Ctrl+A H/J/K/L` |
| 同步输入到所有面板 | `Ctrl+A y` |

**复制模式**

| 操作 | 快捷键 |
|---|---|
| 进入复制模式 | `Ctrl+A Esc` |
| 开始选择 | `v` |
| 复制选择 | `y` |
| 粘贴 | `Ctrl+A p` |

**快捷操作**

| 操作 | 快捷键 |
|---|---|
| Lazygit 弹窗 | `Ctrl+A g` |
| claude-dashboard | `Ctrl+A y` |
| 切换状态栏 | `Ctrl+A T` |
| 重载配置 | `Ctrl+A r` |

**插件**

- `tmux-resurrect`：会话持久化（重启后保留）
- `tmux-continuum`：自动保存 & 自动恢复

## 8. Claude (AI CLI)

```bash
# 交互式聊天
claude

# 直接提问
claude "如何优化这段代码"

# 管道输入
cat error.log | claude "分析这个错误"

# 在 tmux 中打开 dashboard
Ctrl+A y
```

## 9. Ruby & CocoaPods

```bash
# 安装特定 Ruby 版本（通过 rvminstall 脚本）
rvminstall 3.3.7

# 切换 Ruby 版本
rvm use 3.3.7

# 安装 CocoaPods
gem install cocoapods

# 常用 pod 操作
pod install
pod update
pod repo update
```

## 10. 禁用 Neovim AI 功能

AI 插件位于 `~/.config/nvim/lua/plugins/ai.lua`：

- `neocodeium` — 代码补全（类似 Copilot）
- `sidekick.nvim` — Claude / Codex 侧边栏
- `aicommits.nvim` — AI 生成提交信息

**方案 A：完全禁用（推荐）**

重命名或删除该文件；Lazy 不会从缺失的文件中加载插件：

```bash
mv ~/.config/nvim/lua/plugins/ai.lua ~/.config/nvim/lua/plugins/ai.lua.bak
```

**方案 B：禁用单个插件**

编辑 `ai.lua` 并在要跳过的每个插件中添加 `enabled = false`：

```lua
return {
    {
        "monkoose/neocodeium",
        enabled = false,  -- 禁用 AI 补全
        -- ...
    },
    {
        "folke/sidekick.nvim",
        enabled = false,  -- 禁用 Claude / Codex 侧边栏
        -- ...
    },
    {
        "404pilo/aicommits.nvim",
        enabled = false,  -- 禁用 AI 提交
    },
}
```

重启 Neovim 并运行 `:Lazy` 确认插件不再加载。

## 11. 其他命令

```bash
# Ruby 代码格式化
rubyfmt
```

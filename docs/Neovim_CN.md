# Neovim 配置指南

Neovim 配置的完整参考：通用设置、插件列表以及所有键位映射。

<p align="center">
  <a href="Neovim.md">English</a> · <a href="Neovim_CN.md">中文</a>
</p>

---

## 1. 通用设置

配置文件位于 `core/options.lua`。

| 选项 | 值 | 说明 |
|---|---|---|
| Leader 键 | `Space` | 自定义快捷键的主前缀 |
| Local leader | `,` | 文件类型专用快捷键前缀 |
| 剪贴板 | `unnamedplus` | 与系统剪贴板共享 |
| 鼠标 | `a` | 所有模式下启用鼠标 |
| 文件编码 | `utf-8` | 默认文件编码 |
| Tab 宽度 | 2 空格 | `tabstop` = `shiftwidth` = 2 |
| 自动缩进 | `true` | 新行自动缩进 |
| 行号 | 相对行号 | 同时启用 `number` 和 `relativenumber` |
| 光标行 | `true` | 高亮当前行 |
| 自动换行 | `true` | 长行自动视觉换行 |
| 搜索 | 不区分大小写 | 启用 `ignorecase` |
| 交换文件 | `false` | 关闭以保持工作区整洁 |
| 滚动偏移 | 20 | 光标上下保留 20 行可见 |
| 命令行高度 | 0 | 需要时才显示 |
| 状态栏 | 全局 | 所有窗口共享一条状态栏 |
| 标题 | `true` | 窗口标题显示当前文件路径 |
| 窗口边框 | `bold` | 浮窗使用粗体边框 |
| 窗口透明度 | 6 | 浮窗略微透明 |
| 超时 | 800ms | 按键序列超时时间 |

**自定义文件类型：**

| 扩展名/文件名 | 识别为 |
|---|---|
| `.arb` | JSON |
| `.zshrc` | Shell |

---

## 2. 插件管理器

[Lazy.nvim](https://github.com/folke/lazy.nvim) — 首次启动时自动引导安装。所有插件位于 `plugins/` 目录下，通过 `{ import = "plugins" }` 加载。

| 操作 | 快捷键 |
|---|---|
| 打开 Lazy UI | `<Space>P` |

---

## 3. 插件列表

### 颜色主题

| 插件 | 说明 |
|---|---|
| [catppuccin/nvim](https://github.com/catppuccin/nvim) | Catppuccin（风味：frappé，透明背景） |
| [EdenEast/nightfox.nvim](https://github.com/EdenEast/nightfox.nvim) | Nightfox |
| [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Tokyo Night（无 winborder 时自定义 Telescope 边框） |
| [olimorris/onedarkpro.nvim](https://github.com/olimorris/onedarkpro.nvim) | One Dark Pro（最高优先级） |

| 操作 | 快捷键 |
|---|---|
| 切换主题 | `<Space>ac` |

---

### UI 与状态栏

| 插件 | 说明 |
|---|---|
| [rebelot/heirline.nvim](https://github.com/rebelot/heirline.nvim) | 可定制的状态栏 / 窗口栏 / 标签栏 |
| [akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | 缓冲区标签页（支持 LSP 诊断） |
| [folke/noice.nvim](https://github.com/folke/noice.nvim) | 增强命令行 UI、消息和弹窗 |
| [rcarriga/nvim-notify](https://github.com/rcarriga/nvim-notify) | 动画通知管理器 |
| [sphamba/smear-cursor.nvim](https://github.com/sphamba/smear-cursor.nvim) | 光标平滑动画拖尾 |
| [lukas-reineke/indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | 缩进参考线 |

---

### 文件浏览器与项目

| 插件 | 说明 |
|---|---|
| [nvim-neo-tree/neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | 带 Git 状态的文件树侧边栏 |
| [ahmedkhalf/project.nvim](https://github.com/ahmedkhalf/project.nvim) | 项目管理与自动检测 |

**Neo-tree 键位映射（树内操作）**

| 操作 | 快捷键 |
|---|---|
| 打开文件/展开文件夹 | `l` 或 `<Tab>` |
| 折叠文件夹 | `h` |
| 切换文件夹展开 | `<Space>` |
| 模糊搜索 | `f` 或 `/` |
| 切换隐藏文件 | `.` |
| 新建文件/文件夹 | `A` |
| 仅新建文件夹 | `Ctrl+A` |
| 重命名 | `R` |
| 删除 | `D` |
| 复制 | `Y` |
| 粘贴 | `P` |
| 移动 | `M` |
| 设为根目录 | `c` |
| 导航到上级根目录 | `H` |
| 展开所有节点 | `O` |
| 关闭所有子节点 | `C` |

**项目与文件快捷键**

| 操作 | 快捷键 |
|---|---|
| 文件浏览器 (Neo-tree) | `<Space>fl` |
| 切换侧边栏 | `<Space>fh` |
| 查找文件 (Telescope) | `Ctrl+F` |
| 最近文件 | `<Space>fr` |
| 保存文件 | `<Space>fw` |
| Netrw 文件管理器 | `<Space>fd` |
| 切换项目 | `<Space>pp` |
| 重置项目根目录 | `<Space>pP` |
| 添加项目 | `<Space>pa` |
| Zoxide 跳转 | `<Space>z` |

---

### Telescope（模糊搜索）

| 插件 | 说明 |
|---|---|
| [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | 可扩展的模糊搜索器 |
| [telescope-ui-select.nvim](https://github.com/nvim-telescope/telescope-ui-select.nvim) | 用 Telescope 替换 `vim.ui.select` |
| [telescope-tabs](https://github.com/LukasPietzschmann/telescope-tabs) | 标签页选择器 |
| [telescope-zoxide](https://github.com/jvgrootveld/telescope-zoxide) | Zoxide 集成 |
| [telescope-emoji](https://github.com/xiyaowong/telescope-emoji.nvim) | 表情符号选择器 |

**Telescope 插入模式内：**

- `Ctrl+Q` — 将结果发送到 Trouble 快速修复列表

| 操作 | 快捷键 |
|---|---|
| 查找文件 | `Ctrl+F` |
| 列出缓冲区 | `Ctrl+B` 或 `<Space>bb` |
| 全局搜索 (live grep) | `<Space>as` |
| 所有命令 | `<Space><Space>` |
| 帮助标签 | `<Space>ah` |
| 跳转列表 | `<Space>aj` |
| 键位映射 | `<Space>ak` |
| 表情符号 | `<Space>ae` 或 `Ctrl+E`（插入模式） |
| 消息/通知 | `<Space>am` |
| 颜色主题 | `<Space>ac` |
| 待办列表 | `<Space>at` |
| 列出标签页 | `<Space>tt` |
| Zoxide 跳转 | `<Space>z` |

---

### 代码补全

| 插件 | 说明 |
|---|---|
| [saghen/blink.cmp](https://github.com/saghen/blink.cmp) | 基于 Rust 模糊匹配的快速补全引擎 |

使用 **super-tab** 预设：

| 操作 | 快捷键 |
|---|---|
| 接受补全 | `Tab` |
| 打开菜单/文档 | `Ctrl+Space` |
| 下一项 | `Ctrl+N` 或 `Down` |
| 上一项 | `Ctrl+P` 或 `Up` |
| 隐藏菜单 | `Ctrl+E` |
| 切换签名帮助 | `Ctrl+K` |

**命令行补全：**

| 操作 | 快捷键 |
|---|---|
| 接受 | `Ctrl+K` 或 `Tab` |
| 接受并执行 | `Enter` |

补全来源：`lsp`、`path`、`snippets`、`buffer`。

---

### LSP

| 插件 | 说明 |
|---|---|
| [mason.nvim](https://github.com/williamboman/mason.nvim) | LSP / DAP / Linter / Formatter 安装器 |
| [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) | 自动安装 LSP 服务器 |
| [mason-tool-installer.nvim](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim) | 确保工具已安装 |
| [mason-nvim-dap.nvim](https://github.com/jay-babu/mason-nvim-dap.nvim) | DAP 适配器安装器 |
| [onsails/lspkind.nvim](https://github.com/onsails/lspkind.nvim) | LSP 补全图标 |
| [ray-x/lsp_signature.nvim](https://github.com/ray-x/lsp_signature.nvim) | 插入模式下的签名帮助 |

**已配置的 LSP 服务器：**

`lua_ls`、`shellcheck`、`sourcekit-lsp`（Swift/ObjC）、`clangd`（C/C++/ObjC）、`rust_analyzer`、`gopls`、`pyright`。

**LSP 快捷键（LSP 附加时生效）**

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
| 格式化代码 | `<Space>lf` |
| 切换内嵌提示 | `<Space>lti` |

**LSP 导航（通过 `<Space>l` 组）**

| 操作 | 快捷键 |
|---|---|
| 跳转到定义 | `<Space>lgd` |
| 类型定义 | `<Space>lgD` |
| 引用 | `<Space>lgr` |
| 实现 | `<Space>lgi` |
| 工作区符号 | `<Space>lgo` |
| 文档符号 | `<Space>lgl` |

---

### 调试 (DAP)

| 插件 | 说明 |
|---|---|
| [mfussenegger/nvim-dap](https://github.com/mfussenegger/nvim-dap) | 调试适配器协议客户端 |
| [rcarriga/nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) | DAP 用户界面 |
| [theHamsta/nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text) | 变量行内虚拟文本 |

| 操作 | 快捷键 |
|---|---|
| 切换断点 | `<Space>db` |
| 启动/继续 | `<Space>dc` |
| 步过 | `<Space>dn` |
| 步入 | `<Space>di` |
| 步出 | `<Space>do` |
| 终止 | `<Space>dq` |
| 切换 DAP UI | `<Space>du` |
| 切换 REPL | `<Space>dl` |
| 清空 REPL | `<Space>dL` |
| 启动调试服务器 (Lua) | `<Space>ds` |

---

### Git

| 插件 | 说明 |
|---|---|
| [lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | 侧栏 Git 标记 |
| [TimUntersberger/neogit](https://github.com/TimUntersberger/neogit) | Magit 风格的 Git 客户端 |
| [sindrets/diffview.nvim](https://github.com/sindrets/diffview.nvim) | 并排差异查看器 |

| 操作 | 快捷键 |
|---|---|
| 打开 Neogit | `<Space>gg` |
| 打开 Lazygit | `<Space>gG` |
| 暂存当前块 | `<Space>gs` |
| 暂存整个文件 | `<Space>gS` |
| 撤销暂存块 | `<Space>gu` |
| 重置当前块 | `<Space>gx` |
| 下一个块 | `<Space>gj` |
| 上一个块 | `<Space>gk` |
| 行内预览块 | `<Space>gh` |
| 弹窗预览块 | `<Space>gH` |
| 行级追溯 | `<Space>gb` |
| 行级追溯弹窗 | `<Space>gB` |
| 查看差异 | `<Space>gdd` |
| 关闭差异 | `<Space>gdc` |
| 当前文件历史 | `<Space>gdf` |
| 切换差异文件列表 | `<Space>gdt` |
| Git 状态 (Neo-tree) | `<Space>gl` |
| 切换行高亮 | `<Space>gtl` |
| 切换行号高亮 | `<Space>gtn` |
| 切换标记显示 | `<Space>gts` |

---

### 编辑与移动

| 插件 | 说明 |
|---|---|
| [folke/flash.nvim](https://github.com/folke/flash.nvim) | 闪电般的光标跳转 |
| [kylechui/nvim-surround](https://github.com/kylechui/nvim-surround) | 添加/修改/删除包围字符 |
| [folke/ts-comments.nvim](https://github.com/folke/ts-comments.nvim) | 基于 Treesitter 的增强注释 |
| [windwp/nvim-autopairs](https://github.com/windwp/nvim-autopairs) | 自动闭合括号和引号 |
| [chentoast/marks.nvim](https://github.com/chentoast/marks.nvim) | 增强标记（带符号显示） |

**Flash 快捷键**

| 操作 | 快捷键 |
|---|---|
| Flash 跳转 | `r` 然后输入目标 |
| Treesitter 搜索 | `R` |
| Treesitter 选择 | `Ctrl+R` |

**Surround 快捷键（默认 nvim-surround）**

| 操作 | 快捷键 |
|---|---|
| 添加包围 | `ys{动作}{字符}` |
| 删除包围 | `ds{字符}` |
| 修改包围 | `cs{旧}{新}` |

**标记快捷键**

| 操作 | 快捷键 |
|---|---|
| 设置标记 | `m` + 字母 |
| 跳转到标记 | `'` + 字母 |
| 删除标记 | `dm` + 字母 |
| 设置下一个可用标记 | `m,` |
| 切换当前行标记 | `m;` |
| 下一个标记 | `m]` |
| 上一个标记 | `m[` |
| 预览标记 | `m:` |
| 删除缓冲区所有标记 | `dm-` |

---

### Treesitter

| 插件 | 说明 |
|---|---|
| [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | 语法高亮与代码理解 |
| [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) | 结构化文本对象 |
| [HiPhish/rainbow-delimiters.nvim](https://github.com/HiPhish/rainbow-delimiters.nvim) | 彩虹括号 |

**文本对象选择（可视/操作等待模式）**

| 文本对象 | 内部 | 外部 |
|---|---|---|
| 函数 | `if` | `af` |
| 类 | `ic` | `ac` |

**交换快捷键**

| 操作 | 快捷键 |
|---|---|
| 交换下一个参数 | `<Space>cp` |
| 交换上一个参数 | `<Space>cP` |
| 交换下一个函数 | `<Space>cf` |
| 交换上一个函数 | `<Space>cF` |
| 交换下一个类 | `<Space>cc` |
| 交换上一个类 | `<Space>cC` |

**移动快捷键（跳转到下/上一个起始/结束位置）**

| 目标 | 下一个起始 | 下一个结束 | 上一个起始 | 上一个结束 |
|---|---|---|---|---|
| 参数 | `]p` | `]P` | `[p` | `[P` |
| 函数 | `]f` / `]m` | `]F` | `[f` | `[F` |
| 类 | `]c` / `]]` | `]C` | `[c` | `[C` |
| 循环 | `]o` | `]O` | `[o` | `[O` |
| 折叠 | `]z` | — | `[z` | — |

**重复移动**

| 操作 | 快捷键 |
|---|---|
| 重复上次向前移动 | `;` |
| 重复上次向后移动 | `,` |

---

### Trouble（诊断列表）

| 插件 | 说明 |
|---|---|
| [folke/trouble.nvim](https://github.com/folke/trouble.nvim) | 增强诊断和快速修复列表 |

| 操作 | 快捷键 |
|---|---|
| 切换诊断 | `<Space>xx` |
| 缓冲区诊断 | `<Space>xf` |
| LSP 引用/定义 | `<Space>xs` |
| 上一个诊断 | `Ctrl+Shift+P` |
| 下一个诊断 | `Ctrl+Shift+N` |

---

### AI

| 插件 | 说明 |
|---|---|
| [monkoose/neocodeium](https://github.com/monkoose/neocodeium) | AI 代码补全（类似 Copilot） |
| [folke/sidekick.nvim](https://github.com/folke/sidekick.nvim) | Claude / Codex AI 侧边栏 |
| [404pilo/aicommits.nvim](https://github.com/404pilo/aicommits.nvim) | AI 生成提交信息 |

**NeoCodeium 快捷键**

| 操作 | 快捷键 |
|---|---|
| 接受建议 | `Tab`（插入模式，可见时） |

**Sidekick 快捷键**

| 操作 | 快捷键 |
|---|---|
| 切换 CLI | `<Space>aa` |
| 切换 Claude | `<Space>ac` |
| 切换 Codex / Grok | `<Space>ag` |
| 询问提示 | `<Space>ap` |
| 切换焦点 | `Ctrl+.` |
| 跳转/应用下一个编辑 | `Tab` |

> 参见[禁用 Neovim AI 功能](QuickStart_CN.md#10-禁用-neovim-ai-功能)了解如何禁用 AI 插件。

---

### Markdown

| 插件 | 说明 |
|---|---|
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | 编辑器内 Markdown 内联渲染 |
| [peek.nvim](https://github.com/toppair/peek.nvim) | 浏览器实时预览（需要 [Deno](https://deno.land/)） |

| 操作 | 快捷键 |
|---|---|
| 打开浏览器预览 | `<Space>mp` |
| 关闭浏览器预览 | `<Space>mc` |

---

### Todo 注释

| 插件 | 说明 |
|---|---|
| [folke/todo-comments.nvim](https://github.com/folke/todo-comments.nvim) | 高亮并搜索 TODO / FIXME / HACK / WARN / NOTE / PERF |

| 操作 | 快捷键 |
|---|---|
| 搜索所有 TODO (Telescope) | `<Space>at` |

---

### 格式化

| 插件 | 说明 |
|---|---|
| [stevearc/conform.nvim](https://github.com/stevearc/conform.nvim) | 保存时自动格式化（按文件类型配置格式化器） |

**已配置的格式化器：**

| 文件类型 | 格式化器 |
|---|---|
| Lua | `stylua` |
| Python | `yapf` |
| Swift | `swiftformat`（自定义配置路径） |

| 操作 | 快捷键 |
|---|---|
| 格式化代码块 | `<Space>lf` |

---

### 滚动

| 插件 | 说明 |
|---|---|
| [karb94/neoscroll.nvim](https://github.com/karb94/neoscroll.nvim) | 平滑滚动动画 |

滚动映射：`Ctrl+U`、`Ctrl+D`、`Ctrl+B`、`Ctrl+F`、`zt`、`zz`、`zb`。

---

### 窗口管理

| 插件 | 说明 |
|---|---|
| [mrjones2014/smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim) | 智能窗口导航 |
| [anuvyklack/windows.nvim](https://github.com/anuvyklack/windows.nvim) | 自动调整窗口大小 |

| 操作 | 快捷键 |
|---|---|
| 向左导航 | `Ctrl+H` |
| 向下导航 | `Ctrl+J` |
| 向上导航 | `Ctrl+K` |
| 向右导航 | `Ctrl+L` |
| 切换自动宽度 | `<Space>wat` |
| 平均化宽度 | `<Space>wae` |
| 最大化宽度 | `<Space>wam` |

---

### tmux 集成

| 插件 | 说明 |
|---|---|
| [christoomey/vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Neovim 分屏与 tmux 面板无缝导航 |

面板导航（`Ctrl+H/J/K/L`）在 Neovim 和 tmux 之间共享。

---

### Which-Key

| 插件 | 说明 |
|---|---|
| [folke/which-key.nvim](https://github.com/folke/which-key.nvim) | 按下部分按键时弹出快捷键提示 |

按下任意前缀（如 `<Space>`）并等待，即可查看所有可用快捷键。

---

## 4. 基础编辑（Vim 原生）

| 操作 | 快捷键 |
|---|---|
| 退出插入模式 | `jk` |
| 搜索 | `/关键词` 然后回车 |
| 下一个匹配 | `n` |
| 上一个匹配 | `N` |
| 清除高亮 | `<Space>an` |
| 复制一行 | `yy` |
| 粘贴（光标后） | `p` |
| 粘贴（光标前） | `P` |
| 复制到行尾 | `y$` |
| 可视选择并复制 | `v` → 移动 → `y` |
| 跳转到文件开头 | `gg` |
| 跳转到文件结尾 | `G` |
| 跳转到行首 | `0`（绝对）/ `^`（第一个非空字符） |
| 跳转到行尾 | `$` |
| 折叠/展开 | `Tab` |
| 向前跳转（标签） | `Ctrl+I` |
| 向后跳转（标签） | `Ctrl+O` |

---

## 5. 缓冲区与标签页

| 操作 | 快捷键 |
|---|---|
| 列出缓冲区 | `Ctrl+B` 或 `<Space>bb` |
| 当前标签页缓冲区 | `<Space>bB` |
| 上一个缓冲区 | `{` 或 `<Space>bh` |
| 下一个缓冲区 | `}` 或 `<Space>bl` |
| 向左移动缓冲区 | `<Space>bH` |
| 向右移动缓冲区 | `<Space>bL` |
| 关闭当前缓冲区 | `Ctrl+C` 或 `<Space>bc` |
| 关闭其他缓冲区 | `<Space>bo` |
| 新建空白缓冲区 | `<Space>bn` |
| 锁定缓冲区 | `<Space>bp` |
| 选择缓冲区 | `<Space>bP` |
| 新建标签页 | `<Space>tn` |
| 关闭标签页 | `<Space>tc` |
| 列出标签页 | `<Space>tt` |
| 上一个标签页 | `Ctrl+[` |
| 下一个标签页 | `Ctrl+]` |
| 切换到标签页 N | `<Space>t1` ~ `<Space>t9` |

---

## 6. 配置管理

| 操作 | 快捷键 |
|---|---|
| 编辑配置文件 | `<Space>Cc` |
| 选择配置 (Neoconf) | `<Space>CC` |
| 编辑本地配置 | `<Space>Cl` |
| 编辑全局配置 | `<Space>Cg` |
| 显示配置 | `<Space>Cs` |
| 显示 LSP 配置 | `<Space>Cp` |

---

## 7. 语言专用快捷键

### Go（`<Space>` 前缀，`.go` 文件内生效）

| 操作 | 快捷键 |
|---|---|
| 备用文件 | `<Space>a` |
| Go 测试 | `<Space>tt` |
| 代码操作 | `<Space>c` |

### Dart / Flutter（`,` 本地 leader 前缀，`.dart` 文件内生效）

| 操作 | 快捷键 |
|---|---|
| Flutter 命令 | `,,` |
| 模拟器 | `,e` |
| 切换组件大纲 | `,w` |
| 运行 Flutter | `,r` |
| 热重启 Flutter | `,R` |
| 提取方法 | `,M` |
| 提取组件 | `,W` |
| 提取局部变量 | `,L` |
| 包裹组件 | `,A` |

### Lua（`,` 本地 leader 前缀，`.lua` 文件内生效）

| 操作 | 快捷键 |
|---|---|
| 重新加载当前文件 | `,s` |
| 运行当前缓冲区 | `,r` |

### Python（`,` 本地 leader 前缀，`.py` 文件内生效）

| 操作 | 快捷键 |
|---|---|
| 运行代码 | `,r` |

---

## 8. 竞赛编程

| 插件 | 说明 |
|---|---|
| [xeluxee/competitest.nvim](https://github.com/xeluxee/competitest.nvim) | 竞赛编程测试运行器 |

| 操作 | 快捷键 |
|---|---|
| 接收问题 | `<Space>Ic` |
| 运行测试 | `<Space>Ir` |
| 添加测试用例 | `<Space>Ia` |
| 编辑测试用例 | `<Space>Ie` |
| 删除测试用例 | `<Space>Id` |

---

## 9. 协作编辑

| 插件 | 说明 |
|---|---|
| [nomad/nomad](https://github.com/nickeisenberg/nomad) | 协作编辑 |

---

## 10. 其他

| 操作 | 快捷键 |
|---|---|
| 打开终端 | `<Space>!` |
| 退出所有 | `<Space>aq` |
| 所有命令 (Telescope) | `<Space><Space>` |
| 查看键位映射 (Telescope) | `<Space>ak` |

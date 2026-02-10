# Neovim Configuration Guide

A comprehensive reference for the Neovim setup: general options, plugin list, and every keymap.

<p align="center">
  <a href="Neovim.md">English</a> · <a href="Neovim_CN.md">中文</a>
</p>

---

## 1. General Settings

Configured in `core/options.lua`.

| Option | Value | Description |
|---|---|---|
| Leader key | `Space` | Main prefix for custom keymaps |
| Local leader | `,` | Prefix for filetype-specific keymaps |
| Clipboard | `unnamedplus` | Shares system clipboard |
| Mouse | `a` | Mouse enabled in all modes |
| File encoding | `utf-8` | Default file encoding |
| Tab width | 2 spaces | `tabstop` = `shiftwidth` = 2 |
| Auto indent | `true` | Automatically indent new lines |
| Line numbers | Relative | Both `number` and `relativenumber` |
| Cursor line | `true` | Highlights the current line |
| Word wrap | `true` | Long lines wrap visually |
| Search | Case-insensitive | `ignorecase` enabled |
| Swap file | `false` | Disabled for cleaner workflow |
| Scroll offset | 20 | Keeps 20 lines visible above/below cursor |
| Command height | 0 | Hidden unless needed |
| Status line | Global | Single statusline across all windows |
| Title | `true` | Window title shows current file path |
| Window border | `bold` | Bold floating window borders |
| Window blend | 6 | Slight transparency on floating windows |
| Timeout | 800ms | Key sequence timeout |

**Custom filetypes:**

| Extension / Filename | Treated as |
|---|---|
| `.arb` | JSON |
| `.zshrc` | Shell |

---

## 2. Plugin Manager

[Lazy.nvim](https://github.com/folke/lazy.nvim) — auto-bootstrapped on first launch. All plugins live in `plugins/` and are loaded via `{ import = "plugins" }`.

| Action | Key |
|---|---|
| Open Lazy UI | `<Space>P` |

---

## 3. Plugin List

### Color Schemes

| Plugin | Description |
|---|---|
| [catppuccin/nvim](https://github.com/catppuccin/nvim) | Catppuccin (flavour: frappé, transparent background) |
| [EdenEast/nightfox.nvim](https://github.com/EdenEast/nightfox.nvim) | Nightfox |
| [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Tokyo Night (custom Telescope borders when no `winborder`) |
| [olimorris/onedarkpro.nvim](https://github.com/olimorris/onedarkpro.nvim) | One Dark Pro (highest priority) |

| Action | Key |
|---|---|
| Switch colorscheme | `<Space>ac` |

---

### UI & Statusline

| Plugin | Description |
|---|---|
| [rebelot/heirline.nvim](https://github.com/rebelot/heirline.nvim) | Customizable statusline / winbar / tabline |
| [akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | Buffer tabs with LSP diagnostics |
| [folke/noice.nvim](https://github.com/folke/noice.nvim) | Enhanced command-line UI, messages, and popups |
| [rcarriga/nvim-notify](https://github.com/rcarriga/nvim-notify) | Animated notification manager |
| [sphamba/smear-cursor.nvim](https://github.com/sphamba/smear-cursor.nvim) | Smooth animated cursor trail |
| [lukas-reineke/indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | Indent guide lines |

---

### File Explorer & Project

| Plugin | Description |
|---|---|
| [nvim-neo-tree/neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | File tree sidebar with git status |
| [ahmedkhalf/project.nvim](https://github.com/ahmedkhalf/project.nvim) | Project management and auto-detection |

**Neo-tree keymaps (inside the tree)**

| Action | Key |
|---|---|
| Open file / expand folder | `l` or `<Tab>` |
| Collapse folder | `h` |
| Toggle folder | `<Space>` |
| Fuzzy search | `f` or `/` |
| Toggle hidden files | `.` |
| Create file/folder | `A` |
| Create folder only | `Ctrl+A` |
| Rename | `R` |
| Delete | `D` |
| Copy | `Y` |
| Paste | `P` |
| Move | `M` |
| Set as root | `c` |
| Navigate to parent root | `H` |
| Expand all nodes | `O` |
| Close all sub-nodes | `C` |

**Project & file keymaps**

| Action | Key |
|---|---|
| File explorer (Neo-tree) | `<Space>fl` |
| Toggle sidebar | `<Space>fh` |
| Find file (Telescope) | `Ctrl+F` |
| Recent files | `<Space>fr` |
| Save file | `<Space>fw` |
| Netrw file manager | `<Space>fd` |
| Switch project | `<Space>pp` |
| Reset project root | `<Space>pP` |
| Add project | `<Space>pa` |
| Zoxide jump | `<Space>z` |

---

### Telescope (Fuzzy Finder)

| Plugin | Description |
|---|---|
| [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Extensible fuzzy finder |
| [telescope-ui-select.nvim](https://github.com/nvim-telescope/telescope-ui-select.nvim) | Replaces `vim.ui.select` with Telescope |
| [telescope-tabs](https://github.com/LukasPietzschmann/telescope-tabs) | Tab picker |
| [telescope-zoxide](https://github.com/jvgrootveld/telescope-zoxide) | Zoxide integration |
| [telescope-emoji](https://github.com/xiyaowong/telescope-emoji.nvim) | Emoji picker |

**Telescope inside insert mode:**

- `Ctrl+Q` — send results to Trouble quickfix

| Action | Key |
|---|---|
| Find file | `Ctrl+F` |
| List buffers | `Ctrl+B` or `<Space>bb` |
| Global search (live grep) | `<Space>as` |
| All commands | `<Space><Space>` |
| Help tags | `<Space>ah` |
| Jumplist | `<Space>aj` |
| Keymaps | `<Space>ak` |
| Emoji | `<Space>ae` or `Ctrl+E` (insert mode) |
| Messages / Notifications | `<Space>am` |
| Colorscheme | `<Space>ac` |
| Todo list | `<Space>at` |
| List tabs | `<Space>tt` |
| Zoxide jump | `<Space>z` |

---

### Completion

| Plugin | Description |
|---|---|
| [saghen/blink.cmp](https://github.com/saghen/blink.cmp) | Fast completion engine with Rust fuzzy matching |

Uses the **super-tab** preset:

| Action | Key |
|---|---|
| Accept completion | `Tab` |
| Open menu / docs | `Ctrl+Space` |
| Next item | `Ctrl+N` or `Down` |
| Previous item | `Ctrl+P` or `Up` |
| Hide menu | `Ctrl+E` |
| Toggle signature help | `Ctrl+K` |

**Command-line completion:**

| Action | Key |
|---|---|
| Accept | `Ctrl+K` or `Tab` |
| Accept and enter | `Enter` |

Sources: `lsp`, `path`, `snippets`, `buffer`.

---

### LSP

| Plugin | Description |
|---|---|
| [mason.nvim](https://github.com/williamboman/mason.nvim) | LSP / DAP / Linter / Formatter installer |
| [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) | Auto-install LSP servers |
| [mason-tool-installer.nvim](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim) | Ensure tools are installed |
| [mason-nvim-dap.nvim](https://github.com/jay-babu/mason-nvim-dap.nvim) | DAP adapter installer |
| [onsails/lspkind.nvim](https://github.com/onsails/lspkind.nvim) | LSP completion icons |
| [ray-x/lsp_signature.nvim](https://github.com/ray-x/lsp_signature.nvim) | Signature help on insert |

**Configured LSP servers:**

`lua_ls`, `shellcheck`, `sourcekit-lsp` (Swift/ObjC), `clangd` (C/C++/ObjC), `rust_analyzer`, `gopls`, `pyright`.

**LSP keymaps (active when LSP attaches)**

| Action | Key |
|---|---|
| Go to definition | `gd` |
| Type definition | `gD` |
| Go to references | `gr` |
| Implementation | `gi` |
| Hover documentation | `K` |
| Rename | `<Space>rn` or `<Space>ln` |
| Code action | `ca` or `<Space>la` |
| Workspace symbols | `go` |
| Document symbols | `gl` |
| Format code | `<Space>lf` |
| Toggle inlay hint | `<Space>lti` |

**LSP navigation (via `<Space>l` group)**

| Action | Key |
|---|---|
| Go to definition | `<Space>lgd` |
| Type definition | `<Space>lgD` |
| References | `<Space>lgr` |
| Implementation | `<Space>lgi` |
| Workspace symbols | `<Space>lgo` |
| Document symbols | `<Space>lgl` |

---

### Debug (DAP)

| Plugin | Description |
|---|---|
| [mfussenegger/nvim-dap](https://github.com/mfussenegger/nvim-dap) | Debug Adapter Protocol client |
| [rcarriga/nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) | UI for DAP |
| [theHamsta/nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text) | Inline virtual text for variables |

| Action | Key |
|---|---|
| Toggle breakpoint | `<Space>db` |
| Start / continue | `<Space>dc` |
| Step over | `<Space>dn` |
| Step into | `<Space>di` |
| Step out | `<Space>do` |
| Terminate | `<Space>dq` |
| Toggle DAP UI | `<Space>du` |
| Toggle REPL | `<Space>dl` |
| Clear REPL | `<Space>dL` |
| Start debug server (Lua) | `<Space>ds` |

---

### Git

| Plugin | Description |
|---|---|
| [lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git signs in the gutter |
| [TimUntersberger/neogit](https://github.com/TimUntersberger/neogit) | Magit-style Git client |
| [sindrets/diffview.nvim](https://github.com/sindrets/diffview.nvim) | Side-by-side diff viewer |

| Action | Key |
|---|---|
| Open Neogit | `<Space>gg` |
| Open Lazygit | `<Space>gG` |
| Stage hunk | `<Space>gs` |
| Stage buffer | `<Space>gS` |
| Undo stage hunk | `<Space>gu` |
| Reset hunk | `<Space>gx` |
| Next hunk | `<Space>gj` |
| Previous hunk | `<Space>gk` |
| Preview hunk (inline) | `<Space>gh` |
| Preview hunk (popup) | `<Space>gH` |
| Blame | `<Space>gb` |
| Blame line (popup) | `<Space>gB` |
| Diff this | `<Space>gdd` |
| Close diff | `<Space>gdc` |
| Current file history | `<Space>gdf` |
| Toggle diff file list | `<Space>gdt` |
| Git status (Neo-tree) | `<Space>gl` |
| Toggle line highlight | `<Space>gtl` |
| Toggle number highlight | `<Space>gtn` |
| Toggle signs | `<Space>gts` |

---

### Editing & Motion

| Plugin | Description |
|---|---|
| [folke/flash.nvim](https://github.com/folke/flash.nvim) | Lightning-fast cursor jump |
| [kylechui/nvim-surround](https://github.com/kylechui/nvim-surround) | Add / change / delete surrounding pairs |
| [folke/ts-comments.nvim](https://github.com/folke/ts-comments.nvim) | Better commenting via Treesitter |
| [windwp/nvim-autopairs](https://github.com/windwp/nvim-autopairs) | Auto-close brackets and quotes |
| [chentoast/marks.nvim](https://github.com/chentoast/marks.nvim) | Enhanced marks with signs |

**Flash keymaps**

| Action | Key |
|---|---|
| Flash jump | `r` then type target |
| Treesitter search | `R` |
| Treesitter select | `Ctrl+R` |

**Surround keymaps (default nvim-surround)**

| Action | Key |
|---|---|
| Add surround | `ys{motion}{char}` |
| Delete surround | `ds{char}` |
| Change surround | `cs{old}{new}` |

**Marks keymaps**

| Action | Key |
|---|---|
| Set mark | `m` + letter |
| Jump to mark | `'` + letter |
| Delete mark | `dm` + letter |
| Set next available mark | `m,` |
| Toggle mark on current line | `m;` |
| Next mark | `m]` |
| Previous mark | `m[` |
| Preview mark | `m:` |
| Delete all marks in buffer | `dm-` |

---

### Treesitter

| Plugin | Description |
|---|---|
| [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting & code understanding |
| [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) | Structural text objects |
| [HiPhish/rainbow-delimiters.nvim](https://github.com/HiPhish/rainbow-delimiters.nvim) | Rainbow-colored brackets |

**Text object selection (visual / operator-pending)**

| Text Object | Inner | Outer |
|---|---|---|
| Function | `if` | `af` |
| Class | `ic` | `ac` |

**Swap keymaps**

| Action | Key |
|---|---|
| Swap next parameter | `<Space>cp` |
| Swap previous parameter | `<Space>cP` |
| Swap next function | `<Space>cf` |
| Swap previous function | `<Space>cF` |
| Swap next class | `<Space>cc` |
| Swap previous class | `<Space>cC` |

**Move keymaps (go to next/previous start/end)**

| Target | Next start | Next end | Prev start | Prev end |
|---|---|---|---|---|
| Parameter | `]p` | `]P` | `[p` | `[P` |
| Function | `]f` / `]m` | `]F` | `[f` | `[F` |
| Class | `]c` / `]]` | `]C` | `[c` | `[C` |
| Loop | `]o` | `]O` | `[o` | `[O` |
| Fold | `]z` | — | `[z` | — |

**Repeat movement**

| Action | Key |
|---|---|
| Repeat last move forward | `;` |
| Repeat last move backward | `,` |

---

### Trouble (Diagnostics List)

| Plugin | Description |
|---|---|
| [folke/trouble.nvim](https://github.com/folke/trouble.nvim) | Enhanced diagnostics and quickfix list |

| Action | Key |
|---|---|
| Toggle diagnostics | `<Space>xx` |
| Buffer diagnostics | `<Space>xf` |
| LSP references/definitions | `<Space>xs` |
| Previous diagnostic | `Ctrl+Shift+P` |
| Next diagnostic | `Ctrl+Shift+N` |

---

### AI

| Plugin | Description |
|---|---|
| [monkoose/neocodeium](https://github.com/monkoose/neocodeium) | AI code completion (Copilot-like) |
| [folke/sidekick.nvim](https://github.com/folke/sidekick.nvim) | Claude / Codex AI sidebar |
| [404pilo/aicommits.nvim](https://github.com/404pilo/aicommits.nvim) | AI-generated commit messages |

**NeoCodeium keymaps**

| Action | Key |
|---|---|
| Accept suggestion | `Tab` (insert mode, when visible) |

**Sidekick keymaps**

| Action | Key |
|---|---|
| Toggle CLI | `<Space>aa` |
| Toggle Claude | `<Space>ac` |
| Toggle Codex / Grok | `<Space>ag` |
| Ask prompt | `<Space>ap` |
| Switch focus | `Ctrl+.` |
| Goto / apply next edit | `Tab` |

> See [Disable Neovim AI Features](QuickStart.md#10-disable-neovim-ai-features) for instructions on disabling AI plugins.

---

### Markdown

| Plugin | Description |
|---|---|
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | Inline Markdown rendering in the editor |
| [peek.nvim](https://github.com/toppair/peek.nvim) | Live browser preview (requires [Deno](https://deno.land/)) |

| Action | Key |
|---|---|
| Open browser preview | `<Space>mp` |
| Close browser preview | `<Space>mc` |

---

### Todo Comments

| Plugin | Description |
|---|---|
| [folke/todo-comments.nvim](https://github.com/folke/todo-comments.nvim) | Highlight and search TODO / FIXME / HACK / WARN / NOTE / PERF |

| Action | Key |
|---|---|
| Search all TODOs (Telescope) | `<Space>at` |

---

### Formatting

| Plugin | Description |
|---|---|
| [stevearc/conform.nvim](https://github.com/stevearc/conform.nvim) | Format on save with per-filetype formatters |

**Configured formatters:**

| Filetype | Formatter |
|---|---|
| Lua | `stylua` |
| Python | `yapf` |
| Swift | `swiftformat` (custom config path) |

| Action | Key |
|---|---|
| Format code block | `<Space>lf` |

---

### Scrolling

| Plugin | Description |
|---|---|
| [karb94/neoscroll.nvim](https://github.com/karb94/neoscroll.nvim) | Smooth scrolling animations |

Scroll mappings: `Ctrl+U`, `Ctrl+D`, `Ctrl+B`, `Ctrl+F`, `zt`, `zz`, `zb`.

---

### Window Management

| Plugin | Description |
|---|---|
| [mrjones2014/smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim) | Smart window navigation |
| [anuvyklack/windows.nvim](https://github.com/anuvyklack/windows.nvim) | Auto-resize windows |

| Action | Key |
|---|---|
| Navigate left | `Ctrl+H` |
| Navigate down | `Ctrl+J` |
| Navigate up | `Ctrl+K` |
| Navigate right | `Ctrl+L` |
| Toggle auto width | `<Space>wat` |
| Equalize width | `<Space>wae` |
| Maximize width | `<Space>wam` |

---

### tmux Integration

| Plugin | Description |
|---|---|
| [christoomey/vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless navigation between tmux panes and Neovim splits |

Pane navigation (`Ctrl+H/J/K/L`) is shared between Neovim and tmux.

---

### Which-Key

| Plugin | Description |
|---|---|
| [folke/which-key.nvim](https://github.com/folke/which-key.nvim) | Keymap hints popup on partial key press |

Press any prefix (e.g. `<Space>`) and wait to see all available keymaps.

---

## 4. Basic Editing (Vim-native)

| Action | Key |
|---|---|
| Exit insert mode | `jk` |
| Search | `/keyword` then Enter |
| Next match | `n` |
| Previous match | `N` |
| Clear highlight | `<Space>an` |
| Yank a line | `yy` |
| Paste after cursor | `p` |
| Paste before cursor | `P` |
| Yank to end of line | `y$` |
| Visual select and yank | `v` → move → `y` |
| Jump to file start | `gg` |
| Jump to file end | `G` |
| Jump to line start | `0` (absolute) / `^` (first non-blank) |
| Jump to line end | `$` |
| Fold / unfold | `Tab` |
| Jump forward (tag) | `Ctrl+I` |
| Jump backward (tag) | `Ctrl+O` |

---

## 5. Buffer & Tab

| Action | Key |
|---|---|
| List buffers | `Ctrl+B` or `<Space>bb` |
| Tab-local buffers | `<Space>bB` |
| Previous buffer | `{` or `<Space>bh` |
| Next buffer | `}` or `<Space>bl` |
| Move buffer left | `<Space>bH` |
| Move buffer right | `<Space>bL` |
| Close current buffer | `Ctrl+C` or `<Space>bc` |
| Close other buffers | `<Space>bo` |
| New empty buffer | `<Space>bn` |
| Pin buffer | `<Space>bp` |
| Pick buffer | `<Space>bP` |
| New tab | `<Space>tn` |
| Close tab | `<Space>tc` |
| List tabs | `<Space>tt` |
| Previous tab | `Ctrl+[` |
| Next tab | `Ctrl+]` |
| Go to tab N | `<Space>t1` ~ `<Space>t9` |

---

## 6. Config Management

| Action | Key |
|---|---|
| Edit config files | `<Space>Cc` |
| Select config (Neoconf) | `<Space>CC` |
| Edit local config | `<Space>Cl` |
| Edit global config | `<Space>Cg` |
| Show config | `<Space>Cs` |
| Show LSP config | `<Space>Cp` |

---

## 7. Language-Specific Keymaps

### Go (`<Space>` prefix, active in `.go` files)

| Action | Key |
|---|---|
| Alt file | `<Space>a` |
| Go test | `<Space>tt` |
| Code action | `<Space>c` |

### Dart / Flutter (`,` local leader prefix, active in `.dart` files)

| Action | Key |
|---|---|
| Flutter commands | `,,` |
| Emulators | `,e` |
| Toggle widget outline | `,w` |
| Run Flutter | `,r` |
| Restart Flutter | `,R` |
| Extract method | `,M` |
| Extract widget | `,W` |
| Extract local variable | `,L` |
| Wrap with widget | `,A` |

### Lua (`,` local leader prefix, active in `.lua` files)

| Action | Key |
|---|---|
| Source current file | `,s` |
| Run current buffer | `,r` |

### Python (`,` local leader prefix, active in `.py` files)

| Action | Key |
|---|---|
| Run code | `,r` |

---

## 8. Competitive Programming

| Plugin | Description |
|---|---|
| [xeluxee/competitest.nvim](https://github.com/xeluxee/competitest.nvim) | Competitive programming test runner |

| Action | Key |
|---|---|
| Receive problem | `<Space>Ic` |
| Run tests | `<Space>Ir` |
| Add testcase | `<Space>Ia` |
| Edit testcase | `<Space>Ie` |
| Delete testcase | `<Space>Id` |

---

## 9. Collaborative Editing

| Plugin | Description |
|---|---|
| [nomad/nomad](https://github.com/nickeisenberg/nomad) | Collaborative editing |

---

## 10. Other

| Action | Key |
|---|---|
| Open terminal | `<Space>!` |
| Quit all | `<Space>aq` |
| All commands (Telescope) | `<Space><Space>` |
| View keymaps (Telescope) | `<Space>ak` |

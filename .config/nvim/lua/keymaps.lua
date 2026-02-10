-- Remap jk to <ESC>
vim.keymap.set("i", "jk", "<esc>")

-- Use C-i C-o to jump between locations
vim.keymap.set("n", "<C-i>", "<C-]>")

-- Fold
vim.keymap.set("n", "<tab>", "za")

-- Buffers
vim.keymap.set("n", "<C-c>", utils.bufdelete.delete)
vim.keymap.set("n", "<C-b>", "<cmd>Telescope buffers<cr>")
vim.keymap.set("n", "{", "<cmd>BufferLineCyclePrev<cr>")
vim.keymap.set("n", "}", "<cmd>BufferLineCycleNext<cr>")

-- Tabs
vim.keymap.set("n", "<C-[>", "<cmd>tabprevious<cr>")
vim.keymap.set("n", "<C-]>", "<cmd>tabnext<cr>")

-- File
vim.keymap.set("n", "<C-f>", "<cmd>Telescope find_files<cr>")

-- Emoji
vim.keymap.set("i", "<C-e>", "<cmd>Telescope emoji<cr>")

-- moving between splits
vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)

local wk = require("which-key")

-- ========================================
-- |        Keymaps with <Leader>         |
-- ========================================
wk.add({
	mode = { "n", "x" },
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
	{ "<leader><leader>", "<cmd>Telescope commands<cr>", group = "命令 (Commands)", desc = "Telescope 命令 (Telescope commands)" },
	-- Application
	{ "<leader>a", group = "应用 (Application)" },
	{ "<leader>aq", "<cmd>quitall<cr>", desc = "退出所有 (Quit All)" },
	{ "<leader>an", "<cmd>noh<cr>", desc = "停止高亮 (Stop Highlight)" },
	{ "<leader>aj", "<cmd>Telescope jumplist<cr>", desc = "历史跳转列表 (Jumplist)" },
	{ "<leader>as", "<cmd>Telescope live_grep<cr>", desc = "全局搜索 (Search)" },
	{ "<leader>ah", "<cmd>Telescope help_tags<cr>", desc = "帮助 (Help Tags)" },
	{ "<leader>ac", "<cmd>Telescope colorscheme<cr>", desc = "切换主题 (Colorscheme)" },
	{ "<leader>ak", "<cmd>Telescope keymaps<cr>", desc = "键位映射 (Keymaps)" },
	{ "<leader>at", "<cmd>TodoTelescope<cr>", desc = "待办列表 (Todo List)" },
	{ "<leader>ae", "<cmd>Telescope emoji<cr>", desc = "表情符号 (Emoji)" },
	{ "<leader>am", "<cmd>Telescope notify<cr>", desc = "消息通知 (Messages)" },
	-- Config
	{ "<leader>C", group = "配置 (Config)" },
	{ "<leader>Cc", utils.config_files, desc = "编辑配置 (Edit Config)" },
	{ "<leader>CC", "<cmd>Neoconf<cr>", desc = "选择配置 (Select Config)" },
	{ "<leader>Cl", "<cmd>Neoconf local<cr>", desc = "编辑本地配置 (Edit Local Config)" },
	{ "<leader>Cg", "<cmd>Neoconf global<cr>", desc = "编辑全局配置 (Edit Global Config)" },
	{ "<leader>Cs", "<cmd>Neoconf show<cr>", desc = "显示配置 (Show Config)" },
	{ "<leader>Cp", "<cmd>Neoconf lsp<cr>", desc = "显示 LSP 配置 (Show LSP Config)" },
	-- Terminal
	{ "<leader>!", utils.term.select, desc = "打开终端 (Open Terminal)" },
	-- Tab
	{ "<leader>t", group = "标签页 (Tab)" },
	{ "<leader>tn", "<cmd>tabnew<cr>", desc = "新建标签页 (New Empty Tab)" },
	{ "<leader>tc", "<cmd>tabclose<cr>", desc = "关闭当前标签页 (Close Current Tab)" },
	{ "<leader>tt", require("telescope-tabs").list_tabs, desc = "查找标签页 (Tabs)" },
	{ "<leader>t1", "<cmd>exec 'normal! 1gt'<cr>", desc = "切换到标签页 1 (Go to Tab 1)" },
	{ "<leader>t2", "<cmd>exec 'normal! 2gt'<cr>", desc = "切换到标签页 2 (Go to Tab 2)" },
	{ "<leader>t3", "<cmd>exec 'normal! 3gt'<cr>", desc = "切换到标签页 3 (Go to Tab 3)" },
	{ "<leader>t4", "<cmd>exec 'normal! 4gt'<cr>", desc = "切换到标签页 4 (Go to Tab 4)" },
	{ "<leader>t5", "<cmd>exec 'normal! 5gt'<cr>", desc = "切换到标签页 5 (Go to Tab 5)" },
	{ "<leader>t6", "<cmd>exec 'normal! 6gt'<cr>", desc = "切换到标签页 6 (Go to Tab 6)" },
	{ "<leader>t7", "<cmd>exec 'normal! 7gt'<cr>", desc = "切换到标签页 7 (Go to Tab 7)" },
	{ "<leader>t8", "<cmd>exec 'normal! 8gt'<cr>", desc = "切换到标签页 8 (Go to Tab 8)" },
	{ "<leader>t9", "<cmd>exec 'normal! 9gt'<cr>", desc = "切换到标签页 9 (Go to Tab 9)" },
	-- Buffer
	{ "<leader>b", group = "缓冲区 (Buffer)" },
	{ "<leader>bb", "<cmd>Telescope buffers<cr>", desc = "查找缓冲区 (Buffers)" },
	{ "<leader>bB", "<cmd>Telescope buffers<cr>", desc = "当前标签页缓冲区 (Tab-local Buffers)" },
	{ "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "关闭其他缓冲区 (Close Other Buffers)" },
	{ "<leader>bh", "<cmd>BufferLineCyclePrev<cr>", desc = "上一个缓冲区 (Previous Buffer)" },
	{ "<leader>bl", "<cmd>BufferLineCycleNext<cr>", desc = "下一个缓冲区 (Next Buffer)" },
	{ "<leader>bH", "<cmd>BufferLineMovePrev<cr>", desc = "向左移动 (Move Left)" },
	{ "<leader>bL", "<cmd>BufferLineMoveNext<cr>", desc = "向右移动 (Move Right)" },
	{ "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "锁定缓冲区 (Pin Buffer)" },
	{ "<leader>bP", "<cmd>BufferLinePick<cr>", desc = "选择缓冲区 (Pick Buffer)" },
	{ "<leader>bn", "<cmd>enew<cr>", desc = "新建空白缓冲区 (New Buffer)" },
	{ "<leader>bc", utils.bufdelete.delete, desc = "关闭缓冲区 (Close Buffer)" },
	-- Diagnostic
	{ "<leader>e", group = "诊断 (Diagnostic)" },
	-- File
	{ "<leader>f", group = "文件 (File)" },
	{ "<leader>fw", "<cmd>silent wa<cr>", desc = "保存文件 (Save File)" },
	{ "<leader>fl", "<cmd>Neotree<cr>", desc = "文件浏览器 (File Explorer)" },
	{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "最近文件 (Recent Files)" },
	{ "<leader>fd", "<cmd>Ex<cr>", desc = "文件管理器 (Netrw)" },
	{ "<leader>fh", "<cmd>Neotree toggle<CR>", desc = "展开收起文件浏览器侧边栏 (Toggle File Explorer)" },
	-- Window
	{ "<leader>w", group = "窗口 (Window)" },
	{ "<leader>wa", desc = "自动调整大小 (Auto Resize)" },
	{ "<leader>wat", "<cmd>WindowsToggleAutowidth<cr>", desc = "切换自动宽度 (Toggle Auto Width)" },
	{ "<leader>wae", "<cmd>WindowsEqualize<cr>", desc = "平均化宽度 (Equalize Width)" },
	{ "<leader>wam", "<cmd>WindowsMaximize<cr>", desc = "最大化宽度 (Maximize Width)" },
	-- Git
	{
		"<leader>g",
		-- function()
		-- 	require("which-key").show({ keys = "<leader>g", loop = true })
		-- end,
		group = "Git",
	},
	{ "<leader>gg", require("neogit").open, desc = "打开 Neogit" },
	{
		"<leader>gG",
		function()
	        vim.cmd("tabnew")
	        vim.fn.termopen("lazygit", { on_exit = function() vim.cmd("bdelete!") end })
	        vim.cmd("startinsert")
	    end,
		desc = "打开 Lazygit"
	},
	{ "<leader>gs", "<cmd>Gitsigns stage_hunk<cr>", desc = "暂存当前块 (Stage Hunk)" },
	{ "<leader>gS", "<cmd>Gitsigns stage_buffer<cr>", desc = "暂存整个文件 (Stage Buffer)" },
	{ "<leader>gu", "<cmd>Gitsigns undo_stage_hunk<cr>", desc = "撤销暂存块 (Undo Stage Hunk)" },
	{ "<leader>gx", "<cmd>Gitsigns reset_hunk<cr>", desc = "重置当前块 (Reset Hunk)" },
	{ "<leader>gd", group = "Diff (差异)" },
	{ "<leader>gdd", "<cmd>Gitsigns diffthis<cr>", desc = "查看差异 (Diff This)" },
	{ "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "关闭差异视图 (Close Diff)" },
	{ "<leader>gdf", "<cmd>DiffviewFileHistory %<cr>", desc = "当前文件历史 (Current File History)" },
	{ "<leader>gdt", "<cmd>DiffviewToggleFiles<cr>", desc = "切换差异文件列表 (Toggle Files)" },
	{ "<leader>gj", "<cmd>Gitsigns next_hunk<cr>", desc = "下一个块 (Next Hunk)" },
	{ "<leader>gk", "<cmd>Gitsigns prev_hunk<cr>", desc = "上一个块 (Previous Hunk)" },
	{ "<leader>gh", "<cmd>Gitsigns preview_hunk_inline<cr>", desc = "行内预览块 (Preview Hunk)" },
	{ "<leader>gH", "<cmd>Gitsigns preview_hunk<cr>", desc = "弹窗预览块 (Preview Hunk Popup)" },

	{ "<leader>gl", "<cmd>Neotree git_status<cr>", desc = "Git 状态 (Git Status)" },
	{ "<leader>gt", group = "切换 (Toggle)" },
	{ "<leader>gtl", "<cmd>Gitsigns toggle_linehl<cr>", desc = "行高亮 (Line Highlight)" },
	{ "<leader>gtn", "<cmd>Gitsigns toggle_numhl<cr>", desc = "行号高亮 (Number Highlight)" },
	{ "<leader>gts", "<cmd>Gitsigns toggle_signs<cr>", desc = "符号显示 (Signs)" },
	{ "<leader>gb", "<cmd>Gitsigns blame<cr>", desc = "行级追溯 (Blame)" },
	{ "<leader>gB", "<cmd>Gitsigns blame_line<cr>", desc = "行级追溯弹窗 (Blame Line)" },
	-- Project
	{ "<leader>p", group = "项目 (Project)" },
	{
		"<leader>pp",
		function()
			require("telescope").extensions.projects.projects({})
		end,
		desc = "切换项目 (Projects)",
	},
	{ "<leader>pP", "<cmd>ProjectRoot<cr>", desc = "重置项目根目录 (Reset Root Directory)" },
	{ "<leader>pa", "<cmd>AddProject<cr>", desc = "添加项目 (Add Project)" },
	-- Zoxide
	{ 
        "<leader>z", 
        function() 
            require("telescope").extensions.zoxide.list() 
        end, 
        desc = "Zoxide 跳转 (Zoxide)" 
    },
	-- Package Management
	{ "<leader>P", "<cmd>Lazy<cr>", desc = "包管理 (Package Management)" },
	-- Debug
	{ "<leader>d", group = "调试 (Debug)" },
	{
		"<leader>ds",
		function()
			require("osv").launch({ port = 8086 })
		end,
		desc = "启动调试服务器 (Start Debug Server)",
	},
	{ "<leader>db", require("dap").toggle_breakpoint, desc = "切换断点 (Toggle Breakpoint)" },
	{ "<leader>du", require("dapui").toggle, desc = "切换 DAP UI (Toggle DAP UI)" },
	{ "<leader>dc", require("dap").continue, desc = "启动或继续 (Start or Continue)" },
	{ "<leader>dn", require("dap").step_over, desc = "步过 (Step Over)" },
	{ "<leader>di", require("dap").step_into, desc = "步入 (Step Into)" },
	{ "<leader>do", require("dap").step_out, desc = "步出 (Step Out)" },
	{ "<leader>dq", require("dap").terminate, desc = "终止调试 (Terminate)" },
	{ "<leader>dl", require("dap.repl").toggle, desc = "切换 REPL (Toggle REPL)" },
	{ "<leader>dL", require("dap.repl").clear, desc = "清空 REPL (Clear REPL)" },
	-- Competitive Programming
	{ "<leader>I", group = "竞赛编程 (Competitive)" },
	{
		"<leader>Ic",
		function()
			local ok, picker = pcall(require, "fzf-lua")
			if not ok then
				vim.notify("fzf-lua not found", vim.log.levels.ERROR)
				return
			end
			picker.fzf_exec("fd --type d", {
				actions = {
					["default"] = function(selected)
						_G.received_position = vim.fn.fnamemodify(selected[1], ":p")
					end,
				},
			})
			vim.cmd("CompetiTest receive problem")
		end,
		desc = "接收问题 (Receive Problem)",
	},
	{
		"<leader>Ir",
		"<cmd>CompetiTest run<cr>",
		desc = "运行测试 (Run)",
	},
	{
		"<leader>Ia",
		"<cmd>CompetiTest add_testcase<cr>",
		desc = "添加测试用例 (Add Testcase)",
	},
	{
		"<leader>Ie",
		"<cmd>CompetiTest edit_testcase<cr>",
		desc = "编辑测试用例 (Edit Testcase)",
	},
	{
		"<leader>Id",
		"<cmd>CompetiTest delete_testcase<cr>",
		desc = "删除测试用例 (Delete Testcase)",
	},
})

-- Go Special Keymaps
utils.map_on_filetype("go", {
	a = { "<cmd>GoAlt<cr>", "Go 备用文件 (Alt)" },
	t = {
		name = "测试 (Test)",
		t = { "<cmd>GoTest<cr>", "运行 Go 测试 (GoTest)" },
	},
	c = { "<cmd>GoCodeAction<cr>", "Go 代码操作 (GoCodeAction)", mode = { "n", "v" } },
})

-- Dart Special Keymaps
utils.map_on_filetype("dart", {
	["<localleader>"] = { "<cmd>Telescope flutter commands<cr>", "Flutter 命令 (Flutter Commands)" },
	e = { "<cmd>FlutterEmulators<cr>", "模拟器 (Emulators)" },
	w = { "<cmd>FlutterOutlineToggle<cr>", "切换组件大纲 (Toggle Widget Outline)" },
	r = { "<cmd>FlutterRun<cr>", "运行 Flutter (Run Flutter)" },
	R = { "<cmd>FlutterRestart<cr>", "热重启 Flutter (Restart Flutter)" },
	M = {
		function()
			vim.lsp.buf.code_action({
				apply = true,
				filter = function(action)
					return action.title == "Extract Method"
				end,
			})
		end,
		"提取方法 (Extract Method)",
	},
	W = {
		function()
			vim.lsp.buf.code_action({
				apply = true,
				filter = function(action)
					return action.title == "Extract Widget"
				end,
			})
		end,
		"提取组件 (Extract Widget)",
	},
	L = {
		function()
			vim.lsp.buf.code_action({
				apply = true,
				filter = function(action)
					return action.title == "Extract Local Variable"
				end,
			})
		end,
		"提取局部变量 (Extract Local Variable)",
	},
	A = {
		function()
			vim.lsp.buf.code_action({
				apply = true,
				filter = function(action)
					return action.title == "Wrap with widget..."
				end,
			})
		end,
		"包裹组件 (Wrap with Widget)",
	},
})

local augroup = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup,
	callback = function(data)
		local client = vim.lsp.get_client_by_id(data.data.client_id)
		if not client then
			vim.notify("Failed to get LSP Client by Id: " .. data.id, vim.log.levels.WARN)
			return
		end

		local buf = data.buf
		if client:supports_method("textDocument/inlayHint", buf) then
			vim.lsp.inlay_hint.enable(false, { bufnr = buf })
		end
		-- shortcuts
		local bufopts = { noremap = true, silent = true, buffer = buf }
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
		vim.keymap.set("n", "ca", vim.lsp.buf.code_action, bufopts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
		vim.keymap.set("n", "gD", vim.lsp.buf.type_definition, bufopts)
		vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", bufopts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			"go",
			":Telescope lsp_dynamic_workspace_symbols<CR>",
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			"gl",
			":Telescope lsp_document_symbols<CR>",
			{ noremap = true, silent = true }
		)

		-- register keymaps using which-key
		require("which-key").add({
			{ "<leader>l", group = "LSP" }, -- group for LSP
			{ "<leader>ln", vim.lsp.buf.rename, desc = "重命名 (Rename)", buffer = buf },
			{ "<leader>la", vim.lsp.buf.code_action, desc = "代码操作 (Code Action)" },
			{ "<leader>l", group = "跳转 (Goto)" },
			{ "<leader>lgd", vim.lsp.buf.definition, desc = "跳转到定义 (Go to Definition)" },
			{ "<leader>lgD", vim.lsp.buf.type_definition, desc = "类型定义 (Type Definition)" },
			{ "<leader>lgr", "<cmd>Telescope lsp_references<cr>", desc = "查看引用 (References)" },
			{ "<leader>lgi", vim.lsp.buf.implementation, desc = "实现 (Implementation)" },
			{ "<leader>lgo", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "工作区符号 (Workspace Symbols)" },
			{ "<leader>lgl", "<cmd>Telescope lsp_document_symbols<cr>", desc = "文档符号 (Document Symbols)" },
			{ "<leader>lt", group = "切换 (Toggle)", buffer = buf },
			{ "<leader>lti", utils.toggles.toggle_inlay_hint, desc = "切换内嵌提示 (Toggle Inlay Hint)" },
		})
	end,
})

-- Lua Special Keymaps
utils.map_on_filetype("lua", {
	["s"] = { "<cmd>source %<cr>", "重新加载 (Source)" },
	r = { "<cmd>LuaRun<cr>", "运行当前文件 (Run Current Buffer)" },
})

-- Python Special Keymaps
utils.map_on_filetype("python", {
	["r"] = { "<cmd>RunCode<cr>", "运行代码 (Run)" },
})
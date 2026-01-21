return {
	"nvim-neo-tree/neo-tree.nvim",
	version = "v3.x",
	dependencies = { 
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])

		require("neo-tree").setup({
			enable_git_status = true,
			popup_border_style = "rounded",
			close_if_last_window = true,

			window = {
				width = 45,
				mappings = {
					["<tab>"] = "open",
					["O"] = "expand_all_nodes",
					["C"] = "close_all_subnodes",
				},
			},
			filesystem = {
				filtered_items = {
					hide_by_pattern = { -- uses glob style patterns
						"*.g.dart",
						"*.freezed.dart",
						"__pycache__",
					},

					always_show = {
						".gitignore",
						".nvim.lua",
					},
				},
				window = {
					mappings = {
						------------------------------------------------------------------
						-- 🔍 SEARCH
						------------------------------------------------------------------
						["f"] = "fuzzy_finder",      -- fast fuzzy search (file/dir)
						["/"] = "fuzzy_finder",      -- fast fuzzy search (file/dir)

						------------------------------------------------------------------
						-- 📁 FILE OPERATIONS
						------------------------------------------------------------------
						["Y"] = "copy_to_clipboard",     -- copy file/dir
						["P"] = "paste_from_clipboard",  -- paste copied file/dir
						["M"] = "move",                  -- move file/dir
						["D"] = "delete",                -- delete file/dir

						------------------------------------------------------------------
						-- ➕ CREATE / ✏️ RENAME
						------------------------------------------------------------------
						["A"] = "add",                   -- create file or folder
						["Ctrl+A"] = "add_directory",    -- create folder only
						["R"] = "rename",                -- rename file/dir

						------------------------------------------------------------------
						-- 📂 ROOT MANAGEMENT
						------------------------------------------------------------------
						["c"] = "set_root",              -- set current node as new root
						["H"] = "navigate_up",           -- go to parent directory root

						------------------------------------------------------------------
						-- ⏩ EASY NAVIGATION
						------------------------------------------------------------------
						["l"] = "open",                  -- open file / expand folder
						["h"] = "close_node",            -- collapse folder
						["<space>"] = "toggle_node",     -- toggle folder
						["."] = "toggle_hidden",         -- toggle hidden files
					},
				},
				bind_to_cwd = true, 
				use_libuv_file_watcher = true,
				follow_current_file = {
					enabled = true,
					leave_dirs_open = true,
				},
			},
		})
	end,
}

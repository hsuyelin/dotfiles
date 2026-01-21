local dashboard = require("utils.dashboard")

local configs = {
	advanced = {
		sections = {
			{ section = "header", padding = 1 },
			-- {
			-- 	pane = 2,
			-- 	section = "terminal",
			-- 	cmd = "colorscript -e square",
			-- 	height = 5,
			-- 	padding = 1,
			-- },
			{ section = "keys", gap = 1, padding = 1 },
			{ pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
			{ pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
			-- {
			-- 	pane = 2,
			-- 	icon = " ",
			-- 	title = "Git Status",
			-- 	section = "terminal",
			-- 	enabled = function()
			-- 	end,
			-- 	cmd = "git status --short --branch --renames",
			-- 	height = 5,
			-- 	padding = 1,
			-- 	ttl = 5 * 60,
			-- 	indent = 3,
			-- },
			{ section = "startup" },
		},
	},
	chafa = {},
	compact_files = {},
	doom = {},
	files = {},
	github = {},
	pokemon = {},
	startify = {},
}

if vim.fn.argc(-1) == 0 then
	local augroup = vim.api.nvim_create_augroup("dashboard", { clear = true })
	vim.api.nvim_create_autocmd("VimEnter", {
		group = augroup,
		callback = function()
			dashboard(configs.advanced)
		end,
	})
end

return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"jay-babu/mason-nvim-dap.nvim",
	},
	priority = 100,
	config = function()
		require("mason").setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗"
				}
			},
			keymaps = {
				toggle_package_expand = "<TAB>",
			},
		})

		require("mason-lspconfig").setup({
			automatic_installation = true,
		})
		local lsp_servers = require("core.configs").lsp.servers
		local ensure_installed = {}
		for _, server in ipairs(lsp_servers) do
			if type(server) == "string" then
				table.insert(ensure_installed, server)
			elseif type(server) == "table" and server[1] and (server["mason"] == nil or server["mason"] == true) then
				table.insert(ensure_installed, server[1])
			end
			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed,
			})
			require("mason-nvim-dap").setup()
		end
	end,
}

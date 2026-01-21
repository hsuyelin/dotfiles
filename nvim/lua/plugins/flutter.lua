return {
	"akinsho/flutter-tools.nvim",
	ft = { "dart" },
	config = function()
		local on_attach = vim.lsp.handlers.on_attach
		local capabilities = vim.lsp.handlers.capabilities

		local dap_avail, _ = pcall(require, "dap")

		require("flutter-tools").setup({
			debugger = {
				enabled = true,
				run_via_dap = dap_avail,
				register_configurations = function(_)
					require("dap").configurations.dart = {
						{
							type = "dart",
							request = "launch",
							name = "Launch Flutter Program",
							program = "./lib/main.dart",
							cwd = "${workspaceFolder}",
							-- This gets forwarded to the Flutter CLI tool, substitute `linux` for whatever device you wish to launch
						},
					}
				end,
			},
			decorations = {
				statusline = {
					app_version = false,
					device = true,
				},
			},
			widget_guides = {
				enabled = true,
			},
			dev_log = {
				enabled = false,
			},
			lsp = {
				on_attach = on_attach,
				capabilities = capabilities,
				color = {
					enabled = true,
					background = true,
					background_color = nil,
					virtual_text = false,
				},
			},
		})

		local telescope_ok, telescope = pcall(require, "telescope")
		if telescope_ok then
			telescope.load_extension("flutter")
		end
	end,
}

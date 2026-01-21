return {
	{
		"mfussenegger/nvim-dap",

		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
		},
		-- config = function()
		-- 	require("configs.dap")
		-- end,
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		opts = {
			virt_text_pos = "eol",
		},
	},
	--
	-- -- Adapters
	-- {
	-- 	"jbyuki/one-small-step-for-vimkind",
	-- 	config = function()
	-- 		local dap = require("dap")
	-- 		dap.configurations.lua = {
	-- 			{
	-- 				type = "nlua",
	-- 				request = "attach",
	-- 				name = "Attach to running Neovim instance",
	-- 			},
	-- 		}
	--
	-- 		dap.adapters.nlua = function(callback, config)
	-- 			callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
	-- 		end
	-- 	end,
	-- },
}

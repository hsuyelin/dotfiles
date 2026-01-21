local M = {}

require("configs.dap.highlight")

-- load all files in the cfgs directory
local filelist = vim.fn.readdir(vim.fn.expand("~/.config/nvim/lua/configs/dap/langs"))
for _, fname in ipairs(filelist) do
	local path = "configs.dap.langs." .. fname:gsub(".lua", "")
	local ok, _ = pcall(require, path)
	if not ok then
		vim.notify("Error loading: " .. path, vim.log.levels.ERROR)
	end
end

-- auto close/open dapui and set keybindings
-- local dap = require("dap")
local dapui = require("dapui")
dapui.setup()
--
-- dap.listeners.before.attach.dapui_config = function()
-- 	dapui.open()
-- end
-- dap.listeners.before.launch.dapui_config = function()
-- 	dapui.open()
-- end
-- dap.listeners.before.event_terminated.dapui_config = function()
-- 	dapui.close()
-- end
-- dap.listeners.before.event_exited.dapui_config = function()
-- 	dapui.close()
-- end
--

M.servers = {}

return M

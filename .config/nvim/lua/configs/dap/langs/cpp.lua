local dap = require("dap")

dap.adapters.codelldb = {
	type = "server",
	port = "${port}",
	executable = {
		command = "codelldb",
		args = { "--port", "${port}" },
	},
}
dap.configurations.cpp = {
	{
		name = "File Launch",
		type = "codelldb",
		request = "launch",
		program = function()
			local filename = vim.fn.expand("%")
			local program = vim.fn.getcwd() .. "/" .. vim.fn.expand("%:r")
			vim.fn.system("g++ -g " .. filename .. " -o " .. program)
			return program
		end,
		cwd = "${workspaceFolder}",
		terminal = "console",
		stopOnEntry = false,
		breakpointMode = "file",
	},
}

dap.configurations.c = dap.configurations.cpp

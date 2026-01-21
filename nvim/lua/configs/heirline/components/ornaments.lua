local utils = require("heirline.utils")
local conditions = require("heirline.conditions")

local LSPActiveCondition = {
	condition = conditions.lsp_attached,
}
local LSPActive = {
	update = { "LspAttach", "LspDetach" },
	provider = function()
		local names = {}
		for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
			table.insert(names, server.name)
		end
		return " " .. table.concat(names, " ")
	end,
	hl = { fg = "black", bg = "green", bold = false },
	-- hl = { fg = "green", bold = false },
}
LSPActiveCondition = utils.insert(LSPActiveCondition, utils.surround({ "", "" }, "green", LSPActive))

local GitBranchCondition = {
	condition = conditions.is_git_repo,
}
local GitBranch = {
	init = function(self)
		self.status_dict = vim.b.gitsigns_status_dict
	end,
	hl = { fg = "black", bg = "orange", bold = false },
	-- hl = { fg = "orange", bold = false },

	-- git branch name
	{
		provider = function(self)
			return " " .. self.status_dict.head
		end,
	},
}
GitBranchCondition = utils.insert(GitBranchCondition, utils.surround({ "", "" }, "orange", GitBranch))

return {
	LSPActive = LSPActiveCondition,
	GitBranch = GitBranchCondition,
}

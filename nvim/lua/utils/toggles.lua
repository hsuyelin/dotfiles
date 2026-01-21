local M = {}

function M.toggle_inlay_hint()
	local is_enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
	vim.lsp.inlay_hint.enable(not is_enabled, { bufnr = 0 })
end

return M

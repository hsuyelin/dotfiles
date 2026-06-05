-- Prefer xcrun to guarantee the active Xcode toolchain is used;
-- fall back to PATH on non-macOS.
local function sourcekit_cmd()
	if vim.uv.os_uname().sysname ~= "Darwin" then
		return { "sourcekit-lsp" }
	end
	local path = vim.fn.system({ "xcrun", "--find", "sourcekit-lsp" }):gsub("%s+$", "")
	return (path ~= "" and vim.fn.filereadable(path) == 1)
		and { path }
		or { "sourcekit-lsp" }
end

return {
	cmd = sourcekit_cmd(),
	filetypes = { "swift" },
	root_markers = vim.list_extend(
		vim.deepcopy(core.configs.root_markers),
		{ "buildServer.json", "Package.swift" }
	),
}

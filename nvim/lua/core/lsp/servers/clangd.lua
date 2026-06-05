vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "cpp", "objc", "objcpp" },
	callback = function(ev)
		vim.keymap.set("n", "gA", function()
			local params = vim.lsp.util.make_text_document_params(ev.buf)
			vim.lsp.buf_request(ev.buf, "textDocument/switchSourceHeader", params, function(err, result)
				if err or not result then
					vim.notify("No alternate file found", vim.log.levels.WARN)
					return
				end
				vim.cmd("edit " .. vim.fn.fnameescape(vim.uri_to_fname(result)))
			end)
		end, { buffer = ev.buf, desc = "Switch header ↔ source (clangd)" })
	end,
})

-- On macOS, prefer the Xcode toolchain clangd so its version matches the
-- Apple clang that built Xcode's ModuleCache.noindex. Using a mismatched
-- clangd (e.g. Mason's LLVM upstream build) causes all PCMs to be rebuilt
-- from scratch, which fails for iOS cross-compilation targets.
local function clangd_cmd()
	if vim.uv.os_uname().sysname ~= "Darwin" then
		return { "clangd" }
	end
	local xcode_clangd = vim.fn.system({ "xcrun", "--find", "clangd" }):gsub("%s+$", "")
	if xcode_clangd ~= "" and vim.fn.filereadable(xcode_clangd) == 1 then
		return { xcode_clangd }
	end
	return { "/usr/bin/clangd" }
end

return {
	cmd = clangd_cmd(),
	filetypes = { "c", "cpp", "objc", "objcpp" },
	root_markers = vim.list_extend(
		vim.deepcopy(core.configs.root_markers),
		{ "compile_commands.json", "buildServer.json", "*.xcodeproj", "*.xcworkspace" }
	),
}

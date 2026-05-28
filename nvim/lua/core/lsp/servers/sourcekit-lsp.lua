-- Auto-generate buildServer.json (sourcekit-lsp) and compile_commands.json (clangd)
-- when opening a Swift/ObjC file and the config files are missing.
local function xcode_index_setup(root, workspace)
	if vim.fn.executable("xcode-build-server") == 0 then return end

	-- Derive candidate scheme from workspace name; fall back to xcodebuild -list on failure.
	local guessed_scheme = vim.fn.fnamemodify(workspace, ":t:r")

	local function run_config(scheme)
		vim.fn.jobstart(
			{ "xcode-build-server", "config", "-workspace", workspace, "-scheme", scheme },
			{
				cwd = root,
				on_exit = function(_, code)
					if code == 0 then
						vim.notify(
							"[xcode] buildServer.json ready (scheme=" .. scheme .. "). Run :LspRestart",
							vim.log.levels.INFO
						)
					else
						vim.notify(
							"[xcode] xcode-build-server failed for scheme=" .. scheme,
							vim.log.levels.WARN
						)
					end
				end,
			}
		)
	end

	-- Try guessed scheme first; on failure query xcodebuild -list and retry with first valid scheme.
	local stderr_lines = {}
	vim.fn.jobstart(
		{ "xcode-build-server", "config", "-workspace", workspace, "-scheme", guessed_scheme },
		{
			cwd = root,
			on_stderr = function(_, data) vim.list_extend(stderr_lines, data) end,
			on_exit = function(_, code)
				if code == 0 then
					vim.notify(
						"[xcode] buildServer.json ready. Run :LspRestart",
						vim.log.levels.INFO
					)
					return
				end
				-- Scheme guess failed — query the real scheme list
				local schemes = {}
				vim.fn.jobstart(
					{ "xcodebuild", "-workspace", workspace, "-list" },
					{
						cwd = root,
						stdout_buffered = true,
						on_stdout = function(_, data)
							local in_schemes = false
							for _, line in ipairs(data) do
								if line:match("Schemes:") then in_schemes = true
								elseif in_schemes then
									local s = line:match("^%s+(.+)$")
									-- Skip Pods- prefixed and test schemes
									if s and not s:match("^Pods%-") and not s:match("Tests?$") then
										table.insert(schemes, s)
									end
								end
							end
						end,
						on_exit = function(_, _)
							if #schemes == 0 then
								vim.notify("[xcode] no valid scheme found in workspace", vim.log.levels.WARN)
								return
							end
							run_config(schemes[1])
						end,
					}
				)
			end,
		}
	)
end

local function generate_compile_commands(root)
	-- Parse the most recent Xcode build log to produce compile_commands.json for clangd.
	-- Requires: xcode-build-server parse, xcactivitylog in DerivedData.
	if vim.fn.executable("xcode-build-server") == 0 then return end
	if vim.fn.filereadable(root .. "/compile_commands.json") == 1 then return end

	-- Find DerivedData for projects rooted here
	local dd_base = vim.fn.expand("~/Library/Developer/Xcode/DerivedData")
	local logs = vim.fn.glob(dd_base .. "/*/Logs/Build/*.xcactivitylog", false, true)
	if #logs == 0 then return end

	-- Filter to logs whose DerivedData info.plist WorkspacePath starts with root
	local valid = vim.tbl_filter(function(p)
		local info = p:match("(.*)/Logs/Build/") .. "/info.plist"
		if vim.fn.filereadable(info) == 0 then return false end
		local content = table.concat(vim.fn.readfile(info), "\n")
		return content:find(root, 1, true) ~= nil
	end, logs)
	if #valid == 0 then return end

	-- Sort by modification time (newest first) and take the latest
	table.sort(valid, function(a, b)
		return vim.fn.getftime(a) > vim.fn.getftime(b)
	end)
	local latest_log = valid[1]

	vim.fn.jobstart(
		{ "xcode-build-server", "parse", "-logArchive", latest_log },
		{
			cwd = root,
			stdout_buffered = true,
			on_stdout = function(_, data)
				if #data > 0 and data[1] ~= "" then
					vim.fn.writefile(data, root .. "/compile_commands.json")
					vim.notify("[xcode] compile_commands.json generated for clangd", vim.log.levels.INFO)
				end
			end,
		}
	)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "swift", "objc", "objcpp" },
	callback = function()
		local root = vim.fs.root(0, { ".git", "*.xcodeproj", "*.xcworkspace" })
		if not root then return end

		-- buildServer.json: needed by sourcekit-lsp for Swift (and ObjC via same build server)
		if vim.fn.filereadable(root .. "/buildServer.json") == 0 then
			local ws = vim.fn.glob(root .. "/**/*.xcworkspace", false, true)
			ws = vim.tbl_filter(function(p)
				return not p:match("/Pods/") and not p:match("%.xcodeproj/")
			end, ws)
			if #ws > 0 then
				xcode_index_setup(root, ws[1])
			end
		end

		-- compile_commands.json: needed by clangd for ObjC/C/C++ gd
		generate_compile_commands(root)
	end,
})

return {
	cmd = { "sourcekit-lsp" },
	filetypes = { "swift" },
	root_markers = vim.list_extend(vim.deepcopy(core.configs.root_markers), { "*.xcodeproj" }),
}

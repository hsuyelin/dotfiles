local fullpath = "/tmp/xcodebuild.nvim/"
_G.handle = _G.handle or vim.uv.new_fs_event()

if _G.handle then
	_G.handle:start(fullpath, {
		recursive = false,
		stat = true,
		watch_entry = true,
		persistent = true,
	}, function(_, _, _)
		vim.schedule(function()
			vim.cmd.checktime()
		end)
	end)
end

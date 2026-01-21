return {
	{
		"folke/snacks.nvim",
		opts = {
			image = {
				enabled = true,
			},
		},
	},
	{
		"wojciech-kulik/xcodebuild.nvim",
		opts = {
			console_logs = {
				enabled = false, -- enable console logs in dap-ui
				format_line = function(line) -- format each line of logs
					return line
				end,
				filter_line = function(line) -- filter each line of logs
					return true
				end,
			},
		},
	},
}

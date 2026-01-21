---@type string|nil
_G.received_position = nil
return {
	{
		"xeluxee/competitest.nvim",
		dependencies = "MunifTanjim/nui.nvim",
		opts = {
			local_config_file_name = ".competitest.lua",
			floating_border = "rounded",
			floating_border_highlight = "FloatBorder",
			picker_ui = {
				width = 0.2,
				height = 0.3,
				mappings = {
					focus_next = { "j", "<down>", "<Tab>" },
					focus_prev = { "k", "<up>", "<S-Tab>" },
					close = { "<esc>", "<C-c>", "q", "Q" },
					submit = "<cr>",
				},
			},
			editor_ui = {
				popup_width = 0.4,
				popup_height = 0.6,
				show_nu = true,
				show_rnu = false,
				normal_mode_mappings = {
					switch_window = { "<C-h>", "<C-l>", "<C-i>" },
					save_and_close = "<C-s>",
					cancel = { "q", "Q" },
				},
				insert_mode_mappings = {
					switch_window = { "<C-h>", "<C-l>", "<C-i>" },
					save_and_close = "<C-s>",
					cancel = "<C-q>",
				},
			},
			runner_ui = {
				interface = "popup",
				selector_show_nu = false,
				selector_show_rnu = false,
				show_nu = true,
				show_rnu = false,
				mappings = {
					run_again = "R",
					run_all_again = "<C-r>",
					kill = "K",
					kill_all = "<C-k>",
					view_input = { "i", "I" },
					view_output = { "a", "A" },
					view_stdout = { "o", "O" },
					view_stderr = { "e", "E" },
					toggle_diff = { "d", "D" },
					close = { "q", "Q" },
				},
				viewer = {
					width = 0.5,
					height = 0.5,
					show_nu = true,
					show_rnu = false,
					open_when_compilation_fails = true,
				},
			},
			popup_ui = {
				total_width = 0.8,
				total_height = 0.8,
				layout = {
					{ 4, "tc" },
					{ 5, { { 1, "so" }, { 1, "si" } } },
					{ 5, { { 1, "eo" }, { 1, "se" } } },
				},
			},
			split_ui = {
				position = "right",
				relative_to_editor = true,
				total_width = 0.3,
				vertical_layout = {
					{ 1, "tc" },
					{ 1, { { 1, "so" }, { 1, "eo" } } },
					{ 1, { { 1, "si" }, { 1, "se" } } },
				},
				total_height = 0.4,
				horizontal_layout = {
					{ 2, "tc" },
					{ 3, { { 1, "so" }, { 1, "si" } } },
					{ 3, { { 1, "eo" }, { 1, "se" } } },
				},
			},

			save_current_file = true,
			save_all_files = false,
			compile_directory = ".",
			compile_command = {
				c = { exec = "gcc", args = { "-Wall", "$(FNAME)", "-o", "program" } },
				cpp = { exec = "g++", args = { "-Wall", "$(FNAME)", "-o", "program" } },
				-- rust = { exec = "rustc", args = { "$(FNAME)" } },
				-- java = { exec = "javac", args = { "$(FNAME)" } },
			},
			running_directory = ".",
			run_command = {
				c = { exec = "./program" },
				cpp = { exec = "./program" },
				-- rust = { exec = "./$(FNOEXT)" },
				-- python = { exec = "python", args = { "$(FNAME)" } },
				-- java = { exec = "java", args = { "$(FNOEXT)" } },
			},
			multiple_testing = -1,
			maximum_time = 5000,
			output_compare_method = "squish",
			view_output_diff = false,

			testcases_directory = "./testcases/",
			testcases_use_single_file = false,
			testcases_auto_detect_storage = true,
			testcases_single_file_format = "$(FNOEXT).testcases",
			testcases_input_file_format = "$(TCNUM).in",
			testcases_output_file_format = "$(TCNUM).out",

			companion_port = 27121,
			receive_print_message = true,
			start_receiving_persistently_on_setup = false,
			template_file = {
				-- config path
				cpp = vim.fn.stdpath("config") .. "/templates/template.cpp",
			},
			evaluate_template_modifiers = true,
			date_format = "%c",
			received_files_extension = "cpp",
			received_problems_path = function(task, _)
				if received_position == nil or vim.fn.isdirectory(received_position) == 0 then
					vim.notify("received_position is invalid: " .. received_position, vim.log.levels.ERROR)
					return
				end
				local url = task.url
				-- only root domain
				local domain = url:match("^https?://([^/]+)")
				if domain == "open.kattis.com" then
					local id = url:match("/problems/([^/]+)")
					local ret = vim.fs.joinpath(received_position, id, id .. ".cpp")
					return ret
				else
					vim.notify("Unsupported domain", vim.log.levels.WARN)
					return
				end
			end,
			received_problems_prompt_path = true,
			received_contests_directory = "$(CWD)",
			received_contests_problems_path = "$(PROBLEM).$(FEXT)",
			received_contests_prompt_directory = true,
			received_contests_prompt_extension = true,
			open_received_problems = true,
			open_received_contests = true,
			replace_received_testcases = false,
		},
	},
}

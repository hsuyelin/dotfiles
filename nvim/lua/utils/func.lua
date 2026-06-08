local M = {}

function M.map_on_filetype(filetype, maps)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = filetype,
		group = vim.api.nvim_create_augroup("mapping" .. filetype, { clear = true }),
		callback = function()
			local buf = vim.api.nvim_get_current_buf()

			for lhs, detail in pairs(maps) do
				local rhs, desc = detail[1], detail[2]
				require("which-key").add({
					"<localleader>" .. lhs,
					rhs,
					buffer = buf,
					desc = desc,
				})
			end
		end,
	})
end

function M.code()
	vim.lsp.buf.code_action({
		apply = true,
		filter = function(action)
			return action.title == "Fix All"
		end,
	})
end

-- Collect all lines in the current buffer that match a vim-regex pattern,
-- then open them in a new tab as a read-only scratch buffer.
-- Line numbers are shown as a prefix so you can jump back to the source.
function M.grep_lines_to_tab()
    local src_buf  = vim.api.nvim_get_current_buf()
    local src_name = vim.api.nvim_buf_get_name(src_buf)

    local pattern = vim.fn.input("/ ")
    if pattern == "" then return end
    local filetype = vim.bo[src_buf].filetype
    local all_lines = vim.api.nvim_buf_get_lines(src_buf, 0, -1, false)

    local matches = {}
    local lpat = pattern:lower()
    for lnum, line in ipairs(all_lines) do
        if tostring(line):lower():find(lpat, 1, true) then
            table.insert(matches, string.format("%5d │ %s", lnum, line))
        end
    end

    if #matches == 0 then
        vim.notify("No matches: " .. pattern, vim.log.levels.WARN)
        return
    end

    vim.cmd("tabnew")
    local buf   = vim.api.nvim_get_current_buf()
    local title = ("matches [%s] %s"):format(pattern, vim.fn.fnamemodify(src_name, ":t"))
    pcall(vim.api.nvim_buf_set_name, buf, title)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, matches)
    vim.bo[buf].buftype   = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype  = filetype
end

-- Batch replace across the current buffer (normal mode) or visual selection.
-- opts.regex = true  → pattern is a Vim regex
-- opts.regex = false → pattern is treated as a literal string (\V very-nomagic)
function M.replace(opts)
    opts = opts or {}
    local use_regex = opts.regex == true

    -- Capture visual range BEFORE calling input(), which would exit visual mode.
    local range = "%"
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then
        local from = math.min(vim.fn.line("v"), vim.fn.line("."))
        local to   = math.max(vim.fn.line("v"), vim.fn.line("."))
        range = from .. "," .. to
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        vim.api.nvim_feedkeys(esc, "nx", false)
    end

    local label = use_regex and "[regex]" or "[literal]"
    local search = vim.fn.input(label .. " Search: ")
    if search == "" then return end
    local replacement = vim.fn.input(label .. " Replace: ")

    local pattern = use_regex and search
        or ("\\V" .. vim.fn.escape(search, "\\/"))
    -- In literal mode also escape special replacement atoms (&, ~).
    local rep = use_regex
        and vim.fn.escape(replacement, "/\\")
        or  vim.fn.escape(replacement, "/\\&~")

    local ok, err = pcall(vim.cmd, range .. "s/" .. pattern .. "/" .. rep .. "/g")
    if not ok then
        vim.notify("Replace failed: " .. tostring(err), vim.log.levels.ERROR)
    end
end

function M.config_files()
	local ok, telescope = pcall(require, "telescope.builtin")
	if not ok then
		vim.notify("Telescope not found", vim.log.levels.ERROR)
		return
	end
	telescope.find_files({
		prompt_title = "Config Files",
		cwd = "~/.config/nvim/",
	})
end

return M

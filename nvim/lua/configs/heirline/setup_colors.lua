local utils = require("heirline.utils")

local function setup_colors()
    local normal_bg = utils.get_highlight("Normal").bg or "NONE"
    
    return {
        white = utils.get_highlight("Normal").fg,
        black = "NONE",
        bright_bg = utils.get_highlight("Folded").bg or "NONE",
        bright_fg = utils.get_highlight("Folded").fg or utils.get_highlight("Normal").fg,
        red = utils.get_highlight("DiagnosticError").fg,
        green = utils.get_highlight("String").fg,
        cyan = utils.get_highlight("Special").fg,
        orange = utils.get_highlight("Constant").fg,
        purple = utils.get_highlight("Statement").fg,
        directory = utils.get_highlight("Directory").fg,
        file = utils.get_highlight("@Property").fg,
    }
end

-- auto reload new colorscheme
local heirline_group = vim.api.nvim_create_augroup("Heirline", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		utils.on_colorscheme(setup_colors)
	end,
	group = heirline_group,
})

return setup_colors

local function has_provider()
	local has_wayland = (vim.env.WAYLAND_DISPLAY or "") ~= ""
	local has_x11     = (vim.env.DISPLAY or "") ~= ""

	if has_wayland and vim.fn.exepath("wl-copy") ~= "" then return true end
	if has_x11 and (vim.fn.exepath("xclip") ~= "" or vim.fn.exepath("xsel") ~= "") then return true end

	return false
end

if has_provider() then return end

-- No system clipboard provider: fall back to OSC52.
-- OSC52 is a terminal escape sequence supported by most modern terminals
-- (Ghostty, WezTerm, Alacritty, iTerm2, tmux ≥3.2, etc.) and works over SSH.
vim.g.clipboard = {
	name  = "OSC 52",
	copy  = {
		["+"] = require("vim.ui.clipboard.osc52").copy("+"),
		["*"] = require("vim.ui.clipboard.osc52").copy("*"),
	},
	paste = {
		["+"] = require("vim.ui.clipboard.osc52").paste("+"),
		["*"] = require("vim.ui.clipboard.osc52").paste("*"),
	},
}

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		-- vim.schedule defers the notification to after VimEnter completes,
		-- preventing the "Press ENTER to continue" prompt from blocking startup.
		vim.schedule(function()
			vim.notify(
				"[clipboard] No provider found, using OSC52 (terminal clipboard).\n"
					.. "For full clipboard support install one of:\n"
					.. "  X11:    sudo apt install xclip   (or xsel)\n"
					.. "  Wayland: sudo apt install wl-clipboard",
				vim.log.levels.WARN
			)
		end)
	end,
})

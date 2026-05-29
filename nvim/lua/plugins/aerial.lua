local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({ gh('stevearc/aerial.nvim') })

require("aerial").setup({
    backends = { "lsp", "treesitter" },
    layout = {
        max_width        = { 40, 0.2 },
        min_width        = 24,
        default_direction = "prefer_right",
    },
    filter_kind        = false,
    show_guides        = true,
    highlight_on_hover = true,
    close_on_select    = false,
})

local ok, telescope = pcall(require, "telescope")
if ok then
    pcall(telescope.load_extension, "aerial")
end

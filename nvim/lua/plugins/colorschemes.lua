local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('catppuccin/nvim'),
  gh('EdenEast/nightfox.nvim'),
  gh('folke/tokyonight.nvim'),
  gh('olimorris/onedarkpro.nvim'),
})

require("catppuccin").setup({
  flavour = "mocha",
  transparent_background = true,
  integrations = {
    neogit = false,
    hop = true,
    telescope = true,
    neotree = {
      enabled = true,
      show_root = true,
      transparent_panel = false,
    },
  },
})

if vim.o.winborder == "none" then
  require("tokyonight").setup({
    on_highlights = function(hl, c)
      local prompt = "#2d3149"
      hl.FloatBorder = { bg = c.bg_dark, fg = c.bg_dark }
      hl.TelescopeNormal = { bg = c.bg_dark, fg = c.fg_dark }
      hl.TelescopeBorder = { bg = c.bg_dark, fg = c.bg_dark }
      hl.TelescopePromptNormal = { bg = prompt }
      hl.TelescopePromptBorder = { bg = prompt, fg = prompt }
      hl.TelescopePromptTitle = { bg = prompt, fg = prompt }
      hl.TelescopePreviewTitle = { bg = c.bg_dark, fg = c.bg_dark }
      hl.TelescopeResultsTitle = { bg = c.bg_dark, fg = c.bg_dark }
    end,
  })
end

vim.cmd.colorscheme("catppuccin")

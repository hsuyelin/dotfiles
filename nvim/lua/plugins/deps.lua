-- Shared dependencies used by multiple plugins.
-- No setup needed — just ensure they're in rtp before other plugins configure.
local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('nvim-lua/plenary.nvim'),
  gh('nvim-tree/nvim-web-devicons'),
  gh('echasnovski/mini.icons'),
  gh('MunifTanjim/nui.nvim'),
  gh('nvim-neotest/nvim-nio'),
})

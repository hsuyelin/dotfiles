local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('lewis6991/gitsigns.nvim'),
  gh('sindrets/diffview.nvim'),
  gh('TimUntersberger/neogit'),
})

require("gitsigns").setup({
  linehl = false,
  numhl = true,
})

require("neogit").setup({
  integrations = {
    diffview = true,
  },
})

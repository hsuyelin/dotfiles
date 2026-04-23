local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('mfussenegger/nvim-dap'),
  gh('rcarriga/nvim-dap-ui'),
  gh('theHamsta/nvim-dap-virtual-text'),
})

require("nvim-dap-virtual-text").setup({
  virt_text_pos = "eol",
})

require("mason-nvim-dap").setup()

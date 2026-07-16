local gh = function(r) return 'https://github.com/' .. r end

vim.g.tmux_navigator_no_mappings = 1

vim.pack.add({
  gh('christoomey/vim-tmux-navigator'),
})

vim.keymap.set("n", "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>")

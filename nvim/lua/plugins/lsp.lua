local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('onsails/lspkind.nvim'),
  gh('ray-x/lsp_signature.nvim'),
  gh('stevearc/conform.nvim'),
})

-- lsp_signature: defer to first InsertEnter to avoid slowing startup
vim.api.nvim_create_autocmd("InsertEnter", {
  once = true,
  callback = function()
    require("lsp_signature").setup({})
  end,
})

require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "yapf" },
    swift = { "swiftformat_custom" },
  },
  format_on_save = {
    lsp_fallback = true,
    timeout_ms = 500,
  },
  formatters = {
    swiftformat_custom = {
      command = "swiftformat",
      args = {
        "--config",
        vim.fn.expand("$HOME/.config/swiftformat/.swiftformat"),
        "--stdinpath",
        "$FILENAME",
      },
      stdin = true,
    },
  },
})

vim.keymap.set({ "n", "v" }, "<leader>lf", function()
  require("conform").format({ async = false })
end, { noremap = true, desc = "Format Code Block" })

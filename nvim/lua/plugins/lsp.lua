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
        (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/swiftformat/.swiftformat",
        "--stdinpath",
        "$FILENAME",
      },
      stdin = true,
    },
  },
})

vim.api.nvim_create_user_command("LspRestart", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in ipairs(clients) do
    vim.lsp.stop_client(client.id, true)
  end
  vim.defer_fn(function()
    if vim.api.nvim_buf_get_name(0) ~= "" then
      vim.cmd("edit")
    end
  end, 500)
end, { desc = "Restart LSP clients for current buffer" })

vim.keymap.set({ "n", "v" }, "<leader>lf", function()
  require("conform").format({ async = false })
end, { noremap = true, desc = "Format Code Block" })

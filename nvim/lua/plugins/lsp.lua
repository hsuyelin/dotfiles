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
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, client in ipairs(clients) do
    client:stop()
  end
  -- Poll until every client has actually stopped, then re-trigger attachment.
  -- A fixed delay races against slow servers (e.g. sourcekit-lsp on SPM projects).
  local timer = vim.uv.new_timer()
  timer:start(200, 200, vim.schedule_wrap(function()
    for _, client in ipairs(clients) do
      if not client:is_stopped() then return end
    end
    timer:stop()
    timer:close()
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) ~= "" then
      vim.api.nvim_buf_call(bufnr, function() vim.cmd("edit") end)
    end
  end))
end, { desc = "Restart LSP clients for current buffer" })

vim.keymap.set({ "n", "v" }, "<leader>lf", function()
  require("conform").format({ async = false })
end, { noremap = true, desc = "Format Code Block" })

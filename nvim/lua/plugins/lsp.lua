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

vim.api.nvim_create_user_command("LspInfo", function()
  local bufnr    = vim.api.nvim_get_current_buf()
  local bufname  = vim.api.nvim_buf_get_name(bufnr)
  local attached = vim.lsp.get_clients({ bufnr = bufnr })
  local all      = vim.lsp.get_clients()

  -- collect clients not attached to this buffer
  local attached_ids = {}
  for _, c in ipairs(attached) do attached_ids[c.id] = true end
  local others = vim.tbl_filter(function(c)
    return not attached_ids[c.id]
  end, all)

  local lines = {}
  local hl    = {}   -- { line (0-based), col_start, col_end, hl_group }

  local function push(line, group, s, e)
    lines[#lines + 1] = line
    if group then
      hl[#hl + 1] = { #lines - 1, s or 0, e or #line, group }
    end
  end

  local function section(title)
    push("")
    push(" " .. title, "Title", 1, 1 + #title)
  end

  local function client_block(c, prefix)
    local status = c.initialized and "initialized" or "initializing"
    local fts    = table.concat(c.config.filetypes or {}, ", ")
    local dot    = c.initialized and "●" or "○"
    local name_line = string.format("  %s %s  (id: %d)", prefix .. dot, c.name, c.id)
    push(name_line, c.initialized and "Function" or "Comment")
    push(string.format("      root_dir:  %s", c.root_dir or "(none)"), "String")
    push(string.format("      filetypes: %s", fts ~= "" and fts or "(any)"), "Comment")
    push(string.format("      status:    %s", status), "Comment")
  end

  -- header
  push(" LSP Info", "Title", 1, 9)
  push(string.format(" buffer: %s", bufname ~= "" and bufname or "(unnamed)"), "Comment")

  section(string.format("Attached (%d)", #attached))
  if #attached == 0 then
    push("   (none)", "Comment")
  else
    for _, c in ipairs(attached) do client_block(c, "") end
  end

  section(string.format("Running, not attached (%d)", #others))
  if #others == 0 then
    push("   (none)", "Comment")
  else
    for _, c in ipairs(others) do client_block(c, "") end
  end

  push("")

  -- open floating window
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width  = math.min(width + 4, math.floor(vim.o.columns * 0.85))
  local height = math.min(#lines, math.floor(vim.o.lines * 0.7))

  local fbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(fbuf, 0, -1, false, lines)
  vim.bo[fbuf].modifiable = false
  vim.bo[fbuf].bufhidden  = "wipe"

  for _, h in ipairs(hl) do
    vim.api.nvim_buf_add_highlight(fbuf, -1, h[4], h[1], h[2], h[3])
  end

  local win = vim.api.nvim_open_win(fbuf, true, {
    relative = "editor",
    width    = width,
    height   = height,
    row      = math.floor((vim.o.lines - height) / 2),
    col      = math.floor((vim.o.columns - width) / 2),
    style    = "minimal",
    border   = "rounded",
    title    = " LSP Info ",
    title_pos = "center",
  })
  vim.wo[win].wrap      = false
  vim.wo[win].cursorline = true

  -- q / <Esc> to close
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<cr>", { buffer = fbuf, nowait = true })
  end
end, { desc = "Show LSP client info for current buffer" })

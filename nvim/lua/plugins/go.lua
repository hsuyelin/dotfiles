local function go_buffer_path()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or not path:match("%.go$") then
    vim.notify("Current buffer is not a Go file", vim.log.levels.WARN)
    return nil
  end
  return vim.fn.fnamemodify(path, ":p")
end

local function go_alt()
  local path = go_buffer_path()
  if not path then
    return
  end

  local target
  if path:match("_test%.go$") then
    target = path:gsub("_test%.go$", ".go")
  else
    target = path:gsub("%.go$", "_test.go")
  end

  vim.cmd.edit(vim.fn.fnameescape(target))
end

local function setup_term_buf(buf)
  vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = buf, silent = true })
  vim.keymap.set("t", "<C-c>", [[<C-\><C-n><C-w>c]], { buffer = buf, silent = true })
end

local function open_go_terminal(cmd)
  vim.cmd("botright 12split")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "go-term"
  setup_term_buf(buf)
  vim.fn.termopen({ vim.o.shell, "-lc", cmd })
  vim.cmd.startinsert()
end

local function go_test(opts)
  local path = go_buffer_path()
  if not path then
    return
  end

  local dir = vim.fn.fnamemodify(path, ":h")
  local args = opts.args ~= "" and (" " .. opts.args) or ""
  local cmd = ("cd %s && go test ./...%s"):format(vim.fn.shellescape(dir), args)
  open_go_terminal(cmd)
end

local function go_code_action()
  vim.lsp.buf.code_action()
end

vim.api.nvim_create_user_command("GoAlt", go_alt, {})
vim.api.nvim_create_user_command("GoTest", go_test, { nargs = "*" })
vim.api.nvim_create_user_command("GoCodeAction", go_code_action, { range = true })

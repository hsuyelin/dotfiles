local gh = function(r) return 'https://github.com/' .. r end

local function has_env(name)
  local value = vim.env[name]
  return type(value) == "string" and value ~= ""
end

local has_openai_key = has_env("AICOMMITS_NVIM_OPENAI_API_KEY") or has_env("OPENAI_API_KEY")
local has_gemini_key = has_env("AICOMMITS_NVIM_GEMINI_API_KEY") or has_env("GEMINI_API_KEY")
local load_aicommits = has_openai_key or has_gemini_key

local plugins = {
  gh("monkoose/neocodeium"),
}

if load_aicommits then
  table.insert(plugins, gh("404pilo/aicommits.nvim"))
end

vim.pack.add(plugins)

-- neocodeium: defer to after startup
vim.schedule(function()
  local neocodeium = require("neocodeium")
  neocodeium.setup({
    enabled = true,
    silent = true,
    filetypes = {
      help = false,
      gitrebase = false,
      ["."] = false,
      ["cpp"] = false,
    },
  })
  vim.keymap.set("i", "<Tab>", function()
    if neocodeium.visible() then
      neocodeium.accept()
    else
      return "<Tab>"
    end
  end, { expr = true, silent = true })
end)

---@type table<string, terminal.Term>
local ai_terminals = {}
local last_terminal

local function cmd_is_available(cmd)
  if type(cmd) == "table" then
    return vim.fn.executable(cmd[1]) == 1
  end
  return vim.fn.executable(cmd) == 1
end

local function visible_window_for(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

local function terminal_for(name, cmd)
  local term = ai_terminals[name]
  if not term or not vim.api.nvim_buf_is_valid(term.buf) then
    term = utils.term.new(cmd)
    ai_terminals[name] = term
  end
  last_terminal = name
  return term
end

local function open_terminal(name, cmd)
  local term = terminal_for(name, cmd)
  term:open(nil, { auto_enter = true })
  vim.cmd.startinsert()
end

local function toggle_terminal(name, cmd)
  local term = ai_terminals[name]
  if term and vim.api.nvim_buf_is_valid(term.buf) then
    local win = visible_window_for(term.buf)
    if win then
      vim.api.nvim_win_close(win, true)
      return
    end
  end
  open_terminal(name, cmd)
end

local function default_ai_cmd()
  for _, cmd in ipairs({ "codex", "claude", "gemini", "amazon_q" }) do
    if vim.fn.executable(cmd) == 1 then
      return cmd
    end
  end
  return vim.o.shell
end

local function toggle_named_cli(name, cmd)
  if not cmd_is_available(cmd) then
    vim.notify(("Command not found: %s"):format(type(cmd) == "table" and cmd[1] or cmd), vim.log.levels.WARN)
    return
  end
  toggle_terminal(name, cmd)
end

local function focus_last_terminal()
  if last_terminal and ai_terminals[last_terminal] and vim.api.nvim_buf_is_valid(ai_terminals[last_terminal].buf) then
    open_terminal(last_terminal)
    return
  end
  toggle_terminal("ai", default_ai_cmd())
end

vim.keymap.set({ "n", "x", "i", "t" }, "<c-.>", function()
  focus_last_terminal()
end, { desc = "AI Terminal Focus" })
vim.keymap.set({ "n", "v" }, "<leader>aa", function()
  toggle_terminal("ai", default_ai_cmd())
end, { desc = "AI Terminal Toggle" })
vim.keymap.set({ "n", "v" }, "<leader>ac", function()
  toggle_named_cli("claude", "claude")
end, { desc = "Claude Terminal Toggle" })
vim.keymap.set({ "n", "v" }, "<leader>ag", function()
  toggle_named_cli("codex", "codex")
end, { desc = "Codex Terminal Toggle" })
vim.keymap.set({ "n", "v" }, "<leader>ap", function()
  vim.ui.input({ prompt = "AI command: ", default = default_ai_cmd() }, function(input)
    if not input or vim.trim(input) == "" then
      return
    end
    toggle_terminal("prompt:" .. input, input)
  end)
end, { desc = "AI Prompt Terminal" })

if load_aicommits then
  local config = {
    integrations = {
      neogit = {
        enabled = true,
        mappings = {
          enabled = true,
          key = "C",
        },
      },
    },
  }

  if has_openai_key then
    config.active_provider = "openai"
    config.providers = {
      openai = {
        enabled = true,
      },
      ["gemini-api"] = {
        enabled = false,
      },
    }
  else
    config.active_provider = "gemini-api"
    config.providers = {
      openai = {
        enabled = false,
      },
      ["gemini-api"] = {
        enabled = true,
      },
    }
  end

  require("aicommits").setup(config)
end

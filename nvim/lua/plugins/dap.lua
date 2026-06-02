local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('mfussenegger/nvim-dap'),
  gh('rcarriga/nvim-dap-ui'),
  gh('theHamsta/nvim-dap-virtual-text'),
})

local dap = require("dap")
local dapui = require("dapui")

require("nvim-dap-virtual-text").setup({
  virt_text_pos = "eol",
})

dapui.setup()

local is_macos = vim.uv.os_uname().sysname == "Darwin"

local function xcrun_find(tool)
  if not is_macos then return nil end
  local path = vim.fn.system({ "xcrun", "--find", tool })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  path = vim.trim(path)
  return path ~= "" and path or nil
end

local function split_args(input)
  if not input or vim.trim(input) == "" then
    return {}
  end
  return vim.split(vim.trim(input), "%s+", { trimempty = true })
end

local lldb_dap = xcrun_find("lldb-dap")
if lldb_dap then
  dap.adapters["lldb-dap"] = {
    type = "executable",
    command = lldb_dap,
    name = "lldb-dap",
  }
end

dap.configurations.swift = {
  {
    name = "Launch Swift Executable",
    type = "lldb-dap",
    request = "launch",
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    program = function()
      local default = vim.fn.getcwd() .. "/.build/debug/"
      return vim.fn.input("Path to executable: ", default, "file")
    end,
    args = function()
      return split_args(vim.fn.input("Arguments: "))
    end,
  },
  {
    name = "Attach To Process",
    type = "lldb-dap",
    request = "attach",
    cwd = "${workspaceFolder}",
    pid = require("dap.utils").pick_process,
    args = {},
  },
}

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end

dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end

dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

require("mason-nvim-dap").setup({
  automatic_installation = false,
})

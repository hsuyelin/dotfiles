local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('williamboman/mason.nvim'),
  gh('williamboman/mason-lspconfig.nvim'),
  gh('WhoIsSethDaniel/mason-tool-installer.nvim'),
  gh('jay-babu/mason-nvim-dap.nvim'),
})

require("mason").setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
  keymaps = {
    toggle_package_expand = "<TAB>",
  },
})

require("mason-lspconfig").setup({
  automatic_installation = true,
})

local lsp_servers = core.configs.lsp.servers
local ensure_installed = {}
for _, server in ipairs(lsp_servers) do
  if type(server) == "string" then
    table.insert(ensure_installed, server)
  elseif type(server) == "table" and server[1] and (server["mason"] == nil or server["mason"] == true) then
    table.insert(ensure_installed, server[1])
  end
end

-- formatters managed by Mason (cross-platform)
local mason_formatters = {
  "stylua",
  "prettier",
  "yapf",
  "clang-format",
  "goimports",
  "shfmt",
  "taplo",
}
vim.list_extend(ensure_installed, mason_formatters)

require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
-- mason-nvim-dap.setup() is called in plugins/dap.lua after nvim-dap is loaded

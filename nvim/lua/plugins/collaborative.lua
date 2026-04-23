-- NOTE: nomad.nvim downloads prebuilt binaries on first load.
-- If it fails to load, run manually:
--   :lua require("nomad.neovim.build").builders.download_prebuilt():build({})
local gh = function(r) return 'https://github.com/' .. r end

vim.pack.add({
  gh('nomad/nomad'),
})

-- nomad requires prebuilt binaries; wrap in pcall so missing binary doesn't abort startup
local ok = pcall(function() require("nomad").setup({}) end)
if not ok then
  -- Download prebuilt binaries then retry setup
  vim.schedule(function()
    local build_ok, build = pcall(require, "nomad.neovim.build")
    if build_ok then
      pcall(function()
        build.builders.download_prebuilt():build({})
        require("nomad").setup({})
      end)
    end
  end)
else
  -- Already loaded; ensure binaries are present
  vim.schedule(function()
    local build_ok, build = pcall(require, "nomad.neovim.build")
    if build_ok then
      pcall(function() build.builders.download_prebuilt():build({}) end)
    end
  end)
end

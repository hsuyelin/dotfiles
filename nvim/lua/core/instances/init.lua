-- configurations for GUI clients
if vim.g.neovide then
	require("core.instances.neovide")
end

-- Ghostty: GHOSTTY_RESOURCES_DIR is set by Ghostty automatically
if vim.env.GHOSTTY_RESOURCES_DIR then
	require("core.instances.ghostty")
end

-- Linux: clipboard provider detection and OSC52 fallback
if vim.uv.os_uname().sysname == "Linux" then
	require("core.instances.linux")
end

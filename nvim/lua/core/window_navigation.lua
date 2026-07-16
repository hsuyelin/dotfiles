local M = {}

local tmux_commands = {
    left = "Left",
    down = "Down",
    up = "Up",
    right = "Right",
}

local function non_empty(value)
    return value ~= nil and value ~= ""
end

local function focus_herdr(direction)
    local pane_id = vim.env.HERDR_PANE_ID
    if not non_empty(pane_id) then
        return false
    end

    local herdr = vim.env.HERDR_BIN_PATH
    if not non_empty(herdr) then
        herdr = "herdr"
    end

    vim.fn.system({
        herdr,
        "pane",
        "focus",
        "--direction",
        direction,
        "--pane",
        pane_id,
    })
    return true
end

local function focus_tmux(direction)
    if not non_empty(vim.env.TMUX) then
        return false
    end

    local suffix = tmux_commands[direction]
    if not suffix then
        return false
    end

    local ok = pcall(vim.cmd, "TmuxNavigate" .. suffix)
    return ok
end

local function navigate(wincmd, direction)
    local previous = vim.api.nvim_get_current_win()

    vim.cmd("wincmd " .. wincmd)
    if vim.api.nvim_get_current_win() ~= previous then
        return
    end

    if focus_herdr(direction) then
        return
    end

    focus_tmux(direction)
end

function M.left()
    navigate("h", "left")
end

function M.down()
    navigate("j", "down")
end

function M.up()
    navigate("k", "up")
end

function M.right()
    navigate("l", "right")
end

return M

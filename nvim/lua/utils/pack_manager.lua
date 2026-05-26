-- Pack manager: update and clean plugins managed by vim.pack.add.
--
-- Must be required before any vim.pack.add() call so the wrapper can
-- intercept every plugin registration and build the registry used by
-- PackClean to identify orphaned directories.

local M = {}

local _pack_root = vim.fn.stdpath("data") .. "/site/pack/nvim"

-- Registry populated lazily as vim.pack.add() is called.
M._registry = {} -- name → { src, dir }

local function find_dir(name)
    for _, sub in ipairs({ "opt", "start" }) do
        local d = _pack_root .. "/" .. sub .. "/" .. name
        if vim.fn.isdirectory(d) == 1 then return d end
    end
    return _pack_root .. "/opt/" .. name
end

-- Wrap vim.pack.add to intercept registrations.
local _real_add = vim.pack.add
---@diagnostic disable-next-line: duplicate-set-field
vim.pack.add = function(specs, opts)
    local list = (type(specs) == "table" and vim.islist(specs)) and specs or { specs }
    for _, spec in ipairs(list) do
        local src = type(spec) == "string" and spec
            or (type(spec) == "table" and spec.src)
        if src then
            local name = src:match("([^/]+)$")
            if name then
                M._registry[name] = { src = src, dir = find_dir(name) }
            end
        end
    end
    return _real_add(specs, opts)
end

-- ── Shared UI helpers ─────────────────────────────────────────────────────────

local function open_float(title, lines)
    local width  = 62
    local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.75))
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    local win = vim.api.nvim_open_win(buf, true, {
        relative  = "editor",
        width     = width,
        height    = height,
        row       = math.floor((vim.o.lines   - height) / 2),
        col       = math.floor((vim.o.columns - width)  / 2),
        style     = "minimal",
        border    = "rounded",
        title     = " " .. title .. " ",
        title_pos = "center",
    })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    for _, k in ipairs({ "q", "<Esc>" }) do
        vim.keymap.set("n", k, function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
        end, { buffer = buf, nowait = true })
    end
    return buf, win
end

local function set_line(buf, idx, text)
    vim.api.nvim_buf_set_lines(buf, idx, idx + 1, false, { text })
end

-- ── :PackUpdate ───────────────────────────────────────────────────────────────

M.update = function()
    local items = {}
    for _, sub in ipairs({ "opt", "start" }) do
        local path = _pack_root .. "/" .. sub
        if vim.fn.isdirectory(path) == 1 then
            for _, name in ipairs(vim.fn.readdir(path)) do
                local d = path .. "/" .. name
                if vim.fn.isdirectory(d .. "/.git") == 1 then
                    table.insert(items, { name = name, dir = d })
                end
            end
        end
    end

    if #items == 0 then
        vim.notify("PackUpdate: no plugins found", vim.log.levels.WARN)
        return
    end

    -- Build initial buffer lines.
    local init = { string.format("  Updating %d plugin(s) …", #items), "" }
    for _, item in ipairs(items) do
        table.insert(init, string.format("  ○ %s", item.name))
    end
    table.insert(init, "")

    local buf, win = open_float("Pack Update", init)
    local HEADER = 2 -- two lines before the plugin list

    local done, n_ok, n_skip, n_fail = 0, 0, 0, 0

    local function on_all_done()
        local last = vim.api.nvim_buf_line_count(buf) - 1
        set_line(buf, last, string.format(
            "  Done — ✓ %d updated  ↩ %d up-to-date  ✗ %d failed    [q]",
            n_ok, n_skip, n_fail
        ))
    end

    -- Launch all git pulls in parallel; callbacks schedule back to main loop.
    for i, item in ipairs(items) do
        local line_idx = HEADER + (i - 1)
        vim.system(
            { "git", "-C", item.dir, "pull", "--ff-only", "--quiet" },
            {},
            function(out)
                vim.schedule(function()
                    done = done + 1
                    local icon
                    if out.code == 0 then
                        local stdout = (out.stdout or "") .. (out.stderr or "")
                        if stdout:find("up to date") then
                            icon = "↩"; n_skip = n_skip + 1
                        else
                            icon = "✓"; n_ok = n_ok + 1
                        end
                    else
                        icon = "✗"; n_fail = n_fail + 1
                    end
                    set_line(buf, line_idx, string.format(
                        "  %s %-36s [%d/%d]", icon, item.name, done, #items
                    ))
                    if done == #items then on_all_done() end
                end)
            end
        )
    end
end

-- ── :PackClean ────────────────────────────────────────────────────────────────

M.clean = function()
    if next(M._registry) == nil then
        vim.notify("PackClean: registry is empty — was pack_manager loaded first?",
            vim.log.levels.WARN)
        return
    end

    local orphans = {}
    for _, sub in ipairs({ "opt", "start" }) do
        local path = _pack_root .. "/" .. sub
        if vim.fn.isdirectory(path) == 1 then
            for _, name in ipairs(vim.fn.readdir(path)) do
                if not M._registry[name] then
                    table.insert(orphans, { name = name, dir = path .. "/" .. name })
                end
            end
        end
    end

    if #orphans == 0 then
        vim.notify("PackClean: nothing to remove", vim.log.levels.INFO)
        return
    end

    local lines = { string.format("  %d unused plugin(s) found:", #orphans), "" }
    for _, p in ipairs(orphans) do
        table.insert(lines, "    • " .. p.name)
    end
    table.insert(lines, "")
    table.insert(lines, "  [y] delete all   [n / q] cancel")

    local buf, win = open_float("Pack Clean", lines)

    local function close()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end

    vim.keymap.set("n", "y", function()
        close()
        for _, p in ipairs(orphans) do
            vim.fn.delete(p.dir, "rf")
        end
        vim.notify(string.format("PackClean: removed %d plugin(s)", #orphans),
            vim.log.levels.INFO)
    end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "n", close, { buffer = buf, nowait = true })
end

-- ── Commands ──────────────────────────────────────────────────────────────────

vim.api.nvim_create_user_command(
    "PackUpdate", M.update, { desc = "Update all installed plugins (git pull)" }
)
vim.api.nvim_create_user_command(
    "PackClean", M.clean, { desc = "Remove plugin dirs not registered via vim.pack.add" }
)

return M

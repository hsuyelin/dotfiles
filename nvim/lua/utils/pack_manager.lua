-- Pack manager: update and clean plugins managed by vim.pack.add.
--
-- Must be required before any vim.pack.add() call so the wrapper intercepts
-- every registration and builds the registry used by PackClean / PackUpdate.

local M = {}

M._registry = {} -- name → { src, dir, version? }

-- ── Path resolution ───────────────────────────────────────────────────────────

-- Scan all packpath entries for the real install location of a plugin.
-- Covers any package name (not just "nvim") and both opt/ and start/.
local function find_dir(name)
    for _, pp in ipairs(vim.opt.packpath:get()) do
        local pack = pp .. "/pack"
        if vim.fn.isdirectory(pack) == 1 then
            for _, pkg in ipairs(vim.fn.readdir(pack)) do
                for _, sub in ipairs({ "opt", "start" }) do
                    local d = pack .. "/" .. pkg .. "/" .. sub .. "/" .. name
                    if vim.fn.isdirectory(d) == 1 then return d end
                end
            end
        end
    end
    -- Fallback for plugins not yet installed.
    return vim.fn.stdpath("data") .. "/site/pack/nvim/opt/" .. name
end

-- ── vim.pack.add wrapper ──────────────────────────────────────────────────────

local _real_add = vim.pack.add
---@diagnostic disable-next-line: duplicate-set-field
vim.pack.add = function(specs, opts)
    -- Install first so find_dir() locates the real directory afterwards.
    local result = _real_add(specs, opts)
    local list = (type(specs) == "table" and vim.islist(specs)) and specs or { specs }
    for _, spec in ipairs(list) do
        local src     = type(spec) == "string" and spec or (type(spec) == "table" and spec.src)
        local version = type(spec) == "table"  and spec.version or nil
        if src then
            local name = src:match("([^/]+)$")
            if name then
                M._registry[name] = { src = src, dir = find_dir(name), version = version }
            end
        end
    end
    return result
end

-- ── UI helpers ────────────────────────────────────────────────────────────────

local function open_float(title, lines)
    local width  = 64
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

-- ── Update strategies ─────────────────────────────────────────────────────────

-- For plugins with a version range: fetch tags, find highest satisfying tag,
-- checkout if needed. Calls cb(icon, detail_string) when done.
local function update_versioned(item, cb)
    vim.system({ "git", "-C", item.dir, "fetch", "--tags", "--quiet" }, {}, function(fetch)
        if fetch.code ~= 0 then
            cb("✗", "fetch failed")
            return
        end
        vim.system(
            { "git", "-C", item.dir, "tag", "--list", "--sort=-v:refname" },
            { text = true },
            function(tag_out)
                local tags = vim.split(tag_out.stdout or "", "\n", { trimempty = true })
                local best
                for _, tag in ipairs(tags) do
                    local v = vim.version.parse(tag)
                    if v and item.version:has(v) then
                        best = tag
                        break -- sorted newest-first, first match wins
                    end
                end
                if not best then
                    cb("✗", "no tag satisfies constraint")
                    return
                end
                vim.system(
                    { "git", "-C", item.dir, "describe", "--tags", "--exact-match", "HEAD" },
                    { text = true },
                    function(head)
                        local current = head.code == 0
                            and head.stdout:gsub("%s+$", "") or nil
                        if current == best then
                            cb("↩", best)
                            return
                        end
                        vim.system(
                            { "git", "-C", item.dir, "checkout", best, "--quiet" },
                            {},
                            function(co)
                                cb(co.code == 0 and "✓" or "✗",
                                   co.code == 0 and best or "checkout failed")
                            end
                        )
                    end
                )
            end
        )
    end)
end

-- For plugins tracking HEAD: plain fast-forward pull.
local function update_unversioned(item, cb)
    vim.system(
        { "git", "-C", item.dir, "pull", "--ff-only", "--quiet" },
        {},
        function(out)
            if out.code ~= 0 then
                cb("✗", nil)
            elseif ((out.stdout or "") .. (out.stderr or "")):find("up to date") then
                cb("↩", nil)
            else
                cb("✓", nil)
            end
        end
    )
end

-- ── :PackUpdate ───────────────────────────────────────────────────────────────

M.update = function()
    local items = {}
    for name, info in pairs(M._registry) do
        if vim.fn.isdirectory(info.dir .. "/.git") == 1 then
            table.insert(items, {
                name    = name,
                dir     = info.dir,
                version = info.version,
            })
        end
    end
    table.sort(items, function(a, b) return a.name < b.name end)

    if #items == 0 then
        vim.notify("PackUpdate: no plugins found", vim.log.levels.WARN)
        return
    end

    local init = { string.format("  Updating %d plugin(s) …", #items), "" }
    for _, item in ipairs(items) do
        local tag = item.version and " [pinned]" or ""
        table.insert(init, string.format("  ○ %s%s", item.name, tag))
    end
    table.insert(init, "")

    local buf, win = open_float("Pack Update", init)
    local HEADER = 2

    local done, n_ok, n_skip, n_fail = 0, 0, 0, 0

    local function on_all_done()
        local last = vim.api.nvim_buf_line_count(buf) - 1
        set_line(buf, last, string.format(
            "  Done — ✓ %d  ↩ %d  ✗ %d    [q] close",
            n_ok, n_skip, n_fail
        ))
    end

    for i, item in ipairs(items) do
        local strategy = item.version and update_versioned or update_unversioned
        strategy(item, function(icon, detail)
            vim.schedule(function()
                done = done + 1
                if icon == "✓" then n_ok   = n_ok   + 1
                elseif icon == "↩" then n_skip = n_skip + 1
                else n_fail = n_fail + 1 end
                local suffix = detail and ("  " .. detail) or ""
                set_line(buf, HEADER + i - 1, string.format(
                    "  %s %-34s%s  [%d/%d]",
                    icon, item.name, suffix, done, #items
                ))
                if done == #items then on_all_done() end
            end)
        end)
    end
end

-- ── :PackClean ────────────────────────────────────────────────────────────────

M.clean = function()
    if next(M._registry) == nil then
        vim.notify("PackClean: registry empty — was pack_manager loaded first?",
            vim.log.levels.WARN)
        return
    end

    -- Derive the parent directories from the registry instead of hardcoding.
    local parent_dirs = {}
    for _, info in pairs(M._registry) do
        parent_dirs[vim.fn.fnamemodify(info.dir, ":h")] = true
    end

    local orphans = {}
    for parent in pairs(parent_dirs) do
        if vim.fn.isdirectory(parent) == 1 then
            for _, name in ipairs(vim.fn.readdir(parent)) do
                if not M._registry[name] then
                    table.insert(orphans, { name = name, dir = parent .. "/" .. name })
                end
            end
        end
    end
    table.sort(orphans, function(a, b) return a.name < b.name end)

    if #orphans == 0 then
        vim.notify("PackClean: nothing to remove", vim.log.levels.INFO)
        return
    end

    local lines = { string.format("  %d unused plugin(s):", #orphans), "" }
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
    "PackUpdate", M.update,
    { desc = "Update all plugins (respects version constraints)" }
)
vim.api.nvim_create_user_command(
    "PackClean", M.clean,
    { desc = "Remove plugin dirs not registered via vim.pack.add" }
)

return M

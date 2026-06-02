-- Pack manager: update and clean plugins managed by vim.pack.add.
--
-- Must be required before any vim.pack.add() call so the wrapper intercepts
-- every registration and builds the registry used by PackClean / PackUpdate.

-- vim.pack requires Neovim >= 0.11. On older versions stub it out so that
-- plugin files calling vim.pack.add() do not crash — plugins simply won't load.
if not vim.pack then
    vim.notify(
        "pack_manager: vim.pack not found — Neovim ≥ 0.11 required, plugins disabled",
        vim.log.levels.WARN
    )
    vim.pack = { add = function() end, del = function() end }
    local noop = function()
        vim.notify("Requires Neovim ≥ 0.11", vim.log.levels.WARN)
    end
    return {
        _registry    = {},
        update       = noop,
        clean        = noop,
        check_update = noop,
        check_health = noop,
    }
end

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
    local list = (type(specs) == "table" and vim.islist(specs)) and specs or { specs }

    -- Partition into enabled / disabled.
    -- A spec is disabled only when it is a table with enabled == false.
    local enabled = {}
    for _, spec in ipairs(list) do
        if not (type(spec) == "table" and spec.enabled == false) then
            table.insert(enabled, spec)
        end
    end

    -- Always pass a list to _real_add: Neovim 0.12+ requires list format.
    local result
    if #enabled > 0 then
        result = _real_add(enabled, opts)
    end

    -- Register only enabled plugins so PackClean treats disabled ones as orphans.
    for _, spec in ipairs(enabled) do
        local src     = type(spec) == "string" and spec or (type(spec) == "table" and spec.src)
        local version = type(spec) == "table"  and spec.version or nil
        if src then
            local name = src:match("([^/]+)$")
            if name then
                -- version may already be a parsed range object (e.g. vim.version.range(...))
                -- or a raw string; normalise to a range object in either case.
                local version_range
                if version ~= nil then
                    version_range = (type(version) == "table" and type(version.has) == "function")
                        and version
                        or vim.version.range(tostring(version))
                end
                M._registry[name] = { src = src, dir = find_dir(name), version = version_range }
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
    local bg_mode      = false
    local spinner_timer -- assigned below; declared here so go_background can close over it

    local function go_background()
        if not vim.api.nvim_win_is_valid(win) then return end
        bg_mode = true
        if spinner_timer then spinner_timer:stop() end
        vim.api.nvim_win_close(win, true)
        vim.notify("PackUpdate: running in background…", vim.log.levels.INFO)
    end
    -- Override the default q / <Esc> close set by open_float.
    vim.keymap.set("n", "q",     go_background, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<Esc>", go_background, { buffer = buf, nowait = true })

    local function on_all_done()
        if spinner_timer then
            spinner_timer:stop()
            spinner_timer:close()
        end
        if not bg_mode and vim.api.nvim_buf_is_valid(buf) then
            local last = vim.api.nvim_buf_line_count(buf) - 1
            set_line(buf, last, string.format(
                "  Done — ✓ %d  ↩ %d  ✗ %d    [q] close",
                n_ok, n_skip, n_fail
            ))
        end
        vim.notify(
            string.format("PackUpdate: done — ✓ %d updated  ↩ %d skipped  ✗ %d failed",
                n_ok, n_skip, n_fail),
            n_fail > 0 and vim.log.levels.WARN or vim.log.levels.INFO
        )
    end

    local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    local spinner_frame  = 0
    local in_progress    = {} -- index → true while git op is running

    local uv = vim.uv or vim.loop
    spinner_timer = uv.new_timer()
    spinner_timer:start(0, 80, vim.schedule_wrap(function()
        if bg_mode then return end
        spinner_frame = (spinner_frame % #spinner_frames) + 1
        local fr = spinner_frames[spinner_frame]
        for idx in pairs(in_progress) do
            local it  = items[idx]
            local tag = it.version and " [pinned]" or ""
            set_line(buf, HEADER + idx - 1,
                string.format("  %s %s%s", fr, it.name, tag))
        end
    end))

    for i, item in ipairs(items) do
        in_progress[i] = true
        local strategy = item.version and update_versioned or update_unversioned
        strategy(item, function(icon, detail)
            vim.schedule(function()
                in_progress[i] = nil
                done = done + 1
                if icon == "✓" then n_ok   = n_ok   + 1
                elseif icon == "↩" then n_skip = n_skip + 1
                else n_fail = n_fail + 1 end
                if not bg_mode and vim.api.nvim_buf_is_valid(buf) then
                    local suffix = detail and ("  " .. detail) or ""
                    set_line(buf, HEADER + i - 1, string.format(
                        "  %s %-34s%s  [%d/%d]",
                        icon, item.name, suffix, done, #items
                    ))
                end
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
        local names = vim.tbl_map(function(p) return p.name end, orphans)
        -- vim.pack.del removes the directory AND clears the lockfile entry,
        -- preventing Neovim from prompting to reinstall on next startup.
        pcall(vim.pack.del, names)
        -- Fallback: delete any directories not tracked by vim.pack (e.g. manually cloned).
        for _, p in ipairs(orphans) do
            if vim.fn.isdirectory(p.dir) == 1 then
                vim.fn.delete(p.dir, "rf")
            end
        end
        vim.notify(string.format("PackClean: removed %d plugin(s)", #orphans),
            vim.log.levels.INFO)
    end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "n", close, { buffer = buf, nowait = true })
end

-- ── Check-update strategies ───────────────────────────────────────────────────

-- Fetch remote refs then count commits the local branch is behind upstream.
-- Falls back to origin/HEAD if no upstream tracking branch is configured.
-- Calls cb("↑", n_commits) when behind, cb(nil) when up-to-date, cb("✗") on error.
local function check_update_unversioned(item, cb)
    vim.system({ "git", "-C", item.dir, "fetch", "--quiet" }, {}, function(fetch)
        if fetch.code ~= 0 then
            cb("✗")
            return
        end
        vim.system(
            { "git", "-C", item.dir, "rev-list", "--count", "HEAD..@{upstream}" },
            { text = true },
            function(up)
                local ref = up.code == 0 and "@{upstream}" or "origin/HEAD"
                vim.system(
                    { "git", "-C", item.dir, "rev-list", "--count", "HEAD.." .. ref },
                    { text = true },
                    function(out)
                        local n = tonumber((out.stdout or ""):match("%d+")) or 0
                        cb(n > 0 and "↑" or nil, n > 0 and n or nil)
                    end
                )
            end
        )
    end)
end

-- Fetch tags then check if a newer tag satisfies the version constraint.
-- Calls cb("↑", new_tag) when a better tag exists, cb(nil) when current, cb("✗") on error.
local function check_update_versioned(item, cb)
    vim.system({ "git", "-C", item.dir, "fetch", "--tags", "--quiet" }, {}, function(fetch)
        if fetch.code ~= 0 then
            cb("✗")
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
                        break
                    end
                end
                if not best then
                    cb(nil)
                    return
                end
                vim.system(
                    { "git", "-C", item.dir, "describe", "--tags", "--exact-match", "HEAD" },
                    { text = true },
                    function(head)
                        local current = head.code == 0 and head.stdout:gsub("%s+$", "") or nil
                        cb(current ~= best and "↑" or nil, current ~= best and best or nil)
                    end
                )
            end
        )
    end)
end

-- ── :PackCheckUpdate ──────────────────────────────────────────────────────────

M.check_update = function()
    local items = {}
    for name, info in pairs(M._registry) do
        if vim.fn.isdirectory(info.dir .. "/.git") == 1 then
            table.insert(items, { name = name, dir = info.dir, version = info.version })
        end
    end
    table.sort(items, function(a, b) return a.name < b.name end)

    if #items == 0 then
        vim.notify("PackCheckUpdate: no plugins found", vim.log.levels.WARN)
        return
    end

    local buf, win = open_float("Pack Check Update", {
        string.format("  Checking %d plugin(s) for updates…  [0/%d]", #items, #items),
        "",
        "  (no updates found yet)",
        "",
    })

    local done = 0
    local updates = {} -- { name, detail }

    local function redraw()
        local lines = {
            string.format(
                "  Checking %d plugin(s) for updates…  [%d/%d]", #items, done, #items
            ),
            "",
        }
        if #updates == 0 then
            table.insert(lines, "  (no updates found yet)")
        else
            for _, u in ipairs(updates) do
                local suffix = u.detail and ("  →  " .. tostring(u.detail)) or ""
                table.insert(lines, string.format("  ↑ %s%s", u.name, suffix))
            end
        end
        table.insert(lines, "")
        if done == #items then
            if #updates == 0 then
                table.insert(lines, "  All plugins are up to date.")
            else
                table.insert(lines, string.format(
                    "  %d plugin(s) available. Run :PackUpdate to apply.", #updates
                ))
            end
            table.insert(lines, "  [q] close")
        end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        -- Resize window height to fit content.
        local h = math.min(#lines + 2, math.floor(vim.o.lines * 0.75))
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_set_height(win, h)
        end
    end

    for _, item in ipairs(items) do
        local strategy = item.version and check_update_versioned or check_update_unversioned
        strategy(item, function(icon, detail)
            vim.schedule(function()
                done = done + 1
                if icon == "↑" then
                    local label = type(detail) == "number"
                        and (detail .. " commit(s) behind")
                        or detail
                    table.insert(updates, { name = item.name, detail = label })
                elseif icon == "✗" then
                    table.insert(updates, { name = item.name, detail = "check failed" })
                end
                redraw()
            end)
        end)
    end
end

-- ── :PackCheckHealth ──────────────────────────────────────────────────────────

-- Derive candidate health-module names from a plugin directory name.
-- Most plugins follow: strip .nvim suffix, replace - with _, optionally strip nvim- prefix.
local function health_candidates(name)
    local base = name:gsub("%.nvim$", ""):gsub("^nvim%-", ""):gsub("%-", "_")
    local full = name:gsub("%-", "_"):gsub("%.", "_")
    local seen, out = {}, {}
    for _, c in ipairs({ base, full }) do
        if not seen[c] then seen[c] = true; table.insert(out, c) end
    end
    return out
end

M.check_health = function()
    -- Intercept vim.health to capture only warnings and errors.
    local captured = {} -- plugin_name → { errors = [], warns = [] }
    local current  = nil

    local orig = {
        ok    = vim.health.ok,
        info  = vim.health.info,
        start = vim.health.start,
        warn  = vim.health.warn,
        error = vim.health.error,
    }

    vim.health.ok    = function(_) end
    vim.health.info  = function(_) end
    vim.health.start = function(_) end
    vim.health.warn  = function(msg)
        if not current then return end
        captured[current] = captured[current] or { errors = {}, warns = {} }
        table.insert(captured[current].warns, msg)
    end
    vim.health.error = function(msg)
        if not current then return end
        captured[current] = captured[current] or { errors = {}, warns = {} }
        table.insert(captured[current].errors, msg)
    end

    local n_checked = 0
    for name, info in pairs(M._registry) do
        for _, mod in ipairs(health_candidates(name)) do
            -- Only attempt if the health file actually exists in the plugin dir.
            local found = vim.fn.filereadable(
                info.dir .. "/lua/" .. mod .. "/health.lua"
            ) == 1 or vim.fn.filereadable(
                info.dir .. "/lua/" .. mod .. "/health/init.lua"
            ) == 1
            if found then
                current = name
                local ok, health = pcall(require, mod .. ".health")
                if ok and type(health) == "table" and type(health.check) == "function" then
                    pcall(health.check)
                    n_checked = n_checked + 1
                end
                current = nil
                break
            end
        end
    end

    -- Restore vim.health.
    for fn, fn_orig in pairs(orig) do vim.health[fn] = fn_orig end

    -- Build display — only plugins with issues.
    local issues = {}
    for name, data in pairs(captured) do
        if #data.errors > 0 or #data.warns > 0 then
            table.insert(issues, { name = name, errors = data.errors, warns = data.warns })
        end
    end
    table.sort(issues, function(a, b) return a.name < b.name end)

    if #issues == 0 then
        vim.notify(
            string.format("PackCheckHealth: %d plugin(s) checked — no issues", n_checked),
            vim.log.levels.INFO
        )
        return
    end

    local lines = {
        string.format("  Checked %d plugin(s) — %d have issues:", n_checked, #issues),
        "",
    }
    for _, item in ipairs(issues) do
        local icon = #item.errors > 0 and "✗" or "⚠"
        table.insert(lines, string.format("  %s %s", icon, item.name))
        for _, e in ipairs(item.errors) do
            table.insert(lines, "      error  " .. e)
        end
        for _, w in ipairs(item.warns) do
            table.insert(lines, "      warn   " .. w)
        end
    end
    table.insert(lines, "")
    table.insert(lines, "  Run :checkhealth <plugin> for full details.  [q] close")

    open_float("Pack Check Health", lines)
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
vim.api.nvim_create_user_command(
    "PackCheckUpdate", M.check_update,
    { desc = "Check which plugins have updates available (no download)" }
)
vim.api.nvim_create_user_command(
    "PackCheckHealth", M.check_health,
    { desc = "Run health checks and show only plugins with warnings or errors" }
)

return M

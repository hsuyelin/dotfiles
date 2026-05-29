local M = {}

-- ── node-type sets ────────────────────────────────────────────────────────

local _container_types = {
    class_declaration     = true,  -- Swift class / struct / actor
    extension_declaration = true,  -- Swift extension
    struct_declaration    = true,
    enum_declaration      = true,
    protocol_declaration  = true,
}

local _fn_types = {
    function_declaration      = true,
    function_definition       = true,
    method_declaration        = true,
    method_definition         = true,
    func_literal              = true,
    local_function            = true,
    function_item             = true,
    async_function_definition = true,
    init_declaration          = true,
    deinit_declaration        = true,
    subscript_declaration     = true,
    computed_property         = true,
}

-- Direct body children of a FUNCTION node (holds its statements)
local _fn_body_types = {
    function_body      = true,  -- tree-sitter-swift
    block              = true,  -- tree-sitter-go / rust / python
    statement_block    = true,  -- tree-sitter-javascript / typescript
    compound_statement = true,  -- tree-sitter-c / cpp
}

-- Direct body children of a CONTAINER node (holds its member declarations)
local _container_body_types = {
    class_body    = true,  -- Swift class / struct / extension
    enum_body     = true,  -- Swift enum
    protocol_body = true,  -- Swift protocol
}

-- ── helpers ───────────────────────────────────────────────────────────────

local function get_tree()
    local ok, parser = pcall(vim.treesitter.get_parser, 0)
    if not ok or not parser then return nil end
    local trees = parser:parse()
    return trees and trees[1] or nil
end

local function cursor_node()
    local tree = get_tree()
    if not tree then return nil end
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    return tree:root():named_descendant_for_range(row - 1, col, row - 1, col)
end

local function first_child_of(node, types)
    for child in node:iter_children() do
        if types[child:type()] then return child end
    end
    return nil
end

local function nearest(node, types)
    local n = node
    while n do
        if types[n:type()] then return n end
        n = n:parent()
    end
    return nil
end

-- Foldlevel at the midpoint of a node.
-- Using the midpoint (not start/end) avoids ambiguity at boundary lines where
-- multiple folds can start simultaneously (e.g. Go's `func Foo() {`).
local function mid_foldlevel(node)
    local sr = node:start()
    local er = node:end_()
    if er <= sr then return 0 end
    return vim.fn.foldlevel(math.floor((sr + er) / 2) + 1)
end

-- True when the fold that starts at `row` (0-indexed) is currently closed.
local function fold_closed_at(row)
    return vim.fn.foldclosed(row + 1) ~= -1
end

-- Container body: the node that holds member declarations (class_body, etc.)
-- Falls back to fn_body_types for languages that reuse the same node name.
local function container_body(node)
    return first_child_of(node, _container_body_types)
        or first_child_of(node, _fn_body_types)
end

-- ── container fold logic ──────────────────────────────────────────────────

-- Return the foldlevel that shows member signatures but folds their bodies.
-- Looks at the first member that has a body and reads its mid foldlevel.
local function target_level_for(container)
    local cbody = container_body(container)
    if not cbody then return nil end
    for child in cbody:iter_children() do
        local fbody = first_child_of(child, _fn_body_types)
        if fbody then
            local level = mid_foldlevel(fbody)
            if level > 0 then return level - 1 end
        end
    end
    return nil
end

-- True when ALL member function bodies inside a container are currently folded.
local function all_members_folded(container)
    local cbody = container_body(container)
    if not cbody then return false end
    local found = false
    for child in cbody:iter_children() do
        local fbody = first_child_of(child, _fn_body_types)
        if fbody then
            found = true
            if not fold_closed_at(fbody:start()) then return false end
        end
    end
    return found
end

-- ── public API ────────────────────────────────────────────────────────────

--- Smart <Tab>:
---   cursor on container first line  → toggle all member body folds
---   cursor on function first line   → toggle that function's body fold
---   otherwise                       → plain za
function M.smart_tab()
    local node = cursor_node()
    if not node then
        pcall(vim.cmd, "normal! za")
        return
    end

    local row = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed

    -- Case 1: cursor on the opening line of a class / extension / struct
    local container = nearest(node, _container_types)
    if container and container:start() == row then
        if all_members_folded(container) then
            vim.cmd("normal! zR")
        else
            local level = target_level_for(container)
            if level then
                vim.wo.foldlevel = level
            else
                vim.cmd("normal! zM")
            end
        end
        return
    end

    -- Case 2: cursor on the opening line of a function / method
    local fn = nearest(node, _fn_types)
    if fn and fn:start() == row then
        local fbody = first_child_of(fn, _fn_body_types)
        if fbody then
            local saved = vim.api.nvim_win_get_cursor(0)
            vim.api.nvim_win_set_cursor(0, { fbody:start() + 1, 0 })
            pcall(vim.cmd, "normal! za")
            vim.api.nvim_win_set_cursor(0, saved)
            return
        end
    end

    -- Default
    pcall(vim.cmd, "normal! za")
end

--- Fold all function bodies in the buffer, showing signatures.
--- Computes the required foldlevel from the treesitter tree so it works
--- regardless of nesting depth (top-level Go funcs vs Swift extension methods).
function M.fold_functions()
    local tree = get_tree()
    if not tree then
        vim.wo.foldlevel = 1
        return
    end

    local min_level = nil

    local function scan(node)
        if _fn_types[node:type()] then
            local fbody = first_child_of(node, _fn_body_types)
            if fbody then
                local level = mid_foldlevel(fbody)
                if level > 0 and (min_level == nil or level < min_level) then
                    min_level = level
                end
            end
            return  -- don't recurse: nested functions stay inside the fold
        end
        for child in node:iter_children() do scan(child) end
    end

    scan(tree:root())
    vim.wo.foldlevel = min_level and (min_level - 1) or 1
end

--- Toggle between full-collapse (zM) and full-expand (zR).
function M.toggle_all()
    if vim.wo.foldlevel == 0 then
        vim.cmd("normal! zR")
    else
        vim.cmd("normal! zM")
    end
end

return M

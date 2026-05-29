local M = {}

-- Treesitter node types that represent a complete function or method.
-- Only these are folded by fold_functions(); everything else stays open.
local _fn_types = {
    function_declaration      = true,  -- Swift, Go, TS, Lua
    function_definition       = true,  -- Python, C/C++, Lua
    method_declaration        = true,  -- Swift, Java, C#
    method_definition         = true,  -- TS/JS
    func_literal              = true,  -- Go anonymous func
    local_function            = true,  -- Lua
    function_item             = true,  -- Rust
    async_function_definition = true,  -- Python async def
    init_declaration          = true,  -- Swift init
    deinit_declaration        = true,  -- Swift deinit
    subscript_declaration     = true,  -- Swift subscript
}

-- Named body node types: these are the direct children of a function node
-- that represent the { ... } block.  In tree-sitter grammars the `{` token
-- is usually INSIDE the body node, not a direct child of the function node.
local _body_types = {
    function_body      = true,  -- tree-sitter-swift
    block              = true,  -- tree-sitter-go, tree-sitter-rust, tree-sitter-python
    statement_block    = true,  -- tree-sitter-javascript / typescript
    compound_statement = true,  -- tree-sitter-c / cpp
}

-- Return the 0-indexed row where the function body opens (the `{` line).
-- Treesitter folds are created at the START of a named body node, so we
-- must use the body child's row, not the function node's row.
local function block_open_row(node)
    -- First pass: prefer a named body node (body starts at its own `{`)
    for child in node:iter_children() do
        if _body_types[child:type()] then
            return child:start()
        end
    end
    -- Second pass: literal `{` as a direct child (rare, some grammars)
    for child in node:iter_children() do
        if child:type() == "{" then
            return child:start()
        end
    end
    -- Fallback: fold at the function keyword line (Python-style, no braces)
    return node:start()
end

--- Fold only function/method bodies in the current buffer.
--- Uses treesitter to identify function nodes; falls back to zM when
--- treesitter is unavailable for the current filetype.
function M.fold_functions()
    local ok, parser = pcall(vim.treesitter.get_parser, 0)
    if not ok or not parser then
        vim.cmd("normal! zM")
        return
    end

    -- Start from a clean state: everything open.
    vim.cmd("normal! zR")

    local trees = parser:parse()
    if not trees or not trees[1] then return end

    local saved = vim.api.nvim_win_get_cursor(0)

    local function visit(node)
        if _fn_types[node:type()] then
            local sr = block_open_row(node)
            local er = node:end_()
            if er > sr then
                vim.api.nvim_win_set_cursor(0, { sr + 1, 0 })
                pcall(vim.cmd, "normal! zc")
            end
            return  -- don't recurse: nested closures stay inside the fold
        end
        for child in node:iter_children() do
            visit(child)
        end
    end

    visit(trees[1]:root())
    vim.api.nvim_win_set_cursor(0, saved)
end

return M

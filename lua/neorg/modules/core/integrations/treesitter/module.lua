--[[
    File: Treesitter-Integration
    Title: TreeSitter integration in Neorg
	Summary: A module designed to integrate TreeSitter into Neorg.
    ---
--]]

require("neorg.modules.base")

local module = neorg.modules.create("core.integrations.treesitter")

module.private = {
    ts_utils = nil,
}

module.setup = function()
    return { success = true, requires = { "core.highlights", "core.mode", "core.keybinds", "core.neorgcmd" } }
end

module.load = function()
    local success, ts_utils = pcall(require, "nvim-treesitter.ts_utils")

    assert(success, "Unable to load nvim-treesitter.ts_utils :(")

    if module.config.public.configure_parsers then
        -- luacheck: push ignore

        local parser_configs = require("nvim-treesitter.parsers").get_parser_configs()

        parser_configs.norg = {
            install_info = module.config.public.parser_configs.norg,
        }

        parser_configs.norg_meta = {
            install_info = module.config.public.parser_configs.norg_meta,
        }

        module.required["core.neorgcmd"].add_commands_from_table({
            definitions = {
                ["sync-parsers"] = {},
            },
            data = {
                ["sync-parsers"] = {
                    args = 0,
                    name = "sync-parsers",
                },
            },
        })

        -- luacheck: pop

        if not neorg.lib.inline_pcall(vim.treesitter.parse_query, "norg", [[]]) then
            if module.config.public.install_parsers then
                pcall(vim.cmd, "TSInstallSync! norg")
                pcall(vim.cmd, "TSInstallSync! norg_meta")
            else
                assert(false, "Neorg's parser is not installed! Run `:Neorg sync-parsers` to install it.")
            end
        end
    end

    module.private.ts_utils = ts_utils

    module.required["core.mode"].add_mode("traverse-heading")
    module.required["core.keybinds"].register_keybinds(module.name, { "next.heading", "previous.heading" })
end

module.config.public = {
    configure_parsers = true,
    install_parsers = true,
    parser_configs = {
        norg = {
            url = "https://github.com/nvim-neorg/tree-sitter-norg",
            files = { "src/parser.c", "src/scanner.cc" },
            branch = "main",
        },
        norg_meta = {
            url = "https://github.com/nvim-neorg/tree-sitter-norg-meta",
            files = { "src/parser.c" },
            branch = "main",
        },
    },
}

---@class core.integrations.treesitter
module.public = {
    get_ts_utils = function()
        return module.private.ts_utils
    end,

    goto_next_heading = function()
        local line_number = vim.api.nvim_win_get_cursor(0)[1]

        local lines = vim.api.nvim_buf_get_lines(0, line_number, -1, true)

        for relative_line_number, line in ipairs(lines) do
            local match = line:match("^%s*%*+%s+")

            if match then
                vim.api.nvim_win_set_cursor(0, { line_number + relative_line_number, match:len() })
                break
            end
        end
    end,

    goto_previous_heading = function()
        local line_number = vim.api.nvim_win_get_cursor(0)[1]

        local lines = vim.fn.reverse(vim.api.nvim_buf_get_lines(0, 0, line_number - 1, true))

        for relative_line_number, line in ipairs(lines) do
            local match = line:match("^%s*%*+%s+")

            if match then
                vim.api.nvim_win_set_cursor(0, { line_number - relative_line_number, match:len() })
                break
            end
        end
    end,

    ---  Gets all nodes of a given type from the AST
    --- @param  type string #the type of node to filter out
    --- @param opts? table
    get_all_nodes = function(type, opts)
        local result = {}
        opts = opts or {}

        if not opts.buf then
            opts.buf = 0
        end

        if not opts.ft then
            opts.ft = "norg"
        end

        -- Do we need to go through each tree? lol
        vim.treesitter.get_parser(opts.buf, opts.ft):for_each_tree(function(tree)
            -- Get the root for that tree
            local root = tree:root()

            -- @Summary Function to recursively descend down the syntax tree
            -- @Description Recursively searches for a node of a given type
            -- @Param  node (userdata/treesitter node) - the starting point for the search
            local function descend(node)
                -- Iterate over all children of the node and try to match their type
                for child, _ in node:iter_children() do
                    if child:type() == type then
                        table.insert(result, child)
                    else
                        -- If no match is found try descending further down the syntax tree
                        for _, child_node in ipairs(descend(child) or {}) do
                            table.insert(result, child_node)
                        end
                    end
                end
            end

            descend(root)
        end)

        return result
    end,

    -- @Summary Returns the first occurence of a node in the AST
    -- @Description Returns the first node of given type if present
    -- @Param  type (string) - the type of node to search for
    get_first_node = function(type, buf, parent)
        if not buf then
            buf = 0
        end

        local function iterate(parent_node)
            for child, _ in parent_node:iter_children() do
                if child:type() == type then
                    return child
                end
            end
        end

        if parent then
            return iterate(parent)
        end

        vim.treesitter.get_parser(buf, "norg"):for_each_tree(function(tree)
            -- Iterate over all top-level children and attempt to find a match
            return iterate(tree:root())
        end)
    end,

    get_first_node_recursive = function(type, opts)
        opts = opts or {}
        local result

        if not opts.buf then
            opts.buf = 0
        end

        if not opts.ft then
            opts.ft = "norg"
        end

        -- Do we need to go through each tree? lol
        vim.treesitter.get_parser(opts.buf, opts.ft):for_each_tree(function(tree)
            -- Get the root for that tree
            local root
            if opts.parent then
                root = opts.parent
            else
                root = tree:root()
            end

            -- @Summary Function to recursively descend down the syntax tree
            -- @Description Recursively searches for a node of a given type
            -- @Param  node (userdata/treesitter node) - the starting point for the search
            local function descend(node)
                -- Iterate over all children of the node and try to match their type
                for child, _ in node:iter_children() do
                    if child:type() == type then
                        return child
                    else
                        -- If no match is found try descending further down the syntax tree
                        local descent = descend(child)
                        if descent then
                            return descent
                        end
                    end
                end

                return nil
            end

            result = result or descend(root)
        end)

        return result
    end,

    -- @Summary Invokes a callback for every element of the current tree
    -- @Param  callback (function(node)) - the callback to invoke
    -- TODO: docs
    tree_map = function(callback, ts_tree)
        local tree = ts_tree or vim.treesitter.get_parser(0, "norg"):parse()[1]

        local root = tree:root()

        for child, _ in root:iter_children() do
            callback(child)
        end
    end,

    tree_map_rec = function(callback, ts_tree)
        local tree = ts_tree or vim.treesitter.get_parser(0, "norg"):parse()[1]

        local root = tree:root()

        local function descend(start)
            for child, _ in start:iter_children() do
                local stop_descending = callback(child)
                if not stop_descending then
                    descend(child)
                end
            end
        end

        descend(root)
    end,

    -- Gets the range of a given node
    get_node_range = function(node)
        if not node then
            return {
                row_start = 0,
                column_start = 0,
                row_end = 0,
                column_end = 0,
            }
        end

        local rs, cs, re, ce = neorg.lib.when(type(node) == "table", function()
            local brs, bcs, _, _ = node[1]:range()
            local _, _, ere, ece = node[#node]:range()
            return brs, bcs, ere, ece
        end, function()
            local a, b, c, d = node:range()
            return a, b, c, d
        end)

        return {
            row_start = rs,
            column_start = cs,
            row_end = re,
            column_end = ce,
        }
    end,

    --- Extracts the document root from the current document
    --- @param buf number The number of the buffer to extract (can be nil)
    --- @return userdata the root node of the document
    get_document_root = function(buf)
        local tree = vim.treesitter.get_parser(buf or 0, "norg"):parse()[1]

        if not tree or not tree:root() then
            log.warn("Unable to parse the current document's syntax tree :(")
            return
        end

        return tree:root():type() ~= "ERROR" and tree:root()
    end,

    --- Extracts the text from a node (only the first line)
    --- @param node userdata a treesitter node to extract the text from
    --- @param buf number the buffer number. This is required to verify the source of the node. Can be nil in which case it is treated as "0"
    --- @return string The contents of the node in the form of a string
    get_node_text = function(node, buf)
        if not node then
            return
        end

        local text = module.private.ts_utils.get_node_text(node, buf or 0)

        if not text then
            return
        end

        return text[#text] == "\n" and table.concat(vim.list_slice(text, 0, -2), " ") or table.concat(text, " ")
    end,

    find_parent = function(node, types)
        local _node = node

        while _node do
            if type(types) == "string" then
                if _node:type():match(types) then
                    return _node
                end
            elseif vim.tbl_contains(types, _node:type()) then
                return _node
            end

            _node = _node:parent()
        end
    end,

    get_first_node_on_line = function(buf, line, unnamed, lenient)
        local query_str = [[
            _ @node
        ]]

        local document_root = module.public.get_document_root(buf)

        if not document_root then
            return
        end

        if line == 0 and not lenient then
            local first_node = document_root:named_child(0)

            if not first_node then
                return
            end

            if module.public.get_node_range(first_node).row_start == 0 then
                return first_node
            end

            return
        end

        local query = vim.treesitter.parse_query("norg", query_str)

        local function find_closest_unnamed_node(node)
            if unnamed or not node or node:named() then
                return node
            end

            while node and not node:named() do
                node = node:parent()
            end

            return node
        end

        local result

        for id, node in query:iter_captures(document_root, buf, lenient and line - 1 or line, line + 1) do
            if query.captures[id] == "node" then
                if lenient then
                    result = node
                else
                    local range = module.public.get_node_range(node)

                    if range.row_start == line then
                        return find_closest_unnamed_node(node)
                    end
                end
            end
        end

        return find_closest_unnamed_node(result)
    end,

    get_document_metadata = function(buf)
        buf = buf or 0

        local languagetree = vim.treesitter.get_parser(buf, "norg")

        if not languagetree then
            return
        end

        local result = {}

        languagetree:for_each_child(function(tree)
            if tree:lang() ~= "norg_meta" then
                return
            end

            local meta_language_tree = tree:parse()[1]

            if not meta_language_tree then
                return
            end

            local query = vim.treesitter.parse_query(
                "norg_meta",
                [[
                (metadata
                    (pair
                        (key) @key
                    )
                )
            ]]
            )

            local function parse_data(node)
                return neorg.lib.match(node:type())({
                    value = neorg.lib.wrap(module.public.get_node_text, node, buf),
                    array = function()
                        local resulting_array = {}

                        for child in node:iter_children() do
                            if child:named() then
                                local parsed_data = parse_data(child)

                                if parsed_data then
                                    table.insert(resulting_array, parsed_data)
                                end
                            end
                        end

                        return resulting_array
                    end,
                    object = function()
                        local resulting_object = {}

                        for child in node:iter_children() do
                            if not child:named() or child:type() ~= "pair" then
                                goto continue
                            end

                            local key = child:named_child(0)
                            local value = child:named_child(1)

                            if not key then
                                goto continue
                            end

                            local key_content = module.public.get_node_text(key, buf)

                            resulting_object[key_content] = (value and parse_data(value) or vim.NIL)

                            ::continue::
                        end

                        return resulting_object
                    end,
                })
            end

            for id, node in query:iter_captures(meta_language_tree:root(), buf) do
                if query.captures[id] == "key" then
                    local key_content = module.public.get_node_text(node, buf)

                    result[key_content] = (
                            node:next_named_sibling() and parse_data(node:next_named_sibling()) or vim.NIL
                        )
                end
            end
        end)

        return result
    end,
}

module.on_event = function(event)
    if event.split_type[1] == "core.keybinds" then
        if event.split_type[2] == "core.integrations.treesitter.next.heading" then
            module.public.goto_next_heading()
        elseif event.split_type[2] == "core.integrations.treesitter.previous.heading" then
            module.public.goto_previous_heading()
        end
    elseif event.split_type[2] == "sync-parsers" then
        pcall(vim.cmd, "TSInstall! norg")
        pcall(vim.cmd, "TSInstall! norg_meta")
    end
end

module.events.subscribed = {
    ["core.keybinds"] = {
        ["core.integrations.treesitter.next.heading"] = true,
        ["core.integrations.treesitter.previous.heading"] = true,
    },

    ["core.neorgcmd"] = {
        ["sync-parsers"] = true,
    },
}

return module

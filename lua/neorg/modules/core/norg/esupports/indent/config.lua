---@class mod.norg.esupports.indent.config
local config = {
    indents = {
        _ = {
            modifiers = { "under-headings" },
            indent = 0,
        },

        ["paragraph_segment"] = {
            modifiers = { "under-headings", "under-nestable-detached-modifiers" },
            indent = 0,
        },

        ["strong_paragraph_delimiter"] = {
            indent = function(buf, _, line)
                local node = module.required["core.integrations.treesitter"].get_first_node_on_line(
                    buf,
                    vim.fn.prevnonblank(line) - 1
                )

                if not node then
                    return 0
                end

                return module.required["core.integrations.treesitter"].get_node_range(
                    node:type():match("heading%d") and node:named_child(1) or node
                ).column_start
            end,
        },

        ["heading1"] = {
            indent = 0,
        },
        ["heading2"] = {
            indent = 0,
        },
        ["heading3"] = {
            indent = 0,
        },
        ["heading4"] = {
            indent = 0,
        },
        ["heading5"] = {
            indent = 0,
        },
        ["heading6"] = {
            indent = 0,
        },

        ["ranged_tag"] = {
            modifiers = { "under-headings" },
            indent = 0,
        },

        ["ranged_tag_content"] = {
            indent = -1,
        },

        ["ranged_tag_end"] = {
            indent = function(_, node)
                return module.required["core.integrations.treesitter"].get_node_range(node:parent()).column_start
            end,
        },
    },
    modifiers = {
        -- For any object that can exist under headings
        ["under-headings"] = function(_, node)
            local heading = module.required["core.integrations.treesitter"].find_parent(node:parent(), "heading%d")

            if not heading or not heading:named_child(1) then
                return 0
            end

            return module.required["core.integrations.treesitter"].get_node_range(heading:named_child(1)).column_start
        end,

        -- For any object that should be indented under a list
        ["under-nestable-detached-modifiers"] = function(_, node)
            local list = module.required["core.integrations.treesitter"].find_parent(node, {
                "unordered_list1",
                "unordered_list2",
                "unordered_list3",
                "unordered_list4",
                "unordered_list5",
                "unordered_list6",
                "ordered_list1",
                "ordered_list2",
                "ordered_list3",
                "ordered_list4",
                "ordered_list5",
                "ordered_list6",
                "quote1",
                "quote2",
                "quote3",
                "quote4",
                "quote5",
                "quote6",
            })

            if not list or not list:named_child(1) then
                return 0
            end

            return module.required["core.integrations.treesitter"].get_node_range(list:named_child(1)).column_start
        end,
    },
    tweaks = {},

    format_on_enter = true,
    format_on_escape = true,
}


return config

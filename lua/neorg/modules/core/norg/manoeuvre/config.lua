---@class mod.norg.manouvre.config
local config = {
    moveables = {
        headings = {
            "heading%d",
            "heading%d",
        },
        todo_items = {
            "todo_item%d",
            {
                "todo_item%d",
                "unordered_list%d",
            },
        },
        unordered_list_elements = {
            "unordered_list%d",
            {
                "todo_item%d",
                "unordered_list%d",
            },
        },
    },
}


return config

---@class mod.itero.config
local config = {
    -- A list of strings detailing what nodes can be "iterated".
    -- Usually doesn't need to be changed, unless you want to disable some
    -- items from being iterable.
    iterables = {
        "unordered_list%d",
        "ordered_list%d",
        "heading%d",
        "quote%d",
    },

    -- Which items to retain extensions for
    retain_extensions = {
        ["unordered_list%d"] = true,
        ["ordered_list%d"] = true,
    },
}


return config

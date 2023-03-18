local neorg = require("neorg.core")

---@class mod.norg.esupports.metagen.config
local config = {
    -- One of "none", "auto" or "empty"
    -- - None generates no metadata
    -- - Auto generates metadata if it is not present
    -- - Empty generates metadata only for new files/buffers.
    type = "none",

    -- Whether updated date field should be automatically updated on save if required
    update_date = true,

    -- How to generate a tabulation inside the `@document.meta` tag
    tab = "",

    -- Custom delimiter between tag and value
    delimiter = ": ",

    -- Custom template to use for generating content inside `@document.meta` tag
    template = {
        {
            "title",
            function()
                return vim.fn.expand("%:p:t:r")
            end,
        },
        { "description", "" },
        { "authors", neorg.utils.get_username },
        { "categories", "" },
        {
            "created",
            function()
                return os.date("%Y-%m-%d")
            end,
        },
        {
            "updated",
            function()
                return os.date("%Y-%m-%d")
            end,
        },
        { "version", neorg.configuration.version },
    },
}


return config

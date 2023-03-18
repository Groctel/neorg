---@class markdown.environment
---@field public start string #String that starts the environment
---@field public end string #String that ends the environment

---@class mod.markdown.config
---Used by the exporter to know what extension to use when creating markdown
---files. The default is recommended, although you can change it.
---@field public extension string
---Any extensions you may want to use when exporting to markdown. By default no
---extensions are loaded (the exporter is commonmark compliant). You can also
---set this value to `"all"` to enable all extensions. The full extension list
---is: `todo-items-basic`, `todo-items-pending`, `todo-items-extended`,
---`definition-lists`, `mathematics` and 'metadata'.
---@field public extensions dict<any>
---Data about how to render mathematics.
---The default is recommended as it is the most common, although certain flavours
---of markdown use different syntax.
---@field public mathematics dict<markdown.environment>
---Data about how to render metadata. There are a few ways to render metadata
---blocks, but the default one is the most common.
---@field public metadata markdown.environment
local config = {
    extension = "md",
    extensions = {},

    mathematics = {
        inline = {
            start = "$",
            ["end"] = "$",
        },
        block = {
            start = "$$",
            ["end"] = "$$",
        },
    },

    metadata = {
        start = "---",
        ["end"] = "---", -- Is usually also "..."
    },
}


-- TODO: Rename to start to begin?
-- TODO: Rename end to a non-reserved word?
-- TODO: Move mathematics and metadata to a single environment table?
return config

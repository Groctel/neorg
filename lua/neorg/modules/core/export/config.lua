---@class mod.export.config
---@field public export_dir string #Destination directory when running `:Neorg export directory`. The string can be formatted with the special keys: `<export-dir>` and `<language>`.
local config = {
    export_dir = "<export-dir>/<language>-export",
}


return config

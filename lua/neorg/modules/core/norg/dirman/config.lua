---@class mod.norg.dirman.config
---@field public default_workspace path? #The default workspace to set whenever Neovim starts.
---@field public index string #The name for the index file
---Whether to open the last workspace's index file when `nvim` is executed without
---arguments. May also be set to the string `"default"`, due to which Neorg will
---always open up the index file for the workspace defined in `default_workspace`.
---@field public open_last_workspace boolean|string.default
---@field public workspaces dict<path>
local config = {
    default_workspace = nil,
    index = "index.norg",
    open_last_workspace = false,
    workspaces = {
        default = vim.fn.getcwd(),
    },
}


return config

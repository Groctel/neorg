---@class mod.storage.config
local config = {
    -- Full path to store data (saved in mpack data format)
    path = vim.fn.stdpath("data") .. "/neorg.mpack",
}


return config

---@class mod.keybinds.config
local config = {
    -- Use the default keybinds provided in https://github.com/nvim-neorg/neorg/blob/main/lua/neorg/modules/core/keybinds/keybinds.lua
    default_keybinds = true,

    -- Prefix for some Neorg keybinds
    neorg_leader = "<LocalLeader>",

    -- Function to be invoked that allows the user to change their keybinds
    hook = nil,

    -- The keybind preset to use
    keybind_preset = "neorg",

    -- An array of functions, each one corresponding to a separate preset
    keybind_presets = {},
}


return config

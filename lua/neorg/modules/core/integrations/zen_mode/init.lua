local modules = require("neorg.modules")
local module = modules.create("core.integrations.zen_mode")
local require_relative = require("neorg.utils").require_relative

module.load = function()
    local success, zen_mode = pcall(require, "zen_mode")

    assert(success, "Unable to load zen_mode...")

    zen_mode.setup(module.config)

    module.private.zen_mode = zen_mode
end

module.private = {
    zen_mode = nil,
}

module.config = require_relative(..., "config")

---@class core.integrations.zen_mode
module.public = {
    toggle = function()
        vim.cmd(":ZenMode")
    end,
}
return module

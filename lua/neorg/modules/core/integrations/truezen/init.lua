local modules = require("neorg.modules")
local module = modules.create("core.integrations.truezen")
local require_relative = require("neorg.utils").require_relative

module.load = function()
    local success, truezen = pcall(require, "true-zen.main")

    assert(success, "Unable to load truezen...")

    local _success, truezen_setup = pcall(require, "true-zen")
    assert(_success, "Unable to load truezen setup")

    truezen_setup.setup(module.config)

    module.private.truezen = truezen
end

module.private = {
    truezen = nil,
}

module.config = require_relative(..., "config")

---@class core.integrations.truezen
module.public = {
    toggle_ataraxis = function()
        vim.cmd(":TZAtaraxis")
    end,
}
return module

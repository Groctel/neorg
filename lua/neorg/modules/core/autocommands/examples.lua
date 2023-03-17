local modules = require("neorg.modules")
local neorg = require("neorg.core")

local examples = {}


-- TODO: Check if the example is still correct
examples["Binding to an Autocommand"] = function()
    local mymodule = modules.create("my.module")

    mymodule.setup = function()
        return {
            success = true,
            requires = {
                "core.autocommands", -- Be sure to require the module!
            },
        }
    end

    mymodule.load = function()
        -- Enable an autocommand (in this case InsertLeave)
        module.required["core.autocommands"].enable_autocommand("InsertLeave")
    end

    -- Listen for any incoming events
    mymodule.on_event = function(event)
        -- If it's the event we're looking for then do something!
        if event.name == "insertleave" then
            neorg.log.warn("We left insert mode!")
        end
    end

    mymodule.events.subscribed = {
        ["core.autocommands"] = {
            insertleave = true, -- Be sure to listen in for this event!
        },
    }

    return mymodule
end


return examples

local log = require("neorg.core.log")
local modules = require("neorg.modules")

local examples = {}


-- TODO: Check if the example is still correct
examples["Create keybinds in your module"] = function()
    -- The process of defining a keybind is only a tiny bit more involved than defining e.g. an autocommand. Let's see what differs in creating a keybind rather than creating an autocommand:

    local test = modules.create("test.module")

    test.setup = function()
        return { success = true, requires = { "core.keybinds" } } -- Require the keybinds module
    end

    test.load = function()
        module.required["core.keybinds"].register_keybind(test.name, "my_keybind")

        -- It is also possible to mass initialize keybindings via the public register_keybinds function. It can be used like so:
        -- This should stop redundant calls to the same function or loops within module code.
        module.required["core.keybinds"].register_keybinds(test.name, { "second_keybind", "my_other_keybind" })
    end

    test.on_event = function(event)
        -- The event.split_type field is the type field except split into two.
        -- The split point is .events., meaning if the event type is e.g. "test.module.my_keybind" the value of split_type will be { "core.keybinds", "test.module.my_keybind" }.
        if event.name == "test.module.my_keybind" then
            log.info("Keybind my_keybind has been pressed!")
        end
    end

    test.events.subscribed = {

        ["core.keybinds"] = {
            -- The event path is a bit different here than it is normally.
            -- Whenever you receive an event, you're used to the path looking like this: <module_path>.events.<event_name>.
            -- Here, however, the path looks like this: <module_path>.events.test.module.<event_name>.
            -- Why is that? Well, the module operates a bit differently under the hood.
            -- In order to create a unique name for every keybind we use the module's name as well.
            -- Meaning if your module is called test.module you will receive an event of type <module_path>.events.test.module.<event_name>.
            ["test.module.my_keybind"] = true, -- Subscribe to the event
        },
    }
end


-- TODO: Check if the example is still correct
examples["Attach some keys to the create keybind"] = function()
    -- To invoke a keybind, we can then use :Neorg keybind norg test.module.my_keybind.
    -- :Neorg keybind tells core.neorgcmd to invoke a keybind, and the next argument (norg) is the mode that the keybind should be executed in.
    -- Modes are a way to isolate different parts of the neorg environment easily, this includes keybinds too.
    -- core.mode, the module designed to manage modes, is explaned in this own page (see the wiki sidebar).
    -- Just know that by default neorg launches into the norg mode, so you'd most likely want to bind to that.
    -- After the mode you can find the path to the keybind we want to trigger. Soo let's bind it! You should have already read the user keybinds document that details where and how to bind keys, the below code snippet is an extension of that:

    -- (Somewhere in your config)
    -- Require the user callbacks module, which allows us to tap into the core of Neorg
    local neorg_callbacks = require("neorg.core.callbacks")

    -- Listen for the enable_keybinds event, which signals a "ready" state meaning we can bind keys.
    -- This hook will be called several times, e.g. whenever the Neorg Mode changes or an event that
    -- needs to reevaluate all the bound keys is invoked
    neorg_callbacks.on_event("enable_keybinds", function(_, keybinds)
        -- All your other keybinds

        -- Map all the below keybinds only when the "norg" mode is active
        keybinds.map_event_to_mode("norg", {
            n = {
                { "<Leader>o", "test.module.my_keybind" },
            },
        }, { silent = true, noremap = true })
    end)

    -- To change the current mode as a user of neorg you can run :Neorg set-mode <mode>.
    -- If you try changing the current mode into a non-existent mode (like :Neorg set-mode a-nonexistent-mode) you will see that all the keybinds you bound to the norg mode won't work anymore!
    -- They'll start working again if you reset the mode back via :Neorg set-mode norg.
end


return examples

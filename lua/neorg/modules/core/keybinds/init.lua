--[[
    File: User-Keybinds
    Title: The Keybinds Module
    Summary: Module for managing keybindings with Neorg mode support.
    ---

### Disabling Default Keybinds
By default when you load the `core.keybinds` module all keybinds will be enabled.
If you want to change this, be sure to set `default_keybinds` to `false`:
```lua
["core.keybinds"] = {
    config = {
        default_keybinds = false,
    }
}
```

### Setting Up a Keybind Hook
Want to change some keybinds? You can set up a function that will allow you to tweak
every keybind bit by bit.

```lua
["core.keybinds"] = {
    config = {
        hook = function(keybinds)
            -- Unmaps any Neorg key from the `norg` mode
            keybinds.unmap("norg", "n", "gtd")

            -- Binds the `gtd` key in `norg` mode to execute `:echo 'Hello'`
            keybinds.map("norg", "n", "gtd", "<cmd>echo 'Hello!'<CR>")

            -- Remap unbinds the current key then rebinds it to have a different action
            -- associated with it.
            -- The following is the equivalent of the `unmap` and `map` calls you saw above:
            keybinds.remap("norg", "n", "gtd", "<cmd>echo 'Hello!'<CR>")

            -- Sometimes you may simply want to rebind the Neorg action something is bound to
            -- versus remapping the entire keybind. This remap is essentially the same as if you
            -- did `keybinds.remap("norg", "n", "<C-Space>, "<cmd>Neorg keybind norg core.norg.qol.todo_items.todo.task_done<CR>")
            keybinds.remap_event("norg", "n", "<C-Space>", "core.norg.qol.todo_items.todo.task_done")

            -- Want to move one keybind into the other? `remap_key` moves the data of the
            -- first keybind to the second keybind, then unbinds the first keybind.
            keybinds.remap_key("norg", "n", "<C-Space>", "<Leader>t")
        end,
    }
}
```
--]]

local neorg = require("neorg.core")
local modules = require("neorg.modules")
local module = modules.create("core.keybinds")
local log = neorg.log

module.setup = function()
    return {
        success = true,
        requires = { "core.neorgcmd", "core.mode", "core.autocommands" },
        imports = { "keybinds" },
    }
end

module.load = function()
    module.required["core.autocommands"].enable_autocommand("BufEnter")
    module.required["core.autocommands"].enable_autocommand("BufLeave")

    if module.config.public.hook then
        neorg.callbacks.on_event("enable_keybinds", function(_, keybinds)
            module.config.public.hook(keybinds)
        end)
    end
end

module.config.public = {
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

---@class core.keybinds
module.public = {

    -- Define neorgcmd autocompletions and commands
    neorg_commands = {
        keybind = {
            min_args = 2,
            name = "core.keybinds.trigger",

            complete = {
                {},
                {},
            },
        },
    },

    version = "0.0.9",

    -- Adds a new keybind to the database of known keybinds
    -- @param module_name string #the name of the module that owns the keybind. Make sure it's an absolute path.
    -- @param name string  #the name of the keybind. The module_name will be prepended to this string to form a unique name.
    register_keybind = function(module_name, name)
        -- Create the full keybind name
        local keybind_name = module_name .. "." .. name

        -- If that keybind is not defined yet then define it
        if not module.events.defined[keybind_name] then
            module.events.defined[keybind_name] = keybind_name

            -- Define autocompletion for core.neorgcmd
            table.insert(module.public.neorg_commands.keybind.complete[2], keybind_name)
        end

        -- Update core.neorgcmd's internal tables
        module.required["core.neorgcmd"].add_commands_from_table(module.public.neorg_commands)
    end,

    --- Like register_keybind(), except registers a batch of them
    ---@param module_name string #The name of the module that owns the keybind. Make sure it's an absolute path.
    ---@param names #list of strings - a list of strings detailing names of the keybinds. The module_name will be prepended to each one to form a unique name.
    register_keybinds = function(module_name, names)
        -- Loop through each name from the names argument
        for _, name in ipairs(names) do
            -- Create the full keybind name
            local keybind_name = module_name .. "." .. name

            -- If that keybind is not defined yet then define it
            if not module.events.defined[keybind_name] then
                module.events.defined[keybind_name] = keybind_name

                -- Define autocompletion for core.neorgcmd
                table.insert(module.public.neorg_commands.keybind.complete[2], keybind_name)
            end
        end

        -- Update core.neorgcmd's internal tables
        module.required["core.neorgcmd"].add_commands_from_table(module.public.neorg_commands)
    end,

    bind_all = function(buf, action, for_mode)
        local current_mode = for_mode or module.required["core.mode"].get_mode()

        -- Keep track of the keys the user may want to bind
        local bound_keys = {}

        -- Broadcast the enable_keybinds event to any user that might have registered a User Callback for it
        local payload

        payload = {

            --- Maps a key to a specific Neorg mode
            ---@param neorg_mode string #The Neorg mode to bind to
            ---@param mode string #The Neovim mode to bind to, e.g. `n` or `i` etc.
            ---@param key string #The lhs value from `:h vim.keymap.set`
            ---@param command string|function #The rhs value from `:h vim.keymap.set`
            ---@param opts table #The table value from `:h vim.keymap.set`
            map = function(neorg_mode, mode, key, command, opts)
                if neorg_mode ~= "all" and current_mode ~= neorg_mode then
                    return
                end

                bound_keys[neorg_mode] = bound_keys[neorg_mode] or {}
                bound_keys[neorg_mode][mode] = bound_keys[neorg_mode][mode] or {}
                bound_keys[neorg_mode][mode][key] = bound_keys[neorg_mode][mode][key] or {}

                bound_keys[neorg_mode][mode][key] = {
                    command = command,
                    opts = opts,
                }
            end,

            --- Maps a key to a specific Neorg keybind.
            --  `map()` binds to any rhs value, whilst `map_event()` is essentially a wrapper
            --  for <cmd>Neorg keybind `neorg_mode` `expr`<CR>
            ---@param neorg_mode string #The Neorg mode to bind to
            ---@param mode string #The Neovim mode to bind to, e.g. `n` or `i` etc.
            ---@param key string #The lhs value from `:h vim.keymap.set`
            ---@param expr string #The Neorg event to bind to (e.g. `core.norg.dirman.new.note`)
            ---@param opts table #The table value from `:h vim.keymap.set`
            map_event = function(neorg_mode, mode, key, expr, opts)
                payload.map(neorg_mode, mode, key, "<cmd>Neorg keybind " .. neorg_mode .. " " .. expr .. "<CR>", opts)
            end,

            --- Unmaps any keybind from any Neorg mode
            ---@param neorg_mode string #The Neorg mode to remove the key from
            ---@param mode string #The target Neovim mode
            ---@param key string #The key itself to unmap
            unmap = function(neorg_mode, mode, key)
                if neorg_mode == "all" then
                    for _, norg_mode in ipairs(module.required["core.mode"].get_modes()) do
                        payload.unmap(norg_mode, mode, key)
                    end
                end

                bound_keys[neorg_mode] = bound_keys[neorg_mode] or {}
                bound_keys[neorg_mode][mode] = bound_keys[neorg_mode][mode] or {}

                bound_keys[neorg_mode][mode][key] = bound_keys[neorg_mode][mode][key] and nil
            end,

            remap = function(neorg_mode, mode, key, new_rhs)
                if neorg_mode ~= "all" and current_mode ~= neorg_mode then
                    return
                end

                bound_keys[neorg_mode] = bound_keys[neorg_mode] or {}
                bound_keys[neorg_mode][mode] = bound_keys[neorg_mode][mode] or {}
                bound_keys[neorg_mode][mode][key] = bound_keys[neorg_mode][mode][key] or {}

                local opts = bound_keys[neorg_mode][mode][key].opts

                payload.map(neorg_mode, mode, key, new_rhs, opts)
            end,

            remap_event = function(neorg_mode, mode, key, new_event)
                if neorg_mode ~= "all" and current_mode ~= neorg_mode then
                    return
                end

                bound_keys[neorg_mode] = bound_keys[neorg_mode] or {}
                bound_keys[neorg_mode][mode] = bound_keys[neorg_mode][mode] or {}
                bound_keys[neorg_mode][mode][key] = bound_keys[neorg_mode][mode][key] or {}

                local opts = bound_keys[neorg_mode][mode][key].opts

                payload.map(
                    neorg_mode,
                    mode,
                    key,
                    "<cmd>Neorg keybind " .. neorg_mode .. " " .. new_event .. "<CR>",
                    opts
                )
            end,

            remap_key = function(neorg_mode, mode, old_key, new_key)
                if neorg_mode ~= "all" and current_mode ~= neorg_mode then
                    return
                end

                bound_keys[neorg_mode] = bound_keys[neorg_mode] or {}
                bound_keys[neorg_mode][mode] = bound_keys[neorg_mode][mode] or {}
                bound_keys[neorg_mode][mode][old_key] = bound_keys[neorg_mode][mode][old_key] or {}

                local command = bound_keys[neorg_mode][mode][old_key].command
                local opts = bound_keys[neorg_mode][mode][old_key].opts

                payload.unmap(neorg_mode, mode, old_key)
                payload.map(neorg_mode, mode, new_key, command, opts)
            end,

            --- An advanced wrapper around the map() function, maps several keys if the current neorg mode is the desired one
            ---@param mode string #The neorg mode to bind the keys on
            ---@param keys #table { <neovim_mode> = { { "<key>", "<name-of-keybind>", custom_opts } } } - a table of keybinds
            ---@param opts #table) - the same parameters that should be passed into vim.keymap.set('s opts parameter
            map_to_mode = function(mode, keys, opts)
                -- If the keys table is empty then don't bother doing any parsing
                if vim.tbl_isempty(keys) then
                    return
                end

                -- If the current mode matches the desired mode then
                if mode == "all" or (for_mode or module.required["core.mode"].get_mode()) == mode then
                    -- Loop through all the keybinds for a certain mode
                    for neovim_mode, keymaps in pairs(keys) do
                        -- Loop though all the keymaps in that mode
                        for _, keymap in ipairs(keymaps) do
                            -- Map the keybind and keep track of it using the map() function
                            payload.map(mode, neovim_mode, keymap[1], keymap[2], keymap[3] or opts)
                        end
                    end
                end
            end,

            --- An advanced wrapper around the map() function, maps several keys if the current neorg mode is the desired one
            ---@param mode string #The neorg mode to bind the keys on
            ---@param keys #table { <neovim_mode> = { { "<key>", "<name-of-keybind>", custom_opts } } } - a table of keybinds
            ---@param opts #table) - the same parameters that should be passed into vim.keymap.set('s opts parameter
            map_event_to_mode = function(mode, keys, opts)
                -- If the keys table is empty then don't bother doing any parsing
                if vim.tbl_isempty(keys) then
                    return
                end

                -- If the current mode matches the desired mode then
                if mode == "all" or (for_mode or module.required["core.mode"].get_mode()) == mode then
                    -- Loop through all the keybinds for a certain mode
                    for neovim_mode, keymaps in pairs(keys) do
                        -- Loop though all the keymaps in that mode
                        for _, keymap in ipairs(keymaps) do
                            -- Map the keybind and keep track of it using the map() function
                            payload.map(
                                mode,
                                neovim_mode,
                                keymap[1],
                                "<cmd>Neorg keybind "
                                    .. mode
                                    .. " "
                                    .. table.concat(vim.list_slice(keymap, 2), " ")
                                    .. "<CR>",
                                opts
                            )
                        end
                    end
                end
            end,

            -- Include the current Neorg mode and leader in the contents
            mode = current_mode,
            leader = module.config.public.neorg_leader,
        }

        local function generate_default_functions(cb, ...)
            local funcs = { ... }

            for _, func in ipairs(funcs) do
                local name, to_exec = cb(func, payload[func])

                payload[name] = to_exec
            end
        end

        generate_default_functions(function(name, func)
            return name .. "d", function(...)
                func("norg", ...)
            end
        end, "map", "map_event", "unmap", "remap", "remap_key", "remap_event")
                print(mode, vim.inspect(keys), vim.inspect(opts))

        if
            module.config.public.default_keybinds
            and module.config.public.keybind_presets[module.config.public.keybind_preset]
        then
            module.config.public.keybind_presets[module.config.public.keybind_preset](payload)
        end

        for _, callback in pairs(module.private.requested_keys) do
            callback(payload)
        end

        -- Broadcast our event with the desired payload!
        neorg.events.new(module, "enable_keybinds", payload):broadcast(
            modules.loaded_modules,
            function()
                for neorg_mode, neovim_modes in pairs(bound_keys) do
                    if neorg_mode == "all" or neorg_mode == current_mode then
                        for mode, keys in pairs(neovim_modes) do
                            for key, data in pairs(keys) do
                                local ok, error = pcall(function()
                                    if action then
                                        action(buf, mode, key, data.command, data.opts or {})
                                    else
                                        local opts = data.opts or {}
                                        opts.buffer = buf

                                        vim.keymap.set(mode, key, data.command, opts)
                                    end
                                end)

                                if not ok then
                                    log.trace(
                                        string.format(
                                            "An error occurred when trying to bind key '%s' in mode '%s' in neorg mode '%s' - %s",
                                            key,
                                            mode,
                                            current_mode,
                                            error
                                        )
                                    )
                                end
                            end
                        end
                    end
                end
            end
        )
    end,

    --- Updates the list of known modes and keybinds for easy autocompletion. Invoked automatically during neorg_post_load().
    sync = function()
        -- Update the first parameter with the new list of modes
        -- NOTE(vhyrro): Is there a way to prevent copying? Can you "unbind" a reference to a table?
        module.public.neorg_commands.keybind.complete[1] = vim.deepcopy(module.required["core.mode"].get_modes())
        table.insert(module.public.neorg_commands.keybind.complete[1], "all")

        -- Update core.neorgcmd's internal tables
        module.required["core.neorgcmd"].add_commands_from_table(module.public.neorg_commands)
    end,

    request_keys = function(module_name, callback)
        module.private.requested_keys[module_name] = callback
    end,
}

module.private = {
    requested_keys = {},
}

module.neorg_post_load = module.public.sync

module.on_event = function(event)
    neorg.lib.match(event.name)({
        ["core.keybinds.trigger"] = function()
            -- Query the current mode and the expected mode (the one passed in by the user)
            local expected_mode = event.payload[1]
            local current_mode = module.required["core.mode"].get_mode()

            -- If the modes don't match then don't execute the keybind
            if expected_mode ~= current_mode and expected_mode ~= "all" then
                return
            end

            -- Get the event path to the keybind
            local keybind_event_path = event.payload[2]

            -- If it is defined then broadcast the event
            if module.events.defined[keybind_event_path] then
                neorg.events.new(
                    module,
                    keybind_event_path,
                    vim.list_slice(event.payload, 3)
                ):broadcast(modules.loaded_modules)
            else -- Otherwise throw an error
                log.error("Unable to trigger keybind", keybind_event_path, "- the keybind does not exist")
            end
        end,
        ["mode_created"] = neorg.lib.wrap(module.public.sync),
        ["mode_set"] = function()
            -- If a new mode has been set then reset all of our keybinds
            module.public.bind_all(event.buffer, function(buf, mode, key)
                vim.api.nvim_buf_del_keymap(buf, mode, key)
            end, event.payload.current)
            module.public.bind_all(event.buffer)
        end,
        ["bufenter"] = function()
            if not event.payload.norg then
                return
            end

            -- If a new mode has been set then reset all of our keybinds
            module.public.bind_all(event.buffer, function(buf, mode, key)
                vim.api.nvim_buf_del_keymap(buf, mode, key)
            end, module.required["core.mode"].get_previous_mode())
            module.public.bind_all(event.buffer)
        end,
    })
end

module.events.defined = {
    enable_keybinds = "enable_keybinds",
}

module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["core.keybinds.trigger"] = true,
    },

    ["core.autocommands"] = {
        bufenter = true,
        bufleave = true,
    },

    ["core.mode"] = {
        mode_created = true,
        mode_set = true,
    },
}


return module

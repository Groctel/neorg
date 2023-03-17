local examples = {}


-- TODO: Check if the example is still correct
examples["Adding a Neorg command"] = function()
    -- In your module.setup(), make sure to require core.neorgcmd (requires = { "core.neorgcmd" })
    -- Afterwards in a function of your choice that gets called *after* core.neorgcmd gets intialized e.g. load():

    module.load = function()
        module.required["core.neorgcmd"].add_commands_from_table({
            -- The name of our command
            my_command = {
                min_args = 1, -- Tells neorgcmd that we want at least one argument for this command
                max_args = 1, -- Tells neorgcmd we want no more than one argument
                args = 1, -- Setting this variable instead would be the equivalent of min_args = 1 and max_args = 1
                -- This command is only avaiable within `.norg` files.
                -- This can also be a function(bufnr, is_in_an_norg_file)
                condition = "norg",

                subcommands = { -- Defines subcommands
                    -- Repeat the definition cycle again
                    my_subcommand = {
                        args = 2, -- Force two arguments to be supplied
                        -- The identifying name of this command
                        -- Every "endpoint" must have a name associated with it
                        name = "my.command",

                        -- If your command takes in arguments versus
                        -- subcommands you can make a table of tables with
                        -- completion for those arguments here.
                        -- This table is optional.
                        complete = {
                            { "first_completion1", "first_completion2" },
                            { "second_completion1", "second_completion2" },
                        },

                        -- We do not define a subcommands table here because we don't have any more subcommands
                        -- Creating an empty subcommands table will cause errors so don't bother
                    },
                },
            },
        })
    end

    -- Afterwards, you want to subscribe to the corresponding event:

    module.events.subscribed = {
        ["core.neorgcmd"] = {
            ["my.command"] = true, -- Has the same name as our "name" variable had in the "data" table
        },
    }

    -- There's also another way to define your own custom commands that's a lot more automated. Such automation can be achieved
    -- by putting your code in a special directory. That directory is in core.neorgcmd.commands. Creating your modules in this directory
    -- will allow users to easily enable you as a "command module" without much hassle.

    -- To enable a command in the commands/ directory, do this:

    require("neorg").setup({
        load = {
            ["core.neorgcmd"] = {
                config = {
                    load = {
                        "some.neorgcmd", -- The name of a valid command
                    },
                },
            },
        },
    })

    -- And that's it! You're good to go.
    -- Want to find out more? Read the wiki entry! https://github.com/nvim-neorg/neorg/wiki/Neorg-Command
end


return examples

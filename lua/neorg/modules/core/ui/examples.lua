local log = require("neorg.core.log")
local examples = {}


-- TODO: Check if the example is still correct
examples["Create a selection popup"] = function()
    -- Creates the buffer
    local buffer = module.public.create_split("selection/Test selection")

    -- Binds a selection to that buffer
    local selection = module.public
        .begin_selection(buffer)
        :apply({
            -- A title will simply be text with a custom highlight
            title = function(self, text)
                return self:text(text, "@text.title")
            end,
        })
        :listener("destroy", { "<Esc>" }, function(self)
            self:destroy()
        end)
        :listener("go-back", { "<BS>" }, function(self)
            self:pop_page()
        end)

    selection
        :options({
            text = {
                highlight = "@text.underline",
            },
        })
        :title("Hello World!")
        :blank()
        :text("Flags:")
        :flag("<CR>", "finish")
        :flag("t", "test flag", function()
            log.warn("The test flag has been pressed!")
        end)
        :blank()
        :text("Other flags:")
        :rflag("a", "press me!", function()
            selection:setstate("test", "hello from the other side")

            -- Create more elements for the selection
            selection
                :title("Another Title!")
                :blank()
                :text("Other Flags:")
                :flag("a", "i do nothing :)")
                :rflag("b", "yet another nested flag", function()
                    selection
                        :title("Final Title")
                        :blank()
                        :text("Btw, did you know that you can")
                        :text("Press <BS> to go back a page? Try it!")
                        :blank()
                        :text("Also, psst, pressing `g` will give you a small surprise")
                        :blank()
                        :flag("a", "does nothing too")
                        :listener("print-message", { "g" }, function()
                            log.warn("You are awesome :)")
                        end)
                end)
        end)
        :stateof( -- To view this press `a` and then <BS> to go back
            "test",
            "This is a custom message: %s." --[[ you can supply a third argument which
            will forcefully render the message even if the state isn't present. The state will be replaced with a " " ]]
        )
end


return examples

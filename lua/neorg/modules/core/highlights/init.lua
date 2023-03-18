--[[
    File: Core-Highlights
    Title: Neorg module for managing highlight groups
    Summary: Manages your highlight groups with this module.
    Internal: true
--]]


---@alias mod.highlights.todo
---|`none` #The content of TODO items will not be coloured in any special way
---|`all` #The content of TODO items will directly reflect the colour of the item's TODO box
---|`except_undone` #This Will have the same behaviour as `all` but will exclude undone TODO items
---|`cancelled` #This will only highlight the content of TODO items for cancelled tasks

---@class mod.highlights.dim_group
---@field public reference string #TODO: Document type
---@field public percentage integer #TODO: Document type
---@field public affect string? #TODO: Document type
---@class mod.highlights.dim_branch : dict<dim_branch|dim_group>

---@class mod.highlights.highlight_group: dict<string>
---@class mod.highlights.highlight_branch : dict<highlight_branch|highlight_group>

local neorg = require("neorg.core")
local modules = require("neorg.modules")
local module = modules.create("core.highlights")
local require_relative = require("neorg.utils").require_relative


module.config = require_relative(..., "config")


module.setup = function()
    return { success = true, requires = { "core.autocommands" } }
end

module.load = function()
    module.required["core.autocommands"].enable_autocommand("BufEnter")
    module.required["core.autocommands"].enable_autocommand("ColorScheme", true)

    if module.config.todo_items_match_color then
        if
            not vim.tbl_contains({ "all", "except_undone", "cancelled" }, module.config.todo_items_match_color)
        then
            neorg.log.error(
                "Error when parsing `todo_items_match_color` for `core.highlights`, the key only accepts the following values: all, except_undone and cancelled."
            )
            return
        end

        for i = 1, 6 do
            local todo_items = module.config.highlights.todo_items
            local index = tostring(i)

            if module.config.todo_items_match_color ~= "cancelled" then
                if module.config.todo_items_match_color ~= "except_undone" then
                    todo_items.undone[index].content = todo_items.undone[index][""]
                end

                todo_items.pending[index].content = todo_items.pending[index][""]
                todo_items.done[index].content = todo_items.done[index][""]
                todo_items.urgent[index].content = todo_items.urgent[index][""]
                todo_items.on_hold[index].content = todo_items.on_hold[index][""]
                todo_items.recurring[index].content = todo_items.recurring[index][""]
                todo_items.uncertain[index].content = todo_items.uncertain[index][""]
            end

            todo_items.cancelled[index].content = todo_items.cancelled[index][""]
        end
    end

    module.public.trigger_highlights()

    vim.api.nvim_create_autocmd("ColorScheme", {
        callback = module.public.trigger_highlights,
    })
end

---@class core.highlights
module.public = {

    --- Reads the highlights configuration table and applies all defined highlights
    trigger_highlights = function()
        --- Recursively descends down the highlight configuration and applies every highlight accordingly
        ---@param highlights table #The table of highlights to descend down
        ---@param callback #(function(hl_name, highlight, prefix) -> bool) - a callback function to be invoked for every highlight. If it returns true then we should recurse down the table tree further
        ---@param prefix string #Should be only used by the function itself, acts as a "savestate" so the function can keep track of what path it has descended down
        local function descend(highlights, callback, prefix)
            -- Loop through every highlight defined in the provided table
            for hl_name, highlight in pairs(highlights) do
                -- If the callback returns true then descend further down the table tree
                if callback(hl_name, highlight, prefix) then
                    descend(highlight, callback, prefix .. "." .. hl_name)
                end
            end
        end

        -- Begin the descent down the public highlights configuration table
        descend(module.config.highlights, function(hl_name, highlight, prefix)
            -- If the type of highlight we have encountered is a table
            -- then recursively descend down it as well
            if type(highlight) == "table" then
                return true
            end

            -- Trim any potential leading and trailing whitespace
            highlight = vim.trim(highlight)

            -- Check whether we are trying to link to an existing hl group
            -- by checking for the existence of the + sign at the front
            local is_link = highlight:sub(1, 1) == "+"

            local full_highlight_name = "@neorg" .. prefix .. (hl_name:len() > 0 and ("." .. hl_name) or "")
            local does_hl_exist = neorg.lib.inline_pcall(vim.api.nvim_exec, "highlight " .. full_highlight_name, true)

            -- If we are dealing with a link then link the highlights together (excluding the + symbol)
            if is_link then
                -- If the highlight already exists then assume the user doesn't want it to be
                -- overwritten
                if does_hl_exist and does_hl_exist:len() > 0 and not does_hl_exist:match("xxx%s+cleared") then
                    return
                end

                vim.api.nvim_set_hl(0, full_highlight_name, {
                    link = highlight:sub(2),
                })
            else -- Otherwise simply apply the highlight options the user provided
                -- If the highlight already exists then assume the user doesn't want it to be
                -- overwritten
                if does_hl_exist and does_hl_exist:len() > 0 then
                    return
                end

                -- We have to use vim.cmd here
                vim.cmd({
                    cmd = "highlight",
                    args = { full_highlight_name, highlight },
                    bang = true,
                })
            end
        end, "")

        -- Begin the descent down the dimming configuration table
        descend(module.config.dim, function(hl_name, highlight, prefix)
            -- If we don't have a percentage value then keep traversing down the table tree
            if not highlight.percentage then
                return true
            end

            local full_highlight_name = "@neorg" .. prefix .. (hl_name:len() > 0 and ("." .. hl_name) or "")
            local does_hl_exist = neorg.lib.inline_pcall(vim.api.nvim_exec, "highlight " .. full_highlight_name, true)

            -- If the highlight already exists then assume the user doesn't want it to be
            -- overwritten
            if does_hl_exist and does_hl_exist:len() > 0 and not does_hl_exist:match("xxx%s+cleared") then
                return
            end

            -- Apply the dimmed highlight
            vim.api.nvim_set_hl(0, full_highlight_name, {
                [highlight.affect == "background" and "bg" or "fg"] = module.public.dim_color(
                    module.public.get_attribute(
                        highlight.reference or full_highlight_name,
                        highlight.affect or "foreground"
                    ),
                    highlight.percentage
                ),
            })
        end, "")
    end,

    --- Takes in a table of highlights and applies them to the current buffer
    ---@param highlights table #A table of highlights
    add_highlights = function(highlights)
        module.config.highlights =
            vim.tbl_deep_extend("force", module.config.highlights, highlights or {})
        module.public.trigger_highlights()
    end,

    --- Takes in a table of items to dim and applies the dimming to them
    ---@param dim table #A table of items to dim
    add_dim = function(dim)
        module.config.dim = vim.tbl_deep_extend("force", module.config.dim, dim or {})
        module.public.trigger_highlights()
    end,

    --- Assigns all Neorg* highlights to `clear`
    clear_highlights = function()
        --- Recursively descends down the highlight configuration and clears every highlight accordingly
        ---@param highlights table #The table of highlights to descend down
        ---@param prefix string #Should be only used by the function itself, acts as a "savestate" so the function can keep track of what path it has descended down
        local function descend(highlights, prefix)
            -- Loop through every defined highlight
            for hl_name, highlight in pairs(highlights) do
                -- If it is a table then recursively traverse down it!
                if type(highlight) == "table" then
                    descend(highlight, hl_name)
                else -- Otherwise we're dealing with a string
                    -- Hence we should clear the highlight
                    vim.cmd("highlight! clear Neorg" .. prefix .. hl_name)
                end
            end
        end

        -- Begin the descent
        descend(module.config.highlights, "")
    end,

    -- NOTE: Shamelessly taken and tweaked a little from akinsho's nvim-bufferline:
    -- https://github.com/akinsho/nvim-bufferline.lua/blob/fec44821eededceadb9cc25bc610e5114510a364/lua/bufferline/colors.lua
    -- <3
    get_attribute = function(name, attribute)
        -- Attempt to get the highlight
        local success, hl = pcall(vim.api.nvim_get_hl_by_name, name, true)

        -- If we were successful and if the attribute exists then return it
        if success and hl[attribute] then
            return bit.tohex(hl[attribute], 6)
        else -- Else log the message in a regular info() call, it's not an insanely important error
            neorg.log.info("Unable to grab highlight for attribute", attribute, " - full error:", hl)
        end

        return "NONE"
    end,

    dim_color = function(colour, percent)
        if colour == "NONE" then
            return colour
        end

        local function hex_to_rgb(hex_colour)
            return tonumber(hex_colour:sub(1, 2), 16),
                tonumber(hex_colour:sub(3, 4), 16),
                tonumber(hex_colour:sub(5), 16)
        end

        local function alter(attr)
            return math.floor(attr * (100 - percent) / 100)
        end

        local r, g, b = hex_to_rgb(colour)

        if not r or not g or not b then
            return "NONE"
        end

        return string.format("#%02x%02x%02x", math.min(alter(r), 255), math.min(alter(g), 255), math.min(alter(b), 255))
    end,

    -- END of shamelessly ripped off akinsho code
}

module.events.subscribed = {
    ["core.autocommands"] = {
        colorscheme = true,
        bufenter = true,
    },
}

return module

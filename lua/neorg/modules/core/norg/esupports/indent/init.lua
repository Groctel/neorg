--[[
    File: Indent
    Title: Proper Indents with `core.norg.esupports.indent`
    Summary: A set of instructions for Neovim to indent Neorg documents.
    ---
--]]

local neorg = require("neorg.core")
local modules = require("neorg.modules")
local module = modules.create("core.norg.esupports.indent")
local require_relative = require("neorg.utils").require_relative

module.setup = function()
    return {
        requires = {
            "core.integrations.treesitter",
            "core.autocommands",
        },
    }
end

module.public = {
    indentexpr = function(buf, line, node)
        line = line or (vim.v.lnum - 1)
        node = node or module.required["core.integrations.treesitter"].get_first_node_on_line(buf, line)

        if not node then
            return 0
        end

        local indent_data = module.config.indents[node:type()] or module.config.indents._

        if not indent_data then
            return 0
        end

        local _, initial_indent = node:start()

        local indent = 0

        for _, modifier in ipairs(indent_data.modifiers or {}) do
            if module.config.modifiers[modifier] then
                local ret = module.config.modifiers[modifier](buf, node, line, initial_indent)

                if ret ~= 0 then
                    indent = ret
                end
            end
        end

        local line_len = (vim.api.nvim_buf_get_lines(buf, line, line + 1, true)[1] or ""):len()

        -- Ensure that the cursor is within the `norg` language
        local current_lang = vim.treesitter.get_parser(buf, "norg"):language_for_range({
            line,
            line_len,
            line,
            line_len,
        })

        -- If it isn't then fall back to `nvim-treesitter`'s indent instead.
        if current_lang:lang() ~= "norg" then
            -- If we're in a ranged tag then apart from providing nvim-treesitter indents also make sure
            -- to account for the indentation level of the tag itself.
            if node:type() == "ranged_verbatim_tag_content" then
                local lnum = line
                local start = node:range()

                while lnum > start do
                    if vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]:match("^%s*$") then
                        lnum = lnum - 1
                    else
                        return vim.fn["nvim_treesitter#indent"]()
                    end
                end

                return module.required["core.integrations.treesitter"].get_node_range(node:parent()).column_start
                    + vim.fn["nvim_treesitter#indent"]()
            else
                return vim.fn["nvim_treesitter#indent"]()
            end
        end

        -- Indents can be a static value, so account for that here
        if type(indent_data.indent) == "number" then
            -- If the indent is -1 then let Neovim indent instead of us
            if indent_data.indent == -1 then
                return -1
            end

            return indent + indent_data.indent + (module.config.tweaks[node:type()] or 0)
        end

        local calculated_indent = indent_data.indent(buf, node, line, indent, initial_indent) or 0

        if calculated_indent == -1 then
            return -1
        end

        return indent + calculated_indent + (module.config.tweaks[node:type()] or 0)
    end,
}


module.config = require_relative(..., "config")


module.load = function()
    module.required["core.autocommands"].enable_autocommand("BufEnter")
end

module.on_event = function(event)
    if event.name == "bufenter" and event.payload.norg then
        vim.api.nvim_buf_set_option(
            event.buffer,
            "indentexpr",
            -- FIXME: Not a global anymore!
            ("v:lua.neorg.modules.get_module('core.norg.esupports.indent').indentexpr(%d)"):format(event.buffer)
        )

        local indentkeys = "o,O,*<M-o>,*<M-O>"
            .. neorg.lib.when(module.config.format_on_enter, ",*<CR>", "")
            .. neorg.lib.when(module.config.format_on_escape, ",*<Esc>", "")
        vim.api.nvim_buf_set_option(event.buffer, "indentkeys", indentkeys)
    end
end

module.events.subscribed = {
    ["core.autocommands"] = {
        bufenter = true,
    },
}

return module

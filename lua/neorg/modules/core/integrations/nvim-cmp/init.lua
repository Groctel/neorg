--[[
    File: Nvim-Cmp
    Title: Integrating Neorg with `nvim-cmp`
    Summary: A module for integrating nvim-cmp with Neorg.
    Internal: true
    ---

This module works with the `core.norg.completion` module to attempt to provide
intelligent completions. Note that integrations like this are second-class
citizens and may not work in 100% of scenarios. If they don't then please file
a bug report!

After setting up `core.norg.completion` with the `engine` set to `nvim-cmp`,
make sure to also set up "neorg" as a source in `nvim-cmp`:
```lua
sources = {
    { name = "neorg" },
},
```
--]]

local neorg = require("neorg.core")
local modules = require("neorg.modules")
local module = modules.create("core.integrations.nvim-cmp")

local this = {
    source = {},
    cmp = {},
    completions = {},
}

module.load = function()
    local success, cmp = pcall(require, "cmp")

    if not success then
        neorg.log.fatal("nvim-cmp not found, aborting...")
        return
    end

    this.cmp = cmp
end

---@class core.integrations.nvim-cmp
module.public = {
    create_source = function()
        this.completion_item_mapping = {
            Directive = this.cmp.lsp.CompletionItemKind.Keyword,
            Tag = this.cmp.lsp.CompletionItemKind.Keyword,
            Language = this.cmp.lsp.CompletionItemKind.Property,
            TODO = this.cmp.lsp.CompletionItemKind.Event,
            Property = this.cmp.lsp.CompletionItemKind.Property,
            Format = this.cmp.lsp.CompletionItemKind.Property,
            Embed = this.cmp.lsp.CompletionItemKind.Property,
        }

        this.source.new = function()
            return setmetatable({}, { __index = this.source })
        end

        function this.source.complete(_, request, callback)
            local abstracted_context = module.public.create_abstracted_context(request)

            local completion_cache = module.public.invoke_completion_engine(abstracted_context)

            if completion_cache.options.pre then
                completion_cache.options.pre(abstracted_context)
            end

            local completions = vim.deepcopy(completion_cache.items)

            for index, element in ipairs(completions) do
                local word = element
                local label = element
                if type(element) == "table" then
                    word = element[1]
                    label = element.label
                end
                completions[index] = {
                    word = word,
                    label = label,
                    kind = this.completion_item_mapping[completion_cache.options.type],
                }
            end

            callback(completions)
        end

        function this.source:get_trigger_characters()
            return { "@", "-", "(", " ", "." }
        end

        this.cmp.register_source("neorg", this.source)
    end,

    create_abstracted_context = function(request)
        return {
            start_offset = request.offset,
            char = request.context.cursor.character,
            before_char = request.completion_context.triggerCharacter,
            line = request.context.cursor_before_line,
            column = request.context.cursor.col,
            buffer = request.context.bufnr,
            line_number = request.context.cursor.line,
            previous_context = {
                line = request.context.prev_context.cursor_before_line,
                column = request.context.prev_context.cursor.col,
                start_offset = request.offset,
            },
            full_line = request.context.cursor_line,
        }
    end,
}

return module

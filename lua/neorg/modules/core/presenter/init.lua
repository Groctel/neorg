--[[
    File: Core-Presenter
    Title: Powerpoint-like for Neorg
    Summary: Neorg module to create gorgeous presentation slides.
    ---
--]]

local neorg = require("neorg.core")
local modules = require("neorg.modules")
local module = modules.create("core.presenter")
local api = vim.api
local require_relative = require("neorg.utils").require_relative


local this = {
    data = {},
    nodes = {},
    buf = nil,
    current_page = 1,
}


module.setup = function()
    return {
        success = true,
        requires = {
            "core.queries.native",
            "core.integrations.treesitter",
            "core.ui",
            "core.mode",
            "core.keybinds",
            "core.neorgcmd",
        },
    }
end

module.load = function()
    local error_loading = false

    ---@type core.keybinds
    ---@diagnostic disable-next-line: unused-local
    local keybinds = module.required["core.keybinds"]

    if module.config.zen_mode == "truezen" then
        modules.load_module("core.integrations.truezen", module.name)
    elseif module.config.zen_mode == "zen-mode" then
        modules.load_module("core.integrations.zen_mode", module.name)
    else
        neorg.log.error("Unrecognized mode for 'zen_mode' option. Please check your presenter config")
        error_loading = true
    end

    if error_loading then
        return
    end

    keybinds.register_keybinds(module.name, { "next_page", "previous_page", "close" })
    -- Add neorgcmd capabilities
    module.required["core.neorgcmd"].add_commands_from_table({
        presenter = {
            args = 1,
            condition = "norg",
            subcommands = {
                start = { args = 0, name = "presenter.start" },
                close = { args = 0, name = "presenter.close" },
            },
        },
    })
end

module.config = require_relative(..., "config")


---@class core.presenter
module.public = {
    version = "0.0.8",
    present = function()
        if this.buf then
            neorg.log.warn("Presentation already started")
            return
        end
        ---@type core.queries.native
        local queries = module.required["core.queries.native"]

        -- Get current file and check if it's a norg one
        local uri = vim.uri_from_bufnr(0)
        local fname = vim.uri_to_fname(uri)

        if string.sub(fname, -5, -1) ~= ".norg" then
            neorg.log.error("Not on a norg file")
            return
        end

        local tree = {
            {
                query = { "all", "heading1" },
                recursive = true,
            },
        }
        -- Free the text in memory after reading nodes
        queries.delete_content(0)

        local results = queries.query_nodes_from_buf(tree, 0)

        if vim.tbl_isempty(results) then
            neorg.log.warn("Could not generate the presenter mode (no heading1 present on this file)")
            return
        end

        this.nodes = results
        results = queries.extract_nodes(results, { all_lines = true })

        results = this.remove_blanklines(results)

        -- This is a temporary fix because querying the heading1 nodes seems to query the next heading1 node too !
        for _, res in pairs(results) do
            if vim.startswith(res[#res], "* ") then
                res[#res] = nil
            end
        end

        if
            module.config.zen_mode == "truezen" and modules.is_module_loaded("core.integrations.truezen")
        then
            modules.get_module("core.integrations.truezen").toggle_ataraxis()
        elseif
            module.config.zen_mode == "zen-mode" and modules.is_module_loaded("core.integrations.zen_mode")
        then
            modules.get_module("core.integrations.zen_mode").toggle()
        end

        -- Generate views selection popup
        local buffer =
            module.required["core.ui"].create_norg_buffer("Norg Presenter", "nosplit", nil, { keybinds = false })

        api.nvim_buf_set_option(buffer, "modifiable", true)
        api.nvim_buf_set_lines(buffer, 0, -1, false, results[1])
        api.nvim_buf_call(buffer, function()
            vim.cmd("set scrolloff=999")
        end)

        api.nvim_buf_set_option(buffer, "modifiable", false)

        module.required["core.mode"].set_mode("presenter")
        this.buf = buffer
        this.data = results
    end,

    next_page = function()
        if vim.tbl_isempty(this.data) or not this.buf then
            return
        end

        if vim.tbl_count(this.data) == this.current_page then
            api.nvim_buf_set_option(this.buf, "modifiable", true)
            api.nvim_buf_set_lines(this.buf, 0, -1, false, { "Press `next` again to close..." })
            api.nvim_buf_set_option(this.buf, "modifiable", false)
            this.current_page = this.current_page + 1
            return
        elseif vim.tbl_count(this.data) < this.current_page then
            module.public.close()
            return
        end

        this.current_page = this.current_page + 1

        api.nvim_buf_set_option(this.buf, "modifiable", true)
        api.nvim_buf_set_lines(this.buf, 0, -1, false, this.data[this.current_page])
        api.nvim_buf_set_option(this.buf, "modifiable", false)
    end,

    previous_page = function()
        if vim.tbl_isempty(this.data) or not this.buf then
            return
        end

        if this.current_page == 1 then
            return
        end

        this.current_page = this.current_page - 1

        api.nvim_buf_set_option(this.buf, "modifiable", true)
        api.nvim_buf_set_lines(this.buf, 0, -1, false, this.data[this.current_page])
        api.nvim_buf_set_option(this.buf, "modifiable", false)
    end,

    close = function()
        if not this.buf then
            return
        end

        -- Go back to previous mode
        local previous_mode = module.required["core.mode"].get_previous_mode()
        module.required["core.mode"].set_mode(previous_mode)

        if
            module.config.zen_mode == "truezen" and modules.is_module_loaded("core.integrations.truezen")
        then
            modules.get_module("core.integrations.truezen").toggle_ataraxis()
        elseif
            module.config.zen_mode == "zen-mode" and modules.is_module_loaded("core.integrations.zen_mode")
        then
            modules.get_module("core.integrations.zen_mode").toggle()
        end

        api.nvim_buf_delete(this.buf, {})
        this.data = {}
        this.current_page = 1
        this.buf = nil
        this.nodes = {}
    end,
}

this = {
    remove_blanklines = function(t)
        local copy = t
        for k, _t in pairs(copy) do
            -- Stops at the first non-blankline text
            local found_non_blankline = false

            for i = #_t, 1, -1 do
                if not found_non_blankline then
                    local value = _t[i]
                    value = string.gsub(value, "%s*", "")
                    if value == "" then
                        table.remove(copy[k], i)
                    else
                        found_non_blankline = true
                    end
                end
            end
        end
        return copy
    end,
}

module.on_event = function(event)
    if vim.tbl_contains({ "core.neorgcmd", "core.keybinds" }, event.referrer.name) then
        if vim.tbl_contains({ "presenter.start" }, event.name) then
            module.public.present()
        elseif vim.tbl_contains({ "presenter.close", "core.presenter.close" }, event.name) then
            module.public.close()
        elseif vim.tbl_contains({ "core.presenter.previous_page" }, event.name) then
            module.public.previous_page()
        elseif vim.tbl_contains({ "core.presenter.next_page" }, event.name) then
            module.public.next_page()
        end
    end
end

module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["presenter.start"] = true,
        ["presenter.close"] = true,
    },
    ["core.keybinds"] = {
        ["core.presenter.previous_page"] = true,
        ["core.presenter.next_page"] = true,
        ["core.presenter.close"] = true,
    },
}

return module

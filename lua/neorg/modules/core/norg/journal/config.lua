---@class mod.norg.journal.config
local config = {
    -- which workspace to use for the journal files, default is the current
    workspace = nil,
    -- the name for the folder in which the journal files are put
    journal_folder = "journal",

    -- The strategy to use to create directories
    -- can be "flat" (2022-03-02.norg), "nested" (2022/03/02.norg),
    -- a lua string with the format given to `os.date()` or a lua function
    -- that returns a lua string with the same format.
    strategy = "nested",

    -- the name of the template file
    template_name = "template.norg",
    -- use your journal_folder template
    use_template = true,

    -- formatter function used to generate the toc file
    -- receives a table that contains tables like { yy, mm, dd, link, title }
    -- must return a table of strings
    toc_format = nil,
}


return config

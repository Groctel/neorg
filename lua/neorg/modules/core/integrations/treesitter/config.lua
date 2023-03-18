---@class mod.integrations.treesitter.config
local config = {
    --- If true will auto-configure the parsers to use the recommended setup.
    --  Sometimes `nvim-treesitter`'s repositories lag behind and this is the only good fix.
    configure_parsers = true,

    --- If true will automatically install parsers if they are not present.
    install_parsers = true,

    --- Configurations for each parser as expected by `nvim-treesitter`.
    --  If you want to tweak your parser configs you can do so here.
    parser_configs = {
        norg = {
            url = "https://github.com/nvim-neorg/tree-sitter-norg",
            files = { "src/parser.c", "src/scanner.cc" },
            branch = "main",
            revision = "6348056b999f06c2c7f43bb0a5aa7cfde5302712",
        },
        norg_meta = {
            url = "https://github.com/nvim-neorg/tree-sitter-norg-meta",
            files = { "src/parser.c" },
            branch = "main",
            revision = "e93dcbc56a472649547cfc288f10ae4a93ef8795",
        },
    },
}


return config

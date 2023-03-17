local examples = {}


-- TODO: Check if the example is still correct
examples["Get the content of all todo_item1 in a norg file"] = function()
    local buf = 1 -- The buffer to query informations

    --- @type core.queries.native.tree_node[]
    local tree = {
        {
            query = { "first", "document_content" },
            subtree = {
                {
                    query = { "all", "generic_list" },
                    recursive = true,
                    subtree = {
                        {
                            query = { "all", "todo_item1" },
                        },
                    },
                },
            },
        },
    }

    -- Get a list of { node, buf }
    local nodes = module.required["core.queries.native"].query_nodes_from_buf(tree, buf)
    local extracted_nodes = module.required["core.queries.native"].extract_nodes(nodes)

    -- Free the text in memory after reading nodes
    module.required["core.queries.native"].delete_content(buf)

    print(nodes, extracted_nodes)
end


return examples

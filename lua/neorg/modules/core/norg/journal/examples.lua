local examples = {}


-- TODO: Check if the example is still correct
examples["Changing TOC format to divide year in quarters"] = function()
    -- In your ["core.norg.journal"] options, change toc_format to a function like this:

    require("neorg").setup({
        load = {
            -- ...
            ["core.norg.journal"] = {
                config = {
                    -- ...
                    toc_format = function(entries)
                        -- Convert the entries into a certain format

                        local output = {}
                        local current_year
                        local current_quarter
                        local last_quarter
                        local current_month
                        for _, entry in ipairs(entries) do
                            -- Don't print the year if it hasn't changed
                            if not current_year or current_year < entry[1] then
                                current_year = entry[1]
                                table.insert(output, "* " .. current_year)
                            end

                            -- Check to which quarter the current month corresponds to
                            if entry[2] <= 3 then
                                current_quarter = 1
                            elseif entry[2] <= 6 then
                                current_quarter = 2
                            elseif entry[2] <= 9 then
                                current_quarter = 3
                            else
                                current_quarter = 4
                            end

                            -- If the current month corresponds to another quarter, print it
                            if current_quarter ~= last_quarter then
                                table.insert(output, "** Quarter " .. current_quarter)
                                last_quarter = current_quarter
                            end

                            -- Don't print the month if it hasn't changed
                            if not current_month or current_month < entry[2] then
                                current_month = entry[2]
                                table.insert(output, "*** Month " .. current_month)
                            end

                            -- Prints the file link
                            table.insert(output, entry[4] .. string.format("[%s]", entry[5]))
                        end

                        return output
                    end,
                    -- ...
                },
            },
        },
    })
end


return examples

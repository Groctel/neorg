--[[
--    HELPER FUNCTIONS FOR NEORG
--    This file contains some simple helper functions to improve QOL
--]]

local lib = {}


--- Returns the item that matches the first item in statements
---@param value any #The value to compare against
---@param compare? function #A custom comparison function
---@return function #A function to invoke with a table of potential matches
lib.match = function(value, compare)
    -- Returning a function allows for such syntax:
    -- match(something) { ..matches.. }
    return function(statements)
        if value == nil then
            return
        end

        -- Set the comparison function
        -- A comparison function may be required for more complex
        -- data types that need to be compared against another static value.
        -- The default comparison function compares booleans as strings to ensure
        -- that boolean comparisons work as intended.
        compare = compare
            or function(lhs, rhs)
                if type(lhs) == "boolean" then
                    return tostring(lhs) == rhs
                end

                return lhs == rhs
            end

        -- Go through every statement, compare it, and perform the desired action
        -- if the comparison was successful
        for case, action in pairs(statements) do
            -- If the case statement is a list of data then compare that
            if type(case) == "table" and vim.tbl_islist(case) then
                for _, subcase in ipairs(case) do
                    if compare(value, subcase) then
                        -- The action can be a function, in which case it is invoked
                        -- and the return value of that function is returned instead.
                        if type(action) == "function" then
                            return action(value)
                        end

                        return action
                    end
                end
            end

            if compare(value, case) then
                -- The action can be a function, in which case it is invoked
                -- and the return value of that function is returned instead.
                if type(action) == "function" then
                    return action(value)
                end

                return action
            end
        end

        -- If we've fallen through all statements to check and haven't found
        -- a single match then see if we can fall back to a `_` clause instead.
        if statements._ then
            local action = statements._

            if type(action) == "function" then
                return action(value)
            end

            return action
        end
    end
end


--- Maps a function to every element of a table
--  The function can return a value, in which case that specific element will be assigned
--  the return value of that function.
---@param tbl table #The table to iterate over
---@param callback function #The callback that should be invoked on every iteration
---@return table #A modified version of the original `tbl`.
lib.map = function(tbl, callback)
    local copy = vim.deepcopy(tbl)

    for k, v in pairs(tbl) do
        local cb = callback(k, v, tbl)

        if cb then
            copy[k] = cb
        end
    end

    return copy
end

--- Iterates over all elements of a table and returns the first value returned by the callback.
---@param tbl table #The table to iterate over
---@param callback function #The callback function that should be invoked on each iteration.
--- Can return a value in which case that value will be returned from the `filter()` call.
---@return any|nil #The value returned by `callback`, if any
lib.filter = function(tbl, callback)
    for k, v in pairs(tbl) do
        local cb = callback(k, v)

        if cb then
            return cb
        end
    end
end


--- Tries to extract a variable in all nesting levels of a table.
---@param tbl table #The table to traverse
---@param value any #The value to look for - note that comparison is done through the `==` operator
---@return any|nil #The value if it was found, else nil
lib.extract = function(tbl, value)
    local results = {}

    for key, expected_value in pairs(tbl) do
        if key == value then
            table.insert(results, expected_value)
        end

        if type(expected_value) == "table" then
            vim.list_extend(results, lib.extract(expected_value, value))
        end
    end

    return results
end


--- Wraps a function in a callback
---@param function_pointer function #The function to wrap
---@vararg ... #The arguments to pass to the wrapped function
---@return function #The wrapped function in a callback
lib.wrap = function(function_pointer, ...)
    local params = { ... }

    if type(function_pointer) ~= "function" then
        local prev = function_pointer

        -- luacheck: push ignore
        function_pointer = function()
            return prev, unpack(params)
        end
        -- luacheck: pop
    end

    return function()
        return function_pointer(unpack(params))
    end
end


--- Repeats an arguments `index` amount of times
---@param value any #The value to repeat
---@param index number #The amount of times to repeat the argument
---@return ... #An expanded vararg with the repeated argument
lib.reparg = function(value, index)
    if index == 1 then
        return value
    end

    return value, lib.reparg(value, index - 1)
end

--- Lazily concatenates a string to prevent runtime errors where an object may not exist
--  Consider the following example:
--
--      str ~= nil and str .. " extra text" or ""
--
--  This would fail, simply because the string concatenation will still be evaluated in order
--  to be placed inside the variable. You may use:
--
--      str ~= nil and lib.lazy_string_concat(str, " extra text") or ""
--
--  To mitigate this issue directly.
--- @vararg string #An unlimited number of strings
---@return string #The result of all the strings concatenateA.
lib.lazy_string_concat = function(...)
    return table.concat({ ... })
end

--- Converts an array of values to a table of keys
---@param values string[]|number[] #An array of values to store as keys
---@param default any #The default value to assign to all key pairs
---@return table #The converted table
lib.to_keys = function(values, default)
    local ret = {}

    for _, value in ipairs(values) do
        ret[value] = default or {}
    end

    return ret
end


--- Constructs a new key-pair table by running a callback on all elements of an array.
---@param keys string[] #A string array with the keys to iterate over
---@param cb function #A function that gets invoked with each key and returns a value to be placed in the output table
---@return table #The newly constructed table
lib.construct = function(keys, cb)
    local result = {}

    for _, key in ipairs(keys) do
        result[key] = cb(key)
    end

    return result
end


--- Converts a table with `key = value` pairs to a `{ key, value }` array.
---@param tbl_with_keys table #A table with key-value pairs
---@return table<any, any> #An array of `{ key, value }` pairs.
lib.unroll = function(tbl_with_keys)
    local res = {}

    for key, value in pairs(tbl_with_keys) do
        table.insert(res, { key, value })
    end

    return res
end


--- Works just like pcall, except returns only a single value or nil (useful for ternary operations
--  which are not possible with a function like `pcall` that returns two values).
---@param func function #The function to invoke in a protected environment
---@vararg any #The parameters to pass to `func`
---@return any|nil #The return value of the executed function or `nil`
lib.inline_pcall = function(func, ...)
    local ok, ret = pcall(func, ...)

    if ok then
        return ret
    end

    -- return nil
end


return lib

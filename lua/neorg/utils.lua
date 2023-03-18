local utils = {}


--- Requires the contents of a module relative to a root path
--- Inspired by from https://stackoverflow.com/a/9146653
---@param root string #Root of the relative path to look from. Use `...` to require relative to the file's current path
---@param path string #The require path relative to the caller's root
---@param prune boolean? #Whether the last item of the path should be pruned
---@return any #The module loaded from the relative path
function utils.require_relative(root, path, prune)
    root = prune and root:match("(.-)%.[^%.]+$") or root
    return require(root.."."..path)
end


return utils

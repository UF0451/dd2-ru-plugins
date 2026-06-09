--========================================================--
-- SafeCall.lua
-- Author: Wandd3rer
-- Purpose: Safely calls a method on a manager that may be nil,
--          with method caching and fallback defaults.
--========================================================--

local M = {}

-- key: type_definition
-- value: {["method_name"] = method_object}
local method_cache = setmetatable({}, { __mode = "k" }) -- weak keys


-- Fetches a method by name from the object’s type definition.
-- Caches the result so the lookup happens only once.
-- Note that method = obj:get_type_definition():get_method(method_name)
-- @param obj singleton Manager (may be nil).
-- @param method_name string Method name.
local function get_cached_method(obj, method_name)
    if not obj then return nil end

    local td = obj:get_type_definition()
    if not td then return nil end

    -- Gets cache bucket for this type
    local bucket = method_cache[td]
    if not bucket then
        bucket = {}
        method_cache[td] = bucket
    end

    -- Returns from cache if already resolved
    if bucket[method_name] then
        return bucket[method_name]
    end

    -- Resolves and caches the method
    local method = td:get_method(method_name)
    bucket[method_name] = method

    return method
end


-- Calls a method on an object that might be nil.
-- @param obj singleton Manager (may be nil).
-- @param method_name string Method name (ex: "isPausedAny").
-- @param default any Value to return if obj is nil or method fails.
-- @param args table List of arguments required by the method.
-- @return any Value returned by the method.
function M.call(obj, method_name, default, args)
    if not obj then
        return default
    end

    local method = get_cached_method(obj, method_name)

    -- Fallbacks if method does not exist on this object
    if not method then
        return default
    end

    -- Protects against engine calls that may throw errors
    args = args or {}
    local ok, result = pcall(method, obj, table.unpack(args))
    if not ok then
        return default
    end

    -- Fallbacks as well if the method returns nil
    if result == nil then
        return default
    end

    return result
end


-- Convenience boolean call.
-- Default is always `false` for boolean checks.
function M.bool(obj, method_name, args)
    return M.call(obj, method_name, false, args)
end

return M
--========================================================--
-- Managers.lua
-- Author: Wandd3rer
-- Purpose: Unified access to game managers
--========================================================--

local Managers = {}

-- Internal cache
local _cache = {}


-- Generic getter
function Managers:get(name)
    local m = _cache[name]
    if not m or m == nil then
        m = sdk.get_managed_singleton(name)
        _cache[name] = m
        if not m then
            log.warn(string.format("[Managers] Manager not found: %s", name))
        end
    end
    return m
end


-- Shortcut helpers
function Managers:character() return self:get("app.CharacterManager") end
function Managers:item() return self:get("app.ItemManager") end
function Managers:player()
    local cm = self:character()
    if cm then
        return cm:get_ManualPlayer()
    end
    return nil
end

return Managers
local common = require("EnemySpawner/common")
local enumHelper = common.enumHelper
local ns = common.nativeSimple

local input = {}
input.enums = {}
input.devices = {
    ["kb"] = {
        ["enum"] = "via.hid.KeyboardKey", 
        ["type"] = "via.hid.Keyboard", 
        ["init"] = "get_Device"},
    ["ms"] = {
        ["enum"] = "via.hid.MouseButton", 
        ["type"] = "via.hid.Mouse", 
        ["init"] = "get_Device"},
    ["gp"] = {
        ["enum"] = "via.hid.GamePadButton", 
        ["type"] = "via.hid.GamePad", 
        ["init"] = "get_Device"}
}
input.states = {
    "UP",
    "TRIGGER",
    "DOWN",
    "RELEASE"
}
input.loadEnums = function(self)
    for nm,p in pairs(self.devices) do 
        self.enums[nm] = enumHelper:getTranslations(p["enum"])
    end
end

input.state = {}
input.initState = function(self)
    for k,v in pairs(input.devices) do 
        self.state[k] = {['NULL'] = 0}
    end
end

input.getState = function(self, dvc, k)
    if self.state[dvc] then 
        if not self.state[dvc][k] then 
            self.state[dvc][k] = 1
        end
        return self.state[dvc][k]
    end
    return 0
end
input.setState = function(self, dvc, k, s)
    if self.state and self.state[dvc] and self.state[dvc][k] then 
        self.state[dvc][k] = s
    end
end

input.init = function(self)
    self:loadEnums()
    self:initState()
    for nm,p in pairs(self.devices) do 
        self[nm] = {}
        self[nm]['dvc'] = ns:callFunc(p.type, p.init, p.args)
        for k,e in pairs(self.enums[nm]) do 
            self[nm][k] = e
        end
    end
end

input.update = function(self)
    for dvc,_ in pairs(self.devices) do 
        if self[dvc] then 
            for k,v in pairs(self.enums[self[dvc]]) do 
                self[dvc]:call("get_Button")
            end
        end
    end
end

input.isDownKb = function(self, k)
    if self.kb.dvc then
        if tonumber(k) then 
            return self.kb.dvc:call("isDown", tonumber(k))
        elseif self.kb.byName[k] then 
            return self.kb.dvc:call("isDown", self.kb.byName[k])
        end
    end 
    return false
end

input.checkState = function(self, dvc, k)
    local prevState = self:getState(dvc, k)
    local currState = nil
    local newState = nil
    if dvc == 'kb' then 
        currState = self:isDownKb(k)
    else 
        currState = self:isDownBitWise(dvc,k)
    end
    if currState then 
        if prevState <= 1 then 
            newState = 2
        else 
            newState = 3
        end 
    else 
        if prevState == 3 then 
            newState = 4
        else 
            newState = 1
        end 
    end
    self:setState(dvc,k,newState)
    return newState
end

input.checkStateName = function(self, dvc, k)
    local s = self:checkState(dvc,k)
    return self.states[s]
end

input.isDownBitWise = function(self, dvc, k)
    if self[dvc].dvc then 
        local bwKeyVal = self[dvc].byName[k]
        if bwKeyVal ~= nil then 
            local gbBitVal = self[dvc].dvc:get_Button()
            if gbBitVal & bwKeyVal ~=0 then
                return true
            end
        end
    end
    return false
end

input.isDownMs = function(self, k)
    return self:isDownBitWise('ms', k) 
end

input.isDownGp = function(self, k)
    return self:isDownBitWise('gp', k) 
end

return input

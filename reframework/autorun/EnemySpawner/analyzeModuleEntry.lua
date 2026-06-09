local common = require('common')
local modName = "AnalyzeModuleEntry"
local ModuleInstance = {}
ModuleInstance.__index = ModuleInstance
function ModuleInstance:new(name)
    local mi = {}
    setmetatable(mi,ModuleInstance)
    mi.name = name or nil
    mi.callCount = 0
    return mi
end
ModuleInstance.increment = function(self)
    self.callCount = self.callCount + 1
end
ModuleInstance.getCallCount = function(self)
    return self.callCount
end

local MethodInstance = ModuleInstance:new()
MethodInstance.__index = MethodInstance
function MethodInstance:new(_class, _method)
    local fi = {}
    setmetatable(fi, ModuleInstance)
    fi.cls = _class or nil
    fi.method = _method or nil
    return fi 
end


local AnalyzeModuleEntry = {}
AnalyzeModuleEntry.__index = AnalyzeModuleEntry
function AnalyzeModuleEntry:new(tm)
    local ame = {}
    setmetatable(ame, AnalyzeModuleEntry)
    ame.tm = tm or nil
    ame.ModuleEntryList = common.enumHelper:getTranslations('via.ModuleEntry')
    ame.trackedList = {}
    return ame
end

AnalyzeModuleEntry.toast = function(self,msg,_type) 
    if self.tm then 
        self.tm:toast("[AME] "..msg, _type)
    end
end
AnalyzeModuleEntry.trackModuleInstance = function(self, name)
    if name then 
        table.insert(self.trackedList, ModuleInstance:new(name))
        self:toast("updateTrackedList " .. tostring(name) .. " LEN: " .. tostring(#self.trackedList))
    end
end
AnalyzeModuleEntry.trackMethodInstance = function(self, cls, mth)
    if cls and mth then
        table.insert(self.trackedMethodList, MethodInstance:new(cls,mth))
        self:toast("updateTrackedMethodList " .. cls .. "." .. mth .. " LEN: " .. tostring(#self.trackedList))
    end
end

AnalyzeModuleEntry.setupHooks = function(self,_start,_end)
    local _start = _start or -1
    local _end = _end or 99999
    for i,name in pairs(self.ModuleEntryList.byIndex) do 
        if i >= _start and i <= _end then
            self:trackModuleInstance(name)
        end
    end
    for _,mi in pairs(self.trackedList) do 
        re.on_application_entry(mi.name, function() mi:increment() end)
    end
end

AnalyzeModuleEntry.setupMethodHooks = function(self,clsList)

local ame = AnalyzeModuleEntry:new()
ame:setupHooks()
local hidCount = 0
local function incrHIDCount() 
    hidCount = hidCount + 1
end
re.on_pre_application_entry("UpdateHID", incrHIDCount)

re.on_draw_ui(function()
    if imgui.tree_node(modName) then
        if ame and #ame.trackedList > 0 then 
            if imgui.collapsing_header("ON_APPLICATION_ENTRY") then 
                imgui.begin_table("1",2,1,{200,200})
                imgui.table_next_row()
                    imgui.table_next_column()
                    imgui.text("CONTROL__UpdateHID")
                    imgui.table_next_column()
                    imgui.text(hidCount)
                for nm, mi in ipairs(ame.trackedList) do 
                    local cnt = mi:getCallCount()
                    if cnt and cnt > 0 then 
                        imgui.table_next_row()
                        imgui.table_next_column()
                        imgui.text(mi.name)
                        imgui.table_next_column()
                        imgui.text(cnt)
                    end
                end
                imgui.end_table()
            end
        end
        imgui.tree_pop()
    end
end)

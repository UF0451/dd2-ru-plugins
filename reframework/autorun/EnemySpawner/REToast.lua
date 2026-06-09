--[[
Reframework toast ui 
]]

-- Toast - an individual toast message item
local Toast = {}
Toast.__index = Toast
-- INIT
function Toast:new(msg,style,lifetime,ease)
    local t = {}
    setmetatable(t, Toast)
    t.msg = msg or "default message"
    t.style = style or {
        ["name"] = "debug",
        ["color"] = 0xffffffff,
        ["bg"] = nil
    }
    t.lifetime = lifetime or 1000
    t.ease = ease or 0
    t.status = 1
    t.frameCount = 0
    return t
end

-- METHODS
function Toast:checkStatus()
    if self.ease < 1 then
        if self.frameCount < self.lifetime then 
            self.status = 3
        else 
            self.status = 5 
        end
    else 
        if self.frameCount < self.ease then 
            self.status = 2
        elseif self.frameCount < self.ease + self.lifetime then 
            self.status = 3
        elseif self.frameCount < self.ease * 2 + self.lifetime then 
            self.status = 4
        else
            self.status = 5
        end
    end
    self.frameCount = self.frameCount + 1
end
-- display this toast object on screen using draw
function Toast:show()
    imgui.text_colored(self.msg, self.style.color)
end
function Toast:update()
    self:checkStatus()
    self:show()
end

-- Bread - an individual permanent toast message
local Bread = {}
Bread.__index = Bread
-- INIT
function Bread:new(msg,style)
    local b = {}
    setmetatable(b, Toast)
    b.msg = msg or "default message"
    b.style = style or {
        ["name"] = "debug",
        ["color"] = 0xffffffff,
        ["bg"] = nil
    }
    return b
end

-- ToastManager - a controller to create and manage Toast items
local ToastManager = {}
ToastManager.__index = ToastManager
-- INIT
function ToastManager:new(showLevel,lifetime,ease,width)
    local tm = {}
    setmetatable(tm, ToastManager)
    -- ATTRIBUTES
    tm.hide = false
    tm.showLevel = showLevel or 0
    tm.items = {}
    tm.breadItems = {}
    tm.display = nil 
    tm.config = {
        ["types"] = {
            {["name"] = "debug", ["color"] = 0xff888888, ["bg"] = nil},
            {["name"] = "normal", ["color"] = 0xffffffff, ["bg"] = nil},
            {["name"] = "success", ["color"] = 0xff00ff00, ["bg"] = nil},
            {["name"] = "warning", ["color"] = 0xff00ffff, ["bg"] = nil},
            {["name"] = "fail", ["color"] = 0xff0000ff, ["bg"] = nil},
            {["name"] = "info", ["color"] = 0xffff0000, ["bg"] = nil},
            {["name"] = "alert", ["color"] = 0xffff00ff, ["bg"] = nil},
            {["name"] = "none", ["color"] = 0x00000000, ["bg"] = nil},
        },
        ["lifetime"] = lifetime or 1000,
        ["ease"] = ease or 0,
        ["retain"] = 100,
        ["anchor"] = {
            ["type"] = 1,
            ["x"] = 0,
            ["y"] = 0
        },
        ["width"] = width or 4
    }
    tm.DEBUG = 1
    tm.GREY = 1
    tm.NORMAL = 2
    tm.DEFAULT = 2
    tm.WHITE = 2
    tm.SUCCESS = 3
    tm.GREEN = 3
    tm.WARNING = 4
    tm.YELLOW = 4
    tm.RED = 5
    tm.FAIL = 5
    tm.ERROR = 5
    tm.BLUE = 6
    tm.INFO = 6
    tm.PURPLE = 7
    tm.ALERT = 7
    tm.BLANK = 8
    tm.NONE = 8
    return tm
end

-- METHODS
ToastManager.isShow = function(self, lvl)
    if lvl and lvl >= self.showLevel then 
        return true
    end
    return false
end
ToastManager.appendTable = function(self,t)
    if self.items and #self.items > self.config.retain then 
        table.remove(self.items, 1)
    end
    table.insert(self.items, t)
end
ToastManager.toast = function(self, msg, _t, lifetime, ease)
    local _type = _t or 2
    if self:isShow(_type) then 
        local typeDef = self.config.types[_type]
        local lifetime = lifetime or self.config.lifetime
        local ease = ease or self.config.ease
        local t = Toast:new(msg, typeDef, lifetime, ease)
        self:appendTable(t)
    end
end
ToastManager.bread = function(self, msg, _t)
    local _type = _t or 2
    if self:isShow(_type) then 
        local _typeDef = self.config.types[_type]
        local b = Bread:new(msg, _typeDef)
        table.insert(self.breadItems, b)
    end
end
ToastManager.getAll = function(self)
    return self.items 
end
ToastManager.getActive = function(self)
    local _buffer = {}
    for i,t in ipairs(self.items) do
        if t and t.status < 5 then 
            table.insert(_buffer, t)
        end
    end
    return _buffer 
end
ToastManager.update = function(self)
    if self.display then 
        imgui.set_next_window_pos({10, 10})
        imgui.set_next_window_size({self.display.x / self.config.width, self.display.y - 10})
        imgui.begin_window("Toast", nil, 471999)
        local buffer = self:getActive()
        if #buffer > 0 then
            for _,t in ipairs(buffer) do t:update() end
        end
        imgui.end_window()
        -- bread
        if #self.breadItems > 0 then 
            imgui.set_next_window_pos({self.display.x - (self.display.x / self.config.width +10), 10})
            imgui.set_next_window_size({self.display.x / self.config.width, self.display.y - 10})
            imgui.begin_window("Bread", nil, 471999)
            for _,b in ipairs(self.breadItems) do b:show() end
            imgui.end_window()
            self.breadItems = {}
        end

    else 
        self.display = imgui.get_display_size()
    end
end

ToastManager.showAll = function(self)
    for _,t in ipairs(self:getAll()) do t:show() end
end

return ToastManager
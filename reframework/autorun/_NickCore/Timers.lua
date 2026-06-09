local fns = require("_NickCore/Functions")
local p = require("_NickCore/Properties")

local timers = {}
local active = {}

local index = 0
function timers.set_timer(delay,fn)
	local start = p.gameTime
	local key = "Timer" .. index
	index = index + 1
	
	active[key] = fn
	fns.on_frame[key] = function()		
		if not active[key] then return end
		
		if p.gameTime - start > delay then
			local callback = active[key]
			active[key] = nil
			fns.on_frame[key] = nil
			callback()
		end
	end
	return key
end

function timers.cancel_timer(key)
	active[key] = nil
	fns.on_frame[key] = nil
end

function timers.end_timer(key)
	local callback = active[key]
    if not callback then return end

    active[key] = nil
    fns.on_frame[key] = nil
    callback()
end

return timers
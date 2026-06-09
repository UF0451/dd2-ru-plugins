local config = require("UDD2P/Config")
local h = require("UDD2P/Helpers")
if not config.BATTAHLI_GUARDS_TWEAK then return end

local TimeManager = sdk.get_managed_singleton("app.TimeManager")
local TimeSkipManager = sdk.get_managed_singleton("app.TimeSkipManager")

local function create_universal_position(position)
    local pos = ValueType.new(sdk.find_type_definition('via.Position'))
    pos.x = position.x or position[1]
    pos.y = position.y or position[2]
    pos.z = position.z or position[3]
    return pos
end

local function warp_player(position,time_hour,time_min,time_day)
    local now_hr = TimeManager:get_InGameHour()
    local now_min = TimeManager:get_InGameMinute()
    local now_day = TimeManager:get_InGameDay()

    local end_hr = now_hr
    local end_min = now_min
    local end_day = now_day

	if time_day == nil or time_hour == nil then
		if time_min == nil then time_min = now_min end
	else
		if time_min == nil then time_min = 0 end
	end
	if time_day == nil or time_day < now_day then time_day = now_day end
	if time_hour == nil then time_hour = now_hr end

	if time_day == now_day and (time_hour < now_hr or (time_hour == now_hr and time_min <= now_min)) then
		end_day = end_day + 1
	end
	end_hr = time_hour
	end_min = time_min
    TimeSkipManager:call('requestPlayerWarp', end_hr, end_min, end_day, position,Quaternion.new(0.79918038845062,0.0,-0.60109132528305,0.0), nil, true, true)
end

local kickGuids = {
	["bd690dc3-3806-4bf0-86bc-70a46a25a515"] = "What business have you\nhere?",
	["2ca921b2-a004-4ed7-b493-12701f3253f4"] = "What do you think you're\ndoing here?",
	["f0217081-2eac-4ec0-8b05-2d5017463a27"] = "What business have you\nhere?",
	["b1afc03c-096c-4c7a-bfdf-c9431c7dbc3e"] = "What do you think you're\ndoing here?",
}

sdk.hook(
	sdk.find_type_definition("app.TalkEventPlayer"):get_method("isNextSubtitleTriggered"),
	function(args)
		local storage = thread.get_hook_storage()
		local this = sdk.to_managed_object(args[2])
		local currentNode = this._CurrentNode
		local nodeType = currentNode._NodeType
		if nodeType ~= 10 then return end -- Common NPC talk
		local guid = this._CurrentSpeaker["<CurrentMsgId>k__BackingField"]
		if not guid then return end
		storage.guidString = guid:ToString()
	end,
	function(retval)
		local guidString = thread.get_hook_storage().guidString
		local isFinish = sdk.to_int64(retval) & 1 == 1
		if kickGuids[guidString] and isFinish and h.get_now_area() == 113 then
			local pos = create_universal_position({-1443.7788772583,107.56834411621,387.13031768799})
			warp_player(pos)
		end
		return retval
	end
)
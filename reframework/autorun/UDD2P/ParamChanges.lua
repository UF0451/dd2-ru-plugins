local config = require("UDD2P/Config")
local fns = require("_NickCore/Functions")

local CharacterManager = sdk.get_managed_singleton("app.CharacterManager") 
local ItemManager = sdk.get_managed_singleton("app.ItemManager") 
local WeatherManager = sdk.get_managed_singleton("app.WeatherManager")
local SuddenQuestManager = sdk.get_managed_singleton("app.SuddenQuestManager")

-- Splits a dotted path string into keys, converting numeric strings to numbers
local function split_path(path)
    local keys = {}
    for key in string.gmatch(path, "[^%.]+") do
        local num = tonumber(key)
        table.insert(keys, num or key)
    end
    return keys
end

local function safe_get_path(root, path)
	local keys = split_path(path)
	local current = root
	for _, key in ipairs(keys) do
		if not current[key] then
            return false
        end
        current = current[key]
	end
	return current
end

local function safe_set_path(root, path, value)
    local keys = split_path(path)
    local current = root
    for i = 1, #keys - 1 do
        local key = keys[i]
        if not current[key] then
            return false
        end
        current = current[key]
    end
    current[keys[#keys]] = value
    return true
end

local function apply_param_override(root, path, overrideTable)
	local target = safe_get_path(root, path)
	if not target then
		return false
	end
	for k, v in pairs(overrideTable) do
		target[k] = v
	end
	return true
end

local FALL_DAMAGE_LOOKUP = {
	[0] = {
		HeightDamageForHuman = 8.0,
		BaseDamageForHuman = 200.0,
		DamagePerHeightForHuman = 150.0,
		HeightDieForHuman = 20.0
	},
	[1] = {
		HeightDamageForHuman = 11.0,
		BaseDamageForHuman = 250.0,
		DamagePerHeightForHuman = 150.0,
		HeightDieForHuman = 25.0
	},
	[2] = {
		HeightDamageForHuman = 14.0,
		BaseDamageForHuman = 300.0,
		DamagePerHeightForHuman = 150.0,
		HeightDieForHuman = 30.0
	}
}

local ATTACK_RATES_LOOKUP = {
	RateAttackXS = 1.0,
	RateAttackS = 1.0,
	RateAttackM = 1.0,
	RateAttackL = 1.0,
	RateAttackXL = 1.0
}

fns.run_once["UDD2P - Fall damage"] = function()
	return apply_param_override(CharacterManager, "<CharacterCommonDamageParam>k__BackingField.FallParam",FALL_DAMAGE_LOOKUP[config.FALL_DAMAGE_SETTING])
end

fns.run_once["UDD2P - Sliding angle"] = function()
	return safe_set_path(CharacterManager,"<SlopeParam>k__BackingField.NormalSlopeLimit",config.SLIDING_ANGLE)
end

if config.REMOVE_DAMAGE_SCALING then
	fns.run_once["UDD2P - Damage scaling"] = function()
		return apply_param_override(CharacterManager,"<HumanParam>k__BackingField.ActionParam.BodyScaleActionParam.RateAttackParam",ATTACK_RATES_LOOKUP)
	end
end

if config.ETERNAL_WOKESTONE_FIX then
	fns.run_once["UDD2P - Eternal wakestone"] = function()
		return safe_set_path(ItemManager,"_ItemDataDict.76._FakeItemId",468)
	end
end

if config.NIGHT_EVENT_FIX then
	fns.run_once["UDD2P - Night event"] = function()
		return safe_set_path(SuddenQuestManager,"_EntityDict.33.<StartCondition>k__BackingField._ConditionArray.2._Logic",5)
	end
end
-- 0 is Vermund
-- 1 is Battahl
-- 2 is Volcanic Island
-- Days go from 0 to 27
-- As for weather, 4 is Drizzle and 5 is Downpour
local rainNights = {
	[0] = {
		[3] = 4,
		[7] = 4,
		[14] = 5,
		[20] = 5,
		[25] = 4,
	},
	[1] = {
		[10] = 4,
		[15] = 4,
		[19] = 4,
		[23] = 4,
	},
	[2] = {
		[4] = 5,
		[6] = 5,
		[10] = 5,
		[25] = 5,
	}
}

if config.NIGHTREIGN then
	sdk.hook(
		sdk.find_type_definition("app.WeatherManager"):get_method("changeBackWorld"),
		nil,
		function(retval)
			if WeatherManager._IsBackWorld == false then
				local schedules = WeatherManager.mWeatherSchedule
				if schedules:get_Count() < 3 then return end
				for area=0,2 do
					local areaSchedule = schedules[area]
					if areaSchedule then
						local daysSchedule = areaSchedule.WSUD._DaySetting
						for day,weather in pairs(rainNights[area]) do
							daysSchedule[day]._HourSettings[0]._Weather = weather
						end
					end
				end
			end
			return retval
		end
	)
end
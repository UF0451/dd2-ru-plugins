local config = require("UDD2P/Config")
local timers = require("_NickCore/Timers")

local modName = "UDD2P"
local DATA_COLLECTION = 0
local MODIFY_DATA = 1
local operation_mode = MODIFY_DATA

local enemyIDs = {
	["ch253000"] = config.ARCHER_DAMAGE_FIX, -- Griffin
	["ch227001"] = config.ARCHER_DAMAGE_FIX, -- Wight
	["ch227000"] = config.ARCHER_DAMAGE_FIX, -- Lich
}

local regionData = {}
for ID,name in pairs(enemyIDs) do
	regionData[ID] = json.load_file(modName .. "\\" .. ID .. ".json")
end

local damageTypeEnum = {
	[0] = "Slash",
	[1] = "Blow",
	[2] = "Shoot"
}

local magicDamageTypeEnum = {
	[0] = "Neutral",
	[1] = "Fire",
	[2] = "Ice",
	[3] = "Thunder",
	[4] = "Holy",
}

local function round(num)
    return math.floor(num * 1000 + 0.5) / 1000
end


local function copy_params_to_data(params)
	local data = {}	
	data["PhysDamage"] = {}
	data["PhysStagger"] = {}
	data["MagDamage"] = {}
	data["MagStagger"] = {}
	
	local physDamage = params._DamageAdjustRatePys
	for k=0,2 do
		data["PhysDamage"][damageTypeEnum[k]] = round(physDamage[k]["m_value"])
	end
	local physStagger = params._ReactionAdjustRatePys
	for k=0,2 do
		data["PhysStagger"][damageTypeEnum[k]] = round(physStagger[k]["m_value"])
	end
	
	local magDamage = params._DamageAdjustRateMgc
	for k=0,4 do
		data["MagDamage"][magicDamageTypeEnum[k]] = round(magDamage[k]["m_value"])
	end
	local magStagger = params._ReactionAdjustRateMgc
	for k=0,4 do
		data["MagStagger"][magicDamageTypeEnum[k]] = round(magStagger[k]["m_value"])
	end

	return data
end

local function copy_data_to_params(params,partData)
	local physDamage = params._DamageAdjustRatePys
	if partData["PhysDamage"] then
		for k=0,2 do
			if partData["PhysDamage"][damageTypeEnum[k]] then
				local v = physDamage[k]
				v.m_value = partData["PhysDamage"][damageTypeEnum[k]]
				physDamage[k] = v
			end
		end
	end
	local physStagger = params._ReactionAdjustRatePys
	if partData["PhysStagger"] then
		for k=0,2 do
			if partData["PhysStagger"][damageTypeEnum[k]] then
				local v = physStagger[k]
				v.m_value = partData["PhysStagger"][damageTypeEnum[k]]
				physStagger[k] = v
			end
		end
	end
	
	local magDamage = params._DamageAdjustRateMgc
	if partData["MagDamage"] then
		for k=0,4 do
			if partData["MagDamage"][magicDamageTypeEnum[k]] then
				local v = magDamage[k]
				v.m_value = partData["MagDamage"][magicDamageTypeEnum[k]]
				magDamage[k] = v
			end
		end
	end
	local magStagger = params._ReactionAdjustRateMgc
	if partData["MagStagger"] then
		for k=0,4 do
			if partData["MagStagger"][magicDamageTypeEnum[k]] then
				local v = magStagger[k]
				v.m_value = partData["MagStagger"][magicDamageTypeEnum[k]]
				magStagger[k] = v
			end
		end
	end
end

sdk.hook(
	sdk.find_type_definition("app.HitController"):get_method("start"),
	function(args)
		local HitController = sdk.to_managed_object(args[2])
		local character = HitController["<CachedCharacter>k__BackingField"]
		if not character or not character:get_Valid() then return end
		local enemyID = string.sub(character:get_CharaIDString(),1,8)
		if not enemyIDs[enemyID] then return end
		
		timers.set_timer(0.1,function() -- Small delay trying to avoid an error
			local RegionStatusCtrl = HitController["<CachedRegionStatusCtrl>k__BackingField"]
			if not RegionStatusCtrl then return end
			local regionParams = RegionStatusCtrl["<RegionStatusDataProp>k__BackingField"]._IntermediateRegionStatusParams
			local states = regionParams:get_Count()
			
			local jsonData = {}
			-- This loops over the different states (normal, angry, flying...)
			for i=0,states-1 do
				local thisStateParams = regionParams[i]._IntermediateRegionParams
				local thisStateName = regionParams[i]._StatusId
				local parts = thisStateParams:get_Count()
				
				jsonData[thisStateName] = {}
				-- This loops over every part (head, tail, wings...)
				for j=0,parts-1 do
					local thisPartParams = thisStateParams[j]
					if operation_mode == DATA_COLLECTION then
						jsonData[thisStateName][j] = copy_params_to_data(thisPartParams)
					end
					if operation_mode == MODIFY_DATA then
						local thisEnemyData = regionData[enemyID]
						local thisStateData = thisEnemyData and thisEnemyData[thisStateName]
						local thisPartData = thisStateData and thisStateData[tostring(j)]
						if thisPartData then
							copy_data_to_params(thisPartParams,thisPartData)
						end
					end
				end
			end
			if operation_mode == DATA_COLLECTION then
				json.dump_file(modName .."\\" .. enemyID .. ".json",jsonData)
			end
		end)
	end
)
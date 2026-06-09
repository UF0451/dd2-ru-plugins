local config = require("UDD2P/Config")
local h = require("UDD2P/Helpers")
local database = json.load_file("UDD2P/WeakspotDatabase.json")
local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")

local vocations = { -- Vocations that will get magic weakspots
	[1] = false,
	[2] = false,
	[3] = true,
	[4] = false,
	[5] = false,
	[6] = true,
	[7] = true,
	[8] = false,
	[9] = false,
}

local elementEnum = {
	[0] = "Neutral",
	[1] = "Fire",
	[2] = "Ice",
	[3] = "Thunder",
	[4] = "Holy",
}

local sphinxRegionData = {
    [0] = {
        MagDamage = { Fire = 1.0, Holy = 1.0, Ice = 1.0, Neutral = 1.0, Thunder = 1.0 },
        PhysDamage = { Blow = 1.0, Shoot = 1.0, Slash = 1.0 }
    },
    [1] = {
        MagDamage = { Fire = 1.0, Holy = 1.0, Ice = 1.0, Neutral = 1.0, Thunder = 1.0 },
        PhysDamage = { Blow = 1.0, Shoot = 1.5, Slash = 1.0 }
    },
    [2] = {
        MagDamage = { Fire = 0.4, Holy = 0.4, Ice = 0.4, Neutral = 0.4, Thunder = 0.4 },
        PhysDamage = { Blow = 0.7, Shoot = 0.5, Slash = 0.7 }
    },
    [3] = {
        MagDamage = { Fire = 1.0, Holy = 1.0, Ice = 1.0, Neutral = 1.0, Thunder = 1.0 },
        PhysDamage = { Blow = 0.5, Shoot = 0.5, Slash = 0.5 }
    },
    [4] = {
        MagDamage = { Fire = 1.0, Holy = 1.0, Ice = 1.0, Neutral = 1.0, Thunder = 1.0 },
        PhysDamage = { Blow = 0.5, Shoot = 0.5, Slash = 0.5 }
    },
    [5] = {
        MagDamage = { Fire = 1.5, Holy = 1.5, Ice = 1.5, Neutral = 1.5, Thunder = 1.5 },
        PhysDamage = { Blow = 1.5, Shoot = 1.0, Slash = 1.5 }
    },
    [6] = {
        MagDamage = { Fire = 0.6, Holy = 0.6, Ice = 0.6, Neutral = 0.6, Thunder = 0.6 },
        PhysDamage = { Blow = 0.6, Shoot = 0.6, Slash = 0.6 }
    },
    [7] = {
        MagDamage = { Fire = 1.0, Holy = 1.0, Ice = 1.0, Neutral = 1.0, Thunder = 1.0 },
        PhysDamage = { Blow = 0.5, Shoot = 0.5, Slash = 0.5 }
    },
    [8] = {
        MagDamage = { Fire = 1.0, Holy = 1.0, Ice = 1.0, Neutral = 1.0, Thunder = 1.0 },
        PhysDamage = { Blow = 0.5, Shoot = 0.5, Slash = 0.5 }
    },
    [9] = {
        MagDamage = { Fire = 1.5, Holy = 1.5, Ice = 1.5, Neutral = 1.5, Thunder = 1.5 },
        PhysDamage = { Blow = 1.5, Shoot = 1.0, Slash = 1.5 }
    }
}

local function force_weakspot(damageInfo,key)
	damageInfo["IsWeakDamage"] = true
	-- Rattler/Magma scales need mace or sword sound
	if key == "ch221002:0:4" or key == "ch221003:0:4" then
		damageInfo["HitSeType"] = 3
	else
		-- Anything else is fine with arrow sound
		damageInfo["HitSeType"] = 6
	end
	
	-- We check physical damage just in case
	local isZeroDamageAttack = damageInfo["MagicDamage"] <= 0 and damageInfo["SlashDamage"] <= 0 and damageInfo["BlowDamage"] <= 0 and damageInfo["ShootDamage"] <= 0
	local attackData = damageInfo["<AttackUserData>k__BackingField"]
	if isZeroDamageAttack or (attackData and attackData["ActionRate"] == 0) then
		damageInfo["IsWeakDamage"] = false
		damageInfo["HitSeType"] = -1
	end
end

local function get_element(damageInfo)
	local attackData = damageInfo["<AttackUserData>k__BackingField"]
	local attackDataElement = attackData and attackData._ElementType
	local damageInfoElement = damageInfo.OverwriteElementType._Value
	if damageInfoElement and damageInfoElement > 0 then
		return damageInfoElement
	end
	if attackDataElement and attackDataElement > -1 then
		return attackDataElement
	end
	return 0
end

fns.on_post_calc_damage["UDD2P"] = function(damageInfo,data)
	local receiverName = string.sub(data.receiver:get_CharaIDString(),1,8)
	if config.SCALY_INVADERS_FIX and (receiverName == "ch310043" or receiverName == "ch310044") then
		damageInfo.Damage = 0.0
	end
	if not data.attacker then return end
	local attackerName = string.sub(data.attacker:get_CharaIDString(),1,10)
	if config.PURPLE_HOBGOBLIN_FIX and data.shellHash and attackerName == "ch220001_2" then
		damageInfo.Damage = 0.2 * damageInfo.Damage
	end
end

fns.on_pre_calc_damage_rate["UDD2P"] = function(damageInfo,data)
	local storage = thread.get_hook_storage()
	
	storage.MagicDamage = damageInfo.MagicDamage
	storage.BlowDamage = damageInfo.BlowDamage
	storage.SlashDamage = damageInfo.SlashDamage
	storage.ShootDamage = damageInfo.ShootDamage
	storage.MagicDamage = damageInfo.MagicDamage
	storage.EnchantDamage = damageInfo.EnchantDamage
end

fns.on_post_calc_damage_rate["UDD2P"] = function(damageInfo,data)
	if data.receiver:get_IsDead() then return end
	if not data.attacker then return end
	
	local storage = thread.get_hook_storage()
	
	local receiverName = string.sub(data.receiver:get_CharaIDString(),1,8)
	-- Minotaur 25x damage charge bug fix
	if config.MINOTAUR_FIX and receiverName == "ch256000" then
		-- Horns are regions 2 and 3
		-- Status number is usually 2 and 3 respectively
		-- Unless the bug happens, then it's 12 and 13
		if (damageInfo.RegionNo == 2 and damageInfo.RegionStatusNo == 12) or (damageInfo.RegionNo == 3 and damageInfo.RegionStatusNo == 13) then
			damageInfo.SlashDamage = storage.SlashDamage
			damageInfo.BlowDamage = storage.BlowDamage
			damageInfo.ShootDamage = storage.ShootDamage
			damageInfo.MagicDamage = storage.MagicDamage
			damageInfo.EnchantDamage = storage.EnchantDamage
		end
	end
	
	if config.SPHINX_AND_MEDUSA_FIX and receiverName == "ch253001" then
		local guid = h.get_guid(data.receiver)
		if guid ~= "a9ce03a8-eb29-0d66-10b6-f21811a61441" and guid ~= "60887e70-7bd1-0227-2a67-f385cc4c6a28" then
			local region = damageInfo.RegionStatusNo
			local element = get_element(damageInfo)
			
			if element and element > 0 then
				local elementMult = sphinxRegionData[region].MagDamage[elementEnum[element]]
				damageInfo.MagicDamage = elementMult * storage.MagicDamage
				damageInfo.EnchantDamage = elementMult * storage.EnchantDamage
			end
			
			damageInfo.SlashDamage = storage.SlashDamage * sphinxRegionData[region].PhysDamage.Slash
			damageInfo.BlowDamage = storage.BlowDamage * sphinxRegionData[region].PhysDamage.Blow
			damageInfo.ShootDamage = storage.ShootDamage * sphinxRegionData[region].PhysDamage.Shoot
		end
	end
	
	if data.attacker:get_CharaIDString() ~= "ch000000_00" then return end
	
	if not data.shellHash or not config.MAGIC_WEAKSPOTS then return end
	
	-- Magic weakspots
	if vocations[data.attacker.WeaponJob] == true then
		local magicDefense = 1 - damageInfo["MagicDamage"]/storage.MagicDamage
		local key = receiverName .. ":" .. damageInfo["RegionNo"] .. ":" .. damageInfo["RegionStatusNo"]
		if database[key] and magicDefense < 0.31 then
			-- Exception for Drake: head is only weakspot if heart isn't exposed
			if receiverName == "ch257000" then
				local damageHitController = damageInfo["<DamageHitController>k__BackingField"]
				local regionStatusController = damageHitController:get_CachedRegionStatusCtrl()
				if not regionStatusController then return end
				local statusId = regionStatusController["<PrioStatusId>k__BackingField"]
				
				if key == "ch257000:1:1" or statusId ~= "HeartExposure" then
					force_weakspot(damageInfo,key)
				end
			else
				force_weakspot(damageInfo,key)
			end
		end
	end
end

if config.CHIMERA_STAGGER_FIX then
	fns.on_post_calc_damage_reaction["UDD2P - Chimera stagger fix"] = function(damageInfo,data)
		local charaID = data.receiver:get_CharaID()
		if charaID ~= 3550884773 and charaID ~= 3236853785 then return end
		local region = damageInfo.RegionStatusNo
		if region == 11 then 
			damageInfo.DamageReaction = 0.02 * damageInfo.DamageReaction
		end
	end
end
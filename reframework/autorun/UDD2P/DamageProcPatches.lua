local config = require("UDD2P/Config")
local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")

local BattleManager = sdk.get_managed_singleton("app.BattleManager")
local BattleRelationshipHolder = sdk.get_managed_singleton("app.BattleRelationshipHolder")

local function get_component(object, name)
	if not object or not object:get_Valid() then return end
	object = object.get_GameObject and object:get_GameObject() or object
	return object:call("getComponent(System.Type)", sdk.typeof(name))
end

-- Going through the attack/damage hit controller is a bit faster, but doesn't give the correct attacker in some cases
local function get_attacker(damageInfo)
	if not damageInfo then return end
	local go = damageInfo["<AttackOwnerObject>k__BackingField"]
	return get_component(go,"app.Character")
end

local function get_receiver(damageInfo)
	if not damageInfo then return end
	local go = damageInfo["<DamageGameObject>k__BackingField"]
	return get_component(go,"app.Character")
end


-- Some shells are meant to collide with friendly NPCs in combat
local excludeHashes = {
	[2958473336] = true, -- Fortalice
	[3708702958] = true, -- Remedy arrow
	[3778908409] = true,
	[1424053183] = true,
	[615935455]  = true,
	[2328833977] = true, -- Lifetaking arrow
	[3883266619] = true,
	[3028058402] = true, -- Celerity
	[2533613524] = true,
	[1827152808] = true, -- Celestial Paean
	[2627024446] = true, -- Anodyne
	[1566402932] = true, -- Halidom
	[2216277281] = true,
	[3102360309] = true, -- Paladium
}

local shellInfo = {}

if config.NPC_HIT_FIX then
	sdk.hook(
		sdk.find_type_definition("app.HitController"):get_method("damageProc(app.HitController.DamageInfo)"), 
		function(args)
			local damageInfo = sdk.to_managed_object(args[3])

			local receiver = get_receiver(damageInfo)
			if not receiver then return end
			local attacker = get_attacker(damageInfo)
			if attacker ~= p.player then return end
			
			local attackHitController = damageInfo["<AttackHitController>k__BackingField"]
			if not attackHitController then return end

			local shell = attackHitController["<CachedShell>k__BackingField"]
			if not shell then return end

			local shellHash = shell["<ShellParamId>k__BackingField"]
			if excludeHashes[shellHash] then return end

			if BattleManager._BattleMode == 0 then return end
			if not (receiver:isKindOf(2) or receiver:isKindOf(4)) then return end

			local relationship = BattleRelationshipHolder:getRelationshipFromTo(attacker, receiver)
			if relationship ~= 1 then
				return sdk.PreHookResult.SKIP_ORIGINAL
			end
		end
	)
end

fns.on_pre_calc_damage["UDD2P"] = function(damageInfo,data)
	local attackData = damageInfo["<AttackUserData>k__BackingField"]
	local name = attackData and attackData:get_Name()
	
	if config.GOBLIN_TORCH_FIX and name == "松明" then
		attackData.HitDisableTime = 120.0
	end
	if config.THIEF_FIX and name == "N_地_軽_走" then
		attackData.HitDisableTime = 10.0
	end
end
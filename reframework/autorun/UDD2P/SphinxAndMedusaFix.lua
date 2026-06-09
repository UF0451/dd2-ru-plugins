local config = require("UDD2P/Config")
if not config.SPHINX_AND_MEDUSA_FIX then return end
local h = require("UDD2P/Helpers")
local fns = require("_NickCore/Functions")
local timers = require("_NickCore/Timers")

local QuestManager = sdk.get_managed_singleton("app.QuestManager")
local SoundBgmManager = sdk.get_managed_singleton("app.SoundBgmManager")
local ExpMethod = sdk.find_type_definition("app.ExpDispenser"):get_method("addExpAndJobPoint(app.CharacterID, System.Int32, System.Int32, app.Character)")

-- Medusa fix
local function get_ai_target_pos(ch2)
	local target = ch2:getAttackTarget()
	if not target or not target:get_Valid() then return nil end
	local targetTransform = target["<Transform>k__BackingField"]
	if not targetTransform then return nil end
	return targetTransform:get_UniversalPosition()
end

local function is_lair_medusa(pos)
	local distanceToLair = ((pos.x+2025.0)^2+(pos.y-73.0)^2+(pos.z-788.0)^2)^(1/2)
	return distanceToLair < 100.0 or QuestManager:getQuestResultNo(10030) ~= 0
end

sdk.hook(
	sdk.find_type_definition("app.Ch255BattleWayPointCtrl"):get_method("findBattlePosition"), 
	function(args)
		local this = sdk.to_managed_object(args[2])
		local character = this.Chara
		local ch2 = character and character.EnemyCtrl.Ch2
		if not ch2 then return end
		if character:get_CharaIDString() ~= "ch255000_01" then return end
		local pos = get_ai_target_pos(ch2)
		if not pos then return end
		if is_lair_medusa(pos) then return end
		
		this["<LastFoundedBattlePosition>k__BackingField"] = pos
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
)

-- Swap the head for a decayed head if not on her lair
sdk.hook(
	sdk.find_type_definition("app.DropPartsController"):get_method("executeInteract(System.UInt32, app.Character)"), 
	function(args)
		local this = sdk.to_managed_object(args[2])
		local character = sdk.to_managed_object(args[4])
		local name = string.sub(this.ParentCache:get_Name(),1,8)
		if name ~= "ch255000" then return end
		local pos = character:get_Transform():get_UniversalPosition()

		local dropPartsContext = this["<_DropPartsContext>k__BackingField"]
		local originalHead = dropPartsContext._ItemId
		
		if not is_lair_medusa(pos) then
			dropPartsContext._ItemId = 101
		end
	end
)

-- Sphinx fix
local function play_sphinx_bgm()
	local overwriteBgmManager = SoundBgmManager["<OverwriteBgm>k__BackingField"]
	local overwriteBgmControllerDict = overwriteBgmManager._ControllerDic
	local sphinxBgmController = overwriteBgmControllerDict[23]
	local phaseSettingsInfoList = sphinxBgmController["<PhaseSettingsInfoList>k__BackingField"]
	local battlePhaseInfo = phaseSettingsInfoList[10]
	battlePhaseInfo._EnableLimitByDistance = false -- Make Sphinx's battle theme available outside of her arena

	overwriteBgmManager:requestPlay(23,10)
	overwriteBgmManager:requestStateOverwritePhaseState(23,10,20200)
end

local function stop_sphinx_bgm()
	local overwriteBgmManager = SoundBgmManager["<OverwriteBgm>k__BackingField"]
	overwriteBgmManager:requestStop(23,10)
end

local function kill_sphinx(chara,DamageInfo,reward)
	local actionManager = chara:get_ActionManager()
	actionManager:requestActionCore(0,"Ch253001WarpBeforeLookAtDamageCheckQuick",0)
	local go = chara:get_GameObject()
	timers.set_timer(2.8,function()
		if go and go:get_Valid() then
			go:destroy(go)
			if reward then
				chara:onDieFromAttack(DamageInfo) -- Compatibility with GPO and other random loot systems
				for _,character in ipairs(h.get_party()) do
					ExpMethod:call(nil,character:get_CharaID(),10000,233,character) -- Gain XP
				end
			end
		end
	end)
	timers.set_timer(5.0,function()
		stop_sphinx_bgm()
	end)
end

-- Fix for immortality when hitting the head
sdk.hook(
	sdk.find_type_definition("app.Ch253001SubdueCtrl"):get_method("onRegionBreak"),
	function(args)
		if h.is_quest_sphinx() then return end
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
)

-- Trigger her overwrite bgm when her regular (mute) bgm plays. If another bgm plays, stop the overwrite bgm
-- There may be edge cases where the music doesn't trigger
sdk.hook(
	sdk.find_type_definition("app.SoundBgmManager.BattleBgmManager.PlayStateController"):get_method("trigger"),
	nil,
	function(retval)
		if h.is_quest_sphinx() then return retval end
		local BattleBgmManager = SoundBgmManager["<BattleBgm>k__BackingField"]
		local groupID = BattleBgmManager["<PlayingUniqueBgmGroupId>k__BackingField"]
		if groupID == 8 then
			play_sphinx_bgm()
		else
			stop_sphinx_bgm()
		end
		return retval
	end
)
-- This should stop Sphinx's even if you run away from here but are still in combat
sdk.hook(
	sdk.find_type_definition("app.SoundBgmManager.BattleBgmManager"):get_method("changeInActiveBattleProcess(System.Boolean)"),
	function(args)
		if h.is_quest_sphinx() then return end
		stop_sphinx_bgm()
	end
)

fns.on_pre_calc_damage_reaction["UDD2P - Sphinx"] = function(damageInfo,data)
	local charaID = data.receiver:get_CharaID()
	if charaID == 3369196004 then
		local guid = h.get_guid(data.receiver)
		if guid == "a9ce03a8-eb29-0d66-10b6-f21811a61441" or guid == "60887e70-7bd1-0227-2a67-f385cc4c6a28" then return end
		
		damageInfo.RegionNo = 0 -- So her regions won't actually get damaged
		
		if data.receiver:get_Hp() - damageInfo.Damage <= 1.0 then
			damageInfo.Damage = data.receiver:get_Hp() - 1 -- Prevent actually killing her
			kill_sphinx(data.receiver,damageInfo,true) -- Make her disappear at 1HP, with rewards
		end
		
		local region = damageInfo.RegionStatusNo
		if region == 1 or region == 5 or region == 9 then 
			damageInfo.IsWeakDamage = true -- Play weakspot sounds on her head and wings
		end
	end
end

-- She doesn't like being petrified
sdk.hook(
	sdk.find_type_definition("app.StatusConditionInfo"):get_method("applyStatusConditionDamage(System.Single, app.HitController.DamageInfo)"), 
	function(args)
		if h.is_quest_sphinx() then return end

		local this = sdk.to_managed_object(args[2])
		local chara = this["<OwnerCharacter>k__BackingField"]
		local charaID = chara:get_CharaID()
		if charaID ~= 3369196004 then return end
		
		local damage = sdk.to_float(args[3])
		local DamageInfo = sdk.to_managed_object(args[4])

		local list = DamageInfo.StatusConditionAtk.AccumulationList
		for i=0,list:get_Count()-1 do
			local info = list[i]
			if info.StatusConditionId == 12 and info.Value == damage then
				kill_sphinx(chara,DamageInfo,false) -- Make her disappear, no rewards
			end
		end
	end
)

-- Prevent her from warping away outside her quest
sdk.hook(
	sdk.find_type_definition("app.Ch253001WarpController"):get_method("updateCandidateWarpPosition()"),
	function(args)
		thread.get_hook_storage().this = sdk.to_managed_object(args[2])
	end,
	function(retval)
		local this = thread.get_hook_storage().this
		local ch2 = this.Ch253001
		if not ch2:get_Valid() then return retval end

		local transform = ch2:get_Transform()
		local startWarpPos = transform:get_UniversalPosition()
		local sphinxPos = transform:get_Position()
		local sphinx = ch2._Chara
		local guid = h.get_guid(sphinx)
		if guid == "a9ce03a8-eb29-0d66-10b6-f21811a61441" or guid == "60887e70-7bd1-0227-2a67-f385cc4c6a28" then return retval end
		
		local success = sdk.to_int64(retval) & 1 == 1
		if success then
			local address = this:get_address()
			fns.on_frame[address] = function()
				this.WarpPosition = startWarpPos
				local correctedRotation
				local target = ch2:get_Valid() and ch2:getAttackTarget()
				if target then
					local targetPos = target["<Transform>k__BackingField"]:get_Position()
					targetPos.y = sphinxPos.y -- Don't want to rotate her vertically
					correctedRotation = h.rotation_from_to(sphinxPos,targetPos)
				end
				this.WarpQuat = correctedRotation or this.WarpQuat
			end
			timers.set_timer(2.7,function()
				fns.on_frame[address] = nil
			end)
		end
		return retval
	end
)

local sphinxSkipNodes = {
	-- Disable nodes related to her fight riddle
	["Ch253001WarpBeforeLookAtDamageCheckQuick"] = true,
	["Ch253001LookAtDamageCheckForQuick"] = true,
	["Ch253001EmotionWaitAndWingLong"] = true,
	["Ch253001EmotionDenial"] = false, -- Bugs her out if I skip it
	["Ch253001EmotionPositive"] = false, -- Same
	["Ch253001EmotionLookAround"] = false, -- Same
	-- These are other warps, no need to skip them now that I managed to make her not teleport out of bounds
	["Ch253001WarpExplopsionStart"] = false,
	["Ch253001WarpMissileStart"] = false,
	["Ch253001BackSpellReleaseWarp"] = false,
}

fns.on_pre_action_request["UDD2P - Sphinx fix"] = function(args,data)
	if data.charaID ~= "ch253001_00" then return end
	
	local guid = h.get_guid(data.character)
	if guid == "a9ce03a8-eb29-0d66-10b6-f21811a61441" or guid == "60887e70-7bd1-0227-2a67-f385cc4c6a28" then return end

	if data.priority == 10 and sphinxSkipNodes[data.node] then
		return true
	end
end
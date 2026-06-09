local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")
local timers = require("_NickCore/Timers")
local h = require("UDD2P/Helpers")
local config = require("UDD2P/Config")

local GuiManager = sdk.get_managed_singleton("app.GuiManager")
local BattleManager = sdk.get_managed_singleton("app.BattleManager")
local TalkManager = sdk.get_managed_singleton("app.TalkEventManager")
local QuestManager = sdk.get_managed_singleton("app.QuestManager")

if config.NO_DISTANCE_PAWN_RESTRICTIONS then
	sdk.hook(
		sdk.find_type_definition("app.ItemManager"):get_method("isFarFromPlayer(app.Character)"),
		nil,
		function(retval)
			return sdk.to_ptr(false)
		end
	)
end

if config.TUTORIAL_RUN then
	fns.on_update_behavior["UDD2P - Tutorial run"] = function()
		if QuestManager:getQuestResultNo(10030) ~= 0 then
			p.human["<IsDisableRun>k__BackingField"] = false
		end
	end
end

if config.OGRE_SLIDE_FIX then
	local ogres = {
		["ch251000_00"] = true,
		["ch251001_00"] = true,
	}
	fns.on_pre_action_request["UDD2P - Ogre slide fix"] = function(args,data)
		if not ogres[data.charaID] then return end
		
		if data.node == "Ch251LivCrounchStartLoop" or data.node == "Ch251LivCrounchAround" then
			local this = sdk.to_managed_object(args[2])
			local currentNode = this.CurrentActionList[0].Name
			if currentNode == data.node then
				return true
			end
		end
	end
end

if config.FASTER_DIALOGUE_SKIP then
	sdk.hook(
		sdk.find_type_definition("app.TalkEventPlayer"):get_method("isNextSubtitleTriggered"),
		nil,
		function(retval)
			local input = GuiManager["<InputSystem>k__BackingField"]
			if input:isButtonTrigger(256,1) and BattleManager._BattleMode == 0 then
				local CurrentTalkInfo = TalkManager["<CurrentTalkInfo>k__BackingField"]
				if not CurrentTalkInfo then return end
				local speakerID = CurrentTalkInfo["<Speaker>k__BackingField"]
				-- Make an exception for drakes, which sometimes talk to you before combat starts
				if speakerID ~= 2133916449 then
					return sdk.to_ptr(true)
				end
			end
			return retval
		end
	)
end

if config.LEVIN_SOUND_FIX then
	local position, lastTime
	fns.on_pre_trigger_sound["UDD2P"] = function(data)
		if data.shell and data.triggerID == 1948966675 then
			if lastTime and p.gameTime - lastTime < 5.0 then
				data.soundRequest["<Position>k__BackingField"] = position
			else
				position = data.soundRequest["<Position>k__BackingField"]
				lastTime = p.gameTime
			end
		end
	end
end

if config.NPC_FREAK_TWEAK then
	sdk.hook(
		-- Yes we're hooking list add lol
		sdk.find_type_definition("System.Collections.Generic.List`1<app.InterestSensor.InterestNode>"):get_method("Add(app.InterestSensor.InterestNode)"),
		function(args)
			if BattleManager._BattleMode ~= 0 then return end
			local interestNode = sdk.to_managed_object(args[3])
			local checkInfos = interestNode.InterestMarker["<CheckInfosInstance>k__BackingField"]
			local count = checkInfos:get_Count()
			for i=0,count-1 do
				local actType = checkInfos[i]["<CheckInfo>k__BackingField"]._RequestAct._ReqActType
				if actType == 0 or actType == 11 then -- NPC reactions to player drawing their weapons
					return sdk.PreHookResult.SKIP_ORIGINAL
				end
			end
		end
	)
end

if config.STRAY_PAWNS then
	sdk.hook(
		sdk.find_type_definition("app.AISituation.TaskExecutable_StrayPawn_Sales"):get_method("check"),
		nil,
		function(retval)
			return sdk.to_ptr(false)
		end
	)
end

if config.NO_STAMINA_COST then
	local function set_dash_params(isCombat)
		local staminaParams = p.staminaParams.CommonConsumeList[1]
		staminaParams.VeryLight = isCombat and -0.650 or 0.0
		staminaParams.Light = isCombat and -0.650 or 0.0
		staminaParams.Middle = isCombat and -0.650 or 0.0
		staminaParams.Heavy = isCombat and -0.975 or 0.0
		staminaParams.VeryHeavy = isCombat and -1.3 or 0.0
		staminaParams.Over = isCombat and -1.950 or 0.0
	end
	fns.run_once["UDD2P - Sprinting stamina cost"] = function()
		if p.player then
			set_dash_params(BattleManager._BattleMode ~= 0)
			return true
		end
	end
	sdk.hook(
		sdk.find_type_definition("app.MainFlowManager"):get_method("onBattleStart"),
		function(args)
			set_dash_params(true)
		end
	)
	sdk.hook(
		sdk.find_type_definition("app.MainFlowManager"):get_method("onBattleEnd"),
		function(args)
			set_dash_params(false)
		end
	)
end

local function cure_dragonsplague(pawn)
	local contextHolder = pawn["<Context>k__BackingField"]
	local type = sdk.find_type_definition("app.PawnDataContext"):get_runtime_type()
	local pawnDataContextInfo = contextHolder.Contexts[type]
	if pawnDataContextInfo then
		local pawnDataContext = pawnDataContextInfo:get_CurrentContext()
		pawnDataContext._PossessionLv = 0
		pawnDataContext._PossessionProgressPoint = 0
	end
end

sdk.hook(
	sdk.find_type_definition("app.BrineProcessor"):get_method("onKillCommon()"),
	function (args)
		local BrineProcessor = sdk.to_managed_object(args[2])
		local chara = BrineProcessor.Chara
		if not chara or not chara:get_Valid() then return end
		local charaID = chara:get_CharaID()
		local human = chara:get_Human()
		if not human then return end
		if chara:get_IsDead() then return end
		if (config.PAWNS_SURVIVE_BRINE and human:isPlayerOrPartyPawn()) or (config.SCALY_INVADERS_FIX and (charaID == 1770383584 or charaID == 3675926147)) then
			if chara:isKindOf(2) and config.BRINE_HEALS_PLAGUE then
				cure_dragonsplague(chara)
			end
			local pos = BrineProcessor.CalcRevivePosRotHandler
			if pos then
				chara:get_TelepotorProp():teleport(pos)
				return sdk.PreHookResult.SKIP_ORIGINAL
			end
		end
	end
)

if config.FIGHTER_IFRAMES_FIX then
	fns.on_pre_status_apply["UDD2P"] = function(args,data)
		if not data.character["<Human>k__BackingField"] then return end
		if data.status == 15 or data.status == 16 or data.status == 17 then return end -- Elemental boons
		local actionManager = data.character["<ActionManager>k__BackingField"]
		local fullNode = actionManager.CurrentActionList[0].Name
		if not fullNode then return end
		if string.find(fullNode,"JustGuard") then
			return true
		end
	end
end
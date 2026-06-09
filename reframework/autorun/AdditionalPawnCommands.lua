local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")
local timers = require("_NickCore/Timers")

local TalkManager = sdk.get_managed_singleton("app.TalkEventManager")
local CampManager = sdk.get_managed_singleton("app.CampManager")
local PawnManager = sdk.get_managed_singleton("app.PawnManager")
local CameraManager = sdk.get_managed_singleton("app.CameraManager")
local setExecuteMethod = sdk.find_type_definition("app.AIBlackBoardExtensions"):get_method("setBBValuesToExecuteActInter(app.AIBlackBoardController, app.ActInterPackData, app.AITarget)")

local function check_player_status(status)
	local statusConditionController = p.player:get_StatusConditionCtrl()
	return statusConditionController:IsStatusConditionActive(status,false)
end

local checkGrounded
-- Position is a vec3 here, not a via.Position
local function warp_pawns_to_position(position)
    PawnManager:followWarp(position)
end

local function warp_pawns_to_safety()
	local pawnList = PawnManager:get_PartyPawnList():add_ref()
	for i=0,pawnList:get_Count()-1 do
		local try,pawn = pcall(function() return pawnList[i]:add_ref() end) -- Occasional unavodiable error
		if try and pawn then
			local SafetyFinder = pawn:get_SafetyPositionFinder()
			local safety = SafetyFinder:get_Safety()
			if safety ~= 0 then
				local playerPosition = p.transform:get_Position()
				warp_pawns_to_position(playerPosition)
				break
			end
		end
	end
end

-- To me! -> teleport pawns behind player
local function warp_pawns_to_player()
	local playerPosition = p.transform:get_Position()
	local mainCamController = CameraManager._MainCameraControllers[0]
    local warpPosition = mainCamController._Transform:get_Position()
	-- Don't want the poor guys to spawn in the air
	warpPosition.y = playerPosition.y
	warp_pawns_to_position(warpPosition)
	
	-- Safety measure in case pawns end up clipping or falling
	checkGrounded = 0
end

-- Wait! -> freezes pawns in place
local function toggle_pawn_motion()
	local pawnList = PawnManager:get_PawnCharacterList():add_ref()
	for i=0,pawnList:get_Count()-1 do
		local try,pawn = pcall(function() return pawnList[i]:add_ref() end) -- Occasional unavodiable error
		if try and pawn then
			local human = pawn["<Human>k__BackingField"]
			local fsm = human.Fsm
			
			local enabled = fsm:get_Enabled()
			fsm:set_Enabled(not enabled)
		end
	end
end

local function unfreeze_pawns()
	local pawnList = PawnManager:get_PawnCharacterList():add_ref()
	for i=0,pawnList:get_Count()-1 do
		local try,pawn = pcall(function() return pawnList[i]:add_ref() end) -- Occasional unavodiable error
		if try and pawn then
			local human = pawn["<Human>k__BackingField"]
			local fsm = human.Fsm
			fsm:set_Enabled(true)
		end
	end
end

local skillPaths = {
	[5] = "AppSystem\\ai\\actioninterface\\actinterpackdata\\job01_fighter\\job01_springboard_01.user", -- 02, 04, 05 are also valid and do slightly different things
	[29] = "AppSystem\\ai\\actioninterface\\actinterpackdata\\job03_mage\\job03_fireboon.user",
	[30] = "AppSystem\\ai\\actioninterface\\actinterpackdata\\job03_mage\\job03_iceboon.user",
	[31] = "AppSystem\\ai\\actioninterface\\actinterpackdata\\job03_mage\\job03_thunderboon.user",
	[34] = "AppSystem\\ai\\actioninterface\\actinterpackdata\\job03_mage\\job03_hastespot.user",
	[60] = "AppSystem\\ai\\actioninterface\\actinterpackdata\\job05_warrior\\job05_springboard_01.user" -- same as fighter's
}

local function create_AITarget(target)
	if not target then return nil end
	local AITarget = sdk.create_instance("app.AITargetGameObject",true)
	AITarget["<GameObject>k__BackingField"] = target:get_GameObject()
	AITarget["<Character>k__BackingField"] = target
	AITarget["<Owner>k__BackingField"] = target:get_GameObject()
	AITarget["<OwnerCharacter>k__BackingField"] = target
	AITarget["<ContextHolder>k__BackingField"] = target:get_Context()
	AITarget["<Transform>k__BackingField"] = target:get_Transform()
	return AITarget
end

-- We need to keep track of this to prevent the pawns from cancelling their skills
local skillPawnData = {}

local function set_action_interface_pack_data(pawn,skill,target)
	skillPawnData[pawn] = {
		skipCounter = 0,
		usedSkill = skill
	}
	local udata = sdk.create_userdata("app.ActInterPackData",skillPaths[skill])
	local AIBlackBoardController = pawn:get_AIBlackBoardController()
	local AITarget = create_AITarget(target)
	
	setExecuteMethod:call(nil, AIBlackBoardController, udata, AITarget)
	AIBlackBoardController:set_ReqMainActInterPackData(udata)	
	
	local AIDecisionMaker = pawn["<AIDecisionMaker>k__BackingField"]
	AIDecisionMaker:set_Enabled(false)
	
	local start = p.gameTime
	fns.on_frame[pawn] = function() -- We use this instead of timer for repeated calls
		if p.gameTime - start > 3.0 then
			AIDecisionMaker:set_Enabled(true)
		end
	end
end

local function cast_random_boon()
	local pawnList = PawnManager:get_PawnCharacterList():add_ref()
	local casters = {}
	local availableBoons = {}
	-- We loop through the party and cache any potential casters and their equipped boons
	for i=0,pawnList:get_Count()-1 do
		local try,character = pcall(function() return pawnList[i]:add_ref() end) -- Occasional unavodiable error
		if try and character and character.WeaponJob == 3 then
			local SkillContext = character["<Human>k__BackingField"]["<SkillContext>k__BackingField"]
			local EquipedMageSkills = SkillContext.EquipedSkills[3].Skills
			for i=0,3 do
				local skillID = EquipedMageSkills[i].value__
				if skillID == 29 or skillID == 30 or skillID == 31 then
					casters[skillID] = character
					table.insert(availableBoons,skillID)
				end
			end
		end
	end

	if #availableBoons == 0 then return "failure" end
	
	local skillID = availableBoons[math.random(1,#availableBoons)]
	local pawn = casters[skillID]
	set_action_interface_pack_data(pawn,skillID,p.player)
	
	return "success"
end

local function cast_celerity()
	local pawnList = PawnManager:get_PawnCharacterList():add_ref()
	for i=0,pawnList:get_Count()-1 do
		local try,character = pcall(function() return pawnList[i]:add_ref() end) -- Occasional unavodiable error
		if try and character and character.WeaponJob == 3 then
			local SkillContext = character["<Human>k__BackingField"]["<SkillContext>k__BackingField"]
			local EquipedMageSkills = SkillContext.EquipedSkills[3].Skills
			for i=0,3 do
				local skillID = EquipedMageSkills[i].value__
				if skillID == 34 then
					set_action_interface_pack_data(character,skillID,character)
					return
				end
			end
		end
	end
end

-- Help! -> mage pawn casts celerity or elemental boons
local function cast_boon_or_celerity()
	local WeaponDrawContext = p.player.WeaponDrawContext
	if WeaponDrawContext then
		if not WeaponDrawContext["IsDrawedWeapon"] then
			cast_celerity()
			return
		end
	end
	local playerHasBoon = check_player_status(15) or check_player_status(16) or check_player_status(17)
	local weapon = p.player:get_RightWeapon()
	if weapon then
		playerHasBoon = playerHasBoon or weapon:get_ElementTypeProp() ~= -1
	end
	-- If player already has an elemental boon or there are no pawns that know one, cast celerity instead
	if playerHasBoon or cast_random_boon() == "failure" then
		cast_celerity()
	end
end

-- Go! -> fighter or warrior pawn uses springboard/ladder launch
local function toggle_launch_state()
	local pawnList = PawnManager:get_PawnCharacterList():add_ref()
	local launchPawn
	for i=0,pawnList:get_Count()-1 do
		local try,character = pcall(function() return pawnList[i]:add_ref() end) -- Occasional unavodiable error
		if try and character and (character.WeaponJob == 1 or character.WeaponJob == 5) then
			launchPawn = character
			break
		end
	end
	if not launchPawn then return end
	local job = launchPawn.WeaponJob
	
	if job ~= 1 and job ~= 5 then return end
	local human = launchPawn["<Human>k__BackingField"]
	local actionManager = launchPawn["<ActionManager>k__BackingField"]
	local currentAction = actionManager.CurrentActionList[0].Name
	local AIDecisionMaker = launchPawn["<AIDecisionMaker>k__BackingField"]
	
	human:forceChangeDrawingWeapon(true)
	
	local springboardAction = "Job0" .. job .. "_Springboard"
	
	if currentAction == springboardAction then
		actionManager:requestActionCore(0, "NormalLocomotion", 0)
		AIDecisionMaker:set_Enabled(true)
	else
		actionManager:requestActionCore(0, springboardAction, 0)
		AIDecisionMaker:set_Enabled(false)
		timers.set_timer(5.0,function()
			AIDecisionMaker:set_Enabled(true)
		end)
	end
end

-- These are button RELEASE flags
local commandData = {
	[262144] = {name = "Go", lastTimeReleased = 0, on_double_tap = toggle_launch_state},
	[131072] = {name = "ToMe", lastTimeReleased = 0, on_double_tap = warp_pawns_to_player},
	[524288] = {name = "Help", lastTimeReleased = 0, on_double_tap = cast_boon_or_celerity},
	[1048576] = {name = "Wait", lastTimeReleased = 0, on_double_tap = toggle_pawn_motion},
}

local WAIT_RELEASE_FLAG = 1048576

-- We want the commands to be usable while drakes/the dragon talk to you, but not in any other conversation
local speakerCodes = {
	[2133916449] = "Drake",
	[2631267673] = "Dragon0",
	[1032736632] = "Dragon1",
	[1359728607] = "Dragon2",
	[1403005379] = "Dragon3"
}

fns.on_frame["APC"] = function()
	if CampManager:get_IsActiveCamp() then return end

	local talkInfo = TalkManager["<CurrentTalkInfo>k__BackingField"]
	if talkInfo and not speakerCodes[talkInfo["<Speaker>k__BackingField"]] then return end
	
	if checkGrounded then
		checkGrounded = checkGrounded + 1

		-- Delay by a few frames for consistency
		if checkGrounded > 3 then
			checkGrounded = nil
			warp_pawns_to_safety()
		end
	end
	
	local releaseFlag = p.input["ButtonReleaseFlags"]
	if releaseFlag == 0 then return end
	local data = commandData[releaseFlag]
	if not data then return end

	if releaseFlag ~= WAIT_RELEASE_FLAG then 
		unfreeze_pawns()
	end
	
	if p.gameTime - data.lastTimeReleased < 0.25 then
		data.on_double_tap()
	end

	data.lastTimeReleased = p.gameTime
end
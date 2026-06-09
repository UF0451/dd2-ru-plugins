local h = {}
local p = require("_NickCore/Properties")

local SceneManager = sdk.get_native_singleton("via.SceneManager")
local SceneManagerType = sdk.find_type_definition("via.SceneManager")
local PawnManager = sdk.get_managed_singleton("app.PawnManager")
local QuestLogManager = sdk.get_managed_singleton("app.QuestLogManager")
local makeLookAtRH = sdk.find_type_definition("via.matrix"):get_method("makeLookAtRH")

function h.get_component(object, name)
	if not object or not object:get_Valid() then return nil end
	return object:call("getComponent(System.Type)", sdk.typeof(name))
end

function h.get_now_area()
	local scene = sdk.call_native_func(SceneManager, SceneManagerType, "get_CurrentScene()")
	local uiObj = scene:call("findGameObject(System.String)", "ui020301")
	if not uiObj then return nil end
	local uiBase = h.get_component(uiObj,"app.GUIBase")
	
	return uiBase.MapAreaNow
end

local function is_sphinx_quest_completed()
	local questLogDict = QuestLogManager._QuestLogInfoDict
	local sphinxQuest = questLogDict[20200]
	local status = sphinxQuest["<Status>k__BackingField"]
	return status == 2
end

function h.is_quest_sphinx()
	local area = h.get_now_area()
	local isInShrine = area == 1008 or area == 1009
	return isInShrine and not is_sphinx_quest_completed()
end

function h.get_guid(character)
	local generateInfo = h.get_component(character:get_GameObject(),"app.GenerateInfo")
	local guid = generateInfo._Container._CommonInfo._RequestID._UniqID._RowID:ToString()
	return guid
end

function h.get_party()
	local pawnList = PawnManager:get_PawnCharacterList():add_ref()
	local party = {p.player}
	for i=0,pawnList:get_Count()-1 do
		local try,pawn = pcall(function() return pawnList[i]:add_ref() end) -- Occasional unavodiable error
		if try and pawn then
			table.insert(party,pawn)
		end
	end
	return party
end

-- local func = require("_SharedCore/Functions")

-- local function get_no_enemy_ray_cast_position(startPos,endPos,radius)
	-- local results = func.cast_ray(startPos,endPos, 2, 0, radius, 0)
	-- if results[1] then
		-- local result = results[1][2]
		-- local name = results[1][1]:get_Name()
		-- return result,name
	-- end
-- end

-- function h.is_obscured(startPos,endPos)
	-- local rayCastPos,obscuringObjectName = get_no_enemy_ray_cast_position(startPos,endPos,0.01)
	-- if not obscuringObjectName then return false end
	-- if obscuringObjectName ~= "GroundCol" and not string.match(obscuringObjectName,"Env") then return false end
	-- return true
-- end

function h.get_local_position(universalPosition)
	local scene = sdk.call_native_func(SceneManager, SceneManagerType, "get_CurrentScene()")
	return scene:fromUniversalPosition(universalPosition)
end

function h.rotation_from_to(startPos,endPos)
	local rotationMatrix = makeLookAtRH(nil, startPos, endPos, Vector3f.new(0, 1, 0)):inverse()
    local rotation = (rotationMatrix[2] * -1):to_quat():normalized()
	return rotation
end

function h.get_knockdown(human)
	local damageCalc = human.HumanEnemyController.DmgCalculator
	local statusCalculator = damageCalc.StatusCalculator
	local attackDefenseStatus = statusCalculator:calcAttackDefenceWithEquipmentAndBuff()
	
	local weaponKnockdown = attackDefenseStatus["<RightWeaponReactionAttack>k__BackingField"]
	if weaponKnockdown == 0 then
		weaponKnockdown = attackDefenseStatus["<LeftWeaponReactionAttack>k__BackingField"]
	end
	
	local armorKnockdown = attackDefenseStatus["<ArmorReactionAttack>k__BackingField"] -- namely the stagger rings

	local specialBuffMod = statusCalculator.Param.SpecialBuff:getReactionAttackRateFactor()

	local basicAttackDefenseStatus = statusCalculator:calcBasicAttackDefence()
	local baseKnockdown = basicAttackDefenseStatus["<Blow>k__BackingField"]
	
	return specialBuffMod * (baseKnockdown + weaponKnockdown + armorKnockdown)
end

return h
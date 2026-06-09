local modname = "SimpleCharacterStatusManager"
local modNo = 1
local modCode = "scsm"
local modDisplayName = "Простой Менеджер Статуса Персонажей"
local currentVersion = "1.4.16"
local configFileName = modname .. ".json"

local common = require("timtam/common")
local characterHelper = require("timtam/characterHelper")
characterHelper.SetCommon(common)

local requiredVersion = {}
requiredVersion.common = "1.1.16"
requiredVersion.characterHelper = "1.1.9"

local maxNPCCount = 4
local tempMaxNPCCount

local stepsForward = 1
local stepsToTheRight = 0
local stepsUpward = 0
local tempArisenAffinity = {}
local originalChildWindowPositionIndex = 0

local maxHealthAmount = {}
local actualRemainingHealthAmount = {}
local healthRemainingAmountChanged = {}
local actualRemainingStaminaAmount = {}
local maxStaminaAmount = {}
local staminaRemainingAmountChanged = {}
local posData = {}

local lanternSwitchButtonClicked = {}
local applyStatusConditionButtonClicked = {}
local applyStatusConditionButtonPreviouslyClicked = {}
local cureAllStatusConditionButtonClicked = {}
local resetCurrentCharacterValuesButtonClicked = {}
local addScarButtonClicked = {}
local cureAllScarsButtonClicked = {}

local resetAllValuesClicked = false

local function GetDefaultConfig()

	local defaultConfig = {
 
		modname = modname,
		version = currentVersion,
		modEnabled = true,
		installedVersion_common = common.currentVersion,
		installedVersion_characterHelper = characterHelper.currentVersion,
		requiredVersion_common = requiredVersion.common,
		requiredVersion_characterHelper = requiredVersion.characterHelper,
		originalChildWindowPosition = common.WINDOWPOSITION.BOTTOMLEFT,
		maxManagedNPCCount = maxNPCCount,
		refreshListsWhenPausedGUI = false,
		disableExpAndDcpGainFromBattles = false,
		disableAutoDashOutsideCombat = false,
		elvishLanguageOptionIndex = 0,
		useNamesAsLabels = true,
		hideHealthAndStaminaSections = false,
		criticalHealthPercentage =  23.99, --24.999941055113468906572354848217,
		criticalStaminaPercentage = 23.99, --24.400229419703103913630229419703,
		forceBattleRelationshipToPawns = false,
		npcCharID = {
			["-1"] = "",
			["0"] = "",
			["1"] = "",
			["2"] = "",
			["3"] = "",
			["4"] = "",
			["5"] = "",
			["6"] = ""
		},
		freezeHealth = {
			["-1"] = false,
			["0"] = false,
			["1"] = false,
			["2"] = false,
			["3"] = false,
			["4"] = false,
			["5"] = false,
			["6"] = false
		},
		remainingHealthAmount = {
			["-1"] = -1,
			["0"] = -1,
			["1"] = -1,
			["2"] = -1,
			["3"] = -1,
			["4"] = -1,
			["5"] = -1,
			["6"] = -1
		},
		freezeStamina = {
			["-1"] = false,
			["0"] = false,
			["1"] = false,
			["2"] = false,
			["3"] = false,
			["4"] = false,
			["5"] = false,
			["6"] = false
		},
		remainingStaminaAmount = {
			["-1"] = -1,
			["0"] = -1,
			["1"] = -1,
			["2"] = -1,
			["3"] = -1,
			["4"] = -1,
			["5"] = -1,
			["6"] = -1
		},
		statusConditionIndex = {
			["-1"] = 1,
			["0"] = 1,
			["1"] = 1,
			["2"] = 1,
			["3"] = 1,
			["4"] = 1,
			["5"] = 1,
			["6"] = 1
		},
		scarTypeIndex = {
			["-1"] = 1,
			["0"] = 1,
			["1"] = 1,
			["2"] = 1,
			["3"] = 1,
			["4"] = 1,
			["5"] = 1,
			["6"] = 1
		},
		autoReapplyStatusConditionCheckBoxChecked = {
			["-1"] = false,
			["0"] = false,
			["1"] = false,
			["2"] = false,
			["3"] = false,
			["4"] = false,
			["5"] = false,
			["6"] = false
		},
		autoReapplyBattleRelationshipCheckBoxChecked = {
			["-1"] = false,
			["0"] = false,
			["1"] = false,
			["2"] = false,
			["3"] = false,
			["4"] = false,
			["5"] = false,
			["6"] = false
		},
		battleRelationshipIndex = {
			["-1"] = 0,
			["0"] = 0,
			["1"] = 0,
			["2"] = 0,
			["3"] = 0,
			["4"] = 0,
			["5"] = 0,
			["6"] = 0
		},
		battleRelationshipApplicationTypeIndex = {
			["-1"] = 0,
			["0"] = 0,
			["1"] = 0,
			["2"] = 0,
			["3"] = 0,
			["4"] = 0,
			["5"] = 0,
			["6"] = 0
		},
		arisenAffinity = {
			["-1"] = -1000,
			["0"] = -1000,
			["1"] = -1000,
			["2"] = -1000,
			["3"] = -1000,
			["4"] = -1000,
			["5"] = -1000,
			["6"] = -1000
		}
	}

	return defaultConfig

end

local previousConfig
local defaultConfig
local config

local function ReadConfig()

	previousConfig = json.load_file(configFileName)
	defaultConfig = GetDefaultConfig()
	config = defaultConfig

	if previousConfig then

		config.modEnabled = common.GetBooleanValue(previousConfig.modEnabled)
		config.originalChildWindowPosition = common.ChangeToDefaultIfNil(previousConfig.originalChildWindowPosition, defaultConfig.originalChildWindowPosition)
		originalChildWindowPositionIndex = common.GetCurrentListIndex(common.WINDOWPOSITIONS, config.originalChildWindowPosition)

		config.disableExpAndDcpGainFromBattles = common.GetBooleanValue(previousConfig.disableExpAndDcpGainFromBattles)
		config.disableAutoDashOutsideCombat = common.GetBooleanValue(previousConfig.disableAutoDashOutsideCombat)
		config.elvishLanguageOptionIndex = common.ChangeToDefaultIfNotANumber(previousConfig.elvishLanguageOptionIndex, defaultConfig.elvishLanguageOptionIndex)
		config.useNamesAsLabels = common.GetBooleanValue(previousConfig.useNamesAsLabels)
		config.hideHealthAndStaminaSections = common.GetBooleanValue(previousConfig.hideHealthAndStaminaSections)
		config.criticalHealthPercentage =  common.ChangeToDefaultIfNotANumber(previousConfig.criticalHealthPercentage, defaultConfig.criticalHealthPercentage)
		config.criticalStaminaPercentage = common.ChangeToDefaultIfNotANumber(previousConfig.criticalStaminaPercentage, defaultConfig.criticalStaminaPercentage)
		config.forceBattleRelationshipToPawns = common.GetBooleanValue(previousConfig.forceBattleRelationshipToPawns)
		config.maxManagedNPCCount = common.ChangeToDefaultIfNotANumber(previousConfig.maxManagedNPCCount, defaultConfig.maxManagedNPCCount)
		config.refreshListsWhenPausedGUI = common.GetBooleanValue(previousConfig.refreshListsWhenPausedGUI)

		characterHelper.InitializeCharacterHelper(config, 4, config.maxManagedNPCCount, config.refreshListsWhenPausedGUI)
		tempMaxNPCCount = config.maxManagedNPCCount

		for i = -1,characterHelper.GetFinalManagedCharacterIndex(config) do

			config.npcCharID[tostring(i)] = common.ChangeToDefaultIfNil(previousConfig.npcCharID[tostring(i)], "")
		
			config.freezeHealth[tostring(i)] = common.GetBooleanValue(common.GetListItem(previousConfig.freezeHealth, tostring(i)))
			config.remainingHealthAmount[tostring(i)] = common.ChangeToDefaultIfNotANumber(common.GetListItem(previousConfig.remainingHealthAmount, tostring(i)), defaultConfig.remainingHealthAmount[tostring(0)])
			config.freezeStamina[tostring(i)] = common.GetBooleanValue(common.GetListItem(previousConfig.freezeStamina, tostring(i)))
			config.remainingStaminaAmount[tostring(i)] = common.ChangeToDefaultIfNotANumber(common.GetListItem(previousConfig.remainingStaminaAmount, tostring(i)), defaultConfig.remainingStaminaAmount[tostring(0)])
			config.statusConditionIndex[tostring(i)] = common.ChangeToDefaultIfNotANumber(common.GetListItem(previousConfig.statusConditionIndex, tostring(i)), defaultConfig.statusConditionIndex[tostring(0)])
			config.scarTypeIndex[tostring(i)] = common.ChangeToDefaultIfNotANumber(common.GetListItem(previousConfig.scarTypeIndex, tostring(i)), defaultConfig.scarTypeIndex[tostring(0)])
			config.autoReapplyStatusConditionCheckBoxChecked[tostring(i)] = common.GetBooleanValue(common.GetListItem(previousConfig.autoReapplyStatusConditionCheckBoxChecked, tostring(i)))
			config.autoReapplyBattleRelationshipCheckBoxChecked[tostring(i)] = common.GetBooleanValue(common.GetListItem(previousConfig.autoReapplyBattleRelationshipCheckBoxChecked, tostring(i)))
			config.battleRelationshipIndex[tostring(i)] = common.ChangeToDefaultIfNotANumber(common.GetListItem(previousConfig.battleRelationshipIndex, tostring(i)), defaultConfig.battleRelationshipIndex[tostring(0)])
			config.battleRelationshipApplicationTypeIndex[tostring(i)] = common.ChangeToDefaultIfNotANumber(common.GetListItem(previousConfig.battleRelationshipApplicationTypeIndex, tostring(i)), defaultConfig.battleRelationshipApplicationTypeIndex[tostring(0)])
			config.arisenAffinity[tostring(i)] = common.ChangeToDefaultIfNotANumber(common.GetListItem(previousConfig.arisenAffinity, tostring(i)), defaultConfig.arisenAffinity[tostring(0)])
		
		end
		
	else

		characterHelper.InitializeCharacterHelper(config, 4, config.maxManagedNPCCount, config.refreshListsWhenPausedGUI)
		tempMaxNPCCount = config.maxManagedNPCCount
		
	end
	
	characterHelper.RefreshManagedCharacterCache(config)
	
end

--refresh config
ReadConfig()

json.dump_file(configFileName, config)

local versionIsAMatch_common = common.currentVersion == requiredVersion.common
local versionIsAMatch_characterHelper = characterHelper.currentVersion == requiredVersion.characterHelper
local showNotesSection = isCharacterCostumeCustomizerInstalled or isNPCClonerInstalled or not versionIsAMatch_common or not versionIsAMatch_characterHelper

local BattleManager = sdk.get_managed_singleton("app.BattleManager")

local function ResetCurrentCharacterValues(index, includeConfigValues)
	if includeConfigValues then
		config.freezeHealth[tostring(index)] = false
		config.remainingHealthAmount[tostring(index)] = -1

		config.freezeStamina[tostring(index)] = false
		config.remainingStaminaAmount[tostring(index)] = -1

		config.statusConditionIndex[tostring(index)] = 1
		config.autoReapplyStatusConditionCheckBoxChecked[tostring(index)] = false

		config.scarTypeIndex[tostring(index)] = 1
		
		config.autoReapplyBattleRelationshipCheckBoxChecked[tostring(index)] = false
		config.battleRelationshipApplicationTypeIndex[tostring(index)] = 0
		config.battleRelationshipIndex[tostring(index)] = 0

		config.arisenAffinity[tostring(index)] = -1000
	end
	
	healthRemainingAmountChanged[index] = true
	staminaRemainingAmountChanged[index] = true
	posData[index] = ""

	lanternSwitchButtonClicked[index] = false
	applyStatusConditionButtonClicked[index] = false
	applyStatusConditionButtonPreviouslyClicked[index] = false
	cureAllStatusConditionButtonClicked[index] = false
	resetCurrentCharacterValuesButtonClicked[index] = false
	addScarButtonClicked[index] = false
	cureAllScarsButtonClicked[index] = false
end

local function ResetAllValues()
	for index = -1,characterHelper.GetFinalManagedCharacterIndex(config) do
		ResetCurrentCharacterValues(index, false)
	end
	
	config = GetDefaultConfig()
end

local function IsBattleRelationshipsEnabled()
	for i = -1,characterHelper.GetFinalManagedCharacterIndex(config) do
		if config.autoReapplyBattleRelationshipCheckBoxChecked[tostring(i)] then
			return true
		end
	end
	return false
end

local function SetHealth(index, character)
	local characterHitController = character:get_Hit()

	if characterHitController then

		characterHitController:set_IsNoDie(config.freezeHealth[tostring(index)])
		characterHitController:set_IsDamageZero(config.freezeHealth[tostring(index)])

		if (config.freezeHealth[tostring(index)] or healthRemainingAmountChanged[index]) then

			local getUserInput = false
			if tonumber(config.remainingHealthAmount[tostring(index)]) then
				if tonumber(config.remainingHealthAmount[tostring(index)]) > -1 then
					getUserInput = true
				end
			end
				
			if getUserInput then
				characterHitController:setHpValue(tonumber(config.remainingHealthAmount[tostring(index)]), false)
			elseif config.freezeHealth[tostring(index)] and tonumber(actualRemainingHealthAmount[index]) then					
				characterHitController:setHpValue(tonumber(actualRemainingHealthAmount[index]), false)				
			end

		end

		maxHealthAmount[index] = characterHitController:get_OriginalMaxHp()
		actualRemainingHealthAmount[index] = characterHitController:get_Hp()

	end
end

local function SetStamina(index, character)
	local characterStaminaManager = character:get_StaminaManager()

	if characterStaminaManager then

		if (config.freezeStamina[tostring(index)] or staminaRemainingAmountChanged[index]) then

			local getUserInput = false
			if tonumber(config.remainingStaminaAmount[tostring(index)]) then
				if tonumber(config.remainingStaminaAmount[tostring(index)]) > -1 then
					getUserInput = true
				end
			end
				
			if getUserInput then
				characterStaminaManager:set_RemainingAmount(tonumber(config.remainingStaminaAmount[tostring(index)]))
			elseif config.freezeStamina[tostring(index)] and tonumber(actualRemainingStaminaAmount[index]) then
				characterStaminaManager:set_RemainingAmount(tonumber(actualRemainingStaminaAmount[index]))
			end
				
		end

		maxStaminaAmount[index] = characterStaminaManager:get_MaxValue()
		actualRemainingStaminaAmount[index] = characterStaminaManager:get_RemainingAmount()

	end
end

local function SetLantern(index, character)
	if lanternSwitchButtonClicked[index] then						

		local characterHuman = character:get_Human()

		if characterHuman then					
			if lanternSwitchButtonClicked[index] then

				local characterHumanLanternController = characterHuman:get_LanternCtrl()

				if characterHumanLanternController then
					characterHumanLanternController:turn(not characterHumanLanternController:get_IsLanternOn())
				end

			end
		end

	end
end

local function SetDash(index, character)
	if config.disableAutoDashOutsideCombat then						

		local characterHuman = character:get_Human()

		if characterHuman then

			if not BattleManager:get_IsBattleMode() and config.disableAutoDashOutsideCombat then
						
				--2490904261, command hash for dash
				--4, character input action code for dash
				local isDashKeyOrButtonPressed = common.IsKeyPressedOrTriggered(2490904261, false) 
					or common.IsButtonPressedOrTriggered(4, false)

				if not isDashKeyOrButtonPressed then 
					characterHuman:set_IsDisableRun(true)
				end

			end

		end

	end
end

local function SetStatusCondition(index, character)
	local applyStatusCondition = (applyStatusConditionButtonClicked[index] 
		or (applyStatusConditionButtonPreviouslyClicked[index] and config.autoReapplyStatusConditionCheckBoxChecked[tostring(index)])) 
		and config.statusConditionIndex[tostring(index)] > -1
			
	if applyStatusCondition or not config.autoReapplyStatusConditionCheckBoxChecked[tostring(index)] or cureAllStatusConditionButtonClicked[index] then

		local characterStatusConditionCtrl = character:get_StatusConditionCtrl()

		if characterStatusConditionCtrl then

			if (applyStatusConditionButtonClicked[index] 
			or (applyStatusConditionButtonPreviouslyClicked[index] and characterStatusConditionCtrl:getStatusConditionRemainTimer(config.statusConditionIndex[tostring(index)]) < 2 and config.autoReapplyStatusConditionCheckBoxChecked[tostring(index)])) 
			and config.statusConditionIndex[tostring(index)] > -1 then

				characterStatusConditionCtrl:reqStatusConditionApply(config.statusConditionIndex[tostring(index)], false)
				--characterStatusConditionCtrl:applyStatusConditionDamageRate(config.statusConditionIndex[tostring(index)], 0)

				applyStatusConditionButtonPreviouslyClicked[index] = true

			end

			if not applyStatusConditionButtonClicked[index] and characterStatusConditionCtrl:getStatusConditionRemainTimer(config.statusConditionIndex[tostring(index)]) == 0 and not config.autoReapplyStatusConditionCheckBoxChecked[tostring(index)] then
				applyStatusConditionButtonPreviouslyClicked[index] = false
			end

			if cureAllStatusConditionButtonClicked[index] then
				characterStatusConditionCtrl:reqStatusConditionCureAllNoCureDamage()
				applyStatusConditionButtonPreviouslyClicked[index] = false
			end

		end

	end
end

local function SetPawnScars(index, character)
	if index >= 0 and index <= 2 then
		if addScarButtonClicked[index] or cureAllScarsButtonClicked[index] then

			local pawn = characterHelper.GetPawn(index)
			if pawn then
				if addScarButtonClicked[index] then
					pawn:addScar(config.scarTypeIndex[tostring(index)])
				end
				if cureAllScarsButtonClicked[index] then
					pawn:cureAllScar()
				end
			end				
		end
	end
end

local function ForceSetBattleRelationships(currentCharacter) --, currentCharacterIndex)

	if not IsBattleRelationshipsEnabled() then return end

	local isSwitchedToBattleMode = false

	for currentCharacterIndex = -1, characterHelper.GetPartyMembersFinalIndex(config) do

		local character1 = nil
		local character1CharacterID = characterHelper.GetManagedCharacterCharaID(currentCharacterIndex, config)

		if character1CharacterID and currentCharacter.CharacterID == character1CharacterID then
			character1 = currentCharacter --characterHelper.GetManagedCharacter(currentCharacterIndex, config)
		end

		if character1 and config.autoReapplyBattleRelationshipCheckBoxChecked[tostring(currentCharacterIndex)] then

			for i = -1, characterHelper.GetPartyMembersFinalIndex(config) do

				if currentCharacterIndex ~= i then

					local conditionsMet = false
					local battleRelationshipIndex
					
					local character2GroupDetails = characterHelper.GetManagedCharacterGroupDetails(i, config)
					conditionsMet = character2GroupDetails[config.battleRelationshipApplicationTypeIndex[tostring(currentCharacterIndex)]]

					if conditionsMet then
						battleRelationshipIndex = config.battleRelationshipIndex[tostring(currentCharacterIndex)]
					end

					if not conditionsMet and config.autoReapplyBattleRelationshipCheckBoxChecked[tostring(i)] then
					
						local character1GroupDetails = characterHelper.GetManagedCharacterGroupDetails(currentCharacterIndex, config)
						conditionsMet = character1GroupDetails[config.battleRelationshipApplicationTypeIndex[tostring(currentCharacterIndex)]]

						if conditionsMet then
							battleRelationshipIndex = config.battleRelationshipIndex[tostring(i)]
						end
					end

					if conditionsMet then

						local character2 = characterHelper.GetManagedCharacter(i, config)

						local PawnManager = sdk.get_managed_singleton("app.PawnManager")
						local pawnBattleController = PawnManager:get_BattleController()
						local BattleRelationshipHolder = sdk.get_managed_singleton("app.BattleRelationshipHolder")

						if battleRelationshipIndex == 1 then
							
							if i >= 0 and i <= characterHelper.GetPartyMembersFinalIndex(config) then -- character2 is pawn
								--this is the method that works
								pawnBattleController:switchToBattleMode(character2, character1)
								isSwitchedToBattleMode = true
							end
							if currentCharacterIndex >= 0 and currentCharacterIndex <= characterHelper.GetPartyMembersFinalIndex(config) then -- character1 is pawn
								pawnBattleController:switchToBattleMode(character1, character2)
								isSwitchedToBattleMode = true
							end

						elseif not isSwitchedToBattleMode then
							pawnBattleController:switchToNormalMode(0)
						end

						BattleRelationshipHolder:call("requestSetBidirectionalRelationship(app.Character, app.Character, app.Character.BattleRelationship)", character1, character2, battleRelationshipIndex)

					end

				end

			end

		end

	end

end

local function CopyNPCIDName(npcDetails)
	local configChanged = false
	if npcDetails then
		if tonumber(npcDetails.NPCIndex) >= (characterHelper.GetPartyMembersFinalIndex(config) + 1) and tonumber(npcDetails.NPCIndex) <= characterHelper.GetFinalManagedCharacterIndex(config)
			and npcDetails.CharacterIDName ~= "" then
			config.npcCharID[tostring(npcDetails.NPCIndex)] = npcDetails.CharacterIDName
			configChanged = true
		end
	end
	if configChanged then
		json.dump_file(configFileName, config)
	end
end

local function UpdateRemainingHealthAmount(characterIndex)
	local character = characterHelper.GetManagedCharacter(characterIndex, config)
	local characterHitController = character:get_Hit()
	actualRemainingHealthAmount[characterIndex] = characterHitController:get_Hp()
end

local function UpdateRemainingStaminaAmount(characterIndex)
	local character = characterHelper.GetManagedCharacter(characterIndex, config)
	local characterStaminaManager = character:get_StaminaManager()
	actualRemainingStaminaAmount[characterIndex] = characterStaminaManager:get_RemainingAmount()
end

local function TeleportToPlayerCharacterArea(characterIndex)
	if characterIndex > -1 then
		characterHelper.TeleportPartyMemberOrNPCToTargetCharacterPosition(characterIndex, config, characterHelper.GetManagedCharacter(-1, config))
	else
		local hasTeleported1NPC = false
		for j = 0, characterHelper.GetFinalManagedCharacterIndex(config) do
			hasTeleported1NPC = characterHelper.TeleportPartyMemberOrNPCToTargetCharacterPosition(j, config, characterHelper.GetManagedCharacter(-1, config))
		end
	end
end

local characterDisplayName = ""
local characterDisplayName2 = ""
local characterLabel = ""
local characterLabel2 = ""
local headerLabel = ""

local function UpdateCharacterLabels(i)

		characterDisplayName = characterHelper.GetManagedCharacterName(i, config, 2)

		characterDisplayName2 = ""
		if characterDisplayName ~= "" then
			characterDisplayName2 = "= " .. characterDisplayName
		end

		characterLabel = characterHelper.GetManagedCharacterLabel(i, config)
		characterLabel2 = characterHelper.GetManagedCharacterLabel2(i, config, config.useNamesAsLabels)

		if config.useNamesAsLabels then
			headerLabel = characterLabel .. " " .. characterDisplayName2
		else
			headerLabel = characterLabel .. " " .. characterLabel2 .. " " .. characterDisplayName2
		end

		characterDisplayName = characterHelper.GetManagedCharacterName(i, config, 1)
		if characterDisplayName == "" then
			characterDisplayName = characterLabel
		end

end
		
local windowName = ""
local function SetupManagedCharacterUI(i)

	UpdateCharacterLabels(i)

	local configChanged = false
	local changedValue = false
		
	--imgui.begin_rect()

		if i > characterHelper.GetPartyMembersFinalIndex(config) then
			if imgui.begin_table("NPC" .. tostring(i - characterHelper.GetPartyMembersFinalIndex(config)), 1, 1, {100,100}) then
				imgui.table_next_row()
				imgui.table_next_column()
				imgui.table_set_bg_color(1, common.COLOR.GRAY, 1)
				if characterDisplayName2 ~= "" then
					common.TextColoredWithOnHoverTooltip("  o ", common.COLOR.GREEN, "Персонаж существует.")
				else
					common.TextColoredWithOnHoverTooltip("  x ", common.COLOR.RED, "Персонаж не выбран или не существует.")
				end
				imgui.same_line()
				imgui.set_next_item_width(100)
				changedValue, config.npcCharID[tostring(i)] = imgui.input_text("ID персонажа NPC " .. tostring(i - characterHelper.GetPartyMembersFinalIndex(config)), config.npcCharID[tostring(i)])
				if changedValue then
					characterHelper.RefreshManagedCharacterCache(config)
				end
				configChanged = configChanged or changedValue
				imgui.end_table()
			end
		elseif i <= characterHelper.GetPartyMembersFinalIndex(config) then
			if config.npcCharID[tostring(i)] ~= "" then
				config.npcCharID[tostring(i)] = ""
				configChanged = true
			end
		end

		if imgui.collapsing_header(headerLabel) then

			--lantern and teleport section
			if imgui.begin_table("lantern and teleport", 2, 1, {200,200}) then
				--фонарь
				imgui.table_next_row()
				imgui.table_next_column()
				lanternSwitchButtonClicked[i] = imgui.button("Фонарь ВКЛ/ВЫКЛ " .. characterLabel2)

				--телепорт
				imgui.table_next_column()
				local teleportLabel = "Телепорт " .. characterLabel2
				if i == -1 then
					teleportLabel = "Телепорт ВСЕХ " .. characterLabel2
				end
				if imgui.button(teleportLabel) then
					TeleportToPlayerCharacterArea(i)
				end
				imgui.same_line()
				common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Телепортирует персонажей рядом с местоположением Восставшего.\nТакже попытается телепортировать удалённых или не загруженных NPC,\nони могут появиться немного дальше от Восставшего.")
				
				imgui.end_table()
			end

			if not config.hideHealthAndStaminaSections then

				local fsvuip = {}
				local fsvuirv
						
				--HP section
				fsvuip.characterIndex = i
				fsvuip.characterLabel = characterLabel
				fsvuip.characterLabel2 = characterLabel2
				fsvuip.sectionName = "Здоровье"
				fsvuip.sectionCode = "HP"
				fsvuip.freezeValue = config.freezeHealth[tostring(i)]
				fsvuip.remainingAmount = config.remainingHealthAmount[tostring(i)]
				fsvuip.maxAmount = maxHealthAmount[i]
				fsvuip.actualRemainingAmount = actualRemainingHealthAmount[i]
				fsvuip.criticalPercentage = (config.criticalHealthPercentage / 100)
				fsvuip.textRegularColor = common.COLOR.HP
				fsvuip.textCriticalColor = common.COLOR.HPCRITICAL
				fsvuip.textCritical2Color = common.COLOR.HPCRITICAL2

				fsvuirv  = common.SetupFreezeAndSetValueUI(fsvuip)

				changedValue = fsvuirv.freezeOptionChanged
				config.freezeHealth[tostring(i)] = fsvuirv.freezeValue
				healthRemainingAmountChanged[i] = fsvuirv.remainingAmountChanged
				config.remainingHealthAmount[tostring(i)] = fsvuirv.remainingAmount
				maxHealthAmount[i] = fsvuirv.maxAmount
				configChanged = configChanged or changedValue or healthRemainingAmountChanged[i]

				if changedValue then
					UpdateRemainingHealthAmount(i)
				end

				--stamina section					
				fsvuip.characterIndex = i
				fsvuip.characterLabel = characterLabel
				fsvuip.characterLabel2 = characterLabel2
				fsvuip.sectionName = "Выносливость"
				fsvuip.sectionCode = "STM"
				fsvuip.freezeValue = config.freezeStamina[tostring(i)]
				fsvuip.remainingAmount = config.remainingStaminaAmount[tostring(i)]
				fsvuip.maxAmount = maxStaminaAmount[i]
				fsvuip.actualRemainingAmount = actualRemainingStaminaAmount[i]
				fsvuip.criticalPercentage = (config.criticalStaminaPercentage / 100)
				fsvuip.textRegularColor = common.COLOR.STM
				fsvuip.textCriticalColor = common.COLOR.STMCRITICAL
				fsvuip.textCritical2Color = common.COLOR.STMCRITICAL2

				fsvuirv  = common.SetupFreezeAndSetValueUI(fsvuip)

				changedValue = fsvuirv.freezeOptionChanged
				config.freezeStamina[tostring(i)] = fsvuirv.freezeValue
				staminaRemainingAmountChanged[i] = fsvuirv.remainingAmountChanged
				config.remainingStaminaAmount[tostring(i)] = fsvuirv.remainingAmount
				maxStaminaAmount[i] = fsvuirv.maxAmount
				configChanged = configChanged or changedValue or staminaRemainingAmountChanged[i]

				if changedValue then
					UpdateRemainingStaminaAmount(i)
				end
					
			end

			if i == 0 or i > characterHelper.GetPartyMembersFinalIndex(config) then
				--arisen affinity
				if imgui.begin_table("status condition", 2, 1, {200,200}) then
					imgui.table_next_row()
					imgui.table_next_column()
					imgui.table_set_bg_color(1, common.COLOR.GRAY, 1)
					imgui.text_colored("Аффинити Восставшего (AA)", common.COLOR.LIGHTPURPLE)

					local currentSentimentInfoValue = characterHelper.GetManagedCharacterSentimentInfoValue(i, config)
					local currentSentimentRank = characterHelper.GetManagedCharacterSentimentRank(i, config)
							
					local sentimentColor = common.COLOR.YELLOW -- None, Normal or Like
						if (currentSentimentRank == "Love" or currentSentimentRank == "LoveMax") then
							sentimentColor = common.COLOR.RED
						elseif (currentSentimentRank == "Hate" or currentSentimentRank == "Kill" or currentSentimentRank == "KillMax") then
							sentimentColor = common.COLOR.BROWN
						end
					imgui.table_next_column()
					imgui.text_colored(tostring(currentSentimentInfoValue) .. " | " .. currentSentimentRank, sentimentColor)
					
					if i == 0 then
						tempArisenAffinity[i] = common.ChangeToDefaultIfNotANumber(tempArisenAffinity[i], 0.0)
					else
						tempArisenAffinity[i] = common.ChangeToDefaultIfNotANumber(tempArisenAffinity[i], 0)
					end
					
					imgui.table_next_row()
					imgui.table_next_column()
					changedValue, tempArisenAffinity[i] = imgui.input_text("AA " .. characterLabel2, tempArisenAffinity[i])
					imgui.same_line()
					if i == 0 then
						common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Десятичное число.")
					else
						common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Целое число.")
					end
					if imgui.button("Сохранить AA для " .. characterLabel2) then
						config.arisenAffinity[tostring(i)] = tempArisenAffinity[i]
						configChanged = true
					end

					config.arisenAffinity[tostring(i)] = common.ChangeToDefaultIfNotANumber(tonumber(config.arisenAffinity[tostring(i)]), 0)
					if i == 0 then
						config.arisenAffinity[tostring(i)] = tonumber(config.arisenAffinity[tostring(i)])
					else
						config.arisenAffinity[tostring(i)] = tonumber(string.format("%.0f", config.arisenAffinity[tostring(i)]))
					end

					if configChanged and tonumber(config.arisenAffinity[tostring(i)]) and tonumber(config.arisenAffinity[tostring(i)]) > -1000 then
						if tonumber(currentSentimentInfoValue) ~= tonumber(config.arisenAffinity[tostring(i)]) then
							characterHelper.SetManagedCharacterSentimentInfoValue(i, config, tonumber(config.arisenAffinity[tostring(i)]))
						end
					end

					imgui.table_next_column()
					imgui.spacing()

					imgui.end_table()
				end
			end

			--status condition section
			if imgui.begin_table("status condition", 2, 1, {200,200}) then
				imgui.table_next_row()
				imgui.table_next_column()
				imgui.table_set_bg_color(1, common.COLOR.GRAY, 1)
				imgui.text_colored("Состояние (SC)", common.COLOR.LIGHTBLUE)

				imgui.table_next_column()
				imgui.spacing()

				imgui.table_next_row()
				imgui.table_next_column()
				imgui.set_next_item_width(130)
				changedValue, config.statusConditionIndex[tostring(i)] = imgui.combo("Сост. " .. characterLabel2, config.statusConditionIndex[tostring(i)], common.GetCustomList("app.StatusConditionDef.StatusConditionEnum"))
				configChanged = configChanged or changedValue

				if changedValue then
					applyStatusConditionButtonClicked[i] = false
					applyStatusConditionButtonPreviouslyClicked[i] = false
					config.autoReapplyStatusConditionCheckBoxChecked[i] = false
				end

				imgui.table_next_column()
				applyStatusConditionButtonClicked[i] = imgui.button("Применить SC " .. characterLabel2)
						
				imgui.table_next_row()
				imgui.table_next_column()
				changedValue, config.autoReapplyStatusConditionCheckBoxChecked[tostring(i)] = imgui.checkbox("Авто повторное применение SC " .. characterLabel2, config.autoReapplyStatusConditionCheckBoxChecked[tostring(i)])
				configChanged = configChanged or changedValue
				imgui.same_line()
				common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Применяется только к выбранному состоянию.")

				imgui.table_next_column()
				cureAllStatusConditionButtonClicked[i] = imgui.button("Излечить все SC " .. characterLabel2)
				if cureAllStatusConditionButtonClicked[i] then					
					applyStatusConditionButtonPreviouslyClicked[i] = false
					config.autoReapplyStatusConditionCheckBoxChecked[i] = false
					configChanged = true
				end

				imgui.end_table()
			end

			--pawn scars
			if i >= 0 and i <= characterHelper.GetPartyMembersFinalIndex(config) then
				if imgui.begin_table("pawn scars", 2, 1, {100,100}) then
					imgui.table_next_row()
					imgui.table_next_column()
					imgui.table_set_bg_color(1, common.COLOR.GRAY, 1)
					imgui.text_colored("Шрамы пешки (PS)", common.COLOR.PINK)

					imgui.table_next_row()
					imgui.table_next_column()
					configChanged, config.scarTypeIndex[tostring(i)] = imgui.combo("ШР " .. characterLabel2, config.scarTypeIndex[tostring(i)], common.GetCustomList("app.PawnScarDefine.ScarType"))
					configChanged = configChanged or changedValue
					imgui.table_next_column()
					addScarButtonClicked[i] = imgui.button("Добавить PS " .. characterLabel2)

					imgui.table_next_row()
					imgui.table_next_column()
					imgui.spacing()
					imgui.table_next_column()
					cureAllScarsButtonClicked[i] = imgui.button("Излечить все PS " .. characterLabel2)

					imgui.end_table()
				end
			else
				if config.scarTypeIndex[tostring(i)] ~= 1 then
					config.scarTypeIndex[tostring(i)] = 1
					configChanged = true
				end
			end

			--battle relationship
			if imgui.begin_table("battle relationship", 2, 1, {100,100}) then
				imgui.table_next_row()
				imgui.table_next_column()
				imgui.table_set_bg_color(1, common.COLOR.GRAY, 1)
				imgui.text_colored("Боевые отношения (BR)", common.COLOR.LIGHTRED)

				local brColor
				local brText
				if config.battleRelationshipIndex[tostring(i)] == 2 then -- FRIEND
					brColor = common.COLOR.GREEN
					brText = "o"
				elseif config.battleRelationshipIndex[tostring(i)] == 1 then -- HOSTILE
					brColor = common.COLOR.RED
					brText = "x"
				else -- NEUTRAL
					brColor = common.COLOR.YELLOW
					brText = "±"
				end
				imgui.table_next_column()
				imgui.text_colored(brText, brColor)

				imgui.table_next_row()
				imgui.table_next_column()
				changedValue, config.autoReapplyBattleRelationshipCheckBoxChecked[tostring(i)] = imgui.checkbox("Установить BR " .. characterLabel2, config.autoReapplyBattleRelationshipCheckBoxChecked[tostring(i)])
				configChanged = configChanged or changedValue

				imgui.table_next_column()
				imgui.set_next_item_width(150)
				changedValue, config.battleRelationshipIndex[tostring(i)] = imgui.combo("БО " .. characterLabel2, config.battleRelationshipIndex[tostring(i)], common.GetCustomList("app.Character.BattleRelationship"))
				configChanged = configChanged or changedValue

				imgui.end_table()				
			end

			imgui.set_next_item_width(250)
			changedValue, config.battleRelationshipApplicationTypeIndex[tostring(i)] = imgui.combo("Цель BR " .. characterLabel2, config.battleRelationshipApplicationTypeIndex[tostring(i)], characterHelper.BATTLERELATIONSHIPAPPLICATIONTYPES())
			configChanged = configChanged or changedValue

			--reset section
			if imgui.begin_table("reset", 1, 1, {200,200}) then
				imgui.table_next_row()
				imgui.table_next_column()

				resetCurrentCharacterValuesButtonClicked[i] = imgui.button("Сбросить значения для " .. characterDisplayName)
				if resetCurrentCharacterValuesButtonClicked[i] then
					ResetCurrentCharacterValues(i, true)
					configChanged = true
				end

				imgui.end_table()
			end
		
			imgui.text_colored(" - ", common.COLOR.YELLOW)

		end

	--imgui.end_rect(1, 1)

	return configChanged

end

local function SetupSCSMUI()

	local configChanged = false
	local changedValue = false

	changedValue, config.disableExpAndDcpGainFromBattles = imgui.checkbox("Отключить получение EXP и DCP после боев", config.disableExpAndDcpGainFromBattles)
	configChanged = configChanged or changedValue

	changedValue, config.disableAutoDashOutsideCombat = imgui.checkbox("Отключить автоматический рывок вне боя", config.disableAutoDashOutsideCombat)
	configChanged = configChanged or changedValue
	imgui.same_line()
common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Удерживайте кнопку рывка, чтобы разрешить рывок.")

	changedValue, config.forceBattleRelationshipToPawns = imgui.checkbox("Принудительно переводить пешек в боевой режим при враждебных отношениях.", config.forceBattleRelationshipToPawns)
	configChanged = configChanged or changedValue
	imgui.same_line()
common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Опция Враждебных отношений должна быть выбрана.\nЛучше всего работает при применении к Восставшему, если в цели есть пешки.")

	imgui.set_next_item_width(150)
	changedValue, config.elvishLanguageOptionIndex = imgui.combo("Говорящие на эльфийском", config.elvishLanguageOptionIndex, {[0] = "По умолчанию", [1] = "Все", [2] = "Нет"})
	configChanged = configChanged or changedValue

	if imgui.button("Телепорт на") then
		local CharacterManager = sdk.get_managed_singleton("app.CharacterManager")
		characterHelper.TeleportCharacterBySteps(CharacterManager["<ManualPlayer>k__BackingField"], common.ChangeToDefaultIfNotANumber(stepsForward, 0), common.ChangeToDefaultIfNotANumber(stepsUpward, 0), common.ChangeToDefaultIfNotANumber(stepsToTheRight, 0))
	end
	imgui.same_line()
	imgui.set_next_item_width(50)
	_, stepsForward = imgui.input_text("Т Вперёд", stepsForward)
	if imgui.is_item_hovered() then
		imgui.set_tooltip("Отрицательное значение = назад")
	end
	imgui.same_line()
	imgui.set_next_item_width(50)
	_, stepsToTheRight = imgui.input_text("Т Вправо", stepsToTheRight)
	if imgui.is_item_hovered() then
		imgui.set_tooltip("Отрицательное значение = влево")
	end
	imgui.same_line()
	imgui.set_next_item_width(50)
	_, stepsUpward = imgui.input_text("Т Вверх", stepsUpward)
	if imgui.is_item_hovered() then
		imgui.set_tooltip("Отрицательное значение = вниз")
	end

	if imgui.tree_node(" { Группа } ") then
		for i = -1, characterHelper.GetPartyMembersFinalIndex(config) do
			changedValue = SetupManagedCharacterUI(i)
			configChanged = configChanged or changedValue
		end
		imgui.tree_pop()
	end
	if common.ChangeToDefaultIfNil(characterHelper.GetFinalManagedCharacterIndex(config), 0) > common.ChangeToDefaultIfNil(characterHelper.GetPartyMembersFinalIndex(config), 0) then
		if imgui.tree_node(" { NPC } ") then
			for i = characterHelper.GetPartyMembersFinalIndex(config) + 1, characterHelper.GetFinalManagedCharacterIndex(config) do
				changedValue = SetupManagedCharacterUI(i)
				configChanged = configChanged or changedValue
			end
			imgui.tree_pop()
		end
	end

	return configChanged

end
			
local additionalNPCIDListObjects = {}
additionalNPCIDListObjects.EnableCopyNPCDetails = true
additionalNPCIDListObjects.CopyNPCDetailsFunction = CopyNPCIDName
additionalNPCIDListObjects.EnableNPCTeleport = true

local additionalAvailableCharactersListObjects = {}

re.on_frame(function()

	local configChanged = false
	local changedValue = false

	local additionalWindowSettings = {}
	additionalWindowSettings.WindowPosition = common.WINDOWPOSITION.BOTTOMRIGHT

	windowName = modDisplayName .. " - Пользовательский журнал"
	common.ShowPopupWindow(windowName, 450, 300, common.SetupCustomLogUI, nil, additionalWindowSettings)

	additionalWindowSettings.WindowPosition = originalChildWindowPositionIndex

	additionalNPCIDListObjects.config = config

	windowName = modDisplayName .. " - Главное"
	additionalNPCIDListObjects.windowName = windowName
	changedValue = common.ShowPopupWindow(windowName, 700, 300, SetupSCSMUI, additionalNPCIDListObjects, additionalWindowSettings)
	configChanged = configChanged or changedValue

windowName = modDisplayName .. " - Список NPC"
	additionalNPCIDListObjects.windowName = windowName
	common.ShowPopupWindow(windowName, 450, 300, characterHelper.SetupNPCIDListUI, additionalNPCIDListObjects, additionalWindowSettings)

windowName = modDisplayName .. " - Список доступных персонажей"
	additionalAvailableCharactersListObjects.windowName = windowName
	common.ShowPopupWindow(windowName, 450, 300, characterHelper.SetupAvailableCharactersListUI, additionalAvailableCharactersListObjects, additionalWindowSettings)

	if config.modEnabled then

		if common.IsPausedGUI() then return end

		for i = -1,characterHelper.GetFinalManagedCharacterIndex(config) do
			local character = characterHelper.GetManagedCharacter(i, config)
			if character then
				SetHealth(i, character)
				SetStamina(i, character)
				SetLantern(i, character)
				SetDash(i, character)
				SetStatusCondition(i, character)
			end
			SetPawnScars(i)
			if character and config.forceBattleRelationshipToPawns then
				ForceSetBattleRelationships(character) --, i)
			end
		end

	end

	if configChanged then
		json.dump_file(configFileName, config)
	end

end)

re.on_draw_ui(function()

	local configChanged = false
	local changedValue = false

	--imgui.push_font(common.GetFont(0))
			
	if imgui.tree_node(modDisplayName .. " [v" .. currentVersion .. "]") then
		
		changedValue, config.modEnabled = imgui.checkbox("Включить", config.modEnabled)
		configChanged = configChanged or changedValue
		imgui.same_line()
	common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Отключает основные функции мода.\nЭто может быть полезно для проверки, вызывает ли мод проблемы с производительностью.")
		if showNotesSection then
		
			if imgui.tree_node("Заметки:") then
			
				if not versionIsAMatch_common then
					common.SetupUnmatchedModuleVersionsUI("common.lua", requiredVersion.common, common.currentVersion)
				end
				
				if not versionIsAMatch_characterHelper then
					common.SetupUnmatchedModuleVersionsUI("characterHelper.lua", requiredVersion.characterHelper, characterHelper.currentVersion)
				end
				
				imgui.tree_pop()
				
			end
			
		end
		
		if imgui.begin_table("BUTTONS", 1, 1, {300,300}) then
			imgui.table_next_row()
			imgui.table_next_column()
			imgui.table_set_bg_color(1, common.COLOR.GRAY, 1)
			imgui.text_colored(" - ", common.COLOR.DARKGREEN)
			imgui.same_line()
			windowName = modDisplayName .. " - Главное"
			common.AddShowPopupWindowButton("Менеджер", windowName)
			imgui.same_line()
			imgui.text_colored(" - ", common.COLOR.DARKGREEN)
			imgui.table_next_row()
			imgui.table_next_column()
			imgui.table_set_bg_color(1, common.COLOR.GRAY, 1)
			imgui.text_colored(" - ", common.COLOR.DARKGREEN)
			imgui.same_line()
			windowName = modDisplayName .. " - Список NPC"
			common.AddShowPopupWindowButton("Список NPC", windowName)
			imgui.same_line()
			imgui.text_colored(" - ", common.COLOR.DARKGREEN)
			imgui.same_line()
			imgui.table_next_row()
			imgui.table_next_column()
			imgui.table_set_bg_color(1, common.COLOR.GRAY, 1)
			imgui.text_colored(" - ", common.COLOR.DARKGREEN)
			imgui.same_line()
			windowName = modDisplayName .. " - Список доступных персонажей"
			common.AddShowPopupWindowButton("Список доступных персонажей", windowName)
			imgui.same_line()
			imgui.text_colored(" - ", common.COLOR.DARKGREEN)
			imgui.end_table()
		end

		if imgui.tree_node("Другие настройки") then

			changedValue, config.useNamesAsLabels = imgui.checkbox("Использовать имена как метки", config.useNamesAsLabels)
			configChanged = configChanged or changedValue

			changedValue, config.hideHealthAndStaminaSections = imgui.checkbox("Скрыть секции HP и STM", config.hideHealthAndStaminaSections)
			configChanged = configChanged or changedValue

			imgui.set_next_item_width(50)
			changedValue, config.criticalHealthPercentage = imgui.input_text("Критическое здоровье %", config.criticalHealthPercentage)
			configChanged = configChanged or changedValue
			imgui.same_line()
			common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Процент, используемый при расчёте предполагаемого критического здоровья персонажей.")

			imgui.set_next_item_width(50)
			changedValue, config.criticalStaminaPercentage = imgui.input_text("Критическая выносливость %", config.criticalStaminaPercentage)
			configChanged = configChanged or changedValue
			imgui.same_line()
			common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Процент, используемый при расчёте предполагаемой критической выносливости персонажей.")

			originalChildWindowPositionIndex = common.GetCurrentListIndex(common.WINDOWPOSITIONS, config.originalChildWindowPosition)
			imgui.set_next_item_width(150)
			changedValue, originalChildWindowPositionIndex = imgui.combo("Позиция дочернего окна по умолчанию", originalChildWindowPositionIndex, common.WINDOWPOSITIONS)
			config.originalChildWindowPosition = common.WINDOWPOSITIONS[originalChildWindowPositionIndex]
			configChanged = configChanged or changedValue

			resetAllValuesClicked = imgui.button("Сбросить ВСЕ значения") 
			if resetAllValuesClicked then
				ResetAllValues()
				configChanged = true
			end

			imgui.spacing()

			imgui.set_next_item_width(50)
			_, tempMaxNPCCount = imgui.input_text("Количество слотов NPC", tempMaxNPCCount)
			imgui.same_line()
			if imgui.button("Обновить слоты NPC") then
				config.maxManagedNPCCount = tempMaxNPCCount
				json.dump_file(configFileName, config)
				ReadConfig()
			end
			imgui.same_line()
			common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Количество слотов обновится только после нажатия кнопки [Обновить слоты NPC].\nУменьшение числа слотов может удалить сохранённые настройки для удалённых слотов.")
			
			imgui.spacing()
			imgui.text("---")
			imgui.spacing()
			
windowName = modDisplayName .. " - Пользовательский журнал"
		common.AddShowPopupWindowButton("Пользовательский журнал", windowName)

			imgui.tree_pop()

		end
		
		if configChanged then
			json.dump_file(configFileName, config)
		end

		imgui.tree_pop()

	end
	
	--imgui.pop_font()

end)

sdk.hook(sdk.find_type_definition("app.BattleRelationshipHolder"):get_method("getRelationshipFromTo(app.Character, app.Character)"),
    function(args)

	if config.modEnabled then

		if IsBattleRelationshipsEnabled() then

			local character1 = sdk.to_managed_object(args[3])
			local character2 = sdk.to_managed_object(args[4])

			if character1 and character2 then
				local battleRelInfo = characterHelper.SetBattleRelationship(character1, character2,
					config, config.battleRelationshipIndex, config.autoReapplyBattleRelationshipCheckBoxChecked,
					config.battleRelationshipApplicationTypeIndex) --, false) --config.forceBattleRelationshipToPawns)

				common.SetHookStorageValue("battleRelInfo", battleRelInfo)

				if battleRelInfo then
					if battleRelInfo.shouldReturnNewBattleRelationship then
						return sdk.PreHookResult.SKIP_ORIGINAL
					end
				end
			end

		end

	end

    end,
    function(retval)

	if config.modEnabled then
	
		battleRelInfo = common.GetHookStorageValue("battleRelInfo")

		if battleRelInfo then
			if battleRelInfo.shouldReturnNewBattleRelationship then
				return sdk.to_ptr(battleRelInfo.newBattleRelationship)
			end
		end

	end

	return retval

    end
)

local function PreGetExp()
	common.SetHookStorageValue("allowGetExpDcp", true)
	if config.disableExpAndDcpGainFromBattles then	
		common.SetHookStorageValue("allowGetExpDcp", false)
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end

local function PostGetExp(retval)
	if not common.GetHookStorageValue("allowGetExpDcp") then
		return sdk.to_ptr(0)
	else
		return retval
	end
end

sdk.hook(sdk.find_type_definition("app.ExpDispenser.ExpGranter"):get_method("evaluateExpAmount(System.Int32, app.HitController.DamageInfo, app.Character)"),
    function(args)
	if config.modEnabled then
		return PreGetExp()
	end
    end,
    function(retval)
	if config.modEnabled then
		return PostGetExp(retval)
	else
		return retval
	end
    end
)

sdk.hook(sdk.find_type_definition("app.ExpDispenser.ExpGranter"):get_method("adjustExpByCharacterAttack(app.Character, System.Int32, app.Character)"),
    function(args)
	if config.modEnabled then
		return PreGetExp()
	end
    end,
    function(retval)
	if config.modEnabled then
		return PostGetExp(retval)
	else
		return retval
	end
    end
)

sdk.hook(sdk.find_type_definition("app.TalkEventManager"):get_method("isElfSpeakingCharacter(app.CharacterID)"),
    function(args)	
    end,
    function(retval)
	if config.modEnabled then
		if config.elvishLanguageOptionIndex == 1 then
			return sdk.to_ptr(true)
		elseif config.elvishLanguageOptionIndex == 2 then
			return sdk.to_ptr(false)
		end
	end
	return retval
    end
)

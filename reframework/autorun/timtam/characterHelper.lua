local common

local currentVersion = "1.1.10"

local NPCManager = sdk.get_managed_singleton("app.NPCManager")
local CharacterManager = sdk.get_managed_singleton("app.CharacterManager")
local PawnManager = sdk.get_managed_singleton("app.PawnManager")
local CharacterListHolder = sdk.get_managed_singleton("app.CharacterListHolder")

local partyMembersMaxCount = {} --4
local partyMembersFinalIndex = {}
local managedNPCCount = {} --0
local totalManagedCharacters = {} -- partyMembersMaxCount + managedNPCCount
local finalManagedCharacterIndex = {} -- totalManagedCharacters - 2

local npcNameSearchString = ""
local tempNPCNameSearchString = ""
local availableCharacterSearchString = ""
local tempAvailableCharacterSearchString = ""
local currentlySelectedNPCIndex = 0
local filteredNPCList
local filteredNPCListNames
local copyCharacterIDNPCIndex = 0
local copyCharacterIDNPCIndex2 = -2
local refreshListsWhenPausedGUI = false

local generateNPCNPCCharID

local BATTLERELATIONSHIPAPPLICATIONTYPES = {
	[0] = "ALL",
	[1] = "ALL except party and selected NPCs",
	[2] = "Party and selected NPCs only",
	[3] = "Party only",
	[4] = "Selected NPCs only",
	[5] = "ALL except Pawns",
	[6] = "Pawns only",
	[7] = "ALL except Arisen",
	[8] = "Arisen only"
}

local BATTLERELATIONSHIPAPPLICATIONTYPE = {
	ALL = 0,
	ALLEXCEPTPARTYANDSELECTEDNPCS = 1,
	PARTYANDSELECTEDNPCS = 2,
	PARTYONLY = 3,
	SELECTEDNPCSONLY = 4,
	ALLEXCEPTPAWNS = 5,
	PAWNSONLY = 6,
	ALLEXCEPTARISEN = 7,
	ARISENONLY = 8
}

local characterHelperCache = {}

characterHelperCache.managedCharacter = {}
characterHelperCache.managedCharacterIndex = {}
characterHelperCache.managedCharacterName = {}
characterHelperCache.npcNames = {}

characterHelperCache.managedCharacterGroupDetails = {}
characterHelperCache.managedCharacterGroupDetails[0] = {}
characterHelperCache.managedCharacterGroupDetails[0][BATTLERELATIONSHIPAPPLICATIONTYPE.ALL] = true
characterHelperCache.managedCharacterGroupDetails[0][BATTLERELATIONSHIPAPPLICATIONTYPE.ALLEXCEPTPARTYANDSELECTEDNPCS] = false
characterHelperCache.managedCharacterGroupDetails[0][BATTLERELATIONSHIPAPPLICATIONTYPE.PARTYANDSELECTEDNPCS] = true
characterHelperCache.managedCharacterGroupDetails[0][BATTLERELATIONSHIPAPPLICATIONTYPE.PARTYONLY] = true
characterHelperCache.managedCharacterGroupDetails[0][BATTLERELATIONSHIPAPPLICATIONTYPE.SELECTEDNPCSONLY] = false
characterHelperCache.managedCharacterGroupDetails[0][BATTLERELATIONSHIPAPPLICATIONTYPE.ALLEXCEPTPAWNS] = true
characterHelperCache.managedCharacterGroupDetails[0][BATTLERELATIONSHIPAPPLICATIONTYPE.PAWNSONLY] = false
characterHelperCache.managedCharacterGroupDetails[0][BATTLERELATIONSHIPAPPLICATIONTYPE.ALLEXCEPTARISEN] = false
characterHelperCache.managedCharacterGroupDetails[0][BATTLERELATIONSHIPAPPLICATIONTYPE.ARISENONLY] = true
characterHelperCache.managedCharacterGroupDetails[1] = {}
characterHelperCache.managedCharacterGroupDetails[1] [BATTLERELATIONSHIPAPPLICATIONTYPE.ALL] = true
characterHelperCache.managedCharacterGroupDetails[1] [BATTLERELATIONSHIPAPPLICATIONTYPE.ALLEXCEPTPARTYANDSELECTEDNPCS] = false
characterHelperCache.managedCharacterGroupDetails[1] [BATTLERELATIONSHIPAPPLICATIONTYPE.PARTYANDSELECTEDNPCS] = true
characterHelperCache.managedCharacterGroupDetails[1] [BATTLERELATIONSHIPAPPLICATIONTYPE.PARTYONLY] = true
characterHelperCache.managedCharacterGroupDetails[1] [BATTLERELATIONSHIPAPPLICATIONTYPE.SELECTEDNPCSONLY] = false
characterHelperCache.managedCharacterGroupDetails[1] [BATTLERELATIONSHIPAPPLICATIONTYPE.ALLEXCEPTPAWNS] = false
characterHelperCache.managedCharacterGroupDetails[1] [BATTLERELATIONSHIPAPPLICATIONTYPE.PAWNSONLY] = true
characterHelperCache.managedCharacterGroupDetails[1] [BATTLERELATIONSHIPAPPLICATIONTYPE.ALLEXCEPTARISEN] = true
characterHelperCache.managedCharacterGroupDetails[1] [BATTLERELATIONSHIPAPPLICATIONTYPE.ARISENONLY] = false
characterHelperCache.managedCharacterGroupDetails[2] = {}
characterHelperCache.managedCharacterGroupDetails[2][BATTLERELATIONSHIPAPPLICATIONTYPE.ALL] = true
characterHelperCache.managedCharacterGroupDetails[2][BATTLERELATIONSHIPAPPLICATIONTYPE.ALLEXCEPTPARTYANDSELECTEDNPCS] = false
characterHelperCache.managedCharacterGroupDetails[2][BATTLERELATIONSHIPAPPLICATIONTYPE.PARTYANDSELECTEDNPCS] = true
characterHelperCache.managedCharacterGroupDetails[2][BATTLERELATIONSHIPAPPLICATIONTYPE.PARTYONLY] = false
characterHelperCache.managedCharacterGroupDetails[2][BATTLERELATIONSHIPAPPLICATIONTYPE.SELECTEDNPCSONLY] = true
characterHelperCache.managedCharacterGroupDetails[2][BATTLERELATIONSHIPAPPLICATIONTYPE.ALLEXCEPTPAWNS] = true
characterHelperCache.managedCharacterGroupDetails[2][BATTLERELATIONSHIPAPPLICATIONTYPE.PAWNSONLY] = false
characterHelperCache.managedCharacterGroupDetails[2][BATTLERELATIONSHIPAPPLICATIONTYPE.ALLEXCEPTARISEN] = true
characterHelperCache.managedCharacterGroupDetails[2][BATTLERELATIONSHIPAPPLICATIONTYPE.ARISENONLY] = false

local SentimentRanks = nil
local CharacterIDs = nil
local CharacterIDNames = nil

local function PopulateLists()

	SentimentRanks = common.generate_enum_reverse("app.SentimentRank")
	CharacterIDs = common.generate_enum("app.CharacterID")
	CharacterIDNames = common.generate_enum_reverse("app.CharacterID")
	
end

local function SetCommon(newCommon)
	common = newCommon
	PopulateLists()
end

local function InitializeCharacterHelper(config, pPartyMembersMaxCount, pManagedNPCCount, pRefreshListsWhenPausedGUI)
	partyMembersMaxCount[config.modname] = common.ChangeToDefaultIfNotANumber(pPartyMembersMaxCount, 4)
	partyMembersFinalIndex[config.modname] = partyMembersMaxCount[config.modname] - 2
	managedNPCCount[config.modname] = pManagedNPCCount
	totalManagedCharacters[config.modname] = partyMembersMaxCount[config.modname] + managedNPCCount[config.modname]
	finalManagedCharacterIndex[config.modname] = totalManagedCharacters[config.modname] - 2
	refreshListsWhenPausedGUI = pRefreshListsWhenPausedGUI
end

local function GetPartyMembersMaxCount(config)
	return partyMembersMaxCount[config.modname]
end

local function GetPartyMembersFinalIndex(config)
	return partyMembersFinalIndex[config.modname]
end

local function GetManagedNPCCount(config)
	return managedNPCCount[config.modname]
end

local function GetManagedCharacterCount(config)
	return totalManagedCharacters[config.modname]
end

local function GetFinalManagedCharacterIndex(config)
	return finalManagedCharacterIndex[config.modname]
end

local function GenerateManagedNPCIndexList(pManagedNPCCount)
	local list = {}
		for i = 0, pManagedNPCCount - 1 do
			list[i] = tostring(i + 1)
		end
	return list
end

local function GetCharacterNameByCharacterID(charaID) 
	return sdk.find_type_definition("app.GUIBase"):get_method("getName(app.CharacterID)")(nil, charaID)
	--return sdk.find_type_definition("app.GUIBase"):get_method("getElfName(app.CharacterID)")(nil, charaID)
end

local function GetCharacterIDName(charaID)	
	local characterIDName = ""
	--local characterIDList = common.GetCustomList("app.CharacterID")
	--if characterIDList[charaID] then
	--	characterIDName = characterIDList[charaID]
	--end
	characterIDName = CharacterIDNames[charaID]
	return characterIDName	
end

local function GetCharaID(charaIDName)
	local charaID = ""
	--local charaIDField = sdk.find_type_definition("app.CharacterID"):get_field(charaIDName)	
	--if charaIDField then
	--	charaID = charaIDField:get_data()
	--end
	charaID = CharacterIDs[charaIDName]	
	return charaID
end

local function GetCharacterGameObjectName(character)
	if character and common.IsPlayerCharacterReady() then
		local characterGameObject = character:get_GameObject()
		if characterGameObject then
			return characterGameObject:get_Name()
		end
	end
	return nil
end

local function GenerateCharacterDetails(character, charaIDList)
	local characterDetails = {}
	if character then
		local characterGameObjectName = GetCharacterGameObjectName(character)
		local charaID = character.CharacterID
		local newCharaID
		local charaIDDuplicatesFound = common.FindListMatch(charaIDList, charaID, false)
		if charaIDDuplicatesFound > 0 then
			newCharaID = charaID .. "(" .. tostring(charaIDDuplicatesFound + 1) .. ")"
		else
			newCharaID = charaID
		end
		characterDetails.Character = character
		characterDetails.CharaID = charaID
		characterDetails.NewCharaID = newCharaID
		characterDetails.CharacterGameObjectName = characterGameObjectName
		characterDetails.CharacterIDName = GetCharacterIDName(charaID)
		characterDetails.CharacterName = GetCharacterNameByCharacterID(charaID)
	end
	return characterDetails
end

local function GetAvailableCharacterDetailsList()
	local availableCharacterDetailsList
	if not common.GetCustomListIsPopulated("AvailableCharacterDetailsList") or (refreshListsWhenPausedGUI and common.IsPausedGUI() and not common.IsPausedGUIBefore("characterHelper", "GetAvailableCharacterDetailsList")) then
		local availableCharacters = CharacterListHolder:getAllCharacters()
		local charaIDList = {}
		availableCharacterDetailsList = {}
		if CharacterManager["<ManualPlayer>k__BackingField"] then
			local characterGameObjectName = GetCharacterGameObjectName(CharacterManager["<ManualPlayer>k__BackingField"])
			if characterGameObjectName then
				availableCharacterDetailsList[characterGameObjectName] = GenerateCharacterDetails(CharacterManager["<ManualPlayer>k__BackingField"], charaIDList)
				charaIDList[1] = CharacterManager["<ManualPlayer>k__BackingField"].CharacterID
			end
		end
		for i, availableCharacter in ipairs(availableCharacters) do
			local characterGameObjectName = GetCharacterGameObjectName(availableCharacter)
			if characterGameObjectName then
				availableCharacterDetailsList[characterGameObjectName] = GenerateCharacterDetails(availableCharacter, charaIDList)
				charaIDList[i + 1] = availableCharacter.CharacterID
			end
		end
		common.SetCustomList("AvailableCharacterDetailsList", availableCharacterDetailsList)
		common.SetCustomListIsPopulated("AvailableCharacterDetailsList", true)
	else
		availableCharacterDetailsList = common.GetCustomList("AvailableCharacterDetailsList")
	end
	common.UpdateIsPausedGUIBefore("characterHelper", "GetAvailableCharacterDetailsList")
	return availableCharacterDetailsList
end

local function GetCharacterByCharaID(charaID)	
	local availableCharacterDetailsList = GetAvailableCharacterDetailsList()
	for i, availableCharacterDetails in pairs(availableCharacterDetailsList) do
		if availableCharacterDetails.NewCharaID == charaID then
			return availableCharacterDetails.Character
		end
	end
	return nil
end

local function GetCharacterDetailsByCharacterIDName(charaIDName)
	local availableCharacterDetailsList = GetAvailableCharacterDetailsList()
	return availableCharacterDetailsList[charaIDName]
	--for i, availableCharacterDetails in ipairs(availableCharacterDetailsList) do
	--	if availableCharacterDetails.CharacterGameObjectName == charaIDName then
	--		return availableCharacterDetails
	--	end
	--end
	--return nil
end

local function GetCharacterByCharacterIDName(charaIDName)
	local characterDetails = GetCharacterDetailsByCharacterIDName(charaIDName)
	if characterDetails then
		return characterDetails.Character
	end
	return nil
end

local function GetCharacterNameByCharacterIDName(charaIDName)
	local characterDetails = GetCharacterDetailsByCharacterIDName(charaIDName)
	if characterDetails then
		return characterDetails.CharacterName
	end
	return ""
end

local function GetNewCharacterIDName(charaID)	
	local availableCharacterDetailsList = GetAvailableCharacterDetailsList()
	for i, availableCharacterDetails in pairs(availableCharacterDetailsList) do
		if availableCharacterDetails.NewCharaID == charaID then
			return availableCharacterDetails.CharacterGameObjectName
		end
	end
	return ""	
end

local function GetNewCharaIDByCharaIDName(charaIDName)
	local availableCharacterDetailsList = GetAvailableCharacterDetailsList()
	if availableCharacterDetailsList[charaIDName] then
		return availableCharacterDetailsList[charaIDName].NewCharaID
	else
		return nil
	end
end

local function GetNewCharaID(pCharacter)
	local characterGameObjectName = GetCharacterGameObjectName(pCharacter)
	local newCharaID
	if characterGameObjectName then
		newCharaID = GetNewCharaIDByCharaIDName(characterGameObjectName)
	end
	if newCharaID == nil then
		newCharaID = pCharacter.CharacterID
	end
	return newCharaID
end

local function GetNPC(npcCharID)
	local npcCharacter = nil
	local charaID = GetCharaID(npcCharID)	
	if charaID then
		npcCharacter = NPCManager:getCharacter(charaID)
	end
	if npcCharacter == nil then
		npcCharacter = GetCharacterByCharacterIDName(npcCharID)
	end
	return npcCharacter
end

local function GetNPCName(npcCharID)	
	local characterName = ""
	if characterHelperCache.npcNames[npcCharID] ~= nil then
		characterName = characterHelperCache.npcNames[npcCharID]
	else
		local characterData
		local charaID = GetCharaID(npcCharID)
		if charaID then
			characterName = GetCharacterNameByCharacterID(charaID)
			if characterName == "" then
				characterData = NPCManager:getNPCCharacterData(charaID)
				if characterData then
					--characterName = characterData:get_Name()
					characterName = characterData:get_ElfLanguageName()
				end
			end
			if string.find(tostring(characterName):lower(), "?") then
				if not characterData then
					characterData = NPCManager:getNPCCharacterData(charaID)
				end
				if characterData then
					--characterName = characterData:get_Name() .. "*"
					characterName = characterData:get_ElfLanguageName() .. "*"
				end
			end
		end
		if characterName == "" then
			characterName = GetCharacterNameByCharacterIDName(npcCharID)
		else
			characterHelperCache.npcNames[npcCharID] = characterName
		end
	end
	return characterName
end

local function GetEnemy(character)
	if character then
		local enemyController = character:get_EnemyController()
		if enemyController then
				return enemyController.Ch2
		end
	end
	return nil
end

local function GetMonster(character)
	local enemy = GetEnemy(character)
	if enemy then
		return enemy._Monster
	end
	return nil
end

local function GetNPCSpecies(npcCharID)
	local characterData
	local charaID = GetCharaID(npcCharID)
	if charaID then
		characterData = NPCManager:getNPCCharacterData(charaID)
		if characterData then
			return characterData:get_appSpecies()
		end
	end
end

local function GetNPCGender(npcCharID)
	local characterData
	local charaID = GetCharaID(npcCharID)
	if charaID then
		characterData = NPCManager:getNPCCharacterData(charaID)
		if characterData then
			return characterData:get_appGender()
		end
	end
end

local function IsNPCDead(npcCharID)
	local isDead = false
	local charaID = GetCharaID(npcCharID)
	if charaID then
		isDead = NPCManager:NPCisDead(charaID)
	end
	return isDead
end

local function GetNPCSentimentInfoValue(npcCharID, targetCharaID, isCreate)
	local charaID = GetCharaID(npcCharID)
	if charaID then
		local npcHolder = NPCManager:getNPCHolder(charaID)
		if npcHolder then
			local sentimentInfo = npcHolder:getSentimentInfo(targetCharaID, isCreate)
			if sentimentInfo then
				return sentimentInfo.Value
			end
		end
	end
	return 0
end

local function SetNPCSentimentInfoValue(npcCharID, targetCharaID, sentimentInfoValue, isCreate)
	local charaID = GetCharaID(npcCharID)
	if charaID then
		local npcHolder = NPCManager:getNPCHolder(charaID)
		if npcHolder then
			local sentimentInfo = npcHolder:getSentimentInfo(targetCharaID, isCreate)
			if sentimentInfo then
				local isLoad = true
				npcHolder:call("setSentimentValue(app.CharacterID, app.SentimentInfo, System.Int32, System.Boolean)", targetCharaID, sentimentInfo, sentimentInfoValue, isLoad)
			end
		end
	end
end

local function GetNPCSentimentRank(npcCharID, targetCharaID)
	local charaID = GetCharaID(npcCharID)
	if charaID then
		local npcHolder = NPCManager:getNPCHolder(charaID)
		if npcHolder then
			local sentimentRank = npcHolder:call("getSentimentRank(app.CharacterID)", targetCharaID)
			if sentimentRank then
				if SentimentRanks[sentimentRank] then					
					return SentimentRanks[sentimentRank]
				end
			end
		end
	end
	return "Invalid"
end

local function GetNPCList()
	local npcList
	if not common.GetCustomListIsPopulated("NPCDetailsList") or (refreshListsWhenPausedGUI and common.IsPausedGUI() and not common.IsPausedGUIBefore("characterHelper", "GetAvailableCharacterDetailsList")) then
		characterHelperCache.npcNames = {}
		npcList = {}
		local ctr = 0
		local j
		if NPCManager.NPCHolderDic then
			for i, npcHolder in pairs (NPCManager.NPCHolderDic) do
				if npcHolder then
					j = i

					local characterIDName = GetCharacterIDName(npcHolder.CharaID)

					npcList[j] = {}
					npcList[j].CharaID = npcHolder.CharaID
					npcList[j].ActualCharaID = npcHolder.CharaID
					npcList[j].CharacterIDName = characterIDName
					npcList[j].Name = GetNPCName(characterIDName)
					npcList[j].NPCHolderIndex = i
					npcList[j].NPCListIndex = ctr
					npcList[j].IsDead = NPCManager:NPCisDead(npcHolder.CharaID)
					
					local characterData = NPCManager:getNPCCharacterData(npcHolder.CharaID)
					if characterData then
						npcList[j].GenderCode = characterData:get_appGender()
						npcList[j].SpeciesCode = characterData:get_appSpecies()
					else					
						npcList[j].GenderCode = 0
						npcList[j].SpeciesCode = 0
					end

					npcList[j].AliveStatusString = common.GetAliveStatusString(npcList[j].IsNPCDead)
					npcList[j].SpeciesString = common.GetSpeciesString(npcList[j].SpeciesCode)
					npcList[j].GenderString = common.GetGenderString(npcList[j].GenderCode)

					npcList[j].GenderSpeciesString = string.sub(npcList[j].GenderString, 1, 3) .. string.sub(npcList[j].SpeciesString, 1, 3)
					
					ctr = ctr + 1

				end
			end
		end
		local availableCharacterDetailsList = GetAvailableCharacterDetailsList()
		for i, availableCharacterDetails in pairs(availableCharacterDetailsList) do
			if availableCharacterDetails.CharacterGameObjectName ~= "ch000000_00" and common.FindListFieldValueMatch(npcList, "CharacterIDName", availableCharacterDetails.CharacterGameObjectName, true) == 0 then
			--availableCharacter:get_Human() and
			
				j = j + 1
				npcList[j] = {}
				npcList[j].CharaID = availableCharacterDetails.NewCharaID
				npcList[j].CharacterIDName = availableCharacterDetails.CharacterGameObjectName
				npcList[j].Name = availableCharacterDetails.CharacterName
				npcList[j].NPCHolderIndex = -1
				npcList[j].NPCListIndex = ctr
				npcList[j].IsDead = false
				
				local characterData = NPCManager:getNPCCharacterData(charaID)
				if characterData then
					npcList[j].GenderCode = characterData:get_appGender()
					npcList[j].SpeciesCode = characterData:get_appSpecies()
				else					
					npcList[j].GenderCode = 0
					npcList[j].SpeciesCode = 0
				end

				npcList[j].AliveStatusString = common.GetAliveStatusString(npcList[j].IsNPCDead)
				npcList[j].SpeciesString = common.GetSpeciesString(npcList[j].SpeciesCode)
				npcList[j].GenderString = common.GetGenderString(npcList[j].GenderCode)

				npcList[j].GenderSpeciesString = string.sub(npcList[j].GenderString, 1, 3) .. string.sub(npcList[j].SpeciesString, 1, 3)
				
				ctr = ctr + 1
				
			end
		end
		-- sort alphabetically
    		--table.sort(npcList, function(npc1,npc2)
		--	if not npc1 and not npc2 then
		--		return false
		--	end
		--	if not npc1 then
		--		return true
		--	end
		--	if not npc2 then
		--		return false
		--	end
		--	return npc1.Name:lower() < npc2.Name:lower()
		--end
		--)
		common.SetCustomList("NPCDetailsList", npcList)
		common.SetCustomListIsPopulated("NPCDetailsList", true)
	else
		npcList = common.GetCustomList("NPCDetailsList")
	end
	common.UpdateIsPausedGUIBefore("characterHelper", "GetAvailableCharacterDetailsList")
	return npcList
end

local function IsPawn(character)
	local PawnUtil = common.NewValueType("app.PawnUtil")
	return PawnUtil:isPawn(character.CharacterID)
end

local function IsNPCOnly(npcCharID)
	local npcCharacter = nil
	local charaID = GetCharaID(npcCharID)	
	if charaID then
		npcCharacter = NPCManager:getCharacter(charaID)
		if npcCharacter then
			return not IsPawn(npcCharacter)
		end
	end
	return false
end

local function IsOnlinePawn(character)
	local PawnUtil = common.NewValueType("app.PawnUtil")
	return PawnUtil:call("isOnlinePawn(app.Character)", character)
end

local function GetPawn(index)
	local pawn
	if index == 0 then
		pawn = PawnManager:get_MainPawn()
	else
		local pawnArray = PawnManager:get_PartyPawnList()
		if pawnArray and pawnArray:get_Count() > index then
			pawn = pawnArray[index]
			if pawn then
				if index == 1 and tonumber(PawnManager:getPartyPawnID(pawn)) ~= 1 then
					pawn = pawnArray[2]
				elseif index == 2 and tonumber(PawnManager:getPartyPawnID(pawn)) ~= 2 then
					pawn = pawnArray[1]
				end
			end
		end
	end
	return pawn
end

local function GetMainPawnFavorability()
	local pawn = GetPawn(0)
	if pawn then
		local mpdc = pawn.MainPawnDataContext
		return mpdc._FavorabilityRating
	end
	return 0
end

local function SetMainPawnFavorability(favorabilityValue)
	local pawn = GetPawn(0)
	if pawn then
		local mpdc = pawn.MainPawnDataContext
		if mpdc then
			return mpdc:setFavorabilityRating(favorabilityValue)
		end
	end
end

local function GetMainPawnIsLove()
	local pawn = GetPawn(0)
	if pawn then
		local mpdc = pawn.MainPawnDataContext
		if mpdc then
			return mpdc:get_IsLove()
		end
	end
	return false
end

local tempNPCLocation = {}
local function GetNPCLocation(npcCharID, checkSpam)
	local npcLocation = nil	
	local charaID = GetCharaID(npcCharID)
	if charaID then
		local npcData = NPCManager:getNPCData(charaID)
		if not npcData then
			return npcLocation
		end
		local npcCharacter
		npcCharacter = NPCManager:getCharacter(charaID)
		if npcCharacter then
			npcLocation = npcCharacter["<Transform>k__BackingField"]:get_UniversalPosition()
			if common.GetBooleanValue(checkSpam) then
				tempNPCLocation["npcLocation" .. charaID] = nil
			end
		end
		if not npcLocation then
			npcCharacter = CharacterListHolder:getCharacter(charaID)
			if npcCharacter then
				npcLocation = npcCharacter["<Transform>k__BackingField"]:get_UniversalPosition()
				if common.GetBooleanValue(checkSpam) then
					tempNPCLocation["npcLocation" .. charaID] = nil
				end
			end
		end
		if not npcLocation then
			local isNotSpamming = true
			if common.GetBooleanValue(checkSpam) then
				isNotSpamming = common.SpamRequestCheckPassed("npcLocation" .. charaID, 2)
			end
			if isNotSpamming then
				local npcHolder = NPCManager:getNPCHolder(charaID)
				if npcHolder then
					npcLocation = npcHolder:get_UniversalPosition()
					if common.GetBooleanValue(checkSpam) then
						tempNPCLocation["npcLocation" .. charaID] = npcLocation
					end
				end
			elseif common.GetBooleanValue(checkSpam) then
				npcLocation = tempNPCLocation["npcLocation" .. charaID]
			end
		end
	end
	return npcLocation
end

local function GetNPCRotation(npcCharID)
	local npcRotation = nil	
	local charaID = GetCharaID(npcCharID)
	if charaID then
		local npcData = NPCManager:getNPCData(charaID)
		if not npcData then
			return npcRotation
		end
		local npcCharacter
		npcCharacter = NPCManager:getCharacter(charaID)
		if npcCharacter then
			npcRotation = npcCharacter["<Transform>k__BackingField"]:get_LocalRotation()
		end
		if not npcRotation then
			npcCharacter = CharacterListHolder:getCharacter(charaID)
			if npcCharacter then
				npcRotation = npcCharacter["<Transform>k__BackingField"]:get_LocalRotation()
			end
		end
		if not npcRotation then
			local npcHolder = NPCManager:getNPCHolder(charaID)
			if npcHolder then
				npcRotation = npcHolder:get_Rotation()
			end
		end
	end
	return npcRotation
end

local function GetDistanceFromPlayerCharacter(position, doubleY)
	if doubleY == nil then
		doubleY = true
	end
	local distance = {}
	distance.x = 99999999
	distance.y = 99999999
	distance.z = 99999999
	distance.total = 399999996
	local player = CharacterManager["<ManualPlayer>k__BackingField"]
	if player and position then
		local playerTransform = player:get_Transform() --["<Transform>k__BackingField"]
		if playerTransform then
			local playerUniversalPosition = playerTransform:get_UniversalPosition()
			if playerUniversalPosition then
				distance.x = playerUniversalPosition.x - position.x
				distance.y = playerUniversalPosition.y - position.y
				distance.z = playerUniversalPosition.z - position.z
				distance.total = math.abs(distance.x) + math.abs(distance.y) + math.abs(distance.z)
				if doubleY then
					distance.total = distance.total  + math.abs(distance.y)
				end
				return distance
			end
		end
	end
	return distance
end

local function IsPositionNearPlayerCharacter(position, nearDistance)
	local distance = GetDistanceFromPlayerCharacter(position)
	if math.abs(distance.x) <= nearDistance and math.abs(distance.y) <= nearDistance and math.abs(distance.z) <= nearDistance then
		return true
	end
	return false
end

local function GetManagedCharacterName(index, config, nameType)
	local characterName = ""
	--local charaID = ""
	if index == -1 then
		local player = CharacterManager["<ManualPlayer>k__BackingField"]
		if player then
			characterName = GetCharacterNameByCharacterID(player.CharacterID)
			--charaID = player.CharacterID
		end
	else
		if index >= 0 and index <= (partyMembersFinalIndex[config.modname]) then
			local pawn = GetPawn(index)
			if pawn then
				local pawnCharacter = pawn["<CachedCharacter>k__BackingField"]
				local pawnDataContext = pawn["<CachedAIGoalPlanning>k__BackingField"]._CachedPawnContext
				if pawnCharacter and pawnDataContext then                			
					if nameType == 1 then
						characterName = pawnDataContext._Nickname
					elseif nameType == 2 then
						characterName = pawnDataContext._Name .. " / " .. pawnDataContext._Nickname
					else
						characterName = pawnDataContext._Name
					end
					--charaID = pawnCharacter.CharacterID
				end
			end
		else
			characterName = GetNPCName(config.npcCharID[tostring(index)])
			--charaID = GetCharaID(config.npcCharID[tostring(index)])
		end
	end
	return characterName
end

local function GetManagedCharacter(index, config)
	if characterHelperCache.managedCharacter[config.modname] == nil then
		characterHelperCache.managedCharacter[config.modname] = {}
	end
	if characterHelperCache.managedCharacter[config.modname][index] == nil then
		characterHelperCache.managedCharacter[config.modname][index] = {}
	end
	local shouldRefreshCharacter = true --false
	if characterHelperCache.managedCharacter[config.modname][index].Character == nil or characterHelperCache.managedCharacter[config.modname][index].PartSwapper == nil or not characterHelperCache.managedCharacter[config.modname][index].Character:get_Valid() then
		shouldRefreshCharacter = true
	end
	if not shouldRefreshCharacter and characterHelperCache.managedCharacter[config.modname][index].Character ~= nil then
		shouldRefreshCharacter = (index > (partyMembersFinalIndex[config.modname]) and (characterHelperCache.managedCharacter[config.modname][index].Character.CharacterID ~= GetCharaID(config.npcCharID[tostring(index)])))
	end
	if shouldRefreshCharacter then
		local character	= nil
		if index == -1 then
			character = CharacterManager["<ManualPlayer>k__BackingField"]
		else
			if index >= 0 and index <= (partyMembersFinalIndex[config.modname]) then
				local pawn = GetPawn(index)
				if pawn then
					character = pawn["<CachedCharacter>k__BackingField"]
				end
			elseif config and config.npcCharID then
				character = GetNPC(config.npcCharID[tostring(index)])
				if character == nil then
					character = GetCharacterByCharacterIDName(config.npcCharID[tostring(index)])
				end
			end
		end
		if character then
			characterHelperCache.managedCharacter[config.modname][index].Character = character
			characterHelperCache.managedCharacter[config.modname][index].PartSwapper = character["<HumanPartSwapper>k__BackingField"]
		else			
			characterHelperCache.managedCharacter[config.modname][index].Character = nil
			characterHelperCache.managedCharacter[config.modname][index].PartSwapper = nil
		end
	end
	return characterHelperCache.managedCharacter[config.modname][index].Character
end

local function GetManagedCharacterCharaID(index, config)
	if index == -1 and CharacterManager["<ManualPlayer>k__BackingField"] then
		return CharacterManager["<ManualPlayer>k__BackingField"].CharacterID
	else
		if index >= 0 and index <= (partyMembersFinalIndex[config.modname]) then
			local pawn = GetPawn(index)
			if pawn and pawn["<CachedCharacter>k__BackingField"] then
				return pawn["<CachedCharacter>k__BackingField"].CharacterID
			end
		elseif config and config.npcCharID then
			local charaID = GetCharaID(config.npcCharID[tostring(i)])
			if charaID == nil then
				local characterDetails = GetCharacterDetailsByCharacterIDName(config.npcCharID[tostring(index)])
				if characterDetails then
					charaID = characterDetails.CharaID
				end
			end
			return charaID
		end
	end
	--local character = GetManagedCharacter(index, config)
	--if character then
	--	return character.CharacterID
	--end
	return nil
end

local function GetManagedCharacterSentimentInfoValue(index, config)
	local sentimentInfoValue = 0
	if index == 0 then
		sentimentInfoValue = GetMainPawnFavorability()
	elseif config and config.npcCharID then
		local playerCharacter = CharacterManager["<ManualPlayer>k__BackingField"]
		if playerCharacter then
			sentimentInfoValue = GetNPCSentimentInfoValue(config.npcCharID[tostring(index)], playerCharacter.CharacterID, false)
		end
	end
	return sentimentInfoValue
end

local function SetManagedCharacterSentimentInfoValue(index, config, sentimentInfoValue)
	if index == 0 then
		SetMainPawnFavorability(sentimentInfoValue)
	elseif config and config.npcCharID then
		local playerCharacter = CharacterManager["<ManualPlayer>k__BackingField"]
		if playerCharacter then
			SetNPCSentimentInfoValue(config.npcCharID[tostring(index)], playerCharacter.CharacterID, sentimentInfoValue, false)
		end
	end
end

local function GetManagedCharacterSentimentRank(index, config)
	local sentimentRank = ""
	if index == 0 then
		local mainPawnIsLove = GetMainPawnIsLove()
		if mainPawnIsLove then
			sentimentRank = "Love"
		else
			sentimentRank = "Normal"
		end
	elseif config and config.npcCharID then
		local playerCharacter = CharacterManager["<ManualPlayer>k__BackingField"]
		if playerCharacter then
			sentimentRank = GetNPCSentimentRank(config.npcCharID[tostring(index)], playerCharacter.CharacterID)
		end
	end
	return sentimentRank
end

local function IsInParty(character)
	if character then
		local characterHuman = character:get_Human()
        	if characterHuman then
			return characterHuman:isPlayerOrPartyPawn()
		end
	end
	return false
end

local function IsASelectedNPC(character, config)
	if character then
		if config.npcCharID then
			local characterIDName = character:get_GameObject():get_Name()
			for i = (partyMembersFinalIndex[config.modname] + 1), finalManagedCharacterIndex[config.modname] do
				if characterIDName == config.npcCharID[tostring(i)] then
					return true
				end
			end
		else		
			for i = (partyMembersFinalIndex[config.modname] + 1), finalManagedCharacterIndex[config.modname] do
				local compareCharacter = GetManagedCharacter(i, config)
				if compareCharacter then
					if character == compareCharacter then
						return true
					end
				end
			end
		end
	end
	return false
end

local function IsInPartyOrASelectedNPC(character, config)
	if IsInParty(character) then
		return true
	else	
		return IsASelectedNPC(character, config)
	end 
end

local function GetCharacterPositionString(character)
	local characterPositionString = ""
	if character then
		characterPositionString = common.GetVec3String(character["<Transform>k__BackingField"]:get_UniversalPosition())
	end
	return characterPositionString
end

local function GetNPCCharacterPositionString(npcCharID)
	return common.GetVec3String(GetNPCLocation(npcCharID, false))
end

local function GetManagedCharacterLabel(index, config)
	local label = ""
	if index == -1 then
		label = "Arisen"
	elseif index >= 0 and index <= (partyMembersFinalIndex[config.modname]) then
		if index == 0 then
			label = "Main Pawn"
		else
			label = "Side Pawn " .. tostring(index)
		end
	else
		label = "NPC " .. tonumber(index - (partyMembersFinalIndex[config.modname]))
	end
	return label
end

local function GetManagedCharacterLabel2(index, config, useName)
	local label = ""
	local characterName = ""
	if useName then
		characterName = GetManagedCharacterName(index, config, 1)
	end	
	if characterName ~= "" then
		label = characterName
	else
		if index == -1 then
			label = "a"
		elseif index >= 0 and index <= (partyMembersFinalIndex[config.modname]) then
			if index == 0 then
				label = "m"
			else
				label = "s" .. tostring(index)
			end
		else
			label = "n" .. tonumber(index - (partyMembersFinalIndex[config.modname]))  .. ""
		end
	end
	--label = string.sub(label:lower(), 1, 2)
	--if index <= 2 then
	--	label = label .. tostring(index + 2)
	--end
	return "<" .. label .. ">"
end

local function RefreshManagedCharacterIndexList(config)
	--if math.fmod(os.time(), 5) == 0 then
		characterHelperCache.managedCharacterIndex[config.modname] = {}
		if CharacterManager["<ManualPlayer>k__BackingField"] and CharacterManager["<ManualPlayer>k__BackingField"].CharacterID then
			characterHelperCache.managedCharacterIndex[config.modname][CharacterManager["<ManualPlayer>k__BackingField"].CharacterID] = -1
		end
		for i = 0, partyMembersFinalIndex[config.modname] do
			local pawn = GetPawn(i)
			if pawn then
				character = pawn["<CachedCharacter>k__BackingField"]
				if character and character.CharacterID then
					characterHelperCache.managedCharacterIndex[config.modname][character.CharacterID] = i
				end
			end
		end
		for i = (partyMembersFinalIndex[config.modname] + 1), finalManagedCharacterIndex[config.modname] do
			local charaID = GetCharaID(config.npcCharID[tostring(i)])
			if charaID then
				characterHelperCache.managedCharacterIndex[config.modname][charaID] = i
			else
				local characterDetails = GetCharacterDetailsByCharacterIDName(config.npcCharID[tostring(i)])
				if characterDetails then
					characterHelperCache.managedCharacterIndex[config.modname][characterDetails.NewCharaID] = i
				end
			end
		end
	--end
end

local function GetManagedCharacterIndexByCharacterID(pCharacterID, config)
	if characterHelperCache.managedCharacterIndex[config.modname] then
		if characterHelperCache.managedCharacterIndex[config.modname][pCharacterID] then
			return characterHelperCache.managedCharacterIndex[config.modname][pCharacterID]
		end
	end
	return -2
end

local function GetManagedCharacterIndex(pCharacter, config)
	if pCharacter then
		local newCharaID = GetNewCharaID(pCharacter)
		return GetManagedCharacterIndexByCharacterID(newCharaID, config)
	end
	return -2	
end

local function GetManagedCharacterGroupDetails(index, config)
	if index == -1 then
		return characterHelperCache.managedCharacterGroupDetails[0]
	elseif index >= 0 and index <= (partyMembersFinalIndex[config.modname]) then
		return characterHelperCache.managedCharacterGroupDetails[1] 
	else
		return characterHelperCache.managedCharacterGroupDetails[2]
	end
end

local function IsBRConditionsMet(config, 
	autoReapplyBattleRelationshipCheckBoxChecked, battleRelationshipApplicationTypeIndex, 
	character1ManagedCharacterIndex, character2ManagedCharacterIndex) --,
	--isMethod2)
	if character1ManagedCharacterIndex > -2 then
		if autoReapplyBattleRelationshipCheckBoxChecked[tostring(character1ManagedCharacterIndex)] then		
			local character2GroupDetails = GetManagedCharacterGroupDetails(character2ManagedCharacterIndex, config)
			return character2GroupDetails[battleRelationshipApplicationTypeIndex[tostring(character1ManagedCharacterIndex)]]
		end
	end
	return false
end

local function SetBattleRelationship(pCharacter1, pCharacter2, config, battleRelationshipIndex, autoReapplyBattleRelationshipCheckBoxChecked, battleRelationshipApplicationTypeIndex) --, isMethod2)

	local battleRelInfo = {}
	battleRelInfo.shouldReturnNewBattleRelationship = false
	battleRelInfo.newBattleRelationship = 0

	if pCharacter1 and pCharacter2 then

		local character1ManagedCharacterIndex = -2
		local character2ManagedCharacterIndex = -2
		
		character1ManagedCharacterIndex = GetManagedCharacterIndexByCharacterID(pCharacter1.CharacterID, config)
		character2ManagedCharacterIndex = GetManagedCharacterIndexByCharacterID(pCharacter2.CharacterID, config)

		local conditionsMet = false

		conditionsMet = IsBRConditionsMet(config, 
			autoReapplyBattleRelationshipCheckBoxChecked, battleRelationshipApplicationTypeIndex, 
			character1ManagedCharacterIndex, character2ManagedCharacterIndex) --,
			--isMethod2)

		if conditionsMet then
			battleRelInfo.shouldReturnNewBattleRelationship = true
			battleRelInfo.newBattleRelationship = battleRelationshipIndex[tostring(character1ManagedCharacterIndex)]
			return battleRelInfo
		end

		if not conditionsMet then
			conditionsMet = IsBRConditionsMet(config, 
				autoReapplyBattleRelationshipCheckBoxChecked, battleRelationshipApplicationTypeIndex, 
				character2ManagedCharacterIndex, character1ManagedCharacterIndex) --,
				--isMethod2)
			
			if conditionsMet then
				battleRelInfo.shouldReturnNewBattleRelationship = true
				battleRelInfo.newBattleRelationship = battleRelationshipIndex[tostring(character2ManagedCharacterIndex)]
			end

		end
		
	end

	return battleRelInfo

end

local function GetFrontAngles(character)
	local characterTransform = character["<Transform>k__BackingField"]
	local characterUniversalPosition = characterTransform:get_UniversalPosition()
	local characterLocalPosition = characterTransform:get_LocalPosition()

	local characterRotation = characterTransform:get_Rotation()
	local characterLocalRotation = characterTransform:get_LocalRotation()

	local characterAxisX = characterTransform:get_AxisX()
	local characterAxisY = characterTransform:get_AxisY()
	local characterAxisZ = characterTransform:get_AxisZ()
	local calculatedFrontHorizontalAngle = (math.atan(characterAxisZ.x, characterAxisZ.z) * (180 / math.pi))
	local calculatedFrontVerticalAngleA = (math.atan(characterAxisZ.y, characterAxisY.y) * (180 / math.pi))
	local calculatedFrontVerticalAngleB = (math.atan(characterAxisX.y, characterAxisY.y) * (180 / math.pi))

	local frontAngles = {}
	frontAngles.HorizontalAngle = calculatedFrontHorizontalAngle
	frontAngles.VerticalAngleA = calculatedFrontVerticalAngleA
	frontAngles.VerticalAngleB = calculatedFrontVerticalAngleB

	return frontAngles
end

local function GetEstimatedNewPositionBasedOnAngle(angleBasis, currentPosition, unitsToAdd)

	local addX = (unitsToAdd * math.sin(math.rad(angleBasis)))
	local addY = 0
	local addZ = (unitsToAdd * math.cos(math.rad(angleBasis)))

	currentPosition.x = currentPosition.x + addX
	currentPosition.y = currentPosition.y + addY
	currentPosition.z = currentPosition.z + addZ

	return currentPosition

end

local function GetEstimatedCharacterFocusTarget(frontAngles, characterLocalPosition)

	local focusDistance = 100

	local addX = (focusDistance * math.sin(frontAngles.HorizontalAngle * (math.pi / 180)))
	local addY = (focusDistance * math.sin(frontAngles.VerticalAngleA * (math.pi / 180))) + (focusDistance * math.sin(frontAngles.VerticalAngleB * (math.pi / 180)))
	local addZ = (focusDistance * math.cos(frontAngles.HorizontalAngle * (math.pi / 180)))
	
	return Vector3f.new(characterLocalPosition.x + addX, characterLocalPosition.y + addY, characterLocalPosition.z + addZ)
	
end

local function SetCharacterFocus(character, targetLocalPosition)

	local characterTransform = character["<Transform>k__BackingField"]
	local characterLocalPosition = characterTransform:get_LocalPosition()
	
	local lookTarget
	local lookUp = characterLocalPosition

	local lookX = targetLocalPosition.x
	local lookY = targetLocalPosition.y
	local lookZ = targetLocalPosition.z

	lookTarget = Vector3f.new(
		lookX - ((lookX - characterLocalPosition.x) * 2), 
		lookY - ((lookY - characterLocalPosition.y) * 2), 
		lookZ - ((lookZ - characterLocalPosition.z) * 2))

	lookUp = Vector3f.new(0, 1, 0)

	characterTransform:lookAt(lookTarget, lookUp)

	if character ~= CharacterManager["<ManualPlayer>k__BackingField"] then
		local frontAngles = GetFrontAngles(character)
		character:set_TargetFrontAngleDeg(frontAngles.HorizontalAngle)
	end

end

local function GetFsm(character)
	if character then
		local fsm
		if character:get_Human() then
			return character:get_Human().Fsm
		else
			--BehaviorTree
			local actionManager = character:get_ActionManager()
			if actionManager then
				return actionManager.Fsm
			end
		end
	end
	return nil
end

local function GetFsmEnabled(character)
	if character then
		local fsm = GetFsm(character)
		if fsm then
			return fsm:get_Enabled()
		end
	end
	return false
end

local function SetFsmEnabled(character, enabled)
	if character then
		local fsm = GetFsm(character)
		if fsm then
			fsm:set_Enabled(enabled)
		end
	end
end

local function GetMotionEnabled(character)
	if character then
		local motion = character:get_Motion()
		if motion then
			return motion:get_Enabled()
		end
	end
	return false
end

local function SetMotionEnabled(character, enabled)
	if character then
		local motion = character:get_Motion()
		if motion then
			motion:set_Enabled(enabled)
		end
	end
end

local function TeleportCharacterToTargetCharacterPosition(character, targetCharacter, characterType, charaID)

	--characterType
	--0 = Arisen
	--1 = Pawn
	--2 = NPC
	
	local isCharacterTeleported = false

	local maxTeleportAttempts = 5

	local targetCharacterPosition = targetCharacter["<Transform>k__BackingField"]:get_UniversalPosition()
	local frontAngles = GetFrontAngles(targetCharacter)

	for i = 0, maxTeleportAttempts do								

		local newPosition = GetEstimatedNewPositionBasedOnAngle(frontAngles.HorizontalAngle, targetCharacterPosition, 1)

		if character == nil then
		
			local playerCharacter = CharacterManager["<ManualPlayer>k__BackingField"]

			if playerCharacter then

				local playerCharacterPosition = playerCharacter["<Transform>k__BackingField"]:get_UniversalPosition()

				if newPosition.x >= playerCharacterPosition.x then
					newPosition.x = playerCharacterPosition.x + 70
				else
					newPosition.x = playerCharacterPosition.x - 70
				end 

				if charaID and characterType == 2 then
					local npcHolder = NPCManager:getNPCHolder(charaID)
					if npcHolder then
						npcHolder:set_isGenerateRequest(true)
						NPCManager:warp(charaID, newPosition, npcHolder:get_Rotation())
						isCharacterTeleported = true
						character = npcHolder:get_CachedCharacter()
					end
				end

			end

		end

		if character and character ~= targetCharacter then

			local characterTeleporter = character:get_TelepotorProp()

			if characterTeleporter then

				local originalFsmEnabled = GetFsmEnabled(character)
				local originalMotionEnabled = GetMotionEnabled(character)
				SetFsmEnabled(character, false)
				SetMotionEnabled(character, false)
				
				characterTeleporter:teleport(newPosition)
				SetCharacterFocus(character, targetCharacter["<Transform>k__BackingField"]:get_LocalPosition())

				SetFsmEnabled(character, originalFsmEnabled)
				SetMotionEnabled(character, originalMotionEnabled)
				
				isCharacterTeleported =  true
				
			end

			break

		end

	end
	
	return isCharacterTeleported
	
end

local function TeleportNPCToTargetCharacterPosition(npcCharID, targetCharacter)		
	if targetCharacter then
		local npcCharacter
		local charaID = GetCharaID(npcCharID)		
		if charaID then			
			local npcHolder = NPCManager:getNPCHolder(charaID)
			if npcHolder then
				npcCharacter = npcHolder:get_CachedCharacter()
			end
		end
		if npcCharacter == nil then
			npcCharacter = GetCharacterByCharacterIDName(npcCharID)
		end
		TeleportCharacterToTargetCharacterPosition(npcCharacter, targetCharacter, 2, charaID)
	end
	return false
end

local function TeleportPartyMemberOrNPCToTargetCharacterPosition(managedCharacterIndex, config, targetCharacter)
	if managedCharacterIndex == -1 then
		return TeleportCharacterToTargetCharacterPosition(GetManagedCharacter(managedCharacterIndex, config), targetCharacter, 0, nil)
	elseif managedCharacterIndex >= 0 and managedCharacterIndex <= (partyMembersFinalIndex[config.modname]) then
		return TeleportCharacterToTargetCharacterPosition(GetManagedCharacter(managedCharacterIndex, config), targetCharacter, 1, nil)
	elseif managedCharacterIndex > (partyMembersFinalIndex[config.modname]) and managedCharacterIndex<= finalManagedCharacterIndex[config.modname] then
		return TeleportNPCToTargetCharacterPosition(config.npcCharID[tostring(managedCharacterIndex)], targetCharacter)
	end
	return false
end

--local charaIDArgs
--sdk.hook(sdk.find_type_definition("app.NPCManager"):get_method("isMustGenerateNPC(app.CharacterID)"),
--    function(args)
	--charaIDArgs = sdk.to_managed_object(args[3])
--    end,
--    function(retval)
	--if charaIDArgs then
	--	if generateNPCNPCCharID then
	--		local characterData
	--		local charaID = GetCharaID(generateNPCNPCCharID)
	--		if charaID then
	--			characterData = NPCManager:getNPCCharacterData(charaID)
	--			if charaID == charaIDArgs then
	--				return sdk.to_ptr(true)
	--			end
	--		end
	--		generateNPCNPCCharID = ""
	--	end
	--end
--	return retval
--    end
--)

local function TeleportCharacter(character, teleportPosition)
	if character then
		local characterTeleporter = character:get_TelepotorProp()
		if characterTeleporter then
			local originalFsmEnabled = GetFsmEnabled(character)
			local originalMotionEnabled = GetMotionEnabled(character)
			SetFsmEnabled(character, false)
			SetMotionEnabled(character, false)
			characterTeleporter:teleport(teleportPosition)
			SetFsmEnabled(character, originalFsmEnabled)
			SetMotionEnabled(character, originalMotionEnabled)
		end
	end
end

local function TeleportCharacterBySteps(character, stepsForward, stepsUpward, stepsToTheRight)
	if character then
		local frontAngles = GetFrontAngles(character)
		local characterTransform = character["<Transform>k__BackingField"]
		if characterTransform then
			local currentPosition = characterTransform:get_UniversalPosition()
			local teleportPosition = GetEstimatedNewPositionBasedOnAngle(frontAngles.HorizontalAngle, currentPosition, stepsForward)
			teleportPosition.y = teleportPosition.y + stepsUpward
			teleportPosition = GetEstimatedNewPositionBasedOnAngle(frontAngles.HorizontalAngle - 90, teleportPosition, stepsToTheRight)
			TeleportCharacter(character, teleportPosition)
		end
	end
end

local function RegenerateCharacter(character)
	if character then
		local isPlayerCharacter = false
		--local targetCharacterPosition
		--local targetCharacterRotation
		isPlayerCharacter = character == CharacterManager["<ManualPlayer>k__BackingField"]
		if isPlayerCharacter then
			--if character["<Transform>k__BackingField"] then
			--	targetCharacterPosition = character["<Transform>k__BackingField"]:get_UniversalPosition()
			--	targetCharacterRotation = character["<Transform>k__BackingField"]:get_LocalRotation()
			--end
		else
			local characterGenerateInfo = character["<GenerateInfo>k__BackingField"]
			if characterGenerateInfo then
				characterGenerateInfo:requestRegenerate()
			end
		end
	end
end

local function RegenerateCharacterByCharacterIndex(characterIndex, config, character)
	if character == nil then
		character = GetManagedCharacter(characterIndex, config)
	end
	RegenerateCharacter(character)
end

local function GetManagedCharacterUniversalPosition(index, config, character)
	if index == -1 then
		return nil
	end
	local characterUniversalPosition	
	if (index > (partyMembersFinalIndex[config.modname]) and index <= finalManagedCharacterIndex[config.modname]) then
		characterUniversalPosition = GetNPCLocation(config.npcCharID[tostring(index)], true)
	end		
	if characterUniversalPosition == nil then
		if character == nil then
			character = GetManagedCharacter(index, config)
		end
		if character then
			local characterTransform = character["<Transform>k__BackingField"]
			if characterTransform then
				characterUniversalPosition = characterTransform:get_UniversalPosition()
			end
		end
	end
	return characterUniversalPosition
end

local function GetManagedCharacterDistanceFromPlayerCharacter(index, config, character)
	local distance
	local characterUniversalPosition = GetManagedCharacterUniversalPosition(index, config, character)
	distance = GetDistanceFromPlayerCharacter(characterUniversalPosition)
	return distance
end

local function IsNearPlayerCharacter(index, config, nearDistance, character)
	local characterUniversalPosition = GetManagedCharacterUniversalPosition(index, config, character)
	return IsPositionNearPlayerCharacter(characterUniversalPosition, nearDistance)
end

local function RespawnMainPawn()
	local playerCharacter = CharacterManager["<ManualPlayer>k__BackingField"]
	if playerCharacter and playerCharacter["<Transform>k__BackingField"] then
		local playerCharacterPosition = playerCharacter["<Transform>k__BackingField"]:get_UniversalPosition()
		local playerCharacterRotation = playerCharacter["<Transform>k__BackingField"]:get_Rotation()
		if playerCharacterPosition and playerCharacterRotation then
			local frontAngles = GetFrontAngles(playerCharacter)
			if frontAngles and frontAngles then
				local newPosition = GetEstimatedNewPositionBasedOnAngle(frontAngles.HorizontalAngle, playerCharacterPosition, 1)
				if newPosition then
						PawnManager:call("respawnMainPawn(via.Position, via.Quaternion, System.Boolean, System.Boolean)", playerCharacterPosition, playerCharacterRotation, false, false)
				end
			end
		end
	end
end

local function SetupAvailableCharactersListUI(additionalAvailableCharactersListObjects)
	if imgui.button("Обновить список") or (common.GetShowWindow(additionalAvailableCharactersListObjects.windowName) and not common.GetShowWindowPrev(additionalAvailableCharactersListObjects.windowName)) then
		common.SetCustomListIsPopulated("AvailableCharacterDetailsList", false)
		common.SetCustomListIsPopulated("NPCDetailsList", false)
		common.SetShowWindow(additionalAvailableCharactersListObjects.windowName, true)
	end
	local changedValue = false
	imgui.same_line()
	imgui.set_next_item_width(150)
	changedValue, availableCharacterSearchString = common.CyrillicInputText("Поиск персонажа", availableCharacterSearchString)
	if imgui.begin_table("Available Characters", 1, 33554432, {100, 100}) then
		imgui.table_setup_scroll_freeze(1, 1)
		imgui.table_next_row()
		imgui.table_next_column()
		imgui.arrow_button("SetupAvailableCharactersListUISampleRightButton", 1)
		imgui.same_line()
		imgui.table_set_bg_color(1, common.COLOR.GRAY, 1)
		imgui.text("#. Имя / ID имени персонажа / ID персонажа")
		imgui.table_next_row()
		imgui.table_next_column()
		if common.GetShowWindow(additionalAvailableCharactersListObjects.windowName) then
			local availableCharacterDetailsList = GetAvailableCharacterDetailsList()
			tempAvailableCharacterSearchString = availableCharacterSearchString
			tempAvailableCharacterSearchString = tempAvailableCharacterSearchString:gsub("%%", "\\%%")
			tempAvailableCharacterSearchString = tempAvailableCharacterSearchString:gsub("%[", "\\[")
			tempAvailableCharacterSearchString = tempAvailableCharacterSearchString:gsub("%(", "\\(")
			local i = 0
			for key, availableCharacterDetails in pairs(availableCharacterDetailsList) do
				i = i + 1
				if string.find(tostring(availableCharacterDetails.CharacterName):lower(), tempAvailableCharacterSearchString:lower())
					or string.find(tostring(availableCharacterDetails.CharacterGameObjectName):lower(), tempAvailableCharacterSearchString:lower())
					or string.find(tostring(availableCharacterDetails.NewCharaID):lower(), tempAvailableCharacterSearchString:lower())
					then
					if imgui.arrow_button("Телепортировать " .. tostring(i), 1) then
						TeleportNPCToTargetCharacterPosition(availableCharacterDetails.CharacterGameObjectName, CharacterManager["<ManualPlayer>k__BackingField"])
					end
					if imgui.is_item_hovered() then
						imgui.set_tooltip("Телепортирует " .. availableCharacterDetails.CharacterName .. " к местоположению игрока.")
					end
					imgui.same_line()
					imgui.set_next_item_width(415)
					imgui.input_text("AC" .. tostring(i), tostring(i)  .. ". " .. availableCharacterDetails.CharacterName .. " / " .. availableCharacterDetails.CharacterGameObjectName .. " / " .. availableCharacterDetails.NewCharaID)
				end
			end
		end
		imgui.end_table()	
	end
end

local function SetupNPCIDListUI(additionalNPCIDListObjects)

	local npcWindowDetails = {
		CustomCheckBoxChecked = false,
		CustomComboBoxIndex = 0,
		SelectedAppearanceID = 0,
		SelectedCostumeID = 0
	}
	
	if common.GetShowWindow(additionalNPCIDListObjects.windowName) then
	
		if not additionalNPCIDListObjects.AppendToLabels then
			additionalNPCIDListObjects.AppendToLabels = ""
		end

		local npcTableColumnCount = 3
		local npcTableOuterSizeWidth = 300
		local npcTableOuterSizeHeight = 300
		
		if common.GetBooleanValue(additionalNPCIDListObjects.ShowRowNos) then
			npcTableColumnCount = 3
		end

		local npcNos = {[0] = "1"}
		local managedCharacterNos = {}	
		
		local npcList = {}
	
		npcList = GetNPCList()

		if imgui.button("Обновить список") or (common.GetShowWindow(additionalNPCIDListObjects.windowName) and not common.GetShowWindowPrev(additionalNPCIDListObjects.windowName)) then
			common.SetCustomListIsPopulated("AvailableCharacterDetailsList", false)
			common.SetCustomListIsPopulated("NPCDetailsList", false)
			common.SetShowWindow(additionalNPCIDListObjects.windowName, true)
			currentlySelectedNPCIndex = 0
		end
		
		if filteredNPCList and filteredNPCListNames and common.GetBooleanValue(additionalNPCIDListObjects.ShowNPCComboBoxWithIterator) then
		
			imgui.same_line()
			imgui.text("                                                           ")
			imgui.same_line()
			
			local filteredNPCListCount = #filteredNPCList
			
			local previousNPCName = "(Предыдущий NPC)"
			local nextNPCName = "(Следующий NPC)"
			local currentNPCName = "(Текущий NPC)"
			
			if (currentlySelectedNPCIndex - 1) > 0 then
				previousNPCName = filteredNPCList[currentlySelectedNPCIndex - 2].Name
			end			
			
			if (currentlySelectedNPCIndex - 1) < (filteredNPCListCount - 1) then
				nextNPCName = filteredNPCList[currentlySelectedNPCIndex].Name
			end
			
			if (currentlySelectedNPCIndex - 1) > -1 and currentlySelectedNPCIndex < filteredNPCListCount then
				currentNPCName = filteredNPCList[currentlySelectedNPCIndex - 1].Name
			end	
			
			local additionaComboBoxSettings = {}
			additionaComboBoxSettings.AddCurrentButton = true
			additionaComboBoxSettings.PreviousButtonLabel = additionalNPCIDListObjects.ShowNPCComboBoxWithIteratorButtonsLabel .. "предыдущего персонажа"
			additionaComboBoxSettings.NextButtonLabel = additionalNPCIDListObjects.ShowNPCComboBoxWithIteratorButtonsLabel .. "следующего персонажа"
			additionaComboBoxSettings.CurrentButtonLabel = additionalNPCIDListObjects.ShowNPCComboBoxWithIteratorButtonsLabel .. "текущего персонажа"
			
			local valueChanged
			valueChanged, currentlySelectedNPCIndex = common.ComboBoxWithNextAndPreviousButtons(additionalNPCIDListObjects.config.modname, "NPC [" .. tostring(currentlySelectedNPCIndex) .. "/" .. tostring(filteredNPCListCount) .. "]", currentlySelectedNPCIndex, filteredNPCListNames, 200, "NPC Names", false, false, true, additionaComboBoxSettings)
			
			if additionalNPCIDListObjects.ShowNPCComboBoxWithIteratorFunction and valueChanged and additionalNPCIDListObjects.ShowNPCComboBoxWithIteratorFunctionCondition then
				additionalNPCIDListObjects.ShowNPCComboBoxWithIteratorFunction(filteredNPCList[(currentlySelectedNPCIndex - 1)])
			end
			
		end
		
		local changedValue = false
		imgui.set_next_item_width(150)
		changedValue, npcNameSearchString = common.CyrillicInputText("Поиск NPC" .. additionalNPCIDListObjects.AppendToLabels, npcNameSearchString)
		if changedValue then
			currentlySelectedNPCIndex = 0
		end
		imgui.same_line()
		common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Имена\nID\nСтатус жизни (ALIVE или DEAD)\nВид (HUMAN или BEASTREN)\nПол (GENDERLESS, MASCULINE или FEMININE)\nПервые 3 буквы Пол+Вид (например: FEMHUM для женщины-человека)")

		if additionalNPCIDListObjects then

			if common.GetBooleanValue(additionalNPCIDListObjects.HasButtonFunction) and common.GetBooleanValue(additionalNPCIDListObjects.ButtonVisibilityCondition) then

				npcTableColumnCount = npcTableColumnCount + 1
				npcTableOuterSizeWidth = npcTableOuterSizeWidth + 100
				npcTableOuterSizeHeight = npcTableOuterSizeHeight + 100

			end

			if common.GetBooleanValue(additionalNPCIDListObjects.EnableCopyNPCDetails2) then

				npcTableColumnCount = npcTableColumnCount + 1
				npcTableOuterSizeWidth = npcTableOuterSizeWidth + 100
				npcTableOuterSizeHeight = npcTableOuterSizeHeight + 100

			end

			--if common.GetBooleanValue(additionalNPCIDListObjects.ShowAppearanceIDandCostumeIDColumns) then
				
			--	npcTableColumnCount = npcTableColumnCount + 2
			--	npcTableOuterSizeWidth = npcTableOuterSizeWidth + 200
			--	npcTableOuterSizeHeight = npcTableOuterSizeHeight + 200

			--end 

		end

		if common.GetBooleanValue(additionalNPCIDListObjects.ShowCustomCheckBox) then

			npcWindowDetails.CustomCheckBoxChecked = additionalNPCIDListObjects.CustomCheckBoxChecked

			imgui.same_line()
			_, npcWindowDetails.CustomCheckBoxChecked = imgui.checkbox(additionalNPCIDListObjects.CustomCheckBoxLabel .. additionalNPCIDListObjects.AppendToLabels, npcWindowDetails.CustomCheckBoxChecked)
			imgui.same_line()
			common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, additionalNPCIDListObjects.CustomCheckBoxToolTip)

		end

		if common.GetBooleanValue(additionalNPCIDListObjects.ShowCustomComboBox) then

			npcWindowDetails.CustomComboBoxIndex = additionalNPCIDListObjects.CustomComboBoxIndex

			imgui.set_next_item_width(additionalNPCIDListObjects.CustomComboBoxWidth)
			_, npcWindowDetails.CustomComboBoxIndex = imgui.combo(":" .. additionalNPCIDListObjects.CustomComboBoxLabel .. additionalNPCIDListObjects.AppendToLabels, npcWindowDetails.CustomComboBoxIndex, additionalNPCIDListObjects.CustomComboBoxOptions)
			imgui.same_line()
			common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, additionalNPCIDListObjects.CustomComboBoxToolTip)

		end

		if common.GetBooleanValue(additionalNPCIDListObjects.ShowAppearanceIDandCostumeIDTextBoxes) then

			npcWindowDetails.SelectedAppearanceID = additionalNPCIDListObjects.SelectedAppearanceID
			npcWindowDetails.SelectedCostumeID = additionalNPCIDListObjects.SelectedCostumeID

			imgui.same_line()
			imgui.set_next_item_width(50)
			_, npcWindowDetails.SelectedAppearanceID = common.CyrillicInputText("ID внешности" .. additionalNPCIDListObjects.AppendToLabels, npcWindowDetails.SelectedAppearanceID)
			npcWindowDetails.SelectedAppearanceID = common.ChangeToDefaultIfNotANumber(npcWindowDetails.SelectedAppearanceID, 0)
			imgui.same_line()
			common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "ID вариации внешности.\nЦелое число.")

			imgui.same_line()
			imgui.set_next_item_width(50)
			_, npcWindowDetails.SelectedCostumeID = common.CyrillicInputText("ID костюма" .. additionalNPCIDListObjects.AppendToLabels, npcWindowDetails.SelectedCostumeID)
			npcWindowDetails.SelectedCostumeID = common.ChangeToDefaultIfNotANumber(npcWindowDetails.SelectedCostumeID, 0)
			imgui.same_line()
			common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "ID вариации костюма.\nЦелое число.")

		end

		local npcTableOuterSize = {npcTableOuterSizeWidth, npcTableOuterSizeHeight}

		if imgui.begin_table("NPC List Additional Options 2", npcTableColumnCount, 1, npcTableOuterSize) then

			imgui.table_next_row()
			imgui.table_next_column()
			imgui.spacing()

			imgui.table_next_column()
			if common.GetBooleanValue(additionalNPCIDListObjects.EnableCopyNPCDetails) then

				npcNos = GenerateManagedNPCIndexList(additionalNPCIDListObjects.config.maxManagedNPCCount)

				imgui.set_next_item_width(50)
				_, copyCharacterIDNPCIndex = imgui.combo(":слот NPC" .. additionalNPCIDListObjects.AppendToLabels, copyCharacterIDNPCIndex, npcNos)
				imgui.same_line()
				common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Слот NPC, в который будет скопировано выбранное ID имени персонажа.")
		
			end
			
			imgui.table_next_column()
			imgui.spacing()

			if common.GetBooleanValue(additionalNPCIDListObjects.EnableCopyNPCDetails2) then

				managedCharacterNos = additionalNPCIDListObjects.CopyNPCDetails2ComboBoxOptions

				if copyCharacterIDNPCIndex2 == -2 and managedCharacterNos then
					local stopAtNumber = 10
					while copyCharacterIDNPCIndex2 <= stopAtNumber do
						if managedCharacterNos[copyCharacterIDNPCIndex2] then
							break
						end
						copyCharacterIDNPCIndex2 = copyCharacterIDNPCIndex2 + 1
					end
				end

				imgui.table_next_column()
				imgui.set_next_item_width(additionalNPCIDListObjects.CopyNPCDetails2ComboBoxWidth)
				_, copyCharacterIDNPCIndex2 = imgui.combo(":" .. additionalNPCIDListObjects.CopyNPCDetails2ComboBoxLabel .. additionalNPCIDListObjects.AppendToLabels, copyCharacterIDNPCIndex2, managedCharacterNos)
				imgui.same_line()
				common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, additionalNPCIDListObjects.CopyNPCDetails2ComboBoxToolTip)
		
			end

			imgui.end_table()

		end

		if imgui.begin_table("NPC List", npcTableColumnCount, 33554432, npcTableOuterSize) then
		
			imgui.table_setup_scroll_freeze(1, 1)

			imgui.table_next_row()
			
			if common.GetBooleanValue(additionalNPCIDListObjects.ShowRowNos) then
				imgui.table_next_column()
				imgui.table_header("#")
			end
			
			imgui.table_next_column()
			imgui.table_header("Имя")

			imgui.table_next_column()
			imgui.table_header("ID имени персонажа")

			imgui.table_next_column()
			imgui.table_header("ID персонажа")

			if common.GetBooleanValue(additionalNPCIDListObjects.EnableCopyNPCDetails2) then
				imgui.table_next_column()
				imgui.table_header(additionalNPCIDListObjects.CopyNPCDetails2HeaderLabel)
			end

			--if common.GetBooleanValue(additionalNPCIDListObjects.ShowAppearanceIDandCostumeIDColumns) then
			--	imgui.table_next_column()
			--	imgui.table_header("AppearanceIDs")
			--	imgui.table_next_column()
			--	imgui.table_header("CostumeIDs")
			--end

			if common.GetBooleanValue(additionalNPCIDListObjects.HasButtonFunction) and common.GetBooleanValue(additionalNPCIDListObjects.ButtonVisibilityCondition) then
				imgui.table_next_column()
				imgui.table_header(additionalNPCIDListObjects.ButtonFunctionHeaderLabel)
			end
			
			filteredNPCList = {}
			filteredNPCListNames = {}
			local ctr = 0

			if npcList then

				tempNPCNameSearchString = npcNameSearchString
				tempNPCNameSearchString = tempNPCNameSearchString:gsub("%%", "\\%%")
				tempNPCNameSearchString = tempNPCNameSearchString:gsub("%[", "\\[")
				tempNPCNameSearchString = tempNPCNameSearchString:gsub("%(", "\\(")
			
				for i, npc in pairs(npcList) do

					npc.NPCIndex = copyCharacterIDNPCIndex + (partyMembersFinalIndex[additionalNPCIDListObjects.config.modname]) + 1
					npc.NPCIndex2 = copyCharacterIDNPCIndex2

					if string.find(tostring(npc.Name):lower(), tempNPCNameSearchString:lower())
						or string.find(tostring(npc.CharacterIDName):lower(), tempNPCNameSearchString:lower())
						or string.find(tostring(npc.CharaID):lower(), tempNPCNameSearchString:lower())
						or string.find(npc.AliveStatusString, tempNPCNameSearchString)
						or string.find(npc.SpeciesString, tempNPCNameSearchString)
						or string.find(npc.GenderString, tempNPCNameSearchString)
						or string.find(npc.GenderSpeciesString, tempNPCNameSearchString)
						then

						imgui.table_next_row()
						if ctr % 2 == 1 then
								imgui.table_set_bg_color(1, common.COLOR.GRAY, 1)
						end
					
						if common.GetBooleanValue(additionalNPCIDListObjects.ShowRowNos) then
							imgui.table_next_column()
							imgui.text(tostring(ctr + 1))
						end
						
						imgui.table_next_column()
						imgui.text(npc.Name)
						if imgui.is_item_hovered() then
							imgui.set_tooltip("#" .. tostring(ctr + 1) .. " - " .. npc.SpeciesString .. ", " .. npc.GenderString .. " (" .. npc.GenderSpeciesString .. ")")
						end

						if npc.IsNPCDead then
							imgui.same_line()
							common.TextColoredWithOnHoverTooltip("x", common.COLOR.RED, npc.AliveStatusString)
						end

						imgui.table_next_column()
						if common.GetBooleanValue(additionalNPCIDListObjects.EnableCopyNPCDetails) and not common.GetBooleanValue(additionalNPCIDListObjects.DisableCopyNPCDetailsCondition) then
							if imgui.arrow_button("Копировать ID имени " .. npc.CharacterIDName .. additionalNPCIDListObjects.AppendToLabels, 3) then
								additionalNPCIDListObjects.CopyNPCDetailsFunction(npc)
							end
							if imgui.is_item_hovered() and npcNos then
								imgui.set_tooltip("Копировать это ID имени персонажа в слот NPC " .. tostring(npcNos[copyCharacterIDNPCIndex]) .. ".")
							end
							imgui.same_line()
							imgui.text(npc.CharacterIDName .. additionalNPCIDListObjects.AppendToLabels)
						else
							imgui.text(npc.CharacterIDName)
						end

						imgui.table_next_column()
						if common.GetBooleanValue(additionalNPCIDListObjects.EnableNPCTeleport) and not common.GetBooleanValue(additionalNPCIDListObjects.DisableNPCTeleportCondition) then
							if imgui.arrow_button("Телепортировать " .. tostring(npc.CharaID) .. additionalNPCIDListObjects.AppendToLabels, 1) then
								TeleportNPCToTargetCharacterPosition(npc.CharacterIDName, CharacterManager["<ManualPlayer>k__BackingField"])
								generateNPCNPCCharID = npc.CharacterIDName
							end
							if imgui.is_item_hovered() then
								imgui.set_tooltip("Телепортирует " .. npc.Name .. " к местоположению игрока.")
							end
							imgui.same_line()
							imgui.text(npc.CharaID .. additionalNPCIDListObjects.AppendToLabels)
							if ctr == 0 then
								local teleportNPCTooltip = "Этот метод телепортации обычно работает только когда персонаж уже загружен в текущей области."
								teleportNPCTooltip = teleportNPCTooltip .. "\nМногократное нажатие кнопки иногда помогает."
								teleportNPCTooltip = teleportNPCTooltip .. "\nЕсли не сработает, персонаж будет телепортирован на 70 'очков' перед игроком."
								teleportNPCTooltip = teleportNPCTooltip .. "\n(Например: Расстояние от входной двери 'Private Dwelling (Noble Quarter)'"
								teleportNPCTooltip = teleportNPCTooltip .. "\nдо переднего сада 'Patrick's Estate' составляет примерно 70 'очков'."
								teleportNPCTooltip = teleportNPCTooltip .. "\nЕсли нажать кнопку телепортации стоя у двери 'Private Dwelling (Noble Quarter)'"
								teleportNPCTooltip = teleportNPCTooltip .. "\nи глядя в сторону 'Patrick's Estate',"
								teleportNPCTooltip = teleportNPCTooltip .. "\nтелепортируемый NPC может появиться в саду 'Patrick's Estate'.)"
								imgui.same_line()
								common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, teleportNPCTooltip)
							end
						else
							imgui.text(npc.CharaID)
						end

						if common.GetBooleanValue(additionalNPCIDListObjects.EnableCopyNPCDetails2) then
							local buttonLabel
							if additionalNPCIDListObjects.CopyNPCDetails2ButtonLabel ~= "" then
								buttonLabel = additionalNPCIDListObjects.CopyNPCDetails2ButtonLabel .. " " .. tostring(i)
							else
								buttonLabel = npc.CharacterIDName --" " .. npc.CharacterIDName .. " "
							end
							imgui.table_next_column()
							if imgui.arrow_button(buttonLabel .. additionalNPCIDListObjects.AppendToLabels, 3) then
								currentlySelectedNPCIndex = ctr + 1
								additionalNPCIDListObjects.CopyNPCDetails2Function(npc)
							end
							if imgui.is_item_hovered() then
								imgui.set_tooltip(additionalNPCIDListObjects.CopyNPCDetails2ButtonToolTip .. " " .. managedCharacterNos[copyCharacterIDNPCIndex2] .. ".")
							end
							imgui.same_line()
							imgui.text(buttonLabel .. additionalNPCIDListObjects.AppendToLabels)
						end

						if additionalNPCIDListObjects then
							--if common.GetBooleanValue(additionalNPCIDListObjects.ShowAppearanceIDandCostumeIDColumns) then
							--	local characterInGameMetaInfos = GetCharacterInGameMetaInfos(npc.CharaID)
							--	local appearanceIDBounds = "-"
							--	local costumeIDBounds = "-"
							--	if characterInGameMetaInfos then
							--		appearanceID = tostring(characterInGameMetaInfos.MinAppearanceID) .. " to " .. tostring(characterInGameMetaInfos.MaxAppearanceID)
							--		costumeID = tostring(characterInGameMetaInfos.MinCostumeID) .. " to " .. tostring(characterInGameMetaInfos.MaxCostumeID)
							--	end
							--	imgui.table_next_column()
							--	imgui.text(tostring(appearanceIDBounds))
							--	imgui.table_next_column()
							--	imgui.text((costumeIDBounds))
							--end
							if common.GetBooleanValue(additionalNPCIDListObjects.HasButtonFunction) and common.GetBooleanValue(additionalNPCIDListObjects.ButtonVisibilityCondition) then
								imgui.table_next_column()
								if imgui.arrow_button(additionalNPCIDListObjects.ButtonFunctionButtonLabel .. " " .. tostring(i) .. additionalNPCIDListObjects.AppendToLabels, 3) then
									currentlySelectedNPCIndex = ctr + 1
									additionalNPCIDListObjects.ButtonFunction(npc)						
								end
								if imgui.is_item_hovered() then
									imgui.set_tooltip(additionalNPCIDListObjects.ButtonFunctionButtonToolTip)
								end
								imgui.same_line()
								imgui.text(additionalNPCIDListObjects.ButtonFunctionButtonLabel .. " " .. tostring(i) .. additionalNPCIDListObjects.AppendToLabels)
							end
						end
						
						filteredNPCList[ctr] = npc
						filteredNPCListNames[ctr + 1] = npc.Name
						ctr = ctr + 1
						
					end

				end
				
			end

			imgui.end_table()

		end
		
	end
	
	return npcWindowDetails

end

local function RefreshManagedCharacterCache(config)
	RefreshManagedCharacterIndexList(config)
	for i = -1, finalManagedCharacterIndex[config.modname] do
		local character = GetManagedCharacter(i, config)
	end
end

local characterHelper = {

	currentVersion = currentVersion,

	BATTLERELATIONSHIPAPPLICATIONTYPES = function() return BATTLERELATIONSHIPAPPLICATIONTYPES end,
	BATTLERELATIONSHIPAPPLICATIONTYPE = function() return BATTLERELATIONSHIPAPPLICATIONTYPE end,
	SentimentRanks = function() return SentimentRanks end,
	
	SetCommon = SetCommon,
	InitializeCharacterHelper = InitializeCharacterHelper,
	GetPartyMembersMaxCount = GetPartyMembersMaxCount,
	GetPartyMembersFinalIndex = GetPartyMembersFinalIndex,
	GetManagedNPCCount = GetManagedNPCCount,
	GetManagedCharacterCount = GetManagedCharacterCount,
	GetFinalManagedCharacterIndex = GetFinalManagedCharacterIndex,	
	GetNPCLocation = GetNPCLocation,
	GetNPCRotation = GetNPCRotation,
	GetDistanceFromPlayerCharacter = GetDistanceFromPlayerCharacter,
	IsPositionNearPlayerCharacter = IsPositionNearPlayerCharacter,	
	GetCharacterNameByCharacterID = GetCharacterNameByCharacterID,
	GetNewCharacterIDName = GetNewCharacterIDName,
	GetNewCharaIDByCharaIDName = GetNewCharaIDByCharaIDName,
	GetNewCharaID = GetNewCharaID,
	GetCharacterNameByCharacterIDName = GetCharacterNameByCharacterIDName,
	GetCharacterIDName = GetCharacterIDName,
	GetCharaID = GetCharaID,	
	GetCharacterGameObjectName = GetCharacterGameObjectName,
	GetCharacterByCharacterGameObjectName = GetCharacterByCharacterGameObjectName,
	GetAvailableCharacterDetailsList = GetAvailableCharacterDetailsList,
	GetCharacterByCharaID = GetCharacterByCharaID,
	GetCharacterDetailsByCharacterIDName = GetCharacterDetailsByCharacterIDName,
	GetCharacterByCharacterIDName = GetCharacterByCharacterIDName,
	GetNPC = GetNPC,
	GetNPCName = GetNPCName,
	GetEnemy = GetEnemy,
	GetMonster = GetMonster,
	GetNPCSentimentInfoValue = GetNPCSentimentInfoValue,
	SetNPCSentimentInfoValue = SetNPCSentimentInfoValue,
	GetNPCSentimentRank = GetNPCSentimentRank,
	GetNPCList = GetNPCList,
	IsPawn = IsPawn,
	IsOnlinePawn = IsOnlinePawn,
	GetPawn = GetPawn,
	IsNPCOnly = IsNPCOnly,
	GetMainPawnFavorability = GetMainPawnFavorability,
	SetMainPawnFavorability = SetMainPawnFavorability,
	GetMainPawnIsLove = GetMainPawnIsLove,
	GetManagedCharacterName = GetManagedCharacterName,
	GetManagedCharacter = GetManagedCharacter,
	GetManagedCharacterCharaID = GetManagedCharacterCharaID,
	GetManagedCharacterSentimentInfoValue = GetManagedCharacterSentimentInfoValue,
	SetManagedCharacterSentimentInfoValue = SetManagedCharacterSentimentInfoValue,
	GetManagedCharacterSentimentRank = GetManagedCharacterSentimentRank,	
	IsInParty = IsInParty,
	IsASelectedNPC = IsASelectedNPC,
	GetCharacterPositionString = GetCharacterPositionString,
	GetManagedCharacterLabel = GetManagedCharacterLabel,
	GetManagedCharacterLabel2 = GetManagedCharacterLabel2,
	RefreshManagedCharacterIndexList = RefreshManagedCharacterIndexList,
	GetManagedCharacterIndexByCharacterID = GetManagedCharacterIndexByCharacterID,
	GetManagedCharacterIndex = GetManagedCharacterIndex,
	GetManagedCharacterGroupDetails = GetManagedCharacterGroupDetails,
	IsBRConditionsMet = IsBRConditionsMet,
	SetBattleRelationship = SetBattleRelationship,
	GetFrontAngles = GetFrontAngles,
	GetEstimatedNewPositionBasedOnAngle = GetEstimatedNewPositionBasedOnAngle,
	GetEstimatedCharacterFocusTarget = GetEstimatedCharacterFocusTarget,
	SetCharacterFocus = SetCharacterFocus,
	GetFsm = GetFsm,
	GetFsmEnabled = GetFsmEnabled,
	SetFsmEnabled = SetFsmEnabled,
	GetMotionEnabled = GetMotionEnabled,
	SetMotionEnabled = SetMotionEnabled,
	TeleportCharacterToTargetCharacterPosition = TeleportCharacterToTargetCharacterPosition,
	TeleportNPCToTargetCharacterPosition = TeleportNPCToTargetCharacterPosition,
	TeleportPartyMemberOrNPCToTargetCharacterPosition = TeleportPartyMemberOrNPCToTargetCharacterPosition,
	IsNPCDead = IsNPCDead,
	TeleportCharacter = TeleportCharacter,
	TeleportCharacterBySteps = TeleportCharacterBySteps,
	RegenerateCharacter = RegenerateCharacter,
	RegenerateCharacterByCharacterIndex = RegenerateCharacterByCharacterIndex,
	GetManagedCharacterUniversalPosition = GetManagedCharacterUniversalPosition,
	GetManagedCharacterDistanceFromPlayerCharacter = GetManagedCharacterDistanceFromPlayerCharacter,
	IsNearPlayerCharacter = IsNearPlayerCharacter,
	RespawnMainPawn = RespawnMainPawn,
	SetupAvailableCharactersListUI = SetupAvailableCharactersListUI,
	SetupNPCIDListUI = SetupNPCIDListUI,
	RefreshManagedCharacterCache = RefreshManagedCharacterCache,
	
}

return characterHelper

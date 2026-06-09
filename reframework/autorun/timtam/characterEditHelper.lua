local common
local characterHelper

local currentVersion = "1.1.22"

local ceh = {}
ceh.Initialized = false
ceh.listsRequireRefreshing = false
ceh.listRefreshDelayDefault = 30
ceh.listRefreshDelay = ceh.listRefreshDelayDefault
ceh.listRefreshAttempts = 0
ceh.listRefreshAttemptsLimit = 10
ceh.isMeshVariableNamesDataLoaded = false
ceh.swapCostumeRequester = ""

local filesList = {}
filesList.mainFolderName = "timtam"
filesList.costumeOptionsFolderName = filesList.mainFolderName .. "\\\\CostumeOptions"
filesList.weaponOptionsFolderName = filesList.mainFolderName .. "\\\\WeaponOptions"
filesList.meshOptionsFolderName = filesList.mainFolderName .. "\\\\MeshOptions"
filesList.meshMaterialVariableNamesSingleFileName = filesList.mainFolderName .. "/MESHMATERIALVARIABLENAMES_SINGLE.json"
filesList.meshMaterialVariableNamesColorFileName = filesList.mainFolderName .. "/MESHMATERIALVARIABLENAMES_COLOR.json"

local ENUMS = {}
ENUMS.CHARACTEREDITTYPES = {
	[-1] = "Нет",
	[0] = "ВСЁ",
	[1] = "Всё кроме костюма",
	[2] = "Голова и детали*",
	[3] = "Тело и детали тела",
	[4] = "Тело",
	[5] = "Детали тела",
	[6] = "Только голова*",
	[7] = "Причёска*",
	[8] = "Детали волос*",
	[9] = "Лицо*",
	[10] = "Борода*",
	[11] = "Макияж*",
	[12] = "Раса",
	[13] = "Пол",
	[14] = "Костюм"
}

ENUMS.CHARACTEREDITTYPE = {
	NONE = -1,
	ALL = 0,
	ALLEXCEPTCOSTUME = 1,
	HEADANDDETAILS = 2,
	BODYANDBODYDETAILS = 3,
	BODY = 4,
	BODYDETAILS = 5,
	HEAD = 6,
	HAIRSTYLE = 7,
	HAIRDETAILS = 8,
	FACE = 9,
	BEARD = 10,
	MAKEUP = 11,
	SPECIES = 12,
	GENDER = 13,
	COSTUME = 14,
}

ENUMS.HelmStyles = {}
ENUMS.HelmVariationStyles = {}
ENUMS.FacewearStyles = {}
ENUMS.FacewearVariationStyles = {}
ENUMS.TopsStyles = {}
ENUMS.TopsVariationStyles = {}
ENUMS.BackpackStyles = {}
ENUMS.PantsStyles = {}
ENUMS.PantsVariationStyles = {}
ENUMS.MantleStyles = {}
ENUMS.MantleVariationStyles = {}
ENUMS.UnderwearStyles = {}
ENUMS.UnderwearVariationStyles = {}

ENUMS.HelmStylesAdditionalDetails = {}
ENUMS.FacewearStylesAdditionalDetails = {}
ENUMS.TopsStylesAdditionalDetails = {}
ENUMS.BackpackStylesAdditionalDetails = {}
ENUMS.PantsStylesAdditionalDetails = {}
ENUMS.MantleStylesAdditionalDetails = {}
ENUMS.UnderwearStylesAdditionalDetails = {}

ENUMS.ch220HelmStyles = {}
ENUMS.ch220TopsStyles = {}
ENUMS.ch220PantsStyles = {}
ENUMS.ch220MantleStyles = {}
ENUMS.ch220UnderwearStyles = {}

ENUMS.ch220HelmStylesAdditionalDetails = {}
ENUMS.ch220TopsStylesAdditionalDetails = {}
ENUMS.ch220PantsStylesAdditionalDetails = {}
ENUMS.ch220MantleStylesAdditionalDetails = {}
ENUMS.ch220UnderwearStylesAdditionalDetails = {}

ENUMS.EquipDataSlotEnum = {}

ENUMS.PlayerVoiceTypes = {}
ENUMS.PersonalityIDs = {}
ENUMS.VoiceToneTypes = {}

ENUMS.JobEnum = {}

ENUMS.WeaponData = {}

ENUMS.COSTUMESOURCES = {[0] = "Персонаж / NPC", [1] = "Параметры костюма"}
ENUMS.COSTUMESOURCE = {SELECTEDCHARACTER = 0, COSTUMEOPTIONS = 1}

ENUMS.MESHMATERIALVARIABLENAMES_SINGLE = {}
ENUMS.MESHMATERIALVARIABLENAMES_COLOR = {}

ENUMS.SWAPITEMSEARCHTYPE = {
	STYLE = 0,
	MESHID = 1
}

ENUMS.TopsBdMeshIDs = {}
ENUMS.TopsBdSubMeshIDs = {}
ENUMS.TopsWbMeshIDs = {}
ENUMS.TopsWbSubMeshIDs = {}
ENUMS.TopsAmMeshIDs = {}
ENUMS.TopsAmSubMeshIDs = {}
ENUMS.TopsBtMeshIDs = {}
ENUMS.TopsBtSubMeshIDs = {}
ENUMS.PantsLgMeshIDs = {}
ENUMS.PantsLgSubMeshIDs = {}
ENUMS.PantsWlMeshIDs = {}
ENUMS.PantsWlSubMeshIDs = {}
ENUMS.HelmMeshIDs = {}
ENUMS.HelmSubMeshIDs = {}
ENUMS.MantleMeshIDs = {}
ENUMS.BackpackMeshIDs = {}
ENUMS.FacewearMeshIDs = {}
ENUMS.UnderwearMeshIDs = {}

local function GetInitialized()
	return ceh.Initialized
end

local function SetInitialized(initialized)
	ceh.Initialized = initialized
end

local function GetPartSwapper(character, mockupBuilder, mockupCtrl)
	local partSwapper
	if (character and character:get_Valid()) then
		if mockupCtrl then
			partSwapper = mockupCtrl:get_PartSwapper()
		elseif mockupBuilder then
			partSwapper = mockupBuilder:get_PartSwapper()
		else
			partSwapper = character["<HumanPartSwapper>k__BackingField"]
		end
	end
	if partSwapper and not (partSwapper.get_CharacterID and partSwapper:get_CharacterID() == character.CharacterID) then
		partSwapper = nil
	end
	return partSwapper
end

ENUMS.CHARACTEROBJECTMESHES = {
	[1] = "_TopsBdMesh",
	[2] = "_TopsBdSubMesh",
	[3] = "_TopsWbMesh",
	[4] = "_TopsWbSubMesh",
	[5] = "_TopsAmMesh",
	[6] = "_TopsAmSubMesh",
	[7] = "_TopsBtMesh",
	[8] = "_TopsBtSubMesh",
	[9] = "_TopsUwMesh",
	[10] = "_PantsLgMesh",
	[11] = "_PantsLgSubMesh",
	[12] = "_PantsWlMesh",
	[13] = "_PantsWlSubMesh",
	[14] = "_HelmMesh",
	[15] = "_HelmSubMesh",
	[16] = "_MantleMesh",
	[17] = "_BackpackMesh",
	[18] = "_FacewearMesh",
	[19] = "_UnderwearMesh",
	[20] = "_HairMesh",
	[21] = "_HairSwapMesh",
	[22] = "_BeardMesh",
	[23] = "_EyebrowMesh",
	[24] = "_RightWeaponMesh",
	[25] = "_LeftWeaponMesh",
	[26] = "Quiver",
	[27] = "Lantern",
	[28] = "Body",
	[29] = "Head",
	[30] = "Ch2Mesh",
	[31] = "MonsterMesh"
}
	--[32] = "Ch29_001Mesh",
	--[33] = "Ch29WeaponMesh",
	--[34] = "Ch259Mesh"

local function GetCharacterObjectMesh(character, characterMeshIndex, mockupBuilder, mockupCtrl)
	if characterMeshIndex > 0 then
		local objectOrMeshName = ENUMS.CHARACTEROBJECTMESHES[characterMeshIndex]
		if objectOrMeshName then
			if (character and character:get_Valid()) then
				local partSwapper = GetPartSwapper(character, mockupBuilder, mockupCtrl)
				local charaID
				local bodyEditor
				local bodyDetailEditor
				local bodyEditorObject
				local characterObjectTransform
				local characterObject
				local human
				if partSwapper then
					if partSwapper[objectOrMeshName] then
						return partSwapper[objectOrMeshName]
					end
					bodyEditor = partSwapper._BodyEditor
					if bodyEditor then
						bodyEditorObject = bodyEditor:get_GameObject()
					end
					if mockupBuilder or mockupCtrl then
						if bodyEditorObject then
							characterObjectTransform = bodyEditorObject:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
						end
					elseif character then
						if characterObject then
							characterObjectTransform = characterObject:get_Transform()
						end
					end
					if characterObjectTransform then
						local characterTransformMeshComponent = characterObjectTransform:find(objectOrMeshName)
						if characterTransformMeshComponent then
							local characterTransformMeshComponentObject = characterTransformMeshComponent:get_GameObject()
							if characterTransformMeshComponentObject then
								return characterTransformMeshComponentObject:call("getComponent(System.Type)", sdk.typeof("via.render.Mesh"))
							end
						end
					end
					characterObject = character:get_GameObject()
					human = character:get_Human()
					bodyDetailEditor = partSwapper["<BodyDetailEditor>k__BackingField"]
					if objectOrMeshName == "_RightWeaponMesh" then
						local rightWeapon = character:get_RightWeapon()
						if rightWeapon then
							return rightWeapon.Mesh
						end
					elseif objectOrMeshName == "_LeftWeaponMesh" then
						local leftWeapon = character:get_LeftWeapon()
						if leftWeapon then
							return leftWeapon.Mesh
						end
					elseif objectOrMeshName == "Quiver" or objectOrMeshName == "Lantern" then
						if human then
							if objectOrMeshName == "Quiver" then
								local quiverController = human["<QuiverController>k__BackingField"]
								if quiverController then
									return quiverController.QuiverMesh
								end
							elseif objectOrMeshName == "Lantern" then
								local humanLanternController = human["<LanternCtrl>k__BackingField"]
								if humanLanternController then
									return humanLanternController["<LanternMesh>k__BackingField"]
								end
							end
						end
					elseif objectOrMeshName == "Body" or objectOrMeshName == "Head" then
						if bodyDetailEditor then
							if objectOrMeshName == "Body" then
								return bodyDetailEditor["<BodyMesh>k__BackingField"]
							elseif objectOrMeshName == "Head" then
								return bodyDetailEditor["<HeadMesh>k__BackingField"]
							end
						end
					end
				elseif objectOrMeshName == "Ch2Mesh" then
					local Ch2 = characterHelper.GetEnemy(character)
					if Ch2 then
						if objectOrMeshName == "Ch2Mesh" then
							return Ch2._Mesh
						end
					end
				elseif objectOrMeshName == "MonsterMesh" then
					local monster = characterHelper.GetMonster(character)
					if monster then
						return monster._Mesh
					end
				elseif objectOrMeshName == "Ch29_001Mesh" or objectOrMeshName == "Ch29WeaponMesh" then
--how do i get ch29?
					local Ch29 = characterHelper.GetEnemy(character)
					if Ch29 then
						if objectOrMeshName == "Ch29_001Mesh" and Ch29["<Ch29_001Mesh>k__BackingField"] then
							return Ch29["<Ch29_001Mesh>k__BackingField"]
						elseif objectOrMeshName == "Ch29WeaponMesh" and Ch29.WeaponMesh then
							return Ch29.WeaponMesh
						end
					end
				elseif objectOrMeshName == "Ch259Mesh" then
					if character then
						local enemyController = character:get_EnemyController()
						if enemyController and enemyController._IsCh259000 then
--how do i get ch259?
							local Ch259 = characterHelper.GetEnemy(character)
							if Ch259 then
								local modelController = Ch259["<ModelController>k__BackingField"]
								if modelController and modelController["<Mesh>k__BackingField"] then
									return modelController["<Mesh>k__BackingField"]
								end
							end
						end
					end
				end
			end
		end
	end
	return nil
end

local function RefreshMeshMaterialVariableNamesData()
	ENUMS.MESHMATERIALVARIABLENAMES_SINGLE = json.load_file(filesList.meshMaterialVariableNamesSingleFileName)
	ENUMS.MESHMATERIALVARIABLENAMES_COLOR = json.load_file(filesList.meshMaterialVariableNamesColorFileName)
	ceh.isMeshVariableNamesDataLoaded = true
end

local function GetDefaultCostumeDetails()
	local defaultCosumeDetails = {}
	defaultCosumeDetails._HelmStyle = 0
	defaultCosumeDetails._HelmVariationStyle = 0
	defaultCosumeDetails._FacewearStyle = 0
	defaultCosumeDetails._FacewearVariationStyle = 0
	defaultCosumeDetails._TopsStyle = 0
	defaultCosumeDetails._TopsVariationStyle = 0
	defaultCosumeDetails._BackpackStyle = 0
	defaultCosumeDetails._PantsStyle = 0
	defaultCosumeDetails._PantsVariationStyle = 0
	defaultCosumeDetails._MantleStyle = 0
	defaultCosumeDetails._MantleVariationStyle = 0
	defaultCosumeDetails._UnderwearStyle = 905051872
	defaultCosumeDetails._UnderwearVariationStyle = 0
	return defaultCosumeDetails
end

local function GetDefaultCostumeVariationStyleDetails()
	local defaultCosumeVariationStyleDetails = {}
	defaultCosumeVariationStyleDetails._HelmVariationStyle = 0
	defaultCosumeVariationStyleDetails._FacewearVariationStyle = 0
	defaultCosumeVariationStyleDetails._TopsVariationStyle = 0
	defaultCosumeVariationStyleDetails._PantsVariationStyle = 0
	defaultCosumeVariationStyleDetails._MantleVariationStyle = 0
	defaultCosumeVariationStyleDetails._UnderwearVariationStyle = 0
	return defaultCosumeVariationStyleDetails
end

local function GetDefaultWeaponDetails()
	local defaultWeaponDetails = {}
	defaultWeaponDetails._RightWeaponJob = 0
	defaultWeaponDetails._RightWeapon = 0
	defaultWeaponDetails._IsRightWeaponDraconic = false
	defaultWeaponDetails._LeftWeaponJob = 0
	defaultWeaponDetails._LeftWeapon = 0
	defaultWeaponDetails._IsLeftWeaponDraconic = false
	return defaultWeaponDetails
end

local function GetCharacterDefaultMeshDetailsItem(currentCharacterMeshDetailsItem)
	if not ceh.isMeshVariableNamesDataLoaded then
		RefreshMeshMaterialVariableNamesData()
	end
	local defaultCharacterMeshDetailsItem = {}
	defaultCharacterMeshDetailsItem.ShouldRefresh = false
	defaultCharacterMeshDetailsItem.Name = ""
	defaultCharacterMeshDetailsItem.MeshIDName = nil
	defaultCharacterMeshDetailsItem.Materials = {}
	defaultCharacterMeshDetailsItem.MeshIDNameChanged = false
	defaultCharacterMeshDetailsItem.MaterialsChanged = false
	defaultCharacterMeshDetailsItem.ResetMeshIDName = false
	defaultCharacterMeshDetailsItem.SwapTops = false
	defaultCharacterMeshDetailsItem.SwapPants = false
	defaultCharacterMeshDetailsItem.SwapHelm = false
	defaultCharacterMeshDetailsItem.SwapMantle = false
	defaultCharacterMeshDetailsItem.SwapBackpack = false
	defaultCharacterMeshDetailsItem.SwapFacewear = false
	defaultCharacterMeshDetailsItem.SwapUnderwear = false
	--defaultCharacterMeshDetailsItem.SwapCh220Tops = false
	--defaultCharacterMeshDetailsItem.SwapCh220Pants = false
	--defaultCharacterMeshDetailsItem.SwapCh220Helm = false
	--defaultCharacterMeshDetailsItem.SwapCh220Mantle = false
	--defaultCharacterMeshDetailsItem.SwapCh220Underwear = false
	if currentCharacterMeshDetailsItem then
		common.CopyArrayItemValueIfNotNull(defaultCharacterMeshDetailsItem, currentCharacterMeshDetailsItem, "Name")
		common.CopyArrayItemValueIfNotNull(defaultCharacterMeshDetailsItem, currentCharacterMeshDetailsItem, "MeshIDName")
		if currentCharacterMeshDetailsItem.Materials ~= nil then
			for matIdx, material in pairs(currentCharacterMeshDetailsItem.Materials) do
				defaultCharacterMeshDetailsItem.Materials[tostring(matIdx)] = {}
				if material.Enabled ~= nil then
					defaultCharacterMeshDetailsItem.Materials[tostring(matIdx)].Enabled = material.Enabled
				end
				for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_SINGLE) do
					common.CopyArrayItemValueIfNotNull(defaultCharacterMeshDetailsItem.Materials[tostring(matIdx)], currentCharacterMeshDetailsItem, mmvName)
				end
				common.CopyArrayItemValueIfNotNull(defaultCharacterMeshDetailsItem.Materials[tostring(matIdx)], currentCharacterMeshDetailsItem, "CustomSingleValueName_" .. tostring(matIdx))
				common.CopyArrayItemValueIfNotNull(defaultCharacterMeshDetailsItem.Materials[tostring(matIdx)], currentCharacterMeshDetailsItem, "CustomSingleValue_" .. tostring(matIdx))
				for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_COLOR) do
					common.CopyArrayItemValueIfNotNull(defaultCharacterMeshDetailsItem.Materials[tostring(matIdx)], currentCharacterMeshDetailsItem, mmvName)
				end
				common.CopyArrayItemValueIfNotNull(defaultCharacterMeshDetailsItem.Materials[tostring(matIdx)], currentCharacterMeshDetailsItem, "CustomColorName_" .. tostring(matIdx))
				common.CopyArrayItemValueIfNotNull(defaultCharacterMeshDetailsItem.Materials[tostring(matIdx)], currentCharacterMeshDetailsItem, "CustomColor_" .. tostring(matIdx))
				defaultCharacterMeshDetailsItem.Materials[tostring(matIdx)].SingleValueChanged = common.GetBooleanValue(material.SingleValueChanged)
				defaultCharacterMeshDetailsItem.Materials[tostring(matIdx)].ColorChanged = common.GetBooleanValue(material.ColorChanged)
			end
		end
		defaultCharacterMeshDetailsItem.MeshIDNameChanged = common.GetBooleanValue(currentCharacterMeshDetailsItem.MeshIDNameChanged)
		defaultCharacterMeshDetailsItem.MaterialsChanged = common.GetBooleanValue(currentCharacterMeshDetailsItem.MaterialsChanged)
		defaultCharacterMeshDetailsItem.ResetMeshIDName = common.GetBooleanValue(currentCharacterMeshDetailsItem.ResetMeshIDName)
		defaultCharacterMeshDetailsItem.SwapTops = common.GetBooleanValue(currentCharacterMeshDetailsItem.SwapTops)
		defaultCharacterMeshDetailsItem.SwapPants = common.GetBooleanValue(currentCharacterMeshDetailsItem.SwapPants)
		defaultCharacterMeshDetailsItem.SwapHelm = common.GetBooleanValue(currentCharacterMeshDetailsItem.SwapHelm)
		defaultCharacterMeshDetailsItem.SwapMantle = common.GetBooleanValue(currentCharacterMeshDetailsItem.SwapMantle)
		defaultCharacterMeshDetailsItem.SwapBackpack = common.GetBooleanValue(currentCharacterMeshDetailsItem.SwapBackpack)
		defaultCharacterMeshDetailsItem.SwapFacewear = common.GetBooleanValue(currentCharacterMeshDetailsItem.SwapFacewear)
		defaultCharacterMeshDetailsItem.SwapUnderwear = common.GetBooleanValue(currentCharacterMeshDetailsItem.SwapUnderwear)
	end
	return defaultCharacterMeshDetailsItem
end

local function GetDefaultCharacterObjectMeshDetails()
	local defaultCharacterObjectMeshDetails = {}
	for i = 1, #ENUMS.CHARACTEROBJECTMESHES do
		defaultCharacterObjectMeshDetails[tostring(i)] = GetCharacterDefaultMeshDetailsItem(nil)
		defaultCharacterObjectMeshDetails[tostring(i)].Name = ENUMS.CHARACTEROBJECTMESHES[i]
	end
	return defaultCharacterObjectMeshDetails
end

removeUnknownGenderStyles = true

CURRENTITEMVALUENAME = "[Current Value]"
local CURRENTITEMVALUE = -1

local function PopulateLists(refreshOnlyItemsThatRequireRefreshing)

	local alwaysRemoveUnknownGenderStyles = false

	if not refreshOnlyItemsThatRequireRefreshing or (refreshOnlyItemsThatRequireRefreshing and ENUMS.HelmStylesAdditionalDetails.ShouldRefresh) then

		alwaysRemoveUnknownGenderStyles = (refreshOnlyItemsThatRequireRefreshing and ENUMS.HelmStylesAdditionalDetails.ShouldRefresh) and ceh.listRefreshAttempts >= (ceh.listRefreshAttemptsLimit + 1)

		ENUMS.HelmStyles, ENUMS.HelmStylesAdditionalDetails = common.AppendGenderToListItems(common.AppendItemNamesToListItems(common.generate_enum_reverse("app.HelmStyle"), "app.HelmStyle"), "app.HelmStyle", "_HelmDB", removeUnknownGenderStyles or alwaysRemoveUnknownGenderStyles, ENUMS.HelmStylesAdditionalDetails.ShouldRefresh)
		ENUMS.HelmStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.HelmStyles, "HelmStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)

	end

	if not refreshOnlyItemsThatRequireRefreshing or (refreshOnlyItemsThatRequireRefreshing and ENUMS.FacewearStylesAdditionalDetails.ShouldRefresh) then

		alwaysRemoveUnknownGenderStyles = (refreshOnlyItemsThatRequireRefreshing and ENUMS.FacewearStylesAdditionalDetails.ShouldRefresh) and ceh.listRefreshAttempts >= (ceh.listRefreshAttemptsLimit + 1)

		ENUMS.FacewearStyles, ENUMS.FacewearStylesAdditionalDetails = common.AppendGenderToListItems(common.AppendItemNamesToListItems(common.generate_enum_reverse("app.FacewearStyle"), "app.FacewearStyle"), "app.FacewearStyle", "_FacewearDB", removeUnknownGenderStyles or alwaysRemoveUnknownGenderStyles, ENUMS.FacewearStylesAdditionalDetails.ShouldRefresh)
		ENUMS.FacewearStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.FacewearStyles, "FacewearStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)

	end

	if not refreshOnlyItemsThatRequireRefreshing or (refreshOnlyItemsThatRequireRefreshing and ENUMS.TopsStylesAdditionalDetails.ShouldRefresh) then

		alwaysRemoveUnknownGenderStyles = (refreshOnlyItemsThatRequireRefreshing and ENUMS.TopsStylesAdditionalDetails.ShouldRefresh) and ceh.listRefreshAttempts >= (ceh.listRefreshAttemptsLimit + 1)

		ENUMS.TopsStyles, ENUMS.TopsStylesAdditionalDetails = common.AppendGenderToListItems(common.AppendItemNamesToListItems(common.generate_enum_reverse("app.TopsStyle"), "app.TopsStyle"), "app.TopsStyle", "_TopsDB", removeUnknownGenderStyles or alwaysRemoveUnknownGenderStyles, ENUMS.TopsStylesAdditionalDetails.ShouldRefresh)
		ENUMS.TopsStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.TopsStyles, "TopsStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)

	end

	if not refreshOnlyItemsThatRequireRefreshing or (refreshOnlyItemsThatRequireRefreshing and ENUMS.BackpackStylesAdditionalDetails.ShouldRefresh) then

		alwaysRemoveUnknownGenderStyles = (refreshOnlyItemsThatRequireRefreshing and ENUMS.BackpackStylesAdditionalDetails.ShouldRefresh) and ceh.listRefreshAttempts >= (ceh.listRefreshAttemptsLimit + 1)

		ENUMS.BackpackStyles, ENUMS.BackpackStylesAdditionalDetails = common.AppendGenderToListItems(common.AppendItemNamesToListItems(common.generate_enum_reverse("app.BackpackStyle"), "app.BackpackStyle"), "app.BackpackStyle", "_BackpackDB", removeUnknownGenderStyles or alwaysRemoveUnknownGenderStyles, ENUMS.BackpackStylesAdditionalDetails.ShouldRefresh)
		ENUMS.BackpackStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.BackpackStyles, "BackpackStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)

	end

	if not refreshOnlyItemsThatRequireRefreshing or (refreshOnlyItemsThatRequireRefreshing and ENUMS.PantsStylesAdditionalDetails.ShouldRefresh) then

		alwaysRemoveUnknownGenderStyles = (refreshOnlyItemsThatRequireRefreshing and ENUMS.PantsStylesAdditionalDetails.ShouldRefresh) and ceh.listRefreshAttempts >= (ceh.listRefreshAttemptsLimit + 1)

		ENUMS.PantsStyles, ENUMS.PantsStylesAdditionalDetails = common.AppendGenderToListItems(common.AppendItemNamesToListItems(common.generate_enum_reverse("app.PantsStyle"), "app.PantsStyle"), "app.PantsStyle", "_PantsDB", removeUnknownGenderStyles or alwaysRemoveUnknownGenderStyles, ENUMS.PantsStylesAdditionalDetails.ShouldRefresh)
		ENUMS.PantsStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.PantsStyles, "PantsStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)

	end

	if not refreshOnlyItemsThatRequireRefreshing or (refreshOnlyItemsThatRequireRefreshing and ENUMS.MantleStylesAdditionalDetails.ShouldRefresh) then

		alwaysRemoveUnknownGenderStyles = (refreshOnlyItemsThatRequireRefreshing and ENUMS.MantleStylesAdditionalDetails.ShouldRefresh) and ceh.listRefreshAttempts >= (ceh.listRefreshAttemptsLimit + 1)

		ENUMS.MantleStyles, ENUMS.MantleStylesAdditionalDetails = common.AppendGenderToListItems(common.AppendItemNamesToListItems(common.generate_enum_reverse("app.MantleStyle"), "app.MantleStyle"), "app.MantleStyle", "_MantleDB", removeUnknownGenderStyles or alwaysRemoveUnknownGenderStyles, ENUMS.MantleStylesAdditionalDetails.ShouldRefresh)
		ENUMS.MantleStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.MantleStyles, "MantleStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)

	end

	if not refreshOnlyItemsThatRequireRefreshing or (refreshOnlyItemsThatRequireRefreshing and ENUMS.UnderwearStylesAdditionalDetails.ShouldRefresh) then

		alwaysRemoveUnknownGenderStyles = (refreshOnlyItemsThatRequireRefreshing and ENUMS.UnderwearStylesAdditionalDetails.ShouldRefresh) and ceh.listRefreshAttempts >= (ceh.listRefreshAttemptsLimit + 1)

		ENUMS.UnderwearStyles, ENUMS.UnderwearStylesAdditionalDetails = common.AppendGenderToListItems(common.AppendItemNamesToListItems(common.generate_enum_reverse("app.UnderwearStyle"), "app.UnderwearStyle"), "app.UnderwearStyle", "_UnderwearDB", removeUnknownGenderStyles or alwaysRemoveUnknownGenderStyles, ENUMS.UnderwearStylesAdditionalDetails.ShouldRefresh)
		ENUMS.UnderwearStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.UnderwearStyles, "UnderwearStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)

	end

	if not refreshOnlyItemsThatRequireRefreshing then

		ENUMS.HelmVariationStyles = common.generate_enum_reverse("app.charaedit.ch000.HelmVariationStyle")
		ENUMS.HelmVariationStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.HelmVariationStyles, "HelmVariationStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)
		ENUMS.FacewearVariationStyles = common.generate_enum_reverse("app.charaedit.ch000.FacewearVariationStyle")
		ENUMS.FacewearVariationStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.FacewearVariationStyles, "FacewearVariationStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)
		ENUMS.TopsVariationStyles = common.generate_enum_reverse("app.charaedit.ch000.TopsVariationStyle")
		ENUMS.TopsVariationStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.TopsVariationStyles, "TopsVariationStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)
		ENUMS.PantsVariationStyles = common.generate_enum_reverse("app.charaedit.ch000.PantsVariationStyle")
		ENUMS.PantsVariationStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.PantsVariationStyles, "PantsVariationStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)
		ENUMS.MantleVariationStyles = common.generate_enum_reverse("app.charaedit.ch000.MantleVariationStyle")
		ENUMS.MantleVariationStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.MantleVariationStyles, "MantleVariationStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)
		ENUMS.UnderwearVariationStyles = common.generate_enum_reverse("app.charaedit.ch000.UnderwearVariationStyle")
		ENUMS.UnderwearVariationStyles = common.edit_enum(common.AddContentEditorContentToEnum(ENUMS.UnderwearVariationStyles, "UnderwearVariationStyle"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)

		ENUMS.TopsBdMeshIDs = common.generate_enum_reverse("app.CharacterEditDefine.TopsBdMeshID")
		ENUMS.TopsBdSubMeshIDs = ENUMS.TopsBdMeshIDs
		ENUMS.TopsWbMeshIDs = common.generate_enum_reverse("app.CharacterEditDefine.TopsWbMeshID")
		ENUMS.TopsWbSubMeshIDs = ENUMS.TopsWbMeshIDs
		ENUMS.TopsAmMeshIDs = common.generate_enum_reverse("app.CharacterEditDefine.TopsAmMeshID")
		ENUMS.TopsAmSubMeshIDs = ENUMS.TopsAmMeshIDs
		ENUMS.TopsBtMeshIDs = common.generate_enum_reverse("app.CharacterEditDefine.TopsBtMeshID")
		ENUMS.TopsBtSubMeshIDs = ENUMS.TopsBtMeshIDs
		ENUMS.PantsLgMeshIDs = common.generate_enum_reverse("app.CharacterEditDefine.PantsLgMeshID")
		ENUMS.PantsLgSubMeshIDs = ENUMS.PantsLgMeshIDs
		ENUMS.PantsWlMeshIDs = common.generate_enum_reverse("app.CharacterEditDefine.PantsWlMeshID")
		ENUMS.PantsWlSubMeshIDs = ENUMS.PantsWlMeshIDs
		ENUMS.HelmMeshIDs = common.generate_enum_reverse("app.CharacterEditDefine.HelmMeshID")
		ENUMS.HelmSubMeshIDs = ENUMS.HelmMeshIDs
		ENUMS.MantleMeshIDs = common.generate_enum_reverse("app.CharacterEditDefine.MantleMeshID")
		ENUMS.BackpackMeshIDs = common.generate_enum_reverse("app.CharacterEditDefine.BackpackMeshID")
		ENUMS.FacewearMeshIDs = common.generate_enum_reverse("app.CharacterEditDefine.FacewearMeshID")
		ENUMS.UnderwearMeshIDs = common.generate_enum_reverse("app.CharacterEditDefine.UnderwearMeshID")

		ENUMS.EquipDataSlotEnum = common.generate_enum("app.EquipData.SlotEnum")

		ENUMS.PlayerVoiceTypes = common.generate_enum_reverse("app.SoundVoiceManager.PlayerVoiceType")
		ENUMS.PersonalityIDs = common.generate_enum_reverse("app.PersonalityDefine.PersonalityID")
		ENUMS.VoiceToneTypes = common.generate_enum_reverse("app.SoundVoiceManager.VoiceToneType")

		ENUMS.JobEnum = common.generate_enum_reverse("app.Character.ENUMS.JobEnum")

		ENUMS.WeaponData = common.edit_enum(common.AppendItemNamesToListItems(common.generate_enum_reverse("app.WeaponID"), "app.WeaponID"), CURRENTITEMVALUENAME, CURRENTITEMVALUE)

		common.SetIsFileListLoaded(filesList.costumeOptionsFolderName, false)
		common.RefreshFileNamesList(filesList.costumeOptionsFolderName)
		common.SetIsFileListLoaded(filesList.weaponOptionsFolderName, false)
		common.RefreshFileNamesList(filesList.weaponOptionsFolderName)
		common.SetIsFileListLoaded(filesList.meshOptionsFolderName, false)
		common.RefreshFileNamesList(filesList.meshOptionsFolderName)

	end

	ceh.listsRequireRefreshing = ENUMS.HelmStylesAdditionalDetails.ShouldRefresh
		or ENUMS.FacewearStylesAdditionalDetails.ShouldRefresh
		or ENUMS.TopsStylesAdditionalDetails.ShouldRefresh
		or ENUMS.BackpackStylesAdditionalDetails.ShouldRefresh
		or ENUMS.PantsStylesAdditionalDetails.ShouldRefresh
		or ENUMS.MantleStylesAdditionalDetails.ShouldRefresh
		or ENUMS.UnderwearStylesAdditionalDetails.ShouldRefresh
		--or ENUMS.ch220HelmStylesAdditionalDetails.ShouldRefresh
		--or ENUMS.ch220TopsStylesAdditionalDetails.ShouldRefresh
		--or ENUMS.ch220PantsStylesAdditionalDetails.ShouldRefresh
		--or ENUMS.ch220MantleStylesAdditionalDetails.ShouldRefresh
		--or ENUMS.ch220UnderwearStylesAdditionalDetails.ShouldRefresh

end

local function SetCommon(newCommon, newCharacterHelper)
	common = newCommon
	characterHelper = newCharacterHelper
	PopulateLists()
end

local function IsCharacterReadyToBeEdited(character)
	if character and character["<HumanPartSwapper>k__BackingField"] and character:get_Valid() then
		return true
	end
	return false
end

local function StartFaceEdits(ccItems, faceEditor)
	--if ccItems then
	--	if faceEditor then
	--		if ccItems.LocationType == "Anywhere" and ccItems.EditContexts then
	--			faceEditor:setupContext()
	--		end
	--	end
	--end
end

local function EndFaceEdits(ccItems, faceEditor)
	--if ccItems then
	--	if ccItems.PartSwapper then
	--		if ccItems.LocationType == "Anywhere" and ccItems.SaveContext then
	--			ccItems.PartSwapper:saveContext()
	--			ccItems.PartSwapper:recontext()
	--		end
	--	end
	--end
end

local function StartBodyEdits(ccItems, bodyEditor)
	if ccItems then
		if bodyEditor then
			if ccItems.LocationType == "Anywhere" then
	--			if  ccItems.EditContexts then
	--				bodyEditor:setupContext()
	--			end
			end
		end
	end
end

local function EndBodyEdits(ccItems, bodyEditor)
	if ccItems then
		if bodyEditor then
	--		if ccItems.LocationType == "Anywhere" and ccItems.SaveContext then
	--		end
	--	end
	--	if ccItems.PartSwapper then
	--		if ccItems.LocationType == "Anywhere" and ccItems.SaveContext then
	--			ccItems.PartSwapper:saveContext()
	--			ccItems.PartSwapper:recontext()
	--			if not ccItems.SkipRequestSwap then
	--				ccItems.PartSwapper:requestSwap()
	--			end
	--		end
		end
	end
end

local function StartBodyDetailEdits(ccItems)
	if ccItems then
		if ccItems.BodyDetailEditor then
			if ccItems.LocationType == "Anywhere" and ccItems.CharacterIndex > characterHelper.GetPartyMembersFinalIndex(ccItems.config) then
	--			if ccItems.EditContexts then
	--				ccItems.BodyDetailEditor:setupContext()
	--			end
				ccItems.BodyDetailEditor:set_MaterialBake(0)
	--		elseif ccItems.LocationType == "Anywhere" and ccItems.CharacterIndex <= characterHelper.GetPartyMembersFinalIndex(ccItems.config) then
	--			ccItems.BodyDetailEditor:set_MaterialBake(0)
			end
		end
	end
end

local function EndBodyDetailEdits(ccItems)
	if ccItems then
	--	if ccItems.PartSwapper and ccItems.LocationType == "Anywhere" then
	--		if ccItems.LocationType == "Anywhere" and ccItems.SaveContext then
	--			ccItems.PartSwapper:saveContext()
	--			ccItems.PartSwapper:recontext()
	--		end
		end
	--	if ccItems.BodyDetailEditor then
	--		if ccItems.LocationType == "Anywhere" then
	--			ccItems.BodyDetailEditor:apply()
	--			ccItems.BodyDetailEditor:requestForceApplyDetails()
	--		end
	--	end
	--end
end

local function StartPartSwapperEdits(ccItems)
	--if ccItems then
	--	if ccItems.PartSwapper then
	--		if ccItems.LocationType == "Anywhere" and ccItems.EditContexts then
	--			ccItems.PartSwapper:setupContext()
	--		end
	--	end
	--end
end


local function EndPartSwapperEdits(ccItems)
	if ccItems then
		if ccItems.PartSwapper then
	--		if and ccItems.LocationType == "Anywhere" then
	--			if ccItems.SaveContext then
	--				ccItems.PartSwapper:saveContext()
	--				ccItems.PartSwapper:recontext()
	--			end
	--		end
			if not ccItems.SkipRequestSwap then
				ccItems.PartSwapper:requestSwap()
			end
		end
	end
end

local function ApplyBodyDetailEdits(ccItems)
	if ccItems then
		if ccItems.BodyDetailEditor then
			if ccItems.LocationType == "Anywhere" and ccItems.EditContexts then
				ccItems.BodyDetailEditor:apply()
				ccItems.BodyDetailEditor:requestForceApplyDetails()
			end
		end
	--	EndPartSwapperEdits(ccItems)
	end
end

local function CharacterEditManagerRequestLimiterRemoval()
	local CharacterEditManager = sdk.get_managed_singleton("app.CharacterEditManager")
	if CharacterEditManager then
		CharacterEditManager:requestLimiterRemoval()
		CharacterEditManager:set_BuildLimiter(false)
		CharacterEditManager:set_CurrentBuildLimiter(false)
	end
end

local function HumanEditControllerSetEditLimited(isLimited)
	local GuiManager = sdk.get_managed_singleton("app.GuiManager")
	if GuiManager then
		local GUICharaEditCtrl = GuiManager._CharaEditCtrl
		if GUICharaEditCtrl then
			GUICharaEditCtrl:setEditLimitFlag(isLimited)
			GUICharaEditCtrl:set_IsEditLimited(isLimited)

			local guiPreviewModelEditor = GuiManager._CharaEditCtrl["<ModelEditor>k__BackingField"]
			local editInfoSet = guiPreviewModelEditor.Edit
			if editInfoSet then
				local humanEditController = editInfoSet.EditCtrl
				if humanEditController then
					humanEditController:setEditLimited(isLimited)
				end
			end
		end
	end
end

local function GetAECode(character)
	return characterHelper.IsOnlinePawn(character)
end

local function GetFinalEPCode(pEPCode)
	return (pEPCode < -25 or pEPCode > -25)
end

local epCode = 1
local function SetEPCode(PEPCode)
	epCode = PEPCode
end

local function repc()
	epCode = 151
end

local function GetEditValues(editor, getEditValuesFunctionName)
	local editValues = {}
	local editorList = editor:call(getEditValuesFunctionName)
	local editorListCount = editorList:get_Count()
	for i = 0, editorListCount - 1 do
		local editorItem = editorList:get_Item(i)
		editValues[i] = {}
		editValues[i]._Value = editorItem._Value
		editValues[i]._EditKeyHash = editorItem._EditKeyHash
	end
	return editValues
end

local function EditHair(hair, hairDetails, parseColors, ccItems)
	if hair and hairDetails then
		if parseColors then
			hair:set_RootColor(common.ParseColor(hairDetails._RootColor))
			hair:set_TipColor(common.ParseColor(hairDetails._TipColor))
			if hair._CapRootColor and hairDetails._CapRootColor then
				hair:set_CapRootColor(common.ParseColor(hairDetails._CapRootColor))
			end
		else
			hair:set_RootColor(hairDetails._RootColor)
			hair:set_TipColor(hairDetails._TipColor)
			if hair._CapRootColor and hairDetails._CapRootColor then
				hair:set_CapRootColor(hairDetails._CapRootColor)
			end
		end
		if hair.set_AutoCapColor then
			hair:set_AutoCapColor(hairDetails._AutoCapColor)
		end
		hair:set_TipBlend(hairDetails._TipBlend)
		hair:set_Sheen(hairDetails._Sheen)
		hair:set_Gloss(hairDetails._Gloss)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditEyeliner(eyeliner, eyelinerDetails, parseColors, ccItems)
	if eyeliner and eyelinerDetails then
		if parseColors then
			eyeliner:set_Color(common.ParseColor(eyelinerDetails._Color))
		else
			eyeliner:set_Color(eyelinerDetails._Color)
		end
		eyeliner:set_Thickness(eyelinerDetails._Thickness)
		eyeliner:set_Opacity(eyelinerDetails._Opacity)
		eyeliner:set_Metallic(eyelinerDetails._Metallic)
		eyeliner:set_Roughness(eyelinerDetails._Roughness)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditEyeshadowBase(eyeshadowBase, eyeshadowBaseDetails, ccItems)
	if eyeshadowBase and eyeshadowBaseDetails then
		eyeshadowBase:set_Spread(eyeshadowBaseDetails._Spread)
		eyeshadowBase:set_Opacity(eyeshadowBaseDetails._Opacity)
		eyeshadowBase:set_Metallic(eyeshadowBaseDetails._Metallic)
		eyeshadowBase:set_Roughness(eyeshadowBaseDetails._Roughness)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditEyeshadow(eyeshadow, eyeshadowDetails, parseColors, ccItems)
	if eyeshadow and eyeshadowDetails then
		if eyeshadow._Common and eyeshadowDetails._Common then
			if parseColors then
				eyeshadow._Common:set_Color1(common.ParseColor(eyeshadowDetails._Common._Color1))
				eyeshadow._Common:set_Color2(common.ParseColor(eyeshadowDetails._Common._Color2))
			else
				eyeshadow._Common:set_Color1(eyeshadowDetails._Common._Color1)
				eyeshadow._Common:set_Color2(eyeshadowDetails._Common._Color2)
			end
			eyeshadow._Common:set_Thickness(eyeshadowDetails._Common._Thickness)
			eyeshadow._Common:set_Opacity(eyeshadowDetails._Common._Opacity)
			eyeshadow._Common:set_Metallic(eyeshadowDetails._Common._Metallic)
			eyeshadow._Common:set_Roughness(eyeshadowDetails._Common._Roughness)
		elseif eyeshadow._Common then
			if parseColors then
				eyeshadow._Common:set_Color1(common.ParseColor(eyeshadowDetails._Color1))
				eyeshadow._Common:set_Color2(common.ParseColor(eyeshadowDetails._Color2))
			else
				eyeshadow._Common:set_Color1(eyeshadowDetails._Color1)
				eyeshadow._Common:set_Color2(eyeshadowDetails._Color2)
			end
			eyeshadow._Common:set_Thickness(eyeshadowDetails._Thickness)
			eyeshadow._Common:set_Opacity(eyeshadowDetails._Opacity)
			eyeshadow._Common:set_Metallic(eyeshadowDetails._Metallic)
			eyeshadow._Common:set_Roughness(eyeshadowDetails._Roughness)
		elseif eyeshadowDetails._Common then
			if parseColors then
				eyeshadow:set_Color1(common.ParseColor(eyeshadowDetails._Common._Color1))
				eyeshadow:set_Color2(common.ParseColor(eyeshadowDetails._Common._Color2))
			else
				eyeshadow:set_Color1(eyeshadowDetails._Common._Color1)
				eyeshadow:set_Color2(eyeshadowDetails._Common._Color2)
			end
			eyeshadow:set_Thickness(eyeshadowDetails._Common._Thickness)
			eyeshadow:set_Opacity(eyeshadowDetails._Common._Opacity)
			eyeshadow:set_Metallic(eyeshadowDetails._Common._Metallic)
			eyeshadow:set_Roughness(eyeshadowDetails._Common._Roughness)
		else
			if parseColors then
				eyeshadow:set_Color1(common.ParseColor(eyeshadowDetails._Color1))
				eyeshadow:set_Color2(common.ParseColor(eyeshadowDetails._Color2))
			else
				eyeshadow:set_Color1(eyeshadowDetails._Color1)
				eyeshadow:set_Color2(eyeshadowDetails._Color2)
			end
			eyeshadow:set_Thickness(eyeshadowDetails._Thickness)
			eyeshadow:set_Opacity(eyeshadowDetails._Opacity)
			eyeshadow:set_Metallic(eyeshadowDetails._Metallic)
			eyeshadow:set_Roughness(eyeshadowDetails._Roughness)
		end
		EditEyeshadowBase(eyeshadow._Area1, eyeshadowDetails._Area1, ccItems)
		EditEyeshadowBase(eyeshadow._Area2, eyeshadowDetails._Area2, ccItems)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditCheek(cheek, cheekDetails, parseColors, ccItems)
	if cheek and cheekDetails then
		if parseColors then
			cheek:set_Color(common.ParseColor(cheekDetails._Color))
		else
			cheek:set_Color(cheekDetails._Color)
		end
		cheek:set_Spread(cheekDetails._Spread)
		cheek:set_Opacity(cheekDetails._Opacity)
		cheek:set_Metallic(cheekDetails._Metallic)
		cheek:set_Roughness(cheekDetails._Roughness)
		cheek:set_Thickness(cheekDetails._Thickness)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditLips(lips, lipsDetails, parseColors, ccItems)
	if lips and lipsDetails then
		if lips._Common and lipsDetails._Common then
			if parseColors then
				lips._Common:set_Color1(common.ParseColor(lipsDetails._Common._Color1))
			else
				lips._Common:set_Color1(lipsDetails._Common._Color1)
			end
			lips._Common:set_Spread(lipsDetails._Common._Spread)
			lips._Common:set_Opacity(lipsDetails._Common._Opacity)
			lips._Common:set_Metallic(lipsDetails._Common._Metallic)
			lips._Common:set_Roughness(lipsDetails._Common._Roughness)
		elseif lips._Common then
			if parseColors then
				lips._Common:set_Color1(common.ParseColor(lipsDetails._Color1))
			else
				lips._Common:set_Color1(lipsDetails._Color1)
			end
			lips._Common:set_Spread(lipsDetails._Spread)
			lips._Common:set_Opacity(lipsDetails._Opacity)
			lips._Common:set_Metallic(lipsDetails._Metallic)
			lips._Common:set_Roughness(lipsDetails._Roughness)
		elseif lipsDetails._Common then
			if parseColors then
				lips:set_Color1(common.ParseColor(lipsDetails._Common._Color1))
			else
				lips:set_Color1(lipsDetails._Common._Color1)
			end
			lips:set_Spread(lipsDetails._Common._Spread)
			lips:set_Opacity(lipsDetails._Common._Opacity)
			lips:set_Metallic(lipsDetails._Common._Metallic)
			lips:set_Roughness(lipsDetails._Common._Roughness)
		else
			if parseColors then
				lips:set_Color1(common.ParseColor(lipsDetails._Color1))
			else
				lips:set_Color1(lipsDetails._Color1)
			end
			lips:set_Spread(lipsDetails._Spread)
			lips:set_Opacity(lipsDetails._Opacity)
			lips:set_Metallic(lipsDetails._Metallic)
			lips:set_Roughness(lipsDetails._Roughness)
		end
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditFurFacePattern(furFacePattern, furFacePatternDetails, parseColors, ccItems)
	if furFacePattern and furFacePatternDetails then --furFacePattern:get_IsBeastman()
		if parseColors then
			furFacePattern:set_Color1(common.ParseColor(furFacePatternDetails._Color1))
			furFacePattern:set_Color2(common.ParseColor(furFacePatternDetails._Color2))
		else
			furFacePattern:set_Color1(furFacePatternDetails._Color1)
			furFacePattern:set_Color2(furFacePatternDetails._Color2)
		end
		furFacePattern:set_Color1_Override(furFacePatternDetails._Color1_Override)
		furFacePattern:set_Color2_Override(furFacePatternDetails._Color2_Override)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditFur(fur, furDetails, ccItems)
	if fur and furDetails then --fur:get_IsBeastman()
		fur:set_Opacity(furDetails._Opacity)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditEyeBase(eyeBase, eyeBaseDetails, eyeStyle, parseColors, ccItems)
	if eyeBase and eyeBaseDetails then
		if parseColors then
			eyeBase:set_IrisColor1(common.ParseColor(eyeBaseDetails._IrisColor1))
			eyeBase:set_IrisColor2(common.ParseColor(eyeBaseDetails._IrisColor2))
			eyeBase:set_IrisColor3(common.ParseColor(eyeBaseDetails._IrisColor3))
			eyeBase:set_IrisColor4(common.ParseColor(eyeBaseDetails._IrisColor4))
		else
			eyeBase:set_IrisColor1(eyeBaseDetails._IrisColor1)
			eyeBase:set_IrisColor2(eyeBaseDetails._IrisColor2)
			eyeBase:set_IrisColor3(eyeBaseDetails._IrisColor3)
			eyeBase:set_IrisColor4(eyeBaseDetails._IrisColor4)
		end
		if eyeBase.set_EyeStyle then
			if eyeStyle then
				eyeBase:set_EyeStyle(eyeStyle)
			else
				eyeBase:set_EyeStyle(eyeBaseDetails._EyeStyle)
			end
		end
		eyeBase:set_IrisSize(eyeBaseDetails._IrisSize)
		eyeBase:set_PupilShape(eyeBaseDetails._PupilShape)
		eyeBase:set_PupilSize(eyeBaseDetails._PupilSize)
		eyeBase:set_PupilWidth(eyeBaseDetails._PupilWidth)
		eyeBase:set_PupilHeight(eyeBaseDetails._PupilHeight)
	end
end

local function EditEyes(eyes, eyesDetails, partSwapperHumanCustomData, parseColors, ccItems)
	if eyes and eyesDetails then
		local leftEye
		local rightEye
		local leftEyeCopy
		local rightEyeCopy
		local leftEyeStyle
		local rightEyeStyle
		local commonEyeStyle
		if eyes._LeftEye then
			leftEye = eyes._LeftEye
		end
		if eyes._Left then
			leftEye = eyes._Left
		end
		if eyesDetails._Left then
			leftEyeCopy = eyesDetails._Left
		end
		if eyesDetails._LeftEye then
			leftEyeCopy = eyesDetails._LeftEye
		end
		if eyes._RightEye then
			rightEye = eyes._RightEye
		end
		if eyes._Right then
			rightEye = eyes._Right
		end
		if eyesDetails._Right then
			rightEyeCopy = eyesDetails._Right
		end
		if eyesDetails._RightEye then
			rightEyeCopy = eyesDetails._RightEye
		end
		if partSwapperHumanCustomData._Meta and partSwapperHumanCustomData._Meta._EyeLeftStyle then
			leftEyeStyle = partSwapperHumanCustomData._Meta._EyeLeftStyle
		elseif leftEye.set_EyeStyle then
			leftEyeStyle = leftEyeCopy._EyeStyle
		end
		if partSwapperHumanCustomData._Meta and partSwapperHumanCustomData._Meta._EyeRightStyle then
			rightEyeStyle = partSwapperHumanCustomData._Meta._EyeRightStyle
		elseif rightEye.set_EyeStyle then
			rightEyeStyle = rightEyeCopy._EyeStyle
		end
		if partSwapperHumanCustomData._Meta and partSwapperHumanCustomData._Meta._EyeStyle then
			commonEyeStyle = partSwapperHumanCustomData._Meta._EyeStyle
		else
			commonEyeStyle = eyesDetails._EyeStyle
		end
		--if not (leftEye and leftEyeCopy and leftEyeCopy._Enabled and rightEye and rightEyeCopy and rightEyeCopy._Enabled) then --(eyesDetails._Common and eyesDetails._Common._Enabled) or not eyesDetails._Common then
			if eyes.set_EyeStyle and commonEyeStyle then
				eyes:set_EyeStyle(commonEyeStyle)
			end
			if eyes._Common and eyesDetails._Common and (eyesDetails._Common._Enabled or (not leftEyeCopy._Enabled and not rightEyeCopy._Enabled)) then
				EditEyeBase(eyes._Common, eyesDetails._Common, commonEyeStyle, parseColors, ccItems)
			elseif eyes._Common then
				EditEyeBase(eyes._Common, eyesDetails, commonEyeStyle, parseColors, ccItems)
			elseif eyesDetails._Common and (eyesDetails._Common._Enabled or (not leftEyeCopy._Enabled and not rightEyeCopy._Enabled)) then
				EditEyeBase(eyes, eyesDetails._Common, commonEyeStyle, parseColors, ccItems)
			else
				EditEyeBase(eyes, eyesDetails, commonEyeStyle, parseColors, ccItems)
			end
		--end
		if leftEye and leftEyeCopy and leftEyeCopy._Enabled then
			if leftEye.set_EyeStyle then
				leftEye:set_EyeStyle(leftEyeStyle)
			end
			EditEyeBase(leftEye, leftEyeCopy, leftEyeStyle, parseColors, ccItems)
		end
		if rightEye and rightEyeCopy and rightEyeCopy._Enabled then
			if rightEye.set_EyeStyle then
				rightEye:set_EyeStyle(rightEyeStyle)
			end
			EditEyeBase(rightEye, rightEyeCopy, rightEyeStyle, parseColors, ccItems)
		end
		if eyes.set_HasEyeTypePropertyChanged and eyesDetails._HasEyeTypePropertyChanged ~= nil then
			eyes:set_HasEyeTypePropertyChanged(eyesDetails._HasEyeTypePropertyChanged)
		end
		eyes:set_LeftEyeState(eyesDetails._LeftEyeState)
		eyes:set_LeftEyeSquintRate(eyesDetails._LeftEyeSquintRate)
		eyes:set_RightEyeState(eyesDetails._RightEyeState)
		eyes:set_RightEyeSquintRate(eyesDetails._RightEyeSquintRate)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditEyelashBase(eyelashBase, eyelashBaseDetails, parseColors, ccItems)
	if eyelashBase and eyelashBaseDetails then
		if parseColors then
			eyelashBase:set_RootColor(common.ParseColor(eyelashBaseDetails._RootColor))
			eyelashBase:set_TipColor(common.ParseColor(eyelashBaseDetails._TipColor))
		else
			eyelashBase:set_RootColor(eyelashBaseDetails._RootColor)
			eyelashBase:set_TipColor(eyelashBaseDetails._TipColor)
		end
		eyelashBase:set_TipBlend(eyelashBaseDetails._TipBlend)
		eyelashBase:set_Metallic(eyelashBaseDetails._Metallic)
		eyelashBase:set_Roughness(eyelashBaseDetails._Roughness)
		eyelashBase:set_Length(eyelashBaseDetails._Length)
		eyelashBase:set_Density(eyelashBaseDetails._Density)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditEyelashes(eyelashes, eyelashesDetails, parseColors, ccItems)
	if eyelashes and eyelashesDetails then
		EditEyelashBase(eyelashes._Upper, eyelashesDetails._Upper, parseColors, ccItems)
		EditEyelashBase(eyelashes._Lower, eyelashesDetails._Lower, parseColors, ccItems)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditEyebrows(eyebrows, eyebrowsDetails, parseColors, ccItems)
	if eyebrows and eyebrowsDetails then
		if parseColors then
			eyebrows:set_Color(common.ParseColor(eyebrowsDetails._Color))
		else
			eyebrows:set_Color(eyebrowsDetails._Color)
		end
		eyebrows:set_Metallic(eyebrowsDetails._Metallic)
		eyebrows:set_Roughness(eyebrowsDetails._Roughness)
		eyebrows:set_Density(eyebrowsDetails._Density)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditTeeth(teeth, teethDetails, parseColors, ccItems)
	if teeth and teethDetails then
		if parseColors then
			teeth:set_Color(common.ParseColor(teethDetails._Color))
			teeth:set_DirtColor(common.ParseColor(teethDetails._DirtColor))
		else
			teeth:set_Color(teethDetails._Color)
			teeth:set_DirtColor(teethDetails._DirtColor)
		end
		teeth:set_TeethEnable(teethDetails._TeethEnable)
		teeth:set_Opacity(teethDetails._Opacity)
		teeth:set_DirtOpacity(teethDetails._DirtOpacity)
		teeth:set_DirtRange(teethDetails._DirtRange)
		teeth:set_DirtRoughness(teethDetails._DirtRoughness)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditFreckles(freckles, frecklesDetails, parseColors, ccItems)
	if freckles and frecklesDetails then
		if parseColors then
			freckles:set_Color(common.ParseColor(frecklesDetails._Color))
		else
			freckles:set_Color(frecklesDetails._Color)
		end
		freckles:set_Opacity(frecklesDetails._Opacity)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditNose(nose, noseDetails, parseColors, ccItems)
	if nose and noseDetails then
		if parseColors then
			nose:set_Color(common.ParseColor(noseDetails._Color))
			nose:set_Color2(common.ParseColor(noseDetails._Color2))
		else
			nose:set_Color(noseDetails._Color)
			nose:set_Color2(noseDetails._Color2)
		end
		nose:set_Opacity(noseDetails._Opacity)
		nose:set_Roughness(noseDetails._Roughness)
		nose:set_Opacity2(noseDetails._Opacity2)
		nose:set_Roughness2(noseDetails._Roughness2)
		nose:set_Thickness(noseDetails._Thickness)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditSkin(skin, skinDetails, parseColors, ccItems)
	if skin and skinDetails then
		if parseColors then
			skin:set_Color(common.ParseColor(skinDetails._Color))
		else
			skin:set_Color(skinDetails._Color)
		end
		skin:set_WrinkeStrength(skinDetails._WrinkeStrength)
		skin:set_MuscleStrength(skinDetails._MuscleStrength)
		skin:set_SkinColorCurve(skinDetails._SkinColorCurve)
		skin:set_SkinContrast(skinDetails._SkinContrast)
		skin:set_Roughness(skinDetails._Roughness)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditClaws(claws, clawsDetails, parseColors, ccItems)
	if claws and clawsDetails then
		if parseColors then
			claws:set_Color(common.ParseColor(clawsDetails._Color))
		else
			claws:set_Color(clawsDetails._Color)
		end
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditBodyHair(bodyHair, bodyHairDetails, parseColors, ccItems)
	if bodyHair and bodyHairDetails then
		if parseColors then
			bodyHair:set_Color(common.ParseColor(bodyHairDetails._Color))
		else
			bodyHair:set_Color(bodyHairDetails._Color)
		end
		bodyHair:set_Density(bodyHairDetails._Density)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditFurPattern(furPattern, furPatternDetails, parseColors, ccItems)
	if furPattern and furPatternDetails then --furPattern:get_IsBeastman()
		if parseColors then
			furPattern:set_Color1(common.ParseColor(furPatternDetails._Color1))
			furPattern:set_Color2(common.ParseColor(furPatternDetails._Color2))
			furPattern:set_Color3(common.ParseColor(furPatternDetails._Color3))
			furPattern:set_Color4(common.ParseColor(furPatternDetails._Color4))
		else
			furPattern:set_Color1(furPatternDetails._Color1)
			furPattern:set_Color2(furPatternDetails._Color2)
			furPattern:set_Color3(furPatternDetails._Color3)
			furPattern:set_Color4(furPatternDetails._Color4)
		end
		furPattern:set_Color1_Override(furPatternDetails._Color1_Override)
		furPattern:set_Color2_Override(furPatternDetails._Color2_Override)
		furPattern:set_Color3_Override(furPatternDetails._Color3_Override)
		furPattern:set_Color4_Override(furPatternDetails._Color4_Override)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditDirt(dirt, dirtDetails, parseColors, ccItems)
	if dirt and dirtDetails then
		if parseColors then
			dirt:set_Color1(common.ParseColor(dirtDetails._Color1))
			dirt:set_Color2(common.ParseColor(dirtDetails._Color2))
		else
			dirt:set_Color1(dirtDetails._Color1)
			dirt:set_Color2(dirtDetails._Color2)
		end
		dirt:set_DirtPattern(dirtDetails._DirtPattern)
		dirt:set_Coverage(dirtDetails._Coverage)
		if dirt._DirtRate and dirtDetails._DirtRate then
			dirt:set_DirtRate(dirtDetails._DirtRate)
		end
		dirt:set_Opacity(dirtDetails._Opacity)
		dirt:set_OpacityCurve(dirtDetails._OpacityCurve)
		dirt:set_ColorCurve(dirtDetails._ColorCurve)
		dirt:set_Thickness(dirtDetails._Thickness)
		dirt:set_Roughness(dirtDetails._Roughness)
		if dirt._OverwriteData and dirtDetails._OverwriteData then
			dirt:setOverwriteData(dirtDetails._OverwriteData)
		end
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditTattoo(tattoo, tattooDetails, parseColors, ccItems)
	if tattoo and tattooDetails then
		if parseColors then
			tattoo:set_Color1(common.ParseColor(tattooDetails._Color1))
			tattoo:set_Color2(common.ParseColor(tattooDetails._Color2))
			tattoo:set_Color3(common.ParseColor(tattooDetails._Color3))
		else
			tattoo:set_Color1(tattooDetails._Color1)
			tattoo:set_Color2(tattooDetails._Color2)
			tattoo:set_Color3(tattooDetails._Color3)
		end
		tattoo:set_HasPropertyChanged(tattooDetails["<HasPropertyChanged>k__BackingField"])
		tattoo:set_HasStyleChanged(tattooDetails["<HasStyleChanged>k__BackingField"])
		tattoo:set_Style(tattooDetails._Style)
		tattoo:set_Region(tattooDetails._Region)
		tattoo:set_Opacity(tattooDetails._Opacity)
		tattoo:set_HorizontalPosition(tattooDetails._HorizontalPosition)
		tattoo:set_VerticalPosition(tattooDetails._VerticalPosition)
		tattoo:set_Scale(tattooDetails._Scale)
		tattoo:set_HorizontalScale(tattooDetails._HorizontalScale)
		tattoo:set_VerticalScale(tattooDetails._VerticalScale)
		tattoo:set_Rotation(tattooDetails._Rotation)
		tattoo:set_HorizontalTiling(tattooDetails._HorizontalTiling)
		tattoo:set_VerticalTiling(tattooDetails._VerticalTiling)
		tattoo:set_Thickness(tattooDetails._Thickness)
		tattoo:set_Metallic(tattooDetails._Metallic)
		tattoo:set_Roughness(tattooDetails._Roughness)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditTattoos(tattoos, tattoosDetails, slotDatasName, parseColors, ccItems)
	if tattoos and tattoosDetails then
		if tattoos._Tattoos then
			while tattoos._Tattoos[0] do
				tattoos:removeSlotData(0)
			end
		end
		local slotIndex = {}
		if tattoosDetails[slotDatasName] then
			for i, newTattoo in pairs(tattoosDetails[slotDatasName]) do
				slotIndex[i] = tattoos:addSlotData(newTattoo._Region)
				tattoos:set_StartSlotNo(slotIndex[i])
				if slotIndex[i] > -1 then
					if tattoos._Tattoos then
						EditTattoo(tattoos._Tattoos[slotIndex[i]], newTattoo, parseColors, ccItems)
					end
					if tattoos._SlotDatas then
						EditTattoo(tattoos._SlotDatas[slotIndex[i]], newTattoo, parseColors, ccItems)
					end
				end
			end
		end
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditScar(scar, scarDetails, ccItems)
	if scar and scarDetails then
		scar:set_HasPropertyChanged(scarDetails["<HasPropertyChanged>k__BackingField"])
		scar:set_HasStyleChanged(scarDetails["<HasStyleChanged>k__BackingField"])
		scar:set_Style(scarDetails._Style)
		scar:set_Region(scarDetails._Region)
		scar:set_Opacity(scarDetails._Opacity)
		scar:set_HorizontalPosition(scarDetails._HorizontalPosition)
		scar:set_VerticalPosition(scarDetails._VerticalPosition)
		scar:set_Scale(scarDetails._Scale)
		scar:set_HorizontalScale(scarDetails._HorizontalScale)
		scar:set_VerticalScale(scarDetails._VerticalScale)
		scar:set_Rotation(scarDetails._Rotation)
		scar:set_HorizontalTiling(scarDetails._HorizontalTiling)
		scar:set_VerticalTiling(scarDetails._VerticalTiling)
		scar:set_Thickness(scarDetails._Thickness)
		scar:set_Roughness(scarDetails._Roughness)
		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditScars(scars, scarsDetails, slotDatasName, ccItems)
	if scars and scarsDetails then
		if scars._Scars then
			while scars._Scars[0] do
				scars:removeSlotData(0)
			end
		end
		local slotIndex = {}
		if scarsDetails[slotDatasName] then
			for i, newScar in pairs(scarsDetails[slotDatasName]) do
				slotIndex[i] = scars:addSlotData(newScar._Region)
				scars:set_StartSlotNo(slotIndex[i])
				if slotIndex[i] > -1 then
					if scars._Scars then
						EditScar(scars._Scars[slotIndex[i]], newScar, ccItems)
					end
					if scars._SlotDatas then
						EditScar(scars._SlotDatas[slotIndex[i]], newScar, ccItems)
					end
				end
			end
		end

		ApplyBodyDetailEdits(ccItems)
	end
end

local function EditPretender(pretender, pretenderDetails, ccItems)
	if pretender and pretenderDetails then
		pretender:set_Age(pretenderDetails._Age)
		pretender:set_SexUpperBody(pretenderDetails._SexUpperBody)
		pretender:set_SexLowerBody(pretenderDetails._SexLowerBody)
		pretender:set_SpineBend(pretenderDetails._SpineBend)
	end
end

local function CrashFix(fc, et, ch)
	fc = common.ChangeToDefaultIfNil(fc, 0)
	if GetFinalEPCode(epCode) and ((fc == 1 and GetAECode(ch)) or fc == 2) then
		if et == 14 then
			return 14
		else
			return 15
		end
	end
	return et
end

local function GetBaseCharacterCustomizationItems(ccItems, additionalParameters, character, partSwapper)
	local GuiManager = sdk.get_managed_singleton("app.GuiManager")
	ccItems.GUICharaEditCtrl = GuiManager._CharaEditCtrl
	if ccItems.GUICharaEditCtrl then
		ccItems.GUIPreviewModelEditor = ccItems.GUICharaEditCtrl["<ModelEditor>k__BackingField"]
		ccItems.GUICharaEditCtrl:set_IsEditLimited(false)
	end
	if ccItems.GUIPreviewModelEditor then
		ccItems.PreviewModelObj = ccItems.GUIPreviewModelEditor["<PreviewModelObj>k__BackingField"]
	end
	if (additionalParameters and additionalParameters.cloneOrMockupBuilder) then
		ccItems.PartSwapper = additionalParameters.cloneOrMockupBuilder:get_PartSwapper()
	elseif character then
		ccItems.PartSwapper = character["<HumanPartSwapper>k__BackingField"]
	else
		if partSwapper then
			ccItems.PartSwapper = partSwapper
		elseif ccItems.PreviewModelObj then
			ccItems.PartSwapper = ccItems.PreviewModelObj:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
			ccItems.FaceEditor = nil --ccItems.PartSwapper._FaceEditor
			ccItems.BodyEditor = ccItems.PreviewModelObj:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
			ccItems.Transform = ccItems.PreviewModelObj:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
		end
	end
	if ccItems.PartSwapper then
		if not ccItems.FaceEditor then
			ccItems.FaceEditor = nil --ccItems.PartSwapper._FaceEditor
		end
		if not ccItems.BodyEditor then
			ccItems.BodyEditor = ccItems.PartSwapper._BodyEditor
		end
	end
	if ccItems.BodyEditor then
		if not ccItems.BodyEditorObject then
			ccItems.BodyEditorObject = ccItems.BodyEditor:get_GameObject()
		end
		ccItems.BodyEditorRoot = ccItems.BodyEditor:get_BaseBodyEditor()
		if ccItems.BodyEditorRoot then
			ccItems.PartSwapperRoot = ccItems.BodyEditorRoot["<BasePartSwapper>k__BackingField"]
		end
	end
	if not ccItems.Transform and character then
		ccItems.Transform = character["<Transform>k__BackingField"]
	end
	if not ccItems.Transform and ccItems.BodyEditorObject then
		ccItems.Transform = ccItems.BodyEditorObject:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
	end
	if ccItems.PartSwapper then
		ccItems.BodyDetailEditor = ccItems.PartSwapper:get_BodyDetailEditor() --ccItems.PreviewModelObj:call("getComponent(System.Type)", sdk.typeof("app.BodyDetailEditor"))
		if not ccItems.BodyDetailEditor then
			ccItems.BodyDetailEditor = ccItems.PartSwapper._BodyDetailEditor
		end
	end
	if not ccItems.FaceEditor and ccItems.Transform then
		local transformHead = ccItems.Transform:find("head")
		if transformHead then
			ccItems.HeadObject = transformHead:get_GameObject()
			if ccItems.HeadObject then
				ccItems.FaceEditor = ccItems.HeadObject:call("getComponent(System.Type)", sdk.typeof("app.FaceEditor"))
			end
		end
	end
	if additionalParameters then
		ccItems.config = additionalParameters.config
		ccItems.EditContexts = common.GetBooleanValue(additionalParameters.editContexts)
		ccItems.SaveContext = common.GetBooleanValue(additionalParameters.saveContext)
		ccItems.ApplyWorkarounds = common.GetBooleanValue(additionalParameters.applyWorkarounds)
	else
		ccItems.EditContexts = false
		ccItems.SaveContext = false
		ccItems.ApplyWorkarounds = false
	end
	if additionalParameters.skipRequestSwap ~= nil then
		ccItems.SkipRequestSwap = additionalParameters.skipRequestSwap
	end
end

local function GetCharacterCustomizationItemsFromPartSwapper(partSwapper, additionalParameters)
	local ccItems = {}
	ccItems.Character = nil
	ccItems.LocationType = "Anywhere"
	GetBaseCharacterCustomizationItems(ccItems, additionalParameters, nil, partSwapper)
	return ccItems
end

local function GetCharacterCustomizationItemsCCS(additionalParameters)
	local ccItems = {}
	ccItems.Character = nil
	ccItems.LocationType = "CharacterCustomizationScreen"
	GetBaseCharacterCustomizationItems(ccItems, additionalParameters, nil, nil)
	return ccItems
end

local function GetCharacterCustomizationItems(character, additionalParameters)
	local ccItems = {}
	ccItems.Character = character
	ccItems.LocationType = "Anywhere"
	GetBaseCharacterCustomizationItems(ccItems, additionalParameters, character, nil)
	return ccItems
end

local function GetCharacterSkinColor(character)
	local additionalParameters = {}
	additionalParameters.config = config
	additionalParameters.editContexts = false
	additionalParameters.saveContext = false
	additionalParameters.applyWorkarounds = false
	additionalParameters.skipRequestSwap = false
	local ccItems = GetCharacterCustomizationItemsFromPartSwapper(character["<HumanPartSwapper>k__BackingField"], additionalParameters)
	if ccItems.BodyDetailEditor then
		return ccItems.BodyDetailEditor._Skin._Color
	end
	return nil
end

local lastEditedBodyDetailData
local function GetLastEditedBodyDetailData()
	return lastEditedBodyDetailData
end

local function EditCharacterBodyDetailsUsingCustomData(ccItems, bodyDetailCustomData, partSwapperHumanCustomData, editType)
	if ccItems.BodyDetailData == nil then
		StartBodyDetailEdits(ccItems)
		ccItems.BodyDetailData = ccItems.BodyDetailEditor
	end
	if ccItems.BodyDetailData then
		local bodyDetailContext
		if ccItems.EditContexts and ccItems.BodyDetailData._Context then
			bodyDetailContext = ccItems.BodyDetailData._Context
		end
		if bodyDetailCustomData and (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BODYANDBODYDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BODYDETAILS
			or editType == ENUMS.CHARACTEREDITTYPE.HEAD or editType == ENUMS.CHARACTEREDITTYPE.HAIRDETAILS or editType == ENUMS.CHARACTEREDITTYPE.FACE
			or editType == ENUMS.CHARACTEREDITTYPE.BEARD or editType == ENUMS.CHARACTEREDITTYPE.MAKEUP) then
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.HAIRDETAILS) then
				if bodyDetailCustomData._Hair then
					if ccItems.BodyDetailData._Hair then
						EditHair(ccItems.BodyDetailData._Hair, bodyDetailCustomData._Hair, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Hair:call("copyFrom(app.charaedit.ch000.Hair)", ccItems.BodyDetailData._Hair)
						end
					elseif ccItems.BodyDetailData["<Hair>k__BackingField"] then
						EditHair(ccItems.BodyDetailData["<Hair>k__BackingField"], bodyDetailCustomData._Hair, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Hair:call("copyFrom(app.charaedit.ch000.Hair)", ccItems.BodyDetailData["<Hair>k__BackingField"])
						end
					end
				end
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BEARD) then
				if bodyDetailCustomData._Beard then
					if ccItems.BodyDetailData._Beard then
						EditHair(ccItems.BodyDetailData._Beard, bodyDetailCustomData._Beard, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Beard:call("copyFrom(app.charaedit.ch000.Beard)", ccItems.BodyDetailData._Beard)
						end
					elseif ccItems.BodyDetailData["<Beard>k__BackingField"] then
						EditHair(ccItems.BodyDetailData["<Beard>k__BackingField"], bodyDetailCustomData._Beard, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Beard:call("copyFrom(app.charaedit.ch000.Beard)", ccItems.BodyDetailData["<Beard>k__BackingField"])
						end
					end
				end
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.MAKEUP) then
				local sourceMakeup
				if bodyDetailCustomData._Makeup then
					sourceMakeup = {}
					sourceMakeup._Eyeliner = bodyDetailCustomData._Makeup._Eyeliner
					sourceMakeup._Eyeshadow = bodyDetailCustomData._Makeup._Eyeshadow
					sourceMakeup._Cheek = bodyDetailCustomData._Makeup._Cheek
					sourceMakeup._Lips = bodyDetailCustomData._Makeup._Lips
				else
					sourceMakeup = {}
					sourceMakeup._Eyeliner = bodyDetailCustomData._Eyeliner
					sourceMakeup._Eyeshadow = bodyDetailCustomData._Eyeshadow
					sourceMakeup._Cheek = bodyDetailCustomData._Cheek
					sourceMakeup._Lips = bodyDetailCustomData._Lips
				end
				local destinationMakeup
				if sourceMakeup then
					if ccItems.BodyDetailData._Makeup then
						destinationMakeup = {}
						EditEyeliner(ccItems.BodyDetailData._Makeup._Eyeliner, sourceMakeup._Eyeliner, ccItems.ParseColors, ccItems)
						destinationMakeup._Eyeliner = ccItems.BodyDetailData._Makeup._Eyeliner
						EditEyeshadow(ccItems.BodyDetailData._Makeup._Eyeshadow, sourceMakeup._Eyeshadow, ccItems.ParseColors, ccItems)
						destinationMakeup._Eyeshadow = ccItems.BodyDetailData._Makeup._Eyeshadow
						EditCheek(ccItems.BodyDetailData._Makeup._Cheek, sourceMakeup._Cheek, ccItems.ParseColors, ccItems)
						destinationMakeup._Cheek = ccItems.BodyDetailData._Makeup._Cheek
						EditLips(ccItems.BodyDetailData._Makeup._Lips, sourceMakeup._Lips, ccItems.ParseColors, ccItems)
						destinationMakeup._Lips = ccItems.BodyDetailData._Makeup._Lips
					elseif ccItems.BodyDetailData["<Makeup>k__BackingField"] then
						destinationMakeup = {}
						EditEyeliner(ccItems.BodyDetailData["<Makeup>k__BackingField"]._Eyeliner, sourceMakeup._Eyeliner, ccItems.ParseColors, ccItems)
						destinationMakeup._Eyeliner = ccItems.BodyDetailData["<Makeup>k__BackingField"]._Eyeliner
						EditEyeshadow(ccItems.BodyDetailData["<Makeup>k__BackingField"]._Eyeshadow, sourceMakeup._Eyeshadow, ccItems.ParseColors, ccItems)
						destinationMakeup._Eyeshadow = ccItems.BodyDetailData["<Makeup>k__BackingField"]._Eyeshadow
						EditCheek(ccItems.BodyDetailData["<Makeup>k__BackingField"]._Cheek, sourceMakeup._Cheek, ccItems.ParseColors, ccItems)
						destinationMakeup._Cheek = ccItems.BodyDetailData["<Makeup>k__BackingField"]._Cheek
						EditLips(ccItems.BodyDetailData["<Makeup>k__BackingField"]._Lips, sourceMakeup._Lips, ccItems.ParseColors, ccItems)
						destinationMakeup._Lips = ccItems.BodyDetailData["<Makeup>k__BackingField"]._Lips
					else
						destinationMakeup = {}
						if ccItems.BodyDetailData._Eyeliner then
							EditEyeliner(ccItems.BodyDetailData._Eyeliner, sourceMakeup._Eyeliner, ccItems.ParseColors, ccItems)
							destinationMakeup._Eyeliner = ccItems.BodyDetailData._Eyeliner
						end
						if ccItems.BodyDetailData._Eyeshadow then
							EditEyeshadow(ccItems.BodyDetailData._Eyeshadow, sourceMakeup._Eyeshadow, ccItems.ParseColors, ccItems)
							destinationMakeup._Eyeshadow = ccItems.BodyDetailData._Eyeshadow
						end
						if ccItems.BodyDetailData._Cheek then
							EditCheek(ccItems.BodyDetailData._Cheek, sourceMakeup._Cheek, ccItems.ParseColors, ccItems)
							destinationMakeup._Cheek = ccItems.BodyDetailData._Cheek
						end
						if ccItems.BodyDetailData._Lips then
							EditLips(ccItems.BodyDetailData._Lips, sourceMakeup._Lips, ccItems.ParseColors, ccItems)
							destinationMakeup._Lips = ccItems.BodyDetailData._Lips
						end
					end
					if destinationMakeup then
						if ccItems.EditContexts and bodyDetailContext then
							if destinationMakeup._Eyeliner then
								bodyDetailContext._Eyeliner:call("copyFrom(app.charaedit.ch000.Eyeliner)", destinationMakeup._Eyeliner)
							end
							if destinationMakeup._Eyeshadow then
								bodyDetailContext._Eyeshadow:call("copyFrom(app.charaedit.ch000.Eyeshadow)", destinationMakeup._Eyeshadow)
							end
							if destinationMakeup._Cheek then
								bodyDetailContext._Cheek:call("copyFrom(app.charaedit.ch000.Cheek)", destinationMakeup._Cheek)
							end
							if destinationMakeup._Lips then
								bodyDetailContext._Lips:call("copyFrom(app.charaedit.ch000.Lips)", destinationMakeup._Lips)
							end
						end
					end
				end
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.FACE) then
				if bodyDetailCustomData._FurFacePattern then
					if ccItems.BodyDetailData._FurFacePattern then
						EditFurFacePattern(ccItems.BodyDetailData._FurFacePattern, bodyDetailCustomData._FurFacePattern, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurFacePattern:call("copyFrom(app.charaedit.ch000.FurFacePattern)", ccItems.BodyDetailData._FurFacePattern)
						end
					elseif ccItems.BodyDetailData["<FurFacePattern>k__BackingField"] then
						EditFurFacePattern(ccItems.BodyDetailData["<FurFacePattern>k__BackingField"], bodyDetailCustomData._FurFacePattern, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurFacePattern:call("copyFrom(app.charaedit.ch000.FurFacePattern)", ccItems.BodyDetailData["<FurFacePattern>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._FurFaceMask then
					if ccItems.BodyDetailData._FurFaceMask then
						EditFur(ccItems.BodyDetailData._FurFaceMask, bodyDetailCustomData._FurFaceMask, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurFaceMask:call("copyFrom(app.charaedit.ch000.FurFaceMask)", ccItems.BodyDetailData._FurFaceMask)
						end
					elseif ccItems.BodyDetailData["<FurFaceMask>k__BackingField"] then
						EditFur(ccItems.BodyDetailData["<FurFaceMask>k__BackingField"], bodyDetailCustomData._FurFaceMask, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurFaceMask:call("copyFrom(app.charaedit.ch000.FurFaceMask)", ccItems.BodyDetailData["<FurFaceMask>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._FurForehead then
					if ccItems.BodyDetailData._FurForehead then
						EditFur(ccItems.BodyDetailData._FurForehead, bodyDetailCustomData._FurForehead, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurForehead:call("copyFrom(app.charaedit.ch000.FurForehead)", ccItems.BodyDetailData._FurForehead)
						end
					elseif ccItems.BodyDetailData["<FurForehead>k__BackingField"] then
						EditFur(ccItems.BodyDetailData["<FurForehead>k__BackingField"], bodyDetailCustomData._FurForehead, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurForehead:call("copyFrom(app.charaedit.ch000.FurForehead)", ccItems.BodyDetailData["<FurForehead>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._FurEyes then
					if ccItems.BodyDetailData._FurEyes then
						EditFur(ccItems.BodyDetailData._FurEyes, bodyDetailCustomData._FurEyes, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurEyes:call("copyFrom(app.charaedit.ch000.FurEyes)", ccItems.BodyDetailData._FurEyes)
						end
					elseif ccItems.BodyDetailData["<FurEyes>k__BackingField"] then
						EditFur(ccItems.BodyDetailData["<FurEyes>k__BackingField"], bodyDetailCustomData._FurEyes, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurEyes:call("copyFrom(app.charaedit.ch000.FurEyes)", ccItems.BodyDetailData["<FurEyes>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._FurCheeks then
					if ccItems.BodyDetailData._FurCheeks then
						EditFur(ccItems.BodyDetailData._FurCheeks, bodyDetailCustomData._FurCheeks, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurCheeks:call("copyFrom(app.charaedit.ch000.FurCheeks)", ccItems.BodyDetailData._FurCheeks)
						end
					elseif ccItems.BodyDetailData["<FurCheeks>k__BackingField"] then
						EditFur(ccItems.BodyDetailData["<FurCheeks>k__BackingField"], bodyDetailCustomData._FurCheeks, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurCheeks:call("copyFrom(app.charaedit.ch000.FurCheeks)", ccItems.BodyDetailData["<FurCheeks>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._FurNose then
					if ccItems.BodyDetailData._FurNose then
						EditFur(ccItems.BodyDetailData._FurNose, bodyDetailCustomData._FurNose, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurNose:call("copyFrom(app.charaedit.ch000.FurNose)", ccItems.BodyDetailData._FurNose)
						end
					elseif ccItems.BodyDetailData["<FurNose>k__BackingField"] then
						EditFur(ccItems.BodyDetailData["<FurNose>k__BackingField"], bodyDetailCustomData._FurNose, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurNose:call("copyFrom(app.charaedit.ch000.FurNose)", ccItems.BodyDetailData["<FurNose>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._Eyes then
					local leftEyeCopy
					if bodyDetailCustomData._Eyes._Left then
						leftEyeCopy = bodyDetailCustomData._Eyes._Left
					end
					if bodyDetailCustomData._Eyes._LeftEye then
						leftEyeCopy = bodyDetailCustomData._Eyes._LeftEye
					end
					local rightEyeCopy
					if bodyDetailCustomData._Eyes._Right then
						rightEyeCopy = bodyDetailCustomData._Eyes._Right
					end
					if bodyDetailCustomData._Eyes._RightEye then
						rightEyeCopy = bodyDetailCustomData._Eyes._RightEye
					end
					if ccItems.BodyDetailData._Eyes then
						EditEyes(ccItems.BodyDetailData._Eyes, bodyDetailCustomData._Eyes, partSwapperHumanCustomData, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Eyes:call("copyFrom(app.charaedit.ch000.Eyes)", ccItems.BodyDetailData._Eyes)
							bodyDetailContext._Eyes._Left:set_Enabled(leftEyeCopy._Enabled)
							bodyDetailContext._Eyes._Right:set_Enabled(rightEyeCopy._Enabled)
							if bodyDetailCustomData._Eyes._Common then
								bodyDetailContext._Eyes._Common:set_Enabled(bodyDetailCustomData._Eyes._Common._Enabled)
							end
						end
					elseif ccItems.BodyDetailData["<Eyes>k__BackingField"] then
						EditEyes(ccItems.BodyDetailData["<Eyes>k__BackingField"], bodyDetailCustomData._Eyes, partSwapperHumanCustomData, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Eyes:call("copyFrom(app.charaedit.ch000.Eyes)", ccItems.BodyDetailData["<Eyes>k__BackingField"])
							bodyDetailContext._Eyes._Left:set_Enabled(leftEyeCopy._Enabled)
							bodyDetailContext._Eyes._Right:set_Enabled(rightEyeCopy._Enabled)
							if bodyDetailCustomData._Eyes._Common then
								bodyDetailContext._Eyes._Common:set_Enabled(bodyDetailCustomData._Eyes._Common._Enabled)
							end
						end
					end
				end
				if bodyDetailCustomData._Eyelashes then
					if ccItems.BodyDetailData._Eyelashes then
						--EditEyelashes(ccItems.BodyDetailData._Eyelashes, bodyDetailCustomData._Eyelashes, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							--bodyDetailContext._Eyelashes:call("copyFrom(app.charaedit.ch000.Eyelashes)", ccItems.BodyDetailData._Eyelashes)
							EditEyelashes(bodyDetailContext._Eyelashes, bodyDetailCustomData._Eyelashes, ccItems.ParseColors, ccItems)
							bodyDetailContext._Eyelashes._Upper:set_Enabled(true) --bodyDetailCustomData._Eyelashes._Upper._Enabled)
							bodyDetailContext._Eyelashes._Lower:set_Enabled(true) --bodyDetailCustomData._Eyelashes._Lower._Enabled)
							--if bodyDetailCustomData._Eyelashes._Base then
								bodyDetailContext._Eyelashes._Base:set_Enabled(true) --bodyDetailCustomData._Eyelashes._Base._Enabled)
							--end
							ccItems.BodyDetailData._Eyelashes:call("restore(app.BodyDetailContext.EyelashesContext)", bodyDetailContext._Eyelashes)
						else
							EditEyelashes(ccItems.BodyDetailData._Eyelashes, bodyDetailCustomData._Eyelashes, ccItems.ParseColors, ccItems)
						end
					elseif ccItems.BodyDetailData["<Eyelashes>k__BackingField"] then
						--EditEyelashes(ccItems.BodyDetailData["<Eyelashes>k__BackingField"], bodyDetailCustomData._Eyelashes, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							--bodyDetailContext._Eyelashes:call("copyFrom(app.charaedit.ch000.Eyelashes)", ccItems.BodyDetailData["<Eyelashes>k__BackingField"])
							EditEyelashes(bodyDetailContext._Eyelashes, bodyDetailCustomData._Eyelashes, ccItems.ParseColors, ccItems)
							bodyDetailContext._Eyelashes._Upper:set_Enabled(true) --bodyDetailCustomData._Eyelashes._Upper._Enabled)
							bodyDetailContext._Eyelashes._Lower:set_Enabled(true) --bodyDetailCustomData._Eyelashes._Lower._Enabled)
							--if bodyDetailCustomData._Eyelashes._Base then
								bodyDetailContext._Eyelashes._Base:set_Enabled(true) --bodyDetailCustomData._Eyelashes._Base._Enabled)
							--end
							ccItems.BodyDetailData["<Eyelashes>k__BackingField"]:call("restore(app.BodyDetailContext.EyelashesContext)", bodyDetailContext._Eyelashes)
						else
							EditEyelashes(ccItems.BodyDetailData["<Eyelashes>k__BackingField"], bodyDetailCustomData._Eyelashes, ccItems.ParseColors, ccItems)
						end
					end
				end
				if bodyDetailCustomData._Eyebrows then
					if ccItems.BodyDetailData._Eyebrows then
						EditEyebrows(ccItems.BodyDetailData._Eyebrows, bodyDetailCustomData._Eyebrows, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Eyebrows:call("copyFrom(app.charaedit.ch000.Eyebrows)", ccItems.BodyDetailData._Eyebrows)
						end
					elseif ccItems.BodyDetailData["<Eyebrows>k__BackingField"] then
						EditEyebrows(ccItems.BodyDetailData["<Eyebrows>k__BackingField"], bodyDetailCustomData._Eyebrows, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Eyebrows:call("copyFrom(app.charaedit.ch000.Eyebrows)", ccItems.BodyDetailData["<Eyebrows>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._Teeth then
					if ccItems.BodyDetailData._Teeth then
						EditTeeth(ccItems.BodyDetailData._Teeth, bodyDetailCustomData._Teeth, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Teeth:call("copyFrom(app.charaedit.ch000.Teeth)", ccItems.BodyDetailData._Teeth)
						end
					elseif ccItems.BodyDetailData["<Teeth>k__BackingField"] then
						EditTeeth(ccItems.BodyDetailData["<Teeth>k__BackingField"], bodyDetailCustomData._Teeth, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Teeth:call("copyFrom(app.charaedit.ch000.Teeth)", ccItems.BodyDetailData["<Teeth>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._Freckles then
					if ccItems.BodyDetailData._Freckles then
						EditFreckles(ccItems.BodyDetailData._Freckles, bodyDetailCustomData._Freckles, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Freckles:call("copyFrom(app.charaedit.ch000.Freckles)", ccItems.BodyDetailData._Freckles)
						end
					elseif ccItems.BodyDetailData["<Freckles>k__BackingField"] then
						EditFreckles(ccItems.BodyDetailData["<Freckles>k__BackingField"], bodyDetailCustomData._Freckles, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Freckles:call("copyFrom(app.charaedit.ch000.Freckles)", ccItems.BodyDetailData["<Freckles>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._Nose then
					if ccItems.BodyDetailData._Nose then
						EditNose(ccItems.BodyDetailData._Nose, bodyDetailCustomData._Nose, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Nose:call("copyFrom(app.charaedit.ch000.Nose)", ccItems.BodyDetailData._Nose)
						end
					elseif ccItems.BodyDetailData["<Nose>k__BackingField"] then
						EditNose(ccItems.BodyDetailData["<Nose>k__BackingField"], bodyDetailCustomData._Nose, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Nose:call("copyFrom(app.charaedit.ch000.Nose)", ccItems.BodyDetailData["<Nose>k__BackingField"])
						end
					end
				end
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.BODYANDBODYDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BODYDETAILS) then
				if bodyDetailCustomData._Skin then
					if ccItems.BodyDetailData._Skin then
						EditSkin(ccItems.BodyDetailData._Skin, bodyDetailCustomData._Skin, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Skin:call("copyFrom(app.charaedit.ch000.Skin)", ccItems.BodyDetailData._Skin)
						end
					elseif ccItems.BodyDetailData["<Skin>k__BackingField"] then
						EditSkin(ccItems.BodyDetailData["<Skin>k__BackingField"], bodyDetailCustomData._Skin, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Skin:call("copyFrom(app.charaedit.ch000.Skin)", ccItems.BodyDetailData["<Skin>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._Claws then
					if ccItems.BodyDetailData._Claws then
						EditClaws(ccItems.BodyDetailData._Claws, bodyDetailCustomData._Claws, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Claws:call("copyFrom(app.charaedit.ch000.Claws)", ccItems.BodyDetailData._Claws)
						end
					elseif ccItems.BodyDetailData["<Claws>k__BackingField"] then
						EditClaws(ccItems.BodyDetailData["<Claws>k__BackingField"], bodyDetailCustomData._Claws, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Claws:call("copyFrom(app.charaedit.ch000.Claws)", ccItems.BodyDetailData["<Claws>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._BodyHair then
					if ccItems.BodyDetailData._BodyHair then
						EditBodyHair(ccItems.BodyDetailData._BodyHair, bodyDetailCustomData._BodyHair, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._BodyHair:call("copyFrom(app.charaedit.ch000.BodyHair)", ccItems.BodyDetailData._BodyHair)
						end
					elseif ccItems.BodyDetailData["<BodyHair>k__BackingField"] then
						EditBodyHair(ccItems.BodyDetailData["<BodyHair>k__BackingField"], bodyDetailCustomData._BodyHair, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._BodyHair:call("copyFrom(app.charaedit.ch000.BodyHair)", ccItems.BodyDetailData["<BodyHair>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData[ccItems.FurPatternBodyDetailName] then
					if ccItems.BodyDetailData._FurPattern then
						EditFurPattern(ccItems.BodyDetailData._FurPattern, bodyDetailCustomData[ccItems.FurPatternBodyDetailName], ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurPattern:call("copyFrom(app.charaedit.ch000.FurPatterns)", ccItems.BodyDetailData._FurPattern)
						end
					elseif ccItems.BodyDetailData["<FurPattern>k__BackingField"] then
						EditFurPattern(ccItems.BodyDetailData["<FurPattern>k__BackingField"], bodyDetailCustomData[ccItems.FurPatternBodyDetailName], ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurPattern:call("copyFrom(app.charaedit.ch000.FurPatterns)", ccItems.BodyDetailData["<FurPattern>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._Dirt then
					if ccItems.BodyDetailData._Dirt then
						EditDirt(ccItems.BodyDetailData._Dirt,  bodyDetailCustomData._Dirt, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Dirt:call("copyFrom(app.charaedit.ch000.Dirt)", ccItems.BodyDetailData._Dirt)
						end
					elseif ccItems.BodyDetailData["<Dirt>k__BackingField"] then
						EditDirt(ccItems.BodyDetailData["<Dirt>k__BackingField"],  bodyDetailCustomData._Dirt, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Dirt:call("copyFrom(app.charaedit.ch000.Dirt)", ccItems.BodyDetailData["<Dirt>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._Tattoos then
					if ccItems.BodyDetailData._Tattoos then
						EditTattoos(ccItems.BodyDetailData._Tattoos, bodyDetailCustomData._Tattoos, ccItems.TattoosSlotDatasName, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Tattoos:call("copyFrom(app.charaedit.ch000.Tattoos)", ccItems.BodyDetailData._Tattoos)
						end
					elseif ccItems.BodyDetailData["<Tattoos>k__BackingField"] then
						EditTattoos(ccItems.BodyDetailData["<Tattoos>k__BackingField"], bodyDetailCustomData._Tattoos, ccItems.TattoosSlotDatasName, ccItems.ParseColors, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Tattoos:call("copyFrom(app.charaedit.ch000.Tattoos)", ccItems.BodyDetailData["<Tattoos>k__BackingField"])
						end
					end
				end
				if bodyDetailCustomData._Scars then
					if ccItems.BodyDetailData._Scars then
						EditScars(ccItems.BodyDetailData._Scars, bodyDetailCustomData._Scars, ccItems.ScarsSlotDatasName, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Scars:call("copyFrom(app.charaedit.ch000.Scars)", ccItems.BodyDetailData._Scars)
						end
					elseif ccItems.BodyDetailData["<Scars>k__BackingField"] then
						EditScars(ccItems.BodyDetailData["<Scars>k__BackingField"], bodyDetailCustomData._Scars, ccItems.ScarsSlotDatasName, ccItems)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Scars:call("copyFrom(app.charaedit.ch000.Scars)", ccItems.BodyDetailData["<Scars>k__BackingField"])
						end
					end
				end
			end
		end
		lastEditedBodyDetailData = ccItems.BodyDetailData
		EndBodyDetailEdits(ccItems)
		return true
	end
	return false
end

--USED IN CLONER
local function EditCharacterBodyDetailsUsingAppearanceData(ccItems, appearanceData, editType)
	local isCompletelyEdited = true
	if ccItems.BodyDetailData == nil then
		StartBodyDetailEdits(ccItems)
		ccItems.BodyDetailData = ccItems.BodyDetailEditor
	end
	if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BODYANDBODYDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BODYDETAILS
		or editType == ENUMS.CHARACTEREDITTYPE.HEAD or editType == ENUMS.CHARACTEREDITTYPE.HAIRDETAILS or editType == ENUMS.CHARACTEREDITTYPE.FACE
		or editType == ENUMS.CHARACTEREDITTYPE.BEARD or editType == ENUMS.CHARACTEREDITTYPE.MAKEUP) then
		if ccItems.BodyDetailData and appearanceData then
			local bodyDetailContext
			if ccItems.EditContexts and ccItems.BodyDetailData._Context then
				bodyDetailContext = ccItems.BodyDetailData._Context
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.HAIRDETAILS) then
				if appearanceData._Hair then
					if ccItems.BodyDetailData._Hair then
						ccItems.BodyDetailData._Hair:call("copyFrom(app.charaedit.ch000.HairData)", appearanceData._Hair)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Hair:call("copyFrom(app.charaedit.ch000.Hair)", ccItems.BodyDetailData._Hair)
						end
					elseif ccItems.BodyDetailData["<Hair>k__BackingField"] then
						ccItems.BodyDetailData["<Hair>k__BackingField"]:call("copyFrom(app.charaedit.ch000.HairData)", appearanceData._Hair)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Hair:call("copyFrom(app.charaedit.ch000.Hair)", ccItems.BodyDetailData["<Hair>k__BackingField"])
						end
					end
				end
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BEARD) then
				if appearanceData._Beard then
					if ccItems.BodyDetailData._Beard then
						ccItems.BodyDetailData._Beard:call("copyFrom(app.charaedit.ch000.BeardData)", appearanceData._Beard)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Beard:call("copyFrom(app.charaedit.ch000.Beard)", ccItems.BodyDetailData._Beard)
						end
					elseif ccItems.BodyDetailData["<Beard>k__BackingField"] then
						ccItems.BodyDetailData["<Beard>k__BackingField"]:call("copyFrom(app.charaedit.ch000.BeardData)", appearanceData._Beard)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Beard:call("copyFrom(app.charaedit.ch000.Beard)", ccItems.BodyDetailData["<Beard>k__BackingField"])
						end
					end
				end
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.MAKEUP) then
				if appearanceData._Makeup then
					local destinationMakeup
					if ccItems.BodyDetailData._Makeup then
						destinationMakeup = {}
						ccItems.BodyDetailData._Makeup:call("copyFrom(app.charaedit.ch000.Makeup)", appearanceData._Makeup)
						destinationMakeup._Eyeliner = ccItems.BodyDetailData._Makeup._Eyeliner
						destinationMakeup._Eyeshadow = ccItems.BodyDetailData._Makeup._Eyeshadow
						destinationMakeup._Cheek = ccItems.BodyDetailData._Makeup._Cheek
						destinationMakeup._Lips = ccItems.BodyDetailData._Makeup._Lips
					elseif ccItems.BodyDetailData["<Makeup>k__BackingField"] then
						destinationMakeup = {}
						ccItems.BodyDetailData["<Makeup>k__BackingField"]:call("copyFrom(app.charaedit.ch000.Makeup)", appearanceData._Makeup)
						destinationMakeup._Eyeliner = ccItems.BodyDetailData["<Makeup>k__BackingField"]._Eyeliner
						destinationMakeup._Eyeshadow = ccItems.BodyDetailData["<Makeup>k__BackingField"]._Eyeshadow
						destinationMakeup._Cheek = ccItems.BodyDetailData["<Makeup>k__BackingField"]._Cheek
						destinationMakeup._Lips = ccItems.BodyDetailData["<Makeup>k__BackingField"]._Lips
					else
						destinationMakeup = {}
						if ccItems.BodyDetailData._Eyeliner then
							EditEyeliner(ccItems.BodyDetailData._Eyeliner, appearanceData._Makeup._Eyeliner, ccItems.ParseColors, ccItems)
							destinationMakeup._Eyeliner = ccItems.BodyDetailData._Eyeliner
						end
						if ccItems.BodyDetailData._Eyeshadow then
							EditEyeshadow(ccItems.BodyDetailData._Eyeshadow, appearanceData._Makeup._Eyeshadow, ccItems.ParseColors, ccItems)
							destinationMakeup._Eyeshadow = ccItems.BodyDetailData._Eyeshadow
						end
						if ccItems.BodyDetailData._Cheek then
							EditCheek(ccItems.BodyDetailData._Cheek, appearanceData._Makeup._Cheek, ccItems.ParseColors, ccItems)
							destinationMakeup._Cheek = ccItems.BodyDetailData._Cheek
						end
						if ccItems.BodyDetailData._Lips then
							EditLips(ccItems.BodyDetailData._Lips, appearanceData._Makeup._Lips, ccItems.ParseColors, ccItems)
							destinationMakeup._Lips = ccItems.BodyDetailData._Lips
						end
					end
					if destinationMakeup and ccItems.EditContexts and bodyDetailContext then
						if bodyDetailContext._Eyeliner and bodyDetailContext._Eyeshadow and bodyDetailContext._Cheek and bodyDetailContext._Lips then
							bodyDetailContext._Eyeliner:call("copyFrom(app.charaedit.ch000.Eyeliner)", destinationMakeup._Eyeliner)
							bodyDetailContext._Eyeshadow:call("copyFrom(app.charaedit.ch000.Eyeshadow)", destinationMakeup._Eyeshadow)
							bodyDetailContext._Cheek:call("copyFrom(app.charaedit.ch000.Cheek)", destinationMakeup._Cheek)
							bodyDetailContext._Lips:call("copyFrom(app.charaedit.ch000.Lips)", destinationMakeup._Lips)
						end
					end
				end
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.FACE) then
				if appearanceData._FurFacePattern then
					if ccItems.BodyDetailData._FurFacePattern then
						ccItems.BodyDetailData._FurFacePattern:call("copyFrom(app.charaedit.ch000.FurFacePatternData)", appearanceData._FurFacePattern)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurFacePattern:call("copyFrom(app.charaedit.ch000.FurFacePattern)", ccItems.BodyDetailData._FurFacePattern)
						end
					elseif ccItems.BodyDetailData["<FurFacePattern>k__BackingField"] then
						ccItems.BodyDetailData["<FurFacePattern>k__BackingField"]:call("copyFrom(app.charaedit.ch000.FurFacePatternData)", appearanceData._FurFacePattern)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurFacePattern:call("copyFrom(app.charaedit.ch000.FurFacePattern)", ccItems.BodyDetailData["<FurFacePattern>k__BackingField"])
						end
					end
				end
				if appearanceData._FurFaceMask then
					if ccItems.BodyDetailData._FurFaceMask then
						ccItems.BodyDetailData._FurFaceMask:call("copyFrom(app.charaedit.ch000.FurFaceMaskData)", appearanceData._FurFaceMask)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurFaceMask:call("copyFrom(app.charaedit.ch000.FurFaceMask)", ccItems.BodyDetailData._FurFaceMask)
						end
					elseif ccItems.BodyDetailData["<FurFaceMask>k__BackingField"] then
						ccItems.BodyDetailData["<FurFaceMask>k__BackingField"]:call("copyFrom(app.charaedit.ch000.FurFaceMaskData)", appearanceData._FurFaceMask)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurFaceMask:call("copyFrom(app.charaedit.ch000.FurFaceMask)", ccItems.BodyDetailData["<FurFaceMask>k__BackingField"])
						end
					end
				end
				if appearanceData._FurForehead then
					if ccItems.BodyDetailData._FurForehead then
						ccItems.BodyDetailData._FurForehead:call("copyFrom(app.charaedit.ch000.FurForeheadData)", appearanceData._FurForehead)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurForehead:call("copyFrom(app.charaedit.ch000.FurForehead)", ccItems.BodyDetailData._FurForehead)
						end
					elseif ccItems.BodyDetailData["<FurForehead>k__BackingField"] then
						ccItems.BodyDetailData["<FurForehead>k__BackingField"]:call("copyFrom(app.charaedit.ch000.FurForeheadData)", appearanceData._FurForehead)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurForehead:call("copyFrom(app.charaedit.ch000.FurForehead)", ccItems.BodyDetailData["<FurForehead>k__BackingField"])
						end
					end
				end
				if appearanceData._FurEyes then
					if ccItems.BodyDetailData._FurEyes then
						ccItems.BodyDetailData._FurEyes:call("copyFrom(app.charaedit.ch000.FurEyesData)", appearanceData._FurEyes)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurEyes:call("copyFrom(app.charaedit.ch000.FurEyes)", ccItems.BodyDetailData._FurEyes)
						end
					elseif ccItems.BodyDetailData["<FurEyes>k__BackingField"] then
						ccItems.BodyDetailData["<FurEyes>k__BackingField"]:call("copyFrom(app.charaedit.ch000.FurEyesData)", appearanceData._FurEyes)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurEyes:call("copyFrom(app.charaedit.ch000.FurEyes)", ccItems.BodyDetailData["<FurEyes>k__BackingField"])
						end
					end
				end
				if appearanceData._FurCheeks then
					if ccItems.BodyDetailData._FurCheeks then
						ccItems.BodyDetailData._FurCheeks:call("copyFrom(app.charaedit.ch000.FurCheeksData)", appearanceData._FurCheeks)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurCheeks:call("copyFrom(app.charaedit.ch000.FurCheeks)", ccItems.BodyDetailData._FurCheeks)
						end
					elseif ccItems.BodyDetailData["<FurCheeks>k__BackingField"] then
						ccItems.BodyDetailData["<FurCheeks>k__BackingField"]:call("copyFrom(app.charaedit.ch000.FurCheeksData)", appearanceData._FurCheeks)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurCheeks:call("copyFrom(app.charaedit.ch000.FurCheeks)", ccItems.BodyDetailData["<FurCheeks>k__BackingField"])
						end
					end
				end
				if appearanceData._FurNose then
					if ccItems.BodyDetailData._FurNose then
						ccItems.BodyDetailData._FurNose:call("copyFrom(app.charaedit.ch000.FurNoseData)", appearanceData._FurNose)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurNose:call("copyFrom(app.charaedit.ch000.FurNose)", ccItems.BodyDetailData._FurNose)
						end
					elseif ccItems.BodyDetailData["<FurNose>k__BackingField"] then
						ccItems.BodyDetailData["<FurNose>k__BackingField"]:call("copyFrom(app.charaedit.ch000.FurNoseData)", appearanceData._FurNose)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurNose:call("copyFrom(app.charaedit.ch000.FurNose)", ccItems.BodyDetailData["<FurNose>k__BackingField"])
						end
					end
				end
				if appearanceData._Eyes then
					if ccItems.BodyDetailData._Eyes then
						ccItems.BodyDetailData._Eyes:call("copyFrom(app.charaedit.ch000.EyesData)", appearanceData._Eyes)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Eyes:call("copyFrom(app.charaedit.ch000.Eyes)", ccItems.BodyDetailData._Eyes)
						end
					elseif ccItems.BodyDetailData["<Eyes>k__BackingField"] then
						ccItems.BodyDetailData["<Eyes>k__BackingField"]:call("copyFrom(app.charaedit.ch000.EyesData)", appearanceData._Eyes)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Eyes:call("copyFrom(app.charaedit.ch000.Eyes)", ccItems.BodyDetailData["<Eyes>k__BackingField"])
						end
					end
				end
				if appearanceData._Eyelashes then
					if ccItems.BodyDetailData._Eyelashes then
						--ccItems.BodyDetailData._Eyelashes:call("copyFrom(app.charaedit.ch000.EyelashesData)", appearanceData._Eyelashes)
						EditEyelashes(ccItems.BodyDetailData._Eyelashes, appearanceData._Eyelashes, ccItems.ParseColors, ccItems)
						ccItems.BodyDetailData._Eyelashes._Upper:set_Enabled(true) --appearanceData._Eyelashes._Upper._Enabled)
						ccItems.BodyDetailData._Eyelashes._Lower:set_Enabled(true) --appearanceData._Eyelashes._Lower._Enabled)
						if appearanceData._Eyelashes._Base then
							ccItems.BodyDetailData._Eyelashes._Base:set_Enabled(true) --appearanceData._Eyelashes._Base._Enabled)
						end
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Eyelashes:call("copyFrom(app.charaedit.ch000.Eyelashes)", ccItems.BodyDetailData._Eyelashes)
						end
					elseif ccItems.BodyDetailData["<Eyelashes>k__BackingField"] then
						--ccItems.BodyDetailData["<Eyelashes>k__BackingField"]:call("copyFrom(app.charaedit.ch000.EyelashesData)", appearanceData._Eyelashes)
						EditEyelashes(ccItems.BodyDetailData._Eyelashes, appearanceData._Eyelashes, ccItems.ParseColors, ccItems)
						ccItems.BodyDetailData._Eyelashes._Upper:set_Enabled(true) --appearanceData._Eyelashes._Upper._Enabled)
						ccItems.BodyDetailData._Eyelashes._Lower:set_Enabled(true) --appearanceData._Eyelashes._Lower._Enabled)
						if appearanceData._Eyelashes._Base then
							ccItems.BodyDetailData._Eyelashes._Base:set_Enabled(true) --appearanceData._Eyelashes._Base._Enabled)
						end
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Eyelashes:call("copyFrom(app.charaedit.ch000.Eyelashes)", ccItems.BodyDetailData["<Eyelashes>k__BackingField"])
						end
					end
				end
				if appearanceData._Eyebrows then
					if ccItems.BodyDetailData._Eyebrows then
						ccItems.BodyDetailData._Eyebrows:call("copyFrom(app.charaedit.ch000.EyebrowsData)", appearanceData._Eyebrows)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Eyebrows:call("copyFrom(app.charaedit.ch000.Eyebrows)", ccItems.BodyDetailData._Eyebrows)
						end
					elseif ccItems.BodyDetailData["<Eyebrows>k__BackingField"] then
						ccItems.BodyDetailData["<Eyebrows>k__BackingField"]:call("copyFrom(app.charaedit.ch000.EyebrowsData)", appearanceData._Eyebrows)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Eyebrows:call("copyFrom(app.charaedit.ch000.Eyebrows)", ccItems.BodyDetailData["<Eyebrows>k__BackingField"])
						end
					end
				end
				if appearanceData._Teeth then
					if ccItems.BodyDetailData._Teeth then
						ccItems.BodyDetailData._Teeth:call("copyFrom(app.charaedit.ch000.TeethData)", appearanceData._Teeth)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Teeth:call("copyFrom(app.charaedit.ch000.Teeth)", ccItems.BodyDetailData._Teeth)
						end
					elseif ccItems.BodyDetailData["<Teeth>k__BackingField"] then
						ccItems.BodyDetailData["<Teeth>k__BackingField"]:call("copyFrom(app.charaedit.ch000.TeethData)", appearanceData._Teeth)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Teeth:call("copyFrom(app.charaedit.ch000.Teeth)", ccItems.BodyDetailData["<Teeth>k__BackingField"])
						end
					end
				end
				if appearanceData._Freckles then
					if ccItems.BodyDetailData._Freckles then
						ccItems.BodyDetailData._Freckles:call("copyFrom(app.charaedit.ch000.FrecklesData)", appearanceData._Freckles)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Freckles:call("copyFrom(app.charaedit.ch000.Freckles)", ccItems.BodyDetailData._Freckles)
						end
					elseif ccItems.BodyDetailData["<Freckles>k__BackingField"] then
						ccItems.BodyDetailData["<Freckles>k__BackingField"]:call("copyFrom(app.charaedit.ch000.FrecklesData)", appearanceData._Freckles)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Freckles:call("copyFrom(app.charaedit.ch000.Freckles)", ccItems.BodyDetailData["<Freckles>k__BackingField"])
						end
					end
				end
				if appearanceData._Nose then
					if ccItems.BodyDetailData._Nose then
						ccItems.BodyDetailData._Nose:call("copyFrom(app.charaedit.ch000.NoseData)", appearanceData._Nose)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Nose:call("copyFrom(app.charaedit.ch000.Nose)", ccItems.BodyDetailData._Nose)
						end
					elseif ccItems.BodyDetailData["<Nose>k__BackingField"] then
						ccItems.BodyDetailData["<Nose>k__BackingField"]:call("copyFrom(app.charaedit.ch000.NoseData)", appearanceData._Nose)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Nose:call("copyFrom(app.charaedit.ch000.Nose)", ccItems.BodyDetailData["<Nose>k__BackingField"])
						end
					end
				end
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.BODYANDBODYDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BODYDETAILS) then
				if appearanceData._Skin then
					if ccItems.BodyDetailData._Skin then
						ccItems.BodyDetailData._Skin:call("copyFrom(app.charaedit.ch000.SkinData)", appearanceData._Skin)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Skin:call("copyFrom(app.charaedit.ch000.Skin)", ccItems.BodyDetailData._Skin)
						end
					elseif ccItems.BodyDetailData["<Skin>k__BackingField"] then
						ccItems.BodyDetailData["<Skin>k__BackingField"]:call("copyFrom(app.charaedit.ch000.SkinData)", appearanceData._Skin)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Skin:call("copyFrom(app.charaedit.ch000.Skin)", ccItems.BodyDetailData["<Skin>k__BackingField"])
						end
					end
				end
				if appearanceData._Claws then
					if ccItems.BodyDetailData._Claws then
						ccItems.BodyDetailData._Claws:call("copyFrom(app.charaedit.ch000.ClawsData)", appearanceData._Claws)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Claws:call("copyFrom(app.charaedit.ch000.Claws)", ccItems.BodyDetailData._Claws)
						end
					elseif ccItems.BodyDetailData["<Claws>k__BackingField"] then
						ccItems.BodyDetailData["<Claws>k__BackingField"]:call("copyFrom(app.charaedit.ch000.ClawsData)", appearanceData._Claws)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Claws:call("copyFrom(app.charaedit.ch000.Claws)", ccItems.BodyDetailData["<Claws>k__BackingField"])
						end
					end
				end
				if appearanceData._BodyHair then
					if ccItems.BodyDetailData._BodyHair then
						ccItems.BodyDetailData._BodyHair:call("copyFrom(app.charaedit.ch000.BodyHairData)", appearanceData._BodyHair)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._BodyHair:call("copyFrom(app.charaedit.ch000.BodyHair)", ccItems.BodyDetailData._BodyHair)
						end
					elseif ccItems.BodyDetailData["<BodyHair>k__BackingField"] then
						ccItems.BodyDetailData["<BodyHair>k__BackingField"]:call("copyFrom(app.charaedit.ch000.BodyHairData)", appearanceData._BodyHair)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._BodyHair:call("copyFrom(app.charaedit.ch000.BodyHair)", ccItems.BodyDetailData["<BodyHair>k__BackingField"])
						end
					end
				end
				if appearanceData._FurPatterns then
					if ccItems.BodyDetailData._FurPattern then
						ccItems.BodyDetailData._FurPattern:call("copyFrom(app.charaedit.ch000.FurPatternsData)", appearanceData._FurPatterns)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurPattern:call("copyFrom(app.charaedit.ch000.FurPatterns)", ccItems.BodyDetailData._FurPattern)
						end
					elseif ccItems.BodyDetailData["<FurPattern>k__BackingField"] then
						ccItems.BodyDetailData["<FurPattern>k__BackingField"]:call("copyFrom(app.charaedit.ch000.FurPatternsData)", appearanceData._FurPatterns)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._FurPattern:call("copyFrom(app.charaedit.ch000.FurPatterns)", ccItems.BodyDetailData["<FurPattern>k__BackingField"])
						end
					end
				end
				if appearanceData._Dirt then
					if ccItems.BodyDetailData._Dirt then
						ccItems.BodyDetailData._Dirt:call("copyFrom(app.charaedit.ch000.DirtData)", appearanceData._Dirt)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Dirt:call("copyFrom(app.charaedit.ch000.Dirt)", ccItems.BodyDetailData._Dirt)
						end
					elseif ccItems.BodyDetailData["<Dirt>k__BackingField"] then
						ccItems.BodyDetailData["<Dirt>k__BackingField"]:call("copyFrom(app.charaedit.ch000.DirtData)", appearanceData._Dirt)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Dirt:call("copyFrom(app.charaedit.ch000.Dirt)", ccItems.BodyDetailData["<Dirt>k__BackingField"])
						end
					end
				end
				if appearanceData._Tattoos then
					if ccItems.BodyDetailData._Tattoos then
						ccItems.BodyDetailData._Tattoos:call("restore(app.charaedit.ch000.Tattoos.SlotData[], System.Boolean)", appearanceData._Tattoos:get_SlotDatas(), true)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Tattoos:call("copyFrom(app.charaedit.ch000.Tattoos)", ccItems.BodyDetailData._Tattoos)
						end
					elseif ccItems.BodyDetailData["<Tattoos>k__BackingField"] then
						ccItems.BodyDetailData["<Tattoos>k__BackingField"]:call("restore(app.charaedit.ch000.Tattoos.SlotData[], System.Boolean)", appearanceData._Tattoos:get_SlotDatas(), true)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Tattoos:call("copyFrom(app.charaedit.ch000.Tattoos)", ccItems.BodyDetailData["<Tattoos>k__BackingField"])
						end
					end
				end
				if appearanceData._Scars then
					if ccItems.BodyDetailData._Scars then
						ccItems.BodyDetailData._Scars:call("restore(app.charaedit.ch000.Scars.SlotData[], System.Boolean)", appearanceData._Scars:get_SlotDatas(), true)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Scars:call("copyFrom(app.charaedit.ch000.Scars)", ccItems.BodyDetailData._Scars)
						end
					elseif ccItems.BodyDetailDat["<Scars>k__BackingField"] then
						ccItems.BodyDetailDat["<Scars>k__BackingField"]:call("restore(app.charaedit.ch000.Scars.SlotData[], System.Boolean)", appearanceData._Scars:get_SlotDatas(), true)
						if ccItems.EditContexts and bodyDetailContext then
							bodyDetailContext._Scars:call("copyFrom(app.charaedit.ch000.Scars)", ccItems.BodyDetailDat["<Scars>k__BackingField"])
						end
					end
				end
			end
		else
			isCompletelyEdited = false
		end
	end
	lastEditedBodyDetailData = ccItems.BodyDetailData
	EndBodyDetailEdits(ccItems)
	return isCompletelyEdited
end

--USED IN CLONER
local function GetAppearanceDatas(charaID)
	local CharacterEditManager = sdk.get_managed_singleton("app.CharacterEditManager")
	local characterAppearanceDatas = CharacterEditManager._AppearanceDB[charaID]
	return characterAppearanceDatas
end

--USED IN CLONER
local function GetAppearanceData(charaID, appearanceID)
	local characterAppearanceDatas = GetAppearanceDatas(charaID)
	if characterAppearanceDatas then
		return characterAppearanceDatas[appearanceID]
	end
	return nil
end

--USED IN CLONER
local function GetCostumeDatas(charaID)
	local CharacterEditManager = sdk.get_managed_singleton("app.CharacterEditManager")
	local characterCostumeDatas = CharacterEditManager._CostumeDB[charaID]
	return characterCostumeDatas
end

--USED IN CLONER
local function GetCostumeData(charaID, costumeID)
	local characterCostumeDatas = GetCostumeDatas(charaID)
	if characterCostumeDatas then
		return characterCostumeDatas[costumeID]
	end
	return nil
end

local function HasAppearanceDataMatch(charaID, appearanceData)
	local characterAppearanceDatas = GetAppearanceDatas(charaID)
	for appearanceKey, appearanceValue in pairs(characterAppearanceDatas._entries) do
		if appearanceValue.value and appearanceValue.value == appearanceData then
			return true
		end
	end
	return false
end

local function GetContextHolderContext(contextholder, contextTypeString)
	if contextholder then
		local contextList = contextholder.Contexts
		if contextList then
			local contextRuntimeType = sdk.find_type_definition(contextTypeString):get_runtime_type()
			local contextInfo = contextList[contextRuntimeType]
			if contextInfo then
				local selectedContext = contextInfo:get_CurrentContext()
				return selectedContext
			end
		end
	end
end

local function GetCharacterCustomizationDataFromPartSwapper(partSwapper, additionalParameters)
	local isBodyDetailContext = false
	local ccItems = GetCharacterCustomizationItemsFromPartSwapper(partSwapper, additionalParameters)
	local characterCustomizationData = {}
	local bodyEditorPretenderData
	if ccItems.BodyEditor then
		bodyEditorPretenderData = ccItems.BodyEditor._PretenderData
	end
	if ccItems.PartSwapper then
		partSwapperHuman = ccItems.PartSwapper._HumanContext
	end
	local faceEditorData
	local bodyEditorData
	local bodyDetailEditorData
	if ccItems.FaceEditor then
		faceEditorData = {}
		faceEditorData._EditValues = GetEditValues(ccItems.FaceEditor, "getEditValues()")
	end
	if ccItems.BodyEditor then
		bodyEditorData = {}
		bodyEditorData._EditValues = GetEditValues(ccItems.BodyEditor, "getEditValues()")
	end
	if not partSwapperHuman and ccItems.PartSwapper then
		local tempPartSwapperHuman = {}
		tempPartSwapperHuman._Meta = ccItems.PartSwapper._Meta
		partSwapperHuman = tempPartSwapperHuman
	end
	if ccItems.BodyDetailEditor then
		bodyDetailEditorData = {}
		bodyDetailEditorData._Skin = ccItems.BodyDetailEditor._Skin
		bodyDetailEditorData._Claw = ccItems.BodyDetailEditor._Claws
		bodyDetailEditorData._Hair = ccItems.BodyDetailEditor._Hair
		bodyDetailEditorData._Beard = ccItems.BodyDetailEditor._Beard
		bodyDetailEditorData._BodyHair = ccItems.BodyDetailEditor._BodyHair
		bodyDetailEditorData._FurPattern = ccItems.BodyDetailEditor._FurPattern
		bodyDetailEditorData._FurFacePattern = ccItems.BodyDetailEditor._FurFacePattern
		bodyDetailEditorData._FurFaceMask = ccItems.BodyDetailEditor._FurFaceMask
		bodyDetailEditorData._FurForehead = ccItems.BodyDetailEditor._FurForehead
		bodyDetailEditorData._FurEyes = ccItems.BodyDetailEditor._FurEyes
		bodyDetailEditorData._FurCheeks = ccItems.BodyDetailEditor._FurCheeks
		bodyDetailEditorData._FurNose = ccItems.BodyDetailEditor._FurNose
		bodyDetailEditorData._Eyes = ccItems.BodyDetailEditor._Eyes
		bodyDetailEditorData._Eyebrows = ccItems.BodyDetailEditor._Eyebrows
		bodyDetailEditorData._Eyelashes = ccItems.BodyDetailEditor._Eyelashes
		bodyDetailEditorData._Eyeliner = ccItems.BodyDetailEditor._Makeup._Eyeliner
		bodyDetailEditorData._Eyeshadow = ccItems.BodyDetailEditor._Makeup._Eyeshadow
		bodyDetailEditorData._Cheek = ccItems.BodyDetailEditor._Makeup._Cheek
		bodyDetailEditorData._Lips = ccItems.BodyDetailEditor._Makeup._Lips
		bodyDetailEditorData._Makeup = ccItems.BodyDetailEditor._Makeup
		bodyDetailEditorData._Teeth = ccItems.BodyDetailEditor._Teeth
		bodyDetailEditorData._Freckles = ccItems.BodyDetailEditor._Freckles
		bodyDetailEditorData._Nose = ccItems.BodyDetailEditor._Nose
		bodyDetailEditorData._Dirt = ccItems.BodyDetailEditor._Dirt
		bodyDetailEditorData._Tattoos = ccItems.BodyDetailEditor._Tattoos
		bodyDetailEditorData._Scars = ccItems.BodyDetailEditor._Scars
	end
	characterCustomizationData["HeadFaceEditor"] = faceEditorData
	characterCustomizationData["BodyEditorBodyEdit"] = bodyEditorData
	characterCustomizationData["BodyEditorPretender"] = bodyEditorPretenderData
	characterCustomizationData["PartSwapperHuman"] = partSwapperHuman
	characterCustomizationData["BodyDetailEditor"] = bodyDetailEditorData
	characterCustomizationData["IsBodyDetailContext"] = isBodyDetailContext
	return characterCustomizationData
end

--local characterCustomizationDataCache = {}
local function GetCharacterCustomizationData(character, additionalParameters)
	local isBodyDetailContext = false
	local partSwapper = character["<HumanPartSwapper>k__BackingField"]
	local ccItems = GetCharacterCustomizationItemsFromPartSwapper(partSwapper, additionalParameters)
	local characterCustomizationData = {}
	local bodyEditorPretenderData
	if ccItems.BodyEditor then
		bodyEditorPretenderData = ccItems.BodyEditor._PretenderData
	end
	local partSwapperHuman
	if ccItems.PartSwapper then
		partSwapperHuman = ccItems.PartSwapper._HumanContext
	end
	local faceEditorData
	local bodyEditorData
	local bodyDetailEditorData

	if partSwapper then
		ccItems.BodyDetailEditor = partSwapper:get_BodyDetailEditor()
	end
	--if characterCustomizationDataCache[tostring(character.CharacterID)] then
	--	characterCustomizationData = characterCustomizationDataCache[tostring(character.CharacterID)]
	--else
		local characterContextholder = character:get_Context()
		local faceEditContext = GetContextHolderContext(characterContextholder, "app.FaceEditContext")
		local bodyEditContext = GetContextHolderContext(characterContextholder, "app.BodyEditContext")
		local bodyDetailEditContext = GetContextHolderContext(characterContextholder, "app.BodyDetailContext")

		--local ch230AppearanceContext = GetContextHolderContext(characterContextholder, "app.Ch230AppearanceContext")
		--if ch230AppearanceContext then
		--	characterCh230AppearanceContext:set_HeadPattern(ch230AppearanceContext._HeadPattern)
		--	characterCh230AppearanceContext:set_HairPattern(ch230AppearanceContext._HairPattern)
		--	characterCh230AppearanceContext:set_BeardPattern(ch230AppearanceContext._BeardPattern)
		--	characterCh230AppearanceContext:set_AppearancePattern(ch230AppearanceContext._AppearancePattern)
		--	characterCh230AppearanceContext:set_CostumePattern(ch230AppearanceContext._CostumePattern)
		--end

		if faceEditContext then
			faceEditorData = {}
			faceEditorData._EditValues = faceEditContext._EditValues
		elseif ccItems.FaceEditor then
			faceEditorData = {}
			faceEditorData._EditValues = GetEditValues(ccItems.FaceEditor, "getEditValues()")
		end

		if bodyEditContext then
			bodyEditorData = {}
			bodyEditorData._EditValues = bodyEditContext._EditValues
		elseif ccItems.BodyEditor then
			bodyEditorData = {}
			bodyEditorData._EditValues = GetEditValues(ccItems.BodyEditor, "getEditValues()")
		end

		if not partSwapperHuman and ccItems.PartSwapper then
			local tempPartSwapperHuman = {}
			tempPartSwapperHuman._Meta = ccItems.PartSwapper._Meta
			partSwapperHuman = tempPartSwapperHuman
		end

		if bodyDetailEditContext then
			bodyDetailEditorData = {}
			bodyDetailEditorData._Skin = bodyDetailEditContext._Skin
			bodyDetailEditorData._Claw = bodyDetailEditContext._Claws
			bodyDetailEditorData._Hair = bodyDetailEditContext._Hair
			bodyDetailEditorData._Beard = bodyDetailEditContext._Beard
			bodyDetailEditorData._BodyHair = bodyDetailEditContext._BodyHair
			bodyDetailEditorData._FurPattern = bodyDetailEditContext._FurPattern
			bodyDetailEditorData._FurFacePattern = bodyDetailEditContext._FurFacePattern
			bodyDetailEditorData._FurFaceMask = bodyDetailEditContext._FurFaceMask
			bodyDetailEditorData._FurForehead = bodyDetailEditContext._FurForehead
			bodyDetailEditorData._FurEyes = bodyDetailEditContext._FurEyes
			bodyDetailEditorData._FurCheeks = bodyDetailEditContext._FurCheeks
			bodyDetailEditorData._FurNose = bodyDetailEditContext._FurNose
			bodyDetailEditorData._Eyes = bodyDetailEditContext._Eyes
			bodyDetailEditorData._Eyebrows = bodyDetailEditContext._Eyebrows
			bodyDetailEditorData._Eyelashes = bodyDetailEditContext._Eyelashes
			bodyDetailEditorData._Eyeliner = bodyDetailEditContext._Eyeliner
			bodyDetailEditorData._Eyeshadow = bodyDetailEditContext._Eyeshadow
			bodyDetailEditorData._Cheek = bodyDetailEditContext._Cheek
			bodyDetailEditorData._Lips = bodyDetailEditContext._Lips
			bodyDetailEditorData._Teeth = bodyDetailEditContext._Teeth
			bodyDetailEditorData._Freckles = bodyDetailEditContext._Freckles
			bodyDetailEditorData._Nose = bodyDetailEditContext._Nose
			bodyDetailEditorData._Dirt = bodyDetailEditContext._Dirt
			bodyDetailEditorData._Tattoos = bodyDetailEditContext._Tattoos
			bodyDetailEditorData._Scars = bodyDetailEditContext._Scars
			isBodyDetailContext = true
		elseif ccItems.BodyDetailEditor then
			bodyDetailEditorData = {}
			bodyDetailEditorData._Skin = ccItems.BodyDetailEditor._Skin
			bodyDetailEditorData._Claw = ccItems.BodyDetailEditor._Claws
			bodyDetailEditorData._Hair = ccItems.BodyDetailEditor._Hair
			bodyDetailEditorData._Beard = ccItems.BodyDetailEditor._Beard
			bodyDetailEditorData._BodyHair = ccItems.BodyDetailEditor._BodyHair
			bodyDetailEditorData._FurPattern = ccItems.BodyDetailEditor._FurPattern
			bodyDetailEditorData._FurFacePattern = ccItems.BodyDetailEditor._FurFacePattern
			bodyDetailEditorData._FurFaceMask = ccItems.BodyDetailEditor._FurFaceMask
			bodyDetailEditorData._FurForehead = ccItems.BodyDetailEditor._FurForehead
			bodyDetailEditorData._FurEyes = ccItems.BodyDetailEditor._FurEyes
			bodyDetailEditorData._FurCheeks = ccItems.BodyDetailEditor._FurCheeks
			bodyDetailEditorData._FurNose = ccItems.BodyDetailEditor._FurNose
			bodyDetailEditorData._Eyes = ccItems.BodyDetailEditor._Eyes
			bodyDetailEditorData._Eyebrows = ccItems.BodyDetailEditor._Eyebrows
			bodyDetailEditorData._Eyelashes = ccItems.BodyDetailEditor._Eyelashes
			bodyDetailEditorData._Eyeliner = ccItems.BodyDetailEditor._Makeup._Eyeliner
			bodyDetailEditorData._Eyeshadow = ccItems.BodyDetailEditor._Makeup._Eyeshadow
			bodyDetailEditorData._Cheek = ccItems.BodyDetailEditor._Makeup._Cheek
			bodyDetailEditorData._Lips = ccItems.BodyDetailEditor._Makeup._Lips
			bodyDetailEditorData._Makeup = ccItems.BodyDetailEditor._Makeup
			bodyDetailEditorData._Teeth = ccItems.BodyDetailEditor._Teeth
			bodyDetailEditorData._Freckles = ccItems.BodyDetailEditor._Freckles
			bodyDetailEditorData._Nose = ccItems.BodyDetailEditor._Nose
			bodyDetailEditorData._Dirt = ccItems.BodyDetailEditor._Dirt
			bodyDetailEditorData._Tattoos = ccItems.BodyDetailEditor._Tattoos
			bodyDetailEditorData._Scars = ccItems.BodyDetailEditor._Scars
			isBodyDetailContext = false
		end
	--	characterCustomizationDataCache[tostring(character.CharacterID)] = characterCustomizationData
	--end
	characterCustomizationData["HeadFaceEditor"] = faceEditorData
	characterCustomizationData["BodyEditorBodyEdit"] = bodyEditorData
	characterCustomizationData["BodyEditorPretender"] = bodyEditorPretenderData
	characterCustomizationData["PartSwapperHuman"] = partSwapperHuman
	characterCustomizationData["BodyDetailEditor"] = bodyDetailEditorData
	characterCustomizationData["IsBodyDetailContext"] = isBodyDetailContext
	return characterCustomizationData
end

local function GetCharacterEditDefineMetaData(character, cloneOrMockupBuilder)
	local meta = nil
	local characterPartSwapper = nil
	if cloneOrMockupBuilder then
		characterPartSwapper = cloneOrMockupBuilder:get_PartSwapper()
	elseif character then
		characterPartSwapper = character["<HumanPartSwapper>k__BackingField"]
	end
	if characterPartSwapper then
		meta = characterPartSwapper._Meta
	end
	return meta
end

local function GetItemSlotData(equipData, equipDataSlotEnum)
	local itemData
	if equipData and equipDataSlotEnum then
		local storageData
		storageData = equipData:call("get(app.EquipData.SlotEnum)", equipDataSlotEnum)
		if storageData then
			itemData = storageData._ItemData
		end
	end
	return itemData
end

local function GetCharacterItemData(character)
	local characterItemData = {}

	if character then
		local ItemManager = sdk.get_managed_singleton("app.ItemManager")
		local roEquipData = ItemManager:call("getEquipData(app.Character)", character)

		characterItemData.HeadItemData, characterItemData.HeadStorageData = GetItemSlotData(roEquipData, ENUMS.EquipDataSlotEnum.Head)
		characterItemData.VisualItemData, characterItemData.VisualStorageData = GetItemSlotData(roEquipData, ENUMS.EquipDataSlotEnum.Visual)
		characterItemData.UpperItemData, characterItemData.UpperStorageData = GetItemSlotData(roEquipData, ENUMS.EquipDataSlotEnum.Upper)
		characterItemData.MantleItemData, characterItemData.MantleStorageData = GetItemSlotData(roEquipData, ENUMS.EquipDataSlotEnum.Mantle)
		characterItemData.LowerItemData, characterItemData.LowerStorageData = GetItemSlotData(roEquipData, ENUMS.EquipDataSlotEnum.Lower)
		characterItemData.MainItemData, characterItemData.MainStorageData = GetItemSlotData(roEquipData, ENUMS.EquipDataSlotEnum.Main)
		characterItemData.SubItemData, characterItemData.SubStorageData = GetItemSlotData(roEquipData, ENUMS.EquipDataSlotEnum.Sub)
		characterItemData.Jewelry_00ItemData, characterItemData.Jewelry_00StorageData = GetItemSlotData(roEquipData, ENUMS.EquipDataSlotEnum.Jewelry_00)
		characterItemData.Jewelry_01ItemData, characterItemData.Jewelry_01StorageData = GetItemSlotData(roEquipData, ENUMS.EquipDataSlotEnum.Jewelry_01)

		if characterItemData.HeadItemData then
			characterItemData._HelmStyle = ItemManager:getHelmStyle(characterItemData.HeadItemData._StyleNo)
		end
		if characterItemData.VisualItemData then
			characterItemData._FacewearStyle = ItemManager:getFaceStyle(characterItemData.VisualItemData._StyleNo)
		end
		if characterItemData.UpperItemData then
			characterItemData._TopsStyle = ItemManager:getTopsStyle(characterItemData.UpperItemData._StyleNo)
		end
		if characterItemData.MantleItemData then
			characterItemData._MantleStyle = ItemManager:getMantleStyle(characterItemData.MantleItemData._StyleNo)
		end
		if characterItemData.LowerItemData then
			characterItemData._PantsStyle = ItemManager:getPantsStyle(characterItemData.LowerItemData._StyleNo)
		end

		if characterItemData.MainItemData then
			characterItemData.MainItemParam = characterItemData.MainItemData:get_WeaponParam()
			if characterItemData.MainItemParam then
				characterItemData._RightWeapon = characterItemData.MainItemParam:get_WeaponId()
				characterItemData._RightWeaponJob = characterItemData.MainItemParam:getJob()
			end
		end
		if characterItemData.MainStorageData then
			characterItemData._IsRightWeaponDraconic = characterItemData.MainStorageData:get_IsDraconic()
		end
		if characterItemData.SubItemData then
			characterItemData.SubItemParam = characterItemData.SubItemData:get_WeaponParam()
			if characterItemData.SubItemParam then
				characterItemData._LeftWeapon = characterItemData.SubItemParam:get_WeaponId()
				characterItemData._LeftWeaponJob = characterItemData.SubItemParam:getJob()
			end
		end
		if characterItemData.SubStorageData then
			characterItemData._IsLeftWeaponDraconic = characterItemData.SubStorageData:get_IsDraconic()
		end

	end

	return characterItemData
end

--USED IN CLONER
local function EditCostumeMetaVariationStyles(meta, costumeDetails, editType, character)
	if editType ~= ENUMS.CHARACTEREDITTYPE.ALL and editType ~= ENUMS.CHARACTEREDITTYPE.COSTUME then
		return true
	end
	if costumeDetails then
		if meta then
			--local metaLocked = meta:get_Locked() --1099511627775
			if meta.set_Locked then
				meta:set_Locked(0)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.COSTUME) then
				local characterItemData = nil
				if character then
					characterItemData = GetCharacterItemData(character)
				end
				if costumeDetails._HelmVariationStyle ~= CURRENTITEMVALUE then
					meta:call("set_HelmVariationStyle(app.charaedit.ch000.HelmVariationStyle)", costumeDetails._HelmVariationStyle)
				end
				if costumeDetails._FacewearVariationStyle ~= CURRENTITEMVALUE then
					meta:call("set_FacewearVariationStyle(app.charaedit.ch000.FacewearVariationStyle)", costumeDetails._FacewearVariationStyle)
				end
				if costumeDetails._TopsVariationStyle ~= CURRENTITEMVALUE then
					meta:call("set_TopsVariationStyle(app.charaedit.ch000.TopsVariationStyle)", costumeDetails._TopsVariationStyle)
				end
				if costumeDetails._PantsVariationStyle ~= CURRENTITEMVALUE then
					meta:call("set_PantsVariationStyle(app.charaedit.ch000.PantsVariationStyle)", costumeDetails._PantsVariationStyle)
				end
				if costumeDetails._MantleVariationStyle ~= CURRENTITEMVALUE then
					meta:call("set_MantleVariationStyle(app.charaedit.ch000.MantleVariationStyle)", costumeDetails._MantleVariationStyle)
				end
				if costumeDetails._UnderwearVariationStyle ~= CURRENTITEMVALUE then
					meta:call("set_UnderwearVariationStyle(app.charaedit.ch000.UnderwearVariationStyle)", costumeDetails._UnderwearVariationStyle)
				end
			end
			--meta:set_Locked(metaLocked)
			return true
		end
	end
	return false
end

--USED IN CLONER
local function EditCostumeMeta(meta, costumeDetails, editType, character)
	if editType ~= ENUMS.CHARACTEREDITTYPE.ALL and editType ~= ENUMS.CHARACTEREDITTYPE.COSTUME then
		return true
	end
	if costumeDetails then
		if meta then
			--local metaLocked = meta:get_Locked() --1099511627775
			if meta.set_Locked then
				meta:set_Locked(0)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.COSTUME) then
				local characterItemData = nil
				if character then
					characterItemData = GetCharacterItemData(character)
				end
				if costumeDetails._HelmStyle ~= CURRENTITEMVALUE then
					meta:call("set_HelmStyle(app.HelmStyle)", costumeDetails._HelmStyle)
				elseif characterItemData then
					meta:call("set_HelmStyle(app.HelmStyle)", characterItemData._HelmStyle)
				end
				if costumeDetails._FacewearStyle ~= CURRENTITEMVALUE then
					meta:call("set_FacewearStyle(app.FacewearStyle)", costumeDetails._FacewearStyle)
				elseif characterItemData then
					meta:call("set_FacewearStyle(app.FacewearStyle)", characterItemData._FacewearStyle)
				end
				if costumeDetails._TopsStyle ~= CURRENTITEMVALUE then
					meta:call("set_TopsStyle(app.TopsStyle)", costumeDetails._TopsStyle)
				elseif characterItemData then
					meta:call("set_TopsStyle(app.TopsStyle)", characterItemData._TopsStyle)
				end
				if costumeDetails._BackpackStyle ~= CURRENTITEMVALUE then
					meta:call("set_BackpackStyle(app.BackpackStyle)", costumeDetails._BackpackStyle)
				elseif characterItemData then
					meta:call("set_BackpackStyle(app.BackpackStyle)", characterItemData._BackpackStyle)
				end
				if costumeDetails._PantsStyle ~= CURRENTITEMVALUE then
					meta:call("set_PantsStyle(app.PantsStyle)", costumeDetails._PantsStyle)
				elseif characterItemData then
					meta:call("set_PantsStyle(app.PantsStyle)", characterItemData._PantsStyle)
				end
				if costumeDetails._MantleStyle ~= CURRENTITEMVALUE then
					meta:call("set_MantleStyle(app.MantleStyle)", costumeDetails._MantleStyle)
				elseif characterItemData then
					meta:call("set_MantleStyle(app.MantleStyle)", characterItemData._MantleStyle)
				end
				if costumeDetails._UnderwearStyle ~= CURRENTITEMVALUE then
					meta:call("set_UnderwearStyle(app.UnderwearStyle)", costumeDetails._UnderwearStyle)
				elseif characterItemData then
					meta:call("set_UnderwearStyle(app.UnderwearStyle)", characterItemData._UnderwearStyle)
				end
			end
			--meta:set_Locked(metaLocked)
			return EditCostumeMetaVariationStyles(meta, costumeDetails, editType, character)
		end
	end
	return false
end

local function GetCostumeVariationStylesMeta(meta, costumeDetails)
	if costumeDetails == nil then
		costumeDetails = {}
	end
	costumeDetails._HelmVariationStyle = meta._HelmVariationStyle
	costumeDetails._FacewearVariationStyle = meta._FacewearVariationStyle
	costumeDetails._TopsVariationStyle = meta._TopsVariationStyle
	costumeDetails._PantsVariationStyle = meta._PantsVariationStyle
	costumeDetails._MantleVariationStyle = meta._MantleVariationStyle
	costumeDetails._UnderwearVariationStyle = meta._UnderwearVariationStyle
	return costumeDetails
end

local function GetCostumeMeta(meta)
	local costumeDetails = {}
	costumeDetails._HelmStyle = meta._HelmStyle
	costumeDetails._FacewearStyle = meta._FacewearStyle
	costumeDetails._TopsStyle = meta._TopsStyle
	costumeDetails._BackpackStyle = meta._BackpackStyle
	costumeDetails._PantsStyle = meta._PantsStyle
	costumeDetails._MantleStyle = meta._MantleStyle
	costumeDetails._UnderwearStyle = meta._UnderwearStyle
	return GetCostumeVariationStylesMeta(meta, costumeDetails)
end

local function GetDefaultCostumeMeta()
	local costumeDetails = {}
	costumeDetails._HelmStyle = 0
	costumeDetails._FacewearStyle = 0
	costumeDetails._TopsStyle = 0
	costumeDetails._MantleStyle = 0
	costumeDetails._PantsStyle = 0
	costumeDetails._BackpackStyle = 0
	costumeDetails._UnderwearStyle = 905051872
	costumeDetails._HelmVariationStyle = 0
	costumeDetails._FacewearVariationStyle = 0
	costumeDetails._TopsVariationStyle = 0
	costumeDetails._PantsVariationStyle = 0
	costumeDetails._MantleVariationStyle = 0
	costumeDetails._UnderwearVariationStyle = 0
	return costumeDetails
end

local function EditCostumePartSwapperMeta(ccItems, costumeDetails, editType)
	if editType ~= ENUMS.CHARACTEREDITTYPE.ALL and editType ~= ENUMS.CHARACTEREDITTYPE.COSTUME then
		return true
	end
	if ccItems.PartSwapper then
		StartPartSwapperEdits(ccItems)
		local isEdited = EditCostumeMeta(ccItems.PartSwapper._Meta, costumeDetails, editType, character)
		EndPartSwapperEdits(ccItems)
		return isEdited
	end
	return false
end

local function EditCharacterCostumeMeta(character, costumeDetails, editType, cloneOrMockupBuilder)
	if editType ~= ENUMS.CHARACTEREDITTYPE.ALL and editType ~= ENUMS.CHARACTEREDITTYPE.COSTUME then
		return true
	end
	local meta = GetCharacterEditDefineMetaData(character, cloneOrMockupBuilder)
	return EditCostumeMeta(meta, costumeDetails, editType, character)
end

local function GetHeadAppearanceMeta(meta)
	local appearanceDetails = {}
	appearanceDetails._HeadStyle = meta._HeadStyle
	appearanceDetails._HairStyle = meta._HairStyle
	appearanceDetails._BeardStyle = meta._BeardStyle
	appearanceDetails._FurFaceStyle = meta._FurFaceStyle
	appearanceDetails._FurForeheadStyle = meta._FurForeheadStyle
	appearanceDetails._FurEyeStyle = meta._FurEyeStyle
	appearanceDetails._FurCheekStyle = meta._FurCheekStyle
	appearanceDetails._FurNoseStyle = meta._FurNoseStyle
	appearanceDetails._EyeLeftStyle = meta._EyeLeftStyle
	appearanceDetails._EyeRightStyle = meta._EyeRightStyle
	appearanceDetails._EyeStyle = meta._EyeStyle
	appearanceDetails._EyebrowStyle = meta._EyebrowStyle
	appearanceDetails._EyelashStyle = meta._EyelashStyle
	appearanceDetails._EyelinerStyle = meta._EyelinerStyle
	appearanceDetails._EyeshadowStyle = meta._EyeshadowStyle
	appearanceDetails._CheekStyle = meta._CheekStyle
	appearanceDetails._LipStyle = meta._LipStyle
	appearanceDetails._FrecklesStyle = meta._FrecklesStyle
	appearanceDetails._NoseStyle = meta._NoseStyle
	return appearanceDetails
end

local function EditHeadAppearanceMeta(meta, appearanceDetails, editType)
	if editType ~= ENUMS.CHARACTEREDITTYPE.ALL and editType ~= ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME
		and editType ~= ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS
		and editType ~= ENUMS.CHARACTEREDITTYPE.HEAD
		and editType ~= ENUMS.CHARACTEREDITTYPE.HAIRSTYLE
		and editType ~= ENUMS.CHARACTEREDITTYPE.BEARD
		and editType ~= ENUMS.CHARACTEREDITTYPE.MAKEUP
		and editType ~= ENUMS.CHARACTEREDITTYPE.FACE
		then
		return true
	end
	if appearanceDetails then
		if meta then
			--local metaLocked = meta:get_Locked() --1099511627775
			if meta.set_Locked then
				meta:set_Locked(0)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.HEAD) then
				meta:call("set_HeadStyle(app.HeadStyle)", appearanceDetails._HeadStyle)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.HAIRSTYLE) then
				meta:call("set_HairStyle(app.HairStyle)", appearanceDetails._HairStyle)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BEARD) then
				meta:call("set_BeardStyle(app.BeardStyle)", appearanceDetails._BeardStyle)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.MAKEUP) then
				meta:call("set_EyelashStyle(app.EyelashStyle)", appearanceDetails._EyelashStyle)
				meta:call("set_EyelinerStyle(app.EyelinerStyle)", appearanceDetails._EyelinerStyle)
				meta:call("set_EyeshadowStyle(app.EyeshadowStyle)", appearanceDetails._EyeshadowStyle)
				meta:call("set_CheekStyle(app.CheekStyle)", appearanceDetails._CheekStyle)
				meta:call("set_LipStyle(app.LipStyle)", appearanceDetails._LipStyle)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.FACE) then
				meta:call("set_FurFaceStyle(app.charaedit.ch000.FurFaceStyle)", appearanceDetails._FurFaceStyle)
				meta:call("set_FurForeheadStyle(app.charaedit.ch000.FurForeheadStyle)", appearanceDetails._FurForeheadStyle)
				meta:call("set_FurEyeStyle(app.charaedit.ch000.FurEyeStyle)", appearanceDetails._FurEyeStyle)
				meta:call("set_FurCheekStyle(app.charaedit.ch000.FurCheekStyle)", appearanceDetails._FurCheekStyle)
				meta:call("set_FurNoseStyle(app.charaedit.ch000.FurNoseStyle)", appearanceDetails._FurNoseStyle)
				if appearanceDetails._EyeLeftStyle and appearanceDetails._EyeRightStyle and appearanceDetails._EyeLeftStyle == appearanceDetails._EyeRightStyle then
					meta:call("set_EyeStyle(app.EyeStyle)", appearanceDetails._EyeStyle)
				end
				if appearanceDetails._EyeLeftStyle then
					meta:call("set_EyeLeftStyle(app.EyeStyle)", appearanceDetails._EyeLeftStyle)
				end
				if appearanceDetails._EyeRightStyle then
					meta:call("set_EyeRightStyle(app.EyeStyle)", appearanceDetails._EyeRightStyle)
				end
				meta:call("set_EyebrowStyle(app.EyebrowStyle)", appearanceDetails._EyebrowStyle)
				meta:call("set_FrecklesStyle(app.FrecklesStyle)", appearanceDetails._FrecklesStyle)
				meta:call("set_NoseStyle(app.charaedit.ch000.NoseStyle)", appearanceDetails._NoseStyle)
			end
			--meta:set_Locked(metaLocked)
			return true
		end
	end
	return false
end

local function GetBodyDetailAppearanceMeta(meta)
	local appearanceDetails = {}
	appearanceDetails._Gender = meta._Gender
	appearanceDetails._Species = meta._Species
	appearanceDetails._SkinStyle = meta._SkinStyle
	appearanceDetails._MuscleStyle = meta._MuscleStyle
	appearanceDetails._BodyHairStyle = meta._BodyHairStyle
	appearanceDetails._FurStyle = meta._FurStyle
	appearanceDetails._FurPattern = meta._FurPattern
	appearanceDetails._SpecialScarStyle = meta._SpecialScarStyle
	return appearanceDetails
end

local function EditBodyDetailAppearanceMeta(meta, appearanceDetails, editType)
	if editType ~= ENUMS.CHARACTEREDITTYPE.ALL and editType ~= ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME
		and editType ~= ENUMS.CHARACTEREDITTYPE.GENDER
		and editType ~= ENUMS.CHARACTEREDITTYPE.SPECIES
		and editType ~= ENUMS.CHARACTEREDITTYPE.BODYANDBODYDETAILS
		and editType ~= ENUMS.CHARACTEREDITTYPE.BODYDETAILS
		then
		return true
	end
	if appearanceDetails then
		if meta then
			--local metaLocked = meta:get_Locked() --1099511627775
			if meta.set_Locked then
				meta:set_Locked(0)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.GENDER) then
				meta:call("set_Gender(app.Gender)", appearanceDetails._Gender)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.SPECIES) then
				meta:call("set_Species(app.Species)", appearanceDetails._Species)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.BODYANDBODYDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BODYDETAILS) then
				meta:call("set_SkinStyle(app.SkinStyle)", appearanceDetails._SkinStyle)
				meta:call("set_MuscleStyle(app.MuscleStyle)", appearanceDetails._MuscleStyle)
				meta:call("set_BodyHairStyle(app.BodyHairStyle)", appearanceDetails._BodyHairStyle)
				meta:call("set_FurStyle(app.FurStyle)", appearanceDetails._FurStyle)
				meta:call("set_FurPattern(app.FurPattern)", appearanceDetails._FurPattern)
				meta:call("set_SpecialScar(app.SpecialScarStyle)", appearanceDetails._SpecialScarStyle)
			end
			--meta:set_Locked(metaLocked)
			return true
		end
	end
	return false
end

--USED IN CLONER
local function EditAppearanceMeta(meta, appearanceDetails, editType)
	if editType == ENUMS.CHARACTEREDITTYPE.COSTUME then
		return true
	end
	if appearanceDetails then
		if meta then
			--local metaLocked = meta:get_Locked() --1099511627775
			if meta.set_Locked then
				meta:set_Locked(0)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS
				or editType == ENUMS.CHARACTEREDITTYPE.HEAD or editType == ENUMS.CHARACTEREDITTYPE.HAIRSTYLE or editType == ENUMS.CHARACTEREDITTYPE.FACE
				or editType == ENUMS.CHARACTEREDITTYPE.BEARD or editType == ENUMS.CHARACTEREDITTYPE.MAKEUP) then
				EditHeadAppearanceMeta(meta, appearanceDetails, editType)
			end
			if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.BODYANDBODYDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BODYDETAILS or editType == ENUMS.CHARACTEREDITTYPE.GENDER or editType == ENUMS.CHARACTEREDITTYPE.SPECIES) then
				EditBodyDetailAppearanceMeta(meta, appearanceDetails, editType)
			end
			--meta:set_Locked(metaLocked)
			return true
		end
	end
	return false
end

local function EditCharacterAppearanceMeta(character, appearanceDetails, editType, cloneOrMockupBuilder)
	if editType == ENUMS.CHARACTEREDITTYPE.COSTUME then
		return true
	end
	local meta = GetCharacterEditDefineMetaData(character, cloneOrMockupBuilder)
	return EditAppearanceMeta(meta, appearanceDetails, editType)
end

local function ResetAppearanceMeta(meta)
	local appearanceDetails = {}
	appearanceDetails._Gender = 0
	appearanceDetails._Species = 0
	appearanceDetails._SkinStyle = 0
	appearanceDetails._MuscleStyle = 0
	appearanceDetails._BodyHairStyle = 0
	appearanceDetails._FurStyle = 0
	appearanceDetails._FurPattern = 0
	appearanceDetails._SpecialScarStyle = 0
	appearanceDetails._HeadStyle = 0
	appearanceDetails._HairStyle = 0
	appearanceDetails._BeardStyle = 0
	appearanceDetails._FurFaceStyle = 0
	appearanceDetails._FurForeheadStyle = 0
	appearanceDetails._FurEyeStyle = 0
	appearanceDetails._FurCheekStyle = 0
	appearanceDetails._FurNoseStyle = 0
	appearanceDetails._EyeLeftStyle = 0
	appearanceDetails._EyeRightStyle = 0
	appearanceDetails._EyeStyle = 0
	appearanceDetails._EyebrowStyle = 0
	appearanceDetails._EyelashStyle = 0
	appearanceDetails._EyelinerStyle = 0
	appearanceDetails._EyeshadowStyle = 0
	appearanceDetails._CheekStyle = 0
	appearanceDetails._LipStyle = 0
	appearanceDetails._FrecklesStyle = 0
	appearanceDetails._NoseStyle = 0
	return EditAppearanceMeta(meta, appearanceDetails, ENUMS.CHARACTEREDITTYPE.ALL)
end

local function EditEditorDataUsingEditValueData(editor, editValueData, isEditValueData, isContext, ccItems, editType) -- do I need to add conditons for editTypes?
	local isEdited = false
	if editValueData then
		local editValues = editValueData:GetEnumerator()
		while editValues:MoveNext() == true do
			local currentEditValue = editValues:get_Current()
			local editValue
			if isEditValueData then
				editValue = currentEditValue:makeEditValue()
			else
				editValue = currentEditValue
			end
			--local currentEditValue = editor:getEditValue(editValue._EditKeyHash)
			--local applyEdit = true
			--if currentEditValue then
			--	if currentEditValue._Value == editValue._Value then
			--		applyEdit = false
			--	end
			--end
			--if applyEdit then
				if not isContext then
					local newEditValue
					if common.GetBooleanValue(ccItems.ApplyWorkarounds) and common.ChangeToDefaultIfNil(ccItems.CharacterIndex, characterHelper.GetPartyMembersFinalIndex(ccItems.config)) > characterHelper.GetPartyMembersFinalIndex(ccItems.config) then -- this is just a workaround
						if editValue._EditKeyHash == 2846328871 then -- chest shape
							newEditValue = editValue._Value + 50
						elseif editValue._EditKeyHash == 1673052757 then -- chest size
							newEditValue = editValue._Value / 2.5
						elseif editValue._EditKeyHash == 4061319525 then -- chest height
							newEditValue = editValue._Value + 50
						elseif editValue._EditKeyHash == 3467158119 then -- chest thickness
							newEditValue = editValue._Value
						else
							newEditValue = editValue._Value
						end
						--if newEditValue > 100 then
						--	newEditValue = 100
						--elseif newEditValue < -100 then
						--	newEditValue = -100
						--end
					else
						newEditValue = editValue._Value
					end
					if editor.setEditValue then
						editor:setEditValue(editValue._EditKeyHash, newEditValue, false)
					elseif editor._BodyEdit and editor._BodyEdit[editValue._EditKeyHash] then
						editor._BodyEdit[editValue._EditKeyHash] = newEditValue
					elseif editor._FaceEdit and editor._FaceEdit[editValue._EditKeyHash] then
						editor._FaceEdit[editValue._EditKeyHash] = newEditValue
					end
					if editor.applyEdit then
						editor:applyEdit()
					end
				else
					if editor.setEditValue then
						editor:setEditValue(editValue._EditKeyHash, editValue._Value)
					elseif editor._BodyEdit and editor._BodyEdit[editValue._EditKeyHash] then
						editor._BodyEdit[editValue._EditKeyHash] = newEditValue
					elseif editor._FaceEdit and editor._FaceEdit[editValue._EditKeyHash] then
						editor._FaceEdit[editValue._EditKeyHash] = newEditValue
					end
				end
			--end
		end
		isEdited = true
	end
	return isEdited
end

local function EditEditorDataUsingEditValueDataTable(editor, editValueDataTable, isEditValueData, isContext, ccItems, editType) -- do I need to add conditons for editTypes?
	local isEdited = false
	if editValueDataTable then
		for i, currentEditValue in pairs (editValueDataTable) do
			local editValue
			if isEditValueData then
				editValue = currentEditValue:makeEditValue()
			else
				editValue = currentEditValue
			end
			if not isContext then
				local newEditValue
				if common.GetBooleanValue(ccItems.ApplyWorkarounds) and common.ChangeToDefaultIfNil(ccItems.CharacterIndex, characterHelper.GetPartyMembersFinalIndex(ccItems.config)) > characterHelper.GetPartyMembersFinalIndex(ccItems.config) then -- this is just a workaround
					if editValue._EditKeyHash == 2846328871 then -- chest shape
						newEditValue = editValue._Value + 50
					elseif editValue._EditKeyHash == 1673052757 then -- chest size
						newEditValue = editValue._Value / 2.5
					elseif editValue._EditKeyHash == 4061319525 then -- chest height
						newEditValue = editValue._Value + 50
					elseif editValue._EditKeyHash == 3467158119 then -- chest thickness
						newEditValue = editValue._Value
					else
						newEditValue = editValue._Value
					end
					--if newEditValue > 100 then
					--	newEditValue = 100
					--elseif newEditValue < -100 then
					--	newEditValue = -100
					--end
				else
					newEditValue = editValue._Value
				end
				if editor.setEditValue then
					editor:setEditValue(editValue._EditKeyHash, newEditValue, false)
				elseif editor._BodyEdit and editor._BodyEdit[editValue._EditKeyHash] then
					editor._BodyEdit[editValue._EditKeyHash] = newEditValue
				elseif editor._FaceEdit and editor._FaceEdit[editValue._EditKeyHash] then
					editor._FaceEdit[editValue._EditKeyHash] = newEditValue
				end
				if editor.applyEdit then
					editor:applyEdit()
				end
			else
				if editor.setEditValue then
					editor:setEditValue(editValue._EditKeyHash, editValue._Value)
				elseif editor._BodyEdit and editor._BodyEdit[editValue._EditKeyHash] then
					editor._BodyEdit[editValue._EditKeyHash] = newEditValue
				elseif editor._FaceEdit and editor._FaceEdit[editValue._EditKeyHash] then
					editor._FaceEdit[editValue._EditKeyHash] = newEditValue
				end
			end
		end
		isEdited = true
	end
	return isEdited
end

local function EditCharacterHeadAndBodyUsingCustomData(ccItems, headFaceEditCustomData, bodyEditorBodyEditCustomData, bodyEditorPretenderCustomData, editType)
	local isCompletelyEdited = true
	local isEdited
	local headObject
	--if ccItems.BodyEditor then
	--	local bodyEditorObject = ccItems.BodyEditor:get_GameObject()
	--	local bodyEditorObjectTransform = bodyEditorObject:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
	--	headObject = bodyEditorObjectTransform:find("head")
	--end
	if not headObject and ccItems.Transform then
		headObject = ccItems.Transform:find("head"):get_GameObject()
	end
	if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.BODYANDBODYDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BODY) then
		if ccItems.BodyEditor then
			StartBodyEdits(ccItems, ccItems.BodyEditor)
			--ccItems.BodyEditor:call("restore(app.BodyEditContext, app.PretenderContext)", bodyEditorBodyEditCustomData, bodyEditorPretenderCustomData)
			if ccItems.EditContexts and ccItems.BodyEditor._BodyEditContext and ccItems.BodyEditor._PretenderContext then
				--ccItems.BodyEditor._BodyEditContext:call("copyFrom(app.CharacterEditDefine.EditValue[])", bodyEditorBodyEditCustomData._EditValues)
				--ccItems.BodyEditor:call("restore(app.CharacterEditDefine.EditValue[])", ccItems.BodyEditor._BodyEditContext:get_EditValues())
				--if ccItems.IsUsingEditValueArray then
				--	isEdited = EditEditorDataUsingEditValueData(ccItems.BodyEditor._BodyEditContext, bodyEditorBodyEditCustomData._EditValues, false, true, ccItems, editType)
				--else
				if bodyEditorBodyEditCustomData then
					if not ccItems.IsCCDOnCCS then
						isEdited = EditEditorDataUsingEditValueDataTable(ccItems.BodyEditor._BodyEditContext, bodyEditorBodyEditCustomData._EditValues, false, true, ccItems, editType)
					else
						ccItems.BodyEditor._BodyEditContext:call("copyFrom(app.CharacterEditDefine.EditValue[])", bodyEditorBodyEditCustomData._EditValues)
						isEdited = true
					end
				end
				EditPretender(ccItems.BodyEditor._PretenderContext, bodyEditorPretenderCustomData, ccItems)
				ccItems.BodyEditor:call("restore(app.BodyEditContext, app.PretenderContext))", ccItems.BodyEditor._BodyEditContext, ccItems.BodyEditor._PretenderContext)
				isEdited = true
			else
				--ccItems.BodyEditor:call("copyFrom(app.CharacterEditDefine.EditValue[])", bodyEditorBodyEditCustomData._EditValues)
				--if ccItems.IsUsingEditValueArray then
				--	isEdited = EditEditorDataUsingEditValueData(ccItems.BodyEditor, bodyEditorBodyEditCustomData._EditValues, false, false, ccItems, editType)
				--else
				if bodyEditorBodyEditCustomData then
					if not ccItems.IsCCDOnCCS then
						isEdited = EditEditorDataUsingEditValueDataTable(ccItems.BodyEditor, bodyEditorBodyEditCustomData._EditValues, false, false, ccItems, editType)
					else
						ccItems.BodyEditor:call("restore(app.CharacterEditDefine.EditValue[])", bodyEditorBodyEditCustomData._EditValues)
						isEdited = true
					end
				end
				EditPretender(ccItems.BodyEditor._PretenderData, bodyEditorPretenderCustomData, ccItems)
			end
			EndBodyEdits(ccItems, ccItems.BodyEditor)
			isCompletelyEdited = isCompletelyEdited and isEdited
			if headObject then
				local headBodyEditor = headObject:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
				if headBodyEditor then
					StartBodyEdits(ccItems, headBodyEditor)
					if ccItems.EditContexts and headBodyEditor._BodyEditContext and headBodyEditor._PretenderContext then
						--if ccItems.IsUsingEditValueArray then
						--	isEdited = EditEditorDataUsingEditValueData(headBodyEditor._BodyEditContext, bodyEditorBodyEditCustomData._EditValues, false, true, ccItems, editType)
						--else
							isEdited = EditEditorDataUsingEditValueDataTable(headBodyEditor._BodyEditContext, bodyEditorBodyEditCustomData._EditValues, false, true, ccItems, editType)
						--end
						EditPretender(headBodyEditor._PretenderContext, bodyEditorPretenderCustomData, ccItems)
						headBodyEditor:call("restore(app.BodyEditContext, app.PretenderContext))", headBodyEditor._BodyEditContext, headBodyEditor._PretenderContext)
					else
						headBodyEditor:copyEditValueFrom(ccItems.BodyEditor)
					end
					EndBodyEdits(ccItems, headBodyEditor)
				--else
				--	isCompletelyEdited = false
				end
			end
		else
			isCompletelyEdited = false
		end
	end
	if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS) and headFaceEditCustomData then
		if headObject then
			local faceEditor = headObject:call("getComponent(System.Type)", sdk.typeof("app.FaceEditor"))
			if faceEditor then
				StartFaceEdits(ccItems, faceEditor)
				--faceEditor:call("restore(app.FaceEditContext)", headFaceEditCustomData) --crashes the game when using CharacterManager data
				if ccItems.EditContexts and faceEditor._Context then
					--faceEditor._Context:call("copyFrom(app.CharacterEditDefine.EditValue[])", headFaceEditCustomData._EditValues)
					--if ccItems.IsUsingEditValueArray then
					--	EditEditorDataUsingEditValueData(faceEditor._Context, headFaceEditCustomData._EditValues, false, true, ccItems, editType)
					--else
						EditEditorDataUsingEditValueDataTable(faceEditor._Context, headFaceEditCustomData._EditValues, false, true, ccItems, editType)
					--end
					isEdited = EditEditorDataUsingEditValueData(faceEditor, faceEditor._Context._EditValues, false, false, ccItems, editType)
				else
					--if ccItems.IsUsingEditValueArray then
					--	isEdited = EditEditorDataUsingEditValueData(faceEditor, headFaceEditCustomData._EditValues, false, false, ccItems, editType)
					--else
						isEdited = EditEditorDataUsingEditValueDataTable(faceEditor, headFaceEditCustomData._EditValues, false, false, ccItems, editType)
					--end
				end
				EndFaceEdits(ccItems, faceEditor)
				isCompletelyEdited = isCompletelyEdited and isEdited
			else
				isCompletelyEdited = false
			end
		else
			isCompletelyEdited = false
		end
	end
	return isCompletelyEdited
end

--USED IN CLONER
--CCS = CharacterCustomizationScreen
local function EditCharacterHeadAndBodyUsingNPCDetailsCCS(ccItems, charaID, appearanceID, editType)
	local isCompletelyEdited = true
	local headObject
	if ccItems.Transform then
		headObject = ccItems.Transform:find("head"):get_GameObject()
	end
	if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.BODYANDBODYDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BODY) then
		if ccItems.BodyEditor then
			--if ccItems.appearanceData then
			--	EditEditorDataUsingEditValueData(ccItems.BodyEditor, ccItems.appearanceData._BodyEdit, true, false, ccItems, editType)
			--end
			ccItems.BodyEditor:call("restore(app.CharacterID, System.Byte)", charaID, appearanceID)
			if headObject then
				local headBodyEditor = headObject:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
				if headBodyEditor then
					headBodyEditor:copyEditValueFrom(ccItems.BodyEditor)
				else
					isCompletelyEdited = false
				end
			end
		else
			isCompletelyEdited = false
		end
	end
	if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.FACE) then
		if headObject then
			local faceEditor = headObject:call("getComponent(System.Type)", sdk.typeof("app.FaceEditor"))
			if faceEditor then
				faceEditor:call("restore(app.CharacterID, System.Byte)", charaID, appearanceID)
			else
				isCompletelyEdited = false
			end
		else
			isCompletelyEdited = false
		end
	end
	return isCompletelyEdited
end

local function EditCharacterHeadAndBodyUsingNPCDetails(ccItems, charaID, appearanceID, editType)
	local isCompletelyEdited = true
	local isEdited
	local headObject
	--if ccItems.BodyEditor then
	--	local bodyEditorObject = ccItems.BodyEditor:get_GameObject()
	--	local bodyEditorObjectTransform = bodyEditorObject:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
	--	headObject = bodyEditorObjectTransform:find("head")
	--end
	if not headObject and ccItems.Transform then
		headObject = ccItems.Transform:find("head"):get_GameObject()
	end
	local appearanceData = GetAppearanceData(charaID, appearanceID)
	if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.BODYANDBODYDETAILS or editType == ENUMS.CHARACTEREDITTYPE.BODY) then
		if ccItems.BodyEditor then
			--if ccItems.CharacterIndex > characterHelper.GetPartyMembersFinalIndex(ccItems.config) then --and common.SpamRequestCheckPassed("bodyEditor", 3) then
			--	ccItems.BodyEditor:call("restore(app.CharacterID, System.Byte)", charaID, appearanceID)
			if appearanceData then
				StartBodyEdits(ccItems, ccItems.BodyEditor)
				if ccItems.EditContexts and ccItems.BodyEditor._BodyEditContext and ccItems.BodyEditor._PretenderContext then
					--ccItems.BodyEditor._BodyEditContext:call("copyFrom(app.CharacterEditDefine.EditValue[])", appearanceData._BodyEdit)
					--ccItems.BodyEditor:call("restore(app.CharacterEditDefine.EditValue[])", ccItems.BodyEditor._BodyEditContext:get_EditValues())
					isEdited = EditEditorDataUsingEditValueData(ccItems.BodyEditor._BodyEditContext, appearanceData._BodyEdit, true, true, ccItems, editType)
					EditPretender(ccItems.BodyEditor._PretenderContext, appearanceData._Pretender, ccItems)
					ccItems.BodyEditor:call("restore(app.BodyEditContext, app.PretenderContext))", ccItems.BodyEditor._BodyEditContext, ccItems.BodyEditor._PretenderContext)
					isEdited = true
				else
					--ccItems.BodyEditor:call("copyFrom(app.CharacterEditDefine.EditValue[])", appearanceData._BodyEdit)
					isEdited = EditEditorDataUsingEditValueData(ccItems.BodyEditor, appearanceData._BodyEdit, true, false, ccItems, editType)
					EditPretender(ccItems.BodyEditor._PretenderData, appearanceData._Pretender, ccItems)
				end
				EndBodyEdits(ccItems, ccItems.BodyEditor)
				isCompletelyEdited = isCompletelyEdited and isEdited
			--else
			--	isCompletelyEdited = false
			end
			if headObject then
				local headBodyEditor = headObject:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
				if headBodyEditor then
					StartBodyEdits(ccItems, headBodyEditor)
					if ccItems.EditContexts and headBodyEditor._BodyEditContext and headBodyEditor._PretenderContext then
						isEdited = EditEditorDataUsingEditValueData(headBodyEditor._BodyEditContext, appearanceData._BodyEdit, true, true, ccItems, editType)
						EditPretender(headBodyEditor._PretenderContext, appearanceData._Pretender, ccItems)
						headBodyEditor:call("restore(app.BodyEditContext, app.PretenderContext))", headBodyEditor._BodyEditContext, headBodyEditor._PretenderContext)
					else
						headBodyEditor:copyEditValueFrom(ccItems.BodyEditor)
					end
					EndBodyEdits(ccItems, headBodyEditor)
				--else
				--	isCompletelyEdited = false
				end
			end
		else
			isCompletelyEdited = false
		end
	end
	if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.ALLEXCEPTCOSTUME or editType == ENUMS.CHARACTEREDITTYPE.HEADANDDETAILS or editType == ENUMS.CHARACTEREDITTYPE.FACE) then
		if headObject then --and appearanceData then
			local faceEditor = headObject:call("getComponent(System.Type)", sdk.typeof("app.FaceEditor"))
			if faceEditor then
				--if ccItems.CharacterIndex > characterHelper.GetPartyMembersFinalIndex(ccItems.config) and common.SpamRequestCheckPassed("faceEditor", 3) then
				--	faceEditor:call("restore(app.CharacterID, System.Byte)", charaID, appearanceID) -- crashes randomly :(
				if appearanceData then
					StartFaceEdits(ccItems, faceEditor)
					if ccItems.EditContexts and faceEditor._Context then
						--faceEditor._Context:call("copyFrom(app.CharacterEditDefine.EditValue[])", appearanceData._FaceEdit)
						EditEditorDataUsingEditValueData(faceEditor._Context, appearanceData._FaceEdit, true, true, ccItems, editType)
						isEdited = EditEditorDataUsingEditValueData(faceEditor, faceEditor._Context._EditValues, false, false, ccItems, editType)
					else
						isEdited = EditEditorDataUsingEditValueData(faceEditor, appearanceData._FaceEdit, true, false, ccItems, editType)
					end
					EndFaceEdits(ccItems, faceEditor)
					isCompletelyEdited = isCompletelyEdited and isEdited
				--else
				--	isCompletelyEdited = false
				end
			else
				isCompletelyEdited = false
			end
		else
			isCompletelyEdited = false
		end
	end
	return isCompletelyEdited
end

local function EditPartSwapperUsingCustomData(ccItems, partSwapperHumanCustomData, editType)
	local isCompletelyEdited = false
	local isEdited

	if ccItems.PartSwapper and partSwapperHumanCustomData then
		--ccItems.PartSwapper:call("restore(app.PartSwapHumanContext)", partSwapperHumanCustomData)
		StartPartSwapperEdits(ccItems)
		isEdited = EditAppearanceMeta(ccItems.PartSwapper._Meta, partSwapperHumanCustomData._Meta, editType)
		if ccItems.EditContexts and ccItems.PartSwapper._HumanContext then
			EditCostumeMeta(ccItems.PartSwapper._HumanContext._Meta, partSwapperHumanCustomData._Meta, editType)
		end
		isCompletelyEdited = isEdited
		isEdited = EditCostumeMeta(ccItems.PartSwapper._Meta, partSwapperHumanCustomData._Meta, editType)
		if ccItems.EditContexts and ccItems.PartSwapper._HumanContext then
			EditAppearanceMeta(ccItems.PartSwapper._HumanContext._Meta, partSwapperHumanCustomData._Meta, editType)
		end
		isCompletelyEdited = isCompletelyEdited and isEdited
		EndPartSwapperEdits(ccItems)
	end
	return isCompletelyEdited
end

--USED IN CLONER
local function EditPartSwapperUsingNPCDetails(ccItems, charaID, appearanceID, costumeID, editType)
	local isCompletelyEdited = false
	local isEdited
	if ccItems.PartSwapper then
		--if (editType == ENUMS.CHARACTEREDITTYPE.ALL) then
		--	ccItems.PartSwapper:call("restore(app.CharacterID, System.Byte, System.Byte)", charaID, appearanceID, costumeID)  -- this somehow conflicts with CharacterManager (this will not function properly after CharacterManager data is applied)
		--	isCompletelyEdited = true
		--else
			StartPartSwapperEdits(ccItems)
			isEdited = EditCostumeMeta(ccItems.PartSwapper._Meta, GetCostumeData(charaID, costumeID), editType)
			if ccItems.EditContexts and ccItems.PartSwapper._HumanContext then
				EditCostumeMeta(ccItems.PartSwapper._HumanContext._Meta, GetCostumeData(charaID, costumeID), editType)
			end
			isCompletelyEdited = isEdited
			isEdited = EditAppearanceMeta(ccItems.PartSwapper._Meta, GetAppearanceData(charaID, appearanceID), editType)
			if ccItems.EditContexts and ccItems.PartSwapper._HumanContext then
				EditAppearanceMeta(ccItems.PartSwapper._HumanContext._Meta, GetAppearanceData(charaID, appearanceID), editType)
			end
			isCompletelyEdited = isCompletelyEdited and isEdited
			EndPartSwapperEdits(ccItems)
		--end
	else
		isCompletelyEdited = false
	end
	return isCompletelyEdited
end

--USED IN CLONER
--CCS = CharacterCustomizationScreen
local function EditCharacterDataUsingNPCDetailsCCS(ccItems, charaID, appearanceID, costumeID, editType)
	local isCompletelyEdited = true
	local appearanceData = GetAppearanceData(charaID, appearanceID)
	local costumeData = GetCostumeData(charaID, costumeID)
	if not appearanceData then
		appearanceID = 0
		if (editType ~= ENUMS.CHARACTEREDITTYPE.COSTUME) then
			isCompletelyEdited = false
		end
	end
	if not costumeData then
		costumeID = 0
		if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.COSTUME) then
			isCompletelyEdited = false
		end
	end
	StartPartSwapperEdits(ccItems)
	if not EditPartSwapperUsingNPCDetails(ccItems, charaID, appearanceID, costumeID, editType) then
		isCompletelyEdited = false
	end
	EndPartSwapperEdits(ccItems)
	ccItems.appearanceData = appearanceData
	if not EditCharacterHeadAndBodyUsingNPCDetailsCCS(ccItems, charaID, appearanceID, editType) then
		isCompletelyEdited = false
	end
	if not EditCharacterBodyDetailsUsingAppearanceData(ccItems, appearanceData, editType) then
		isCompletelyEdited = false
	end
	return isCompletelyEdited
end

local function EditCharacterDataUsingNPCDetails(character, ccItems, charaID, appearanceID, costumeID, editType, cloneOrMockupBuilder)
	local isCompletelyEdited = true
	local appearanceData = GetAppearanceData(charaID, appearanceID)
	local costumeData = GetCostumeData(charaID, costumeID)
	if not appearanceData then
		appearanceID = 0
		if (editType ~= ENUMS.CHARACTEREDITTYPE.COSTUME) then
			isCompletelyEdited = false
		end
	end
	if not costumeData then
		costumeID = 0
		if (editType == ENUMS.CHARACTEREDITTYPE.ALL or editType == ENUMS.CHARACTEREDITTYPE.COSTUME) then
			isCompletelyEdited = false
		end
	end
	StartPartSwapperEdits(ccItems)
	--if not EditPartSwapperUsingNPCDetails(ccItems, charaID, appearanceID, costumeID, editType) then
	--	isCompletelyEdited = false
	--end
	if not EditCharacterAppearanceMeta(character, appearanceData, editType, cloneOrMockupBuilder) then
		isCompletelyEdited = false
	end
	if not EditCharacterCostumeMeta(character, costumeData, editType, cloneOrMockupBuilder) then
		isCompletelyEdited = false
	end
	EndPartSwapperEdits(ccItems)
	if not EditCharacterHeadAndBodyUsingNPCDetails(ccItems, charaID, appearanceID, editType) then
		isCompletelyEdited = false
	end
	--if not EditCharacterBodyDetailsUsingCustomData(ccItems, appearanceData, editType) then
	if not EditCharacterBodyDetailsUsingAppearanceData(ccItems, appearanceData, editType) then
		isCompletelyEdited = false
	end
	return isCompletelyEdited
end

--USED IN CLONER
local function EditCharacterFromAnywhereUsingCustomData(character, characterIndex, faceEditorCustomData, bodyEditorBodyEditCustomData, bodyEditorPretenderCustomData, partSwapperHumanCustomData, bodyDetailCustomData, editType, additionalParameters)
	local isCompletelyEdited = false
	local isEdited
	if (character or (additionalParameters and additionalParameters.cloneOrMockupBuilder)) then
		local ccItems = GetCharacterCustomizationItems(character, additionalParameters)
		ccItems.CharacterIndex = characterIndex
		ccItems.IsUsingEditValueArray = additionalParameters.isUsingEditValueArray
		ccItems.IsCCDOnCCS = additionalParameters.isCCDOnCCS
		if additionalParameters.sourceCharacterIsNotContext then
			ccItems.FurPatternBodyDetailName = "_FurPatterns"
			ccItems.TattoosSlotDatasName = "_Tattoos"
			ccItems.ScarsSlotDatasName = "_Scars"
		else
			ccItems.FurPatternBodyDetailName = "_FurPattern"
			ccItems.TattoosSlotDatasName = "_SlotDatas"
			ccItems.ScarsSlotDatasName = "_SlotDatas"
		end
		if additionalParameters.doNotParseColors then
			ccItems.ParseColors = false
		else
			ccItems.ParseColors = true
		end
		CharacterEditManagerRequestLimiterRemoval()
		StartPartSwapperEdits(ccItems)
		isEdited = EditPartSwapperUsingCustomData(ccItems, partSwapperHumanCustomData, editType)
		isCompletelyEdited = isCompletelyEdited and isEdited
		EndPartSwapperEdits(ccItems)
		isEdited = EditCharacterHeadAndBodyUsingCustomData(ccItems, faceEditorCustomData, bodyEditorBodyEditCustomData, bodyEditorPretenderCustomData, editType)
		isCompletelyEdited = isCompletelyEdited and isEdited
		isEdited = EditCharacterBodyDetailsUsingCustomData(ccItems, bodyDetailCustomData, partSwapperHumanCustomData, editType)
		isCompletelyEdited = isEdited
	end
	return isCompletelyEdited
end

--USED IN CLONER
--CCS = CharacterCustomizationScreen
local function EditCharacterUsingCharacterCustomizationData(sourceCharacter, ccItems, editType, additionalParameters)
	local isCompletelyEdited = true
	if editType == 15 then
		editType = ENUMS.CHARACTEREDITTYPE.COSTUME
		isCompletelyEdited = false
	end
	local characterCustomizationData
	local isEdited = false
	characterCustomizationData = GetCharacterCustomizationData(sourceCharacter, additionalParameters)
	additionalParameters.sourceCharacterIsNotContext = not characterCustomizationData["IsBodyDetailContext"]
	isEdited = EditPartSwapperUsingCustomData(ccItems, characterCustomizationData["PartSwapperHuman"], editType)
	isCompletelyEdited = isEdited
	isEdited = EditCharacterHeadAndBodyUsingCustomData(ccItems, characterCustomizationData["HeadFaceEditor"], characterCustomizationData["BodyEditorBodyEdit"], characterCustomizationData["BodyEditorPretender"], editType)
	isCompletelyEdited = isCompletelyEdited and isEdited
	isEdited = EditCharacterBodyDetailsUsingCustomData(ccItems, characterCustomizationData["BodyDetailEditor"], characterCustomizationData["PartSwapperHuman"], editType)
	isCompletelyEdited = isCompletelyEdited and isEdited
	return isCompletelyEdited
end

--USED IN CLONER
local function EditCharacterFromCCSUsingNPCDetails(charaID, appearanceID, costumeID, editType, additionalParameters)
	local isCompletelyEdited = false
	local ccItems = GetCharacterCustomizationItemsCCS(additionalParameters)
	ccItems.CharacterIndex = nil
	ccItems.FurPatternBodyDetailName = "_FurPatterns"
	ccItems.TattoosSlotDatasName = "_Tattoos"
	ccItems.ScarsSlotDatasName = "_Scars"
	ccItems.ParseColors = false
	HumanEditControllerSetEditLimited(false)
	CharacterEditManagerRequestLimiterRemoval()
	isCompletelyEdited = EditCharacterDataUsingNPCDetailsCCS(ccItems, charaID, appearanceID, costumeID, editType)
	if false and not isCompletelyEdited and characterHelper then
		ccItems.CharacterIndex = 0
		ccItems.IsCCDOnCCS = true
		if additionalParameters.skipRequestSwap ~= nil then
			ccItems.SkipRequestSwap = additionalParameters.skipRequestSwap
		else
			ccItems.SkipRequestSwap = true
		end
		ccItems.IsUsingEditValueArray = false
		local sourceCharacter
		if not isCompletelyEdited and additionalParameters.npcCharID and not characterHelper.IsNPCOnly(additionalParameters.npcCharID) then
			sourceCharacter = characterHelper.GetCharacterByCharacterIDName(additionalParameters.npcCharID)
			if sourceCharacter then
				isCompletelyEdited = EditCharacterUsingCharacterCustomizationData(sourceCharacter, ccItems, CrashFix(additionalParameters.fixCode, editType, sourceCharacter), additionalParameters)
			end
		end
	end
	return isCompletelyEdited
end

local function EditCharacterFromAnywhereUsingCharacterCustomizationData(character, sourceCharacter, characterIndex, editType, additionalParameters)
	local isCompletelyEdited = true
	if editType == 15 then
		editType = ENUMS.CHARACTEREDITTYPE.COSTUME
		isCompletelyEdited = false
	end
	local characterCustomizationData
	characterCustomizationData = GetCharacterCustomizationData(sourceCharacter, additionalParameters)
	additionalParameters.sourceCharacterIsNotContext = not characterCustomizationData["IsBodyDetailContext"]
	if not EditCharacterFromAnywhereUsingCustomData(character, characterIndex, characterCustomizationData["HeadFaceEditor"], characterCustomizationData["BodyEditorBodyEdit"], characterCustomizationData["BodyEditorPretender"], characterCustomizationData["PartSwapperHuman"], characterCustomizationData["BodyDetailEditor"], editType, additionalParameters) then
		isCompletelyEdited = false
	end
	return isCompletelyEdited
end

local function EditCharacterFromAnywhereUsingNPCDetails(character, characterIndex, charaID, appearanceID, costumeID, editType, additionalParameters)
	local isCompletelyEdited = false
	if (character or (additionalParameters and additionalParameters.cloneOrMockupBuilder)) and charaID then
		local sourceCharacter
		if common.GetBooleanValue(additionalParameters.CopyCurrentAvailableCharacter) then
			sourceCharacter = characterHelper.GetCharacterByCharaID(charaID)
		end
		if sourceCharacter then
			isCompletelyEdited = EditCharacterFromAnywhereUsingCharacterCustomizationData(character, sourceCharacter, characterIndex, CrashFix(additionalParameters.fixCode, editType, sourceCharacter), additionalParameters)
		else
			local ccItems = GetCharacterCustomizationItems(character, additionalParameters)
			ccItems.CharacterIndex = characterIndex
			ccItems.FurPatternBodyDetailName = "_FurPatterns"
			ccItems.TattoosSlotDatasName = "_Tattoos"
			ccItems.ScarsSlotDatasName = "_Scars"
			ccItems.ParseColors = false
			if additionalParameters.skipRequestSwap ~= nil then
				ccItems.SkipRequestSwap = additionalParameters.skipRequestSwap
			else
				ccItems.SkipRequestSwap = true
			end
			CharacterEditManagerRequestLimiterRemoval()
			if additionalParameters then
				isCompletelyEdited = EditCharacterDataUsingNPCDetails(character, ccItems, charaID, appearanceID, costumeID, editType, additionalParameters.cloneOrMockupBuilder)
			else
				isCompletelyEdited = EditCharacterDataUsingNPCDetails(character, ccItems, charaID, appearanceID, costumeID, editType, nil)
			end
			if not isCompletelyEdited and characterHelper and not characterHelper.IsNPCOnly(additionalParameters.npcCharID) then
				local sourceCharacter
				if not isCompletelyEdited and additionalParameters.npcCharID then
					sourceCharacter = characterHelper.GetCharacterByCharacterIDName(additionalParameters.npcCharID)
					if sourceCharacter then
						additionalParameters.doNotParseColors = true
						isCompletelyEdited = EditCharacterFromAnywhereUsingCharacterCustomizationData(character, sourceCharacter, characterIndex, CrashFix(additionalParameters.fixCode, editType, sourceCharacter), additionalParameters)
					end
				end
			end
		end
	end
	return isCompletelyEdited
end

local function GetRemoveUnknownGenderStyles()
	return removeUnknownGenderStyles
end

local function SetRemoveUnknownGenderStyles(shouldRemove)
	removeUnknownGenderStyles = shouldRemove
end

local function ResetCostume(character, additionalParameters)

	local isEdited = false
	local ccItems

	if (character or (additionalParameters and additionalParameters.cloneOrMockupBuilder)) then
		ccItems = GetCharacterCustomizationItems(character, additionalParameters)
	end

	if ccItems then

		if ccItems.PartSwapper then

			local costumeDetails = GetCostumeMeta(ccItems.PartSwapper._Meta)
			local defaultCostumeDetails = GetDefaultCostumeMeta()

			costumeDetails._HelmStyle = defaultCostumeDetails._HelmStyle
			costumeDetails._FacewearStyle = defaultCostumeDetails._FacewearStyle
			costumeDetails._TopsStyle = defaultCostumeDetails._TopsStyle
			costumeDetails._MantleStyle = defaultCostumeDetails._MantleStyle
			costumeDetails._PantsStyle = defaultCostumeDetails._PantsStyle

			local characterItemData = GetCharacterItemData(character)
			if characterItemData._HelmStyle then
				costumeDetails._HelmStyle = characterItemData._HelmStyle
			end
			if characterItemData._FacewearStyle then
				costumeDetails._FacewearStyle = characterItemData._FacewearStyle
			end
			if characterItemData._TopsStyle then
				costumeDetails._TopsStyle = characterItemData._TopsStyle
			end
			if characterItemData._MantleStyle then
				costumeDetails._MantleStyle = characterItemData._MantleStyle
			end
			if characterItemData._PantsStyle then
				costumeDetails._PantsStyle = characterItemData._PantsStyle
			end

			costumeDetails._HelmVariationStyle = defaultCostumeDetails._HelmVariationStyle
			costumeDetails._FacewearVariationStyle = defaultCostumeDetails._FacewearVariationStyle
			costumeDetails._TopsVariationStyle = defaultCostumeDetails._TopsVariationStyle
			costumeDetails._BackpackStyle = defaultCostumeDetails._BackpackStyle
			costumeDetails._PantsVariationStyle = defaultCostumeDetails._PantsVariationStyle
			costumeDetails._MantleVariationStyle = defaultCostumeDetails._MantleVariationStyle
			costumeDetails._UnderwearStyle = defaultCostumeDetails._UnderwearStyle
			costumeDetails._UnderwearVariationStyle = defaultCostumeDetails._UnderwearVariationStyle

			isEdited =  EditCostumePartSwapperMeta(ccItems, costumeDetails, ENUMS.CHARACTEREDITTYPE.COSTUME)

		end

	end

	return isEdited

end

local function GetCharacterObjectMeshDetailsItem(characterObjectMeshDetails, itemName)
	if characterObjectMeshDetails then
		for meshDetailsKeys, meshDetailsItem in pairs(characterObjectMeshDetails) do
			if meshDetailsItem.Name == itemName then
				return meshDetailsItem
			end
		end
	end
	return nil
end

local function IsMeshIDNameChanged(characterObjectMeshDetails, itemName)
	if characterObjectMeshDetails then
		local characterObjectMeshDetailsItem = GetCharacterObjectMeshDetailsItem(characterObjectMeshDetails, itemName)
		if characterObjectMeshDetailsItem and characterObjectMeshDetailsItem.MeshIDNameChanged then
			return true
		end
	end
	return false
end

local function IsMeshIDNamesChanged(characterObjectMeshDetails)
	if characterObjectMeshDetails then
		for meshDetailsKeys, meshDetailsItem in pairs(characterObjectMeshDetails) do
			if meshDetailsItem.MeshIDNameChanged then
				return true
			end
		end
	end
	return false
end

local function GetSwapItem(swapItemSearchType, swapItemSearchParameter, swapItemSearchParameter2, swapItemGender)
	local swapItem
	if swapItemSearchParameter then
		local CharacterEditManager = sdk.get_managed_singleton("app.CharacterEditManager")
		if swapItemSearchParameter2 == "Tops"
			or swapItemSearchParameter2 == "_TopsBdMesh"
			or swapItemSearchParameter2 == "_TopsBdSubMesh"
			or swapItemSearchParameter2 == "_TopsWbMesh"
			or swapItemSearchParameter2 == "_TopsWbSubMesh"
			or swapItemSearchParameter2 == "_TopsAmMesh"
			or swapItemSearchParameter2 == "_TopsAmSubMesh"
			or swapItemSearchParameter2 == "_TopsBtMesh"
			or swapItemSearchParameter2 == "_TopsBtSubMesh" then
			local swapItemCollectionItemEnum = CharacterEditManager._TopsDB:GetEnumerator()
			while swapItemCollectionItemEnum:MoveNext() == true do
				local currentSwapItemCollectionItemEnum = swapItemCollectionItemEnum:get_Current()
				local swapItemCollection = currentSwapItemCollectionItemEnum.value
				local swapItemCollectionValues = swapItemCollection:get_Values()
				local swapItemCollectionValuesEnum = swapItemCollectionValues:GetEnumerator()
				while swapItemCollectionValuesEnum:MoveNext() == true do
					local item = swapItemCollectionValuesEnum:get_Current()
					if (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.STYLE and swapItemSearchParameter== item._TopsStyle and swapItemGender == item._Gender)
						or ((swapItemSearchParameter2 == "_TopsBdMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._BdMeshID))
							or (swapItemSearchParameter2 == "_TopsBdSubMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._BdSubMeshID))
							or (swapItemSearchParameter2 == "_TopsWbMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._WbMeshID))
							or (swapItemSearchParameter2 == "_TopsWbSubMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._WbSubMeshID))
							or (swapItemSearchParameter2 == "_TopsAmMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._AmMeshID))
							or (swapItemSearchParameter2 == "_TopsAmSubMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._AmSubMeshID))
							or (swapItemSearchParameter2 == "_TopsBtMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._BtMeshID))
							or (swapItemSearchParameter2 == "_TopsBtSubMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._BtSubMeshID))) then
						swapItem = item
						break
					end
				end
			end
		elseif swapItemSearchParameter2 == "Pants"
			or swapItemSearchParameter2 == "_PantsLgMesh"
			or swapItemSearchParameter2 == "_PantsLgSubMesh"
			or swapItemSearchParameter2 == "_PantsWlMesh"
			or swapItemSearchParameter2 == "_PantsWlSubMesh" then
			local swapItemCollectionItemEnum = CharacterEditManager._PantsDB:GetEnumerator()
			while swapItemCollectionItemEnum:MoveNext() == true do
				local currentSwapItemCollectionItemEnum = swapItemCollectionItemEnum:get_Current()
				local swapItemCollection = currentSwapItemCollectionItemEnum.value
				local swapItemCollectionValues = swapItemCollection:get_Values()
				local swapItemCollectionValuesEnum = swapItemCollectionValues:GetEnumerator()
				while swapItemCollectionValuesEnum:MoveNext() == true do
					local item = swapItemCollectionValuesEnum:get_Current()
					if (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.STYLE and swapItemSearchParameter== item._PantsStyle and swapItemGender == item._Gender)
						or ((swapItemSearchParameter2 == "_PantsLgMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._LgMeshID))
							or (swapItemSearchParameter2 == "_PantsLgSubMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._LgSubMeshID))
							or (swapItemSearchParameter2 == "_PantsWlMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._WlMeshID))
							or (swapItemSearchParameter2 == "_PantsWlSubMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._WlSubMeshID))) then
						swapItem = item
						break
					end
				end
			end
		elseif swapItemSearchParameter2 == "Helm"
			or swapItemSearchParameter2 == "_HelmMesh"
			or swapItemSearchParameter2 == "_HelmSubMesh" then
			local swapItemCollectionItemEnum = CharacterEditManager._HelmDB:GetEnumerator()
			while swapItemCollectionItemEnum:MoveNext() == true do
				local currentSwapItemCollectionItemEnum = swapItemCollectionItemEnum:get_Current()
				local swapItemCollection = currentSwapItemCollectionItemEnum.value
				local swapItemCollectionValues = swapItemCollection:get_Values()
				local swapItemCollectionValuesEnum = swapItemCollectionValues:GetEnumerator()
				while swapItemCollectionValuesEnum:MoveNext() == true do
					local item = swapItemCollectionValuesEnum:get_Current()
					if (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.STYLE and swapItemSearchParameter== item._HelmStyle and swapItemGender == item._Gender)
						or ((swapItemSearchParameter2 == "_HelmMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._MeshID))
							or (swapItemSearchParameter2 == "_HelmSubMesh" and (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._SubMeshID))) then
						swapItem = item
						break
					end
				end
			end
		elseif swapItemSearchParameter2 == "Mantle"
			or swapItemSearchParameter2 == "_MantleMesh" then
			local swapItemCollectionItemEnum = CharacterEditManager._MantleDB:GetEnumerator()
			while swapItemCollectionItemEnum:MoveNext() == true do
				local currentSwapItemCollectionItemEnum = swapItemCollectionItemEnum:get_Current()
				local swapItemCollection = currentSwapItemCollectionItemEnum.value
				local swapItemCollectionValues = swapItemCollection:get_Values()
				local swapItemCollectionValuesEnum = swapItemCollectionValues:GetEnumerator()
				while swapItemCollectionValuesEnum:MoveNext() == true do
					local item = swapItemCollectionValuesEnum:get_Current()
					if (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.STYLE and swapItemSearchParameter== item._MantleStyle and swapItemGender == item._Gender)
						or (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._MeshID) then
						swapItem = item
						break
					end
				end
			end
		elseif swapItemSearchParameter2 == "Backpack"
			or swapItemSearchParameter2 == "_BackpackMesh" then
			local swapItemCollectionItemEnum = CharacterEditManager._BackpackDB:GetEnumerator()
			while swapItemCollectionItemEnum:MoveNext() == true do
				local currentSwapItemCollectionItemEnum = swapItemCollectionItemEnum:get_Current()
				local swapItemCollection = currentSwapItemCollectionItemEnum.value
				local swapItemCollectionValues = swapItemCollection:get_Values()
				local swapItemCollectionValuesEnum = swapItemCollectionValues:GetEnumerator()
				while swapItemCollectionValuesEnum:MoveNext() == true do
					local item = swapItemCollectionValuesEnum:get_Current()
					if (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.STYLE and swapItemSearchParameter== item._BackpackStyle and swapItemGender == item._Gender)
						or (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._MeshID) then
						swapItem = item
						break
					end
				end
			end
		elseif swapItemSearchParameter2 == "Facewear"
			or swapItemSearchParameter2 == "_FacewearMesh" then
			local swapItemCollectionItemEnum = CharacterEditManager._FacewearDB:GetEnumerator()
			while swapItemCollectionItemEnum:MoveNext() == true do
				local currentSwapItemCollectionItemEnum = swapItemCollectionItemEnum:get_Current()
				local swapItemCollection = currentSwapItemCollectionItemEnum.value
				local swapItemCollectionValues = swapItemCollection:get_Values()
				local swapItemCollectionValuesEnum = swapItemCollectionValues:GetEnumerator()
				while swapItemCollectionValuesEnum:MoveNext() == true do
					local item = swapItemCollectionValuesEnum:get_Current()
					if (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.STYLE and swapItemSearchParameter== item._FacewearStyle and swapItemGender == item._Gender)
						or (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._MeshID) then
						swapItem = item
						break
					end
				end
			end
		elseif swapItemSearchParameter2 == "Underwear"
			or swapItemSearchParameter2 == "_UnderwearMesh" then
			local swapItemCollectionItemEnum = CharacterEditManager._UnderwearDB:GetEnumerator()
			while swapItemCollectionItemEnum:MoveNext() == true do
				local currentSwapItemCollectionItemEnum = swapItemCollectionItemEnum:get_Current()
				local swapItemCollection = currentSwapItemCollectionItemEnum.value
				local swapItemCollectionValues = swapItemCollection:get_Values()
				local swapItemCollectionValuesEnum = swapItemCollectionValues:GetEnumerator()
				while swapItemCollectionValuesEnum:MoveNext() == true do
					local item = swapItemCollectionValuesEnum:get_Current()
					if (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.STYLE and swapItemSearchParameter== item._Style and swapItemGender == item._Gender)
						or (swapItemSearchType == ENUMS.SWAPITEMSEARCHTYPE.MESHID and swapItemSearchParameter == item._MeshID) then
						swapItem = item
						break
					end
				end
			end
		end
	end
	return swapItem
end

local function ResetCostumeMeshID(character, characterObjectMeshDetails, meshName)
	if character and characterObjectMeshDetails then
		local activeMockupDetails = common.GetActiveMockupDetails()
		local partSwapper = GetPartSwapper(character, activeMockupDetails.MockupBuilder, activeMockupDetails.MockupCtrl)
		if partSwapper then
			local costumeDetails = GetCostumeMeta(partSwapper._Meta)
			if costumeDetails then
				local gender
				if partSwapper._BodySkinSwapItem then
					gender = partSwapper._BodySkinSwapItem._Gender
				end
				local topsSwapItem = GetSwapItem(ENUMS.SWAPITEMSEARCHTYPE.STYLE, costumeDetails._TopsStyle, "Tops", gender)
				local pantsSwapItem = GetSwapItem(ENUMS.SWAPITEMSEARCHTYPE.STYLE, costumeDetails._PantsStyle, "Pants", gender)
				local helmSwapItem = GetSwapItem(ENUMS.SWAPITEMSEARCHTYPE.STYLE, costumeDetails._HelmStyle, "Helm", gender)
				local mantleSwapItem = GetSwapItem(ENUMS.SWAPITEMSEARCHTYPE.STYLE, costumeDetails._MantleStyle, "Mantle", gender)
				local backpackSwapItem = GetSwapItem(ENUMS.SWAPITEMSEARCHTYPE.STYLE, costumeDetails._BackpackStyle, "Backpack", gender)
				local facewearSwapItem = GetSwapItem(ENUMS.SWAPITEMSEARCHTYPE.STYLE, costumeDetails._FacewearStyle, "Facewear", gender)
				local underwearSwapItem = GetSwapItem(ENUMS.SWAPITEMSEARCHTYPE.STYLE, costumeDetails._UnderwearStyle, "Underwear", gender) --partSwapper._UnderwearSwapItem._Gender)
				for meshDetailsKeys, meshDetailsItem in pairs(characterObjectMeshDetails) do
					if meshDetailsItem.Name == meshName or meshName == "ALL" then
						local tempMeshName = meshDetailsItem.Name
						if tempMeshName then
							tempMeshName = string.gsub(tempMeshName, "_", "")
						else
							tempMeshName = ""
						end
						local meshNameIDs = ENUMS[tempMeshName .. "IDs"]
						meshDetailsItem.ResetMeshIDName = true
						if meshNameIDs then
							meshDetailsItem.MeshIDNameChanged = true
							meshDetailsItem.MeshIDName = "None"
							if meshDetailsItem.Name == "_TopsBdMesh" and topsSwapItem and topsSwapItem:get_HasBdMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[topsSwapItem._BdMeshID]
							elseif meshDetailsItem.Name == "_TopsBdSubMesh" and topsSwapItem and topsSwapItem:get_HasBdSubMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[topsSwapItem._BdSubMeshID]
							elseif meshDetailsItem.Name == "_TopsWbMesh" and topsSwapItem and topsSwapItem:get_HasWbMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[topsSwapItem._WbMeshID]
							elseif meshDetailsItem.Name == "_TopsWbSubMesh" and topsSwapItem and topsSwapItem:get_HasWbSubMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[topsSwapItem._WbSubMeshID]
							elseif meshDetailsItem.Name == "_TopsAmMesh" and topsSwapItem and topsSwapItem:get_HasAmMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[topsSwapItem._AmMeshID]
							elseif meshDetailsItem.Name == "_TopsAmSubMesh" and topsSwapItem and topsSwapItem:get_HasAmSubMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[topsSwapItem._AmSubMeshID]
							elseif meshDetailsItem.Name == "_TopsBtMesh" and topsSwapItem and topsSwapItem:get_HasBtMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[topsSwapItem._BtMeshID]
							elseif meshDetailsItem.Name == "_TopsBtSubMesh" and topsSwapItem and topsSwapItem:get_HasBtSubMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[topsSwapItem._BtSubMeshID]
							--elseif meshDetailsItem.Name == "_TopsUwMesh" and topsSwapItem and topsSwapItem: then
							--	meshDetailsItem.MeshIDName = meshNameIDs[topsSwapItem.]
							elseif meshDetailsItem.Name == "_PantsLgMesh" and pantsSwapItem and pantsSwapItem:get_HasLgMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[pantsSwapItem._LgMeshID]
							elseif meshDetailsItem.Name == "_PantsLgSubMesh" and pantsSwapItem and pantsSwapItem:get_HasLgSubMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[pantsSwapItem._LgSubMeshID]
							elseif meshDetailsItem.Name == "_PantsWlMesh" and pantsSwapItem and pantsSwapItem:get_HasWlMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[pantsSwapItem._WlMeshID]
							elseif meshDetailsItem.Name == "_PantsWlSubMesh" and pantsSwapItem and pantsSwapItem:get_HasWlSubMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[pantsSwapItem._WlSubMeshID]
							elseif meshDetailsItem.Name == "_HelmMesh" and helmSwapItem and helmSwapItem:get_HasMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[helmSwapItem._MeshID]
							elseif meshDetailsItem.Name == "_HelmSubMesh" and helmSwapItem and helmSwapItem:get_HasSubMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[helmSwapItem._SubMeshID]
							elseif meshDetailsItem.Name == "_MantleMesh" and mantleSwapItem and mantleSwapItem:get_HasMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[mantleSwapItem._MeshID]
							elseif meshDetailsItem.Name == "_BackpackMesh" and backpackSwapItem and backpackSwapItem:get_HasMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[backpackSwapItem._MeshID]
							elseif meshDetailsItem.Name == "_FacewearMesh" and facewearSwapItem and facewearSwapItem:get_HasMesh() then
								meshDetailsItem.MeshIDName = meshNameIDs[facewearSwapItem._MeshID]
							elseif meshDetailsItem.Name == "_UnderwearMesh" and underwearSwapItem then
								meshDetailsItem.MeshIDName = meshNameIDs[underwearSwapItem._MeshID]
							end
						end
						if meshName ~= "ALL" then
							break
						end
					end
				end
			end
		end
	end
end

local function SwapCostumePartSwapper(character, characterIndex, mockupBuilder, mockupCtrl, characterObjectMeshDetails, config)
	if (character and character:get_Valid()) then
		local partSwapper = GetPartSwapper(character, mockupBuilder, mockupCtrl)
		local charaID
		if partSwapper then
			local swapTops = false
			local swapPants = false
			local swapHelm = false
			local swapMantle = false
			local swapBackpack = false
			local swapFacewear = false
			local swapUnderwear = false
			if partSwapper then
				for meshDetailsKeys, meshDetailsItem in pairs(characterObjectMeshDetails) do
					--if meshDetailsItem.MeshIDNameChanged then
						local characterObjectMeshes = meshDetailsItem.Name
						if characterObjectMeshes == "_TopsBdMesh"
							or characterObjectMeshes == "_TopsBdSubMesh"
							or characterObjectMeshes == "_TopsWbMesh"
							or characterObjectMeshes == "_TopsWbSubMesh"
							or characterObjectMeshes == "_TopsAmMesh"
							or characterObjectMeshes == "_TopsAmSubMesh"
							or characterObjectMeshes == "_TopsBtMesh"
							or characterObjectMeshes == "_TopsBtSubMesh"
							or characterObjectMeshes == "_TopsUwMesh" then
							meshDetailsItem.SwapTops = true
							swapTops = true
						elseif characterObjectMeshes == "_PantsLgMesh"
							or characterObjectMeshes == "_PantsLgSubMesh"
							or characterObjectMeshes == "_PantsWlMesh"
							or characterObjectMeshes == "_PantsWlSubMesh" then
							meshDetailsItem.SwapPants = true
							swapPants = true
						elseif characterObjectMeshes == "_HelmMesh"
							or characterObjectMeshes == "_HelmSubMesh" then
							meshDetailsItem.SwapHelm = true
							swapHelm = true
						elseif characterObjectMeshes == "_MantleMesh" then
							meshDetailsItem.SwapMantle = true
							swapMantle = true
						elseif characterObjectMeshes == "_BackpackMesh" then
							meshDetailsItem.SwapBackpack = true
							swapBackpack = true
						elseif characterObjectMeshes == "_FacewearMesh" then
							meshDetailsItem.SwapFacewear = true
							swapFacewear = true
						elseif characterObjectMeshes == "_UnderwearMesh" then
							meshDetailsItem.SwapUnderwear = true
							swapUnderwear = true
						end
					--end
				end
			end
			if swapTops then
				partSwapper:swapTops()
			end
			if swapPants then
				partSwapper:swapPants()
			end
			if swapHelm then
				partSwapper:swapHelm()
			end
			if swapMantle then
				partSwapper:swapMantle()
			end
			if swapBackpack then
				partSwapper:swapBackpack()
			end
			if swapFacewear then
				partSwapper:swapFacewear()
			end
			if swapUnderwear then
				partSwapper:swapUnderwear()
			end
			ceh.swapCostumeRequester = config.modname
		end
	end
end

local function GetMeshID(meshName, partSwapper)
	local tempMeshID
	if meshName == "_TopsBdMesh" then
		tempMeshID = partSwapper._TopsSwapItem._BdMeshID
	elseif meshName == "_TopsBdSubMesh" then
		tempMeshID = partSwapper._TopsSwapItem._BdSubMeshID
	elseif meshName == "_TopsWbMesh" then
		tempMeshID = partSwapper._TopsSwapItem._WbMeshID
	elseif meshName == "_TopsWbSubMesh" then
		tempMeshID = partSwapper._TopsSwapItem._WbSubMeshID
	elseif meshName == "_TopsAmMesh" then
		tempMeshID = partSwapper._TopsSwapItem._AmMeshID
	elseif meshName == "_TopsAmSubMesh" then
		tempMeshID = partSwapper._TopsSwapItem._AmSubMeshID
	elseif meshName == "_TopsBtMesh" then
		tempMeshID = partSwapper._TopsSwapItem._BtMeshID
	elseif meshName == "_TopsBtSubMesh" then
		tempMeshID = partSwapper._TopsSwapItem._BtSubMeshID
	elseif meshName == "_PantsLgMesh" then
		tempMeshID = partSwapper._PantsSwapItem._LgMeshID
	elseif meshName == "_PantsLgSubMesh" then
		tempMeshID = partSwapper._PantsSwapItem._LgSubMeshID
	elseif meshName == "_PantsWlMesh" then
		tempMeshID = partSwapper._PantsSwapItem._WlMeshID
	elseif meshName == "_PantsWlSubMesh" then
		tempMeshID = partSwapper._PantsSwapItem._WlSubMeshID
	elseif meshName == "_HelmMesh" then
		tempMeshID = partSwapper._HelmSwapItem._MeshID
	elseif meshName == "_HelmSubMesh" then
		tempMeshID = partSwapper._HelmSwapItem._SubMeshID
	elseif meshName == "_MantleMesh" then
		tempMeshID = partSwapper._MantleSwapItem._MeshID
	elseif meshName == "_BackpackMesh" then
		tempMeshID = partSwapper._BackpackSwapItem._MeshID
	elseif meshName == "_FacewearMesh" then
		tempMeshID = partSwapper._FacewearSwapItem._MeshID
	elseif meshName == "_UnderwearMesh" then
		local costumeDetails = GetCostumeMeta(partSwapper._Meta)
		if costumeDetails then
			if partSwapper._BodySkinSwapItem then
				local underwearSwapItem = GetSwapItem(ENUMS.SWAPITEMSEARCHTYPE.STYLE, costumeDetails._UnderwearStyle, "Underwear", partSwapper._BodySkinSwapItem._Gender) --partSwapper._UnderwearSwapItem._Gender)
				tempMeshID = underwearSwapItem._MeshID
			end
		end
	end
	return tempMeshID
end

local function GetPawnPersonalityAndVoice(character, additionalCharacterDetails)
	if character then
		local characterPartSwapper = character["<HumanPartSwapper>k__BackingField"]
		if characterPartSwapper then
			local pawnDataContext = characterPartSwapper._PawnDataContext
			if pawnDataContext then
				if not additionalCharacterDetails then
					additionalCharacterDetails = {}
				end
				additionalCharacterDetails.PersonalityID = pawnDataContext:get_Personality()
				additionalCharacterDetails.VoiceGenderCode = pawnDataContext:get_VoiceGender()
				additionalCharacterDetails.VoiceToneType = pawnDataContext:get_VoiceToneType()
			end
		end
	end
	return additionalCharacterDetails
end

local function SetPawnPersonalityAndVoice(character, personalityID, voiceGender, voiceToneType)
	if character then
		local characterPartSwapper = character["<HumanPartSwapper>k__BackingField"]
		if characterPartSwapper then
			local pawnDataContext = characterPartSwapper._PawnDataContext
			if pawnDataContext then
				pawnDataContext:setPersonarity(personalityID)
				pawnDataContext:setVoiceToneType(voiceToneType)
				pawnDataContext:setVoiceGender(voiceGender)
			end
		end
	end
end

local function PartSwapperVisorSwitch(partSwapper)
	if partSwapper then
		if partSwapper:get_VisorSwitch() == 1 then
			 partSwapper:set_VisorSwitch(2)
		elseif partSwapper:get_VisorSwitch() == 2 then
			 partSwapper:set_VisorSwitch(1)
		end
		return true
	end
	return false
end

local function VisorSwitch(character, additionalParameters)
	local ccItems
	if (character or (additionalParameters and additionalParameters.cloneOrMockupBuilder)) then
		ccItems = GetCharacterCustomizationItems(character, additionalParameters)
	end
	if ccItems then
		return PartSwapperVisorSwitch(ccItems.PartSwapper)
	end
	return false
end

local function SetEmptyCostume(character, mockupBuilder, mockupCtrl)
	local partSwapper = GetPartSwapper(character, mockupBuilder, mockupCtrl)
	local defaultCostumeDetails = GetDefaultCostumeMeta()
	local costumeDetails = GetCostumeMeta(partSwapper._Meta)
	local additionalParameters = {}
	local ccItems = {}
	additionalParameters.config = config
	additionalParameters.editContexts = false
	additionalParameters.saveContext = false
	additionalParameters.applyWorkarounds = false
	additionalParameters.skipRequestSwap = false
	ccItems = GetCharacterCustomizationItems(character, additionalParameters)
	EditCostumePartSwapperMeta(ccItems, defaultCostumeDetails, ENUMS.CHARACTEREDITTYPE.COSTUME)
	return ccItems, costumeDetails
end

local function CopyMeshMaterialSingleValue(characterMeshDetailsItem, propertyName, selectedMesh, materialVariableName, mtr_idx, var_idx, actualPropertyName)
	if actualPropertyName == nil then
		actualPropertyName = propertyName
	end
	if propertyName ~= "" and characterMeshDetailsItem[actualPropertyName] == nil and materialVariableName == propertyName then
		characterMeshDetailsItem[actualPropertyName] = selectedMesh:getMaterialFloat(mtr_idx, var_idx)
	end
end

local function SetMeshMaterialSingleValue(characterMeshDetailsItem, propertyName, selectedMesh, materialVariableName, mtr_idx, var_idx, actualPropertyName)
	if actualPropertyName == nil then
		actualPropertyName = propertyName
	end
	if propertyName ~= "" and characterMeshDetailsItem[actualPropertyName] and materialVariableName == propertyName then
		selectedMesh:setMaterialFloat(mtr_idx, var_idx, characterMeshDetailsItem[actualPropertyName])
	end
end

local function CopyMeshMaterialColorValue(characterMeshDetailsItem, propertyName, selectedMesh, materialVariableName, mtr_idx, var_idx, actualPropertyName)
	if actualPropertyName == nil then
		actualPropertyName = propertyName
	end
	if propertyName ~= "" and characterMeshDetailsItem[actualPropertyName] == nil and materialVariableName == propertyName then
		characterMeshDetailsItem[actualPropertyName] = nil
		local colorFloat4 = selectedMesh:getMaterialFloat4(mtr_idx, var_idx)
		if colorFloat4 then
			local colorVec4 = Vector4f.new(colorFloat4.x, colorFloat4.y, colorFloat4.z, colorFloat4.w)
			if colorVec4 then
				characterMeshDetailsItem[actualPropertyName] = common.Vec4ToColorString(colorVec4, true)
			end
		end
	end
end

local function SetMeshMaterialColorValue(characterMeshDetailsItem, propertyName, selectedMesh, materialVariableName, mtr_idx, var_idx, actualPropertyName)
	if actualPropertyName == nil then
		actualPropertyName = propertyName
	end
	if propertyName ~= "" and characterMeshDetailsItem[actualPropertyName] and materialVariableName == propertyName then
		local colorVec4 = common.ColorStringToVec4(characterMeshDetailsItem[actualPropertyName], nil, true)
		selectedMesh:setMaterialFloat4(mtr_idx, var_idx, colorVec4)
	end
end

local function GetAndRefreshCharacterObjectMeshDetailsItem(character, characterMeshIndex, characterMeshDetailsItem, mockupBuilder, mockupCtrl)
	characterMeshDetailsItem = GetCharacterDefaultMeshDetailsItem(characterMeshDetailsItem)
	if (character and character:get_Valid()) and characterMeshIndex > 0 then
		local selectedMesh = GetCharacterObjectMesh(character, characterMeshIndex, mockupBuilder, mockupCtrl)
		if selectedMesh then
			characterMeshDetailsItem.Name = ENUMS.CHARACTEROBJECTMESHES[characterMeshIndex]
			local partSwapper = GetPartSwapper(character, mockupBuilder, mockupCtrl)
			if partSwapper and characterMeshDetailsItem.Name and characterMeshDetailsItem.MeshIDName == nil then
				local tempMeshID = GetMeshID(characterMeshDetailsItem.Name, partSwapper)
				if tempMeshID then
					local meshName = characterMeshDetailsItem.Name
					if meshName then
						meshName = string.gsub(meshName, "_", "")
					else
						meshName = ""
					end
					if ENUMS[meshName .. "IDs"] then
						characterMeshDetailsItem.MeshIDName = ENUMS[meshName .. "IDs"][tempMeshID]
					end
				end
			end
			local visibleMaterialCount = selectedMesh:getMaterialsEnableIndicesCount() --get_MaterialNum()
			for i = 0, visibleMaterialCount - 1 do
				local materialName = selectedMesh:getMaterialName(i)
				local materialVariableCount = selectedMesh:getMaterialVariableNum(i)
				if characterMeshDetailsItem.Materials == nil then
					characterMeshDetailsItem.Materials = {}
				end
				if characterMeshDetailsItem.Materials[tostring(i)] == nil then
					characterMeshDetailsItem.Materials[tostring(i)] = {}
				end
				if characterMeshDetailsItem.Materials and characterMeshDetailsItem.Materials[tostring(i)] then
					for j = 0, materialVariableCount - 1 do
						local materialVariableName = selectedMesh:getMaterialVariableName(i, j)
--common.log(materialVariableName)
						local materialVariableType = selectedMesh:getMaterialVariableType(i, j)
						if materialVariableType == 1 then
							for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_SINGLE) do
								CopyMeshMaterialSingleValue(characterMeshDetailsItem.Materials[tostring(i)], mmvName, selectedMesh, materialVariableName, i, j, nil)
							end
							CopyMeshMaterialSingleValue(characterMeshDetailsItem.Materials[tostring(i)], characterMeshDetailsItem.Materials[tostring(i)].CustomSingleValueName, selectedMesh, materialVariableName, i, j, "CustomSingleValue")
						end
						if materialVariableType == 4 then
							for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_COLOR) do
								CopyMeshMaterialColorValue(characterMeshDetailsItem.Materials[tostring(i)], mmvName, selectedMesh, materialVariableName, i, j, nil)
							end
							CopyMeshMaterialColorValue(characterMeshDetailsItem.Materials[tostring(i)], characterMeshDetailsItem.Materials[tostring(i)].CustomColorName, selectedMesh, materialVariableName, i, j, "CustomColor")
						end
					end
					if characterMeshDetailsItem.Materials[tostring(i)].Enabled == nil then
						characterMeshDetailsItem.Materials[tostring(i)].Enabled = selectedMesh:getMaterialsEnable(i)
					end
					characterMeshDetailsItem.Materials[tostring(i)].MaterialName = materialName
				end
			end
		end
	end
	return characterMeshDetailsItem
end

local function SetCharacterObjectMeshDetailsItem(character, characterMeshIndex, characterMeshDetailsItem, mockupBuilder, mockupCtrl)
	if (character and character:get_Valid()) and characterMeshIndex > 0 and characterMeshDetailsItem then
		local selectedMesh = GetCharacterObjectMesh(character, characterMeshIndex, mockupBuilder, mockupCtrl)
		if selectedMesh then
			--local costumeDetails
			--local ccItems
			--if characterMeshDetailsItem.MeshIDNameChanged then
			--	ccItems, costumeDetails = SetEmptyCostume(character, mockupBuilder, mockupCtrl)
			--end
			local visibleMaterialCount = selectedMesh:getMaterialsEnableIndicesCount() --get_MaterialNum()
			for i = 0, visibleMaterialCount - 1 do
				local isVariableUpdated = false
				local materialName = selectedMesh:getMaterialName(i)
				local materialVariableCount = selectedMesh:getMaterialVariableNum(i)
				if characterMeshDetailsItem.Materials and characterMeshDetailsItem.Materials[tostring(i)] then
					for j = 0, materialVariableCount - 1 do
						local materialVariableName = selectedMesh:getMaterialVariableName(i, j)
--common.log(materialVariableName)
						local materialVariableType = selectedMesh:getMaterialVariableType(i, j)
						if materialVariableType == 1 and characterMeshDetailsItem.Materials[tostring(i)].SingleValueChanged then
							for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_SINGLE) do
								SetMeshMaterialSingleValue(characterMeshDetailsItem.Materials[tostring(i)], mmvName, selectedMesh, materialVariableName, i, j, nil)
							end
							SetMeshMaterialSingleValue(characterMeshDetailsItem.Materials[tostring(i)], characterMeshDetailsItem.Materials[tostring(i)].CustomSingleValueName, selectedMesh, materialVariableName, i, j, "CustomSingleValue")
						end
						if materialVariableType == 4 and characterMeshDetailsItem.Materials[tostring(i)].ColorChanged then
							for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_COLOR) do
								SetMeshMaterialColorValue(characterMeshDetailsItem.Materials[tostring(i)], mmvName, selectedMesh, materialVariableName, i, j, nil)
							end
							SetMeshMaterialColorValue(characterMeshDetailsItem.Materials[tostring(i)], characterMeshDetailsItem.Materials[tostring(i)].CustomColorName, selectedMesh, materialVariableName, i, j, "CustomColor")
						end
					end
					if characterMeshDetailsItem.MaterialsChanged then
						selectedMesh:setMaterialsEnable(i, characterMeshDetailsItem.Materials[tostring(i)].Enabled)
					end
					characterMeshDetailsItem.Materials[tostring(i)].MaterialName = materialName
				end
			end
			--if characterMeshDetailsItem.MeshIDNameChanged then
			--	EditCostumePartSwapperMeta(ccItems, costumeDetails, ENUMS.CHARACTEREDITTYPE.COSTUME)
			--end
		end
		characterMeshDetailsItem.SwapTops = false
		characterMeshDetailsItem.SwapPants = false
		characterMeshDetailsItem.SwapHelm = false
		characterMeshDetailsItem.SwapMantle = false
		characterMeshDetailsItem.SwapBackpack = false
		characterMeshDetailsItem.SwapFacewear = false
		characterMeshDetailsItem.SwapUnderwear = false
	end
end

local function SetAllCharacterObjectMeshDetails(character, characterMeshDetailsItemList, mockupBuilder, mockupCtrl)
	if characterMeshDetailsItemList then
		for characterMeshIndex, characterMeshDetailsItem in pairs(characterMeshDetailsItemList) do
			if characterMeshIndex and tonumber(characterMeshIndex) and characterMeshDetailsItem then
				SetCharacterObjectMeshDetailsItem(character, tonumber(characterMeshIndex), characterMeshDetailsItem, mockupBuilder, mockupCtrl)
			end
		end
	end
end

local function GetCharacterMockupBuilder(character)
	local mockupBuilder
	if character then
		local GuiManager = sdk.get_managed_singleton("app.GuiManager")
		local modelList = GuiManager.MenuMockupList.ModelList
		for i = 0, modelList:get_Count() - 1 do
			local modelListItem = modelList:get_Item(i)
			if modelListItem.CharaId == character.CharacterID then
				mockupBuilder = modelListItem.Builder
			end
		end
	end
	return mockupBuilder
end

local function GetCloneOrMockupBuilderCharaID(cloneOrMockupBuilder)
	local partSwapper = cloneOrMockupBuilder:get_PartSwapper()
	if partSwapper then
		local charaID = partSwapper:get_CharacterID()
		return charaID
	end
	return nil
end

ceh.characterObjectMeshDetailsFMR = {}
local function RefreshCharacterOrMockupObjectMeshDetails(config, character, characterIndex, mockupBuilder, mockupCtrl, characterObjectMeshDetails)
	if characterObjectMeshDetails == nil then
		characterObjectMeshDetails = config.characterObjectMeshDetails[tostring(characterIndex)]
	end
	if character then
		if ceh.characterObjectMeshDetailsFMR[config.modname] == nil then
			ceh.characterObjectMeshDetailsFMR[config.modname] = {}
		end
		if ceh.characterObjectMeshDetailsFMR[config.modname][characterIndex] == nil or (common.IsPausedGUI() and not common.IsPausedGUIBefore("ALL", "RefreshCharacterOrMockupObjectMeshDetails")) then
			ceh.characterObjectMeshDetailsFMR[config.modname][characterIndex] = {}
			for i = 1, #ENUMS.CHARACTEROBJECTMESHES do
				ceh.characterObjectMeshDetailsFMR[config.modname][characterIndex][tostring(i)] = GetAndRefreshCharacterObjectMeshDetailsItem(character, i, nil, nil, nil) --characterObjectMeshDetails[tostring(i)], mockupBuilder, mockupCtrl)
				if characterObjectMeshDetails and characterObjectMeshDetails[tostring(i)] then
					ceh.characterObjectMeshDetailsFMR[config.modname][characterIndex][tostring(i)].MeshIDNameChanged = characterObjectMeshDetails[tostring(i)].MeshIDNameChanged
					ceh.characterObjectMeshDetailsFMR[config.modname][characterIndex][tostring(i)].SingleValueChanged = characterObjectMeshDetails[tostring(i)].SingleValueChanged
					ceh.characterObjectMeshDetailsFMR[config.modname][characterIndex][tostring(i)].ColorChanged = characterObjectMeshDetails[tostring(i)].ColorChanged
					ceh.characterObjectMeshDetailsFMR[config.modname][characterIndex][tostring(i)].MaterialsChanged = characterObjectMeshDetails[tostring(i)].MaterialsChanged
				end
			end
		end
		SetAllCharacterObjectMeshDetails(character, ceh.characterObjectMeshDetailsFMR[config.modname][characterIndex], mockupBuilder, mockupCtrl)
	end
	common.UpdateIsPausedGUIBefore("ALL", "RefreshCharacterOrMockupObjectMeshDetails")
end

ceh.CORMOM = {}
local function AddCORMOM(modname, countDown, config, character, characterIndex, mockupBuilder, mockupCtrl, characterObjectMeshDetails, selectedCharacterMeshIndex)
	local shouldProceed = (ceh.swapCostumeRequester == config.modname)
	if shouldProceed and (mockupBuilder or mockupCtrl) then
		local partSwapper = GetPartSwapper(character, mockupBuilder, mockupCtrl)
		if not partSwapper then
			shouldProceed = false
		end
	end
	if shouldProceed then
		local newCharCORMOM = {}
		newCharCORMOM.originalCountDown = countDown
		newCharCORMOM.countDown = countDown
		newCharCORMOM.config = config
		newCharCORMOM.character = character
		newCharCORMOM.characterIndex = characterIndex
		newCharCORMOM.mockupBuilder = mockupBuilder
		newCharCORMOM.mockupCtrl = mockupCtrl
		newCharCORMOM.characterObjectMeshDetails = characterObjectMeshDetails
		newCharCORMOM.selectedCharacterMeshIndex = selectedCharacterMeshIndex
		newCharCORMOM.isMockup = false
		if mockupBuilder or mockupCtrl then
			newCharCORMOM.isMockup = true
		end
		for charCORMOMKey, charCORMOM in pairs(ceh.CORMOM) do
			if newCharCORMOM.character.CharacterID == charCORMOM.character.CharacterID then
				table.remove(ceh.CORMOM, charCORMOMKey)
				break
			end
		end
		table.insert(ceh.CORMOM, newCharCORMOM)
	end
end

local function RefreshMockup(config, mockupBuilder, mockupCtrl, characterObjectMeshDetails)
	local isNewlyPaused = (common.IsPausedGUI() and not common.IsPausedGUIBefore(config.modname, "RefreshMockup"))
	local refreshSuccess = false
	local shouldRefreshMesh = false
	local shouldExitLoop = false
	for i = -1, characterHelper.GetPartyMembersFinalIndex(config) do
		local character = characterHelper.GetManagedCharacter(i, config)
		if character and character:get_Valid() then
			local charaID = character.CharacterID
			local mockupCharaID
			if mockupCtrl == nil then
				local characterStatusSceneDetails = common.GetCharacterStatusSceneDetails()
				mockupCtrl = characterStatusSceneDetails.MockupCtrl
				mockupCharaID = characterStatusSceneDetails.CharaID
			else
				if mockupCtrl.DispData then
					mockupCharaID = mockupCtrl.DispData:get_CharaId()
				end
			end
			if mockupCharaID == nil then
				mockupCharaID = GetCloneOrMockupBuilderCharaID(mockupBuilder)
			end
			local characterPartSwapper = character["<HumanPartSwapper>k__BackingField"]
			local characterItemData = GetCharacterItemData(character)
			if charaID == mockupCharaID and characterPartSwapper then
				if mockupCtrl and mockupBuilder == nil then
					mockupBuilder = mockupCtrl:getMockupBuilder()
				end
				local mockupPartSwapper
				if mockupPartSwapper == nil and mockupCtrl then
					mockupPartSwapper = mockupCtrl:get_PartSwapper()
				end
				if mockupPartSwapper == nil and mockupBuilder then
					mockupPartSwapper = mockupBuilder:get_PartSwapper()
				end
				if mockupPartSwapper then
					EditCostumeMeta(mockupPartSwapper._Meta, characterPartSwapper._Meta, ENUMS.CHARACTEREDITTYPE.COSTUME, character)
					local currentCostumeDetails = mockupPartSwapper._Meta
					if mockupBuilder and characterItemData then
						local dispEquip = mockupBuilder.DispEquip
						if dispEquip and dispEquip.Equips then
							local ItemManager = sdk.get_managed_singleton("app.ItemManager")
							if ItemManager and dispEquip.Equips then
								for i, storageData in pairs(dispEquip.Equips) do
									if storageData and storageData._ItemData then
										if storageData._ItemData._EquipCategory == 0 then --Main
											--
										end
										if storageData._ItemData._EquipCategory == 1 then --Sub
											--
										end
										if storageData._ItemData._EquipCategory == 2 and ItemManager:getHelmStyle(storageData._ItemData._StyleNo) ~= characterItemData._HelmStyle then --Head
											currentCostumeDetails:call("set_HelmStyle(app.HelmStyle)", ItemManager:getHelmStyle(storageData._ItemData._StyleNo))
											shouldRefreshMesh = true
										end
										if storageData._ItemData._EquipCategory == 3 and ItemManager:getTopsStyle(storageData._ItemData._StyleNo) ~= characterItemData._TopsStyle then --Upper
											currentCostumeDetails:call("set_TopsStyle(app.TopsStyle)", ItemManager:getTopsStyle(storageData._ItemData._StyleNo))
											shouldRefreshMesh = true
										end
										if storageData._ItemData._EquipCategory == 4 and ItemManager:getPantsStyle(storageData._ItemData._StyleNo) ~= characterItemData._PantsStyle then --Lower
											currentCostumeDetails:call("set_PantsStyle(app.PantsStyle)", ItemManager:getPantsStyle(storageData._ItemData._StyleNo))
											shouldRefreshMesh = true
										end
										if storageData._ItemData._EquipCategory == 5 and ItemManager:getMantleStyle(storageData._ItemData._StyleNo) ~= characterItemData._MantleStyle then --Mantle
											currentCostumeDetails:call("set_MantleStyle(app.MantleStyle)", ItemManager:getMantleStyle(storageData._ItemData._StyleNo))
											shouldRefreshMesh = true
										end
										if storageData._ItemData._EquipCategory == 6 then --Jewelry
											--
										end
										if storageData._ItemData._EquipCategory == 7 and ItemManager:getFaceStyle(storageData._ItemData._StyleNo) ~= characterItemData._FacewearStyle then --Visual
											currentCostumeDetails:call("set_FacewearStyle(app.FacewearStyle)", ItemManager:getFaceStyle(storageData._ItemData._StyleNo))
											shouldRefreshMesh = true
										end
									end
								end
							end
						end
					end
					shouldExitLoop = true
				end
				if not shouldExitLoop and mockupCtrl and characterPartSwapper then
					mockupCtrl:reqSync(characterPartSwapper._Meta:clone())
					shouldExitLoop = true
				end
				if shouldExitLoop then
					if character and (mockupBuilder or mockupCtrl) then
						if characterObjectMeshDetails == nil then
							characterObjectMeshDetails = config.characterObjectMeshDetails[tostring(i)]
						end
						if characterObjectMeshDetails then
							if IsMeshIDNamesChanged(characterObjectMeshDetails) then
								SwapCostumePartSwapper(character, i, mockupBuilder, mockupCtrl, characterObjectMeshDetails, config)
							else
								AddCORMOM(3, config, character, i, mockupBuilder, mockupCtrl, characterObjectMeshDetails)
							end
						end
					end
					refreshSuccess = true
					break
				end
			end
		end
	end
	common.UpdateIsPausedGUIBefore(config.modname, "RefreshMockup")
	return refreshSuccess
end

local function RefreshClone(config, cloneBuilder)
	for i = -1, characterHelper.GetPartyMembersFinalIndex(config) do
		local character = characterHelper.GetManagedCharacter(i, config)
		if character and cloneBuilder then
			local charaID = character.CharacterID
			local cloneBuilderCharaID = GetCloneOrMockupBuilderCharaID(cloneBuilder)
			local characterPartSwapper = character["<HumanPartSwapper>k__BackingField"]
			if charaID == cloneBuilderCharaID and characterPartSwapper and characterPartSwapper._Meta then
				local currentCostumeDetails = characterPartSwapper._Meta:clone()
				cloneBuilder:call("requestSwap(app.TopsStyle)", currentCostumeDetails._TopsStyle)
				cloneBuilder:call("requestSwap(app.PantsStyle)", currentCostumeDetails._PantsStyle)
				cloneBuilder:call("requestSwap(app.HelmStyle)", currentCostumeDetails._HelmStyle)
				cloneBuilder:call("requestSwap(app.MantleStyle)", currentCostumeDetails._MantleStyle)
				cloneBuilder:call("requestSwap(app.FacewearStyle)", currentCostumeDetails._FacewearStyle)
				return true
			end
		end
	end
	return false
end

local function RefreshMockupFace(character)
	if character and common.SpamRequestCheckPassed("RefreshMockupFace", 3) then
		local GuiManager = sdk.get_managed_singleton("app.GuiManager")
		GuiManager:call("updateMenuFace(app.Character)", character)
		return true
	end
	return false
end

local function RefreshMockupAndMockupFace(characterIndex, config, character, characterObjectMeshDetails)
	if characterIndex >= -1 and characterIndex <= characterHelper.GetPartyMembersFinalIndex(config) then
		if character == nil then
			character = characterHelper.GetManagedCharacter(characterIndex, config)
		end
		if character then
			local mockupBuilder = GetCharacterMockupBuilder(character)
			if mockupBuilder then
				--mockupBuilder:checkComplete()
				RefreshMockup(config, mockupBuilder, nil, characterObjectMeshDetails)
				RefreshMockupFace(character)
				return true
			end
		end
	end
	return false
end

local function RefreshCostumeData(currentCharacter, config, slotEnum, isOff, characterObjectMeshDetails)
	for i = -1, characterHelper.GetPartyMembersFinalIndex(config) do
		local character = characterHelper.GetManagedCharacter(i, config)
		if character and character.CharacterID == currentCharacter.CharacterID then
			local characterPartSwapper = character["<HumanPartSwapper>k__BackingField"]
			local activeMockupDetails = common.GetActiveMockupDetails()
			if characterPartSwapper and (activeMockupDetails.MockupBuilder or activeMockupDetails.MockupCtrl) then
				local mockupCtrlPartSwapper = GetPartSwapper(character, activeMockupDetails.MockupBuilder, activeMockupDetails.MockupCtrl)
				if mockupCtrlPartSwapper then
					if isOff then
						if slotEnum == 2 then
							mockupCtrlPartSwapper._Meta:call("set_HelmStyle(app.HelmStyle)", 0)
						end
						if slotEnum == 3 then --Upper
							mockupCtrlPartSwapper._Meta:call("set_TopsStyle(app.TopsStyle)", 0)
						end
						if slotEnum == 4 then --Lower
							mockupCtrlPartSwapper._Meta:call("set_PantsStyle(app.PantsStyle)", 0)
						end
						if slotEnum == 5 then --Mantle
							mockupCtrlPartSwapper._Meta:call("set_MantleStyle(app.MantleStyle)", 0)
						end
						if slotEnum == 6 then --Jewelry
							--
						end
						if slotEnum == 7 then --Visual
							mockupCtrlPartSwapper._Meta:call("set_FacewearStyle(app.FacewearStyle)", 0)
						end
					end
					EditCostumeMeta(characterPartSwapper._Meta, mockupCtrlPartSwapper._Meta, ENUMS.CHARACTEREDITTYPE.COSTUME, character)
					local currentCharacterObjectMeshDetails = nil
					if characterObjectMeshDetails == nil then
						currentCharacterObjectMeshDetails = config.characterObjectMeshDetails[tostring(i)]
					else
						currentCharacterObjectMeshDetails = characterObjectMeshDetails
					end
					if currentCharacterObjectMeshDetails then
						if IsMeshIDNamesChanged(currentCharacterObjectMeshDetails) then
							SwapCostumePartSwapper(character, i, activeMockupDetails.MockupBuilder, activeMockupDetails.MockupCtrl, currentCharacterObjectMeshDetails, config)
						else
							AddCORMOM(3, config, character, i, activeMockupDetails.MockupBuilder, activeMockupDetails.MockupCtrl, currentCharacterObjectMeshDetails)
						end
					end
					return true
				end
			end
		end
	end
	return false
end

local function SetWeapons(character, weaponDetails, shouldDrawWeapon)
	if character and character:get_Valid() and weaponDetails then
		local ItemManager = sdk.get_managed_singleton("app.ItemManager")
		if weaponDetails._RightWeapon and weaponDetails._RightWeapon ~= CURRENTITEMVALUE then
			ItemManager:requestRightEquipWeapon(character, weaponDetails._RightWeapon, weaponDetails._IsRightWeaponDraconic)
		end
		if weaponDetails._LeftWeapon and weaponDetails._LeftWeapon ~= CURRENTITEMVALUE then
			ItemManager:requestLeftEquipWeapon(character, weaponDetails._LeftWeapon, weaponDetails._IsLeftWeaponDraconic)
		end
		if shouldDrawWeapon then
			local humanActionSelector = character:get_HumanActionSelector()
			if humanActionSelector then
				humanActionSelector:requestDrawWeapon()
			end
			--local NPCManager = sdk.get_managed_singleton("app.NPCManager")
			--local npcHolder = NPCManager:getNPCHolder(character.CharacterID)
			--if npcHolder then
			--	if npcHolder._NPCBehavior then
			--		local decisionPackTreeController = npcHolder._NPCBehavior.DecisionPackTreeController
			--		if decisionPackTreeController then
			--			local decisionPackTree = decisionPackTreeController.DecisionPackTree
			--			if decisionPackTree then
			--
			--			end if
			--		end
			--	end
			--end
		end
		return true
	end
	return false
end

local function LoadWeapons(character)
	local weaponDetails = {}
	if character then
		local weaponAndItemHolder = character["<WeaponAndItemHolder>k__BackingField"]
		local characterItemData = GetCharacterItemData(character)
		if weaponAndItemHolder then
			weaponDetails._RightWeapon = weaponAndItemHolder["<RightWeapon>k__BackingField"]["<WeaponID>k__BackingField"]
			weaponDetails._LeftWeapon = weaponAndItemHolder["<LeftWeapon>k__BackingField"]["<WeaponID>k__BackingField"]
		end
		if characterItemData then
			weaponDetails._IsRightWeaponDraconic = characterItemData._IsRightWeaponDraconic
			weaponDetails._RightWeaponJob = characterItemData._RightWeaponJob
			weaponDetails._IsLeftWeaponDraconic = characterItemData._IsLeftWeaponDraconic
			weaponDetails._LeftWeaponJob = characterItemData._LeftWeaponJob
		end
	end
	return weaponDetails
end

local function ResetWeapons(character, shouldDrawWeapon)
	local weaponDetails = {}
	if character then
		local characterItemData = GetCharacterItemData(character)
		if characterItemData then
			weaponDetails._RightWeapon = characterItemData._RightWeapon
			weaponDetails._RightWeaponJob = characterItemData._RightWeaponJob
			weaponDetails._IsRightWeaponDraconic = characterItemData._IsRightWeaponDraconic
			if characterItemData._RightWeaponJob == 4 then
				weaponDetails._LeftWeapon = characterItemData._RightWeapon
				weaponDetails._LeftWeaponJob = characterItemData._RightWeaponJob
				weaponDetails._IsLeftWeaponDraconic = characterItemData._IsRightWeaponDraconic
			else
				weaponDetails._LeftWeapon = characterItemData._LeftWeapon
				weaponDetails._LeftWeaponJob = characterItemData._LeftWeaponJob
				weaponDetails._IsLeftWeaponDraconic = characterItemData._IsLeftWeaponDraconic
			end
		end
		return SetWeapons(character, weaponDetails, shouldDrawWeapon)
	end
end

local function VisorSwitchFromCostumeOptions(characterIndex, config, modDetails)
	local ccItems
	local additionalParameters = {}
	additionalParameters.config = config
	additionalParameters.editContexts = false
	additionalParameters.saveContext = false
	additionalParameters.applyWorkarounds = config.applyWorkarounds
	additionalParameters.skipRequestSwap = modDetails.SkipRequestSwap
	local isInCharacterCustomizationScreen = common.IsInDetailedCharacterCustomizationScreen(true)
	if modDetails.isLockedForSpecificCharacter or not isInCharacterCustomizationScreen then
		local characterStatusSceneDetails = common.GetCharacterStatusSceneDetails()
		if not modDetails.isLockedForSpecificCharacter and characterStatusSceneDetails.IsInCharacterStatusScreen and characterStatusSceneDetails.MockupCtrl then
			if characterStatusSceneDetails.MockupCtrl.CompBuilder then
				ccItems = GetCharacterCustomizationItemsFromPartSwapper(characterStatusSceneDetails.MockupCtrl.CompBuilder:get_PartSwapper(), additionalParameters)
			end
		else
			local character = characterHelper.GetManagedCharacter(characterIndex, config)
			ccItems = GetCharacterCustomizationItems(character, additionalParameters)
			additionalParameters.cloneOrMockupBuilder = GetCharacterMockupBuilder(character)
			VisorSwitch(character, additionalParameters)
		end
	else
		ccItems = GetCharacterCustomizationItemsCCS(additionalParameters)
	end
	if ccItems then
		local isCompletelyEdited = PartSwapperVisorSwitch(ccItems.PartSwapper)
		return isEdited
	else
		return false
	end
end

local function LoadCurrentCostumeFromCostumeOptions(characterIndex, costumeDetails, config, modDetails)
	local ccItems
	local additionalParameters = {}
	additionalParameters.config = config
	additionalParameters.editContexts = false
	additionalParameters.saveContext = false
	additionalParameters.applyWorkarounds = config.applyWorkarounds
	additionalParameters.skipRequestSwap = modDetails.SkipRequestSwap
	local isInCharacterCustomizationScreen = common.IsInDetailedCharacterCustomizationScreen(true)
	if modDetails.isLockedForSpecificCharacter or not isInCharacterCustomizationScreen then
		local characterStatusSceneDetails = common.GetCharacterStatusSceneDetails()
		if not modDetails.isLockedForSpecificCharacter and characterStatusSceneDetails.IsInCharacterStatusScreen and characterStatusSceneDetails.MockupCtrl then
			if characterStatusSceneDetails.MockupCtrl.CompBuilder then
				ccItems = GetCharacterCustomizationItemsFromPartSwapper(characterStatusSceneDetails.MockupCtrl.CompBuilder:get_PartSwapper(), additionalParameters)
			end
		else
			local character = characterHelper.GetManagedCharacter(characterIndex, config)
			ccItems = GetCharacterCustomizationItems(character, additionalParameters)
		end
	else
		ccItems = GetCharacterCustomizationItemsCCS(additionalParameters)
	end
	if ccItems and ccItems.PartSwapper then
		local currentCostumeDetails = GetCostumeMeta(ccItems.PartSwapper._Meta)
		costumeDetails._HelmStyle = currentCostumeDetails._HelmStyle
		costumeDetails._HelmVariationStyle = currentCostumeDetails._HelmVariationStyle
		costumeDetails._FacewearStyle = currentCostumeDetails._FacewearStyle
		costumeDetails._FacewearVariationStyle = currentCostumeDetails._FacewearVariationStyle
		costumeDetails._TopsStyle = currentCostumeDetails._TopsStyle
		costumeDetails._TopsVariationStyle = currentCostumeDetails._TopsVariationStyle
		costumeDetails._BackpackStyle = currentCostumeDetails._BackpackStyle
		costumeDetails._PantsStyle = currentCostumeDetails._PantsStyle
		costumeDetails._PantsVariationStyle = currentCostumeDetails._PantsVariationStyle
		costumeDetails._MantleStyle = currentCostumeDetails._MantleStyle
		costumeDetails._MantleVariationStyle = currentCostumeDetails._MantleVariationStyle
		costumeDetails._UnderwearStyle = currentCostumeDetails._UnderwearStyle
		costumeDetails._UnderwearVariationStyle = currentCostumeDetails._UnderwearVariationStyle
	end
end

local function ApplyCostumeFromCostumeOptions(characterIndex, costumeDetails, config, modDetails, cloneOrMockupBuilder)
	local ccItems
	local additionalParameters = {}
	additionalParameters.config = config
	additionalParameters.editContexts = false
	additionalParameters.saveContext = false
	additionalParameters.applyWorkarounds = config.applyWorkarounds
	additionalParameters.skipRequestSwap = modDetails.SkipRequestSwap
	local isInCharacterCustomizationScreen = common.IsInDetailedCharacterCustomizationScreen(true)
	if modDetails.isLockedForSpecificCharacter or not isInCharacterCustomizationScreen then
		local characterStatusSceneDetails = common.GetCharacterStatusSceneDetails()
		if not modDetails.isLockedForSpecificCharacter and characterStatusSceneDetails.IsInCharacterStatusScreen and characterStatusSceneDetails.MockupCtrl then
			if characterStatusSceneDetails.MockupCtrl.CompBuilder then
				ccItems = GetCharacterCustomizationItemsFromPartSwapper(characterStatusSceneDetails.MockupCtrl.CompBuilder:get_PartSwapper(), additionalParameters)
			end
		else
			local character = characterHelper.GetManagedCharacter(characterIndex, config)
			local characterMockupBuilder = cloneOrMockupBuilder
			if characterMockupBuilder == nil then
				characterMockupBuilder = GetCharacterMockupBuilder(character)
			end
			ccItems = GetCharacterCustomizationItems(character, additionalParameters)
			local isCompletelyEdited = false
			local isEdited = false
			isEdited = EditCostumePartSwapperMeta(ccItems, costumeDetails, 0)
			isCompletelyEdited = isCompletelyEdited or isEdited
			if characterMockupBuilder then
				additionalParameters.cloneOrMockupBuilder = characterMockupBuilder
				local mockCCItems = GetCharacterCustomizationItems(character, additionalParameters)
				EditCostumePartSwapperMeta(mockCCItems, costumeDetails, ENUMS.CHARACTEREDITTYPE.COSTUME)
			end
			return isCompletelyEdited
		end
	else
		ccItems = GetCharacterCustomizationItemsCCS(additionalParameters)
	end
	if ccItems then
		local isCompletelyEdited = EditCostumePartSwapperMeta(ccItems, costumeDetails, ENUMS.CHARACTEREDITTYPE.COSTUME)
		return isCompletelyEdited
	else
		return false
	end
end

local function RemoveHelmFacewearAndMantleFromCostumeOptions(characterIndex, costumeDetails, config, modDetails)
	LoadCurrentCostumeFromCostumeOptions(characterIndex, costumeDetails, config, modDetails)
	costumeDetails._HelmStyle = 0
	costumeDetails._FacewearStyle = 0
	costumeDetails._MantleStyle = 0
	ApplyCostumeFromCostumeOptions(characterIndex, costumeDetails, config, modDetails, nil)
end

local function ResetCostumeFromCostumeOptions(characterIndex, config, modDetails)
	local isInCharacterCustomizationScreen = common.IsInDetailedCharacterCustomizationScreen(true)
	if modDetails.isLockedForSpecificCharacter or not isInCharacterCustomizationScreen then
		local characterStatusSceneDetails = common.GetCharacterStatusSceneDetails()
		if not modDetails.isLockedForSpecificCharacter and characterStatusSceneDetails.IsInCharacterStatusScreen and characterStatusSceneDetails.MockupCtrl then
			--if characterStatusSceneDetails.MockupCtrl.CompBuilder then
			--	ccItems = GetCharacterCustomizationItemsFromPartSwapper(characterStatusSceneDetails.MockupCtrl.CompBuilder:get_PartSwapper(), additionalParameters)
			--end
			return
		else
			local character = characterHelper.GetManagedCharacter(characterIndex, config)
			local characterMockupBuilder = GetCharacterMockupBuilder(character)
			if characterIndex <= characterHelper.GetPartyMembersFinalIndex(config) then
				local additionalParameters = {}
				additionalParameters.config = config
				additionalParameters.editContexts = false
				additionalParameters.saveContext = false
				additionalParameters.applyWorkarounds = config.applyWorkarounds
				additionalParameters.skipRequestSwap = modDetails.SkipRequestSwap
				ResetCostume(character, additionalParameters)
				additionalParameters.cloneOrMockupBuilder = characterMockupBuilder
				ResetCostume(character, additionalParameters)
			else
				ApplyCostumeFromCostumeOptions(characterIndex, GetCostumeData(characterHelper.GetCharaID(config.npcCharID[tostring(characterIndex)]), 0), config, modDetails, characterMockupBuilder)
			end
		end
	end
end

local function SetupCostumeOptionsUI(modDetails)

	local characterIndexChanged = false
	local costumeChanged = false
	local changedValue = false

	local costumeOptionsPresets = {}
	local costumeOptionsPresetsCount = 0
	local costumeOptionsPresetIndex = 0
	local costumeUIInitialized = modDetails.costumeUIInitialized
	local updateUIInitializedStatus = true

	local characterStatusSceneDetails
	local isInCharacterStatusScreen = false
	if modDetails.includeCharacterSelection then
		characterStatusSceneDetails = common.GetCharacterStatusSceneDetails()
		isInCharacterStatusScreen = characterStatusSceneDetails.IsInCharacterStatusScreen
	end

	local tableFlag = 1
	if modDetails.includeCharacterSelection then
		tableFlag = 33554432
	end

	if imgui.begin_table("Costume Options" .. modDetails.additionalLabel, 1, tableFlag, {100, 100}) then

		local isInCharacterCustomizationScreen = common.IsInDetailedCharacterCustomizationScreen(true)

		if modDetails.includeCharacterSelection then

			imgui.table_setup_scroll_freeze(1, 1)

			imgui.table_next_row()
			imgui.table_next_column()

			if not common.IsInDetailedCharacterCustomizationScreen(true) and not isInCharacterStatusScreen then
				imgui.set_next_item_width(200)
				characterIndexChanged, modDetails.characterIndex = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Применить к" .. modDetails.additionalLabel, modDetails.characterIndex, modDetails.partyList, 200, "прк" .. modDetails.additionalLabel, false, false, false, nil)
			else
				imgui.set_next_item_width(200)
				imgui.begin_disabled(true)
					_, _ = imgui.combo("Применить к", _, _)
				imgui.end_disabled()
			end

		end

		imgui.table_next_row()
		imgui.table_next_column()

		changedValue, modDetails.costumeDetails._HelmStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Стиль шлема" .. modDetails.additionalLabel, modDetails.costumeDetails._HelmStyle, ENUMS.HelmStyles, 250, "hs" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._HelmVariationStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Вариация шлема" .. modDetails.additionalLabel, modDetails.costumeDetails._HelmVariationStyle, ENUMS.HelmVariationStyles, 250, "hvs" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._FacewearStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Стиль личины" .. modDetails.additionalLabel, modDetails.costumeDetails._FacewearStyle, ENUMS.FacewearStyles, 250, "fs" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._FacewearVariationStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Вариация личины" .. modDetails.additionalLabel, modDetails.costumeDetails._FacewearVariationStyle, ENUMS.FacewearVariationStyles, 250, "fvs" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._TopsStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Стиль верха" .. modDetails.additionalLabel, modDetails.costumeDetails._TopsStyle, ENUMS.TopsStyles, 250, "ts" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._TopsVariationStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Вариация верха" .. modDetails.additionalLabel, modDetails.costumeDetails._TopsVariationStyle, ENUMS.TopsVariationStyles, 250, "tvs" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._BackpackStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Стиль рюкзака" .. modDetails.additionalLabel, modDetails.costumeDetails._BackpackStyle, ENUMS.BackpackStyles, 250, "bs" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._PantsStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Стиль штанов" .. modDetails.additionalLabel, modDetails.costumeDetails._PantsStyle, ENUMS.PantsStyles, 250, "ps" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._PantsVariationStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Вариация штанов" .. modDetails.additionalLabel, modDetails.costumeDetails._PantsVariationStyle, ENUMS.PantsVariationStyles, 250, "pvs" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._MantleStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Стиль накидки" .. modDetails.additionalLabel, modDetails.costumeDetails._MantleStyle, ENUMS.MantleStyles, 250, "ms" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._MantleVariationStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Вариация накидки" .. modDetails.additionalLabel, modDetails.costumeDetails._MantleVariationStyle, ENUMS.MantleVariationStyles, 250, "mvs" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._UnderwearStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Стиль белья" .. modDetails.additionalLabel, modDetails.costumeDetails._UnderwearStyle, ENUMS.UnderwearStyles, 250, "us" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue
		changedValue, modDetails.costumeDetails._UnderwearVariationStyle = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Вариация белья" .. modDetails.additionalLabel, modDetails.costumeDetails._UnderwearVariationStyle, ENUMS.UnderwearVariationStyles, 250, "uvs" .. modDetails.additionalLabel, modDetails.addCostumeSearchTextBoxes, modDetails.addCostumeIDOverrideTextBoxes, false, nil)
		costumeChanged = costumeChanged or changedValue

		imgui.begin_disabled((not modDetails.isLockedForSpecificCharacter and isInCharacterCustomizationScreen) or isInCharacterStatusScreen)
			if imgui.button("Переключить забрало" .. modDetails.additionalLabel) then
				VisorSwitchFromCostumeOptions(modDetails.characterIndex, modDetails.config, modDetails)
			end
		imgui.end_disabled()
		imgui.same_line()
		if imgui.button("Убрать шлем, личину и накидку" .. modDetails.additionalLabel) then
			RemoveHelmFacewearAndMantleFromCostumeOptions(modDetails.characterIndex, modDetails.costumeDetails, modDetails.config, modDetails)
		end

		if imgui.button("Применить костюм" .. modDetails.additionalLabel) then
			ApplyCostumeFromCostumeOptions(modDetails.characterIndex, modDetails.costumeDetails, modDetails.config, modDetails, nil)
		end
		imgui.same_line()
		if imgui.button("Загрузить текущий костюм" .. modDetails.additionalLabel) then
			LoadCurrentCostumeFromCostumeOptions(modDetails.characterIndex, modDetails.costumeDetails, modDetails.config, modDetails)
		end
		imgui.same_line()
		common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Нажмите [Загрузить текущий костюм" .. modDetails.additionalLabel .. "] чтобы получить текущий наряд персонажа.\nПримечание: игра не сохраняет изменения вариаций стилей.")

		imgui.begin_disabled((not modDetails.isLockedForSpecificCharacter and isInCharacterCustomizationScreen) or isInCharacterStatusScreen)
			if imgui.button("Сбросить костюм" .. modDetails.additionalLabel) then
				ResetCostumeFromCostumeOptions(modDetails.characterIndex, modDetails.config, modDetails)
			end
		imgui.end_disabled()

		_, modDetails.addCostumeSearchTextBoxes = imgui.checkbox("Показать поиск костюмов", modDetails.addCostumeSearchTextBoxes)
		imgui.same_line()
		common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "FEMMAS = Feminine (жен.) или Masculine (муж.)\nПредметы без привязки к полу помечены так,\nчтобы они всё равно попадали в результаты поиска\nпри вводе первых 3 букв кода выбранного пола.")

		_, modDetails.addCostumeIDOverrideTextBoxes = imgui.checkbox("Показать ID предметов костюма", modDetails.addCostumeIDOverrideTextBoxes)
		imgui.same_line()
		common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Укажите ID предметов в текстовых полях.\nВ основном для кастомных предметов.\n(например: предметы добавленные через 'Content Editor')")

		imgui.table_next_row()
		imgui.table_next_column()

		imgui.text(" ")

		if imgui.tree_node("- ПРЕСЕТЫ КОСТЮМОВ -") then

			local tempDataTable = common.deepcopy_table(modDetails.costumeDetails, nil)

			local uiDetails = common.SetupCreateEditDeleteDataTableFileUI(tempDataTable, filesList.costumeOptionsFolderName, modDetails.costumeOptionsPresetName, modDetails.costumeOptionsNewPresetName, modDetails, "пресет костюмов", modDetails.costumeOptionsFileExists, modDetails.costumeOptionsShouldConfirmDelete)
			modDetails.costumeOptionsPresetName = uiDetails.fileName
			modDetails.costumeOptionsNewPresetName = uiDetails.newFileName
			costumeOptionsPresets = uiDetails.fileNamesList
			costumeOptionsPresetsCount = uiDetails.fileNamesListCount
			costumeOptionsPresetIndex = uiDetails.fileNamesListIndex
			modDetails.costumeOptionsFileExists = uiDetails.fileExists
			modDetails.costumeOptionsShouldConfirmDelete = uiDetails.shouldConfirmDelete
			costumeChanged = costumeChanged or uiDetails.selectedFileChanged or uiDetails.shouldLoadFile

			if uiDetails.shouldLoadFile or (modDetails.shouldAutoReapplyCostume and uiDetails.selectedFileChanged) then
				modDetails.costumeDetails = uiDetails.dataTable
				costumeUIInitialized = false
				updateUIInitializedStatus = false
			end

			imgui.tree_pop()

		end

		imgui.spacing()
		imgui.spacing()

		if updateUIInitializedStatus then
			costumeUIInitialized = true
		end

		if costumeChanged and modDetails.shouldAutoReapplyCostume then
			ApplyCostumeFromCostumeOptions(modDetails.characterIndex, modDetails.costumeDetails, modDetails.config, modDetails, nil)
		end

		imgui.end_table()

	end

	local costumeOptionsWindowDetails = {}
	costumeOptionsWindowDetails.characterIndexChanged = characterIndexChanged
	costumeOptionsWindowDetails.costumeChanged = costumeChanged
	costumeOptionsWindowDetails.config = modDetails.config
	costumeOptionsWindowDetails.modCode = modDetails.modCode
	costumeOptionsWindowDetails.partyList = modDetails.partyList
	costumeOptionsWindowDetails.characterIndex = modDetails.characterIndex
	if costumeOptionsPresetsCount > -1 then
		costumeOptionsWindowDetails.costumeOptionsPresetName = costumeOptionsPresets[costumeOptionsPresetIndex]
	else
		costumeOptionsWindowDetails.costumeOptionsPresetName =  modDetails.costumeOptionsPresetName
	end
	costumeOptionsWindowDetails.costumeOptionsNewPresetName = modDetails.costumeOptionsNewPresetName
	costumeOptionsWindowDetails.costumeOptionsFileExists = modDetails.costumeOptionsFileExists
	costumeOptionsWindowDetails.costumeOptionsShouldConfirmDelete = modDetails.costumeOptionsShouldConfirmDelete
	costumeOptionsWindowDetails.costumeDetails = modDetails.costumeDetails
	costumeOptionsWindowDetails.addCostumeSearchTextBoxes = modDetails.addCostumeSearchTextBoxes
	costumeOptionsWindowDetails.addCostumeIDOverrideTextBoxes = modDetails.addCostumeIDOverrideTextBoxes
	costumeOptionsWindowDetails.shouldAutoReapplyCostume = modDetails.shouldAutoReapplyCostume
	costumeOptionsWindowDetails.weaponUIInitialized = costumeUIInitialized

	return costumeOptionsWindowDetails

end

local function SetWeaponsFromWeaponOptions(characterIndex, weaponDetails, config, modDetails, cloneOrMockupBuilder)
	local character = characterHelper.GetManagedCharacter(characterIndex, config)
	local shouldDrawWeapon = true
	if characterIndex <= characterHelper.GetPartyMembersFinalIndex(config) then
		shouldDrawWeapon = false
	end
	SetWeapons(character, weaponDetails, shouldDrawWeapon)
end

local function LoadWeaponsFromWeaponOptions(characterIndex, weaponDetails, config, modDetails)
	local character = characterHelper.GetManagedCharacter(characterIndex, config)
	if character then
		weaponDetails = LoadWeapons(character)
	end
	return weaponDetails
end

local function ResetWeaponsFromWeaponOptions(characterIndex, config, modDetails)
	local character = characterHelper.GetManagedCharacter(characterIndex, config)
	local shouldDrawWeapon = true
	if characterIndex <= characterHelper.GetPartyMembersFinalIndex(config) then
		shouldDrawWeapon = false
	end
	ResetWeapons(character, shouldDrawWeapon)
end

local function SetupWeaponOptionsUI(modDetails)

	local characterIndexChanged = false
	local weaponChanged = false
	local changedValue = false

	local weaponOptionsPresets = {}
	local weaponOptionsPresetsCount = 0
	local weaponOptionsPresetIndex = 0
	local weaponUIInitialized = modDetails.weaponUIInitialized
	local updateUIInitializedStatus = true

	local characterStatusSceneDetails
	local isInCharacterStatusScreen = false
	if modDetails.includeCharacterSelection then
		characterStatusSceneDetails = common.GetCharacterStatusSceneDetails()
		isInCharacterStatusScreen = characterStatusSceneDetails.IsInCharacterStatusScreen
	end

	local tableFlag = 1
	if modDetails.includeCharacterSelection then
		tableFlag = 33554432
	end

	if imgui.begin_table("Weapon Options" .. modDetails.additionalLabel, 1, tableFlag, {100, 100}) then

		local isInCharacterCustomizationScreen = common.IsInDetailedCharacterCustomizationScreen(true)

		if modDetails.includeCharacterSelection then

			imgui.table_setup_scroll_freeze(1, 1)

			imgui.table_next_row()
			imgui.table_next_column()

			if not common.IsInDetailedCharacterCustomizationScreen(true) and not isInCharacterStatusScreen then
				imgui.set_next_item_width(200)
				characterIndexChanged, modDetails.characterIndex = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Применить к" .. modDetails.additionalLabel, modDetails.characterIndex, modDetails.partyList, 200, "at" .. modDetails.additionalLabel, false, false, false, nil)
			else
				imgui.set_next_item_width(200)
				imgui.begin_disabled(true)
					_, _ = imgui.combo("Применить к", _, _)
				imgui.end_disabled()
			end

		end

		imgui.table_next_row()
		imgui.table_next_column()

		changedValue, modDetails.weaponDetails._RightWeapon = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Правое оружие" .. modDetails.additionalLabel, modDetails.weaponDetails._RightWeapon, ENUMS.WeaponData, 200, "rw" .. modDetails.additionalLabel, modDetails.addWeaponSearchTextBoxes, modDetails.addWeaponIDOverrideTextBoxes, false, nil)
		weaponChanged = weaponChanged or changedValue
		changedValue, modDetails.weaponDetails._LeftWeapon = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Левое оружие" .. modDetails.additionalLabel, modDetails.weaponDetails._LeftWeapon, ENUMS.WeaponData, 200, "lw" .. modDetails.additionalLabel, modDetails.addWeaponSearchTextBoxes, modDetails.addWeaponIDOverrideTextBoxes, false, nil)
		weaponChanged = weaponChanged or changedValue

		changedValue, modDetails.weaponDetails._IsRightWeaponDraconic = imgui.checkbox("Дракон. правое" .. modDetails.additionalLabel, modDetails.weaponDetails._IsRightWeaponDraconic)
		weaponChanged = weaponChanged or changedValue
		changedValue, modDetails.weaponDetails._IsLeftWeaponDraconic = imgui.checkbox("Дракон. левое" .. modDetails.additionalLabel, modDetails.weaponDetails._IsLeftWeaponDraconic)
		weaponChanged = weaponChanged or changedValue

		if imgui.button("Применить оружие" .. modDetails.additionalLabel) then
			SetWeaponsFromWeaponOptions(modDetails.characterIndex, modDetails.weaponDetails, modDetails.config, modDetails, nil)
		end
		imgui.same_line()
		common.TextColoredWithOnHoverTooltip("(!)", common.COLOR.ORANGE, "Это не совсем Transmog.")
		if imgui.button("Загрузить текущее оружие" .. modDetails.additionalLabel) then
			modDetails.weaponDetails = LoadWeaponsFromWeaponOptions(modDetails.characterIndex, modDetails.weaponDetails, modDetails.config, modDetails)
		end

		imgui.begin_disabled((not modDetails.isLockedForSpecificCharacter and isInCharacterCustomizationScreen) or isInCharacterStatusScreen)
			if imgui.button("Сбросить оружие" .. modDetails.additionalLabel) then
				ResetWeaponsFromWeaponOptions(modDetails.characterIndex, modDetails.config, modDetails)
			end
		imgui.end_disabled()

		_, modDetails.addWeaponSearchTextBoxes = imgui.checkbox("Показать поиск оружия", modDetails.addWeaponSearchTextBoxes)
		--imgui.same_line()
		--common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, ".")

		_, modDetails.addWeaponIDOverrideTextBoxes = imgui.checkbox("Показать ID предметов оружия", modDetails.addWeaponIDOverrideTextBoxes)
		imgui.same_line()
		common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Укажите ID предметов в текстовых полях.\nВ основном для кастомных предметов.\n(например: предметы добавленные через 'Content Editor')")

		imgui.table_next_row()
		imgui.table_next_column()

		imgui.text(" ")

		if imgui.tree_node("- ПРЕСЕТЫ ОРУЖИЯ -") then

			local tempDataTable = common.deepcopy_table(modDetails.weaponDetails, nil)

			local uiDetails = common.SetupCreateEditDeleteDataTableFileUI(tempDataTable, filesList.weaponOptionsFolderName, modDetails.weaponOptionsPresetName, modDetails.weaponOptionsNewPresetName, modDetails, "пресет оружия", modDetails.weaponOptionsFileExists, modDetails.weaponOptionsShouldConfirmDelete)
			modDetails.weaponOptionsPresetName = uiDetails.fileName
			modDetails.weaponOptionsNewPresetName = uiDetails.newFileName
			weaponOptionsPresets = uiDetails.fileNamesList
			weaponOptionsPresetsCount = uiDetails.fileNamesListCount
			weaponOptionsPresetIndex = uiDetails.fileNamesListIndex
			modDetails.weaponOptionsFileExists = uiDetails.fileExists
			modDetails.weaponOptionsShouldConfirmDelete = uiDetails.shouldConfirmDelete
			weaponChanged = weaponChanged or uiDetails.selectedFileChanged or uiDetails.shouldLoadFile

			if uiDetails.shouldLoadFile or (modDetails.shouldAutoReapplyWeapon and uiDetails.selectedFileChanged) then
				modDetails.weaponDetails = uiDetails.dataTable
				weaponUIInitialized = false
				updateUIInitializedStatus = false
			end

			imgui.tree_pop()

		end

		imgui.spacing()
		imgui.spacing()

		if updateUIInitializedStatus then
			weaponUIInitialized = true
		end

		if weaponChanged and modDetails.shouldAutoReapplyWeapon then
			SetWeaponsFromWeaponOptions(modDetails.characterIndex, modDetails.weaponDetails, modDetails.config, modDetails, nil)
			weaponChanged = false
		end

		imgui.end_table()

	end

	local weaponOptionsWindowDetails = {}
	weaponOptionsWindowDetails.characterIndexChanged = characterIndexChanged
	weaponOptionsWindowDetails.weaponChanged = weaponChanged
	weaponOptionsWindowDetails.config = modDetails.config
	weaponOptionsWindowDetails.modCode = modDetails.modCode
	weaponOptionsWindowDetails.partyList = modDetails.partyList
	weaponOptionsWindowDetails.characterIndex = modDetails.characterIndex
	if weaponOptionsPresetsCount > -1 then
		weaponOptionsWindowDetails.weaponOptionsPresetName = weaponOptionsPresets[weaponOptionsPresetIndex]
	else
		weaponOptionsWindowDetails.weaponOptionsPresetName = modDetails.weaponOptionsPresetName
	end
	weaponOptionsWindowDetails.weaponOptionsNewPresetName =  modDetails.weaponOptionsNewPresetName
	weaponOptionsWindowDetails.weaponOptionsFileExists = modDetails.weaponOptionsFileExists
	weaponOptionsWindowDetails.weaponOptionsShouldConfirmDelete = modDetails.weaponOptionsShouldConfirmDelete
	weaponOptionsWindowDetails.weaponDetails = modDetails.weaponDetails
	weaponOptionsWindowDetails.addWeaponSearchTextBoxes = modDetails.addWeaponSearchTextBoxes
	weaponOptionsWindowDetails.addWeaponIDOverrideTextBoxes = modDetails.addWeaponIDOverrideTextBoxes
	weaponOptionsWindowDetails.shouldAutoReapplyWeapon = modDetails.shouldAutoReapplyWeapon
	weaponOptionsWindowDetails.weaponUIInitialized = weaponUIInitialized

	return weaponOptionsWindowDetails

end

local function RefreshMockupsAndMockupFaces(config, skipChecks, characterObjectMeshDetailsList)
	if common.IsPlayerCharacterReady() and ((common.IsPausedGUI() and not common.IsPausedGUIBefore(config.modname, "RefreshMockupsAndMockupFaces")) or skipChecks) then
		for i = -1, characterHelper.GetPartyMembersFinalIndex(config) do
			local characterObjectMeshDetails = nil
			if characterObjectMeshDetailsList and characterObjectMeshDetailsList[i] then
				characterObjectMeshDetails = characterObjectMeshDetailsList[i]
			end
			RefreshMockupAndMockupFace(i, config, nil, characterObjectMeshDetails)
		end
	end
	common.UpdateIsPausedGUIBefore(config.modname, "RefreshMockupsAndMockupFaces")
end

local function RefreshManagedCharacterCostumeVariationStyles(characterIndex, config, character)
	if character == nil then
		character = characterHelper.GetManagedCharacter(characterIndex, config)
	end
	if character and config then
		local partSwapper = character["<HumanPartSwapper>k__BackingField"]
		if partSwapper then
			local ccItems = {}
			ccItems.PartSwapper = partSwapper
			StartPartSwapperEdits(ccItems)
			EditCostumeMetaVariationStyles(partSwapper._Meta, config.costumeVariationStylesDetails[tostring(characterIndex)], ENUMS.CHARACTEREDITTYPE.COSTUME, character)
			EndPartSwapperEdits(ccItems)
		end
	end
end

local function RefreshManagedCharactersCostumeVariationStyles(config)
	if not common.IsInterruptedGUI() and common.IsInterruptedGUIBefore(config.modname, "RefreshManagedCharactersCostumeVariationStyles") then
		for i = -1, characterHelper.GetFinalManagedCharacterIndex(config) do
			local character = characterHelper.GetManagedCharacter(i, config)
			RefreshManagedCharacterCostumeVariationStyles(i, config, character)
		end
	end
	common.UpdateIsInterruptedGUIBefore(config.modname, "RefreshManagedCharactersCostumeVariationStyles")
end

local function GetCharacterSkinColorForColorEdit(modDetails)
	local character = characterHelper.GetManagedCharacter(modDetails.characterIndex, modDetails.config)
	return GetCharacterSkinColor(character)
end

local function SetupMeshOptionsUI(modDetails)

	if not ceh.isMeshVariableNamesDataLoaded then
		RefreshMeshMaterialVariableNamesData()
	end

	local characterIndexChanged = false
	local meshIDNameChanged = false
	local meshEdited = false
	local changedValue = false

	local meshOptionsPresets = {}
	local meshOptionsPresetsCount = 0
	local meshOptionsPresetIndex = 0
	local meshUIInitialized = modDetails.meshUIInitialized
	local updateUIInitializedStatus = true

	local resetMeshIDs = false

	local characterStatusSceneDetails
	local isInCharacterStatusScreen = false
	if modDetails.includeCharacterSelection then
		characterStatusSceneDetails = common.GetCharacterStatusSceneDetails()
		isInCharacterStatusScreen = characterStatusSceneDetails.IsInCharacterStatusScreen
	end

	local tableFlag = 1
	if modDetails.includeCharacterSelection then
		tableFlag = 33554432
	end

	if imgui.begin_table("Mesh Options" .. modDetails.additionalLabel, 1, tableFlag, {100, 100}) then

		local isInCharacterCustomizationScreen = common.IsInDetailedCharacterCustomizationScreen(true)

		if modDetails.includeCharacterSelection then

			imgui.table_setup_scroll_freeze(1, 1)

			imgui.table_next_row()
			imgui.table_next_column()

			if not common.IsInDetailedCharacterCustomizationScreen(true) and not isInCharacterStatusScreen then
				imgui.set_next_item_width(200)
				characterIndexChanged, modDetails.characterIndex = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Применить к" .. modDetails.additionalLabel, modDetails.characterIndex, modDetails.partyList, 200, "at" .. modDetails.additionalLabel, false, false, false, nil)
			else
				imgui.set_next_item_width(200)
				imgui.begin_disabled(true)
					_, _ = imgui.combo("Применить к", _, _)
				imgui.end_disabled()
			end

		end

		imgui.table_next_row()
		imgui.table_next_column()

		local disablingOptionMessage = "Отключение этой опции не отменяет уже применённые изменения."

		changedValue, modDetails.selectedCharacterMeshIndex = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "Имя меша" .. modDetails.additionalLabel, modDetails.selectedCharacterMeshIndex, ENUMS.CHARACTEROBJECTMESHES, 200, "имямеша", false, false, false, nil)
		imgui.same_line()
		if imgui.button("Обновить параметры меша" .. modDetails.additionalLabel) then
			meshUIInitialized = false
		end
		imgui.same_line()
		common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Запускайте если параметры выбранного предмета не загружаются должным образом.")
		if changedValue or not meshUIInitialized or modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].ShouldRefresh then
			local character = characterHelper.GetManagedCharacter(modDetails.characterIndex, modDetails.config)
			local activeMockupDetails = common.GetActiveMockupDetails()
			modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)] = GetAndRefreshCharacterObjectMeshDetailsItem(character, modDetails.selectedCharacterMeshIndex, modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)], activeMockupDetails.MockupBuilder, activeMockupDetails.MockupCtrl)
			modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].ShouldRefresh = false
		end

		if imgui.button("Обновить имена переменных меша" .. modDetails.additionalLabel) then
			RefreshMeshMaterialVariableNamesData()
		end
		imgui.same_line()
		common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Перезагружает конфигурационные файлы с именами переменных материалов меша.\n" .. filesList.meshMaterialVariableNamesSingleFileName .. "\n" .. filesList.meshMaterialVariableNamesColorFileName .. "\nПользователи могут добавлять или удалять элементы в этих файлах, чтобы указать, какие свойства меша (Single) или цвета (Color) они хотят изменять.")

		local meshName = ENUMS.CHARACTEROBJECTMESHES[modDetails.selectedCharacterMeshIndex]
		local meshDisplayName = ""

		if meshName then
			meshName = string.gsub(meshName, "_", "")
			meshDisplayName = meshName .. " "
		else
			meshName = ""
		end

		if meshName ~= "" and ENUMS[meshName .. "IDs"] ~= nil then
			imgui.spacing()
			imgui.spacing()
			imgui.text("[ID]")
			imgui.same_line()
			common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Mesh ID of the selected part.\nChanging the ID swaps the part to that of the selected ID.")
			local additionalComboBoxSettings = {}
			additionalComboBoxSettings.AddNewLineBeforeSearchTextBox = true
			additionalComboBoxSettings.ComboBoxToolTipLabel = "(?)"
			additionalComboBoxSettings.ComboBoxToolTip = "Initial value might be incorrect if the selected mesh has been previously modified."
			changedValue, modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].MeshIDNameChanged = imgui.checkbox("Применить ID меша к " .. meshName .. " " .. modDetails.additionalLabel, modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].MeshIDNameChanged)
			imgui.same_line()
			common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, disablingOptionMessage .. "\nЭкраны статуса замедляются при включении этой функции.")
			meshEdited = meshEdited or changedValue
			local meshIDsListIndex = common.GetCurrentListIndex(ENUMS[meshName .. "IDs"], modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].MeshIDName)
			meshIDNameChanged, meshIDsListIndex = common.ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", "ID меша" .. modDetails.additionalLabel, meshIDsListIndex, ENUMS[meshName .. "IDs"], 200, "идмеша" .. modDetails.additionalLabel, true, false, false, additionalComboBoxSettings)
			modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].MeshIDName = ENUMS[meshName .. "IDs"][meshIDsListIndex]
			meshEdited = meshEdited or meshIDNameChanged
			modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].MeshIDNameChanged = modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].MeshIDNameChanged or meshIDNameChanged

			if imgui.button("Сбросить " .. meshName .. " Mesh ID") then
				local character = characterHelper.GetManagedCharacter(modDetails.characterIndex, modDetails.config)
				ResetCostumeMeshID(character, modDetails.characterObjectMeshDetails, ENUMS.CHARACTEROBJECTMESHES[modDetails.selectedCharacterMeshIndex])
				meshIDNameChanged = true
				resetMeshIDs = true
			end
			imgui.same_line()
			if imgui.button("Сбросить ВСЕ Mesh ID") then
				local character = characterHelper.GetManagedCharacter(modDetails.characterIndex, modDetails.config)
				ResetCostumeMeshID(character, modDetails.characterObjectMeshDetails, "ALL")
				meshIDNameChanged = true
				resetMeshIDs = true
			end
		end

		local materialCount = 0
		for matIdx, material in pairs(modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].Materials) do
			materialCount = materialCount + 1
		end

		if materialCount > 0 then

			imgui.spacing()
			imgui.spacing()
			imgui.text("[Материалы]")

			changedValue, modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].MaterialsChanged = imgui.checkbox("Применить правки материала " .. meshDisplayName .. " " .. modDetails.additionalLabel, modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].MaterialsChanged)
			imgui.same_line()
			common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, disablingOptionMessage)
			meshEdited = meshEdited or changedValue

			local enableAllCurrentMeshMaterials = false
			local disableAllCurrentMeshMaterials = false

			enableAllCurrentMeshMaterials = imgui.button("Вкл. материалы " .. meshDisplayName .. " " .. modDetails.additionalLabel)
			imgui.same_line()
			disableAllCurrentMeshMaterials = imgui.button("Выкл. материалы " .. meshDisplayName .. " " .. modDetails.additionalLabel)

			imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
			_, modDetails.meshMaterialSearchString = common.TextBoxWithCopyAndClearButtons("Поиск материала меша", modDetails.meshMaterialSearchString, 300, nil, nil, nil, "Очистить поле поиска.")
			imgui.same_line()
			common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Поиск по имени материала или свойства.")

			local tempMeshMaterialSearchString = modDetails.meshMaterialSearchString
			tempMeshMaterialSearchString = tempMeshMaterialSearchString:gsub("%%", "\\%%")
			tempMeshMaterialSearchString = tempMeshMaterialSearchString:gsub("%[", "\\[")
			tempMeshMaterialSearchString = tempMeshMaterialSearchString:gsub("%(", "\\(")

			local meshMaterialPropertyNameFound = false
			local meshMaterialColorNameFound = false

			for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_SINGLE) do
				if string.find(tostring(mmvName):lower(), tempMeshMaterialSearchString:lower()) then
					meshMaterialPropertyNameFound = true
					break
				end
			end
			for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_COLOR) do
				if string.find(tostring(mmvName):lower(), tempMeshMaterialSearchString:lower()) then
					meshMaterialColorNameFound = true
					break
				end
			end
			meshMaterialPropertyNameFound = meshMaterialPropertyNameFound or string.find(tostring("кастомное свойство"):lower(), tempMeshMaterialSearchString:lower())
			meshMaterialColorNameFound = meshMaterialColorNameFound or string.find(tostring("кастомный цвет"):lower(), tempMeshMaterialSearchString:lower())

			local copyPropertyValue
			local copyPropertyName
			local copyColorValue
			local copyColorName

			local visibleMaterialCount = 0
			local isPrevEnabled = true
			local meshMaterialNameFound = false
			local meshMaterialPropertyNameFound2 = false
			for matIdx, material in pairs(modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].Materials) do
				if material then
					local materialName = tostring(matIdx)
					local materialFullDisplayName = ""
					if material.MaterialName and material.MaterialName ~= "" then
						materialName = materialName  .. " (" .. material.MaterialName .. ")"
						materialFullDisplayName = meshDisplayName .. material.MaterialName
					else
						materialFullDisplayName = meshDisplayName .. "Material " .. tostring(matIdx)
					end
					meshMaterialNameFound = string.find(tostring(materialFullDisplayName):lower(), tempMeshMaterialSearchString:lower())
					if meshMaterialNameFound or meshMaterialPropertyNameFound or meshMaterialColorNameFound then
						if isPrevEnabled then
							imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
						end
						if enableAllCurrentMeshMaterials then
							material.Enabled = true
						end
						if disableAllCurrentMeshMaterials then
							material.Enabled = false
						end
						changedValue, material.Enabled = imgui.checkbox(meshDisplayName .. "Material " .. materialName .. modDetails.additionalLabel, material.Enabled)
						meshEdited = meshEdited or changedValue
						imgui.same_line()
						common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Visibility of " .. materialFullDisplayName .. ".")
						if changedValue then
							modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].MaterialsChanged = true
						end
						if material.Enabled then

							if meshMaterialNameFound or meshMaterialPropertyNameFound then
								imgui.spacing()
								imgui.spacing()
								imgui.text("- " .. materialFullDisplayName .. " Свойства -")

								imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
								imgui.same_line()
								changedValue, material.SingleValueChanged = imgui.checkbox("Применить " .. materialFullDisplayName .. " свойства" .. modDetails.additionalLabel, material.SingleValueChanged)
								imgui.same_line()
								common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, disablingOptionMessage)
								meshEdited = meshEdited or changedValue

								for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_SINGLE) do
									meshMaterialPropertyNameFound2 = string.find(tostring(mmvName):lower(), tempMeshMaterialSearchString:lower())
									if meshMaterialNameFound or meshMaterialPropertyNameFound2 then
										local materialPropertyFullDisplayName = materialFullDisplayName .. " " .. mmvName .. modDetails.additionalLabel
										imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
										imgui.same_line()
										if imgui.arrow_button("Копировать значение во все мат. из ".. materialFullDisplayName .. " " .. mmvName .. modDetails.additionalLabel, 1) then
											copyPropertyValue = material[mmvName]
											copyPropertyName = mmvName
										end
										if imgui.is_item_hovered() then
											imgui.set_tooltip("Копировать [" .. mmvName .. "] во все [" .. materialFullDisplayName .. "] материалы.")
										end
										imgui.same_line()
										imgui.set_next_item_width(200)
										changedValue, material[mmvName] = imgui.drag_float(materialPropertyFullDisplayName, material[mmvName], 0.01, -1000000.0, 1000000.0)
										if imgui.is_item_hovered() then
											imgui.set_tooltip(materialPropertyFullDisplayName)
										end
										meshEdited = meshEdited or changedValue
										material.SingleValueChanged = material.SingleValueChanged or changedValue
									end
								end

								imgui.spacing()

								if meshMaterialNameFound or string.find(tostring("кастомное свойство"):lower(), tempMeshMaterialSearchString:lower()) then
									imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
									imgui.same_line()
									if imgui.tree_node(materialFullDisplayName .. " Кастомное свойство" .. modDetails.additionalLabel .. " (для теста)") then
										imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
										imgui.same_line()
										imgui.set_next_item_width(200)
										changedValue, material.CustomSingleValueName = imgui.input_text(materialFullDisplayName .. " Имя кастом. св-ва" .. modDetails.additionalLabel, material.CustomSingleValueName)
										meshEdited = meshEdited or changedValue
										if imgui.is_item_hovered() then
											imgui.set_tooltip(materialFullDisplayName .. " Имя кастом. св-ва" .. modDetails.additionalLabel)
										end
										imgui.same_line()
										common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Имя переменной материала меша.\nНапример: Roughness")
										material.SingleValueChanged = material.SingleValueChanged or changedValue
										imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
										imgui.same_line()
										imgui.set_next_item_width(200)
										changedValue, material.CustomSingleValue = imgui.drag_float(materialFullDisplayName .. " Значение кастом. св-ва" .. modDetails.additionalLabel, material.CustomSingleValue, 0.01, -1000000.0, 1000000.0)
										if imgui.is_item_hovered() then
											imgui.set_tooltip(materialFullDisplayName .. " Значение кастом. св-ва" .. modDetails.additionalLabel)
										end
										meshEdited = meshEdited or changedValue
										material.SingleValueChanged = material.SingleValueChanged or changedValue
										imgui.tree_pop()
									end
								end
							end

							if meshMaterialNameFound or meshMaterialColorNameFound then
								imgui.spacing()
								imgui.spacing()
								imgui.text("- " .. materialFullDisplayName .. " Цвета -")

								--local additionalButtonDetails = {}
								--additionalButtonDetails.ColorSourceFunction = GetCharacterSkinColorForColorEdit
								--additionalButtonDetails.ColorSourceFunctionParameter = modDetails
								--additionalButtonDetails.ButtonArrowDirection = 1

								imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
								imgui.same_line()
								changedValue, material.ColorChanged = imgui.checkbox("Применить " .. materialFullDisplayName .. " цвета" .. modDetails.additionalLabel, material.ColorChanged)
								imgui.same_line()
								common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, disablingOptionMessage)
								meshEdited = meshEdited or changedValue

								for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_COLOR) do
									meshMaterialPropertyNameFound2 = string.find(tostring(mmvName):lower(), tempMeshMaterialSearchString:lower())
									if meshMaterialNameFound or meshMaterialPropertyNameFound2 then
										local materialColorFullDisplayName = materialFullDisplayName .. " " .. mmvName .. modDetails.additionalLabel
										--additionalButtonDetails.Label = "Copy Skin Color to " .. materialColorFullDisplayName
										--additionalButtonDetails.ToolTip = "Copy skin color to " .. materialColorFullDisplayName .. "."
										imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
										imgui.same_line()
										if imgui.arrow_button("Копировать значение во все мат. из ".. materialFullDisplayName .. " " .. mmvName .. modDetails.additionalLabel, 1) then
											copyColorValue = material[mmvName]
											copyColorName = mmvName
										end
										if imgui.is_item_hovered() then
											imgui.set_tooltip("Копировать [" .. mmvName .. "] во все [" .. materialFullDisplayName .. "] материалы.")
										end
										local meshColorVec4 = common.ColorStringToVec4(material[mmvName], nil, true)
										imgui.same_line()
										changedValue, meshColorVec4 = common.ColorEdit4WithCopyAndPasteButtons(materialColorFullDisplayName, meshColorVec4, nil, nil) --additionalButtonDetails)
										meshEdited = meshEdited or changedValue
										material.ColorChanged = material.ColorChanged or changedValue
										material[mmvName] = common.Vec4ToColorString(meshColorVec4, true)
									end
								end

								--additionalButtonDetails.Label = "Copy Skin Color to " .. materialFullDisplayName ..  "Custom Color" .. modDetails.additionalLabel
								--additionalButtonDetails.ToolTip = "Copy skin color to " .. materialFullDisplayName ..  "Custom Color" .. modDetails.additionalLabel .. "."

								imgui.spacing()

								if meshMaterialNameFound or string.find(tostring("кастомный цвет"):lower(), tempMeshMaterialSearchString:lower()) then
									imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
									imgui.same_line()
									if imgui.tree_node(materialFullDisplayName .. " Кастомный цвет" .. modDetails.additionalLabel .. " (для теста)") then
										imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
										imgui.same_line()
										imgui.set_next_item_width(200)
										changedValue, material.CustomColorName = imgui.input_text(materialFullDisplayName .. " Имя кастом. цвета" .. modDetails.additionalLabel, material.CustomColorName)
										meshEdited = meshEdited or changedValue
										if imgui.is_item_hovered() then
											imgui.set_tooltip(materialFullDisplayName .. " Имя кастом. цвета" .. modDetails.additionalLabel)
										end
										imgui.same_line()
										common.TextColoredWithOnHoverTooltip("(?)", common.COLOR.GREEN, "Имя переменной материала меша.\nНапример: BaseColor")
										material.ColorChanged = material.ColorChanged or changedValue
										local meshCustomColorVec4 = common.ColorStringToVec4(material.CustomColor, nil, true)
										imgui.text_colored("  o  ", common.COLOR.BGDEFAULT)
										imgui.same_line()
										changedValue, meshCustomColorVec4 = common.ColorEdit4WithCopyAndPasteButtons(materialFullDisplayName .. " Кастомный цвет" .. modDetails.additionalLabel, meshCustomColorVec4, nil, nil) --additionalButtonDetails)
										meshEdited = meshEdited or changedValue
										if imgui.is_item_hovered() then
											imgui.set_tooltip(materialFullDisplayName .. " Кастомный цвет" .. modDetails.additionalLabel)
										end
										material.ColorChanged = material.ColorChanged or changedValue
										material.CustomColor = common.Vec4ToColorString(meshCustomColorVec4, true)
										imgui.tree_pop()
									end
								end
							end
						end
						isPrevEnabled = material.Enabled
						visibleMaterialCount = visibleMaterialCount + 1
					end
				end
			end

			if (copyPropertyValue and copyPropertyName) or (copyColorValue and copyColorName) then
				for matIdx, material in pairs(modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].Materials) do
					if copyPropertyValue and copyPropertyName then
						for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_SINGLE) do
							if copyPropertyName == mmvName then
								material[mmvName] = copyPropertyValue
								material.SingleValueChanged = true
							end
						end
					end
					if copyColorValue and copyColorName then
						for mmvnKey, mmvName in pairs(ENUMS.MESHMATERIALVARIABLENAMES_COLOR) do
							if copyColorName == mmvName then
								material[mmvName] = copyColorValue
								material.ColorChanged = true
							end
						end
					end
				end
				meshEdited = true
			end

			if enableAllCurrentMeshMaterials or disableAllCurrentMeshMaterials then
				meshEdited = true
				modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].MaterialsChanged = true
			end

			local enableAllMeshMaterials = false
			local disableAllMeshMaterials = false

			--enableAllMeshMaterials = imgui.button("Enable All Mesh Materials" .. modDetails.additionalLabel)
			--imgui.same_line()
			--disableAllMeshMaterials = imgui.button("Disable All Mesh Materials" .. modDetails.additionalLabel)

			if enableAllMeshMaterials or disableAllMeshMaterials then
				for comdIdx, comd in pairs(modDetails.characterObjectMeshDetails) do
					if comd and comd.Materials then
						for matIdx, material in pairs(comd.Materials) do
							if enableAllMeshMaterials then
								material.Enabled = true
							end
							if disableAllMeshMaterials then
								material.Enabled = false
							end
						end
						comd.MaterialsChanged = true
					end
				end
				meshEdited = true
			end

		end

		imgui.spacing()
		imgui.spacing()

		local applyMeshEdits = imgui.button("Применить правки меша" .. modDetails.additionalLabel)

		imgui.table_next_row()
		imgui.table_next_column()

		imgui.text(" ")

		if imgui.tree_node("- ПРЕСЕТЫ МЕША -") then

			local tempDataTable = common.deepcopy_table(modDetails.characterObjectMeshDetails, nil)

			local uiDetails = common.SetupCreateEditDeleteDataTableFileUI(tempDataTable, filesList.meshOptionsFolderName, modDetails.meshOptionsPresetName, modDetails.meshOptionsNewPresetName, modDetails, "пресет меша", modDetails.meshOptionsFileExists, modDetails.meshOptionsShouldConfirmDelete)
			modDetails.meshOptionsPresetName = uiDetails.fileName
			modDetails.meshOptionsNewPresetName = uiDetails.newFileName
			meshOptionsPresets = uiDetails.fileNamesList
			meshOptionsPresetsCount = uiDetails.fileNamesListCount
			meshOptionsPresetIndex = uiDetails.fileNamesListIndex
			modDetails.meshOptionsFileExists = uiDetails.fileExists
			modDetails.meshOptionsShouldConfirmDelete = uiDetails.shouldConfirmDelete
			meshEdited = meshEdited or uiDetails.selectedFileChanged or uiDetails.shouldLoadFile

			if uiDetails.shouldLoadFile or (modDetails.shouldAutoReapplyMesh and uiDetails.selectedFileChanged) then
				tempDataTable = common.deepcopy_table(uiDetails.dataTable, nil)
				if tempDataTable[tostring(modDetails.selectedCharacterMeshIndex)] == nil then
					tempDataTable[tostring(modDetails.selectedCharacterMeshIndex)] = {}
				end
				tempDataTable[tostring(modDetails.selectedCharacterMeshIndex)].Materials = {}
				for matIdx, material in pairs(modDetails.characterObjectMeshDetails[tostring(modDetails.selectedCharacterMeshIndex)].Materials) do
					if uiDetails.dataTable[tostring(modDetails.selectedCharacterMeshIndex)] and uiDetails.dataTable[tostring(modDetails.selectedCharacterMeshIndex)].Materials and uiDetails.dataTable[tostring(modDetails.selectedCharacterMeshIndex)].Materials[tostring(matIdx)] then
						tempDataTable[tostring(modDetails.selectedCharacterMeshIndex)].Materials[tostring(matIdx)] = uiDetails.dataTable[tostring(modDetails.selectedCharacterMeshIndex)].Materials[tostring(matIdx)]
					else
						tempDataTable[tostring(modDetails.selectedCharacterMeshIndex)].Materials[tostring(matIdx)] = {}
						tempDataTable[tostring(modDetails.selectedCharacterMeshIndex)].Materials[tostring(matIdx)].Enabled = true
					end
				end
				modDetails.characterObjectMeshDetails = tempDataTable
				meshIDNameChanged = true
				--meshUIInitialized = false
				--updateUIInitializedStatus = false
			end

			imgui.tree_pop()

		end

		if characterIndexChanged then
			meshUIInitialized = false
		elseif updateUIInitializedStatus then
			meshUIInitialized = true
		end

		if (applyMeshEdits or (meshEdited and modDetails.shouldAutoReapplyMesh)) or resetMeshIDs then
			local character = characterHelper.GetManagedCharacter(modDetails.characterIndex, modDetails.config)
			if character then
				local activeMockupDetails = common.GetActiveMockupDetails()
				if meshIDNameChanged or resetMeshIDs then
					SwapCostumePartSwapper(character, modDetails.characterIndex, activeMockupDetails.MockupBuilder, activeMockupDetails.MockupCtrl, modDetails.characterObjectMeshDetails, modDetails.config)
				else
					SetAllCharacterObjectMeshDetails(character, modDetails.characterObjectMeshDetails, activeMockupDetails.MockupBuilder, activeMockupDetails.MockupCtrl)
				end
			end
		end

		imgui.end_table()

	end

	local meshOptionsWindowDetails = {}
	meshOptionsWindowDetails.characterIndexChanged = characterIndexChanged
	meshOptionsWindowDetails.meshEdited = meshEdited
	meshOptionsWindowDetails.config = modDetails.config
	meshOptionsWindowDetails.modCode = modDetails.modCode
	meshOptionsWindowDetails.partyList = modDetails.partyList
	meshOptionsWindowDetails.characterIndex = modDetails.characterIndex
	meshOptionsWindowDetails.selectedCharacterMeshIndex = modDetails.selectedCharacterMeshIndex
	if meshOptionsPresetsCount > -1 then
		meshOptionsWindowDetails.meshOptionsPresetName = meshOptionsPresets[meshOptionsPresetIndex]
	else
		meshOptionsWindowDetails.meshOptionsPresetName = modDetails.meshOptionsPresetName
	end
	meshOptionsWindowDetails.meshOptionsNewPresetName =  modDetails.meshOptionsNewPresetName
	meshOptionsWindowDetails.meshOptionsFileExists = modDetails.meshOptionsFileExists
	meshOptionsWindowDetails.meshOptionsShouldConfirmDelete = modDetails.meshOptionsShouldConfirmDelete
	meshOptionsWindowDetails.characterObjectMeshDetails = modDetails.characterObjectMeshDetails
	--meshOptionsWindowDetails.addMeshSearchTextBoxes = modDetails.addMeshSearchTextBoxes
	--meshOptionsWindowDetails.addMeshIDOverrideTextBoxes = modDetails.addMeshIDOverrideTextBoxes
	--meshOptionsWindowDetails.shouldAutoReapplyMesh = modDetails.shouldAutoReapplyMesh
	meshOptionsWindowDetails.meshUIInitialized = meshUIInitialized
	meshOptionsWindowDetails.meshMaterialSearchString = modDetails.meshMaterialSearchString

	return meshOptionsWindowDetails

end

local function RunCharacterCustomization(character, detailEditType, barberPlace, isPlayer, startFadeDispCallback)
	if character then
		local FacilityManager = sdk.get_managed_singleton("app.FacilityManager")
		if FacilityManager then
			if startFadeDispCallback == nil then
				startFadeDispCallback = FacilityManager.StartBarberFadeDispHandle
			end
			FacilityManager:startBarber(detailEditType, barberPlace, isPlayer, startFadeDispCallback)
		end
	end
end

local function GetCharacterSwapItem(config, partSwapper, characterObjectMeshString, characterObjectMeshDetails, characterIndexOverride)
	local swapItem
	local characterIndex
	local currentCharacterObjectMeshIndex
	for i = 1, #ENUMS.CHARACTEROBJECTMESHES do
		if ENUMS.CHARACTEROBJECTMESHES[i] == characterObjectMeshString then
			currentCharacterObjectMeshIndex = i
			break
		end
	end
	if currentCharacterObjectMeshIndex and partSwapper and partSwapper.get_CharacterID then
		local charaID = partSwapper:get_CharacterID()
		local itemMeshID = nil
		local currentCharacter
		if characterIndexOverride == nil then
			for i = -1, characterHelper.GetFinalManagedCharacterIndex(config) do
				local character = characterHelper.GetManagedCharacter(i, config)
				--if mockupCtrl then
				--	partSwapper = mockupCtrl:get_PartSwapper()
				--elseif mockupBuilder then
				--	partSwapper = mockupBuilder:get_PartSwapper()
				--else
				if character and character.CharacterID == charaID then
					currentCharacter = character
					characterIndex = i
					break
				end
			end
		else
			characterIndex = characterIndexOverride
			currentCharacter = characterHelper.GetManagedCharacter(characterIndex, config)
			if not (currentCharacter and charaID == currentCharacter.CharacterID) then
				characterIndex = nil
			end
		end
		if characterIndex and characterObjectMeshDetails == nil then
			characterObjectMeshDetails = config.characterObjectMeshDetails[tostring(characterIndex)]
		end
		if characterIndex and characterObjectMeshDetails then
			local characterObjectMeshDetailsItem = characterObjectMeshDetails[tostring(currentCharacterObjectMeshIndex)]
			local meshName = characterObjectMeshString
			if meshName then
				meshName = string.gsub(meshName, "_", "")
			else
				meshName = ""
			end
			if ENUMS[meshName .. "IDs"] and (characterObjectMeshDetailsItem and characterObjectMeshDetailsItem.MeshIDNameChanged and characterObjectMeshDetailsItem.MeshIDName) then
				itemMeshID = common.GetCurrentListIndex(ENUMS[meshName .. "IDs"], characterObjectMeshDetailsItem.MeshIDName)
			end
		end
		if characterIndex and itemMeshID then
			swapItem = GetSwapItem(ENUMS.SWAPITEMSEARCHTYPE.MESHID, itemMeshID, characterObjectMeshString, nil)
		end
	end
	return swapItem, characterIndex
end

re.on_frame(function()

	if ceh.Initialized then

		for charCORMOMKey, charCORMOMValue in pairs(ceh.CORMOM) do
			if charCORMOMValue ~= nil then
				if charCORMOMValue.countDown <= 0 then
					local partSwapper = GetPartSwapper(charCORMOMValue.character, charCORMOMValue.mockupBuilder, charCORMOMValue.mockupCtrl)
					if not charCORMOMValue.isMockup or (charCORMOMValue.isMockup and (charCORMOMValue.mockupBuilder or charCORMOMValue.mockupCtrl)) then
						local mockupBuilder = charCORMOMValue.mockupBuilder
						if not mockupBuilder and charCORMOMValue.mockupCtrl then
							mockupBuilder = charCORMOMValue.mockupCtrl:getMockupBuilder()
						end
						if (partSwapper and not partSwapper:get_PartBeingSwapping()) and (not charCORMOMValue.isMockup or (mockupBuilder and mockupBuilder:get_ReadyToShoot())) then
							--local character =  characterHelper.GetManagedCharacter(charCORMOMValue.characterIndex, charCORMOMValue.config)
							RefreshCharacterOrMockupObjectMeshDetails(charCORMOMValue.config, charCORMOMValue.character, charCORMOMValue.characterIndex, charCORMOMValue.mockupBuilder, charCORMOMValue.mockupCtrl, charCORMOMValue.characterObjectMeshDetails)
							for meshDetailsKeys, meshDetailsItem in pairs(charCORMOMValue.characterObjectMeshDetails) do
								meshDetailsItem.ShouldRefresh = true
								if meshDetailsItem.ResetMeshIDName then
									meshDetailsItem.MeshIDNameChanged = false
									meshDetailsItem.ResetMeshIDName = false
								end
							end
							table.remove(ceh.CORMOM, charCORMOMKey)
						else
							charCORMOMValue.countDown = 1
						end
					end
				else
					charCORMOMValue.countDown = charCORMOMValue.countDown - 1
				end
			end
		end

		if (not common.IsPausedGUI() and common.IsPausedGUIBefore("ALL", "RefreshCharacterOrMockupObjectMeshDetails")) then
			ceh.characterObjectMeshDetailsFMR = {}
			common.UpdateIsPausedGUIBefore("ALL", "RefreshCharacterOrMockupObjectMeshDetails")
		end

		if ceh.listsRequireRefreshing and ceh.listRefreshAttempts <= (ceh.listRefreshAttemptsLimit + 1) then
			if ceh.listRefreshDelay <= 0 then
				PopulateLists(true)
				ceh.listRefreshDelay = ceh.listRefreshDelayDefault
				ceh.listRefreshAttempts = ceh.listRefreshAttempts + 1
			else
				ceh.listRefreshDelay = ceh.listRefreshDelay - 1
			end
		end

	end

end)

local characterEditHelper = {

	currentVersion = currentVersion,

	filesList = filesList,

	CURRENTITEMVALUE = CURRENTITEMVALUE,
	CHARACTEREDITTYPES = ENUMS.CHARACTEREDITTYPES,
	CHARACTEREDITTYPE = ENUMS.CHARACTEREDITTYPE,
	COSTUMESOURCES = ENUMS.COSTUMESOURCES,
	COSTUMESOURCE = ENUMS.COSTUMESOURCE,

	GetInitialized = GetInitialized,
	SetInitialized = SetInitialized,

	GetPartSwapper = GetPartSwapper,
	GetCharacterObjectMesh = GetCharacterObjectMesh,
	RefreshMeshMaterialVariableNamesData = RefreshMeshMaterialVariableNamesData,

	GetDefaultCostumeDetails = GetDefaultCostumeDetails,
	GetDefaultCostumeVariationStyleDetails = GetDefaultCostumeVariationStyleDetails,
	GetDefaultWeaponDetails = GetDefaultWeaponDetails,
	GetCharacterDefaultMeshDetailsItem = GetCharacterDefaultMeshDetailsItem,
	GetDefaultCharacterObjectMeshDetails = GetDefaultCharacterObjectMeshDetails,

	CostumeCustomizationInstructions = function() return CostumeCustomizationInstructions end,

	HelmStyles = function() return ENUMS.HelmStyles end,
	HelmVariationStyles = function() return ENUMS.HelmVariationStyles end,
	FacewearStyles = function() return ENUMS.FacewearStyles end,
	FacewearVariationStyles = function() return ENUMS.FacewearVariationStyles end,
	TopsStyles = function() return ENUMS.TopsStyles end,
	TopsVariationStyles = function() return ENUMS.TopsVariationStyles end,
	BackpackStyles = function() return ENUMS.BackpackStyles end,
	PantsStyles = function() return ENUMS.PantsStyles end,
	PantsVariationStyles = function() return ENUMS.PantsVariationStyles end,
	MantleStyles = function() return ENUMS.MantleStyles end,
	MantleVariationStyles = function() return ENUMS.MantleVariationStyles end,
	UnderwearStyles = function() return ENUMS.UnderwearStyles end,
	UnderwearVariationStyles = function() return ENUMS.UnderwearVariationStyles end,

	TopsBdMeshIDs = function() return ENUMS.TopsBdMeshIDs end,
	TopsBdSubMeshIDs = function() return ENUMS.TopsBdSubMeshIDs end,
	TopsWbMeshIDs = function() return ENUMS.TopsWbMeshIDs end,
	TopsWbSubMeshIDs = function() return ENUMS.TopsWbSubMeshIDs end,
	TopsAmMeshIDs = function() return ENUMS.TopsAmMeshIDs end,
	TopsAmSubMeshIDs = function() return ENUMS.TopsAmSubMeshIDs end,
	TopsBtMeshIDs = function() return ENUMS.TopsBtMeshIDs end,
	TopsBtSubMeshIDs = function() return ENUMS.TopsBtSubMeshIDs end,
	PantsLgMeshIDs = function() return ENUMS.PantsLgMeshIDs end,
	PantsLgSubMeshIDs = function() return ENUMS.PantsLgSubMeshIDs end,
	PantsWlMeshIDs = function() return ENUMS.PantsWlMeshIDs end,
	PantsWlSubMeshIDs = function() return ENUMS.PantsWlSubMeshIDs end,
	HelmMeshIDs = function() return ENUMS.HelmMeshIDs end,
	HelmSubMeshIDs = function() return ENUMS.HelmSubMeshIDs end,
	MantleMeshIDs = function() return ENUMS.MantleMeshIDs end,
	BackpackMeshIDs = function() return ENUMS.BackpackMeshIDs end,
	FacewearMeshIDs = function() return ENUMS.FacewearMeshIDs end,
	UnderwearMeshIDs = function() return ENUMS.UnderwearMeshIDs end,

	PlayerVoiceTypes = function() return ENUMS.PlayerVoiceTypes end,
	PersonalityIDs = function() return ENUMS.PersonalityIDs end,
	VoiceToneTypes = function() return ENUMS.VoiceToneTypes end,

	JobEnum = function() return ENUMS.JobEnum end,

	WeaponData = function() return ENUMS.WeaponData end,

	CHARACTEROBJECTMESHES = ENUMS.CHARACTEROBJECTMESHES,

	SetEPCode = SetEPCode,
	repc = repc,
	PopulateLists = PopulateLists,
	SetCommon = SetCommon,
	IsCharacterReadyToBeEdited = IsCharacterReadyToBeEdited,
	GetEditValues = GetEditValues,
	EditHair = EditHair,
	EditEyeliner = EditEyeliner,
	EditEyeshadowBase = EditEyeshadowBase,
	EditEyeshadow = EditEyeshadow,
	EditCheek = EditCheek,
	EditLips = EditLips,
	EditFurFacePattern = EditFurFacePattern,
	EditFur = EditFur,
	EditEyes = EditEyes,
	EditEyelashBase = EditEyelashBase,
	EditEyelashes = EditEyelashes,
	EditEyebrows = EditEyebrows,
	EditTeeth = EditTeeth,
	EditFreckles = EditFreckles,
	EditNose = EditNose,
	EditSkin = EditSkin,
	EditClaws = EditClaws,
	EditBodyHair = EditBodyHair,
	EditFurPattern = EditFurPattern,
	EditDirt = EditDirt,
	EditTattoo = EditTattoo,
	EditTattoos = EditTattoos,
	EditScar = EditScar,
	EditScars = EditScars,
	EditPretender = EditPretender,
	GetCharacterCustomizationItemsFromPartSwapper = GetCharacterCustomizationItemsFromPartSwapper,
	GetCharacterCustomizationItemsCCS = GetCharacterCustomizationItemsCCS,
	GetCharacterCustomizationItems = GetCharacterCustomizationItems,
	GetCharacterSkinColor = GetCharacterSkinColor,
	GetLastEditedBodyDetailData = GetLastEditedBodyDetailData,
	EditCharacterBodyDetailsUsingCustomData = EditCharacterBodyDetailsUsingCustomData,
	EditCharacterBodyDetailsUsingAppearanceData = EditCharacterBodyDetailsUsingAppearanceData,
	GetAppearanceDatas = GetAppearanceDatas,
	GetAppearanceData = GetAppearanceData,
	GetCostumeDatas = GetCostumeDatas,
	GetCostumeData = GetCostumeData,
	HasAppearanceDataMatch = HasAppearanceDataMatch,
	GetContextHolderContext = GetContextHolderContext,
	GetCharacterCustomizationDataFromPartSwapper = GetCharacterCustomizationDataFromPartSwapper,
	GetCharacterCustomizationData = GetCharacterCustomizationData,
	CharacterEditManagerRequestLimiterRemoval = CharacterEditManagerRequestLimiterRemoval,
	HumanEditControllerSetEditLimited = HumanEditControllerSetEditLimited,
	GetCharacterEditDefineMetaData = GetCharacterEditDefineMetaData,
	EditCostumeMetaVariationStyles = EditCostumeMetaVariationStyles,
	EditCostumeMeta = EditCostumeMeta,
	GetHeadAppearanceMeta = GetHeadAppearanceMeta,
	EditHeadAppearanceMeta = EditHeadAppearanceMeta,
	GetBodyDetailAppearanceMeta = GetBodyDetailAppearanceMeta,
	EditBodyDetailAppearanceMeta = EditBodyDetailAppearanceMeta,
	EditAppearanceMeta = EditAppearanceMeta,
	GetCostumeVariationStylesMeta = GetCostumeVariationStylesMeta,
	GetCostumeMeta = GetCostumeMeta,
	GetDefaultCostumeMeta = GetDefaultCostumeMeta,
	EditCostumePartSwapperMeta = EditCostumePartSwapperMeta,
	EditCharacterCostumeMeta = EditCharacterCostumeMeta,
	EditCharacterAppearanceMeta = EditCharacterAppearanceMeta,
	ResetAppearanceMeta = ResetAppearanceMeta,
	EditEditorDataUsingEditValueData = EditEditorDataUsingEditValueData,
	EditEditorDataUsingEditValueDataTable = EditEditorDataUsingEditValueDataTable,
	EditCharacterHeadAndBodyUsingCustomData = EditCharacterHeadAndBodyUsingCustomData,
	EditCharacterHeadAndBodyUsingNPCDetailsCCS = EditCharacterHeadAndBodyUsingNPCDetailsCCS,
	EditCharacterHeadAndBodyUsingNPCDetails, EditCharacterHeadAndBodyUsingNPCDetails,
	EditPartSwapperUsingCustomData = EditPartSwapperUsingCustomData,
	EditPartSwapperUsingNPCDetails = EditPartSwapperUsingNPCDetails,
	EditCharacterDataUsingNPCDetailsCCS = EditCharacterDataUsingNPCDetailsCCS,
	EditCharacterDataUsingNPCDetails = EditCharacterDataUsingNPCDetails,
	EditCharacterFromAnywhereUsingCustomData = EditCharacterFromAnywhereUsingCustomData,
	EditCharacterUsingCharacterCustomizationData = EditCharacterUsingCharacterCustomizationData,
	EditCharacterFromCCSUsingNPCDetails = EditCharacterFromCCSUsingNPCDetails,
	EditCharacterFromAnywhereUsingCharacterCustomizationData = EditCharacterFromAnywhereUsingCharacterCustomizationData,
	EditCharacterFromAnywhereUsingNPCDetails = EditCharacterFromAnywhereUsingNPCDetails,
	GetRemoveUnknownGenderStyles = GetRemoveUnknownGenderStyles,
	SetRemoveUnknownGenderStyles = SetRemoveUnknownGenderStyles,
	ResetCostume = ResetCostume,
	GetCharacterObjectMeshDetailsItem = GetCharacterObjectMeshDetailsItem,
	IsMeshIDNameChanged = IsMeshIDNameChanged,
	IsMeshIDNamesChanged = IsMeshIDNamesChanged,
	GetSwapitem = GetSwapitem,
	ResetCostumeMeshID = ResetCostumeMeshID,
	GetMeshID = GetMeshID,
	GetPawnPersonalityAndVoice = GetPawnPersonalityAndVoice,
	SetPawnPersonalityAndVoice = SetPawnPersonalityAndVoice,
	PartSwapperVisorSwitch = PartSwapperVisorSwitch,
	VisorSwitch = VisorSwitch,
	SetEmptyCostume = SetEmptyCostume,
	SwapCostumePartSwapper = SwapCostumePartSwapper,
	GetAndRefreshCharacterObjectMeshDetailsItem = GetAndRefreshCharacterObjectMeshDetailsItem,
	SetCharacterObjectMeshDetailsItem = SetCharacterObjectMeshDetailsItem,
	SetAllCharacterObjectMeshDetails = SetAllCharacterObjectMeshDetails,
	GetCharacterMockupBuilder = GetCharacterMockupBuilder,
	GetCloneOrMockupBuilderCharaID = GetCloneOrMockupBuilderCharaID,
	RefreshClone = RefreshClone,
	AddCORMOM = AddCORMOM,
	RefreshMockupFace = RefreshMockupFace,
	RefreshMockupAndMockupFace = RefreshMockupAndMockupFace,
	RefreshCostumeData = RefreshCostumeData,
	SetWeapons = SetWeapons,
	LoadWeapons = LoadWeapons,
	ResetWeapons = ResetWeapons,
	VisorSwitchFromCostumeOptions = VisorSwitchFromCostumeOptions,
	LoadCurrentCostumeFromCostumeOptions = LoadCurrentCostumeFromCostumeOptions,
	ApplyCostumeFromCostumeOptions = ApplyCostumeFromCostumeOptions,
	RemoveHelmFacewearAndMantleFromCostumeOptions = RemoveHelmFacewearAndMantleFromCostumeOptions,
	ResetCostumeFromCostumeOptions = ResetCostumeFromCostumeOptions,
	SetupCostumeOptionsUI = SetupCostumeOptionsUI,
	SetWeaponsFromWeaponOptions = SetWeaponsFromWeaponOptions,
	LoadWeaponsFromWeaponOptions = LoadWeaponsFromWeaponOptions,
	ResetWeaponsFromWeaponOptions = ResetWeaponsFromWeaponOptions,
	SetupWeaponOptionsUI = SetupWeaponOptionsUI,
	SetupCostumeWeaponOptionsUI = SetupCostumeWeaponOptionsUI,
	RefreshCharacterOrMockupObjectMeshDetails = RefreshCharacterOrMockupObjectMeshDetails,
	RefreshMockup = RefreshMockup,
	RefreshMockupsAndMockupFaces = RefreshMockupsAndMockupFaces,
	RefreshManagedCharacterCostumeVariationStyles = RefreshManagedCharacterCostumeVariationStyles,
	RefreshManagedCharactersCostumeVariationStyles = RefreshManagedCharactersCostumeVariationStyles,
	SetupMeshOptionsUI = SetupMeshOptionsUI,
	RunCharacterCustomization = RunCharacterCustomization,
	GetCharacterSwapItem = GetCharacterSwapItem

}

return characterEditHelper

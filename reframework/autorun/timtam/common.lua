local currentVersion = "1.1.18"

local otherVariables = {}
otherVariables.LogLimit = 1000
otherVariables.CustomLogText = {}
otherVariables.CurrentLogCount = 0
otherVariables.ColorEdit4Value = nil


--local CJK_GLYPH_RANGES = {
--	0x0001, 0xFFFF, -- load all glyphs
--	0,
--}

local COLOR = {
	BGDEFAULT = 0xFF1A1B1C,
	BLACK = 0xFF000000,
	WHITE = 0xFFFFFFFF,
	DARKGRAY = 0xFF202020, --0xFF202020
	GRAY = 0xFF262727, --0xFF272726
	LIGHTGRAY = 0xFF403F3E, --0xFF3E3F40
	HP = 0xFF8BD4C4, --0xFFC4D48B
	HPCRITICAL = 0xFF3638C7, --0xFFC73836
	HPCRITICAL2 = 0xFF5E82B0, --0xFFB0825E
	STM = 0xFF416577, --0xFF776541
	STMCRITICAL = 0xFF72B8C2, --0xFFC2B872
	STMCRITICAL2 = 0xFFA0F1F2, --0xFFF2F1A0
	DARKGREEN = 0xFF477E37, --0xFF377E47
	GREEN = 0xFF4FFAA1, --0xFFA1FA4F
	ORANGE = 0xFF599BF0, --0xFFF09B59	
	DARKRED = 0xFF00008B, --0xFF8B0000	
	RED = 0xFF2433EB, --0xFFEB3324
	LIGHTRED = 0xFF8487F0, --0xFFF08784
	DARKBLUE = 0xFF7C4116, --0xFF16417C
	BLUE = 0xFFF52300, --0xFF0023F5
	LIGHTBLUE = 0xFFF68232, --0xFF3282F6
	PURPLE = 0xFFF52B73, --0xFF732BF5
	LIGHTPURPLE = 0xFFF7847E, --0xFF7E84F7
	PINK = 0xFFBE88EF, --0xFFEF88BE
	YELLOW = 0xFF55FDFF, --0xFFFFFD55,
	BROWN = 0xFF194E8C, --0xFF8C4E19,
	TEAL = 0xFFABAA49 --0xFF49AAAB
}

local DELAYTIMERSTATUS = {
	NONE = 0,
	OFF = 1,
	RUNNING = 2 
}

local WINDOWPOSITIONS = {
	[0] = "Bottom Left",
	[1] = "Bottom Center",
	[2] = "Bottom Right",
	[3] = "Middle Left",
	[4] = "Middle Center",
	[5] = "Middle Right",
	[6] = "Top Left",
	[7] = "Top Center",
	[8] = "Top Right"
}

local WINDOWPOSITION = {
	BOTTOMLEFT = 0,
	BOTTOMCENTER = 1,
	BOTTOMRIGHT = 2,
	MIDDLELEFT = 3,
	MIDDLECENTER = 4,
	MIDDLERIGHT = 5,
	TOPLEFT = 6,
	TOPCENTER = 7,
	TOPRIGHT = 8 
}

local delayTimer = {}

local buttonClicked = {}
local showWindow = {}
local isWindowRefreshed = {}
local isWindowInitialized = {}

--local font = {}
--font[0] = nil imgui.load_font(nil, 19, CJK_GLYPH_RANGES)
--font[1] = nil imgui.load_font(nil, 14, CJK_GLYPH_RANGES)

local customList = {
	["app.StatusConditionDef.StatusConditionFlag"] = {},
	["app.CharacterID"] = {},
	["NPCDetailsList"] = {}
	}
local isCustomListPopulated = {
	["app.StatusConditionDef.StatusConditionFlag"] = false,
	["app.CharacterID"] = false,
	["NPCDetailsList"] = false
	}

local function CopyArrayItemValueIfNotNull(destinationArray, sourceArray, propertyName)
	if destinationArray and sourceArray and sourceArray[propertyName] ~= nil then
		destinationArray[propertyName] = sourceArray[propertyName]
	end
end

--https://www.tutorialspoint.com/lua/lua_split_string.htm
local function split(inputstr, sep)
   -- if sep is null, set it as space
   if sep == nil then
      sep = '%s'
   end
   -- define an array
   local t={}
   -- split string based on sep
   for str in string.gmatch(inputstr, '([^'..sep..']+)')
   do
      -- insert the substring in table
      table.insert(t, str)
   end
   -- return the array
   return t
end
	
local function IsPlayerCharacterReady()
	local CharacterManager = sdk.get_managed_singleton("app.CharacterManager")
	local playerCharacter = CharacterManager["<ManualPlayer>k__BackingField"]
	if playerCharacter and playerCharacter:get_Valid() then
		return true
	end
	return false
end

local function GetLog(index)
	return otherVariables.CustomLogText[index]
end

local function log(newText)
	if otherVariables.CurrentLogCount < otherVariables.LogLimit then
		otherVariables.CustomLogText[otherVariables.CurrentLogCount] = tostring(newText)
		otherVariables.CurrentLogCount = otherVariables.CurrentLogCount + 1
	end
end

local function clearLog()
	otherVariables.CustomLogText = {}
	otherVariables.CurrentLogCount = 0
end

local function SetupCustomLogUI()
	local tempLog = ""
	for i = 0, #otherVariables.CustomLogText do
		if otherVariables.CustomLogText[i] then
			if i > 0 then
				tempLog = tempLog .. "\n"
			end
			tempLog = tempLog .. otherVariables.CustomLogText[i]
		end
	end
	--imgui.text(tempLog)
	imgui.input_text_multiline("Custom Log", tempLog, {445, 250})
	if imgui.button("Очистить журнал") then
		clearLog()
	end
end

local function StartDelayTimer(timerName, delayTime)
	delayTimer[timerName] = os.clock()
	if delayTime > 0.0 then
		delayTimer[timerName] = delayTimer[timerName] + (delayTime)
	end
end

local function GetDelayTimerStatus(timerName)
	local timerStatus = DELAYTIMERSTATUS.NONE
	if delayTimer[timerName] then
		if os.clock() < delayTimer[timerName] then
			timerStatus = DELAYTIMERSTATUS.RUNNING
		else
			timerStatus = DELAYTIMERSTATUS.OFF
		end
	end
	return timerStatus
end

local function DeleteDelayTimer(timerName)
	delayTimer[timerName] = nil
end

local function IsLoadGUIWithTimer(delayTimer)
	local isLoading = false
	currentDelayTime = delayTimer
	local GuiManager = sdk.get_managed_singleton("app.GuiManager")
	if GuiManager:get_IsLoadGui() or GetDelayTimerStatus("LoadGUI") == DELAYTIMERSTATUS.RUNNING then
		if GuiManager:get_IsLoadGui() then
			StartDelayTimer("LoadGUI", delayTimer)
		end
		isLoading = true 
	end
	return isLoading
end

local function IsLoadGUI()
	local GuiManager = sdk.get_managed_singleton("app.GuiManager")
	return GuiManager:get_IsLoadGui()
end

local function IsPausedGUI()
	local GuiManager = sdk.get_managed_singleton("app.GuiManager")
	return GuiManager:isPausedGUI()
end

local function IsInterruptedGUI()
	local GuiManager = sdk.get_managed_singleton("app.GuiManager")		
	if GuiManager:isPausedGUI()
		or GuiManager:get_IsLoadGui()
		then
		return true
	end	
	if GuiManager.isDispTalkSelect and GuiManager:isDispTalkSelect() then
		return true
	end	
	if GuiManager.isDispControllerLostDialog and GuiManager:isDispControllerLostDialog() then
		return true
	end	
	if GuiManager.isDispTutorialNotcie and GuiManager:isDispTutorialNotcie() then
		return true
	end	
	if GuiManager.isDispQuestNotice and GuiManager:isDispQuestNotice() then
		return true
	end	
	if GuiManager.isDispCutScenePause and GuiManager:isDispCutScenePause() then
		return true
	end	
	return false
end

local isLoadGUIBefore = {}
local function IsLoadGUIBefore(modname, functionName)
	if isLoadGUIBefore[modname] == nil then
		isLoadGUIBefore[modname] = {}
	end
	if isLoadGUIBefore[modname][functionName] == nil then
		isLoadGUIBefore[modname][functionName] = false
	end
	return isLoadGUIBefore[modname][functionName]
end

local function UpdateIsLoadingBefore(modname, functionName)
	if isLoadGUIBefore[modname] == nil then
		isLoadGUIBefore[modname] = {}
	end
	isLoadGUIBefore[modname][functionName] = IsLoadGUI()
end

local isPausedGUIBefore = {}
local function IsPausedGUIBefore(modname, functionName)
	if isPausedGUIBefore[modname] == nil then
		isPausedGUIBefore[modname] = {}
	end
	if isPausedGUIBefore[modname][functionName] == nil then
		isPausedGUIBefore[modname][functionName] = false
	end
	return isPausedGUIBefore[modname][functionName]
end

local function UpdateIsPausedGUIBefore(modname, functionName)
	if isPausedGUIBefore[modname] == nil then
		isPausedGUIBefore[modname] = {}
	end
	isPausedGUIBefore[modname][functionName] = IsPausedGUI()
end

local isInterruptedGUIBefore = {}
local function IsInterruptedGUIBefore(modname, functionName)
	if isInterruptedGUIBefore[modname] == nil then
		isInterruptedGUIBefore[modname] = {}
	end
	if isInterruptedGUIBefore[modname][functionName] == nil then
		isInterruptedGUIBefore[modname][functionName] = false
	end
	return isInterruptedGUIBefore[modname][functionName]
end

local function UpdateIsInterruptedGUIBefore(modname, functionName)
	if isInterruptedGUIBefore[modname] == nil then
		isInterruptedGUIBefore[modname] = {}
	end
	isInterruptedGUIBefore[modname][functionName] = IsInterruptedGUI()
end

--https://cursey.github.io/reframework-book/examples/Example-Snippets.html
-- Find a component contained in a game object by its type name
local function get_component(game_object, type_name)
    local t = sdk.typeof(type_name)

    if t == nil then 
        return nil
    end

    return game_object:call("getComponent(System.Type)", t)
end

-- Get all components of a game object as a table
local function get_components(game_object)
    local transform = game_object:call("get_Transform")

    if not transform then
        return {}
    end

    return game_object:call("get_Components"):get_elements()
end

local function generate_enum(typename, convertValueToString)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

	local convertToString = false
	if convertValueToString then
		convertToString = true
	end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

			if convertToString then
				enum[name] = tostring(raw_value)
			else
				enum[name] = raw_value
			end
        end
    end

    return enum
end

local function generate_enum_reverse(typename, convertValueToString)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

	local convertToString = false
	if convertValueToString then
		convertToString = true
	end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

			if convertToString then
				enum[raw_value] = tostring(name)
			else
				enum[raw_value] = name
			end
        end
    end

    return enum
end

local function edit_enum(enum, name, value, convertValueToString)
	local convertToString = false
	if convertValueToString then
		convertToString = true
	end
	if convertToString then
            enum[value] = tostring(name)
	else
            enum[value] = name
	end
	return enum
end

local function FindStringLastInstance(fullstring, searchstring, init, pattern)
	local startindex, endindex, nextendindex
	local nextstartindex = 0
	while nextstartindex ~= nil and nextstartindex < string.len(fullstring) do
		nextstartindex, nextendindex = string.find(fullstring, searchstring, init, pattern)
		if nextstartindex ~= nil then
			startindex = nextstartindex
			endindex = nextendindex
			init = nextstartindex + 1
		end
	end
	return startindex, endindex
end

local function RemoveSuffix(fullstring, suffix)
	local newstring = fullstring
	local suffixStart = FindStringLastInstance(newstring, suffix)
	if suffixStart ~= nil and suffixStart > 0 then
		newstring = string.sub(newstring, 1 , suffixStart - 1)
	end
	return newstring
end

local function ContainsString(originalString, findString)
	local findIndex = FindStringLastInstance(originalString, findString)
	if findIndex ~= nil and findIndex > 0 then
		return true
	end
	return false
end

--https://stackoverflow.com/questions/4990990/check-if-a-file-exists-with-lua
local function file_exists(name)
   local f = io.open(name, "r")
   return f ~= nil and io.close(f)
end

--https://stackoverflow.com/questions/15429236/how-to-check-if-a-module-exists-in-lua
local function isModuleAvailable(name)
  if package.loaded[name] then
    return true
  else
    for _, searcher in ipairs(package.searchers or package.loaders) do
      local loader = searcher(name)
      if type(loader) == 'function' then
        package.preload[name] = loader
        return true
      end
    end
    return false
  end
end

local function isModuleLoaded(name)
  if package.loaded[name] then
    return true
  else
    return false
  end
end

local GENDER = generate_enum("app.Gender", false)
local GENDER_CODE = generate_enum_reverse("app.Gender", false)
local SPECIES = generate_enum("app.Species", false)
local SPECIES_CODE = generate_enum_reverse("app.Species", false)

local PLATFORMENVIRONMENT = generate_enum("app.PlatformEnvironment", false)
local PLATFORMENVIRONMENT_CODE = generate_enum_reverse("app.PlatformEnvironment", false)

local NETWORKSERVICETYPE = generate_enum("via.network.ServiceType", false)
local NETWORKSERVICETYPE_CODE = generate_enum_reverse("via.network.ServiceType", false)

--local GENDER = {
--	NONE = 0,
--	MALE = 2776536455, -- -1518430841
--	FEMALE = 1910070090
--}

--local SPECIES = {
--	HUMAN = 2501532887, -- -1793434409
--	BEASTMAN = 3666037007 -- -628930289
--}

local function GetBooleanValue(bool)
	if bool == null or tostring(bool) == "" then
		bool = false
	end
	return bool
end

local function ChangeToDefaultIfNil(originalValue, defaultValue)
	if originalValue then
		return originalValue
	else
		return defaultValue
	end
end

local function ChangeToDefaultIfNotANumber(originalValue, defaultValue)
	if tonumber(originalValue) then
		return tonumber(originalValue)
	else
		return defaultValue
	end
end

local function NewValueType(objectTypeName)
	return ValueType.new(sdk.find_type_definition(objectTypeName))
end

local function NewObjectInstance(objectTypeName)
	local newInstance = sdk.create_instance(objectTypeName)
	if newInstance then
		return newInstance:add_ref()
    	end
	return nil
end

local function GetMethod(objectTypeName, methodName)
	return sdk.find_type_definition(objectTypeName):get_method(methodName)
end

local function ReplicateString(stringToReplicate, replicateCount)
	local newString = ""
	for i = 0, replicateCount - 1 do
		newString = newString .. tostring(stringToReplicate)
	end
	return newString
end

local function NormalizeID(currentID, convertToNumber, matchString)
	if matchString == nil then
		matchString = "(.*)%."
	end
	if currentID then
		local isnumber = type(myVar) == "number"
		local newID = tostring(currentID):match(matchString)
		if newID == nil then
			if isnumber or convertToNumber then
				newID = tonumber(currentID)
			else
				newID = currentID
			end
		end
		return newID
	end
	return nil
end

--https://www.tutorialspoint.com/lua/lua_file_existing_check.htm
-- check if file exists
function file_exists(filename)

   local isPresent = true
   -- Opens a file
   f = io.open(filename, "r")

   -- if file is not present, f will be nil
   if not f then
      isPresent = false
   else
      -- close the file  
      f:close()
   end

   -- return status
   return isPresent
end

--http://lua-users.org/wiki/CopyTable
-- Save copied tables in `copies`, indexed by original table.
local function deepcopy_table(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy_table(orig_key, copies)] = deepcopy_table(orig_value, copies)
            end
            setmetatable(copy, deepcopy_table(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local fileNamesList = {}
local fileList = {}
local isFileListLoaded = {}

local function GetFileList(folderName)
		fileList[folderName] = {}
		fileList[folderName] = fs.glob(folderName .. "\\\\.*json")
	return fileList[folderName]
end

--https://stackoverflow.com/questions/77810553/remove-both-path-and-extension-from-string-in-lua
local function RefreshFileNamesList(folderName)
	if not isFileListLoaded[folderName] then
		fileNamesList[folderName] = {}
		local files = GetFileList(folderName)
		if files then
			for i, file in ipairs(files) do
				local filename, extension = file:match("^.+\\(.+)%.(.+)$")
				fileNamesList[folderName][i] = filename
			end
			isFileListLoaded[folderName] = true
		end
	end
end

local function SetIsFileListLoaded(folderName, value)
	isFileListLoaded[folderName] = value
end

local fileDataTable = {}
local isFileDataTableLoaded = {}

local function GetDataTableFromFile(pFileName, folderName, returnOriginal)
	if pFileName then
		if isFileDataTableLoaded[folderName] == nil then
			isFileDataTableLoaded[folderName] = {}
		end
		if isFileDataTableLoaded[folderName][pFileName] == nil then
			isFileDataTableLoaded[folderName][pFileName] = false
		end
		if not isFileDataTableLoaded[folderName][pFileName] then
			if fileDataTable == nil then
				fileDataTable= {}
			end
			if fileDataTable[folderName] == nil then
				fileDataTable[folderName] = {}
			end
			if fileNamesList[folderName] == nil then
				RefreshFileNamesList(folderName)
			end
			if fileNamesList[folderName] then
				fileDataTable[folderName][pFileName] = json.load_file(folderName .. "\\" .. pFileName .. ".json")
				if fileDataTable[folderName][pFileName] then
					isFileDataTableLoaded[folderName][pFileName] = true
				end
			end
		end
		if not returnOriginal then
			return deepcopy_table(fileDataTable[folderName][pFileName], nil)
		else
			return fileDataTable[folderName][pFileName]
		end
	end
	return nil
end

local function SetIsFileDataTableLoaded(folderName, pFileName, value)
	if isFileDataTableLoaded[folderName] == nil then
		isFileDataTableLoaded[folderName] = {}
	end
	if pFileName then
		isFileDataTableLoaded[folderName][pFileName] = value
	end
end

local function GetFileNamesList(folderName)
	return fileNamesList[folderName]
end

--local function GetFont(index)
--	return font[index]
--end

--local function SetFont(index, newfont)
--	font[index] = newfont
--end

local function GetButtonClicked(buttonName)
	return GetBooleanValue(buttonClicked[buttonName])
end

local function SetButtonClicked(buttonName, isVisible)
	buttonClicked[buttonName] = GetBooleanValue(isVisible)
end

local function GetShowWindow(windowName)
	return GetBooleanValue(showWindow[windowName])
end

local function GetShowWindowPrev(windowName)
	return GetBooleanValue(isWindowRefreshed[windowName])
end

local function SetShowWindow(windowName, isVisible)
	isWindowRefreshed[windowName] = GetShowWindow(windowName)
	showWindow[windowName] = GetBooleanValue(isVisible)
end

local function GetCustomList(find_type_definition_name)
	if not isCustomListPopulated[find_type_definition_name] then		
		customList[find_type_definition_name] = {}
		for i, field in pairs(sdk.find_type_definition(find_type_definition_name):get_fields()) do
			if field:get_data() then
				customList[find_type_definition_name][field:get_data()] = tostring(field:get_name())
			end
		end
		isCustomListPopulated[find_type_definition_name] = true
	end
	return customList[find_type_definition_name]
end

local function SetCustomList(listName, pCustomList)
	customList[listName] = pCustomList
end

local function GetCustomListIsPopulated(listName)
	return GetBooleanValue(isCustomListPopulated[listName])
end

local function SetCustomListIsPopulated(listName, isPopulated)
	isCustomListPopulated[listName] = GetBooleanValue(isPopulated)
end

local function GetListItem(list, index)
	if list then
		return list[index]
	end
	return nil
end

local function Vec4ToTable(vec3Object)
	local vec3Table = {}
	vec3Table.x = 0
	vec3Table.y = 0
	vec3Table.z = 0
	if vec3Object then
		vec3Table.x = vec3Object.x
		vec3Table.y = vec3Object.y
		vec3Table.z = vec3Object.z
	end
	return vec3Table
end

local function TableToVec3(vec3Table)
	local vecX = 0
	local vecY = 0
	local vecZ = 0
	if vec3Table then
		if vec3Table.x then
			vecX = vec3Table.x
		end
		if vec3Table.y then
			vecY = vec3Table.y
		end
		if vec3Table.z then
			vecZ = vec3Table.z
		end
	end
	return Vector3f.new(vecX, vecY, vecZ)
end

local function GetVec3String(vec3Object)
	local vec3String = ""
	if vec3Object then
		vec3String = "<x [" .. tostring(vec3Object.x) .. "]>"
			.. " <y [" .. tostring(vec3Object.y) .. "]>"
			.. " <z [" .. tostring(vec3Object.z) .. "]>"
	end
	return vec3String
end

local function Vec4ToTable(vec4Object)
	local vec4Table = {}
	vec4Table.x = 0
	vec4Table.y = 0
	vec4Table.z = 0
	vec4Table.w = 0
	if vec4Object then
		vec4Table.x = vec4Object.x
		vec4Table.y = vec4Object.y
		vec4Table.z = vec4Object.z
		vec4Table.w = vec4Object.w
	end
	return vec4Table
end

local function TableToVec4(vec4Table)
	local vecX = 0
	local vecY = 0
	local vecZ = 0
	local vecW = 0
	if vec4Table then
		if vec4Table.x then
			vecX = vec4Table.x
		end
		if vec4Table.y then
			vecY = vec4Table.y
		end
		if vec4Table.z then
			vecZ = vec4Table.z
		end
		if vec4Table.w then
			vecW = vec4Table.w
		end
	end
	return Vector4f.new(vecX, vecY, vecZ, vecW)
end

local function GetVec4String(vec4Object)
	local vec4String = ""
	if vec4Object then
		vec4String = "<x [" .. tostring(vec4Object.x) .. "]>"
			.. " <y [" .. tostring(vec4Object.y) .. "]>"
			.. " <z [" .. tostring(vec4Object.z) .. "]>"
			.. " <w [" .. tostring(vec4Object.w) .. "]>"
	end
	return vec4String
end

--only applicable to properly sorted lists
local function GetPreviousListItem(itemList, currentItem)
	if itemList then
		local previousItem = currentItem
		for newCurrentItem, value in pairs(itemList) do
			if currentItem == newCurrentItem then
				break
			end
			previousItem = newCurrentItem
		end
		return previousItem
		--if currentItem > 0 then
		--	return currentItem - 1
		--else
		--	return 0
		--end
	end
	return currentItem
end

local function GetCurrentListIndex(itemList, currentItemValue, defaultValue)
	if defaultValue == nil then
		defaultValue = 0
	end
	local currentItem = defaultValue
	if itemList then
		for newCurrentItem, value in pairs(itemList) do
			if currentItemValue == value then
				currentItem = newCurrentItem
			end
		end
	end
	return currentItem
end

--only applicable to properly sorted lists
local function GetNextListItem(itemList, currentItem)
	if itemList then
		local isCurrentItem = false
		for newCurrentItem, value in pairs(itemList) do
			if isCurrentItem then
				return newCurrentItem
			end
			if currentItem == newCurrentItem then
				isCurrentItem = true
			end
		end
		return currentItem
		--if currentItem < #itemList then
		--	return currentItem + 1
		--else
		--	return #itemList
		--end
	end
	return currentItem
end

local function IsKeyboardKeyPressedOrTriggered(keyboardKey, isTriggerCheck)

	local isKeyboardKeyPressedOrTriggered = false

	if keyboardKey then	

		local gamePlayerKeyboard = NewValueType("via.hid.gamePlayer.GamePlayerKeyboard")

		if gamePlayerKeyboard then
			if isTriggerCheck then
				isKeyboardKeyPressedOrTriggered = gamePlayerKeyboard:isTrigger(keyboardKey)
			else
				isKeyboardKeyPressedOrTriggered = gamePlayerKeyboard:isDown(keyboardKey)
			end
		end
	end

	return isKeyboardKeyPressedOrTriggered

end

local function IsGamePadButtonPressedOrTriggered(gamePadButton, isTriggerCheck)

	local isGamePadButtonPressedOrTriggered = false

	if gamePadButton then

		local gamePad = NewValueType("via.hid.GamePad")

		if gamePad then
			local gamePadDevice = gamePad:get_Device()
			
			if gamePadDevice then
				if isTriggerCheck then
					isGamePadButtonPressedOrTriggered = gamePadDevice:isTrigger(gamePadButton)
				else
					isGamePadButtonPressedOrTriggered = gamePadDevice:isDown(gamePadButton)
				end
			end
		end

	end

	return isGamePadButtonPressedOrTriggered

end

local function IsKeyPressedOrTriggered(commandHash, isTriggerCheck)

	local isKeyPressedOrTriggered = false

	local UserInputManager = sdk.get_managed_singleton("app.UserInputManager")
	local keyBindController = UserInputManager:get_KeyBindController()

	if keyBindController then

		local keyBindSettingItem = keyBindController:getCurrentKeyBindSetting(commandHash)

		if keyBindSettingItem then

			isKeyPressedOrTriggered = isKeyPressedOrTriggered or IsKeyboardKeyPressedOrTriggered(keyBindSettingItem:get_PrimaryKey(), isTriggerCheck)
			isKeyPressedOrTriggered = isKeyPressedOrTriggered or IsKeyboardKeyPressedOrTriggered(keyBindSettingItem:get_SecondaryKey(), isTriggerCheck)
			isKeyPressedOrTriggered = isKeyPressedOrTriggered or IsKeyboardKeyPressedOrTriggered(keyBindSettingItem:get_ThirdKey(), isTriggerCheck)

		end

	end
	
	return isKeyPressedOrTriggered

end

local function IsButtonPressedOrTriggered(characterInputActionCode, isTriggerCheck)

	local isButtonPressedOrTriggered = false
						
	local UserInputManager = sdk.get_managed_singleton("app.UserInputManager")
	local characterPadAssign = UserInputManager:getCurrentCharacterPadAssign()	

	if characterPadAssign then
		isButtonPressedOrTriggered = IsGamePadButtonPressedOrTriggered(characterPadAssign:getButton(characterInputActionCode), isTriggerCheck)
	end

	return isButtonPressedOrTriggered

end

local function GetFilteredList(list, searchText)
	if list then
		local filteredList = {}
		local tempSearchString = searchText
		tempSearchString = tempSearchString:gsub("%%", "")
		tempSearchString = tempSearchString:gsub("%[", "")
		tempSearchString = tempSearchString:gsub("%(", "")
		for key,value in pairs(list) do
			if string.find(tostring(value):lower(), tempSearchString:lower()) then
				filteredList[key] = value
			end
		end
		return filteredList
	end
	return list
end

local function FindListMatch(list, value, breakIfMatchIsFound)
	local matchCount = 0
	for i, listItem in pairs (list) do
		if listItem == value then
			matchCount = matchCount + 1
			if breakIfMatchIsFound then
				break
			end
		end
	end
	return matchCount
end

local function FindListFieldValueMatch(list, fieldName, value, breakIfMatchIsFound)
	local matchCount = 0
	for i, listItem in pairs (list) do
		if listItem[fieldName] == value then
			matchCount = matchCount + 1
			if breakIfMatchIsFound then
				break
			end
		end
	end
	return matchCount
end

local function AppendItemNamesToListItems(list, typeName)
	if list then		
		local ItemManager = sdk.get_managed_singleton("app.ItemManager")
		local itemName
		for itemKey, itemValue in pairs(list) do	
				local itemCommonParam = ItemManager:call("getItemData(" .. typeName .. ")", itemKey)
				if itemCommonParam then
					itemName = itemCommonParam:get_item_name(itemCommonParam._Id)
					if itemName and itemName ~= "" and itemName ~= "Invalid" then
						list[itemKey] = tostring(itemName) .. " [" .. tostring(itemValue) .. "]"
					end
				end
		end
	end
	return list	
end

local StyleDB = {}
local FemaleStyleDB = {}
local MaleStyleDB = {}
local FemaleStyleDBEnum = {}
local MaleStyleDBEnum = {}

local function GetStyleDB(styleDBName, refreshList)
	if not StyleDB[styleDBName] or refreshList then
		local CharacterEditManager = sdk.get_managed_singleton("app.CharacterEditManager")
		StyleDB[styleDBName] = CharacterEditManager:get_field(styleDBName)
	end
	return StyleDB[styleDBName]
end

local function GetFemaleStyleDB(styleDBName, refreshList)
	if not FemaleStyleDB[styleDBName] or refreshList then
		local styleDB = GetStyleDB(styleDBName)
		if styleDB then
			FemaleStyleDB[styleDBName] = styleDB[GENDER.Female]
		end
	end
	return FemaleStyleDB[styleDBName]
end

local function GetMaleStyleDB(styleDBName, refreshList)
	if not MaleStyleDB[styleDBName] or refreshList then
		local styleDB = GetStyleDB(styleDBName)
		if styleDB then
			MaleStyleDB[styleDBName] = styleDB[GENDER.Male]
		end
	end
	return MaleStyleDB[styleDBName]
end

local function GetFemaleStyleDBEnum(styleDBName, refreshList)
	if not FemaleStyleDBEnum[styleDBName] or refreshList then
		local femaleStyleDB = GetFemaleStyleDB(styleDBName)
		if femaleStyleDB then
			local femaleStyleDBEnum = {}
			for itemKey, itemValue in pairs(femaleStyleDB._entries) do
				femaleStyleDBEnum[itemValue.key] = itemValue.value
			end
			FemaleStyleDBEnum[styleDBName] = femaleStyleDBEnum
		end
	end
	return FemaleStyleDBEnum[styleDBName]
end

local function GetMaleStyleDBEnum(styleDBName, refreshList)
	if not MaleStyleDBEnum[styleDBName] or refreshList then
		local maleStyleDB = GetMaleStyleDB(styleDBName)
		if maleStyleDB then
			local maleStyleDBEnum = {}
			for itemKey, itemValue in pairs(maleStyleDB._entries) do
				maleStyleDBEnum[itemValue.key] = itemValue.value
			end
			MaleStyleDBEnum[styleDBName] = maleStyleDBEnum
		end
	end
	return MaleStyleDBEnum[styleDBName]
end

local function GetStyleGender(styleDBName, styleID, refreshList)
	local femaleStyleDBEnum = GetFemaleStyleDBEnum(styleDBName, refreshList)
	local maleStyleDBEnum = GetMaleStyleDBEnum(styleDBName, refreshList)
	local hasFemaleVariant = false
	local hasMaleVariant = false
	if femaleStyleDBEnum then
		if femaleStyleDBEnum[styleID] then
			hasFemaleVariant = true
		end
	end
	if maleStyleDBEnum then
		if maleStyleDBEnum[styleID] then
			hasMaleVariant = true
		end
	end
	if hasFemaleVariant and hasMaleVariant then
		return GENDER.None
	elseif hasFemaleVariant then
		return GENDER.Female
	elseif hasMaleVariant then
		return GENDER.Male
	end
	return -1
end

local function AppendGenderToListItems(list, typeName, styleDBName, removeUnknownGenderStyles, refreshList)
	local listAdditionalDetails = {}
	listAdditionalDetails.FeminineCount = 0
	listAdditionalDetails.MasculineCount = 0
	listAdditionalDetails.NoneCount = 0
	listAdditionalDetails.UnknownCount = 0
	listAdditionalDetails.ShouldRefresh = true
	if list then
		local newList = {}
		local styleGender
		local styleGenderString
		for itemKey, itemValue in pairs(list) do
			styleGender = GetStyleGender(styleDBName, itemKey, refreshList)
			styleGenderString = ""
			if styleGender == GENDER.Female then
				styleGenderString = "FEMININE"
				listAdditionalDetails.FeminineCount = listAdditionalDetails.FeminineCount + 1
			elseif styleGender == GENDER.Male then
				styleGenderString = "MASCULINE"
				listAdditionalDetails.MasculineCount = listAdditionalDetails.MasculineCount + 1
			elseif styleGender == GENDER.None then
				styleGenderString = "FEMMAS"
				listAdditionalDetails.NoneCount = listAdditionalDetails.NoneCount + 1
			else
				styleGenderString = "UNKNOWN"
				listAdditionalDetails.UnknownCount = listAdditionalDetails.UnknownCount + 1
			end
			if not (removeUnknownGenderStyles and styleGenderString == "UNKNOWN") then
				if styleGenderString ~= "" and itemValue ~= "None" then
					newList[itemKey] = itemValue .. " {" .. styleGenderString .. "}"
				else
					newList[itemKey] = itemValue
				end
			elseif itemValue == "None" then
				newList[itemKey] = itemValue
			end
		end
		if listAdditionalDetails.FeminineCount > 0 or listAdditionalDetails.MasculineCount > 0 or listAdditionalDetails.NoneCount > 0 then
			listAdditionalDetails.ShouldRefresh = false
		end
		return newList, listAdditionalDetails
	end
	return list, listAdditionalDetails
end

local function GetAliveStatusString(isDead)
	if isDead then
		return "DEAD"
	else
		return "ALIVE"
	end
end

local function GetSpeciesString(speciesCode)
	if speciesCode == SPECIES.Beastman then
		return "BEASTREN" --Beastman
	elseif speciesCode == SPECIES.Human then
		return "HUMAN"
	else
		return "NOSPECIES"
	end
end

local function GetGenderString(genderCode)
	if genderCode == GENDER.Female then
		return "FEMININE"
	elseif genderCode == GENDER.Male then
		return "MASCULINE"
	else
		return "GENDERLESS"
	end
end

local function ParseColor(parseArg)
	local colorParser = sdk.find_type_definition("via.Color"):get_method("Parse")
	local generatedColor = colorParser:call(nil, parseArg)
	return generatedColor
end

local function Vec4ToColorString(vec4Object, is8BitInt)
	local multiplier = 1
	if is8BitInt then
		multiplier = 255
	end
	local colorString = string.format("%.0f", (vec4Object.x * multiplier)) .. "," .. string.format("%.0f", (vec4Object.y * multiplier)) .. "," .. string.format("%.0f", (vec4Object.z * multiplier)) .. "," .. string.format("%.0f", (vec4Object.w * multiplier))
	return colorString
end

local function Vec4ToColor(vec4Object)
	return ParseColor(Vec4ToColorString(vec4Object, true))
end

local function ColorToVec4(colorObject)
	local divisor = 255
	return Vector4f.new((colorObject:get_r() / divisor), (colorObject:get_g() / divisor), (colorObject:get_b() / divisor), (colorObject:get_a() / divisor))
end

local function ColorToColorString(colorObject)
	return Vec4ToColorString(ColorToVec4(colorObject), false)
end

local function ColorStringToVec4(colorString, defaultValue, is8BitInt)
	local divisor = 1
	if is8BitInt == nil or is8BitInt then
		divisor = 255
	end
	if defaultValue == nil then
		defaultValue = Vector4f.new(0, 0, 0, 1)
	end
	local isColorStringValid = false
	local tempStringArray = ""
	if colorString ~= nil and colorString ~= "" and colorString ~= 0 then
		tempStringArray = split(colorString, ",")
		if #tempStringArray == 4 then
			if tonumber(tempStringArray[1]) and tonumber(tempStringArray[2]) and tonumber(tempStringArray[3]) and tonumber(tempStringArray[4]) then
				isColorStringValid = true
			end
		end
	end
	if isColorStringValid then
		return Vector4f.new(tonumber(tempStringArray[1]) / divisor, tonumber(tempStringArray[2]) / divisor, tonumber(tempStringArray[3]) / divisor, tonumber(tempStringArray[4]) / divisor)
	else
		return defaultValue
	end
end

local USERCONTENTBUNDLESFOLDERNAME = "usercontent\\\\bundles"
local USERCONTENTBUNDLESFILEEXTENSION = "json"

local function AddContentEditorContentToEnum(enum, type)
	local fileNames = {}
	local files = fs.glob(USERCONTENTBUNDLESFOLDERNAME.."\\\\.*"..USERCONTENTBUNDLESFILEEXTENSION)
	if files then
		local userContentBundleData = {}
		for i, file in ipairs(files) do
			userContentBundleData[file] = json.load_file(file)
			if userContentBundleData[file] ~= nil then
				if userContentBundleData[file]["initial_insert_ids"] ~= nil then
					if userContentBundleData[file]["initial_insert_ids"][type] ~= nil then
						if userContentBundleData[file]["name"] ~= nil then
							edit_enum(enum, userContentBundleData[file]["name"].."_"..userContentBundleData[file]["initial_insert_ids"][type].." {CUSTOM}", userContentBundleData[file]["initial_insert_ids"][type])
						else
							edit_enum(enum, userContentBundleData[file]["initial_insert_ids"][type].." {CUSTOM}", userContentBundleData[file]["initial_insert_ids"][type])
						end
					end
				end
			end
		end
	end
	return enum
end

local pasteCounter = 0
local function CyrillicInputText(label, text)
	local suffix = ""
	if _G.CustomizerPendingFix and _G.CustomizerPendingFix[label] then
		text = _G.CustomizerPendingFix[label]
		pasteCounter = pasteCounter + 1
		suffix = "##cyr" .. tostring(pasteCounter)
		_G.CustomizerPendingFix[label] = nil
	end
	local changed, newText = imgui.input_text(label .. suffix, text)
	local corrected = newText
	local i = 1
	local result = {}
	while i <= #newText do
		local byte = newText:byte(i)
		if byte == 0xC3 and i < #newText then
			local next_byte = newText:byte(i + 1)
			if next_byte >= 0x80 and next_byte <= 0xBF then
				local win1251 = 0xC0 | (next_byte & 0x3F)
				local cp
				if win1251 >= 0xC0 and win1251 <= 0xDF then
					cp = 0x0410 + (win1251 - 0xC0)
				elseif win1251 >= 0xE0 and win1251 <= 0xFF then
					cp = 0x0430 + (win1251 - 0xE0)
				end
				if cp then
					table.insert(result, string.char(0xD0 | ((cp >> 6) & 0x0F), 0x80 | (cp & 0x3F)))
					i = i + 2
				else
					table.insert(result, string.char(byte, next_byte))
					i = i + 2
				end
			else
				table.insert(result, string.char(byte))
				i = i + 1
			end
		elseif byte == 0xC2 and i < #newText then
			local next_byte = newText:byte(i + 1)
			if next_byte >= 0x80 and next_byte <= 0xBF then
				local win1251 = next_byte
				local cp
				if win1251 == 0xA8 then
					cp = 0x0401
				elseif win1251 == 0xB8 then
					cp = 0x0451
				end
				if cp then
					table.insert(result, string.char(0xD0 | ((cp >> 6) & 0x0F), 0x80 | (cp & 0x3F)))
					i = i + 2
				else
					table.insert(result, string.char(byte, next_byte))
					i = i + 2
				end
			else
				table.insert(result, string.char(byte))
				i = i + 1
			end
		else
			table.insert(result, string.char(byte))
			i = i + 1
		end
	end
	corrected = table.concat(result)
	if corrected ~= newText then
		imgui.text_colored(corrected, COLOR.GREEN)
		imgui.same_line()
		if imgui.small_button("Вставить##" .. label) then
			if not _G.CustomizerPendingFix then _G.CustomizerPendingFix = {} end
			_G.CustomizerPendingFix[label] = corrected
		end
		if imgui.is_item_hovered() then
			imgui.set_tooltip("Заменяет искажённый текст на исправленный.")
		end
	end
	return changed, corrected
end

local function TextBoxWithCopyAndClearButtons(label, currentTextValue, textBoxWidth, copyText, removeCopyTextSuffix, copyToolTip, clearToolTip)
	local changed = false
	local valueChanged = false
	if copyText and copyToolTip then
		if removeCopyTextSuffix and removeCopyTextSuffix ~= "" then
			copyText = RemoveSuffix(copyText, removeCopyTextSuffix)
		end
		if imgui.arrow_button("Copy " .. label, 1) then
			if copyText and copyText ~= "" then
				currentTextValue = copyText
				valueChanged = true
			end
		end
		if imgui.is_item_hovered() then
			imgui.set_tooltip(copyToolTip)
		end
		imgui.same_line()
	end
    if imgui.arrow_button("Clear " .. label, 0) then
		currentTextValue = ""
		valueChanged = true
	end
	if imgui.is_item_hovered() then
		imgui.set_tooltip(clearToolTip)
	end
	imgui.same_line()
	imgui.set_next_item_width(textBoxWidth)
	changed, currentTextValue = CyrillicInputText(label, currentTextValue)
	valueChanged = valueChanged or changed
	return valueChanged, currentTextValue
end

local function TextBoxWithPlusAndMinusButtons(label, currentTextValue, textBoxWidth, label2, incrementValue, disableTextInput)
	local changed = false
	local valueChanged = false
	currentTextValue = ChangeToDefaultIfNotANumber(currentTextValue, 0)
	textBoxWidth = ChangeToDefaultIfNotANumber(textBoxWidth, 0)
	incrementValue = ChangeToDefaultIfNotANumber(incrementValue, 0)
	--if incrementValue ~= 0 then
		local tempLabel2 = ""
		if label2 and label2 ~= "" then
			tempLabel2 = label2 --"(" .. label2 .. ")"
		end
		if imgui.arrow_button(tempLabel2 .. " - " .. tostring(incrementValue), 0) then --if imgui.button("- " .. tempLabel2) then
			currentTextValue = currentTextValue - incrementValue
			valueChanged = true
		end
		if imgui.is_item_hovered() then
			imgui.set_tooltip(tempLabel2 .. " - " .. tostring(incrementValue))
		end
		imgui.same_line()
		if imgui.arrow_button(tempLabel2 .. " + " .. tostring(incrementValue), 1) then --if imgui.button("+ " .. tempLabel2) then
			currentTextValue = currentTextValue + incrementValue
			valueChanged = true
		end
		if imgui.is_item_hovered() then
			imgui.set_tooltip(tempLabel2 .. " + " .. tostring(incrementValue))
		end
		imgui.same_line()
	--end
	if textBoxWidth then
		imgui.set_next_item_width(textBoxWidth)
	end
	imgui.begin_disabled(disableTextInput)
		changed, currentTextValue = imgui.input_text(label, currentTextValue)
		valueChanged = valueChanged or changed
	imgui.end_disabled()
	return valueChanged, currentTextValue
end

local function ColorEdit4WithCopyAndPasteButtons(label, currentSelectedValue, flags, additionalButtonDetails)
	local valueChanged = false
	if imgui.arrow_button("Copy " .. label, 2) then
		local colorString = Vec4ToColorString(currentSelectedValue, true)
		sdk.copy_to_clipboard(colorString)
		otherVariables.ColorEdit4Value = colorString
	end
	if imgui.is_item_hovered() then
		imgui.set_tooltip("Копировать значение в переменную Color и в буфер обмена.")
	end
	imgui.same_line()
	imgui.begin_disabled(otherVariables.ColorEdit4Value == nil)
		if imgui.arrow_button("Paste " .. label, 3) then
			if otherVariables.ColorEdit4Value then
				currentSelectedValue = ColorStringToVec4(otherVariables.ColorEdit4Value, nil, true)
				valueChanged = true
			end
		end
	imgui.end_disabled()
	if imgui.is_item_hovered() then
		imgui.set_tooltip("Вставить значение из переменной Color.")
	end
	if additionalButtonDetails and additionalButtonDetails.ColorSourceFunction and additionalButtonDetails.ColorSourceFunctionParameter then
		local colorSource = additionalButtonDetails.ColorSourceFunction(additionalButtonDetails.ColorSourceFunctionParameter)
		imgui.same_line()
		if imgui.arrow_button(additionalButtonDetails.Label, additionalButtonDetails.ButtonArrowDirection) then
			if colorSource then
				currentSelectedValue = ColorToVec4(colorSource)
				valueChanged = true
			end
		end
		if imgui.is_item_hovered() then
			imgui.set_tooltip(additionalButtonDetails.ToolTip)
		end
	end
	local changed
	imgui.same_line()
	changed, currentSelectedValue = imgui.color_edit4(label, currentSelectedValue, flags)
	if imgui.is_item_hovered() then
		imgui.set_tooltip(label)
	end
	valueChanged = valueChanged or changed
	return valueChanged, currentSelectedValue
end

local searchText = {}
local overrideText = {}
local overrideValueChanged = {}
local function ComboBoxWithNextAndPreviousButtons(parentLabel, label, currentSelectedValue, valuesList, comboBoxWidth, label2, addSearchTextBox, addOverrideTextBox, isNotNumericValues, additionalSettings)
	if not additionalSettings then
		additionalSettings = {}
	end
	additionalSettings.PreviousButtonLabel = ChangeToDefaultIfNil(additionalSettings.PreviousButtonLabel, "")
	if additionalSettings.PreviousButtonLabel == "" then
		additionalSettings.PreviousButtonLabel = "previous " .. label
	end
	additionalSettings.NextButtonLabel = ChangeToDefaultIfNil(additionalSettings.NextButtonLabel, "")
	if additionalSettings.NextButtonLabel == "" then
		additionalSettings.NextButtonLabel = "next " .. label
	end
	additionalSettings.CurrentButtonLabel = ChangeToDefaultIfNil(additionalSettings.CurrentButtonLabel, "")
	if additionalSettings.CurrentButtonLabel == "" then
		additionalSettings.CurrentButtonLabel = "current " .. label
	end
	local newSelectedValue = currentSelectedValue
	local previousSelectedValue
	local valueChanged
	local valueChanged2
	local arrayLabel2 = label2 .. "_" .. parentLabel
	local filteredList
	searchText[arrayLabel2] = ChangeToDefaultIfNil(searchText[arrayLabel2], "")
	overrideText[arrayLabel2] = ChangeToDefaultIfNil(overrideText[arrayLabel2], "")
	filteredList = GetFilteredList(valuesList, searchText[arrayLabel2])
	imgui.begin_disabled(GetBooleanValue(additionalSettings.ComboBoxDisableCondition))
		--Previous button
		if imgui.arrow_button(additionalSettings.PreviousButtonLabel, 0) then --if imgui.button(additionalSettings.PreviousButtonLabel) then
			newSelectedValue = GetPreviousListItem(filteredList, newSelectedValue)
			valueChanged = true
		end
		if imgui.is_item_hovered() then
			local previousItemName = ""
			local previousValue = GetPreviousListItem(filteredList, newSelectedValue)
			if previousValue ~= currentSelectedValue then
				previousItemName = filteredList[previousValue]
			else
				previousItemName = "-"
			end
			if previousItemName ~= "" then
				previousItemName = " (" .. previousItemName .. ")"
			end
			imgui.set_tooltip(additionalSettings.PreviousButtonLabel .. previousItemName)
		end
		--Next button
		imgui.same_line()
		if imgui.arrow_button(additionalSettings.NextButtonLabel, 1) then --if imgui.button(additionalSettings.NextButtonLabel) then
			newSelectedValue = GetNextListItem(filteredList, newSelectedValue)
			valueChanged = true
		end
		if imgui.is_item_hovered() and filteredList then
			local nextItemName = ""
			local nextValue = GetNextListItem(filteredList, newSelectedValue)
			if nextValue ~= currentSelectedValue then
				nextItemName = filteredList[nextValue]
			else
				nextItemName = "-"
			end
			if nextItemName ~= "" then
				nextItemName = " (" .. nextItemName .. ")"
			end
			imgui.set_tooltip(additionalSettings.NextButtonLabel .. nextItemName)
		end
		--Current button
		if GetBooleanValue(additionalSettings.AddCurrentButton) then
			imgui.same_line()
			if imgui.arrow_button(additionalSettings.CurrentButtonLabel, 3) then --if imgui.button(additionalSettings.CurrentButtonLabel) then
				valueChanged = true
			end
			if imgui.is_item_hovered() and filteredList then
				local currentItemName = ""
				if filteredList[newSelectedValue] then
					currentItemName = filteredList[newSelectedValue]
				else
					currentItemName = "-"
				end
				if currentItemName ~= "" then
					currentItemName = " (" .. currentItemName .. ")"
				end
				imgui.set_tooltip(additionalSettings.CurrentButtonLabel .. currentItemName)
			end
		end
		imgui.same_line()
		imgui.set_next_item_width(comboBoxWidth)
		valueChanged2, newSelectedValue = imgui.combo(label, newSelectedValue, filteredList)
		valueChanged = valueChanged or valueChanged2
		if imgui.is_item_hovered() and filteredList then
			imgui.set_tooltip(filteredList[newSelectedValue])
		end
	imgui.end_disabled()
	if ChangeToDefaultIfNil(additionalSettings.ComboBoxToolTipLabel, "") ~= "" and ChangeToDefaultIfNil(additionalSettings.ComboBoxToolTip, "") ~= "" then
		imgui.same_line()
		imgui.text_colored(additionalSettings.ComboBoxToolTipLabel, COLOR.GREEN)
		if imgui.is_item_hovered() then
			imgui.set_tooltip(additionalSettings.ComboBoxToolTip)
		end
	end
	previousSelectedValue = newSelectedValue
	imgui.begin_disabled(GetBooleanValue(additionalSettings.ComboBoxDisableCondition))
		--Search text box
		if addSearchTextBox then
			if not GetBooleanValue(additionalSettings.AddNewLineBeforeSearchTextBox) then
				imgui.same_line()
			else
				imgui.text("~    ")
				imgui.same_line()
			end
			imgui.set_next_item_width(comboBoxWidth + 28)
			valueChanged2, searchText[arrayLabel2] = CyrillicInputText("поиск " .. label2, searchText[arrayLabel2])
			valueChanged = valueChanged or valueChanged2
		end
		--Override text box
		if addOverrideTextBox then
			if not GetBooleanValue(additionalSettings.AddNewLineBeforeOverrideTextBox) then
				if not addSearchTextBox then
					imgui.same_line()
				else
					if not GetBooleanValue(additionalSettings.AddNewLineBeforeSearchTextBox) then
						imgui.same_line()
					else
						imgui.text("~    ")
						imgui.same_line()
					end
				end
			else
				imgui.text("~    ")
				imgui.same_line()
			end
			imgui.set_next_item_width(comboBoxWidth + 28)
			overrideValueChanged[arrayLabel2], overrideText[arrayLabel2] = CyrillicInputText("замена " .. label2, overrideText[arrayLabel2])
			valueChanged = valueChanged or overrideValueChanged[arrayLabel2]
		end
	imgui.end_disabled()
	if overrideValueChanged[arrayLabel2] then
		if not isNotNumericValues then
			newSelectedValue = tonumber(overrideText[arrayLabel2])
		else
			newSelectedValue = overrideText[arrayLabel2]
		end
	end
	if previousSelectedValue ~= newSelectedValue then
		valueChanged = true
	end
	if (previousSelectedValue ~= newSelectedValue) or not addOverrideTextBox then
		overrideText[arrayLabel2] = newSelectedValue
	end
	return valueChanged, newSelectedValue
end

local function TextColoredWithOnHoverTooltip(text, textColor, onHoverTooltip)
	imgui.text_colored(text, textColor)
	if imgui.is_item_hovered() then
		imgui.set_tooltip(onHoverTooltip)
	end
end

local function SetupUnmatchedModuleVersionsUI(moduleName, requiredVersion, currentVersion)
	imgui.text("[" .. moduleName .. "] version")
	imgui.same_line()
	imgui.text("Требуется:")
	imgui.same_line()
	imgui.text_colored(requiredVersion, COLOR.YELLOW)
	imgui.same_line()
	imgui.text("Установлено:")
	imgui.same_line()
	imgui.text_colored(currentVersion, COLOR.RED)
	if imgui.is_item_hovered() then
		imgui.set_tooltip("Новая версия может быть совместимой.")
	end
end

local function SetupFreezeAndSetValueUI(fsvuip)

	local remainingAmountText = tostring(fsvuip.remainingAmount)
	local currentAmountText = ""
	local maxAmountText = ""
	local calculatedCriticalValueText = ""
	local summaryToolTipText = ""
	local remainingAmountChanged = false
	local freezeOptionChanged = false
	local criticalAmount = 0
	local textColor = fsvuip.textRegularColor

	if not tonumber(fsvuip.maxAmount) then
		fsvuip.maxAmount = -1
	end

	if tonumber(fsvuip.maxAmount) > -1 then

		criticalAmount = fsvuip.maxAmount * fsvuip.criticalPercentage

		maxAmountText = "Max: " .. tostring(fsvuip.maxAmount)
		calculatedCriticalValueText = "Estimated Critical: " .. tostring(criticalAmount)
		summaryToolTipText = maxAmountText .. "\n" .. calculatedCriticalValueText

	end

	if tonumber(fsvuip.actualRemainingAmount) then

		if fsvuip.actualRemainingAmount <= criticalAmount then
			if math.fmod(os.time(), 2) == 0 then
				textColor = fsvuip.textCriticalColor
			else
				textColor = fsvuip.textCritical2Color
			end
		end

		currentAmountText = "Current: " .. tostring(fsvuip.actualRemainingAmount)
		summaryToolTipText = currentAmountText .. "\n" .. summaryToolTipText

	end

	if imgui.begin_table(fsvuip.sectionName .. "Options" .. tostring(fsvuip.characterIndex),2,1,{200,200}) then

		imgui.table_next_row()

		imgui.table_next_column()
		imgui.table_set_bg_color(1, COLOR.GRAY, 1)
		imgui.text_colored(fsvuip.sectionName .. " (" .. fsvuip.sectionCode .. ")", textColor)
		if tonumber(fsvuip.maxAmount) > -1 then
			imgui.table_next_column()
			TextColoredWithOnHoverTooltip("(?)", textColor, fsvuip.sectionName .. ":\n" .. summaryToolTipText)
		end

		imgui.table_next_row()
		imgui.table_next_column()
		freezeOptionChanged, fsvuip.freezeValue = imgui.checkbox("заморозить " .. fsvuip.sectionCode .. " " .. fsvuip.characterLabel2, fsvuip.freezeValue)
		imgui.table_next_column()
		imgui.set_next_item_width(100)
		remainingAmountChanged, remainingAmountText = imgui.input_text(fsvuip.sectionCode .. " " .. fsvuip.characterLabel2, remainingAmountText)
		imgui.same_line()
		TextColoredWithOnHoverTooltip("(?)", COLOR.GREEN, "Десятичное число.")

		fsvuip.remainingAmount = tonumber(remainingAmountText)

		imgui.end_table()

	end

	local fsvuirv = {}
	fsvuirv.freezeOptionChanged = freezeOptionChanged
	fsvuirv.freezeValue = fsvuip.freezeValue
	fsvuirv.remainingAmountChanged = remainingAmountChanged
	fsvuirv.remainingAmount = fsvuip.remainingAmount
	fsvuirv.maxAmount = fsvuip.maxAmount

	return fsvuirv

end

local function ShowPopupWindow(windowName, windowWidth, windowHeight, setupUIFunction, functionArgs, additionalWindowSettings)

	local returnValueOfSetupUIFunction

	if reframework:is_drawing_ui() and GetShowWindow(windowName) then

		if not GetBooleanValue(isWindowInitialized[windowName]) then

			local displaySize = imgui.get_display_size()
			local windowX = 0
			local windowY = 0

			if additionalWindowSettings then
				if additionalWindowSettings.WindowPosition then
					if additionalWindowSettings.WindowPosition == WINDOWPOSITION.BOTTOMCENTER then
						windowX = (displaySize.x / 2)
						windowY = displaySize.y - ((windowHeight / 2) + 50)
					elseif additionalWindowSettings.WindowPosition == WINDOWPOSITION.BOTTOMRIGHT then
						windowX = displaySize.x - ((windowWidth / 2) + 50)
						windowY = displaySize.y - ((windowHeight / 2) + 50)
					elseif additionalWindowSettings.WindowPosition == WINDOWPOSITION.MIDDLELEFT then
						windowX = (windowWidth / 2) + 50
						windowY = (displaySize.y / 2)
					elseif additionalWindowSettings.WindowPosition == WINDOWPOSITION.MIDDLECENTER then
						windowX = (displaySize.x / 2)
						windowY = (displaySize.y / 2)
					elseif additionalWindowSettings.WindowPosition == WINDOWPOSITION.MIDDLERIGHT then
						windowX = displaySize.x - ((windowWidth / 2) + 50)
						windowY = (displaySize.y / 2)
					elseif additionalWindowSettings.WindowPosition == WINDOWPOSITION.TOPLEFT then
						windowX = (windowWidth / 2) + 50
						windowY = (windowHeight / 2) + 50
					elseif additionalWindowSettings.WindowPosition == WINDOWPOSITION.TOPCENTER then
						windowX = (displaySize.x / 2)
						windowY = (windowHeight / 2) + 50
					elseif additionalWindowSettings.WindowPosition == WINDOWPOSITION.TOPRIGHT then
						windowX = displaySize.x - ((windowWidth / 2) + 50)
						windowY = (windowHeight / 2) + 50
					end
				end
				if additionalWindowSettings.WindowX then
					windowX = additionalWindowSettings.WindowX
				end
				if additionalWindowSettings.WindowY then
					windowY = additionalWindowSettings.WindowY
				end
			end

			windowX = ChangeToDefaultIfNotANumber(windowX, 0)
			windowY = ChangeToDefaultIfNotANumber(windowY, 0)

			--DEFAULT / WINDOWPOSITION.BOTTOMLEFT
			if windowX == 0 then
				windowX = (windowWidth / 2) + 50
			end
			if windowY == 0 then
				windowY = displaySize.y - ((windowHeight / 2) + 50)
			end

			imgui.set_next_window_pos(Vector2f.new(windowX, windowY), 0, Vector2f.new(0.5, 0.5))
			imgui.set_next_window_size(Vector2f.new(windowWidth, windowHeight), 0)

			isWindowInitialized[windowName] = true

		end

		if GetShowWindow(windowName) then

			showWindow[windowName] = imgui.begin_window(windowName, true, 0)

			if functionArgs ~= nil then
				returnValueOfSetupUIFunction = setupUIFunction(functionArgs)
			else
				returnValueOfSetupUIFunction = setupUIFunction()
			end

			imgui.end_window()

		end

	end

	if GetShowWindowPrev(windowName) then
		isWindowRefreshed[windowName] = GetShowWindow(windowName)
	end

	return returnValueOfSetupUIFunction

end

local function AddShowPopupWindowButton(buttonName, windowName)
	local showHideText = ""
	if GetShowWindow(windowName) then showHideText = "Скрыть" else showHideText = "Показать" end
	if imgui.button(showHideText .. " " .. buttonName) then
		SetShowWindow(windowName, not GetShowWindow(windowName))
	end
end

local spamRequestCheckHelper = {}
local function SpamRequestCheckPassed(bufferName, timeBufferInSeconds)
	local isNotSpamming = true
	if GetDelayTimerStatus(bufferName) == DELAYTIMERSTATUS.NONE or GetDelayTimerStatus(bufferName) == DELAYTIMERSTATUS.OFF then
		isNotSpamming = true
	elseif GetDelayTimerStatus(bufferName) == DELAYTIMERSTATUS.RUNNING then
		isNotSpamming = false
	end
	if isNotSpamming then
		StartDelayTimer(bufferName, timeBufferInSeconds)
	end
	return isNotSpamming
end

local function GetCurrentScene()
	return sdk.call_native_func(sdk.get_native_singleton("via.SceneManager"), sdk.find_type_definition("via.SceneManager"), "get_CurrentScene()")
end

local function GetCharaEditModelCtrl(scene)
	return scene:call("findGameObject(System.String)", "CharaEditModelCtrl")
end

local function GetSceneGUI(scene, guiName)
	local guiObject = scene:call("findGameObject(System.String)", guiName)
	if guiObject then
		return guiObject:call("getComponent(System.Type)", sdk.typeof("app.GUIBase"))
	end
	return nil
end

local function IsInDetailedCharacterCustomizationScreen(allowUnavailableOptionEdits)
	local isInDetailedCharacterCustomizationScreen = false
	
	if not IsPausedGUI() then return isInDetailedCharacterCustomizationScreen end
	
	local currentScene = GetCurrentScene()
	local charaEditModelCtrl = GetCharaEditModelCtrl(currentScene)	
	if charaEditModelCtrl then
		local GuiManager = sdk.get_managed_singleton("app.GuiManager")
		if allowUnavailableOptionEdits and not GuiManager._CharaEditCtrl:get_IsDispEditFade() then
			isInDetailedCharacterCustomizationScreen = true
		else
			local ui070406_01 = GetSceneGUI(currentScene, "ui070406_01")
			if ui070406_01 then
				isInDetailedCharacterCustomizationScreen = true
			end
		end
	end
	return isInDetailedCharacterCustomizationScreen
end

local function GetActiveMockupDetails()
	local activeMockupDetails = {}		
	activeMockupDetails.MockupCtrlGUIName = "none"
	if not IsPausedGUI() then return activeMockupDetails end
	if activeMockupDetails.MockupCtrl == nil then
		activeMockupDetails.CurrentScene = GetCurrentScene()
		activeMockupDetails.ui040101_00 = GetSceneGUI(activeMockupDetails.CurrentScene, "ui040101_00")
		if activeMockupDetails.ui040101_00 then
			activeMockupDetails.MockupCtrlGUIName = "ui040101_00"
			activeMockupDetails.MockupCtrl = activeMockupDetails.ui040101_00.CompMockup
		end
		--Shop
		if activeMockupDetails.MockupCtrl == nil then
			activeMockupDetails.ui040601_00 = GetSceneGUI(activeMockupDetails.CurrentScene, "ui040601_00")
			if activeMockupDetails.ui040601_00 then
				activeMockupDetails.MockupCtrlGUIName = "ui040601_00"
				activeMockupDetails.MockupCtrl = activeMockupDetails.ui040601_00.CompMockup
			end
		end
		if activeMockupDetails.MockupCtrl == nil then
			activeMockupDetails.ui041401 = GetSceneGUI(activeMockupDetails.CurrentScene, "ui041401")
			if activeMockupDetails.ui041401 then
				activeMockupDetails.MockupCtrlGUIName = "ui041401"
				activeMockupDetails.MockupCtrl = activeMockupDetails.ui041401.CompMockup
			end	
		end
		if activeMockupDetails.MockupCtrl == nil then	
			activeMockupDetails.ui041503 = GetSceneGUI(activeMockupDetails.CurrentScene, "ui041503")
			if activeMockupDetails.ui041503 then
				activeMockupDetails.MockupCtrlGUIName = "ui041503"
				activeMockupDetails.MockupCtrl = activeMockupDetails.ui041503.CompMockup
			end
		end
		if activeMockupDetails.MockupCtrl == nil then
			activeMockupDetails.ui041706 = GetSceneGUI(activeMockupDetails.CurrentScene, "ui041706")
			if activeMockupDetails.ui041706 then
				activeMockupDetails.MockupCtrlGUIName = "ui041706"
				activeMockupDetails.MockupCtrl = activeMockupDetails.ui041706.CompMockup
			end	
		end
		if activeMockupDetails.MockupCtrl == nil then	
			activeMockupDetails.ui060301_00 = GetSceneGUI(activeMockupDetails.CurrentScene, "ui060301_00")
			if activeMockupDetails.ui060301_00 then
				activeMockupDetails.MockupCtrlGUIName = "ui060301_00"
				activeMockupDetails.MockupCtrl = activeMockupDetails.ui060301_00.CompMockup
			end	
		end
		--Equipment
		if activeMockupDetails.MockupCtrl == nil then	
			activeMockupDetails.ui060401_00 = GetSceneGUI(activeMockupDetails.CurrentScene, "ui060401_00")
			if activeMockupDetails.ui060401_00 then
				activeMockupDetails.MockupCtrlGUIName = "ui060401_00"
				activeMockupDetails.MockupCtrl = activeMockupDetails.ui060401_00.CompMockup
			end
		end
		if activeMockupDetails.MockupCtrl == nil then
			activeMockupDetails.ui090102 = GetSceneGUI(activeMockupDetails.CurrentScene, "ui090102")
			if activeMockupDetails.ui090102 then
				activeMockupDetails.MockupCtrlGUIName = "ui090102"
				activeMockupDetails.MockupCtrl = activeMockupDetails.ui090102.CompMockup
			end
		end
		if activeMockupDetails.MockupCtrl == nil then
			activeMockupDetails.ui090105 = GetSceneGUI(activeMockupDetails.CurrentScene, "ui090105")
			if activeMockupDetails.ui090105 then
				activeMockupDetails.MockupCtrlGUIName = "ui090105"
				activeMockupDetails.MockupCtrl = activeMockupDetails.ui090105.CompMockup
			end
		end	
		--Status
		if activeMockupDetails.MockupCtrl == nil then
			activeMockupDetails.ui060601_01 = GetSceneGUI(activeMockupDetails.CurrentScene, "ui060601_01")
			if activeMockupDetails.ui060601_01 then
				activeMockupDetails.MockupCtrlGUIName = "ui060601_01"
				activeMockupDetails.MockupCtrl = activeMockupDetails.ui060601_01.CompMockup
			end
		end
	end
	if activeMockupDetails.MockupCtrl then
		activeMockupDetails.MockupBuilder = activeMockupDetails.MockupCtrl.CompBuilder		
		activeMockupDetails.PartSwapper = activeMockupDetails.MockupCtrl:get_PartSwapper()
		if activeMockupDetails.DispData == nil then
			activeMockupDetails.DispData = activeMockupDetails.MockupCtrl.DispData
		end
	end
	if activeMockupDetails.DispData then
		activeMockupDetails.CharaID = activeMockupDetails.DispData:get_CharaId()
	end
	local GuiManager = sdk.get_managed_singleton("app.GuiManager")
	--if activeMockupDetails.MockupCtrl == nil then
	--	activeMockupDetails.MockupCtrl = GuiManager:getMenuMockup(???)
	--	if activeMockupDetails.MockupCtrl then
	--		activeMockupDetails.MockupCtrlGUIName = "GuiManager"
	--		activeMockupDetails.MockupBuilder = activeMockupDetails.MockupCtrl.CompBuilder
	--	end
	--end
	if activeMockupDetails.MockupBuilder == nil then
		if GuiManager._CharaEditCtrl then
			activeMockupDetails.GUIPreviewModelEditor = GuiManager._CharaEditCtrl["<ModelEditor>k__BackingField"]
			if activeMockupDetails.GUIPreviewModelEditor then
				activeMockupDetails.PartSwapper = activeMockupDetails.GUIPreviewModelEditor["<PartSwap>k__BackingField"]
				if activeMockupDetails.PartSwapper then
					activeMockupDetails.MockupBuilder = activeMockupDetails.PartSwapper._MockupBuilder
				end
			end
		end
	end
	return activeMockupDetails
end

local function GetCharacterStatusSceneDetails()
	local characterStatusSceneDetails = {}		
	characterStatusSceneDetails.IsInCharacterStatusScreen = false
	characterStatusSceneDetails.IsInShop = false
	characterStatusSceneDetails.CateInfo = nil
	characterStatusSceneDetails.IsItemEquip = false
	characterStatusSceneDetails.ItemCategory = -1
	characterStatusSceneDetails.ItemEquipCategory = -1
	characterStatusSceneDetails.OfficialPawnMemoryManager = nil
	if not IsPausedGUI() then return characterStatusSceneDetails end
		
	characterStatusSceneDetails.CurrentScene = GetCurrentScene()
	if characterStatusSceneDetails.CurrentScene then
		characterStatusSceneDetails.ui040101_00 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui040101_00")
		if characterStatusSceneDetails.ui040101_00 then
			if characterStatusSceneDetails.MockupCtrl == nil then
				characterStatusSceneDetails.MockupCtrlGUIName = "ui040101_00"
				characterStatusSceneDetails.MockupCtrl = characterStatusSceneDetails.ui040101_00.CompMockup
			end
			if characterStatusSceneDetails.MockupFace == nil then
				characterStatusSceneDetails.MockupFaceGUIName = "ui040101_00"
				characterStatusSceneDetails.MockupFace = characterStatusSceneDetails.ui040101_00.MenuFace
			end
		end		
		--Shop
		characterStatusSceneDetails.ui040601_00 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui040601_00")
		if characterStatusSceneDetails.ui040601_00 then
			if characterStatusSceneDetails.MockupCtrl == nil then
				characterStatusSceneDetails.MockupCtrlGUIName = "ui040601_00"
				characterStatusSceneDetails.MockupCtrl = characterStatusSceneDetails.ui040601_00.CompMockup
			end
			if characterStatusSceneDetails.MockupFace == nil then
				characterStatusSceneDetails.MockupFaceGUIName = "ui040601_00"				
				characterStatusSceneDetails.MockupFace = characterStatusSceneDetails.ui040601_00.MenuFace
			end
			characterStatusSceneDetails.IsInShop = true
			characterStatusSceneDetails.CateInfo = characterStatusSceneDetails.ui040601_00:getSelectedCateInfo()
			if characterStatusSceneDetails.CateInfo then
				characterStatusSceneDetails.ItemCategory = characterStatusSceneDetails.CateInfo.Cate
				characterStatusSceneDetails.ItemEquipCategory = characterStatusSceneDetails.CateInfo.EqCate
			end
		end
		characterStatusSceneDetails.ui041101_00 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui041101_00")
		if characterStatusSceneDetails.ui041101_00 then
			if characterStatusSceneDetails.MockupFace == nil then
				characterStatusSceneDetails.MockupFaceGUIName = "ui041101_00"				
				characterStatusSceneDetails.MockupFace = characterStatusSceneDetails.ui041101_00.MenuFace
			end
		end
		characterStatusSceneDetails.ui041401 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui041401")
		if characterStatusSceneDetails.ui041401 then
			if characterStatusSceneDetails.MockupCtrl == nil then
				characterStatusSceneDetails.MockupCtrlGUIName = "ui041401"
				characterStatusSceneDetails.MockupCtrl = characterStatusSceneDetails.ui041401.CompMockup
			end
		end		
		characterStatusSceneDetails.ui041503 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui041503")
		if characterStatusSceneDetails.ui041503 then
			if characterStatusSceneDetails.MockupCtrl == nil then
				characterStatusSceneDetails.MockupCtrlGUIName = "ui041503"
				characterStatusSceneDetails.MockupCtrl = characterStatusSceneDetails.ui041503.CompMockup
			end
			if characterStatusSceneDetails.MockupFace == nil then
				characterStatusSceneDetails.MockupFaceGUIName = "ui041503"				
				characterStatusSceneDetails.MockupFace = characterStatusSceneDetails.ui041503.MenuFace
			end
		end
		characterStatusSceneDetails.ui060101 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui060101")
		if characterStatusSceneDetails.ui060101 then
			if characterStatusSceneDetails.MockupFace == nil then
				characterStatusSceneDetails.MockupFaceGUIName = "ui060101"
				characterStatusSceneDetails.MockupFace = characterStatusSceneDetails.ui060101.MenuFace
			end
		end
		characterStatusSceneDetails.ui041706 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui041706")
		if characterStatusSceneDetails.ui041706 then
			if characterStatusSceneDetails.MockupCtrl == nil then
				characterStatusSceneDetails.MockupCtrlGUIName = "ui041706"
				characterStatusSceneDetails.MockupCtrl = characterStatusSceneDetails.ui041706.CompMockup
			end
			if characterStatusSceneDetails.MockupFace == nil then
				characterStatusSceneDetails.MockupFaceGUIName = "ui041706"
				characterStatusSceneDetails.MockupFace = characterStatusSceneDetails.ui041706.MenuFace
			end
		end		
		characterStatusSceneDetails.ui060301_00 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui060301_00")
		if characterStatusSceneDetails.ui060301_00 then
			if characterStatusSceneDetails.MockupCtrl == nil then
				characterStatusSceneDetails.MockupCtrlGUIName = "ui060301_00"
				characterStatusSceneDetails.MockupCtrl = characterStatusSceneDetails.ui060301_00.CompMockup
			end
			if characterStatusSceneDetails.MockupFace == nil then
				characterStatusSceneDetails.MockupFaceGUIName = "ui060301_00"
				characterStatusSceneDetails.MockupFace = characterStatusSceneDetails.ui060301_00.MenuFace
			end
			characterStatusSceneDetails.IsInShop = true
		end
		--Equipment
		characterStatusSceneDetails.ui060401_00 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui060401_00")
		if characterStatusSceneDetails.ui060401_00 then
			if characterStatusSceneDetails.MockupCtrl == nil then
				characterStatusSceneDetails.MockupCtrlGUIName = "ui060401_00"
				characterStatusSceneDetails.MockupCtrl = characterStatusSceneDetails.ui060401_00.CompMockup
			end
			if characterStatusSceneDetails.MockupFace == nil then
				characterStatusSceneDetails.MockupFaceGUIName = "ui060401_00"
				characterStatusSceneDetails.MockupFace = characterStatusSceneDetails.ui060401_00.MenuFace
			end
			characterStatusSceneDetails.CateInfo = characterStatusSceneDetails.ui060401_00.SelectCateInfo
			characterStatusSceneDetails.ItemDetail2Ref = characterStatusSceneDetails.ui060401_00.ItemDetail
			if characterStatusSceneDetails.CateInfo then --characterStatusSceneDetails.ItemDetail2Ref then
				--characterStatusSceneDetails.ItemEquipParam = characterStatusSceneDetails.ItemDetail2Ref:get_AfterParam()
				--if characterStatusSceneDetails.ItemEquipParam then
					characterStatusSceneDetails.ItemEquipCategory = characterStatusSceneDetails.CateInfo.EqCate --characterStatusSceneDetails.ItemEquipParam._EquipCategory
				--end
			end
			characterStatusSceneDetails.SlotEnum = characterStatusSceneDetails.ui060401_00:get_SelectedSlot()
		end
		characterStatusSceneDetails.ui090102 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui090102")
		if characterStatusSceneDetails.ui090102 then
			if characterStatusSceneDetails.MockupCtrl == nil then
				characterStatusSceneDetails.MockupCtrlGUIName = "ui090102"
				characterStatusSceneDetails.MockupCtrl = characterStatusSceneDetails.ui090102.CompMockup
			end
		end
		characterStatusSceneDetails.ui090105 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui090105")
		if characterStatusSceneDetails.ui090105 then
			if characterStatusSceneDetails.MockupCtrl == nil then
				characterStatusSceneDetails.MockupCtrlGUIName = "ui090105"
				characterStatusSceneDetails.MockupCtrl = characterStatusSceneDetails.ui090105.CompMockup
			end
		end
		characterStatusSceneDetails.ui070404 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui070404")
		if characterStatusSceneDetails.ui070404 then
			if characterStatusSceneDetails.MockupFace == nil then
				characterStatusSceneDetails.MockupFaceGUIName = "ui070404"
				characterStatusSceneDetails.MockupFace = characterStatusSceneDetails.ui070404.MenuFace
			end
		end
		--Status
		characterStatusSceneDetails.ui060601_01 = GetSceneGUI(characterStatusSceneDetails.CurrentScene, "ui060601_01")
		if characterStatusSceneDetails.ui060601_01 then
			if characterStatusSceneDetails.MockupCtrl == nil then
				characterStatusSceneDetails.MockupCtrlGUIName = "ui060601_01"
				characterStatusSceneDetails.MockupCtrl = characterStatusSceneDetails.ui060601_01.CompMockup
			end
			if characterStatusSceneDetails.MockupFace == nil then
				characterStatusSceneDetails.MockupFaceGUIName = "ui060601_01"				
				characterStatusSceneDetails.MockupFace = characterStatusSceneDetails.ui060601_01.MenuFace
			end
			--if characterStatusSceneDetails.ui060601_01.CompMockup then
			--	characterStatusSceneDetails.DispData = characterStatusSceneDetails.ui060601_01.CompMockup.DispData
			--end
			characterStatusSceneDetails.IsInCharacterStatusScreen = true
		end
	end	
	if characterStatusSceneDetails.MockupCtrl == nil then	
		--local GuiManager = sdk.get_managed_singleton("app.GuiManager")
		--characterStatusSceneDetails.MockupCtrl = GuiManager:getMenuMockup(GuiManager:getTalkSelectSelectedIndex())
	end	
	if characterStatusSceneDetails.MockupCtrl then
		characterStatusSceneDetails.MockupBuilder = characterStatusSceneDetails.MockupCtrl.CompBuilder		
		characterStatusSceneDetails.PartSwapper = characterStatusSceneDetails.MockupCtrl:get_PartSwapper()
		if characterStatusSceneDetails.DispData == nil then
			characterStatusSceneDetails.DispData = characterStatusSceneDetails.MockupCtrl.DispData
		end
	end
	if characterStatusSceneDetails.DispData then
		characterStatusSceneDetails.CharaID = characterStatusSceneDetails.DispData:get_CharaId()
	end
	return characterStatusSceneDetails
end

local function GetHookStorageValue(storageName)
	local ok, storage = pcall(thread.get_hook_storage)
	if not ok or storage == nil then return nil end
	return storage[storageName]
end

local function SetHookStorageValue(storageName, value)
	local ok, storage = pcall(thread.get_hook_storage)
	if not ok or storage == nil then return end
	storage[storageName] = value
end

local function SetupCreateEditDeleteDataTableFileUI(dataTable, folderName, fileName, newFileName, modDetails, fileTypeLabel, fileExists, shouldConfirmDelete)
	
	local changedValue
	
	local uiDetails = {}
	uiDetails.selectedFileChanged = false
	uiDetails.shouldLoadFile = false
	uiDetails.dataTable = dataTable
	uiDetails.folderName = folderName
	uiDetails.fileName = fileName
	uiDetails.newFileName = newFileName	
	uiDetails.fileExists = fileExists	
	uiDetails.shouldConfirmDelete = shouldConfirmDelete	
	
	uiDetails.fileNamesList = GetFileNamesList(uiDetails.folderName)
	uiDetails.fileNamesListCount = -1
	uiDetails.fileNamesListIndex = 0
	uiDetails.currentFileName = ""
	
	if uiDetails.fileNamesList then
		uiDetails.fileNamesListIndex = GetCurrentListIndex(uiDetails.fileNamesList, uiDetails.fileName)
		uiDetails.fileNamesListCount = #uiDetails.fileNamesList
	end
	
	local additionalComboBoxSettings = {}
	additionalComboBoxSettings.AddNewLineBeforeSearchTextBox = true
	additionalComboBoxSettings.AddNewLineBeforeOverrideTextBox = true
	
	uiDetails.selectedFileChanged , uiDetails.fileNamesListIndex = ComboBoxWithNextAndPreviousButtons("[" .. modDetails.modCode .. "]", fileTypeLabel .. modDetails.additionalLabel, uiDetails.fileNamesListIndex, uiDetails.fileNamesList, 250, "file" .. modDetails.additionalLabel, uiDetails.fileNamesListCount > 10, false, true, additionalComboBoxSettings)
	uiDetails.shouldLoadFile = imgui.button("Загрузить " .. fileTypeLabel .. modDetails.additionalLabel)
	if (uiDetails.selectedFileChanged  or uiDetails.shouldLoadFile) and uiDetails.fileNamesListCount > -1 then
		uiDetails.dataTable = GetDataTableFromFile(uiDetails.fileNamesList[uiDetails.fileNamesListIndex], uiDetails.folderName)
		uiDetails.shouldConfirmDelete = false
	end
	local deleteFileButtonLabel = ""
	if uiDetails.shouldConfirmDelete then
		deleteFileButtonLabel = "Удалить "  .. fileTypeLabel
	else
		deleteFileButtonLabel = "Удалить "  .. fileTypeLabel
	end
	if imgui.button(deleteFileButtonLabel .. modDetails.additionalLabel) and uiDetails.fileNamesListCount > -1 then
		if uiDetails.shouldConfirmDelete then
			_io_file.delete(uiDetails.folderName .. "/" .. uiDetails.fileNamesList[uiDetails.fileNamesListIndex] .. ".json")
			SetIsFileListLoaded(uiDetails.folderName, false)
			RefreshFileNamesList(uiDetails.folderName)
			uiDetails.shouldConfirmDelete = false
		else
			uiDetails.shouldConfirmDelete = true
		end
	end
	if uiDetails.shouldConfirmDelete then
		imgui.same_line()
		TextColoredWithOnHoverTooltip("(!)", COLOR.RED, "Нажмите кнопку Удалить ещё раз для подтверждения.")
	end
	imgui.begin_disabled(not uiDetails.shouldConfirmDelete)
		if imgui.button("Отменить удаление " .. fileTypeLabel .. modDetails.additionalLabel) then
			uiDetails.shouldConfirmDelete = false
		end
	imgui.end_disabled()
	if imgui.button("Обновить " .. fileTypeLabel .. modDetails.additionalLabel) then
		SetIsFileListLoaded(uiDetails.folderName, false)
		RefreshFileNamesList(uiDetails.folderName)
	end
	imgui.same_line()
	TextColoredWithOnHoverTooltip("(?)", COLOR.GREEN, "Запускайте если были изменения в файлах " .. fileTypeLabel .. ".")

	imgui.text(" ")
	
	imgui.set_next_item_width(250)
	changedValue, uiDetails.newFileName = TextBoxWithCopyAndClearButtons("Новый "  .. fileTypeLabel .. modDetails.additionalLabel, uiDetails.newFileName, 250, uiDetails.fileNamesList[uiDetails.fileNamesListIndex], nil, "Копировать имя файла выбранного " .. fileTypeLabel .. ".", "Очистить это поле.")
	uiDetails.currentFileName = uiDetails.folderName .. "/" .. uiDetails.newFileName .. ".json"
	
	local proceedWithSave = false
	local isOverwrite = uiDetails.fileExists
	local saveFileButtonLabel = ""
	if uiDetails.fileExists then
		saveFileButtonLabel = "Перезаписать "  .. fileTypeLabel
	else
		saveFileButtonLabel = "Сохранить "  .. fileTypeLabel
	end
	
	imgui.begin_disabled(uiDetails.newFileName == "")
		if imgui.button(saveFileButtonLabel .. modDetails.additionalLabel) then
			uiDetails.fileExists = file_exists(uiDetails.currentFileName)
			if not uiDetails.fileExists or isOverwrite then
				proceedWithSave = true
			end			
			if proceedWithSave then
				json.dump_file(uiDetails.currentFileName, uiDetails.dataTable)
				SetIsFileListLoaded(uiDetails.folderName, false)
				RefreshFileNamesList(uiDetails.folderName)
				uiDetails.fileExists = false
			end
		end
	imgui.end_disabled()
	if isOverwrite then
		imgui.same_line()
		TextColoredWithOnHoverTooltip("(!)", COLOR.RED, "Нажмите кнопку Перезаписать для подтверждения.")
	end
	imgui.begin_disabled(not uiDetails.fileExists or uiDetails.newFileName == "")
		if imgui.button("Отменить перезапись " .. fileTypeLabel .. modDetails.additionalLabel) then
			uiDetails.fileExists = false
		end
	imgui.end_disabled()
	
	return uiDetails
	
end

local function SetNativeField(object, type_definition, field_name, value, proceedIfValueIsNull)
	if value or (value == nil and proceedIfValueIsNull) then
		sdk.set_native_field(object, type_definition, field_name, value)
	end
end

CharacterStatusScreen = {}

CharacterStatusScreen.MockupCtrl = nil
CharacterStatusScreen.PrevMockupCtrl = nil
CharacterStatusScreen.ViewedCharacterDetailsFileName = "LastViewedCharacterDetails.json"
CharacterStatusScreen.TempPrevPawnID = ""
CharacterStatusScreen.TempPrevCharaID = ""
CharacterStatusScreen.CharacterDetailsSummary = ""
CharacterStatusScreen.ViewedCharacterDetails = {}
CharacterStatusScreen.PreviousLastViewedCharacterDetails = {}

local function GetDefaultLastViewedCharacterDetails()

	local defaultLastViewedCharacterDetails = {

		pawnID = "",
		characterTypeString = "",
		characterName = "",
		characterNickname = "",
		characterOwnerName = "",
		characterOwnerNickname = "",
		characterLevel = "",
		charaID = "",
		prevPawnPawnID = "",

	}

	return defaultLastViewedCharacterDetails

end

local function ReadLastViewedCharacterDetailsFile()

	CharacterStatusScreen.PreviousLastViewedCharacterDetails = json.load_file(CharacterStatusScreen.ViewedCharacterDetailsFileName)
	local defaultLastViewedCharacterDetails = GetDefaultLastViewedCharacterDetails()
	CharacterStatusScreen.ViewedCharacterDetails = defaultLastViewedCharacterDetails

	if CharacterStatusScreen.PreviousLastViewedCharacterDetails then
		CharacterStatusScreen.ViewedCharacterDetails = CharacterStatusScreen.PreviousLastViewedCharacterDetails
	end

end

local function InitializeCharacterStatusScreen()
	ReadLastViewedCharacterDetailsFile()
	json.dump_file(CharacterStatusScreen.ViewedCharacterDetailsFileName, CharacterStatusScreen.ViewedCharacterDetails)
end

local function SetupViewCharacterStatusUI()
	CharacterStatusScreen.CharacterDetailsSummary = CharacterStatusScreen.ViewedCharacterDetails.characterName .. " - " .. CharacterStatusScreen.ViewedCharacterDetails.characterTypeString
	if CharacterStatusScreen.ViewedCharacterDetails.pawnID ~= "" then
		CharacterStatusScreen.CharacterDetailsSummary = CharacterStatusScreen.CharacterDetailsSummary .. " (" .. CharacterStatusScreen.ViewedCharacterDetails.pawnID .. ")"
	end
	imgui.set_next_item_width(300)
	_, CharacterStatusScreen.ViewedCharacterDetails.characterTypeString = CyrillicInputText("Тип персонажа", CharacterStatusScreen.ViewedCharacterDetails.characterTypeString)
	imgui.set_next_item_width(300)
	_, CharacterStatusScreen.ViewedCharacterDetails.pawnID = CyrillicInputText("ID пешки", CharacterStatusScreen.ViewedCharacterDetails.pawnID)
	imgui.set_next_item_width(300)
	_, CharacterStatusScreen.ViewedCharacterDetails.characterName = CyrillicInputText("Имя", CharacterStatusScreen.ViewedCharacterDetails.characterName)
	imgui.set_next_item_width(300)
	_, CharacterStatusScreen.ViewedCharacterDetails.characterNickname = CyrillicInputText("Прозвище", CharacterStatusScreen.ViewedCharacterDetails.characterNickname)
	imgui.set_next_item_width(300)
	_, CharacterStatusScreen.ViewedCharacterDetails.characterOwnerName = CyrillicInputText("Имя владельца", CharacterStatusScreen.ViewedCharacterDetails.characterOwnerName)
	imgui.set_next_item_width(300)
	_, CharacterStatusScreen.ViewedCharacterDetails.characterOwnerNickname = CyrillicInputText("Прозвище владельца", CharacterStatusScreen.ViewedCharacterDetails.characterOwnerNickname)
	imgui.set_next_item_width(300)
	_, CharacterStatusScreen.ViewedCharacterDetails.characterLevel = CyrillicInputText("Уровень", CharacterStatusScreen.ViewedCharacterDetails.characterLevel)
	imgui.set_next_item_width(300)
	_, CharacterStatusScreen.ViewedCharacterDetails.charaID = CyrillicInputText("ID персонажа", CharacterStatusScreen.ViewedCharacterDetails.charaID)
	imgui.set_next_item_width(300)
	_, CharacterStatusScreen.ViewedCharacterDetails.prevPawnPawnID = CyrillicInputText("ID пред. пешки", CharacterStatusScreen.ViewedCharacterDetails.prevPawnPawnID)
	imgui.set_next_item_width(300)
	_, CharacterStatusScreen.CharacterDetailsSummary = CyrillicInputText("Персонаж", CharacterStatusScreen.CharacterDetailsSummary)
	if imgui.button("Сохранить в файл") then
		local newFileName
		newFileName = CharacterStatusScreen.CharacterDetailsSummary
		json.dump_file("Character Encounter Data/Character Encounter Data - " .. newFileName .. ".json", CharacterStatusScreen.ViewedCharacterDetails)
	end
	imgui.same_line()
	if imgui.button("Копировать сводку в буфер") then
		sdk.copy_to_clipboard(CharacterStatusScreen.CharacterDetailsSummary)
	end
end

local function RefreshViewCharacterStatusUI()
	local activeMockupDetails = GetActiveMockupDetails()
	local changedMockup = false
	CharacterStatusScreen.MockupCtrl = activeMockupDetails.MockupCtrl
	if CharacterStatusScreen.MockupCtrl ~= CharacterStatusScreen.PrevMockupCtrl then
		CharacterStatusScreen.PrevMockupCtrl = CharacterStatusScreen.MockupCtrl
		changedMockup = true
	end
	if CharacterStatusScreen.MockupCtrl and changedMockup then
		if CharacterStatusScreen.ViewedCharacterDetails.pawnID ~= "" then
			CharacterStatusScreen.TempPrevPawnID = CharacterStatusScreen.ViewedCharacterDetails.pawnID
		end
		CharacterStatusScreen.TempPrevCharaID = CharacterStatusScreen.ViewedCharacterDetails.charaID
		CharacterStatusScreen.ViewedCharacterDetails.pawnID = ""
		CharacterStatusScreen.ViewedCharacterDetails.characterTypeString = "Arisen/Pawn"
		CharacterStatusScreen.ViewedCharacterDetails.characterName = ""
		CharacterStatusScreen.ViewedCharacterDetails.characterNickname = ""
		CharacterStatusScreen.ViewedCharacterDetails.characterOwnerName = ""
		CharacterStatusScreen.ViewedCharacterDetails.characterOwnerNickname = ""
		CharacterStatusScreen.ViewedCharacterDetails.charaID = ""
		if activeMockupDetails.DispData then
			CharacterStatusScreen.ViewedCharacterDetails.pawnID = activeMockupDetails.DispData:get_PawnId()
			CharacterStatusScreen.ViewedCharacterDetails.characterName = activeMockupDetails.DispData:get_Name()
			CharacterStatusScreen.ViewedCharacterDetails.characterNickname = activeMockupDetails.DispData:get_NickName()
			CharacterStatusScreen.ViewedCharacterDetails.characterOwnerName = activeMockupDetails.DispData:get_OwnerName()
			CharacterStatusScreen.ViewedCharacterDetails.characterOwnerNickname = activeMockupDetails.DispData:get_OwnerNickName()
			CharacterStatusScreen.ViewedCharacterDetails.characterLevel = activeMockupDetails.DispData:get_Level()
			CharacterStatusScreen.ViewedCharacterDetails.charaID = activeMockupDetails.DispData:get_CharaId()
			if CharacterStatusScreen.ViewedCharacterDetails.pawnID ~= "" then
				CharacterStatusScreen.ViewedCharacterDetails.characterTypeString = "Pawn"
			end
			if CharacterStatusScreen.TempPrevPawnID ~= CharacterStatusScreen.ViewedCharacterDetails.pawnID then
				CharacterStatusScreen.ViewedCharacterDetails.prevPawnPawnID = CharacterStatusScreen.TempPrevPawnID
			end
			if (CharacterStatusScreen.ViewedCharacterDetails.pawnID or (CharacterStatusScreen.TempPrevPawnID ~= CharacterStatusScreen.ViewedCharacterDetails.pawnID)) and (CharacterStatusScreen.TempPrevCharaID ~= CharacterStatusScreen.ViewedCharacterDetails.charaID) then
				json.dump_file(CharacterStatusScreen.ViewedCharacterDetailsFileName, CharacterStatusScreen.ViewedCharacterDetails)
			end
		end
	end
end

local common = {

	currentVersion = currentVersion,

	COLOR = COLOR,
	DELAYTIMERSTATUS = DELAYTIMERSTATUS,
	WINDOWPOSITIONS = WINDOWPOSITIONS,
	WINDOWPOSITION = WINDOWPOSITION,
	GENDER = GENDER,
	SPECIES = SPECIES,
	GENDER_CODE = GENDER_CODE,
	SPECIES_CODE = SPECIES_CODE,	
	PLATFORMENVIRONMENT = PLATFORMENVIRONMENT,
	PLATFORMENVIRONMENT_CODE = PLATFORMENVIRONMENT_CODE,
	NETWORKSERVICETYPE = NETWORKSERVICETYPE,
	NETWORKSERVICETYPE_CODE = NETWORKSERVICETYPE_CODE,
	--CJK_GLYPH_RANGES = CJK_GLYPH_RANGES,

	CopyArrayItemValueIfNotNull = CopyArrayItemValueIfNotNull,
	split = split,
	IsPlayerCharacterReady = IsPlayerCharacterReady,
	GetLog = GetLog,
	log = log,
	clearLog = clearLog,
	SetupCustomLogUI = SetupCustomLogUI,
	StartDelayTimer = StartDelayTimer,
	GetDelayTimerStatus = GetDelayTimerStatus,
	DeleteDelayTimer = DeleteDelayTimer,
	IsLoadGUIWithTimer = IsLoadGUIWithTimer,
	IsLoadGUI = IsLoadGUI,
	IsPausedGUI = IsPausedGUI,
	IsInterruptedGUI = IsInterruptedGUI,
	IsLoadGUIBefore = IsLoadGUIBefore,
	UpdateIsLoadingBefore = UpdateIsLoadingBefore,
	IsPausedGUIBefore = IsPausedGUIBefore,
	UpdateIsPausedGUIBefore = UpdateIsPausedGUIBefore,
	IsInterruptedGUIBefore = IsInterruptedGUIBefore,
	UpdateIsInterruptedGUIBefore = UpdateIsInterruptedGUIBefore,
	
	get_component = get_component,
	get_components = get_components,
	generate_enum = generate_enum,
	generate_enum_reverse = generate_enum_reverse,
	edit_enum = edit_enum,
	FindStringLastInstance = FindStringLastInstance,
	RemoveSuffix = RemoveSuffix,
	ContainsString = ContainsString,
	file_exists = file_exists,
	isModuleAvailable = isModuleAvailable,
	isModuleLoaded = isModuleLoaded,

	GetBooleanValue = GetBooleanValue,
	ChangeToDefaultIfNil = ChangeToDefaultIfNil,
	ChangeToDefaultIfNotANumber = ChangeToDefaultIfNotANumber,
	NewValueType = NewValueType,
	NewObjectInstance = NewObjectInstance,
	GetMethod = GetMethod,	
	ReplicateString = ReplicateString,
	NormalizeID = NormalizeID,
	file_exists = file_exists,
	deepcopy_table = deepcopy_table,
	GetFileList = GetFileList,
	RefreshFileNamesList = RefreshFileNamesList,
	SetIsFileListLoaded = SetIsFileListLoaded,
	GetDataTableFromFile = GetDataTableFromFile,
	SetIsFileDataTableLoaded = SetIsFileDataTableLoaded,
	GetFileNamesList = GetFileNamesList,
	--GetFont = GetFont,
	--SetFont = SetFont,
	GetButtonClicked = GetButtonClicked,
	SetButtonClicked = SetButtonClicked,
	GetShowWindow = GetShowWindow,
	GetShowWindowPrev = GetShowWindowPrev,
	SetShowWindow = SetShowWindow,
	GetCustomList = GetCustomList,
	SetCustomList = SetCustomList,
	GetCustomListIsPopulated = GetCustomListIsPopulated,
	SetCustomListIsPopulated = SetCustomListIsPopulated,
	GetListItem = GetListItem,
	Vec3ToTable = Vec3ToTable,
	TableToVec3 = TableToVec3,
	GetVec3String = GetVec3String,
	Vec4ToTable = Vec4ToTable,
	TableToVec4 = TableToVec4,
	GetVec4String = GetVec4String,
	GetPreviousListItem = GetPreviousListItem,
	GetCurrentListIndex = GetCurrentListIndex,
	GetNextListItem = GetNextListItem,
	IsKeyboardKeyPressedOrTriggered = IsKeyboardKeyPressedOrTriggered,
	IsGamePadButtonPressedOrTriggered = IsGamePadButtonPressedOrTriggered,
	IsKeyPressedOrTriggered = IsKeyPressedOrTriggered,
	IsButtonPressedOrTriggered = IsButtonPressedOrTriggered,
	GetFilteredList = GetFilteredList,
	FindListMatch = FindListMatch,
	FindListFieldValueMatch = FindListFieldValueMatch,
	AppendItemNamesToListItems = AppendItemNamesToListItems,
	AppendGenderToListItems = AppendGenderToListItems,
	GetAliveStatusString = GetAliveStatusString,
	GetSpeciesString = GetSpeciesString,
	GetGenderString = GetGenderString,
	ParseColor = ParseColor,
	Vec4ToColorString = Vec4ToColorString,
	Vec4ToColor = Vec4ToColor,
	ColorToVec4 = ColorToVec4,
	ColorToColorString = ColorToColorString,
	ColorStringToVec4 = ColorStringToVec4,
	AddContentEditorContentToEnum = AddContentEditorContentToEnum,
	CyrillicInputText = CyrillicInputText,
	TextBoxWithCopyAndClearButtons = TextBoxWithCopyAndClearButtons,
	TextBoxWithPlusAndMinusButtons = TextBoxWithPlusAndMinusButtons,
	ColorEdit4WithCopyAndPasteButtons = ColorEdit4WithCopyAndPasteButtons,
	ComboBoxWithNextAndPreviousButtons = ComboBoxWithNextAndPreviousButtons,
	TextColoredWithOnHoverTooltip = TextColoredWithOnHoverTooltip,
	SetupUnmatchedModuleVersionsUI = SetupUnmatchedModuleVersionsUI,
	SetupFreezeAndSetValueUI = SetupFreezeAndSetValueUI,
	ShowPopupWindow = ShowPopupWindow,
	AddShowPopupWindowButton = AddShowPopupWindowButton,
	SpamRequestCheckPassed = SpamRequestCheckPassed,
	GetCurrentScene = GetCurrentScene,
	GetCharaEditModelCtrl = GetCharaEditModelCtrl,
	GetSceneGUI = GetSceneGUI,
	IsInDetailedCharacterCustomizationScreen = IsInDetailedCharacterCustomizationScreen,
	GetActiveMockupDetails = GetActiveMockupDetails,
	GetSpecificMockupDetails = GetSpecificMockupDetails,
	GetCharacterStatusSceneDetails = GetCharacterStatusSceneDetails,
	GetHookStorageValue = GetHookStorageValue,
	SetHookStorageValue = SetHookStorageValue,
	SetupCreateEditDeleteDataTableFileUI = SetupCreateEditDeleteDataTableFileUI,
	SetNativeField = SetNativeField,

	CharacterStatusScreen = CharacterStatusScreen,
	GetDefaultLastViewedCharacterDetails = GetDefaultLastViewedCharacterDetails,
	ReadLastViewedCharacterDetailsFile = ReadLastViewedCharacterDetailsFile,
	InitializeCharacterStatusScreen = InitializeCharacterStatusScreen,
	SetupViewCharacterStatusUI = SetupViewCharacterStatusUI,
	RefreshViewCharacterStatusUI = RefreshViewCharacterStatusUI

}

return common
local modName = "NPC Finder"

local _NPCManager;
local function GetNPCManager()
    if _NPCManager == nil then
        _NPCManager = sdk.get_managed_singleton("app.NPCManager");
    end
    return _NPCManager;
end 

local _characterManager;
local function GetCharacterManager()
    if _characterManager == nil then
        _characterManager = sdk.get_managed_singleton("app.CharacterManager");
    end
    return _characterManager;
end

local _worldOffsetSystem
local function GetWorldOffsetSystem()
    if _worldOffsetSystem == nil then
        _worldOffsetSystem = sdk.get_managed_singleton("app.WorldOffsetSystem");
    end
    return _worldOffsetSystem;
end

local NPCDataArray = {};
local NPCDataFound = false;
local searchString = "";
local searchStringChange = false;

local getCharaName = sdk.find_type_definition("app.GUIBase"):get_method("getName(app.CharacterID)")
local function translate_character_name(characterId)
    return getCharaName:call(nil, characterId)
end

-- Returns 2D array, where dimension is NPC index,
-- (name, character id, index)  
local function GetNPCData()
	local NPCHolderDic = sdk.get_managed_singleton('app.NPCManager').NPCHolderDic
	for i = 0, NPCHolderDic:get_Length() - 1 do
		local NPCHolder = NPCHolderDic[i]
		if NPCHolder then
			print(i, NPCHolder.CharaID)
            NPCDataArray[i] = {};
            NPCDataArray[i][1] = translate_character_name(NPCHolder.CharaID);
            NPCDataArray[i][2] = NPCHolder.CharaID;
            NPCDataArray[i][3] = i;
			log.info("TESTJU - NPC name = " .. NPCDataArray[i][1] .. " - NPC ID = " .. NPCDataArray[i][2] .. " - NPC index = " .. NPCDataArray[i][3])
		end
	end
    NPCDataFound = #NPCDataArray > 0;

    -- sort alphabetically
    table.sort(NPCDataArray, function(a,b)
		if a == nil and b == nil then
		  return false
		end
		if a == nil then
		  return true
		end
		if b == nil then
		  return false
		end
		return a[1] < b[1]
	end
	)
end

local _defaultHeightDamageForHuman;
local _defaultBaseDamageForHuman;
local _defaultDamagePerHeightForHuman;
local _defaultHeightDieForHuman;
local fallDamageEnabled = true;
local shouldDisableFallDamageDuringWarp = true;

local function SetIsFallDamageEnabled(enabled)
    local manualPlayer = GetCharacterManager():get_ManualPlayer();
    if manualPlayer then
        local fallDamageCalc = manualPlayer:get_field("<FallDamageParamCalc>k__BackingField");
        if fallDamageCalc then
            local fallDamageCalcParam = fallDamageCalc:get_field("<Param>k__BackingField");
            if fallDamageCalcParam then
                if enabled then
                    fallDamageCalcParam.HeightDamageForHuman = _defaultHeightDamageForHuman;
                    fallDamageCalcParam.BaseDamageForHuman = _defaultBaseDamageForHuman;
                    fallDamageCalcParam.DamagePerHeightForHuman = _defaultDamagePerHeightForHuman;
                    fallDamageCalcParam.HeightDieForHuman = _defaultHeightDieForHuman;
                else
                    if fallDamageEnabled then
                        _defaultHeightDamageForHuman = fallDamageCalcParam.HeightDamageForHuman;
                        _defaultBaseDamageForHuman = fallDamageCalcParam.BaseDamageForHuman;
                        _defaultDamagePerHeightForHuman = fallDamageCalcParam.DamagePerHeightForHuman;
                        _defaultHeightDieForHuman = fallDamageCalcParam.HeightDieForHuman;
                    end
                    fallDamageCalcParam.HeightDamageForHuman = 99999;
                    fallDamageCalcParam.BaseDamageForHuman = 0;
                    fallDamageCalcParam.DamagePerHeightForHuman = 0;
                    fallDamageCalcParam.HeightDieForHuman = 99999;
                end
            end
        end
    end
end

local warpCoroutine;
local warping = false;
local function WarpPlayerToNPCPosition(index)
    local NPCHolderList = GetNPCManager():get_NPCHolder_FullList();
    local playerCharacter = GetCharacterManager():get_ManualPlayer();
    if playerCharacter and NPCHolderList then
        local teleporter = playerCharacter:get_TelepotorProp();
        local NPCHolder = GetNPCManager():get_NPCHolder_FullList():ToArray()[index];
        if teleporter and NPCHolder then
            GetCharacterManager():requestStartPause(playerCharacter, 2);
            teleporter:teleport(GetWorldOffsetSystem():toUniversalPosition(NPCHolder:get_Position()));
            
            warping = true;
            warpCoroutine = coroutine.create(function()
                if shouldDisableFallDamageDuringWarp then
                    SetIsFallDamageEnabled(false);
                end

                local time = os.time();
                local newTime = time + 4;
                while (time < newTime) do
                    coroutine.yield();
                    time = os.time();
                end

                GetCharacterManager():requestEndPause(playerCharacter, 2);
                newTime = time + 2;

                while (time < newTime) do
                    coroutine.yield();
                    time = os.time();
                end

                if shouldDisableFallDamageDuringWarp then
                    SetIsFallDamageEnabled(true);
                end

                warping = false;
                -- Data seems to become invalid eventually. This should hopefully keep it up to date enough.
                NPCDataFound = false;
                GetNPCData();
            end);
        
            coroutine.resume(warpCoroutine);
        end
    end
end

re.on_frame(function()
    if warping then
        coroutine.resume(warpCoroutine);
    end
end)

re.on_draw_ui(function()
    if not NPCDataFound then 
        if imgui.tree_node(modName) then
            if imgui.button("Найти NPC") and GetNPCManager() then
                GetNPCData();
            end
            imgui.tree_pop();
        end
    else
        if warping then
            imgui.text('Телепортация...');
        else
            _, shouldDisableFallDamageDuringWarp = imgui.checkbox("Отключить урон от падения при телепортации: ", shouldDisableFallDamageDuringWarp);
            
            if imgui.tree_node(modName) then
                imgui.push_id("Search Field");
                searchStringChange, searchString = imgui.input_text("Поиск", searchString, 0);
                imgui.pop_id();

                imgui.spacing();
        
				local NPCHolderDic = sdk.get_managed_singleton('app.NPCManager').NPCHolderDic
				for i = 0, NPCHolderDic:get_Length() - 1 do
                    if NPCDataArray[i] and NPCDataArray[i][1] ~= "???" and NPCDataArray[i][1] ~= "?" and string.find(NPCDataArray[i][1]:lower(), searchString:lower()) then
						if imgui.button("Warp To " .. NPCDataArray[i][1]) then
							WarpPlayerToNPCPosition(NPCDataArray[i][3]);
                        end
                        imgui.same_line();
                        imgui.text(" i=" .. i);
                    end
                end
                imgui.tree_pop();
            end
        end
    end 
end
)
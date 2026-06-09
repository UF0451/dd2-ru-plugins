local modName = "AffinityBar"
local modVersion = "2.0.1"

local defaultConfig = {
    displayAfterInteractionOnly = false, -- Показывать шкалу только во время разговора
    bridalCarryWhileInLove = true,       -- Носить главную пешку на руках (свадебный стиль), если она влюблена
    hideWhileTalking = false,            -- Скрывать шкалу симпатии во время разговора
    showOnHailForDuration = false,       -- Показывать шкалу при оклике на заданное время
    hailDisplayDuration = 2,             -- Длительность отображения шкалы после оклика (сек)
    barWidth = 200,                      -- Ширина шкалы
    barHeight = 8,                       -- Высота шкалы
    charWidth = 6.480,                   -- Ширина шрифта текста
    delayedDisplayEnabled = false,       -- Включить задержку отображения
    delayedDisplayDuration = 2.5,        -- Длительность задержки
    cheatModeEnabled = false             -- Режим читов (чит-режим)
}

local _NPCManager = sdk.get_managed_singleton("app.NPCManager")
local _guiManager = sdk.get_managed_singleton("app.GuiManager")
local _characterManager = sdk.get_managed_singleton("app.CharacterManager")
local _worldOffsetSystem = sdk.get_managed_singleton("app.WorldOffsetSystem")
local _BrineProcessor = sdk.get_managed_singleton("app.BrineProcessor")
local _Teleporter = sdk.get_managed_singleton("app.Teleporter")
local _CharacterWarp = sdk.get_managed_singleton("app.CharacterWarp")

if not _NPCManager or not _guiManager then
    print("Не удалось загрузить менеджеры RE Engine для AffinityBar.")
    return
end

local config = {}
local configPath = "AffinityBar.json"

local function saveConfig()
    json.dump_file(configPath, config)
end

local function loadConfig()
    local loadedConfig = json.load_file(configPath)
    if loadedConfig then
        for k, v in pairs(loadedConfig) do
            config[k] = v
        end
    else
        config = defaultConfig
        saveConfig()
    end
end

local function resetToDefault()
    for k, v in pairs(defaultConfig) do
        config[k] = v
    end
    saveConfig()
end

local currentOffset = 0.7  
local targetOffset = 0.7
local currentHeadPos = { x = 0, y = 0 }  
local targetHeadPos = { x = 0, y = 0 }
local lerpSpeed = 1  

local lastAffinityValue = nil
local lastCharacterId = nil
local affinityChange = 0
local changeDisplayTimer = 0
local changeDisplayDuration = 3 

local manualFavorabilityRating = 0

local function Log(msg)
    log.info("[" .. modName .. "] " .. msg)
end

local function getDeltaTime()
    return 0.0167 
end

local function getInteractManager()
    local interactManager = sdk.get_managed_singleton("app.InteractManager")
    if not interactManager then
        log.info("[" .. modName .. "] InteractManager не найден")
    end
    return interactManager
end

local function isPlayerTalking()
    local interactManager = getInteractManager()
    return interactManager and interactManager:get_field("IsPlayerTalking") or false
end

local hailTimer = nil

sdk.hook(sdk.find_type_definition("app.InteractManager"):get_method("Update"), 
    function(args)
        local interactManager = sdk.to_managed_object(args[1])
        local isHailTriggered = interactManager:get_field("IsPlayerInteractTriggered")
        if isHailTriggered then
            hailTimer = interactManager:get_field("<ElapsedSecondAfterPlayerInteract>k__BackingField")
        end
    end,
    function(retval) 
        return retval 
    end
)

local function lerp(current, target, deltaTime)
    return current + (target - current) * deltaTime * lerpSpeed
end

local function updateOffset(deltaTime)
    local isTalking = isPlayerTalking()
    targetOffset = isTalking and 0.2 or 0.7  
    currentOffset = lerp(currentOffset, targetOffset, deltaTime * lerpSpeed)
end

local function setCheatModeFavorability(rating)
    local pawnManager = sdk.get_managed_singleton("app.PawnManager")
    if not pawnManager then
        Log("PawnManager не найден")
        return
    end
    local mainPawn = pawnManager:get_MainPawn()
    if not mainPawn then
        Log("Главная пешка не найдена")
        return
    end
    local mainPawnDataContext = mainPawn.MainPawnDataContext
    if not mainPawnDataContext then
        Log("Данные контекста главной пешки не найдены")
        return
    end

    mainPawnDataContext:set_field("FavorabilityRating", rating)
    local confirmedRating = mainPawnDataContext:get_field("FavorabilityRating")
    if confirmedRating == rating then
        Log("Уровень симпатии изменен на: " .. tostring(rating))
    else
        Log("Не удалось изменить симпатию. Текущая: " .. tostring(confirmedRating))
    end
end

local function getEnumMap(enumTypeName)
    local t = sdk.find_type_definition(enumTypeName)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)
            enum[raw_value] = name
        end
    end

    return enum
end

local isHailTextVisible = false

sdk.hook(sdk.find_type_definition("app.ui021301"):get_method("reqDispCommon(System.Single, System.Guid)"),
    function(args)
        isHailTextVisible = true
        hailTimer = 0
    end,
    function(ret)
        return ret
    end
)

local function getCharacterPos(char)
    local gameObject = char:get_GameObject()
    if not gameObject then return nil end
    local transform = gameObject:get_Transform()
    if not transform then return nil end
    local head = transform:getJointByName("Head_0")
    if head then
        local headPos = head:get_Position()
        headPos.x = headPos.x + 0.0
        
        targetOffset = isPlayerTalking() and 0.2 or 0.7
        headPos.y = headPos.y + lerp(currentOffset, targetOffset, getDeltaTime())
        currentOffset = headPos.y - head:get_Position().y

        return headPos
    else
        return nil
    end
end

local SentimentRanks = getEnumMap("app.SentimentRank")

local function getNPCManager()
    return sdk.get_managed_singleton("app.NPCManager")
end

local function getPlayerManager()
    return sdk.get_managed_singleton("app.CharacterManager")
end

local PawnManager = sdk.get_managed_singleton("app.PawnManager")

local function getPawnManager()
    if not PawnManager then
        PawnManager = sdk.get_managed_singleton("app.PawnManager")
    end
    return PawnManager
end

local MainPawn = nil

local function getMainPawn()
    if MainPawn then return MainPawn end
    local mgr = getPawnManager()
    if mgr then
        MainPawn = mgr:get_MainPawn()
        return MainPawn
    end
end

local function isMainPawn(character)
    local pmgr = getPawnManager()
    if not pmgr then return false end
    local mainPawn = pmgr:get_MainPawn()
    return mainPawn and character == mainPawn:get_CachedCharacter()
end

-- Draw Affinity Bar
local function drawAffinity(char)
    if not char then return end
    local charId = char:get_CharaID()

    local worldPos = getCharacterPos(char)
    if not worldPos then return end

    local screenPos = draw.world_to_screen(worldPos)
    if not screenPos then return end

    local affinityValue, isLove, maxAffinityValue = nil, false, 1000
    if isMainPawn(char) then
        local pmgr = getPawnManager()
        local mainPawn = pmgr and pmgr:get_MainPawn()
        local context = mainPawn and mainPawn.MainPawnDataContext
        if context then
            affinityValue = context:get_FavorabilityRating()
            isLove = context:get_IsLove()
        end
    else
        local npc_mgr = getNPCManager()
        local holder = npc_mgr and npc_mgr:getNPCHolder(charId)
        if holder then
            local p_mgr = getPlayerManager()
            local player = p_mgr and p_mgr:call("get_ManualPlayer")
            if player then
                local ok, sentInfo = pcall(function()
                    return holder:getSentimentInfo(player:get_CharaID(), false)
                end)
                if ok and sentInfo then
                    affinityValue = sentInfo.Value
                    maxAffinityValue = 299
                    isLove = affinityValue >= 185
                end
            end
        end
    end

    if not affinityValue then return end

    if lastCharacterId ~= charId then
        lastCharacterId = charId
        lastAffinityValue = affinityValue
        affinityChange = 0
        changeDisplayTimer = 0
    elseif affinityValue ~= lastAffinityValue then
        affinityChange = affinityValue - lastAffinityValue
        changeDisplayTimer = changeDisplayDuration
    end
    lastAffinityValue = affinityValue

    if changeDisplayTimer > 0 then
        changeDisplayTimer = changeDisplayTimer - getDeltaTime()
    else
        affinityChange = nil  
    end

    local percentage = (affinityValue / maxAffinityValue) * 100
    local text = string.format("%d / %d (%.0f%%)", affinityValue, maxAffinityValue, percentage)
    local changeText = (affinityChange and affinityChange ~= 0) and string.format("%+d", affinityChange) or ""
    local changeTextColor = (affinityChange and affinityChange > 0) and 0xFF8AD950 or 0xFF60609C

    local charWidth = config.charWidth
    local textWidth = #text * charWidth
    local changeTextWidth = #changeText * charWidth
    local textX = screenPos.x - textWidth / 2
    local baseTextY = 20  
    local textY = screenPos.y - (baseTextY * (charWidth / 5.8))  
    local changeTextX = screenPos.x - changeTextWidth / 2
    local changeTextY = textY - 20  

    draw.text(text, textX, textY, 0xf49E9992)
    if changeText ~= "" and changeDisplayTimer > 0 then
        draw.text(changeText, changeTextX, changeTextY, changeTextColor)
    end

    local barWidth = config.barWidth
    local barHeight = config.barHeight
    local barX = screenPos.x - barWidth / 2
    local barY = screenPos.y
    draw.filled_rect(barX, barY, barWidth, barHeight, 0x80000000)
    local barColor = isLove and 0xFF7269C8 or 0xad8c5f5f
    draw.filled_rect(barX, barY, barWidth * (affinityValue / maxAffinityValue), barHeight, barColor)
    local loveThreshold = isMainPawn(char) and 620 or 185
    local thresholdX = barX + (barWidth * (loveThreshold / maxAffinityValue))
    local thresholdRectWidth = 2
    draw.filled_rect(thresholdX - thresholdRectWidth / 2, barY, thresholdRectWidth, barHeight, 0xf49E9992)
end

local interactableCharacter = nil
sdk.hook(sdk.find_type_definition("app.ui021301"):get_method("reqDisp(via.GameObject, System.Single, System.Guid)"),
    function(args)
        local obj = sdk.to_managed_object(args[3])
        interactableCharacter = obj:call("getComponent(System.Type)", sdk.find_type_definition("app.Character"):get_runtime_type())
    end, function(ret) end)

local function isCharacterInteractable(character)
    if not character then return false end
    return isHailTextVisible or isPlayerTalking()
end

sdk.hook(sdk.find_type_definition("app.HumanCatchProcessor"):get_method("startCarry"),
    function(args)
        if config.bridalCarryWhileInLove and isMainPawn(sdk.to_managed_object(args[3])) then
            local pmgr = getPawnManager()
            local mainPawn = pmgr and pmgr:get_MainPawn()
            if mainPawn and mainPawn.MainPawnDataContext and mainPawn.MainPawnDataContext:get_IsLove() then
                sdk.to_managed_object(args[2]):startBridalCarry(args[3])
                return sdk.PreHookResult.SKIP_ORIGINAL
            end
        end
    end, function(ret) end)
    
local proximityTimer = 0

local _NPCManager = sdk.get_managed_singleton("app.NPCManager")
local _characterManager = sdk.get_managed_singleton("app.CharacterManager")
local _worldOffsetSystem = sdk.get_managed_singleton("app.WorldOffsetSystem")
local _guiManager = sdk.get_managed_singleton("app.GuiManager")

local NPCDataArray = {}
local markedNPCs = {}
local npcMarkers = {}
local affinityThreshold = 185  
local loveCount = 0  

local DisableFallDamage = true
local teleportCoroutine
local teleporting = false

local function setIsFallDamageEnabled(enabled)
    local manualPlayer = _characterManager:get_ManualPlayer()
    if manualPlayer then
        local fallDamageCalc = manualPlayer:get_field("<FallDamageParamCalc>k__BackingField")
        if fallDamageCalc then
            local fallDamageCalcParam = fallDamageCalc:get_field("<Param>k__BackingField")
            if fallDamageCalcParam then
                if enabled then
                    fallDamageCalcParam.HeightDamageForHuman = _defaultHeightDamageForHuman
                    fallDamageCalcParam.BaseDamageForHuman = _defaultBaseDamageForHuman
                    fallDamageCalcParam.DamagePerHeightForHuman = _defaultDamagePerHeightForHuman
                    fallDamageCalcParam.HeightDieForHuman = _defaultHeightDieForHuman
                else
                    fallDamageCalcParam.HeightDamageForHuman = 99999
                    fallDamageCalcParam.BaseDamageForHuman = 0
                    fallDamageCalcParam.DamagePerHeightForHuman = 0
                    fallDamageCalcParam.HeightDieForHuman = 99999
                end
            end
        end
    end
end

local getCharaName = sdk.find_type_definition("app.GUIBase"):get_method("getName(app.CharacterID)")
local function translate_character_name(characterId)
    return getCharaName:call(nil, characterId)
end

-- ИСПРАВЛЕНО: Добавлена жесткая проверка на нил, предотвращающая краш
local function refreshNPCList()
    local c_mgr = _characterManager or sdk.get_managed_singleton("app.CharacterManager")
    local player = c_mgr and c_mgr:get_ManualPlayer()
    if not player then
        return
    end

    loveCount = 0
    NPCDataArray = {}

    local playerCharaID = player:get_CharaID()
    local npc_m = _NPCManager or sdk.get_managed_singleton("app.NPCManager")
    local NPCHolderDic = npc_m and npc_m.NPCHolderDic
    if not NPCHolderDic then return end

    -- Ошибка синтаксиса ok_uid2 поправлена на корректное условие
    for i = 0, NPCHolderDic:get_Length() - 1 do
        local NPCHolder = NPCHolderDic[i]
        if NPCHolder then
            local sentimentInfo = NPCHolder:getSentimentInfo(playerCharaID, false)
            if sentimentInfo and sentimentInfo.Value >= affinityThreshold then
                local percent = math.floor(sentimentInfo.Value / 299 * 100)
                table.insert(NPCDataArray, {
                    name = translate_character_name(NPCHolder.CharaID),
                    charaID = NPCHolder.CharaID,
                    affinity = sentimentInfo.Value,
                    percent = percent,
                    index = NPCHolder.CharaID
                })
                if sentimentInfo.Value >= 185 then
                    loveCount = loveCount + 1
                end
            end
        end
    end
    table.sort(NPCDataArray, function(a, b) return a.affinity > b.affinity end)
end

local function getNPCLocation(charaID)
    local npc_holder = _NPCManager:getNPCHolder(charaID)
    if npc_holder then
        local upos = _worldOffsetSystem:toUniversalPosition(npc_holder:get_Position())
        if upos then
            return upos
        else
            Log("Не удалось получить универсальные координаты NPC.")
        end
    else
        Log("NPC Holder не найден для ID: " .. tostring(charaID))
    end
    return nil
end

local function teleportToNPC(charaID)
    local npc_holder = _NPCManager:getNPCHolder(charaID)
    if not npc_holder then return end

    local npcLocation = _worldOffsetSystem:toUniversalPosition(npc_holder:get_Position())
    local player = _characterManager:get_ManualPlayer()
    if not player then return end

    local teleporter = player:get_TelepotorProp()
    if not teleporter then return end
    
    setIsFallDamageEnabled(false)
    player:warp(npcLocation, NoChangePositionContext)
    teleporter:teleport(npcLocation)

    local delayCoroutine = coroutine.create(function()
        coroutine.yield(os.time() + 1)  
        setIsFallDamageEnabled(true)
    end)
    coroutine.resume(delayCoroutine)
end

local function summonNPC(charaID)
    local player = _characterManager:get_ManualPlayer()
    if not player then return end

    local playerTransform = player:get_GameObject():get_Transform()
    if not playerTransform then return end

    local playerLocation = playerTransform:get_Position()
    if not playerLocation then return end

    local playerUniversalLocation = _worldOffsetSystem:toUniversalPosition(playerLocation)
    local playerRotation = playerTransform:get_Rotation()
    if not playerUniversalLocation or not playerRotation then return end

    setIsFallDamageEnabled(false)
    _NPCManager:warp(charaID, playerUniversalLocation, playerRotation)

    local delayCoroutine = coroutine.create(function()
        coroutine.yield(os.time() + 1)  
        setIsFallDamageEnabled(true)
    end)
    coroutine.resume(delayCoroutine)
end

re.on_frame(function()
    if delayCoroutine and coroutine.status(delayCoroutine) ~= 'dead' then
        local waitTime = coroutine.resume(delayCoroutine)
        if os.time() >= waitTime then
            coroutine.resume(delayCoroutine)
        end
    end
end)

local function toggleMarkOnMap(charaId)
    local npc_holder = _NPCManager:getNPCHolder(charaId)
    if not npc_holder then return end

    local upos = npc_holder:get_UniversalPosition()
    if not upos then return end

    local questTargetMarkerList = _guiManager:get_QuestTargetMarkerList()
    if markedNPCs[charaId] then
        local marker = npcMarkers[charaId]
        if marker then
            questTargetMarkerList:Remove(marker)
            npcMarkers[charaId] = nil
            markedNPCs[charaId] = nil
        end
    else
        local marker = sdk.find_type_definition("app.GuiManager.QuestTargetMarkerInfo"):create_instance()
        marker.DestType    = 3 
        marker.IconType    = 0 
        marker.KeyLocation = 0 
        marker.LocalArea   = 0 
        marker.MapArea     = 0 
        marker.Pos         = Vector3f.new(upos.x, upos.y, upos.z)

        questTargetMarkerList:Add(marker)
        npcMarkers[charaId] = marker
        markedNPCs[charaId] = true
    end
end

-- ── ИНТЕРФЕЙС И НАСТРОЙКИ НА РУССКОМ ЯЗЫКЕ ──────────────────────────────────
re.on_draw_ui(function()
if imgui.tree_node("Индикатор отношений (Affinity Bar)") then
imgui.spacing()
imgui.separator()
    imgui.push_style_color(imgui.Col_Button, 0xFF006FC5)  
    imgui.push_style_color(imgui.Col_ButtonHovered, 0xFF006FC5)  
    imgui.push_style_color(imgui.Col_ButtonActive, 0xFFF58000)  
    if imgui.button("Сбросить настройки") then
        resetToDefault()
    end
    imgui.pop_style_color(3)  
    
    imgui.spacing()
    imgui.text("Общие настройки")
    imgui.separator()

    local changed = false
    changed, config.bridalCarryWhileInLove = imgui.checkbox("Носить Влюбленную Пешку на руках", config.bridalCarryWhileInLove)
    if changed then saveConfig() end

    if config.showOnHailForDuration then
        imgui.text("Показывать только при разговоре (Отключено из-за режима 'Только при оклике')")
    else
        changed, config.displayAfterInteractionOnly = imgui.checkbox("Показывать только при разговоре", config.displayAfterInteractionOnly)
        if changed then saveConfig() end
    end

    if config.showOnHailForDuration then
        imgui.text("Скрывать во время разговора (Отключено из-за режима 'Только при оклике')")
    else
        changed, config.hideWhileTalking = imgui.checkbox("Скрывать во время разговора", config.hideWhileTalking)
        if changed then saveConfig() end
    end

    changed, config.showOnHailForDuration = imgui.checkbox("Показывать шкалу только при оклике (Hail)", config.showOnHailForDuration)
    if changed then
        if config.showOnHailForDuration then
            config.hideWhileTalking = false  
            config.displayAfterInteractionOnly = false  
            config.delayedDisplayEnabled = false  
        end
        saveConfig()
    end

    imgui.spacing()
    imgui.text("Настройки задержки отображения")
    imgui.separator()

    if config.showOnHailForDuration then
        imgui.text("Включить задержку отображения (Отключено из-за режима 'Только при оклике')")
    else
        changed, config.delayedDisplayEnabled = imgui.checkbox("Включить задержку отображения", config.delayedDisplayEnabled)
        if changed then 
            saveConfig()
        end
    end

    imgui.spacing()
    imgui.text("Размеры шкалы индикатора")
    imgui.separator()

    changed, config.barWidth = imgui.slider_int("Ширина индикатора", config.barWidth, 100, 500)
    if changed then saveConfig() end

    changed, config.barHeight = imgui.slider_int("Высота индикатора", config.barHeight, 5, 30)
    if changed then saveConfig() end

    changed, config.charWidth = imgui.slider_float("Ширина символов текста", config.charWidth, 5.8, 12.0)
    if changed then saveConfig() end

imgui.spacing()  
if imgui.tree_node("Настройки Чит-Режима") then
    imgui.text("Внимание: Телепортация может вызвать критические ошибки или гибель.")
    imgui.spacing()
    changed, config.cheatModeEnabled = imgui.checkbox("Включить Чит-Режим", config.cheatModeEnabled)
    if changed then saveConfig() end

    if config.cheatModeEnabled then
        changed, manualFavorabilityRating = imgui.slider_float("-/+ Симпатия (Очки)", manualFavorabilityRating, -1000.0, 1000.0, "%.0f")

        imgui.push_style_color(imgui.Col_Button, 0xFF006FC5)  
        imgui.push_style_color(imgui.Col_ButtonHovered, 0xFF006FC5)  
        imgui.push_style_color(imgui.Col_ButtonActive, 0xFFF58000)  
        if imgui.button("Применить изменение отношений (NPC в фокусе)") then
            local p_mgr = getPlayerManager()
            local player = p_mgr and p_mgr:get_ManualPlayer()
            if player and interactableCharacter then
                local playerCharId = player:get_CharaID()
                local targetCharId = interactableCharacter:get_CharaID()
                
                local npcHolder = getNPCManager():getNPCHolder(targetCharId)
                if npcHolder then
                    local sentimentInfo = npcHolder:getSentimentInfo(playerCharId, false)
                    local changeAmount = manualFavorabilityRating 

                    if sentimentInfo then
                        local newSentimentValue = sentimentInfo.Value + changeAmount
                        newSentimentValue = math.max(0, math.min(newSentimentValue, 299)) 
                        npcHolder:updateSentimentInfo(playerCharId, newSentimentValue, true) 
                        Log("Симпатия изменена на " .. tostring(changeAmount) .. " для NPC ID: " .. tostring(targetCharId))
                    end
                end
            end
        end
        imgui.pop_style_color(3)  
    end
    imgui.tree_pop()
end
        imgui.spacing()
        imgui.spacing()
        imgui.text("Список отношений")
        imgui.separator()

        imgui.push_style_color(imgui.Col_Button, 0xFF006FC5)  
        imgui.push_style_color(imgui.Col_ButtonHovered, 0xFF006FC5)  
        imgui.push_style_color(imgui.Col_ButtonActive, 0xFFF58000)  
        if imgui.button("Обновить список") then
            refreshNPCList()
        end
        imgui.pop_style_color(3)  
        
        imgui.spacing()
        imgui.separator()

        imgui.text("Персонажей влюблено в вас: " .. loveCount)

        if #NPCDataArray > 0 then
            local columnCount = config.cheatModeEnabled and 5 or 3  
            imgui.begin_table("NPCList", columnCount)
            imgui.table_setup_column("Имя персонажа")
            imgui.table_setup_column("Симпатия")
            imgui.table_setup_column("Метка на карте")
            if config.cheatModeEnabled then
                imgui.table_setup_column("Телепортироваться к NPC")  
                imgui.table_setup_column("Призвать NPC к себе")
            end
            imgui.table_headers_row()

            for _, npc in ipairs(NPCDataArray) do
                imgui.table_next_row()
                imgui.table_next_column()
                imgui.text(npc.name or "Неизвестный NPC")

                imgui.table_next_column()
                imgui.text(string.format("%d/299 (%d%%)", npc.affinity, npc.percent))

                imgui.table_next_column()
                if imgui.button((markedNPCs[npc.charaID] and "Убрать метку" or "Отметить") .. " " .. (npc.name or "")) then
                    toggleMarkOnMap(npc.charaID)
                end

                if config.cheatModeEnabled then
                    imgui.table_next_column()
                    if imgui.button("Лететь к " .. (npc.name or "")) then
                        teleportToNPC(npc.charaID)
                    end

                    imgui.table_next_column()
                    if imgui.button("Призвать " .. (npc.name or "")) then
                        summonNPC(npc.charaID)
                    end
                end
            end
            imgui.end_table()
        else
            imgui.text("Нет персонажей с высокой симпатией. Нажмите 'Обновить список'.")
        end
        imgui.spacing()
        imgui.spacing()
        imgui.separator()
        imgui.tree_pop()
    end
end)

re.on_frame(function()
    local deltaTime = getDeltaTime()
    local guiManager = sdk.get_managed_singleton("app.GuiManager")
    local interactManager = getInteractManager()

    if not guiManager or not interactManager or guiManager:get_field("<IsDispPhotoModeAll>k__BackingField") then
        return
    end

    local isTalking = isPlayerTalking()
    local shouldDisplay = false

    local isNearCharacter = interactableCharacter and isCharacterInteractable(interactableCharacter)
    if isNearCharacter then
        proximityTimer = proximityTimer + deltaTime
    else
        proximityTimer = 0
    end

    if config.displayAfterInteractionOnly then
        shouldDisplay = isTalking
    elseif config.hideWhileTalking and config.showOnHailForDuration then
        if interactManager:get_field("IsPlayerInteractTriggered") and not isTalking then
            shouldDisplay = (interactManager:get_field("<ElapsedSecondAfterPlayerInteract>k__BackingField") <= config.hailDisplayDuration)
        end
    elseif config.hideWhileTalking then
        shouldDisplay = not isTalking and (isHailTextVisible or isNearCharacter)
    elseif config.showOnHailForDuration then
        if isHailTextVisible then
            shouldDisplay = (interactManager:get_field("<ElapsedSecondAfterPlayerInteract>k__BackingField") <= config.hailDisplayDuration)
        end
    elseif config.delayedDisplayEnabled then
        shouldDisplay = (proximityTimer >= config.delayedDisplayDuration)
    else
        shouldDisplay = isNearCharacter or isHailTextVisible
    end

if shouldDisplay and interactableCharacter then
        local ok, err = pcall(drawAffinity, interactableCharacter)
        if not ok then
            interactableCharacter = nil
        end
    else
        interactableCharacter = nil
    end

    isHailTextVisible = interactManager:get_field("IsPlayerInteractTriggered")
end)

function updateHailTimer(interactManager, deltaTime)
    if interactManager:get_field("IsPlayerInteractTriggered") then
        if not hailTimer then
            hailTimer = 0
        end
    elseif hailTimer then
        hailTimer = hailTimer + deltaTime
    end
end

sdk.hook(sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),
    function(args)
        hailTimer = nil
        interactableCharacter = nil
    end,
    function(ret)
        return ret
    end
)

loadConfig()
Log("Мод успешно загружен: " .. modName .. " v" .. modVersion)
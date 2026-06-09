local modname = "Nudify"
local configfile = modname .. '.json'

-- Локализация вариантов отображения одежды
local Choices = {"В одежде", "Цензура (Пар)", "Без одежды", "Нижнее белье"}
local Genders = {"Male", "Female"}

-- Локализация имен ключевых персонажей под официальный перевод DD2
local NPCList = {
    ["Брант"] = "ch310006",
    ["Диса"] = "ch310004",
    ["Дориан"] = "ch310019",
    ["Елена"] = "ch310033",
    ["Глиндр"] = "ch310017",
    ["Надиния"] = "ch310034",
    ["Файзус"] = "ch310009",
    ["Рагналл"] = "ch310078",
    ["Сара"] = "ch310025",
    ["Свен"] = "ch310003",
    ["Ульрика"] = "ch310073",
    ["Вильгельмина"] = "ch310002"
}

local config = json.load_file(configfile) or {["NPCs"] = NPCList,["EnableList"] = {["Male"] = 1, ["Female"] = 1}}

local enabled
local vars = {}
vars.NPCs = config.NPCs or {}
vars.EnableList = config.EnableList
vars.Party = config.Party or {["ch000000_00"] = {["Option"] = 1}}
vars.PawnList = {}
local NPCSpacing
local PartySpacing = Vector2f.new(10, 10)
local NPCManager = sdk.get_managed_singleton("app.NPCManager")
local badTypes = {[198] = true, [192] = true, [195] = true}
NoSpaCensorOverride = {}

-- Страховочная инициализация ключа игрока, чтобы избежать nil-вылетов
if not vars.Party["ch000000_00"] then
    vars.Party["ch000000_00"] = {["Option"] = 1}
end

local function saveConfig()
    local newConfig = {["NPCs"] = vars.NPCs,["EnableList"] = {},["Party"] = {}}
    newConfig.Party = vars.Party
    for k,v in pairs(vars.EnableList) do
        if k == "Male" or k == "Female" or v > 1 then
            newConfig.EnableList[k] = v
        end
    end
    config = newConfig
    if json.load_file(configfile) ~= newConfig then
        json.dump_file(configfile, newConfig)
    end
    NPCSpacing = imgui.calc_text_size(getLargestKey(vars.NPCs))
end


local function requestCheck(CharacterID, option)
    local CharacterData = NPCManager:getNPCCharacterData(CharacterID)
    if not CharacterData then return false end
    if badTypes[CharacterData:get_field("HumanType")] then
        return 0
    else
        return option - 1
    end
end


local function toggleNudity(Human, request_type)
    local UndressCtrl = Human:get_UndressCtrl()
    local PartSwapper = Human:get_Chara():get_HumanPartSwapper()
    if EkiToolsBox ~= nil and EkiToolsBox.BlackListed ~= nil and EkiToolsBox.BlackListed.PartSwapper ~= nil then
        local PartSwapperHashCode = PartSwapper:GetHashCode()
        if EkiToolsBox.BlackListed.PartSwapper[PartSwapperHashCode] == nil then EkiToolsBox.BlackListed.PartSwapper[PartSwapperHashCode] = {} end
        if request_type == 0 then
            EkiToolsBox.BlackListed.PartSwapper[PartSwapperHashCode][modname] = nil
        else
            EkiToolsBox.BlackListed.PartSwapper[PartSwapperHashCode][modname] = PartSwapper
        end
    end
    if request_type == 1 then
        NoSpaCensorOverride[Human] = true
    end
    UndressCtrl:request(request_type, false)
end


local function nudifyPartyMember(member, option)
    local Character
    if member == 3 then
        Character = sdk.get_managed_singleton("app.CharacterManager"):get_ManualPlayer()
    else
        local Pawn = sdk.get_managed_singleton("app.PawnManager"):getPartyPawn(member, true)
        if not Pawn then return end
        Character = Pawn:get_CachedCharacter()
    end
    local request_type = option - 1
    if not Character then return end
    local CharaIDString = Character:get_CharaIDString()
    local Human = Character:get_Human()
    if not Human then return end
    toggleNudity(Human, request_type)
end


local function nudifyNPC(charaIDstring, option, doSave)
    local charaID = sdk.find_type_definition("app.CharacterID"):get_field(charaIDstring):get_data()
    local Character = NPCManager:getCharacter(charaID)
    if not Character then return end
    local Human = Character:get_Human()
    if not Human then return end
    local request_type = option == 1 and option - 1 or requestCheck(charaID, option)
    if not request_type then return end
    if doSave then
        vars.EnableList[charaIDstring] = request_type > 0 and request_type + 1 or nil
        saveConfig()
    end
    toggleNudity(Human, request_type)
end


local function nudifyAll()
    local Character = sdk.get_managed_singleton("app.CharacterManager"):get_ManualPlayer()
    if Character then 
        local Human = Character:get_Human()
        local option = config.Party["ch000000_00"] and config.Party["ch000000_00"]["Option"] > 1 and config.Party["ch000000_00"]["Option"] or config.EnableList[Genders[Human:get_IsFemaleLooks() and 2 or 1]] or 1
        toggleNudity(Human, option - 1)
    end
    local PartyList = sdk.get_managed_singleton("app.PawnManager"):get_PawnCharacterList():ToArray():get_elements()
    if #PartyList > 0 then
        for i,Character in ipairs(PartyList) do
            local Human = Character:get_Human()
            local CharaIDString = Character:get_CharaIDString()
            local option = config.Party[CharaIDString] and config.Party[CharaIDString]["Option"] > 1 and config.Party[CharaIDString]["Option"] or config.EnableList[Genders[Human:get_IsFemaleLooks() and 2 or 1]] or 1
            toggleNudity(Human, option - 1)
        end
    end
    local EntityList = NPCManager:get_NPCHolder_EntityList():ToArray():get_elements()
    if #EntityList > 0 then
        for i,obj in ipairs(EntityList) do
            local Character = obj:get_chara()
            if not Character then return end
            local Human = Character:get_Human()
            if not Human then return end
            local CharaIDString = Character:get_CharaIDString()
            local option = config.EnableList[CharaIDString] or config.EnableList[Genders[Human:get_IsFemaleLooks() and 2 or 1]] or 1
            local request_type = option == 1 and option - 1 or requestCheck(Character:get_CharaID(), option)
            if not request_type then return end
            toggleNudity(Human, request_type)
        end
    end
end


function table.reduce(arr)
    local newarr = {}
    for i,v in ipairs(arr) do 
        if v then table.insert(newarr, v) end
    end
    return newarr
end


local function refreshParty(force)
    local isSameLanguage = sdk.find_type_definition("app.GUIBase"):get_method("isSameLanguage(app.PawnDataContext)")
    local pmgr = sdk.get_managed_singleton("app.PawnManager")
    local PartyList = pmgr and pmgr:get_PartyPawnList():ToArray():get_elements() or {}
    
    local NewPawnSettings = {["ch000000_00"] = {}}
    local NewPawnList = {false,false,false,false}
    local longestVec = imgui.calc_text_size("Восставший")
    local longestSize = longestVec:length()
    
    NewPawnSettings["ch000000_00"]["Option"] = vars.Party["ch000000_00"] and vars.Party["ch000000_00"]["Option"] or 1
    
    if #PartyList > 0 then
        for i,Pawn in ipairs(PartyList) do
            local PawnContext = Pawn:get_CachedAIGoalPlanning():get_CachedPawnContext()
            local PawnID = tonumber(Pawn:get_PawnID())
            local name = isSameLanguage(nil, PawnContext) and PawnContext:get_Name() or PawnContext:get_Nickname()
            if PawnID == 1 then 
                local newVec = imgui.calc_text_size(name)
                longestVec = newVec:length() > longestSize and newVec or longestVec
            end
            local CharaIDString = Pawn:get_CachedCharacter():get_CharaIDString()
            NewPawnList[PawnID+1] = CharaIDString
            NewPawnSettings[CharaIDString] = {["Name"] = name, ["PawnID"] = PawnID, ["Option"] = vars.Party[CharaIDString] and vars.Party[CharaIDString]["Option"] or 1}
        end
    end
    PartySpacing = longestVec
    vars.Party = NewPawnSettings
    vars.PawnList = table.reduce(NewPawnList)
    saveConfig()
end

local function addNPC(charaIDstring)
    local sanitized = string.gsub(charaIDstring, "chch", "ch")
    local field = sdk.find_type_definition("app.CharacterID"):get_field(sanitized)
    if not field then return end
    local charaID = field:get_data()
    local CharacterData = NPCManager:getNPCCharacterData(charaID)
    if not CharacterData then return end
    vars["in_value"] = ""
    if requestCheck(charaID, 3) == 0 then return end
    vars.NPCs[CharacterData:get_Name()] = sanitized
    saveConfig()
end


local function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0
    local iter = function ()
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end


function getLargestKey(t)
    local largest = ""
    local largestSize = 0
    for k,v in pairs(t) do
        local nextSize = imgui.calc_text_size(k):length()
        if nextSize > largestSize then 
            largestSize = nextSize
            largest = k
        end
    end
    return largest
end


-- ── ИСПРАВЛЕННЫЙ И РУСИФИЦИРОВАННЫЙ ИНТЕРФЕЙС ────────────────────────────────
re.on_draw_ui(function ()
    if imgui.tree_node(modname) then
        imgui.push_item_width(120)
        
        -- Тотальная защита от пустых (nil) значений при обновлении списков в рантайме
        if not vars.Party then vars.Party = {} end
        if not vars.Party["ch000000_00"] then vars.Party["ch000000_00"] = {["Option"] = 1} end
        
        if imgui.tree_node("Общие глобальные настройки") then
            vars["female_changed"], vars.EnableList["Female"] = imgui.combo("Женщины (Все)", vars.EnableList["Female"], Choices)
            imgui.same_line()
            imgui.text(" ")
            imgui.same_line()
            vars["male_changed"], vars.EnableList["Male"] = imgui.combo("Мужчины (Все)", vars.EnableList["Male"], Choices)
            if vars["female_changed"] or vars["male_changed"] then saveConfig() nudifyAll() end
            imgui.tree_pop()
        end
        
        if imgui.tree_node("Настройки отряда (Группа)") then
            imgui.same_line()
            if imgui.small_button("Обновить состав группы") then
                refreshParty(true)
            end
            vars["Arisen_changed"], vars.Party["ch000000_00"]["Option"] = imgui.combo("Восставший", vars.Party["ch000000_00"]["Option"], Choices)
            if vars["Arisen_changed"] then saveConfig() nudifyPartyMember(3, vars.Party["ch000000_00"]["Option"]) end
            for n,v in ipairs(vars.PawnList) do
                if vars.Party[v] then
                    if vars.Party[v]["PawnID"] ~= 1 then imgui.same_line() end
                    if vars.Party[v]["PawnID"] == 0 then 
                        imgui.same_line()
                        imgui.invisible_button(v.."space", (PartySpacing - imgui.calc_text_size("Восставший")))
                        imgui.same_line()
                    end
                    vars[v .."_changed"], vars.Party[v]["Option"] = imgui.combo(vars.Party[v]["Name"] or "Пешка", vars.Party[v]["Option"], Choices)
                    if vars[v .."_changed"] then saveConfig() nudifyPartyMember(vars.Party[v]["PawnID"], vars.Party[v]["Option"]) end
                    if vars.Party[v]["PawnID"] == 1 then 
                        imgui.same_line()
                        imgui.invisible_button(v.."space", (PartySpacing - imgui.calc_text_size(vars.Party[v]["Name"] or "Пешка")))
                    end
                end
            end
            imgui.tree_pop()
        end
        
        if imgui.tree_node("Индивидуальные настройки NPC") then
            imgui.text("Добавьте уникального NPC в список по его цифровому ID (например, 310019 для Дориан)")
            imgui.text("Идентификатор: ch")
            imgui.same_line()
            vars["in_changed"], vars["in_value"], vars["in_start"], vars["in_end"] = imgui.input_text(" ", vars["in_value"])
            imgui.same_line()
            if imgui.button("Добавить NPC") and #vars["in_value"] > 0 then
                addNPC("ch"..vars["in_value"])
            end
            local i = 0
            local lasttext = ""
            imgui.spacing()
            for k,v in pairsByKeys(vars.NPCs or {}) do
                if (i % 2 ~= 0) then imgui.same_line() imgui.invisible_button(v.."space", (NPCSpacing - imgui.calc_text_size(lasttext))) imgui.same_line() end
                lasttext = k
                if imgui.button("Удалить##"..v) then 
                    vars.EnableList[v] = nil
                    vars.NPCs[k] = nil 
                    saveConfig()
                end
                imgui.same_line()
                vars[v .."_changed"], vars.EnableList[v] = imgui.combo(k, vars.EnableList[v], Choices)
                if vars[v .."_changed"] then nudifyNPC(v, vars.EnableList[v], true) end
                i = i+1
            end
            imgui.tree_pop()
        end
        imgui.pop_item_width()
        imgui.tree_pop()
    end
end
)


NPCSpacing = imgui.calc_text_size(getLargestKey(vars.NPCs))


sdk.hook(sdk.find_type_definition("app.CharacterFade"):get_method("start()"),
function (args)
    local Character = sdk.to_managed_object(args[2]):get_field("_Character")
    if not Character then return end
    local Human = Character:get_Human()
    if not Human then return end
    local CharaIDString = Character:get_CharaIDString()
    local gender = Human:get_IsFemaleLooks() and 2 or 1
    
    if not vars.Party then vars.Party = {} end
    
    if vars.Party[CharaIDString] and vars.Party[CharaIDString]["Option"] and vars.Party[CharaIDString]["Option"] > 1  then 
        local PawnID = vars.Party[CharaIDString]["PawnID"] or 3
        nudifyPartyMember(PawnID, vars.Party[CharaIDString]["Option"])
    else
        local option = config.EnableList[CharaIDString] or config.EnableList[Genders[gender]] or 1
        if option > 1 then
            nudifyNPC(CharaIDString, option, false)
        end
    end
end, function(retval)
    return retval
end
)


sdk.hook(sdk.find_type_definition("app.HumanLanternController"):get_method("hasEnableLantern()"),
function (args)
    local LanternController = sdk.to_managed_object(args[2])
    local Character = LanternController:get_field("Chara")
    if Character and Character:get_Human() and Character:get_Human():get_UndressCtrl():get_IsUndress() then
        local storage = thread.get_hook_storage()
        storage["this"] = true
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end,
function (retval)
    if thread.get_hook_storage()["this"] then 
        return sdk.to_ptr(false)
    else
        return  retval
    end
end
)
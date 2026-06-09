local re = re
local sdk = sdk
local imgui = imgui
local log = log
local json = json

local CN_FONT_NAME = 'NotoSansSC-Bold.otf'
local t_CN_FONT_NAME = 'NotoSansCJKtc-Bold.otf'

local CN_FONT_SIZE = 18
local CJK_GLYPH_RANGES = {
    0x0020, 0x00FF, -- Basic Latin + Latin Supplement
    0x2000, 0x206F, -- General Punctuation
    0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
    0x31F0, 0x31FF, -- Katakana Phonetic Extensions
    0xFF00, 0xFFEF, -- Half-width characters
    0x4e00, 0x9FAF, -- CJK Ideograms
    0
}

local fontCN = imgui.load_font(CN_FONT_NAME, CN_FONT_SIZE, CJK_GLYPH_RANGES)

log.info("True Warfarer Загружен");

local Config = json.load_file('true-warfarer.json') or {}
local Locstring = json.load_file("locstrings-truewarfarer.json") or {}

-- Встроенный локализатор на случай, если файла локализации нет или он неполный
local RU_Localization = {
    ["jobNames"] = {
        [1] = "Боец",
        [2] = "Лучник",
        [3] = "Маг",
        [4] = "Вор",
        [5] = "Воин",
        [6] = "Чародей",
        [7] = "Мистический копейщик",
        [8] = "Маг-лучник",
        [9] = "Иллюзионист",
        [10] = "Ратник (Warfarer)"
    },
    ["skillNames"] = {
        ["0"] = "Пусто",
        ["100"] = "Быстрая смена (Rearm)",
        ["101"] = "Левитация (Маг)"
        -- Сюда можно вручную дополнить ID других навыков при необходимости,
        -- но в основном они подтягиваются из файла locstrings-truewarfarer.json
    },
    ["ui"] = {
        ["title"] = "Истинный Ратник (True Warfarer)",
        ["language"] = "Язык (Language)",
        ["stamina_chk"] = "Убрать затраты выносливости на навык 'Быстрая смена'",
        ["apply_all"] = "Назначить 'Быструю смену' для всех на",
        ["apply_btn"] = "Применить",
        ["management"] = "Управление наборами навыков",
        ["slot_left"] = "Слот: Влево",
        ["slot_top"] = "Слот: Вверх",
        ["slot_down"] = "Слот: Вниз",
        ["slot_right"] = "Слот: Вправо"
    }
}

if Config.RearmStaminaCostRemoved == nil then
    Config.RearmStaminaCostRemoved = false
end

local function FindIndex(table, value)
    for i = 1, #table do if table[i] == value then return i; end end
    return nil;
end

local Languages = {"EN", "RU", "CN","t_CN"}
if Config.Language == nil or FindIndex(Languages, Config.Language) == nil then
    Config.Language = "RU" -- Меняем дефолтный язык при первом запуске на RU
end

local PlayerManager
local function GetPlayerManager()
    if PlayerManager == nil then
        PlayerManager = sdk.get_managed_singleton(
                            'app.AppSingleton`1<app.CharacterManager>'):call(
                            'get_Instance')
    end
    return PlayerManager
end

local GUIManager
local function GetGUIManager()
    if GUIManager == nil then
        GUIManager = sdk.get_managed_singleton("app.GuiManager")
    end
    return GUIManager
end

local function GetJobNameLoc(id)
    if Config.Language == "RU" and RU_Localization["jobNames"][id] then
        return RU_Localization["jobNames"][id]
    end
    if Locstring[Config.Language] and Locstring[Config.Language]["jobNames"] then
        return Locstring[Config.Language]["jobNames"][id]
    end
    if Locstring["EN"] and Locstring["EN"]["jobNames"] then
        return Locstring["EN"]["jobNames"][id]
    end
    return RU_Localization["jobNames"][id] or ("Класс " .. tostring(id))
end

local function GetSkillNameLoc(id)
    local str_id = tostring(id)
    if Config.Language == "RU" and RU_Localization["skillNames"][str_id] then
        return RU_Localization["skillNames"][str_id]
    end
    if Locstring[Config.Language] and Locstring[Config.Language]["skillNames"] then
        return Locstring[Config.Language]["skillNames"][str_id]
    end
    if Locstring["EN"] and Locstring["EN"]["skillNames"] then
        return Locstring["EN"]["skillNames"][str_id]
    end
    return RU_Localization["skillNames"][str_id] or ("Навык ID: " .. str_id)
end

local function GetUIText(key, default)
    if Config.Language == "RU" and RU_Localization["ui"][key] then
        return RU_Localization["ui"][key]
    end
    return default
end

local WeaponValidSkillMap = {
    [1] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 100},
    [2] = {0, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 100},
    [3] = {0, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 100},
    [4] = {0, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 101, 100},
    [5] = {0, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 100},
    [6] = {0, 24, 25, 26, 27, 62, 63, 64, 65, 66, 67, 68, 69, 100},
    [7] = {0, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 100},
    [8] = {0, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 100},
    [9] = {0, 92, 93, 94, 95, 96, 97, 98, 99, 100},
    [10] = {0}
}

local function SetCurrentJobSkills(skills)
    local playerMgr = GetPlayerManager();
    if not playerMgr then return end

    local player = playerMgr:call("get_ManualPlayer()");
    if not player then return end

    local human = player:call("get_Human");
    if not human then return end

    local jobCtx = human:call("get_JobContext")
    if not jobCtx then return end

    local currentJob = jobCtx:get_field("CurrentJob")
    if not currentJob then return end

    local skillCtx = human:call("get_SkillContext")
    if not skillCtx then return end

    for i = 1, 4 do skillCtx:setSkill(currentJob, skills[i], i - 1) end

    local gui = GetGUIManager();
    if gui then gui:call("setupKeyGuideCustomSkill()") end
end

local function GetSkillSetByJobId(currentJob)
    local playerMgr = GetPlayerManager();
    if not playerMgr then return end

    local player = playerMgr:call("get_ManualPlayer()");
    if not player then return end

    local human = player:call("get_Human");
    if not human then return end

    local jobCtx = human:call("get_JobContext")
    if not jobCtx then return end

    return Config.SkillSets[currentJob]
end

local function GetPlayerCurrentSkills()
    local playerMgr = GetPlayerManager();
    if not playerMgr then return end

    local player = playerMgr:call("get_ManualPlayer()");
    if not player then return end

    local human = player:call("get_Human");
    if not human then return end

    local jobCtx = human:call("get_JobContext")
    if not jobCtx then return end

    local currentJob = jobCtx:get_field("CurrentJob")
    if not currentJob then return end

    local skillCtx = human:call("get_SkillContext")
    if not skillCtx then return end

    local skills = {}
    for i = 1, 4 do skills[i] = skillCtx:getSkillID(currentJob, i - 1) end

    return skills
end

local function GetPlayerSkillsOfJob(job)
    local playerMgr = GetPlayerManager();
    if not playerMgr then return end

    local player = playerMgr:call("get_ManualPlayer()");
    if not player then return end

    local human = player:call("get_Human");
    if not human then return end

    local skillCtx = human:call("get_SkillContext")
    if not skillCtx then return end

    local skills = {}
    for i = 1, 4 do skills[i] = skillCtx:getSkillID(job, i - 1) end

    return skills
end

local function GetPlayerSkillCtx(job)
    local playerMgr = GetPlayerManager();
    if not playerMgr then return end

    local player = playerMgr:call("get_ManualPlayer()");
    if not player then return end

    local human = player:call("get_Human");
    if not human then return end

    local skillCtx = human:call("get_SkillContext")
    if not skillCtx then return end

    return skillCtx
end

local function GetSkillOptionsByJobId(id)
    local validSkills = WeaponValidSkillMap[id]
    local res = {}
    for k,v in pairs(validSkills) do
        if GetSkillNameLoc(v) then
            res[v] = GetSkillNameLoc(v)
        end
    end
    return res
end

-- Инициализация наборов навыков
if Config.SkillSets == nil then
    Config.SkillSets = {}
    for i = 1, 10 do Config.SkillSets[i] = {100, 100, 100, 100} end
end

local skillSlotOptions = {
    [1] = "Влево",
    [2] = "Вверх",
    [3] = "Вниз",
    [4] = "Вправо"
}
local newIndex
local skillSlotIndex = 1

re.on_draw_ui(function()
    local configChanged = false
    
    -- Название главного древа UI
    if imgui.tree_node(GetUIText("title", "True Warfarer")) then
        local changed = false
        local langIdx = FindIndex(Languages, Config.Language)
        
        -- Выбор языка
        changed, langIdx = imgui.combo(GetUIText("language", "Language"), langIdx, Languages)
        configChanged = configChanged or changed
        Config.Language = Languages[langIdx]
        
        -- Снятие затрат выносливости
        local rearmStaminaCostRemoved
        changed, rearmStaminaCostRemoved = imgui.checkbox(
                                               GetUIText("stamina_chk", "Stamina cost of rearm skill removed"),
                                               Config.RearmStaminaCostRemoved)
        configChanged = configChanged or changed
        Config.RearmStaminaCostRemoved = rearmStaminaCostRemoved
        
        -- Массовое назначение быстрой смены оружия
        changed, newIndex = imgui.combo(GetUIText("apply_all", "Apply Rearm skill to all"),
                                        skillSlotIndex, skillSlotOptions)
        skillSlotIndex = newIndex
        configChanged = configChanged or changed

        imgui.same_line()
        if imgui.button(GetUIText("apply_btn", "Apply")) then
            for i = 1, 9 do
                local skillSet = Config.SkillSets[i];
                skillSet[skillSlotIndex] = 100
                configChanged = true
            end
        end
        
        if Config.Language == "CN"  then imgui.push_font(fontCN) end
        if Config.Language == "t_CN"  then imgui.push_font(fontt_CN) end

        -- Меню управления наборами
        if imgui.tree_node(GetUIText("management", "Skill Set Management")) then
            for i = 1, 9 do
                local name = GetJobNameLoc(i)

                local skillSet = Config.SkillSets[i]
                if not skillSet then
                    Config.SkillSets[i] = {100, 100, 100, 100}
                    skillSet = {100, 100, 100, 100}
                end

                local opened = imgui.tree_node(name)
                local idx
                local validSkillOptions = GetSkillOptionsByJobId(i)

                if opened then
                    changed, idx = imgui.combo(GetUIText("slot_left", "Left"), skillSet[1], validSkillOptions)
                    skillSet[1] = idx
                    configChanged = configChanged or changed
                    
                    changed, idx = imgui.combo(GetUIText("slot_top", "Top"), skillSet[2], validSkillOptions)
                    skillSet[2] = idx
                    configChanged = configChanged or changed
                    
                    changed, idx = imgui.combo(GetUIText("slot_down", "Down"), skillSet[3], validSkillOptions)
                    skillSet[3] = idx
                    configChanged = configChanged or changed
                    
                    changed, idx = imgui.combo(GetUIText("slot_right", "Right"), skillSet[4], validSkillOptions)
                    skillSet[4] = idx
                    configChanged = configChanged or changed
                    
                    imgui.unindent(24)
                    imgui.tree_pop()
                end
            end

            imgui.tree_pop();
        end

        imgui.tree_pop();
    end
    if Config.Language == "CN"  then imgui.pop_font() end
    if Config.Language == "t_CN"  then imgui.pop_font() end
    if configChanged then json.dump_file("true-warfarer.json", Config) end
end)

re.on_config_save(function() json.dump_file("true-warfarer.json", Config) end)

local isChangingWeapon = false

local function pre_function_consumeStamina(args)
    if (isChangingWeapon == true) then return sdk.PreHookResult.SKIP_ORIGINAL end
end

local function pre_function(args)
    isChangingWeapon = true
end

local function post_function()
    local playerMgr = GetPlayerManager();
    if not playerMgr then return end

    local player = playerMgr:call("get_ManualPlayer()");
    if not player then return end

    local weaponHolder = player:call("get_WeaponAndItemHolder()")
    local weaponSlot = weaponHolder:get_RightWeapon()
    local weapon = weaponSlot:get_Weapon()
    local weaponJobEnum = weapon:get_JobProp()
    local skillSet = GetSkillSetByJobId(weaponJobEnum)
    
    SetCurrentJobSkills(skillSet)
    isChangingWeapon = false
end

sdk.hook(sdk.find_type_definition("app.Job10WeaponManager"):get_method(
             "changeWeapon"), pre_function, post_function, nil)

if Config.RearmStaminaCostRemoved == true then
    sdk.hook(sdk.find_type_definition("app.Job10ActionController"):get_method(
                 "consumeStaminaAndStartReduceStaminaRecover()"),
             pre_function_consumeStamina, nil, nil)
end
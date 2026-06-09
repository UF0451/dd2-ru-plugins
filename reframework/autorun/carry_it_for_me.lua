--========================================================--
-- Carry It For Me (Локализованная и исправленная версия)
--========================================================--

local re = re
local sdk = sdk
local imgui = imgui
local log = log
local json = json

log.info("[Carry It For Me] Загружен");

local Config = json.load_file('carry_it_for_me.json') or {}
if Config.Enabled == nil then Config.Enabled = true end

if Config.ItemCategory == nil then
    Config.ItemCategory = { ["0"] = true, ["1"] = true, ["2"] = true, ["3"] = true }
end

if Config.ItemSubCategory == nil then
    Config.ItemSubCategory = {
        ["0"] = true, ["1"] = true, ["2"] = true, ["3"] = false, ["4"] = false,
        ["5"] = true, ["6"] = false, ["7"] = false, ["8"] = false, ["9"] = true, ["10"] = true,
    }
end

if Config.ItemEvent == nil then Config.ItemEvent = 2 | 4 | 8 | 16 end

local PlayerManager = sdk.get_managed_singleton("app.CharacterManager")
local function GetPlayerManager()
    if PlayerManager == nil then PlayerManager = sdk.get_managed_singleton("app.CharacterManager") end
    return PlayerManager
end

local PawnManager = sdk.get_managed_singleton("app.PawnManager")
local function GetPawnManager()
    if PawnManager == nil then PawnManager = sdk.get_managed_singleton("app.PawnManager") end
    return PawnManager
end

local function GetPlayer()
    local playerMgr = GetPlayerManager();
    if playerMgr then return playerMgr:call("get_ManualPlayer()"); end
end

local ItemManager = nil
local itemID = nil
local itemNum = nil
local itemEventType = nil

local function GetPawn(extraWeight)
    local pawnMgr = GetPawnManager();
    if pawnMgr and ItemManager then
        local list = pawnMgr:call("get_PawnCharacterList()")
        if list then
            local len = list:call("get_Count")
            for i = 0, len - 1, 1 do
                local pawnChar = list:call("get_Item", i)
                if pawnChar then
                    local limit = ItemManager:call("getWeightLimit(app.Character)", pawnChar)
                    local weight = ItemManager:call("getStorageWeight(app.Character)", pawnChar)
                    local rank = ItemManager:call("getWeightRank(System.Single, System.Single)", weight + extraWeight, limit)
                    if rank <= 2 then return pawnChar end
                end
            end
        end
    end
end

-- ИСПРАВЛЕННАЯ ФУНКЦИЯ: Добавлена проверка на nil (itemParam)
local function PassItemToPawn(ret)
    if Config.Enabled and ItemManager then
        if not (itemEventType & Config.ItemEvent) then return ret end
        local player = GetPlayer()
        if not player then return ret end
        
        local playerID = player:get_CharaID()
        local stroageData = ItemManager:getStorageData(itemID, playerID)
        
        if stroageData and stroageData._ItemData then
            local itemData = stroageData._ItemData
            local itemParam = itemData:get_ItemParam()
            
            if itemParam then
                local isCategoryEnabled = Config.ItemCategory[tostring(itemData._Category)]
                local isSubCategoryEnabled = Config.ItemSubCategory[tostring(itemParam._SubCategory)]
                
                if isCategoryEnabled and isSubCategoryEnabled then
                    local pawn = GetPawn(stroageData._ItemData._Weight * 0.01)
                    if pawn then ItemManager:passItem(stroageData, itemNum, pawn:get_CharaID(), true) end
                end
            end
        end
    end
    return ret
end

sdk.hook(sdk.find_type_definition("app.ItemManager"):get_method("getItem(System.Int32, System.Int32, app.Character, System.Boolean, System.Boolean, System.Boolean, app.ItemManager.GetItemEventType, System.Boolean, System.Boolean)"),
function (args)
    local player = GetPlayer()
    local chara = sdk.to_managed_object(args[5])
    if chara and player and chara:get_CharaID() == player:get_CharaID() then
        ItemManager = sdk.to_managed_object(args[2])
        itemID = sdk.to_int64(args[3])
        itemNum = sdk.to_int64(args[4])
        itemEventType = sdk.to_int64(args[9])
    else
        ItemManager = nil
    end
end, PassItemToPawn)

re.on_draw_ui(function()
    local configChanged = false
    if imgui.tree_node("Авто-передача пешкам (Carry It For Me)") then
        local changed = false
        changed, Config.Enabled = imgui.checkbox("Включить авто-передачу", Config.Enabled)
        configChanged = configChanged or changed

        imgui.text("--- Категории ---")
        changed, Config.ItemCategory["0"] = imgui.checkbox("Использовать", Config.ItemCategory["0"])
        configChanged = configChanged or changed
        changed, Config.ItemCategory["1"] = imgui.checkbox("Материалы", Config.ItemCategory["1"])
        configChanged = configChanged or changed
        changed, Config.ItemCategory["2"] = imgui.checkbox("Другое", Config.ItemCategory["2"])
        configChanged = configChanged or changed
        changed, Config.ItemCategory["3"] = imgui.checkbox("Экипировка", Config.ItemCategory["3"])
        configChanged = configChanged or changed

        imgui.text("--- Подкатегории ---")
        local subs = {"Лечение", "Баффы", "Материалы", "Особые", "Квесты", "Книги", "Стрелы", "Навыки", "Навыки пешки", "Магические книги", "Онлайн"}
        for i = 0, 10 do
            changed, Config.ItemSubCategory[tostring(i)] = imgui.checkbox("Подкатегория: " .. subs[i+1], Config.ItemSubCategory[tostring(i)])
            configChanged = configChanged or changed
        end

        imgui.text("--- События передачи ---")
        local events = { {2, "Сбор ресурсов"}, {4, "Сундуки"}, {8, "Диалог"}, {16, "Трофеи (враги)"} }
        for _, e in ipairs(events) do
            local enabled = (Config.ItemEvent & e[1] ~= 0)
            changed, enabled = imgui.checkbox(e[2], enabled)
            if changed then
                Config.ItemEvent = enabled and (Config.ItemEvent | e[1]) or (Config.ItemEvent ~ e[1])
                configChanged = true
            end
        end
        imgui.tree_pop();
    end
    if configChanged then json.dump_file("carry_it_for_me.json", Config) end
end)

re.on_config_save(function() json.dump_file("carry_it_for_me.json", Config) end)
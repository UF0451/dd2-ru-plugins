--========================================================--
-- ItemBelt.lua
-- Автор: Wandd3rer
-- Модификация: Andrey Yuryevich Moskalenko
--
-- Назначение: Меню быстрого доступа к предметам для Dragon's Dogma 2.
--             Полная автоматизация распределения без ограничений базы данных.
--========================================================--

local mod_name = "ItemBelt"
local tiles_dirname = "tiles"

-- Относительные пути для файлов сохранений ленты
local hp_fpath = string.format("%s/%s", mod_name, "hp_row.json")
local sta_fpath = string.format("%s/%s", mod_name, "sta_row.json")
local config_fpath = string.format("%s/%s", mod_name, "config.json")

-- Загрузка модулей
local Managers = require("ItemBelt.Managers")
local Utils = require("ItemBelt.Utils")
local Safe = require("ItemBelt.SafeCall")
local ID_TO_MENU_DATA = require("ItemBelt.ItemMenuData")

--========================================================--
-- RE Engine / Системные вызовы
--========================================================--

local gui_manager = Managers:get("app.GuiManager")
local input_manager = Managers:get("app.UserInputManager")
local flow_manager = Managers:get("app.MainFlowManager")
local pause_manager = Managers:get("app.PauseManager")

local pad = sdk.get_native_singleton("via.hid.GamePad")
local pad_type = sdk.find_type_definition("via.hid.GamePad")
local pad_device = sdk.call_native_func(pad, pad_type, "get_Device")

local via_hid_mouse = sdk.get_native_singleton("via.hid.Mouse")
local via_hid_mouse_typedef = sdk.find_type_definition("via.hid.Mouse")
local via_hid_keyboard = sdk.get_native_singleton("via.hid.Keyboard")
local via_hid_keyboard_typedef = sdk.find_type_definition("via.hid.Keyboard")

local function generate_statics(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end
    local fields = t:get_fields()
    local enum = {}
    for _, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)
            enum[name] = raw_value
        end
    end
    return enum
end

local function generate_statics_global(typename)
    local parts = {}
    for part in typename:gmatch("[^%.]+") do table.insert(parts, part) end
    local global = _G
    for _, part in ipairs(parts) do
        if not global[part] then global[part] = {} end
        global = global[part]
    end
    if global ~= _G then
        local static_class = generate_statics(typename)
        for k, v in pairs(static_class) do
            global[k] = v
            global[v] = k
        end
    end
    return global
end

generate_statics_global("via.hid.KeyboardKey")

local get_view = sdk.find_type_definition('via.gui.GUI'):get_method('get_View')
local get_game_object = sdk.find_type_definition('via.gui.GUI'):get_method('get_GameObject')
local get_object_name = sdk.find_type_definition('via.GameObject'):get_method('get_Name')
local get_id = sdk.find_type_definition('app.ItemData'):get_method('get_Id')
local set_color_scale = sdk.find_type_definition('via.gui.Control'):get_method('set_ColorScale')

local vec4 = ValueType.new(sdk.find_type_definition("via.Float4"))
local SHORTCUT_GUI_ID_NAME = 'ui020401'

local LB = 256
local DPAD_UP = 1
local DPAD_DOWN = 2
local DPAD_LEFT = 4
local DPAD_RIGHT = 8
local START = 32768

local IMPLEMENTS_ID = {85, 92, 175, 176, 177, 178, 179, 180, 181, 182, 183}
local LANTERN_OIL_ID = 85
local SMOKE_BEACON_ID = 92
local PLAYER_GROUP = 1

local ID_TO_ITEM_ACTION = {
    [92] = "SummonHarpyDLC", [175] = "MagicBookCastHeal", [176] = "MagicBookCastCure",
    [177] = "MagicBookCastSpellBreak", [178] = "MagicBookCastFire", [179] = "MagicBookCastIce",
    [180] = "MagicBookCastThunder", [181] = "MagicBookCastFireBoon", [182] = "MagicBookCastIceBoon",
    [183] = "MagicBookCastThunderBoon"
}

--========================================================--
-- Конфигурация ввода
--========================================================--

local menu_open = false
local current_row_type = "hp" 
local current_active_trigger = "" 

local kb_mod_key = via.hid.KeyboardKey.Control 
local kb_heal_key = via.hid.KeyboardKey.T       -- Панель 1
local kb_util_key = via.hid.KeyboardKey.G       -- Панель 2
local kb_grim_key = via.hid.KeyboardKey.B       -- Панель 3
local kb_tool_key = via.hid.KeyboardKey.N       -- Панель 4
local kb_low_hp_key = via.hid.KeyboardKey.Y     -- Панель 5
local kb_confirm_key = via.hid.KeyboardKey.F    -- Применение 

-- Настройки клавиш ячеек 1-12 по умолчанию (Num 1 ... Num *)
local kb_slots_keys = {
    via.hid.KeyboardKey.NumPad1, via.hid.KeyboardKey.NumPad2, via.hid.KeyboardKey.NumPad3,
    via.hid.KeyboardKey.NumPad4, via.hid.KeyboardKey.NumPad5, via.hid.KeyboardKey.NumPad6,
    via.hid.KeyboardKey.NumPad7, via.hid.KeyboardKey.NumPad8, via.hid.KeyboardKey.NumPad9,
    via.hid.KeyboardKey.Add,      via.hid.KeyboardKey.Subtract, via.hid.KeyboardKey.Multiply
}

local kb_slots_last_down = {
    false, false, false, false, false, false, false, false, false, false, false, false
}

local kb_last_heal_combo_down = false
local kb_last_util_combo_down = false
local kb_last_grim_combo_down = false
local kb_last_tool_combo_down = false
local kb_last_low_hp_combo_down = false
local kb_last_confirm_down = false

local KEY_OPTIONS = {
    { name = "Нет",    key = nil },
    { name = "Ctrl",  key = via.hid.KeyboardKey.Control },
    { name = "Shift", key = via.hid.KeyboardKey.Shift },
    { name = "Alt",   key = via.hid.KeyboardKey.Menu },
    { name = "Space", key = via.hid.KeyboardKey.Space },
    { name = "Enter", key = via.hid.KeyboardKey.Enter },
    { name = "Escape",key = via.hid.KeyboardKey.Escape },
    { name = "Tab",   key = via.hid.KeyboardKey.Tab },
    { name = "BackSpace", key = via.hid.KeyboardKey.Back },
    { name = "CapsLock",  key = via.hid.KeyboardKey.Capital },
    
    -- Алфавит (A-Z)
    { name = "A",     key = via.hid.KeyboardKey.A },
    { name = "B",     key = via.hid.KeyboardKey.B },
    { name = "C",     key = via.hid.KeyboardKey.C },
    { name = "D",     key = via.hid.KeyboardKey.D },
    { name = "E",     key = via.hid.KeyboardKey.E },
    { name = "F",     key = via.hid.KeyboardKey.F },
    { name = "G",     key = via.hid.KeyboardKey.G },
    { name = "H",     key = via.hid.KeyboardKey.H },
    { name = "I",     key = via.hid.KeyboardKey.I },
    { name = "J",     key = via.hid.KeyboardKey.J },
    { name = "K",     key = via.hid.KeyboardKey.K },
    { name = "L",     key = via.hid.KeyboardKey.L },
    { name = "M",     key = via.hid.KeyboardKey.M },
    { name = "N",     key = via.hid.KeyboardKey.N },
    { name = "O",     key = via.hid.KeyboardKey.O },
    { name = "P",     key = via.hid.KeyboardKey.P },
    { name = "Q",     key = via.hid.KeyboardKey.Q },
    { name = "R",     key = via.hid.KeyboardKey.R },
    { name = "S",     key = via.hid.KeyboardKey.S },
    { name = "T",     key = via.hid.KeyboardKey.T },
    { name = "U",     key = via.hid.KeyboardKey.U },
    { name = "V",     key = via.hid.KeyboardKey.V },
    { name = "W",     key = via.hid.KeyboardKey.W },
    { name = "X",     key = via.hid.KeyboardKey.X },
    { name = "Y",     key = via.hid.KeyboardKey.Y },
    { name = "Z",     key = via.hid.KeyboardKey.Z },
    
    -- Цифровая панель
    { name = "1",     key = via.hid.KeyboardKey.D1 },
    { name = "2",     key = via.hid.KeyboardKey.D2 },
    { name = "3",     key = via.hid.KeyboardKey.D3 },
    { name = "4",     key = via.hid.KeyboardKey.D4 },
    { name = "5",     key = via.hid.KeyboardKey.D5 },
    { name = "6",     key = via.hid.KeyboardKey.D6 },
    { name = "7",     key = via.hid.KeyboardKey.D7 },
    { name = "8",     key = via.hid.KeyboardKey.D8 },
    { name = "9",     key = via.hid.KeyboardKey.D9 },
    { name = "0",     key = via.hid.KeyboardKey.D0 },
    
    -- Нампад (NumPad)
    { name = "Num 1", key = via.hid.KeyboardKey.NumPad1 },
    { name = "Num 2", key = via.hid.KeyboardKey.NumPad2 },
    { name = "Num 3", key = via.hid.KeyboardKey.NumPad3 },
    { name = "Num 4", key = via.hid.KeyboardKey.NumPad4 },
    { name = "Num 5", key = via.hid.KeyboardKey.NumPad5 },
    { name = "Num 6", key = via.hid.KeyboardKey.NumPad6 },
    { name = "Num 7", key = via.hid.KeyboardKey.NumPad7 },
    { name = "Num 8", key = via.hid.KeyboardKey.NumPad8 },
    { name = "Num 9", key = via.hid.KeyboardKey.NumPad9 },
    { name = "Num 0", key = via.hid.KeyboardKey.NumPad0 },
    { name = "Num +", key = via.hid.KeyboardKey.Add },
    { name = "Num -", key = via.hid.KeyboardKey.Subtract },
    { name = "Num *", key = via.hid.KeyboardKey.Multiply },
    { name = "Num /", key = via.hid.KeyboardKey.Divide },
    { name = "Num .", key = via.hid.KeyboardKey.Decimal },
    
    -- Стрелки и Управление
    { name = "Up",    key = via.hid.KeyboardKey.Up },
    { name = "Down",  key = via.hid.KeyboardKey.Down },
    { name = "Left",  key = via.hid.KeyboardKey.Left },
    { name = "Right", key = via.hid.KeyboardKey.Right },
    { name = "Insert",key = via.hid.KeyboardKey.Insert },
    { name = "Delete",key = via.hid.KeyboardKey.Delete },
    { name = "Home",  key = via.hid.KeyboardKey.Home },
    { name = "End",   key = via.hid.KeyboardKey.End },
    { name = "PageUp",key = via.hid.KeyboardKey.Prior },
    { name = "PageDown", key = via.hid.KeyboardKey.Next },
    
    -- Функциональные клавиши (F1-F12)
    { name = "F1",    key = via.hid.KeyboardKey.F1 },
    { name = "F2",    key = via.hid.KeyboardKey.F2 },
    { name = "F3",    key = via.hid.KeyboardKey.F3 },
    { name = "F4",    key = via.hid.KeyboardKey.F4 },
    { name = "F5",    key = via.hid.KeyboardKey.F5 },
    { name = "F6",    key = via.hid.KeyboardKey.F6 },
    { name = "F7",    key = via.hid.KeyboardKey.F7 },
    { name = "F8",    key = via.hid.KeyboardKey.F8 },
    { name = "F9",    key = via.hid.KeyboardKey.F9 },
    { name = "F10",   key = via.hid.KeyboardKey.F10 },
    { name = "F11",   key = via.hid.KeyboardKey.F11 },
    { name = "F12",   key = via.hid.KeyboardKey.F12 },
}

local KEY_NAMES = {}
for _, o in ipairs(KEY_OPTIONS) do table.insert(KEY_NAMES, o.name) end

local function combo_keys(label, current_index, current_key)
    local changed, new_idx = imgui.combo(label, current_index, KEY_NAMES)
    imgui.same_line()
    local key_name = "?"
    for _, opt in ipairs(KEY_OPTIONS) do
        if opt.key == current_key then key_name = opt.name break end
    end
    imgui.text_colored(" [" .. key_name .. "]", 0xFFAACCFF)
    if changed then
        return changed, new_idx
    end
    return false, current_index
end

local function key_index(current)
    for i, opt in ipairs(KEY_OPTIONS) do if opt.key == current then return i end end
    return 1
end

local image_error = false
local AUTOSAVE_FRAMES = 600
local LAST_PRIORITY = 99

-- Конфигурация отображения
local DEFAULT_POS = 0.09 
local DEFAULT_OPA = 0.5
local DEFAULT_IMG_W = 100
local DEFAULT_IMG_H = 100

local max_idx = 12

local img_w = DEFAULT_IMG_W
local img_h = DEFAULT_IMG_H
local y_scale = 0.74
position = DEFAULT_POS
opacity = DEFAULT_OPA
local gap = 0
local r_x = 5
local r_y = 5
local base_thickness = 4
local base_thinness = 2
local selection_color = 0xffc6a969
local outline_color = 0xff423227
local solid_color = 0x110f0e
local font_type = "Verdana"
local font_color = 0xffbbab8c
local number_size_factor = 0.2
local number_font = nil
local text_font = nil
local text_size_factor = 0.16
local pad_x = 5

local min_pos = 0.05
local max_pos = 0.9
local min_opa = 0.0
local max_opa = 1.0
local min_size = 40
local max_size = 150

-- Глобальная безопасная инициализация массивов
local hp_row_item_ids = {} local sta_row_item_ids = {} local gr_row_item_ids = {} local tl_row_item_ids = {}
local hp_row_item_counts = {} local sta_row_item_counts = {} local gr_row_item_counts = {} local tl_row_item_counts = {}
local low_hp_row_item_ids, low_hp_row_item_counts = {}, {}

for i=1, max_idx do
    hp_row_item_ids[i] = -1 hp_row_item_counts[i] = 0
    sta_row_item_ids[i] = -1 sta_row_item_counts[i] = 0
    gr_row_item_ids[i] = -1 gr_row_item_counts[i] = 0
    tl_row_item_ids[i] = -1 tl_row_item_counts[i] = 0
	low_hp_row_item_ids[i] = -1 low_hp_row_item_counts[i] = 0
end

--========================================================--
-- Логика инвентаря и автоматического поиска REEngine
--========================================================--

local function get_keyboard_device()
    if not via_hid_keyboard or not via_hid_keyboard_typedef then return nil end
    return sdk.call_native_func(via_hid_keyboard, via_hid_keyboard_typedef, "get_Device")
end

local function is_confirm_pressed()
    local kb_device = get_keyboard_device()
    if not kb_device then return false end
    local ok, trig = pcall(function() return kb_device:call("isTrigger", kb_confirm_key) end)
    if ok and type(trig) == "boolean" then return trig end
    
    local down = kb_device:call("isDown", kb_confirm_key)
    local pressed = (down and not kb_last_confirm_down) or false
    kb_last_confirm_down = down
    return pressed
end

local function is_key_down(kb_device, key)
    if not kb_device or not key then return false end
    return kb_device:call("isDown", key)
end

local function combo_pressed(which)
    local kb_device = get_keyboard_device()
    if not kb_device then return false end
    local mod_ok = true
    if kb_mod_key ~= nil then mod_ok = is_key_down(kb_device, kb_mod_key) end

    if which == "hp" then
        local down = mod_ok and is_key_down(kb_device, kb_heal_key)
        local pressed = down and not kb_last_heal_combo_down
        kb_last_heal_combo_down = down
        return pressed
    elseif which == "sta" then
        local down = mod_ok and is_key_down(kb_device, kb_util_key)
        local pressed = down and not kb_last_util_combo_down
        kb_last_util_combo_down = down
        return pressed
    elseif which == "grim" then
        local down = mod_ok and is_key_down(kb_device, kb_grim_key)
        local pressed = down and not kb_last_grim_combo_down
        kb_last_grim_combo_down = down
        return pressed
    elseif which == "tool" then
        local down = mod_ok and is_key_down(kb_device, kb_tool_key)
        local pressed = down and not kb_last_tool_combo_down
        kb_last_tool_combo_down = down
        return pressed
    elseif which == "low_hp" then
        local down = mod_ok and is_key_down(kb_device, kb_low_hp_key)
        local pressed = down and not kb_last_low_hp_combo_down
        kb_last_low_hp_combo_down = down
        return pressed
    end
    return false
end

local function get_mouse_wheel_delta()
    if not via_hid_mouse or not via_hid_mouse_typedef then return 0 end
    local mouse_device = sdk.call_native_func(via_hid_mouse, via_hid_mouse_typedef, "get_Device")
    if not mouse_device then return 0 end
    local ok, v = pcall(function() return mouse_device:get_WheelDelta() end)
    if ok and type(v) == "number" then return v end
    return 0
end

local function refresh_managers()
    gui_manager = Managers:get("app.GuiManager")
    input_manager = Managers:get("app.UserInputManager")
    flow_manager = Managers:get("app.MainFlowManager")
    pause_manager = Managers:get("app.PauseManager")
end

--========================================================--
-- СБОР ПРЕДМЕТОВ ИЗ ВСЕХ СЛОВАРЕЙ ИНВЕНТАРЯ
--========================================================--

local function get_all_usable_counts()
    local id_to_usable_counts = {}
    local item_manager = Managers:item()
    local player = Managers:player()
    
    -- Если менеджер предметов или игрок не найдены, возвращаем пустую таблицу
    if not item_manager or not player then return {} end
    
    local player_id = player:get_CharaID()
    local get_num_items = item_manager:get_type_definition():get_method("getHaveNum(System.Int32, app.CharacterID)")

    -- Список словарей, содержащих предметы
    local dicts = {
        item_manager._ItemDataDict,
        item_manager._ImportantItemDataDict or item_manager:get_field("_ImportantItemDataDict"),
        item_manager._QuestItemDataDict or item_manager:get_field("_QuestItemDataDict")
    }

    -- Итерация по каждому словарю для сбора всех доступных предметов
    for _, dict in ipairs(dicts) do
        if dict then
            local iterator = dict:GetEnumerator()
            if iterator then
                while iterator:MoveNext() do
                    local current = iterator:get_Current()
                    if current then
                        local item_data = current:get_Value()
                        if item_data then
                            local item_id = item_data._Id
                            -- Если ID еще не в списке, проверяем количество
                            if not id_to_usable_counts[item_id] then
                                local num_items = get_num_items:call(item_manager, item_id, player_id)
                                if num_items and num_items > 0 then
                                    id_to_usable_counts[item_id] = num_items
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return id_to_usable_counts
end

local function build_pure_row(id_to_inv_item_counts, current_max)
    local ids = {} local counts = {}
    local idx_val = 1
    for id, count in pairs(id_to_inv_item_counts) do
        ids[idx_val] = id
        counts[idx_val] = count
        idx_val = idx_val + 1
        if idx_val > current_max then break end
    end
    while idx_val <= current_max do
        ids[idx_val] = -1 counts[idx_val] = 0
        idx_val = idx_val + 1
    end
    return ids, counts
end


-- local function classify_item(name, id)
    -- local n = string.lower(name)
    
    -- -- 1. Сначала отсекаем квестовый мусор
    -- if string.find(n, "гнилое") or string.find(n, "ордер") or string.find(n, "шкура") or 
       -- string.find(n, "изящная") or string.find(n, "капюшон") or string.find(n, "стрел") then
        -- return "junk"
    -- end
    
    -- -- 2. КНИГИ (Панель 3)
    -- if string.find(n, "источник") or string.find(n, "дух") or string.find(n, "спокойствие") or 
       -- string.find(n, "пламя") or string.find(n, "тропа") or string.find(n, "грозы") then
       -- return "grim" 
    -- end

    -- -- 3. ИНСТРУМЕНТЫ (Панель 4)
    -- if id == 85 or id == 92 or id == 58 or id == 99 or id == 205 or string.find(n, "приманка") or string.find(n, "кам") then
    -- return "tool" 
	-- end

    -- -- 4. БАФФЫ (Панель 2)
    -- if string.find(n, "варево") or string.find(n, "средство") or string.find(n, "порошок") or 
       -- string.find(n, "сироп") or string.find(n, "мазь") or string.find(n, "отвар") then
       -- return "sta"
    -- end
    
    -- -- 5. LOW_HP (Панель 5) - ПРОВЕРЬ, ЧТО ТВОИ ПРЕДМЕТЫ ТУТ!
    -- -- Добавь сюда ключевые слова для своих расходников
    -- if string.find(n, "картофел") or string.find(n, "сухофрукт") or id == 49 or id == 50 then
       -- return "low_hp"
    -- end
    
    -- -- 6. HP (Панель 1)
    -- if string.find(n, "пилюл") or string.find(n, "снадобье") or string.find(n, "яблоко") or 
       -- string.find(n, "эликсир") or string.find(n, "виноград") then
       -- return "hp"
    -- end

    -- return "junk"
-- end

--========================================================--
-- СОРТИРОВКА (ВСЕ ПРЕДМЕТЫ)
--========================================================--

local function update_all_belts()
    local raw_counts = get_all_usable_counts()
    local item_manager = Managers:item()
    if not item_manager then return end

    local hp, sta, grim, tool, low_hp = {}, {}, {}, {}, {}
    
    for id, count in pairs(raw_counts) do
        -- ЕСЛИ ХОЧЕШЬ ВРЕМЕННО СКРЫТЬ ПРЕДМЕТЫ:
        -- Просто пропусти их на самом раннем этапе
        if id == 79 or id == 80 or id == 81 then 
            goto continue 
        end

        local menu_data = ID_TO_MENU_DATA[id]
        
        local row = nil
        if menu_data then
            row = menu_data["row_type"]
        end

        if row == "hp" then hp[id] = count
        elseif row == "low_hp" then low_hp[id] = count
        elseif row == "sta" then sta[id] = count
        elseif row == "grim" then grim[id] = count
        elseif row == "tool" then tool[id] = count
        end
        
        ::continue:: -- Метка для пропуска
    end
    
    hp_row_item_ids, hp_row_item_counts = build_pure_row(hp, 12)
    low_hp_row_item_ids, low_hp_row_item_counts = build_pure_row(low_hp, 12)
    sta_row_item_ids, sta_row_item_counts = build_pure_row(sta, 12)
    gr_row_item_ids, gr_row_item_counts = build_pure_row(grim, 12)
    tl_row_item_ids, tl_row_item_counts = build_pure_row(tool, 12)
end

--==================================================================================

local function use_lantern_oil(id)
    local max_oil = 100.0
    local item_manager = Managers:item()
    local player = Managers:player()
    if not item_manager or not player then return false end
    
    local player_id = player:get_CharaID()
    if item_manager:call("isEquipLantern", player, 0) then
        local sto_id = item_manager:call("getEquipLanternStorageId", player_id)
        local current_oil = item_manager:call("getLanternOil", player)
        if current_oil < max_oil then
            item_manager:call("addLanternOil", sto_id, max_oil - current_oil)
            item_manager:call("deleteItem", id, 1, player)
            return true
        end
    end
    return false
end

local function open_inventory_to_item(item_id)
    -- Функция пустая, чтобы не вызывать никаких методов GUI
end

local function consume_item(item_id)
    item_id = item_id or -1
    if item_id == -1 then return false end
    
    local item_manager = Managers:item()
    local player = Managers:player()
    if not item_manager or not player then return false end

    -- 1. Спец. действия (Книги, Маячки - работают отлично)
    local item_action = ID_TO_ITEM_ACTION[item_id]
    if item_action then
        if not player:get_IsGround() then return false end
        local selector = player:get_HumanActionSelector()
        if player:get_IsDrawedWeapon() then selector:call("requestSheatheWeapon", true) end
        selector:call("requestAction", item_action, 0)
        menu_open = false
        return true
    end

    -- 2. "Упрямые" предметы (Камни, Кристаллы)
    if item_id == 79 or item_id == 80 or item_id == 81 then
        -- Просто закрываем меню. Никаких попыток вызывать инвентарь или ввод.
        menu_open = false
        current_active_trigger = ""
        idx = 0
        return true
    end

    -- 3. Обычные предметы (работают штатно)
    if item_id ~= LANTERN_OIL_ID then
        item_manager:call("useItem", item_id, player, player)
        menu_open = false
        return true
    else
        local res = use_lantern_oil(item_id)
        if res then
            menu_open = false
            current_active_trigger = ""
            idx = 0
        end
        return res
    end
end

local function get_gui_element_name(element)
    if element == nil or not element:get_Valid() then return nil end
    local gobj = get_game_object:call(element)
    return gobj and get_object_name:call(gobj) or nil
end

local function hide_gui(element)
    vec4.x = 1.0 vec4.y = 1.0 vec4.z = 1.0 vec4.w = 0.0
    local view = get_view:call(element)
    if view then set_color_scale:call(view, vec4) end
end

local function is_shortcut_disabled()
    local gui_list = gui_manager:get_field('_GUIList')
    if gui_list == nil then return false end
    for i = 0, gui_list:get_Count() - 1 do
        local gui = gui_list:get_Item(i)
        if gui:get_type_definition():get_name() == SHORTCUT_GUI_ID_NAME then
            return sdk.find_type_definition('app.ui020401'):get_method('isItemDisable'):call(gui)
        end
    end
    return false
end

local function load_item_image_paths(item_ids)
    local paths = {}
    local mod_dpath = string.format("%s/%s", mod_name, tiles_dirname)
    
    for _, id in ipairs(item_ids) do
        local auto_path = string.format("%s/%s.png", mod_dpath, tostring(id))
        if ID_TO_MENU_DATA[id] then
            paths[id] = string.format("%s/%s/%s.png", mod_name, tiles_dirname, ID_TO_MENU_DATA[id]["tile_id"])
        else
            paths[id] = auto_path
        end
    end
    return paths
end

local function update_fonts()
    number_font = d2d.Font.new(font_type, img_w * number_size_factor)
    text_font = d2d.Font.new(font_type, img_w * text_size_factor)
end

local function reset_config()
    position = DEFAULT_POS opacity = DEFAULT_OPA img_w = DEFAULT_IMG_W img_h = DEFAULT_IMG_H
    update_fonts()
end

local function save_config()
    local config = {}
    config["pos"] = position config["opa"] = opacity config["img_size"] = img_w
    config["kb_mod"] = tostring(kb_mod_key) config["kb_heal"] = tostring(kb_heal_key) config["kb_util"] = tostring(kb_util_key)
    config["kb_grim"] = tostring(kb_grim_key) config["kb_tool"] = tostring(kb_tool_key) config["kb_confirm"] = tostring(kb_confirm_key)
    
    for i = 1, 12 do
        config["kb_slot" .. i] = tostring(kb_slots_keys[i])
    end
    json.dump_file(config_fpath, config)
end

local function load_config()
    local config = json.load_file(config_fpath)
    if config then
        position = config["pos"] opacity = config["opa"] img_w = config["img_size"] img_h = config["img_size"]
        local function load_key(field, default)
            local v = config[field] if not v then return default end
            for _, opt in ipairs(KEY_OPTIONS) do if tostring(opt.key) == v then return opt.key end end
            return default
        end
        kb_mod_key = load_key("kb_mod", via.hid.KeyboardKey.Control)
        kb_heal_key = load_key("kb_heal", via.hid.KeyboardKey.T)
        kb_util_key = load_key("kb_util", via.hid.KeyboardKey.G)
        kb_grim_key = load_key("kb_grim", via.hid.KeyboardKey.Y)
        kb_tool_key = load_key("kb_tool", via.hid.KeyboardKey.U)
        kb_confirm_key = load_key("kb_confirm", via.hid.KeyboardKey.F)
        
        for i = 1, 12 do
            kb_slots_keys[i] = load_key("kb_slot" .. i, kb_slots_keys[i])
        end
   end
end

--========================================================--
-- Функции перехвата (Shortcuts Блокировка)
--========================================================--

sdk.hook(sdk.find_type_definition("app.GuiManager"):get_method("isInputBanned"), function() if menu_open then return sdk.PreHookResult.SKIP_ORIGINAL end return sdk.PreHookResult.CALL_ORIGINAL end, function(retval) return retval end)
sdk.hook(sdk.find_type_definition("app.LanternShortcut"):get_method("useItem"), function() if menu_open then return sdk.PreHookResult.SKIP_ORIGINAL end return sdk.PreHookResult.CALL_ORIGINAL end, function(retval) return retval end)
sdk.hook(sdk.find_type_definition("app.RecoverHPShortcut"):get_method("useItem"), function()
    local kb_device = get_keyboard_device()
    if not kb_device or not kb_mod_key or not is_key_down(kb_device, kb_mod_key) then return sdk.PreHookResult.CALL_ORIGINAL end
    current_row_type = "hp" menu_open = true idx = 1 return sdk.PreHookResult.SKIP_ORIGINAL
end, function(retval) return retval end)
sdk.hook(sdk.find_type_definition("app.RecoverStaminaShortcut"):get_method("useItem"), function()
    local kb_device = get_keyboard_device()
    if not kb_device or not kb_mod_key or not is_key_down(kb_device, kb_mod_key) then return sdk.PreHookResult.CALL_ORIGINAL end
    current_row_type = "sta" menu_open = true idx = 1 return sdk.PreHookResult.SKIP_ORIGINAL
end, function(retval) return retval end)
sdk.hook(sdk.find_type_definition("app.ItemCh255HeadShortcut"):get_method("useItem"), function() if menu_open then return sdk.PreHookResult.SKIP_ORIGINAL end return sdk.PreHookResult.CALL_ORIGINAL end, function(retval) return retval end)

load_config()

--========================================================--
-- Отрисовка интерфейса (Direct2D)
--========================================================--

d2d.register(
    function()
        number_font = d2d.Font.new(font_type, img_w * number_size_factor)
        text_font = d2d.Font.new(font_type, img_w * text_size_factor)
    end,
    function()
        if not menu_open then return end
        local screen_w, screen_h = d2d.surface_size()
        local fill_color = Utils.hex_to_argb(solid_color, opacity)
        local thickness = base_thickness * (img_w / 100)
        local thinness = base_thinness * (img_w / 100)
        local offset_h = screen_h * position
        local offset_y = img_h * y_scale

        if idx == 0 then idx = 1 end

        local current_ids = hp_row_item_ids or {}
        local current_counts = hp_row_item_counts or {}
        local panel_name = "Панель 1: Здоровье и Стамина"
        
        if current_active_trigger == "sta" then 
            current_ids, current_counts = sta_row_item_ids or {}, sta_row_item_counts or {}
            panel_name = "Панель 2: Дебаффы и Баффы"
        elseif current_active_trigger == "grim" then 
            current_ids, current_counts = gr_row_item_ids or {}, gr_row_item_counts or {}
            panel_name = "Панель 3: Магические Книги"
        elseif current_active_trigger == "tool" then 
            current_ids, current_counts = tl_row_item_ids or {}, tl_row_item_counts or {}
            panel_name = "Панель 4: Прочие Расходники"
        elseif current_active_trigger == "low_hp" then 
            current_ids, current_counts = low_hp_row_item_ids or {}, low_hp_row_item_counts or {}
            panel_name = "Панель 5: Расходники"
        end

        local real_item_count = 0
        local valid_indices = {}
        for i = 1, max_idx do
            if current_ids[i] and current_ids[i] ~= -1 then 
                table.insert(valid_indices, i)
                real_item_count = real_item_count + 1
            end
        end

        local debug_info = string.format("%s [Найдено предметов: %d]", panel_name, real_item_count)
        d2d.text(text_font, debug_info, screen_w / 2 - 150, screen_h - img_h - offset_h - 40, 0xFFFFFFFF)

        if real_item_count == 0 then
            local empty_text = "ПАНЕЛЬ ПУСТАЯ (ФИЛЬТР НЕ НАШЕЛ ПРЕДМЕТОВ)"
            d2d.text(text_font, empty_text, screen_w / 2 - 200, screen_h - img_h - offset_h + 35, 0xFF0000FF)
            table.insert(valid_indices, 1)
        end

        local active_count = #valid_indices
        for display_pos, real_i in ipairs(valid_indices) do
            local x = screen_w / 2 - (img_w) * (active_count / 2 - display_pos + 1) + gap * (2 * display_pos - active_count - 1)
            local y = screen_h - img_h - offset_h
            
            d2d.fill_rounded_rect(x, y, img_w, img_h, r_x, r_y, fill_color)
            d2d.rounded_rect(x, y, img_w, img_h, r_x, r_y, thinness, outline_color)
            
            local item_id = current_ids[real_i]
            if item_id and item_id ~= -1 then
                local img_path = load_item_image_paths({item_id})[item_id]
                local loaded_img = nil
                
                if img_path and img_path ~= "" then
                    pcall(function() loaded_img = d2d.Image.new(img_path) end)
                end
                
                if loaded_img then
                    d2d.image(loaded_img, x, y, img_w, img_h)
                else
                    local item_manager = Managers:item()
                    local real_name = nil
                    
                    if item_manager then
                        local important_dict = item_manager._ImportantItemDataDict or item_manager:get_field("_ImportantItemDataDict")
                        local item_data = nil
                        
                        pcall(function() item_data = item_manager._ItemDataDict:get_Item(item_id) end)
                        if not item_data and important_dict then
                            pcall(function() item_data = important_dict:get_Item(item_id) end)
                        end
                        
                        if item_data then 
                            local success, name_res = pcall(function() return item_data:get_Name() end)
                            if success and name_res and type(name_res) == "string" and name_res ~= "" then
                                real_name = name_res
                            end
                        end
                    end
                    
                    if not real_name or real_name == "" then
                        real_name = "ID: " .. tostring(item_id)
                    end
                    
                    local disp = real_name
                    d2d.text(text_font, disp, x + Utils.hcenter_text(text_font, disp, img_w), y + (img_h * 0.35), font_color)
                end
                
                local count_txt = tostring(current_counts[real_i] or 0)
                d2d.text(number_font, count_txt, x + Utils.right_text(number_font, count_txt, img_w, pad_x), y + offset_y, font_color)
            end

            if idx == real_i then
                d2d.rounded_rect(x, y, img_w, img_h, r_x, r_y, thickness, selection_color)
            end
        end
    end
)
--========================================================--
-- Считывание хоткеев и управление фокусом
--========================================================--


re.on_frame(function()
    refresh_managers()
    local wheel_delta = get_mouse_wheel_delta()
    local menu_is_banned = is_shortcut_disabled() or Safe.bool(pause_manager, "isPausedAny") or Safe.bool(input_manager, "isDisable", {PLAYER_GROUP}) or Safe.bool(gui_manager, "isFadeDispAny") or not Safe.bool(flow_manager, "get_IsInGamePhase")

    if not menu_is_banned then
        if combo_pressed("hp") then
            if menu_open and current_active_trigger == "hp" then menu_open = false idx = 0 current_active_trigger = "" 
            else menu_open = true current_row_type = "hp" idx = 1 current_active_trigger = "hp" end
        elseif combo_pressed("sta") then
            if menu_open and current_active_trigger == "sta" then menu_open = false idx = 0 current_active_trigger = ""
            else menu_open = true current_row_type = "sta" idx = 1 current_active_trigger = "sta" end
        elseif combo_pressed("grim") then
            if menu_open and current_active_trigger == "grim" then menu_open = false idx = 0 current_active_trigger = ""
            else menu_open = true current_row_type = "grim" idx = 1 current_active_trigger = "grim" end
        elseif combo_pressed("tool") then
            if menu_open and current_active_trigger == "tool" then menu_open = false idx = 0 current_active_trigger = ""
            else menu_open = true current_row_type = "tool" idx = 1 current_active_trigger = "tool" end
        elseif combo_pressed("low_hp") then
            if menu_open and current_active_trigger == "low_hp" then menu_open = false idx = 0 current_active_trigger = ""
            else menu_open = true current_row_type = "low_hp" idx = 1 current_active_trigger = "low_hp" end
        end
    end

    if menu_open and menu_is_banned then menu_open = false current_active_trigger = "" end

    if menu_open or Safe.bool(gui_manager, "get_IsChangeGuiAfter") then
        update_all_belts()
    end

    local current_ids = hp_row_item_ids
    if current_active_trigger == "low_hp" then current_ids = low_hp_row_item_ids
    elseif current_active_trigger == "sta" then current_ids = sta_row_item_ids
    elseif current_active_trigger == "grim" then current_ids = gr_row_item_ids
    elseif current_active_trigger == "tool" then current_ids = tl_row_item_ids end

    local valid_indices = {}
    for i = 1, max_idx do
        if current_ids[i] and current_ids[i] ~= -1 then table.insert(valid_indices, i) end
    end
    if #valid_indices == 0 then table.insert(valid_indices, 1) end

    local valid_pos = false
    for _, v in ipairs(valid_indices) do
        if v == idx then valid_pos = true break end
    end
    if not valid_pos then idx = valid_indices[1] end

    -- ОПТИМИЗИРОВАННЫЙ ОПРОС НАМПАДА
    if menu_open then
        local kb_device = get_keyboard_device()
        if kb_device then
            for slot_idx = 1, 12 do
                local custom_key = kb_slots_keys[slot_idx]
                if custom_key then
                    local ok, down = pcall(function() return kb_device:call("isDown", custom_key) end)
                    if ok and down and not kb_slots_last_down[slot_idx] then
                        local target_item_id = current_ids[slot_idx] 
                        if target_item_id and target_item_id ~= -1 then
                            consume_item(target_item_id)
                        end
                        
                        idx = 0 
                        menu_open = false 
                        current_active_trigger = ""
                        
                        kb_slots_last_down[slot_idx] = true
                    elseif ok and not down then
                        kb_slots_last_down[slot_idx] = false
                    end
                end
            end
        end
    end

    if menu_open and wheel_delta ~= 0 then
        local current_pos_idx = 1
        for i, v in ipairs(valid_indices) do
            if v == idx then current_pos_idx = i break end
        end
        current_pos_idx = current_pos_idx + (wheel_delta > 0 and -1 or 1)
        if current_pos_idx < 1 then current_pos_idx = 1 end
        if current_pos_idx > #valid_indices then current_pos_idx = #valid_indices end
        idx = valid_indices[current_pos_idx]
    end

    if menu_open then
        local kb = reframework and reframework.input
        if kb then
            local left = kb.is_key_pressed(0x25) or kb.is_key_pressed(0x51) 
            local right = kb.is_key_pressed(0x27) or kb.is_key_pressed(0x45) 
            local current_pos_idx = 1
            for i, v in ipairs(valid_indices) do if v == idx then current_pos_idx = i break end end
            
            if left then
                current_pos_idx = current_pos_idx - 1
                if current_pos_idx < 1 then current_pos_idx = 1 end
                idx = valid_indices[current_pos_idx]
            elseif right then
                current_pos_idx = current_pos_idx + 1
                if current_pos_idx > #valid_indices then current_pos_idx = #valid_indices end
                idx = valid_indices[current_pos_idx]
            end
        end
    end

    if menu_open and is_confirm_pressed() then
        if current_ids[idx] and current_ids[idx] ~= -1 then
            consume_item(current_ids[idx])
        end
        idx = 0 menu_open = false current_active_trigger = ""
    end
end)

--========================================================--
-- REFramework GUI Оверлей настроек
--========================================================--

re.on_draw_ui(function()
    if imgui.tree_node("Панель предметов (Item Belt)") then
        local changed = false
        local scale_changed = false

        _, position = imgui.slider_float("Вертикальное положение", position, min_pos, max_pos)
        _, opacity = imgui.slider_float("Уровень прозрачности", opacity, min_opa, max_opa)
        
        local tmp_w = img_w
        scale_changed, tmp_w = imgui.slider_int("Размер ячеек (px)", tmp_w, min_size, max_size)
        if scale_changed then 
            img_w = tmp_w
            img_h = tmp_w 
            update_fonts() 
        end
        
        if imgui.button("Восстановить настройки по умолчанию") then reset_config() end
        
        imgui.separator()
        imgui.text("Горячие клавиши вызова панелей")

        local mod_i = key_index(kb_mod_key)
        local heal_i = key_index(kb_heal_key)
        local util_i = key_index(kb_util_key)
        local grim_i = key_index(kb_grim_key)
        local tool_i = key_index(kb_tool_key)
        local low_hp_i = key_index(kb_low_hp_key)
        local conf_i = key_index(kb_confirm_key)

        changed, mod_i = combo_keys("Клавиша-модификатор (Зажатие)", mod_i, kb_mod_key)
        if changed then kb_mod_key = KEY_OPTIONS[mod_i].key save_config() end

        changed, heal_i = combo_keys("Панель 1: Здоровье / Эликсиры ОЗ", heal_i, kb_heal_key)
        if changed then kb_heal_key = KEY_OPTIONS[heal_i].key save_config() end

        changed, util_i = combo_keys("Панель 2: Лечение негативных дебаффов", util_i, kb_util_key)
        if changed then kb_util_key = KEY_OPTIONS[util_i].key save_config() end

        changed, grim_i = combo_keys("Панель 3: Магические Гримуары (Все)", grim_i, kb_grim_key)
        if changed then kb_grim_key = KEY_OPTIONS[grim_i].key save_config() end

        changed, tool_i = combo_keys("Панель 4: Полезные гаджеты / Камни", tool_i, kb_tool_key)
        if changed then kb_tool_key = KEY_OPTIONS[tool_i].key save_config() end
        
        changed, low_hp_i = combo_keys("Панель 5: Расходники (low_hp)", low_hp_i, kb_low_hp_key)
        if changed then kb_low_hp_key = KEY_OPTIONS[low_hp_i].key save_config() end

        changed, conf_i = combo_keys("Клавиша применения предмета (Альтернатива)", conf_i, kb_confirm_key)
        if changed then kb_confirm_key = KEY_OPTIONS[conf_i].key save_config() end

        -- Настройка клавиш быстрого использования ячеек (1-12)
        imgui.separator()
        if imgui.tree_node("Настройка клавиш быстрого использования ячеек (1-12)") then
            for slot_num = 1, 12 do
                local cur_slot_key = kb_slots_keys[slot_num]
                local slot_i = key_index(cur_slot_key)
                local slot_changed = false
                
                slot_changed, slot_i = combo_keys("Ячейка " .. slot_num, slot_i, cur_slot_key)
                if slot_changed then
                    kb_slots_keys[slot_num] = KEY_OPTIONS[slot_i].key
                    save_config()
                end
            end
            imgui.tree_pop()
        end

        imgui.tree_pop()
    end
end)

re.on_config_save(function()
    save_config()
end)
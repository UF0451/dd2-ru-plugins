-- DD2 Quest Tracker: внутриигровой интерфейс квестов + маркеры на карте.
local MOD_VERSION = "1.1"

-- Ротация файла лога при достижении LOG_MAX_BYTES
local LOG_PATH = "quest_tracker_log.txt"
local LOG_MAX_BYTES = 200000
local function _rotate_log_if_big()
    local f = io.open(LOG_PATH, "rb")
    if not f then return end
    local sz = f:seek("end") or 0
    f:close()
    if sz > LOG_MAX_BYTES then
        os.remove(LOG_PATH .. ".old")
        os.rename(LOG_PATH, LOG_PATH .. ".old")
    end
end
local function mlog(...)
    local args = {...}
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(args[i]) end
    local line = "[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] " .. table.concat(parts, " ")
    pcall(function()
        _rotate_log_if_big()
        local f = io.open(LOG_PATH, "ab")
        if f then f:write(line, "\n"); f:close() end
    end)
    print(line)
    if log and log.info then pcall(log.info, line) end
end
mlog("[quest_tracker] ===== мод загружен v" .. MOD_VERSION .. " =====")

-- Ручные исправления координат позиций имеют приоритет над всеми путями разрешения.
-- Используется там, где автоопределение NPC/врагов дает сбой (Сфинкс, ловушки) или статичная точка лучше живого NPC.
-- Точные значения с плавающей запятой для строгого соответствия is_bundled_pos.
local MANUAL_POS_OVERRIDES = {
    [10110] = { x = 493.9796600341797,   y = 27.427902221679688, z = -1025.0746459960938 }, -- Тревожное знакомство
    [10130] = { x = 496.31145095825195,  y = 24.031455993652344, z = -1054.4935245513916 }, -- Тень Восставшего
    [10140] = { x = 493.6757583618164,   y = 27.427902221679688, z = -1024.9119186401367 }, -- Феерия обмана
    [10151] = { x = -1453.9278030395508, y = 101.23748588562012,  z = 300.42830657958984 }, -- Смутные тени
    [20040] = { x = 208.3,               y = 141.4,               z = -2168.6 },              -- Гнездовые проблемы
    [20060] = { x = -1454.6352767944336, y = 107.46630477905273,  z = 421.0796432495117 }, -- Между молотом и наковальней
    [20080] = { x = -425.93798446655273, y = 4.689894199371338,  z = -643.8243865966797 }, -- Чешуйчатые захватчики
    [20082] = { x = -416.230167388916,   y = 2.9613876342773438, z = -728.1577644348145 }, -- Беда на мысе
    [20090] = { x = 488.7228469848633,   y = 24.03145408630371,  z = -1063.8864059448242 }, -- Сказ о нищем
    [20110] = { x = 388.38623809814453,  y = 33.34857177734375,   z = -1025.7169268131256 }, -- Призрачная повозка
    [20130] = { x = 591.3,               y = 9.3,                z = -968.2 },              -- Святой из трущоб
    [20200] = { x = -1226.0890998840332, y = 200.0381965637207,  z = -1696.9209213256836 }, -- Игра умов (Сфинкс)
    [20220] = { x = 493.5822525024414,   y = 27.427902221679688, z = -1024.993310213089 }, -- Безымянная деревня
    [20240] = { x = 479.8509979248047,   y = 28.77345848083496,  z = -1020.0119707584381 }, -- Разочарование в призвании
    [20340] = { x = 560.8182220458984,   y = 23.017465591430664,  z = -1027.091487646103 }, -- qid 20340 (название неизвестно)
    [20350] = { x = -1918.546501159668,  y = 234.49042510986328, z = -931.1457595825195 }, -- Охота за жадеитовой сферой
    [20390] = { x = 501.0633010864258,   y = 26.927902221679688,  z = -1032.420509338379 }, -- qid 20390 (название неизвестно)
    [20420] = { x = -1278.8292846679688, y = 115.24274444580078,  z = 418.3339424133301 }, -- qid 20420 (название неизвестно)
    [20440] = { x = -1235.3050537109375, y = 116.8261489868164,   z = 437.31350326538086 }, -- qid 20440 (название неизвестно)
    [20450] = { x = -508.02643847465515, y = 125.331298828125,     z = -2200.9063472747803 }, -- qid 20450 (название неизвестно)
    [20460] = { x = -278.0672073364258,  y = 18.997406005859375,  z = 1057.7830772399902 }, -- qid 20460 (название неизвестно)
    [20470] = { x = 296.1302909851074,   y = 85.62184143066406,   z = 1340.941234588623 }, -- qid 20470 (название неизвестно)
    [30010] = { x = 489.1841506958008,   y = 21.699199676513672, z = -1080.0725326538086 }, -- Расписная шкатулка
    [30040] = { x = 493.96543884277344,  y = 27.427902221679688, z = -1024.906347155571 }, -- Украденный трон
    [30070] = { x = 480.5570602416992,   y = 24.031455993652344, z = -1072.866901397705 }, -- Испытание стрелка
    [30090] = { x = -578.5190048217773,  y = 127.0729392170906,   z = -2219.5535011291504 }, -- Из леса в кузницу
    [30110] = { x = 99.80061149597168,   y = 157.997220993042,   z = -2122.4835624694824 }, -- Дом там, где сердце
    [30200] = { x = -269.24205780029297, y = 28.95209503173828,   z = 1114.0038223266602 }, -- Фитиль во бурю
    [30210] = { x = -1952.9680557250977, y = 258.339635848999,    z = -779.3873443603516 }, -- Милосердие среди воров
    [30220] = { x = -1020.84508228302,   y = 85.06685638427734,   z = 274.2882251739502 }, -- На праведном пути
    [30240] = { x = 324.0470886230469,   y = 530.5744247436523,   z = 1668.7981867790222 }, -- Столкновение и развязка
}

local ELIMINATED_OVERRIDES = {}

-- Верифицированные пользователями CharaID квестодателей для замены базовых значений.
local MANUAL_GIVER_OVERRIDES = {
    [10090] = 189868107,    -- Зачистка от монстров
    [10100] = 189868107,    -- Заговор Дисы
    [10120] = 189868107,    -- Заключенный законник
    [20010] = 3287815186,   -- Опасное лекарство
    [20020] = 41790483,     -- Испытания новобранца
    [20030] = 527644994,    -- Заботы снабженца
    [20050] = 2984506176,   -- Братья храбрые и робкие
    [20070] = 2696396312,   -- Пока смерть не разлучит нас
    [20100] = 2954976292,   -- Упокоение с миром
    [20120] = 920227254,    -- У истоков истории
    [20140] = 1488552131,   -- Дар дарения
    [20150] = 3743885470,   -- Дом под сияющим солнцем
    [20190] = 3689427708,   -- Благородный обмен
    [20230] = 3202987914,   -- Уютное гнездышко
    [20250] = 1191862039,   -- Волчья добыча
    [20270] = 3252066890,   -- Хмельной мудрец
    [20280] = 2151757684,   -- Ядовитое предложение
    [20290] = 1545619405,   -- Недальновидные амбиции
    [20310] = 2884679268,   -- Творческий кризис скульптора
    [20330] = 4137867127,   -- Скрытые молитвы
    [20480] = 542068695,    -- Посыльный на повозке
    [30030] = 4006438697,   -- Последний урок Берена
    [30041] = 1210835050,   -- Переписка в маске
    [30042] = 4267448965,   -- Судейская ценность
    [30050] = 1461307325,   -- У каждой розы свои шипы
    [30060] = 3560980369,   -- Дар лука
    [30080] = 1007143618,   -- Больное Древо сердца
    [30100] = 240278635,    -- Возвращение бедствия
    [30120] = 1424070675,   -- Потускневшая сталь, холодная кузница
    [30140] = 2145444378,   -- Добро пожаловать в Баттал
    [30150] = 678396953,    -- Очарование магии
    [30160] = 1603137626,   -- Оценка чародея
    [30170] = 1468499554,   -- Верни бодрость моим шагам
    [30180] = 1210835050,   -- Завеса из тонких туч
    [30230] = 43671194,     -- Стычка на большой дороге
}

-- Снимок базовых значений по умолчанию, чтобы файл настроек сохранял только изменения пользователя.
local BUNDLED_GIVER_OVERRIDES = {}
for k, v in pairs(MANUAL_GIVER_OVERRIDES) do BUNDLED_GIVER_OVERRIDES[k] = v end
local BUNDLED_POS_OVERRIDES = {}
for k, v in pairs(MANUAL_POS_OVERRIDES) do
    BUNDLED_POS_OVERRIDES[k] = { x = v.x, y = v.y, z = v.z }
end

local function is_bundled_giver(qid, cid)
    return BUNDLED_GIVER_OVERRIDES[qid] == cid
end
local function is_bundled_pos(qid, p)
    local b = BUNDLED_POS_OVERRIDES[qid]
    if b == nil or p == nil then return false end
    return b.x == p.x and b.y == p.y and b.z == p.z
end

local PREFS_PATH = "quest_tracker_prefs.json"
local DEBUG_LOG_PATH = "quest_tracker_debug.txt"

-- Переключается в меню Параметры > чекбокс "Подробный лог отладки".
-- По умолчанию выключен — запись в файл происходит только при включении пользователем.
local DEBUG_LOGGING = false

-- Ротация отладочного лога при достижении DEBUG_LOG_MAX_BYTES
local DEBUG_LOG_MAX_BYTES = 200000
local function _rotate_debug_log_if_big()
    local f = io.open(DEBUG_LOG_PATH, "rb")
    if not f then return end
    local sz = f:seek("end") or 0
    f:close()
    if sz > DEBUG_LOG_MAX_BYTES then
        os.remove(DEBUG_LOG_PATH .. ".old")
        os.rename(DEBUG_LOG_PATH, DEBUG_LOG_PATH .. ".old")
    end
end
local function dlog(msg)
    if not DEBUG_LOGGING then return end
    _rotate_debug_log_if_big()
    local f = io.open(DEBUG_LOG_PATH, "a")
    if f then
        f:write("[" .. os.date("%H:%M:%S") .. "] " .. tostring(msg) .. "\n")
        f:close()
    end
end

local function _log_session_start()
    if not DEBUG_LOGGING then return end
    local f = io.open(DEBUG_LOG_PATH, "a")
    if f then
        f:write("\n=== Запуск сессии трекера квестов  " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===\n")
        f:close()
    end
end

local MAP_API
local init_map_api
local clear_injected_markers
local get_quest_resource
local pin_quest
local unpin_quest
local unpin_candidate
local restore_candidate
local restore_all_candidates
local get_player_universal_pos
local get_quest_cast_charaids
local force_marker_refresh

local mod = {
    show_window      = true,
    quests           = {},
    name_cache       = {},
    name_en_cache    = {},
    summary_cache    = {},
    last_refresh     = 0,
    refresh_interval = 2.0,
    filter_text      = "",
    tab              = 1,
    sort_mode        = 1,
    highlight_recent = true,
    label_pins       = true,
    debug_logging    = false,
    state_counts     = {0,0,0,0},
    progressing_ids  = {},
    acceptable_ids   = {},
    completed_ids    = {},
    recency_order    = {},
    newest_completed = nil,
}

-- ИСПРАВЛЕНО: Локализация вкладок и вариантов сортировки
local TAB_NAMES  = { "Доступные", "Текущие", "Завершенные", "Все" }
local SORT_NAMES = { "Недавние", "А-Я", "По ID" }

local PREF_KEYS = { "show_window", "sort_mode", "highlight_recent", "tab", "label_pins", "debug_logging" }

local function load_prefs()
    local ok, data = pcall(function() return json.load_file(PREFS_PATH) end)
    if ok and type(data) == "table" then
        for _, k in ipairs(PREF_KEYS) do
            if data[k] ~= nil then mod[k] = data[k] end
        end
        if type(data.giver_overrides) == "table" then
            for k, v in pairs(data.giver_overrides) do
                local kn = tonumber(k)
                if kn and type(v) == "number" and v > 0 then MANUAL_GIVER_OVERRIDES[kn] = v end
            end
        end
        if type(data.manual_pos_overrides) == "table" then
            for k, v in pairs(data.manual_pos_overrides) do
                local kn = tonumber(k)
                if kn and type(v) == "table" and v.x and v.y and v.z then
                    MANUAL_POS_OVERRIDES[kn] = { x = v.x, y = v.y, z = v.z }
                end
            end
        end
        if type(data.eliminated_overrides) == "table" then
            for k, arr in pairs(data.eliminated_overrides) do
                local kn = tonumber(k)
                if kn and type(arr) == "table" then
                    local kept = {}
                    for _, p in ipairs(arr) do
                        if type(p) == "table" and type(p.cid) == "number" and p.cid > 0 then
                            kept[#kept+1] = { cid = p.cid, x = p.x, y = p.y, z = p.z }
                        end
                    end
                    if #kept > 0 then ELIMINATED_OVERRIDES[kn] = kept end
                end
            end
        end
    end
end

local function save_prefs()
    local out = {}
    for _, k in ipairs(PREF_KEYS) do out[k] = mod[k] end
    local overrides_str = {}
    for k, v in pairs(MANUAL_GIVER_OVERRIDES) do
        if not is_bundled_giver(k, v) then overrides_str[tostring(k)] = v end
    end
    out.giver_overrides = overrides_str
    local manual_str = {}
    for k, v in pairs(MANUAL_POS_OVERRIDES) do
        if not is_bundled_pos(k, v) then manual_str[tostring(k)] = v end
    end
    out.manual_pos_overrides = manual_str
    local elim_str = {}
    for k, v in pairs(ELIMINATED_OVERRIDES) do elim_str[tostring(k)] = v end
    out.eliminated_overrides = elim_str
    pcall(function() json.dump_file(PREFS_PATH, out) end)
    mod._prefs_dirty = false
end

local function mark_prefs_dirty()
    mod._prefs_dirty = true
end

local function flush_prefs_if_dirty()
    if mod._prefs_dirty then save_prefs() end
end

load_prefs()
DEBUG_LOGGING = mod.debug_logging == true
_log_session_start()

local function td(n) return sdk.find_type_definition(n) end

local function safe_get_field(obj, name)
    if obj == nil then return nil end
    local ok, res = pcall(function() return obj:get_field(name) end)
    if ok then return res end
    return nil
end

local function safe_call(obj, name, ...)
    if obj == nil then return nil end
    local args = {...}
    local ok, res = pcall(function() return obj:call(name, table.unpack(args)) end)
    if ok then return res end
    return nil
end

local function call_method(m, this, ...)
    if m == nil then return nil end
    local args = {...}
    local ok, res = pcall(function() return m:call(this, table.unpack(args)) end)
    if ok then return res end
    return nil
end

local function iter_list(list, cb)
    if list == nil then return end
    local c = safe_call(list, "get_Count") or safe_call(list, "getCount")
    if c ~= nil then
        for i = 0, c - 1 do
            local el = safe_call(list, "get_Item", i) or safe_call(list, "getItem", i)
            if el ~= nil then cb(el, i) end
        end
        return
    end
    local items = safe_get_field(list, "_items")
    if items then
        local ok, sz = pcall(function() return items:get_size() end)
        if ok and sz then
            for i = 0, sz - 1 do
                local okEl, el = pcall(function() return items:get_element(i) end)
                if okEl and el then cb(el, i) end
            end
        end
    end
end

local function iter_array(arr, cb)
    if arr == nil then return end
    local ok, sz = pcall(function() return arr:get_size() end)
    if ok and sz then
        for i = 0, sz - 1 do
            local okEl, el = pcall(function() return arr:get_element(i) end)
            if okEl and el ~= nil then cb(el, i) end
        end
    end
end

local function to_int(x)
    if type(x) == "number" then return x end
    if type(x) == "userdata" then
        local ok, v = pcall(function() return x:get_field("value__") end)
        if ok and type(v) == "number" then return v end
    end
    return nil
end

local ALL_IDS = nil
local function dump_quest_id_enum()
    local t = td("app.QuestDefine.ID")
    if t == nil then return {} end
    local out = {}
    for _, f in ipairs(t:get_fields()) do
        if f:is_static() and f:is_literal() then
            local ok, v = pcall(function() return f:get_data(nil) end)
            if ok and type(v) == "number" then out[v] = f:get_name() end
        end
    end
    return out
end

local LANG_EN = nil
local MSG_GET_LANG = nil

local function init_english_lookup()
    if LANG_EN ~= nil then return end
    local lt = td("via.Language")
    if lt then
        for _, f in ipairs(lt:get_fields()) do
            if f:is_static() and f:is_literal() then
                local nm = f:get_name()
                if nm == "English" or nm == "ENGLISH" then
                    local ok, v = pcall(function() return f:get_data(nil) end)
                    if ok and type(v) == "number" then LANG_EN = v; break end
                end
            end
        end
    end
    if LANG_EN == nil then LANG_EN = 1 end  -- Дефолтное значение для RE Engine
    local mt = td("via.gui.message")
    if mt then MSG_GET_LANG = mt:get_method("get(System.Guid, via.Language)") end
end

local function resolve_meta(qlm, qid)
    if mod.name_cache[qid] and mod.summary_cache[qid] ~= nil
       and mod.name_en_cache[qid] ~= nil then return end
    local vi = safe_call(qlm, "getQuestLog", qid)
    if vi == nil then return end
    local name = safe_get_field(vi, "QuestName")
    if type(name) == "string" and name ~= "" then
        mod.name_cache[qid] = name
    end
    local summary = safe_get_field(vi, "QuestSummary")
    if type(summary) == "string" then
        mod.summary_cache[qid] = summary
    end
    if MSG_GET_LANG == nil then init_english_lookup() end
    if MSG_GET_LANG ~= nil and mod.name_en_cache[qid] == nil then
        local guid = safe_get_field(vi, "QuestNameId")
        if guid ~= nil then
            local ok, s = pcall(function() return MSG_GET_LANG:call(nil, guid, LANG_EN) end)
            if ok and type(s) == "string" and s ~= "" then
                mod.name_en_cache[qid] = s
            end
        end
    end
end

-- qid -> список предков (ID родительских квестов) из QuestTreeData._PrevTransitions. ПОРЯДОК СЮЖЕТА.
-- ПРИМЕЧАНИЕ: Это исключительно информационный вывод, а не строгое условие доступа — реальные триггеры
-- заскриптованы в сценах мира и не могут быть извлечены статически.
local STORY_CHAIN_MAP = nil
local function build_story_chain_map()
    if STORY_CHAIN_MAP ~= nil then return STORY_CHAIN_MAP end
    STORY_CHAIN_MAP = {}
    local qm = sdk.get_managed_singleton("app.QuestManager")
    if not qm then return STORY_CHAIN_MAP end
    local qcd = safe_get_field(qm, "QuestCatalogDict")
    local vals = qcd and safe_call(qcd, "getValues") or nil
    if vals == nil then return STORY_CHAIN_MAP end
    local sz = 0; pcall(function() sz = vals:get_size() end)
    for i = 0, sz - 1 do
        local okC, cd = pcall(function() return vals:get_element(i) end)
        if okC and cd then
            local tree_list = safe_call(cd, "get_TreeNodeList")
            if tree_list then
                local tsz = 0; pcall(function() tsz = tree_list:call("get_Count") end)
                for j = 0, tsz - 1 do
                    local okN, node = pcall(function() return tree_list:call("get_Item", j) end)
                    if okN and node then
                        local qid = to_int(safe_get_field(node, "_QuestID"))
                        if qid then
                            local ancestors = {}
                            local trans_arr = safe_get_field(node, "_PrevTransitions")
                            local trans_sz = 0; if trans_arr then pcall(function() trans_sz = trans_arr:get_size() end) end
                            for t = 0, trans_sz - 1 do
                                local okT, td_el = pcall(function() return trans_arr:get_element(t) end)
                                if okT and td_el then
                                    local elem_arr = safe_get_field(td_el, "_ElementArray")
                                    local esz = 0; if elem_arr then pcall(function() esz = elem_arr:get_size() end) end
                                    for e = 0, esz - 1 do
                                        local okE, elem = pcall(function() return elem_arr:get_element(e) end)
                                        if okE and elem then
                                            local param_arr = safe_get_field(elem, "_ParamArray")
                                            local psz = 0; if param_arr then pcall(function() psz = param_arr:get_size() end) end
                                            for p = 0, psz - 1 do
                                                local okP, param = pcall(function() return param_arr:get_element(p) end)
                                                if okP and param then
                                                    local preq_qid = to_int(safe_get_field(param, "_QuestID"))
                                                    if preq_qid and preq_qid >= 0 then
                                                        ancestors[#ancestors+1] = preq_qid
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            if #ancestors > 0 then STORY_CHAIN_MAP[qid] = ancestors end
                        end
                    end
                end
            end
        end
    end
    return STORY_CHAIN_MAP
end

local function clear_story_chain_cache()
    STORY_CHAIN_MAP = nil
end

local QD_OK, QD = pcall(require, "quest_data_loader")
if not QD_OK then
    QD = nil
    print("[quest_tracker] модуль quest_data_loader недоступен — запуск без статических данных квестов")
end

local function qd_givers(qid)
    if not QD or not QD.get_givers then return nil end
    local ok, list = pcall(QD.get_givers, qid)
    if ok and type(list) == "table" and #list > 0 then return list end
    return nil
end

local function gather()
    local qlm = sdk.get_managed_singleton("app.QuestLogManager")
    if qlm == nil then return end
    if ALL_IDS == nil then ALL_IDS = dump_quest_id_enum() end

    local progressing = {}
    local acceptable  = {}
    local completed   = {}
    local recency     = {}

    local pl = safe_call(qlm, "getProgressingQuestIds")
    if pl then iter_list(pl, function(q) local n=to_int(q); if n then progressing[n]=true end end) end

    local al = safe_call(qlm, "getAcceptableQuestList")
    if al then iter_list(al, function(q) local n=to_int(q); if n then acceptable[n]=true end end) end

    local t = td("app.QuestLogManager")
    local m_end = t and t:get_method("isQuestLogEnd(app.QuestDefine.ID)")
    if m_end then
        for qid in pairs(ALL_IDS) do
            if qid and qid >= 0 then
                local e = call_method(m_end, qlm, qid)
                if e == true then completed[qid] = true end
            end
        end
    end

    local rec = safe_call(qlm, "getOrderedByUpdateQuestList")
    if rec ~= nil then
        iter_array(rec, function(q, i) local n=to_int(q); if n then recency[n]=i+1 end end)
        if next(recency) == nil then
            iter_list(rec, function(q, i) local n=to_int(q); if n then recency[n]=i+1 end end)
        end
    end

    for qid in pairs(ALL_IDS) do
        if qid and qid >= 0 and mod.name_cache[qid] == nil then
            resolve_meta(qlm, qid)
        end
    end

    -- Переход Доступен -> Текущий: убираем наш маркер, управление берёт внутриигровая метка.
    -- Записи в MANUAL_POS_OVERRIDES сохраняются, чтобы зафиксированные координаты оставались
    -- активными в циклах принятия/провала заданий и в NG+.
    for qid in pairs(mod.acceptable_ids or {}) do
        if progressing[qid] then
            if MAP_API and (MAP_API.pinned_pos and MAP_API.pinned_pos[qid] ~= nil
                                 or MAP_API.pinned_data and MAP_API.pinned_data[qid] ~= nil) then
                pcall(unpin_quest, qid)
                log.info("[quest_tracker] авто-открепление qid=" .. qid .. " (Доступен->Текущий)")
            end
        end
    end

    build_story_chain_map()

    mod.progressing_ids = progressing
    mod.acceptable_ids  = acceptable
    mod.completed_ids    = completed
    mod.recency_order   = recency

    local best_rank, best_qid = 999999, nil
    for qid in pairs(completed) do
        local r = recency[qid] or 999999
        if r < best_rank then best_rank = r; best_qid = qid end
    end
    mod.newest_completed = best_qid
end

local function classify(qid)
    if mod.completed_ids[qid]   then return "Completed" end
    if mod.progressing_ids[qid] then return "Ongoing" end
    if mod.acceptable_ids[qid]  then return "Available" end
    return nil
end

local function rebuild()
    if ALL_IDS == nil then ALL_IDS = dump_quest_id_enum() end
    pcall(gather)

    local list = {}
    local counts = {0,0,0}
    for qid, enum_name in pairs(ALL_IDS) do
        if qid ~= nil and qid >= 0 and enum_name ~= "Invalid" and enum_name ~= "None" then
            local cat = classify(qid)
            if cat ~= nil then
                local name = mod.name_cache[qid] or enum_name
                table.insert(list, {
                    id = qid,
                    enum_name = enum_name,
                    name = name,
                    name_en = mod.name_en_cache[qid],
                    summary = mod.summary_cache[qid],
                    recency = mod.recency_order[qid] or 999999,
                    category = cat,
                })
                if     cat == "Available" then counts[1] = counts[1] + 1
                elseif cat == "Ongoing"   then counts[2] = counts[2] + 1
                elseif cat == "Completed" then counts[3] = counts[3] + 1 end
            end
        end
    end

    if mod.sort_mode == 1 then
        table.sort(list, function(a, b)
            if a.recency ~= b.recency then return a.recency < b.recency end
            return a.name < b.name
        end)
    elseif mod.sort_mode == 2 then
        table.sort(list, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
    else
        table.sort(list, function(a, b) return a.id < b.id end)
    end

    mod.quests = list
    mod.state_counts = {
        counts[1], counts[2], counts[3],
        counts[1] + counts[2] + counts[3]
    }
end

local COL_AVAIL = 0xFFFFFFFF
local COL_ONGO  = 0xFF33CCFF
local COL_DONE  = 0xFF66FF66
local COL_HL    = 0xFF66FFFF
local COL_META  = 0xFF888888
local COL_DIM   = 0xFF666666

local function cat_color(c)
    if c == "Ongoing"   then return COL_ONGO end
    if c == "Completed" then return COL_DONE end
    return COL_AVAIL
end

local function draw_row(q)
    imgui.push_id(q.id)

    local is_recent = mod.highlight_recent and mod.newest_completed == q.id
    local prefix = is_recent and "* " or "  "

    local label = string.format("%s[%-5d] %s", prefix, q.id, q.name)
    local color = is_recent and COL_HL or cat_color(q.category)

    imgui.push_style_color(0, color)
    local open = imgui.tree_node(label)
    imgui.pop_style_color()

    if q.name == q.enum_name then
        imgui.same_line()
        imgui.text_colored(" (нет названия)", COL_DIM)
    end

    if open then
        imgui.push_style_color(0, COL_META)
        imgui.text("  enum: " .. (q.enum_name or ""))
        imgui.pop_style_color()

        if QD then
            local lvl = QD.get_recommended_level and QD.get_recommended_level(q.id) or nil
            if lvl and lvl > 0 then
                imgui.text_colored(string.format("  Рекомендуемый ур: %d", lvl), 0xFFAACCFF)
            end
        end

        do
            local chain_map = STORY_CHAIN_MAP or build_story_chain_map()
            local ancestors = chain_map[q.id]
            if ancestors and #ancestors > 0 then
                local function name_of(qid)
                    for _, pq in ipairs(mod.quests) do
                        if pq.id == qid then return pq.name_en or pq.name or "?" end
                    end
                    if mod.name_en_cache and mod.name_en_cache[qid] then return mod.name_en_cache[qid] end
                    if mod.name_cache and mod.name_cache[qid] then return mod.name_cache[qid] end
                    return "?"
                end
                local function status_tag(qid)
                    if mod.completed_ids[qid] then return " [выполнен]" end
                    if mod.progressing_ids[qid] then return " [в процессе]" end
                    if mod.acceptable_ids[qid] then return " [доступен]" end
                    return ""
                end
                local function draw_chain(qid, depth, visited)
                    if visited[qid] or depth > 8 then return end
                    visited[qid] = true
                    local list = chain_map[qid]
                    if not list then return end
                    local dedup = {}
                    for _, lq in ipairs(list) do
                        if not dedup[lq] then
                            dedup[lq] = true
                            local done = mod.completed_ids[lq]
                            local color = done and 0xFF66FF66 or 0xFFAAAAAA
                            imgui.text_colored(
                                string.rep("  ", depth) .. string.format("    - [%d] %s%s",
                                    lq, name_of(lq), status_tag(lq)),
                                color)
                            draw_chain(lq, depth + 1, visited)
                        end
                    end
                end
                imgui.text_colored("  Цепочка квестов:", 0xFF888888)
                draw_chain(q.id, 0, {})
            end
        end
        if q.category == "Available" or q.category == "Ongoing" then
            local is_pinned = MAP_API.pinned_data[q.id] ~= nil or MAP_API.pinned_pos[q.id] ~= nil
            local label = is_pinned and "Убрать с карты" or "Показать на карте"
            if imgui.button(label) then
                local ok, msg
                if is_pinned then
                    ok, msg = unpin_quest(q.id)
                else
                    ok, msg = pin_quest(q.id)
                end
                if not ok then
                    MAP_API.last_msg = "ошибка qid=" .. q.id .. ": " .. tostring(msg)
                    print("[QuestTrackerV2] " .. MAP_API.last_msg)
                end
            end
            imgui.same_line()
        end
        if q.summary and q.summary ~= "" then
            imgui.text("")
            imgui.text_colored("  " .. q.summary:gsub("\n", "\n  "), 0xFFDDDDDD)
        end

        if q.category ~= "Completed" then
            local pins = MAP_API.pinned_pos and MAP_API.pinned_pos[q.id]
            local elim = MAP_API.eliminated_pos and MAP_API.eliminated_pos[q.id]
            local current_override = MANUAL_GIVER_OVERRIDES[q.id]
            if pins and #pins >= 1 and not current_override then
                imgui.text("")
                imgui.text_colored("  Кандидаты (удалите для исключения, выберите как квестодателя для фиксации):", 0xFFFFCC66)
                for _, p in ipairs(pins) do
                    local tag = "##" .. q.id .. "_" .. tostring(p.cid or "manual")
                    if p.manual then
                        imgui.text(string.format("    [ручная поз] (%.1f,%.1f,%.1f)", p.x, p.y, p.z))
                    else
                        imgui.text(string.format("    cid=%d поз=(%.1f,%.1f,%.1f)", p.cid or 0, p.x, p.y, p.z))
                        imgui.same_line()
                        if imgui.button("Исключить" .. tag) then pcall(unpin_candidate, q.id, p.cid) end
                        imgui.same_line()
                        if imgui.button("Копировать cid" .. tag) then imgui.set_clipboard(tostring(p.cid or 0)) end
                        imgui.same_line()
                        if imgui.button("Сделать квестодателем" .. tag) then
                            if p.cid and p.cid > 0 then
                                MANUAL_GIVER_OVERRIDES[q.id] = p.cid
                                mark_prefs_dirty()
                                pcall(unpin_quest, q.id)
                                pcall(pin_quest, q.id)
                            end
                        end
                    end
                end
            end
            if elim and #elim > 0 then
                imgui.text_colored("  Исключенные (нажмите 'Вернуть' для восстановления):", 0xFF888888)
                for _, p in ipairs(elim) do
                    local tag = "##e" .. q.id .. "_" .. tostring(p.cid or 0)
                    imgui.text(string.format("    cid=%d поз=(%.1f,%.1f,%.1f)", p.cid or 0, p.x, p.y, p.z))
                    imgui.same_line()
                    if imgui.button("Вернуть" .. tag) then pcall(restore_candidate, q.id, p.cid) end
                    imgui.same_line()
                    if imgui.button("Копировать cid" .. tag) then imgui.set_clipboard(tostring(p.cid or 0)) end
                end
                if imgui.button("Восстановить всех##" .. q.id) then pcall(restore_all_candidates, q.id) end
            end
            if current_override then
                imgui.text_colored(string.format("  Сохраненный квестодатель cid=%d", current_override), 0xFF66CCFF)
                imgui.same_line()
                if imgui.button("Сбросить фиксацию##" .. q.id) then
                    MANUAL_GIVER_OVERRIDES[q.id] = nil
                    mark_prefs_dirty()
                    pcall(unpin_quest, q.id)
                end
            end

            local current_pos = MANUAL_POS_OVERRIDES[q.id]
            if current_pos then
                imgui.text_colored(string.format("  Ручная позиция: (%.1f,%.1f,%.1f)",
                    current_pos.x, current_pos.y, current_pos.z), 0xFF66CCFF)
                imgui.same_line()
                if imgui.button("Очистить поз##" .. q.id) then
                    MANUAL_POS_OVERRIDES[q.id] = nil
                    mark_prefs_dirty()
                    pcall(unpin_quest, q.id)
                end
            end
            if imgui.button("Захватить позицию игрока как цель##" .. q.id) then
                local px, py, pz = get_player_universal_pos()
                if px ~= nil then
                    MANUAL_POS_OVERRIDES[q.id] = { x = px, y = py, z = pz }
                    mark_prefs_dirty()
                    pcall(unpin_quest, q.id)
                    pcall(pin_quest, q.id)
                end
            end
        end

        if imgui.button("Копировать ID") then imgui.set_clipboard(tostring(q.id)) end
        imgui.same_line()
        if imgui.button("Копировать название") then imgui.set_clipboard(q.name) end
        imgui.tree_pop()
    end

    imgui.pop_id()
end

-- =========== MAP MARKER API ===========

MAP_API = {
    ready = false,
    gm = nil,
    pinned_data    = {},   -- qid -> массив целевых userdata (Текущие: питает makeQuestTargetMarkerInfo)
    pinned_pos     = {},   -- qid -> массив позиций {x,y,z,cid} в мире (Путь квестодателя)
    eliminated_pos = {},   -- qid -> массив {x,y,z,cid} удаленных пользователем кандидатов
    status = "не инициализировано",
    last_msg = "",
}

for qid, arr in pairs(ELIMINATED_OVERRIDES) do
    MAP_API.eliminated_pos[qid] = {}
    for _, p in ipairs(arr) do
        table.insert(MAP_API.eliminated_pos[qid], {
            cid = p.cid, x = p.x, y = p.y, z = p.z,
        })
    end
end

local HOOK_INSTALLED = false

local function get_marker_list()
    local gm = sdk.get_managed_singleton("app.GuiManager")
    if gm == nil then return nil, nil end
    local ok, list = pcall(function() return gm:call("get_QuestTargetMarkerList") end)
    if ok then return list, gm end
    return nil, gm
end

local function build_marker(dest, qid)
    if dest == nil then return nil end
    local gm = MAP_API.gm or sdk.get_managed_singleton("app.GuiManager")
    if gm == nil then return nil end
    local ok, m = pcall(function() return gm:call("makeQuestTargetMarkerInfo", dest, qid) end)
    if ok and m ~= nil then return m end
    return nil
end

-- Свободный маркер по координатам мира без вычитания ячеек.
local function build_marker_at_pos(wx, wy, wz)
    local t = td("app.GuiManager.QuestTargetMarkerInfo")
    if t == nil then return nil end
    local ok, m = pcall(function() return t:create_instance():add_ref() end)
    if not ok or m == nil then return nil end
    local okS = pcall(function()
        m.DestType    = 3
        m.IconType    = 0
        m.KeyLocation = 0
        m.LocalArea   = 0
        m.MapArea     = 0
        m.Pos         = Vector3f.new(wx, wy, wz)
    end)
    if not okS then return nil end
    return m
end

-- Запускается после вызова оригинального метода setupQuestTargetMarker,
-- чтобы наши маркеры переживали перестроения списков игры.
local function reinject_all()
    local list = get_marker_list()
    if list == nil then return end
    for qid, entry in pairs(MAP_API.pinned_data) do
        for _, dest in ipairs(entry) do
            local marker = build_marker(dest, qid)
            if marker ~= nil then
                pcall(function() list:call("Add", marker) end)
            end
        end
    end
    for qid, entry in pairs(MAP_API.pinned_pos) do
        for _, p in ipairs(entry) do
            local marker = build_marker_at_pos(p.x, p.y, p.z)
            if marker ~= nil then
                pcall(function() list:call("Add", marker) end)
            end
        end
    end
end

-- =========== MAP ICONS С НАЗВАНИЯМИ КВЕСТОВ ===========
local ICON_HOOK_INSTALLED = false
local ICON_ICON_TYPE = 25
local INT_T, INT_T_VOFF
local UI_MAP = nil
local WANT_ICON_REFRESH = false

local function _icon_init_helpers()
    if INT_T == nil then
        INT_T = sdk.find_type_definition("System.Int32")
        if INT_T then
            local f = INT_T:get_field("m_value")
            if f then INT_T_VOFF = f:get_offset_from_base() end
        end
    end
end

local function get_quest_name_guid(qid)
    local qlm = sdk.get_managed_singleton("app.QuestLogManager")
    if qlm == nil then return nil end
    local vi = safe_call(qlm, "getQuestLog", qid)
    if vi == nil then return nil end
    return safe_get_field(vi, "QuestNameId")
end

local function _add_one_labeled_icon(this, x, y, z, name_guid, idx_obj)
    local t = td("app.GuiManager.MapIconInfo")
    if t == nil then return nil end
    local ok, info = pcall(function() return t:create_instance():add_ref() end)
    if not ok or info == nil then return nil end
    pcall(function()
        info.IsEnable      = true
        info.IsNavi        = false
        info.IconId        = 0
        info.SortNo        = 0
        info.IconType      = ICON_ICON_TYPE
        info.Timing        = 0
        info.Pos           = Vector3f.new(x, y, z)
        info.Area          = -1
        info.LocalArea     = 0
        info.IsDispAllArea = true
    end)
    local okA, ui_icon = pcall(function()
        return this:call("addMapIconInfoList",
            info, 0,
            idx_obj:get_address() + INT_T_VOFF,
            -1,
            name_guid)
    end)
    if okA then return ui_icon end
    return nil
end

local function add_labeled_markers_for_all_pins(this)
    if not mod.label_pins then return end
    _icon_init_helpers()
    if INT_T == nil or INT_T_VOFF == nil then return end

    local icon_count = 0
    local icon_limit = 0
    pcall(function() icon_count = this.MapIconInfoList:get_Count() end)
    pcall(function() icon_limit = this.MapIcon:get_Length() end)
    if icon_limit == 0 or icon_count >= icon_limit then return end

    local idx_obj = INT_T:create_instance():add_ref()

    for qid, pins in pairs(MAP_API.pinned_pos) do
        if icon_count >= icon_limit then break end
        local name_guid = get_quest_name_guid(qid)
        if name_guid ~= nil then
            for _, p in ipairs(pins) do
                if icon_count >= icon_limit then break end
                idx_obj:write_dword(INT_T_VOFF, icon_count)
                if _add_one_labeled_icon(this, p.x, p.y, p.z, name_guid, idx_obj) ~= nil then
                    icon_count = icon_count + 1
                end
            end
        end
    end
end

local function install_icon_hook()
    if ICON_HOOK_INSTALLED then return true end
    local t = td("app.ui040205")
    if t == nil then return false end
    local m = t:get_method("setupMapIcon")
    if m == nil then return false end
    local ok = pcall(function()
        sdk.hook(m,
            function(args)
                UI_MAP = sdk.to_managed_object(args[2])
            end,
            function(retval)
                local this = UI_MAP
                if this ~= nil then
                    pcall(add_labeled_markers_for_all_pins, this)
                    pcall(function() this:call("updateMapIcon") end)
                end
                return retval
            end)
    end)
    if ok then ICON_HOOK_INSTALLED = true end
    local mD = t:get_method("onDestroy")
    if mD then
        pcall(function()
            sdk.hook(mD, function(args) end, function(retval) UI_MAP = nil; return retval end)
        end)
    end
    return ICON_HOOK_INSTALLED
end

init_map_api = function()
    if not ICON_HOOK_INSTALLED then pcall(install_icon_hook) end

    if MAP_API.ready then return true end
    MAP_API.gm = sdk.get_managed_singleton("app.GuiManager")
    if MAP_API.gm == nil then MAP_API.status = "GuiManager singleton равен nil"; return false end
    local t = td("app.GuiManager")
    if t == nil then MAP_API.status = "GuiManager typedef равен nil"; return false end

    if not HOOK_INSTALLED then
        local m_setup = t:get_method("setupQuestTargetMarker")
        if m_setup then
            local ok = pcall(function()
                sdk.hook(m_setup, function(args) return end, function(retval)
                    pcall(reinject_all)
                    return retval
                end)
            end)
            if ok then HOOK_INSTALLED = true end
        end
    end

    install_icon_hook()

    MAP_API.ready = true
    MAP_API.status = "ок  хук=" .. tostring(HOOK_INSTALLED) .. " хукиконок=" .. tostring(ICON_HOOK_INSTALLED)
    return true
end

clear_injected_markers = function()
    if not MAP_API.ready then return end
    MAP_API.pinned_data = {}
    MAP_API.pinned_pos  = {}
    MAP_API.last_msg = "активные маркеры очищены"
    force_marker_refresh()
end

get_quest_resource = function(qlm, qid)
    local cat = safe_get_field(qlm, "_Catalog")
    if cat == nil then return nil end
    local vals = safe_call(cat, "getValues")
    if vals == nil then return nil end
    local ok, sz = pcall(function() return vals:get_size() end)
    if not ok or sz == nil then return nil end
    for i = 0, sz - 1 do
        local okE, v = pcall(function() return vals:get_element(i) end)
        if okE and v ~= nil then
            local rq = safe_get_field(v, "_QuestId") or safe_call(v, "get_QuestId")
            if to_int(rq) == qid then return v end
        end
    end
    return nil
end

get_player_universal_pos = function()
    local gmu = sdk.get_managed_singleton("app.GuiManager")
    if gmu == nil then return nil end
    local x, y, z
    pcall(function() local p = gmu.PlUPos; x, y, z = p.x, p.y, p.z end)
    return x, y, z
end

local GIVER_CACHE = {}
get_quest_cast_charaids = function(qid)
    if GIVER_CACHE[qid] ~= nil then return GIVER_CACHE[qid] end
    local qm = sdk.get_managed_singleton("app.QuestManager")
    if qm == nil then return nil end
    local qcd = safe_get_field(qm, "QuestCatalogDict")
    if qcd == nil then return nil end
    local vals = safe_call(qcd, "getValues")
    if vals == nil then return nil end
    local cdsz = 0; pcall(function() cdsz = vals:get_size() end)
    for k = 0, cdsz - 1 do
        local okC, cd = pcall(function() return vals:get_element(k) end)
        if okC and cd then
            local ctx = safe_get_field(cd, "ContextData")
            if ctx then
                local arr = safe_get_field(ctx, "ContextDataArray")
                if arr then
                    local asz = 0; pcall(function() asz = arr:get_size() end)
                    for j = 0, asz - 1 do
                        local okE, e = pcall(function() return arr:get_element(j) end)
                        if okE and e then
                            local idv = safe_get_field(e, "_IDValue")
                            if to_int(idv) == qid then
                                local cast = safe_get_field(e, "CastNPCIDs")
                                local out = {}
                                if cast then
                                    local csz = 0; pcall(function() csz = cast:get_size() end)
                                    for m = 0, csz - 1 do
                                        local okF, item = pcall(function() return cast:get_element(m) end)
                                        if okF and item ~= nil then
                                            local n = to_int(item)
                                            if n then table.insert(out, n) end
                                        end
                                    end
                                end
                                GIVER_CACHE[qid] = out
                                return out
                            end
                        end
                    end
                end
            end
        end
    end
    GIVER_CACHE[qid] = false
    return nil
end

-- NPCHolder.get_UniversalPosition() возвращает координаты мира даже для незаспавненных NPC
-- (считывается из сохранений/состояния мира, а не живого трансформа). (0,0,0) считается пустой меткой.
local function _extract_pos_from(obj)
    if obj == nil then return nil end
    for _, mn in ipairs({"get_UniversalPosition", "get_Position", "get_WorldPosition"}) do
        local ok, p = pcall(function() return obj:call(mn) end)
        if ok and p ~= nil then
            local x, y, z; pcall(function() x, y, z = p.x, p.y, p.z end)
            if x ~= nil and not (x == 0 and y == 0 and z == 0) then return x, y, z end
        end
    end
    local okGO, go = pcall(function() return obj:call("get_GameObject") end)
    if okGO and go ~= nil then
        local okT, trf = pcall(function() return go:call("get_Transform") end)
        if okT and trf ~= nil then
            local okP, p = pcall(function() return trf:call("get_Position") end)
            if okP and p ~= nil then
                local x, y, z; pcall(function() x, y, z = p.x, p.y, p.z end)
                if x ~= nil and not (x == 0 and y == 0 and z == 0) then return x, y, z end
            end
        end
    end
    return nil
end

-- Возвращает x,y,z,nil или nil,nil,nil,ошибка. CharacterManager обрабатывает заспавненных NPC;
-- перебор NPCHolderDic через get_UniversalPosition также находит незаспавненных.
local function get_character_world_pos(cid_int)
    if type(cid_int) ~= "number" then
        return nil, nil, nil, "cid_int не является числом"
    end

    local cm = sdk.get_managed_singleton("app.CharacterManager")
    if cm ~= nil then
        for _, mn in ipairs({"findByCharacterID", "findCharacterByCharacterID", "findCharacter", "getCharacter"}) do
            local ok, c = pcall(function() return cm:call(mn, cid_int) end)
            if ok and c ~= nil then
                local x, y, z = _extract_pos_from(c)
                if x then return x, y, z, nil end
            end
        end
    end

    local nm = sdk.get_managed_singleton("app.NPCManager")
    if nm == nil then return nil, nil, nil, "нет NPCManager" end
    local dic = safe_get_field(nm, "NPCHolderDic")
    if dic == nil then return nil, nil, nil, "нет NPCHolderDic" end

    local sz = 0; pcall(function() sz = dic:get_size() end)
    for i = 0, sz - 1 do
        local okE, h = pcall(function() return dic:get_element(i) end)
        if okE and h ~= nil then
            if to_int(safe_get_field(h, "CharaID")) == cid_int then
                local x, y, z = _extract_pos_from(h)
                if x then return x, y, z, nil end
                return nil, nil, nil, "холдер найден, но UniversalPosition некорректна"
            end
        end
    end
    return nil, nil, nil, "нет совпадений холдера для charaID"
end

local function get_quest_destinations(qlm, qid)
    local res = get_quest_resource(qlm, qid)
    if res == nil then return nil, "нет QuestLogResource" end
    local first_tasks = safe_call(res, "get_FirstTaskList")
                     or safe_get_field(res, "_FirstTaskList")
    if first_tasks == nil then return nil, "нет FirstTaskList" end

    local out = {}
    iter_list(first_tasks, function(task)
        local dests = safe_call(task, "getActiveDestinations")
                   or safe_call(task, "get_Destinations")
                   or safe_get_field(task, "_Destinations")
        if dests == nil then return end
        local okSz, sz = pcall(function() return dests:get_size() end)
        if not okSz or sz == nil or sz == 0 then return end
        for i = 0, sz - 1 do
            local okE, d = pcall(function() return dests:get_element(i) end)
            if okE and d ~= nil then table.insert(out, d) end
        end
    end)
    if #out == 0 then return nil, "нет целевых точек (destinations)" end
    return out
end

pin_quest = function(qid)
    dlog("====== pin_quest qid=" .. tostring(qid) .. " ======")
    if not init_map_api() then return false, "не удалось инициализировать map api" end

    local qlm = sdk.get_managed_singleton("app.QuestLogManager")
    if qlm == nil then return false, "QLM singleton равен nil" end

    local list = get_marker_list()
    if list == nil then return false, "список маркеров равен nil" end

    local is_available = mod.acceptable_ids[qid] == true
    dlog("категория=" .. (is_available and "Доступные" or "Текущие/другое"))
    local added = 0

    if MANUAL_POS_OVERRIDES[qid] then
        local p = MANUAL_POS_OVERRIDES[qid]
        dlog("использование MANUAL_POS_OVERRIDES[" .. qid .. "]=(" .. p.x .. "," .. p.y .. "," .. p.z .. ")")
        local marker = build_marker_at_pos(p.x, p.y, p.z)
        if marker then
            pcall(function() list:call("Add", marker) end)
            MAP_API.pinned_pos[qid] = { { x = p.x, y = p.y, z = p.z, cid = nil, manual = true } }
            MAP_API.last_msg = string.format("закреплен qid=%d режим=ручная-поз поз=(%.1f,%.1f,%.1f)",
                qid, p.x, p.y, p.z)
            dlog("ОК " .. MAP_API.last_msg)
            return true, "закреплено"
        end
    end

    if is_available then
        if MANUAL_GIVER_OVERRIDES[qid] then
            local cid = MANUAL_GIVER_OVERRIDES[qid]
            dlog("использование MANUAL_GIVER_OVERRIDES[" .. qid .. "]=" .. cid)
            local wx, wy, wz, perr = get_character_world_pos(cid)
            if wx ~= nil then
                local marker = build_marker_at_pos(wx, wy, wz)
                if marker then
                    pcall(function() list:call("Add", marker) end)
                    MAP_API.pinned_pos[qid] = { { x = wx, y = wy, z = wz, cid = cid } }
                    MAP_API.last_msg = string.format("закреплен qid=%d режим=вручную cid=%d поз=(%.1f,%.1f,%.1f)",
                        qid, cid, wx, wy, wz)
                    dlog("ОК " .. MAP_API.last_msg)
                    return true, "закреплено"
                end
            end
            dlog("ручное переопределение не удалось, переход к автоопределению: " .. tostring(perr))
        end

        -- Определение: приоритет у статического QD.get_givers, при отсутствии — CastNPCIDs из игры.
        local cast = qd_givers(qid)
        if cast then
            dlog("использование QD.get_givers[" .. qid .. "] (записей: " .. #cast .. ")")
        else
            cast = get_quest_cast_charaids(qid)
            dlog("динамический CastNPCIDs для qid=" .. qid .. ": " .. (cast and ("[" .. table.concat(cast, ",") .. "]") or "nil"))
        end
        if cast == nil or cast == false or #cast == 0 then
            dlog("ОТМЕНА: нет подходящих NPC для квеста")
            return false, "нет NPC квестодателей (см. лог отладки)"
        end
        
        -- Массовое закрепление всех NPC из списка (минус общие шаблоны и исключенные).
        local GENERIC_NPC_IDS = { [2891076981] = true, [260732951] = true }
        local elim_cids = {}
        local elim_list = MAP_API.eliminated_pos[qid]
        if elim_list then
            for _, p in ipairs(elim_list) do
                if p.cid then elim_cids[p.cid] = true end
            end
        end
        local multi = {}
        for _, c in ipairs(cast) do
            if not GENERIC_NPC_IDS[c] and not elim_cids[c] then
                local wx, wy, wz = get_character_world_pos(c)
                if wx ~= nil then
                    table.insert(multi, { x = wx, y = wy, z = wz, cid = c })
                end
            end
        end
        if #multi > 0 then
            for i, p in ipairs(multi) do
                local marker = build_marker_at_pos(p.x, p.y, p.z)
                if marker ~= nil then
                    local okA = pcall(function() list:call("Add", marker) end)
                    if okA then added = added + 1 end
                end
                dlog(string.format("  масс-маркер[%d] cid=%d поз=(%.1f,%.1f,%.1f)", i, p.cid, p.x, p.y, p.z))
            end
            MAP_API.pinned_pos[qid] = multi
            MAP_API.last_msg = string.format("закреплен qid=%d режим=масс-поиск найдено=%d отмечено=%d (выберите правильный маркер через 'Сделать квестодателем')",
                qid, #cast, #multi)
            dlog("ОК " .. MAP_API.last_msg)
            return true, "закреплено"
        end
        dlog("ОТМЕНА: нет NPC в базе NPCHolderDic — возможно, нестандартный квест (Сфинкс/рычаг/интерактив)")
        MAP_API.last_msg = string.format(
            "qid=%d: Кандидаты НЕ найдены. Возможно, цель не является NPC (Сфинкс / триггер / враг). " ..
            "Список Cast: [%s]. Требуется другой источник данных.",
            qid, table.concat(cast, ","))
        return false, "нет кандидатов NPC; вероятно, это нестандартный квест (см. последнее сообщение)"
    else
        local dests = get_quest_destinations(qlm, qid)
        if dests == nil or #dests == 0 then return false, "нет целевых точек" end
        for _, dest in ipairs(dests) do
            local marker = build_marker(dest, qid)
            if marker ~= nil then
                local okA = pcall(function() list:call("Add", marker) end)
                if okA then added = added + 1 end
            end
        end
        if added == 0 then return false, "маркер не создан (makeQuestTargetMarkerInfo вернул ошибку)" end
        MAP_API.pinned_data[qid] = dests
        MAP_API.last_msg = string.format("закреплен qid=%d режим=цель точек=%d добавлено=%d", qid, #dests, added)
    end

    return true, "закреплено"
end

-- Перезапускает оригинальный метод setupQuestTargetMarker
force_marker_refresh = function()
    if MAP_API._refreshing then return end
    MAP_API._refreshing = true
    pcall(function()
        local gm = MAP_API.gm or sdk.get_managed_singleton("app.GuiManager")
        if gm ~= nil then gm:call("setupQuestTargetMarker") end
    end)
    MAP_API._refreshing = false
end

unpin_quest = function(qid)
    MAP_API.pinned_data[qid] = nil
    MAP_API.pinned_pos[qid]  = nil
    MAP_API.last_msg = "откреплен qid=" .. qid
    force_marker_refresh()
    return true, "откреплен"
end

local function sync_eliminated_to_prefs()
    ELIMINATED_OVERRIDES = {}
    for qid, list in pairs(MAP_API.eliminated_pos or {}) do
        local saved = {}
        for _, p in ipairs(list) do
            if p.cid and p.cid > 0 then
                saved[#saved+1] = { cid = p.cid, x = p.x, y = p.y, z = p.z }
            end
        end
        if #saved > 0 then ELIMINATED_OVERRIDES[qid] = saved end
    end
    mark_prefs_dirty()
end

unpin_candidate = function(qid, cid)
    local pins = MAP_API.pinned_pos[qid]
    if pins == nil then return false end
    local kept, removed = {}, nil
    for _, p in ipairs(pins) do
        if p.cid == cid and removed == nil then removed = p
        else table.insert(kept, p) end
    end
    if #kept == 0 then MAP_API.pinned_pos[qid] = nil
    else MAP_API.pinned_pos[qid] = kept end
    if removed then
        MAP_API.eliminated_pos[qid] = MAP_API.eliminated_pos[qid] or {}
        table.insert(MAP_API.eliminated_pos[qid], removed)
        sync_eliminated_to_prefs()
    end
    force_marker_refresh()
    return true
end

restore_candidate = function(qid, cid)
    local elim = MAP_API.eliminated_pos[qid]
    if elim == nil then return false end
    local kept, restored = {}, nil
    for _, p in ipairs(elim) do
        if p.cid == cid and restored == nil then restored = p
        else table.insert(kept, p) end
    end
    if #kept == 0 then MAP_API.eliminated_pos[qid] = nil
    else MAP_API.eliminated_pos[qid] = kept end
    if restored then
        MAP_API.pinned_pos[qid] = MAP_API.pinned_pos[qid] or {}
        table.insert(MAP_API.pinned_pos[qid], restored)
    end
    sync_eliminated_to_prefs()
    force_marker_refresh()
    return true
end

restore_all_candidates = function(qid)
    local elim = MAP_API.eliminated_pos[qid]
    if elim == nil then return end
    MAP_API.pinned_pos[qid] = MAP_API.pinned_pos[qid] or {}
    for _, p in ipairs(elim) do table.insert(MAP_API.pinned_pos[qid], p) end
    MAP_API.eliminated_pos[qid] = nil
    sync_eliminated_to_prefs()
    force_marker_refresh()
end

local function matches_filter(q)
    if mod.filter_text == "" then return true end
    local f = string.lower(mod.filter_text)
    return (string.find(string.lower(q.name or ""), f, 1, true))
        or (q.name_en and string.find(string.lower(q.name_en), f, 1, true))
        or (string.find(string.lower(q.enum_name or ""), f, 1, true))
        or (string.find(string.lower(q.summary or ""), f, 1, true))
        or (string.find(tostring(q.id), f, 1, true))
end

--========================================================--
-- Графический интерфейс настроек REFramework ImGui
--========================================================--
re.on_draw_ui(function()
    if imgui.tree_node("Трекер квестов (Quest Tracker)  [" .. MOD_VERSION .. "]") then
        local ch
        ch, mod.show_window = imgui.checkbox("Показывать окно трекера", mod.show_window)
        if ch then save_prefs() end
        ch, mod.label_pins = imgui.checkbox("Подписывать маркеры на карте названиями квестов", mod.label_pins)
        if ch then save_prefs() end
        ch, mod.debug_logging = imgui.checkbox("Подробный лог отладки (создает файл quest_tracker_debug.txt)", mod.debug_logging)
        if ch then DEBUG_LOGGING = mod.debug_logging; if DEBUG_LOGGING then _log_session_start() end; save_prefs() end

        imgui.separator()
        imgui.text_colored(
            QD and "Модуль quest_data_loader: ЗАГРУЖЕН" or "Модуль quest_data_loader: ОТСУТСТВУЕТ (Реком. уровень и цепочки отключены)",
            QD and 0xFF66CC66 or 0xFF888888)

        imgui.tree_pop()
    end
end)

re.on_frame(function()
    pcall(flush_prefs_if_dirty)

    local now = os.clock()
    if now - mod.last_refresh > mod.refresh_interval then
        mod.last_refresh = now
        pcall(rebuild)
    end

    if not mod.show_window then return end
    if not reframework:is_drawing_ui() then return end

    local draw = imgui.begin_window("Трекер квестов  [" .. MOD_VERSION .. "]", true, 0)
    if not draw then mod.show_window = false; save_prefs() end

    if draw then
        local ch
        local px, py, pz = get_player_universal_pos()
        if px ~= nil then
            imgui.text_colored(string.format("Позиция игрока: (%.1f, %.1f, %.1f)", px, py, pz), 0xFFAACCFF)
        end
        imgui.text("Фильтр:") imgui.same_line()
        ch, mod.filter_text = imgui.input_text("##filter", mod.filter_text)

        imgui.text("Сортировка:") imgui.same_line()
        ch, mod.sort_mode = imgui.combo("##sort", mod.sort_mode, SORT_NAMES)
        if ch then pcall(rebuild); save_prefs() end
        imgui.same_line()
        ch, mod.highlight_recent = imgui.checkbox("Подсвечивать новые", mod.highlight_recent)
        if ch then save_prefs() end

        if imgui.tree_node("Активные маркеры на карте") then
            local any = false
            for qid, pins in pairs(MAP_API.pinned_pos) do
                any = true
                imgui.text("qid=" .. qid .. ":")
                for _, p in ipairs(pins) do
                    imgui.text(string.format("  cid=%d поз=(%.1f,%.1f,%.1f)", p.cid or 0, p.x, p.y, p.z))
                end
            end
            if not any then imgui.text("(нет активных маркеров)") end
            imgui.tree_pop()
        end

        if imgui.button("Очистить все маркеры") then pcall(clear_injected_markers) end
        imgui.same_line()
        
        -- Экспорт пользовательской базы в файл
        if imgui.button("Экспорт данных для сообщества") then
            pcall(function()
                local lines = {}
                table.insert(lines, "# Экспорт данных DD2 Quest Tracker")
                table.insert(lines, "# Версия мода: " .. MOD_VERSION)
                table.insert(lines, "# Экспортировано: " .. os.date("%Y-%m-%d %H:%M:%S"))
                table.insert(lines, "# Формат: заголовок секции, затем строки вида 'qid=значение'")
                table.insert(lines, "# Содержит только те записи, которые отличаются от стандартных настроек мода")
                table.insert(lines, "")
                
                local qids = {}
                for qid, cid in pairs(MANUAL_GIVER_OVERRIDES) do
                    if not is_bundled_giver(qid, cid) then table.insert(qids, qid) end
                end
                table.sort(qids)
                table.insert(lines, "[GIVERS] qid=charaID  (записей: " .. #qids .. ")")
                for _, qid in ipairs(qids) do
                    table.insert(lines, string.format("%d=%d", qid, MANUAL_GIVER_OVERRIDES[qid]))
                end
                table.insert(lines, "")
                
                local pids = {}
                for qid, p in pairs(MANUAL_POS_OVERRIDES) do
                    if not is_bundled_pos(qid, p) then table.insert(pids, qid) end
                end
                table.sort(pids)
                table.insert(lines, "[POSITIONS] qid=x,y,z  (записей: " .. #pids .. ")")
                for _, qid in ipairs(pids) do
                    local p = MANUAL_POS_OVERRIDES[qid]
                    table.insert(lines, string.format("%d=%.2f,%.2f,%.2f", qid, p.x, p.y, p.z))
                end
                
                local out = table.concat(lines, "\n")
                local out_path = "quest_tracker_export.txt"
                local f = io.open(out_path, "w")
                if f then f:write(out); f:close() end
                MAP_API.last_msg = string.format("Экспорт завершен в %s (%d байт, %d квестодателей, %d позиций)",
                    out_path, #out, #qids, #pids)
            end)
        end

        imgui.text_colored("[map api] " .. MAP_API.status, 0xFF888888)
        if MAP_API.last_msg ~= "" then
            imgui.text_colored("[map out] " .. MAP_API.last_msg, 0xFF66CCFF)
        end

        for i, name in ipairs(TAB_NAMES) do
            if i > 1 then imgui.same_line() end
            local count = (i <= 3) and mod.state_counts[i] or mod.state_counts[4]
            if imgui.button(name .. " (" .. tostring(count) .. ")") then
                mod.tab = i
                save_prefs()
            end
        end

        imgui.separator()

        local cat = TAB_NAMES[mod.tab]
        local child_visible = imgui.begin_child_window("list", 0.0, 0.0, true)
        if child_visible then
            local ok, err = pcall(function()
                for _, q in ipairs(mod.quests) do
                    if (cat == "Все" or q.category == (cat == "Доступные" and "Available" or cat == "Текущие" and "Ongoing" or "Completed")) and matches_filter(q) then
                        draw_row(q)
                    end
                end
            end)
            if not ok then
                print("[Трекер квестов] Ошибка отрисовки: " .. tostring(err))
            end
        end
        imgui.end_child_window()
    end
    imgui.end_window()
end)
------------------------------------------------------------
-- dd2_loot_locator.lua (СТАБИЛЬНАЯ ВЕРСИЯ - V1.3 - ФИКС ДРЕВЕСИНЫ)
-- Автономный скрипт. НЕ запускать одновременно с другими модами на подсветку лута.
------------------------------------------------------------

local default_config = {
    enabled          = true,
    max_distance     = 45.0,
    scan_interval    = 40,
    max_markers      = 300,
    color            = 0xFFFFE000,
    show_names       = true,
    show_enemy_drops = true,
    show_unknown      = false,
    height_offset    = 0.5,
    show_rare_only   = false,
    color_rare       = 0xFF00FFFF,
    show_distance    = false,
    use_symbols      = false,
    show_edge_arrows = true,
    radar_radius     = 560.0,
    dev_mode         = false,
    filter_tokens    = true,
    filter_beetles   = true,
    filter_chests    = true,
    filter_riftstones = true,
    filter_wakestones = true,
}

local config = json.load_file("loot_locator_config.json") or {}
for k, v in pairs(default_config) do
    if config[k] == nil then
        config[k] = v
    end
end

local function save_config()
    json.dump_file("loot_locator_config.json", config)
end

-- ── Таблица имен (С заменой Поленницы на Кучу древесины) ─────────────────────
local name_lookup = {
    ["gm80_001"]      = "Сундук с сокровищами",
    ["gm80_053"]      = "Камень разлома",
    ["gm80_096"]      = "Украшенный сундук",
    ["gm80_097"]      = "Большой сундук",
    ["gm80_096_10"]   = "Украшенный сундук",
    ["gm82_018"]      = "Лунноцвет",
    ["gm80_211"]      = "Осколок камня пробуждения",
    ["gm82_000"]      = "Лут",
    ["gm82_001"]      = "Целебная трава",
    ["gm82_000_01"]   = "Лут",
    ["gm82_009_01"]   = "Целебная трава",
    ["gm82_009_05"]   = "Лист сиропника",
    ["gm82_009_10"]   = "Целебная трава",
    ["gm82_009_20"]   = "Крупнолепестник",
    ["gm82_009"]      = "Растение",
    ["gm82_012"]      = "Виноград",
    ["gm82_013"]      = "Яблоко",
    ["gm82_015"]      = "Рудная жила",
    
    ["gm82_014"]      = "Айва",
    ["gm82_014_01"]   = "Айва",
    ["gm82_014_02"]   = "Айва",
    
    ["gm82_016_10"]   = "Звериные кости",
    ["gm82_016"]      = "Куча костей",
    ["gm82_020"]      = "Клубни картофеля",
    ["gm82_023"]      = "Кора корицы",
    ["gm82_036"]      = "Жетон искателя",
    ["gm82_080"]      = "Золотой жук",
    ["gm161"]         = "Золотой жук",
    ["gm167"]         = "Жетон искателя",
    
    -- Все виды древесины теперь называются одинаково
    ["gm82_017"]      = "Куча древесины",
    ["gm82_017_01"]   = "Куча древесины",
    ["gm82_017_02"]   = "Куча древесины",
    ["gm82_017_10"]   = "Куча древесины",
    ["gm82_017_11"]   = "Куча древесины",
    ["gm82_017_12"]   = "Куча древесины",
    ["gm82_017_13"]   = "Куча древесины",
    
    ["gm82_069"]      = "Прибрежная рыба",
    ["gm82_010"]      = "Солнцецвет",
    ["gm82_011"]      = "Земляника",
    ["gm82_030"]      = "Полуденный цвет",
    ["gm81_001"]      = "Золотой жук",
    ["gm81_002"]      = "Золотой жук",
    ["gm81"]          = "Золотой жук",
    ["gm82_009_04"]   = "Утроцвет",
    ["gm82_009_02"]   = "Крупнолепестник",
    ["gm82_021"]      = "Кора горного бука",
    ["gm82_022"]      = "Кора коричника",
    ["gm82_015_01"]   = "Рудная жила",
    ["gm82_015_09"]   = "Рудная жила",
    ["gm82_015_11"]   = "Рудная жила",
    ["gm82_015_02"]   = "Рудная жила",
    ["gm82_024"]      = "Кора горного бука",
    ["gm82_009_03"]   = "Горечавка",
    ["gm82_016_11"]   = "Куча костей",
}

local rare_lookup = {
    ["Сундук с сокровищами"]        = "chest",
    ["Украшенный сундук"]           = "chest",
    ["Большой сундук"]              = "chest",
    ["Камень разлома"]              = "riftstone",
    ["Жетон искателя"]              = "token",
    ["Золотой жук"]                 = "beetle",
    ["Осколок камня пробуждения"]   = "wakestone",
}

local ignore_list = {
    ["gm80_065"] = true, ["gm80_055"] = true, ["gm80_010"] = true,
    ["gm80_129_01"] = true, ["gm80_129_02"] = true, ["gm80_131"] = true,
}

-- ── Состояние ───────────────────────────────────────────────────────────────────
local gm, im, getList, GID, all_ids
local frame       = 0
local cached_loot = {}
local depleted_cache = {}
local live_corpses = {}

local gather_context_t  = sdk.find_type_definition("app.GatherContext")
local gather_context_rt = gather_context_t and gather_context_t:get_runtime_type()
local context_db_record_get_ctx = sdk.find_type_definition("app.ContextDatabaseRecord") and
    sdk.find_type_definition("app.ContextDatabaseRecord"):get_method("getContext(System.Type)")
local intptr_t   = sdk.find_type_definition("System.IntPtr")
local ptr_offset = intptr_t and intptr_t:get_field("_value"):get_offset_from_base()
local scan_ptr_buf = nil

local function clean_name(raw)
    if not raw then return nil end
    local raw_low = tostring(raw):lower()
    
    local clean = name_lookup[raw_low]
    
    if not clean then
        local base = raw_low:match("^(%w+_%d+)")
        if base and name_lookup[base] then clean = name_lookup[base] end
    end
    
    if not clean then
        local prefix = raw_low:match("^(%w+)")
        if prefix and name_lookup[prefix] then clean = name_lookup[prefix] end
    end
    
    return clean
end

-- ── Хук смены сцены ───────────────────────────────────────────────────────────
sdk.hook(
    sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),
    nil,
    function()
        depleted_cache  = {}
        live_corpses    = {}
        cached_loot     = {}
        gm, im, getList, GID, all_ids = nil, nil, nil, nil, nil
    end
)

-- ── Хук трупов ──────────────────────────────────────────────────────────────────
pcall(function()
    sdk.hook(
        sdk.find_type_definition("app.SearchDeadBodyInteractController"):get_method("setupInteractiveObject()"),
        function(args)
            local ctrl = sdk.to_managed_object(args[2])
            if ctrl and ctrl:get_IsEnablePickup() then
                live_corpses[ctrl] = true
            end
        end,
        nil
    )
end)

-- ── Проверка менеджеров ────────────────────────────────────────────────────────
local function ensure_managers()
    gm = gm or sdk.get_managed_singleton("app.GimmickManager")
    im = im or sdk.get_managed_singleton("app.ItemManager")

    if not (getList and GID) then
        local t = sdk.find_type_definition("app.GimmickManager")
        getList = t and t:get_method("getGimmickList(app.GimmickID)")
        GID     = sdk.find_type_definition("app.GimmickID")

        if GID then
            all_ids = {}
            local fields = GID:get_fields()
            for _, f in ipairs(fields) do
                if f:is_static() then
                    local name  = f:get_name()
                    if name:find("^Gm") then
                        local n_low = name:lower()
                        local base  = n_low:match("^(%w+_%d+)") or n_low:match("^(%w+)")
                        local is_known = name_lookup[n_low] or (base and name_lookup[base])

                        if is_known and not ignore_list[n_low] then
                            table.insert(all_ids, { name = name, field = f })
                        end
                    end
                end
            end
        end
    end
    return gm ~= nil and im ~= nil and GID ~= nil
end

local function is_active_scan(g)
    if not g then return false end

    local ok_uid, uid = pcall(function() return g:get_UniqId() end)
    if ok_uid and uid and depleted_cache[uid] then return false end

    local ok_bit,  bit      = pcall(function() return g:get_IsGetFreeBit()    end)
    local ok_open, open_bit = pcall(function() return g:get_IsOpenedFreeBit() end)
    local ok_brk,  brk      = pcall(function() return g:get_IsBroken()         end)

    if (ok_bit and bit == true) or (ok_open and open_bit == true) or (ok_brk and brk == true) then
        local ok_inter, inter = pcall(function() return g:call("get_IsInteractable") end)
        if ok_inter and inter == true then return true end
        if ok_uid and uid then depleted_cache[uid] = true end
        return false
    end

    local ok_ic, ic = pcall(function() return g["<IsCollected>k__BackingField"] end)
    if ok_ic and ic == true then
        if ok_uid and uid then depleted_cache[uid] = true end
        return false
    end
    local ok_col, col = pcall(function() return g["_Collected"] end)
    if ok_col and col == true then
        if ok_uid and uid then depleted_cache[uid] = true end
        return false
    end

    local ok_t, tdef = pcall(function() return g:get_type_definition():get_name() end)
    local tdef_str   = (ok_t and type(tdef) == "string") and tdef:lower() or ""

    if tdef_str:find("gm82") then
        if gather_context_rt and context_db_record_get_ctx and intptr_t and ptr_offset then
            local ok_dbms, dbms = pcall(function() return sdk.get_managed_singleton("app.ContextDBMS") end)
            if ok_dbms and dbms then
                local ok_db, db = pcall(function() return dbms:get_CurrentDB() end)
                if ok_db and db then
                    local ok_uid2, uid2 = pcall(function() return g:get_UniqId() end)
                    if ok_uid2 and uid2 then
                        local ok_lock = pcall(function() db.Lock:readLock() end)
                        local is_depleted = false
                        pcall(function()
                            local ok_ic2, ic2 = pcall(function() return db.IndexCreator end)
                            if not ok_ic2 or not ic2 then return end
                            local ok_map, u2k = pcall(function() return ic2.UniqueID2Keys end)
                            if not ok_map or not u2k then return end

                            if not scan_ptr_buf then return end
                            scan_ptr_buf:write_qword(ptr_offset, 0)
                            if u2k:TryGetValue(uid2, scan_ptr_buf:get_address() + ptr_offset) == false then return end
                            local db_key_ptr = scan_ptr_buf:read_qword(ptr_offset)
                            if db_key_ptr == 0 then return end
                            local db_key = sdk.to_managed_object(db_key_ptr)
                            if not db_key or db_key:get_IsValid() == false then return end
                            local db_idx  = db_key.KeyForSystem
                            local records = db.Records
                            if db_idx >= records:get_Count() then return end
                            local rec = records[db_idx]:get_Record()
                            if not rec then return end
                            local ok_ctx, ctx = pcall(function()
                                return context_db_record_get_ctx(rec, gather_context_rt)
                            end)
                            if ok_ctx and ctx then
                                local ok_num, num = pcall(function() return ctx:get_Num() end)
                                if ok_num and type(num) == "number" and num <= 0 then
                                    is_depleted = true
                                end
                            end
                        end)
                        if ok_lock then pcall(function() db.Lock:readUnlock() end) end
                        
                        if is_depleted then
                            local io_overrides = false
                            pcall(function()
                                local io_obj = g.InteractiveObject
                                if io_obj then
                                    io_overrides = (io_obj:isInteractEnable(0) == true)
                                end
                            end)
                            if io_overrides then is_depleted = false end
                        end
                        
                        if is_depleted then
                            if ok_uid2 and uid2 then depleted_cache[uid2] = true end
                            return false
                        end
                    end
                end
            end
        end
    end

    if tdef_str:find("gm80") or tdef_str:find("treasure") then
        local ok_io, io_obj = pcall(function() return g.InteractiveObject end)
        if ok_io and io_obj then
            local ok_en, en = pcall(function() return io_obj:isInteractEnable(0) end)
            if ok_en and en == false then
                if ok_uid and uid then depleted_cache[uid] = true end
                return false
            end
        end
    end

    return true
end

local function is_active_realtime(g)
    if not g then return false end
    local ok_uid, uid = pcall(function() return g:get_UniqId() end)
    if ok_uid and uid and depleted_cache[uid] then return false end
    
    local ok_ic, ic = pcall(function() return g["<IsCollected>k__BackingField"] end)
    if ok_ic and ic == true then return false end
    local ok_col, col = pcall(function() return g["_Collected"] end)
    if ok_col and col == true then return false end
    
    return true
end

-- ── Сбор и обновление позиций лута ─────────────────────────────────────────
local function refresh_positions()
    if not ensure_managers() or not all_ids then return end

    scan_ptr_buf = nil
    if intptr_t and ptr_offset then
        local ok_alloc, buf = pcall(function()
            local b = intptr_t:create_instance()
            b:add_ref()
            return b
        end)
        if ok_alloc then scan_ptr_buf = buf end
    end
    local cm = sdk.get_managed_singleton("app.CharacterManager")
    local p  = cm and cm:call("get_ManualPlayer")
    if not p then return end

    local new_loot    = {}
    local seen        = {}
    local added       = 0

    -- 1. Статичные объекты мира
    for _, id_info in ipairs(all_ids) do
        local data = id_info.field:get_data(nil)
        local L    = getList:call(gm, data)
        if L then
            for i = 0, L:call("get_Count") - 1 do
                local ok_g, g = pcall(function() return L[i] end)
                if ok_g and g and is_active_scan(g) then
                    local ok_addr, addr = pcall(function() return g:get_address() end)
                    if ok_addr and addr and not seen[addr] then
                        seen[addr] = true
                        local displayName = clean_name(id_info.name)
                        if displayName then
                            local ok_go, go = pcall(function() return g:call("get_GameObject") end)
                            if ok_go and go then
                                local ok_pos, pos = pcall(function() return go:get_Transform():call("get_Position") end)
                                if ok_pos and pos then
                                    table.insert(new_loot, {
                                        pos     = pos,
                                        name    = displayName,
                                        gimmick = g,
                                        color   = config.color,
                                    })
                                    added = added + 1
                                end
                            end
                        end
                    end
                end
                if added >= config.max_markers then break end
            end
        end
        if added >= config.max_markers then break end
    end

    -- 2. Выпавшие мешки с трофеями
    if config.show_enemy_drops and im then
        local drop_list = im:call("get_DropItemList")
        if drop_list then
            for i = 0, drop_list:call("get_Count") - 1 do
                local drop = drop_list[i]
                if drop then
                    local ok_addr, addr = pcall(function() return drop:get_address() end)
                    if ok_addr and addr and not seen[addr] then
                        seen[addr] = true
                        local ok_go, go = pcall(function() return drop:call("get_GameObject") end)
                        if ok_go and go then
                            local ok_draw, draw_self = pcall(function() return go:call("get_DrawSelf") end)
                            if ok_draw and draw_self then
                                local name = "Выпавший трофей"
                                local ok_p, ip = pcall(function() return drop:call("get_ItemParam") end)
                                if ok_p and ip then
                                    local ok_n, iname = pcall(function() return ip:call("get_Name") end)
                                    if ok_n and iname and not iname:match("^[%d_%-]+$") then 
                                        name = iname 
                                    end
                                end
                                local ok_pos, pos = pcall(function() return go:get_Transform():call("get_Position") end)
                                if ok_pos and pos then
                                    table.insert(new_loot, {
                                        pos     = pos,
                                        name    = name,
                                        gimmick = drop,
                                        color   = config.color,
                                    })
                                    added = added + 1
                                end
                            end
                        end
                    end
                end
                if added >= config.max_markers then break end
            end
        end
    end

    -- 3. Динамические точки сбора
    if gm then
        for _, method_name in ipairs({"get_CollectionGimmicks", "get_DropItemGimmicks"}) do
            local ok_list, list = pcall(function() return gm:call(method_name) end)
            if ok_list and list then
                local count = 0
                local ok_ct = pcall(function() count = list:call("get_Count") end)
                if ok_ct and count > 0 then
                    for i = 0, count - 1 do
                        local ok_g, g = pcall(function() return list[i] end)
                        if ok_g and g and is_active_scan(g) then
                            local ok_addr, addr = pcall(function() return g:get_address() end)
                            if ok_addr and addr and not seen[addr] then
                                seen[addr] = true
                                local ok_go, go = pcall(function() return g:call("get_GameObject") end)
                                if ok_go and go then
                                    local ok_n, n = pcall(function() return go:call("get_Name") end)
                                    local nm = n and clean_name(n) or "Точка сбора"
                                    
                                    local ok_pos, pos = pcall(function() return go:get_Transform():call("get_Position") end)
                                    if ok_pos and pos then
                                        table.insert(new_loot, {
                                            pos     = pos,
                                            name    = nm,
                                            gimmick = g,
                                            color   = config.color,
                                        })
                                        added = added + 1
                                    end
                                end
                            end
                        end
                        if added >= config.max_markers then break end
                    end
                end
            end
            if added >= config.max_markers then break end
        end
    end

    -- 4. Тела врагов
    if config.show_enemy_drops then
        local stale = {}
        for ctrl, _ in pairs(live_corpses) do
            local valid = false
            pcall(function()
                if not sdk.is_managed_object(ctrl) then return end
                if not ctrl:get_IsEnablePickup()   then return end

                local chara = ctrl.Chara
                if not chara then return end
                local go = chara:get_GameObject()
                if not go then return end
                local pos = go:get_Transform():get_Position()
                if not pos then return end

                local nm = "Поверженный враг"

                local addr_ok, addr = pcall(function() return ctrl:get_address() end)
                if addr_ok and addr and not seen[addr] then
                    seen[addr] = true
                    table.insert(new_loot, {
                        pos     = pos,
                        name    = nm,
                        gimmick = nil,
                        ctrl    = ctrl,
                        color   = config.color,
                    })
                    added = added + 1
                    valid = true
                else
                    valid = true  
                end
            end)
            if not valid then stale[ctrl] = true end
        end
        for ctrl, _ in pairs(stale) do
            live_corpses[ctrl] = nil
        end
    end

    cached_loot = new_loot
end

-- ── UI REFramework ──────────────────────────────────────────────────────────
re.on_draw_ui(function()
    if imgui.tree_node("Локатор лута") then
        local c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12
        c1, config.enabled          = imgui.checkbox("Включить локатор лута", config.enabled)
        c2, config.show_names       = imgui.checkbox("Показывать названия предметов", config.show_names)
        c3, config.show_enemy_drops = imgui.checkbox("Показывать трофеи и поверженных врагов", config.show_enemy_drops)
        c7, config.show_rare_only   = imgui.checkbox("Только редкие находки", config.show_rare_only)
        if config.show_rare_only then
            imgui.indent()
            local cf1, cf2, cf3, cf4, cf5 = false, false, false, false, false
            cf1, config.filter_tokens     = imgui.checkbox("Жетоны искателя",     config.filter_tokens)
            cf2, config.filter_beetles    = imgui.checkbox("Золотые жуки",        config.filter_beetles)
            cf3, config.filter_chests     = imgui.checkbox("Сундуки",             config.filter_chests)
            cf4, config.filter_riftstones = imgui.checkbox("Камни разлома",        config.filter_riftstones)
            cf5, config.filter_wakestones = imgui.checkbox("Осколки камней пробуждения", config.filter_wakestones)
            imgui.unindent()
            if cf1 or cf2 or cf3 or cf4 or cf5 then save_config() end
        end
        c8, config.use_symbols      = imgui.checkbox("Использовать значки вместо текста (◈)", config.use_symbols)
        if config.use_symbols then
            imgui.begin_disabled()
            imgui.checkbox("Показывать расстояние [Недоступно при значках]", false)
            imgui.end_disabled()
        else
            c9, config.show_distance    = imgui.checkbox("Показывать расстояние до цели", config.show_distance)
        end
        c11, config.show_edge_arrows = imgui.checkbox("Включить круговой радар у краев экрана", config.show_edge_arrows)
        local c13 = false
        if config.show_edge_arrows then
            c13, config.radar_radius = imgui.slider_float("Радиус радара", config.radar_radius, 100.0, 1000.0)
        end
        c4, config.max_distance     = imgui.slider_float("Макс. дистанция отображения", config.max_distance, 5.0, 200.0)
        c5, config.height_offset    = imgui.slider_float("Высота смещения меток", config.height_offset, 0.0, 3.0)
        c6, config.color            = imgui.color_edit_argb("Цвет обычных предметов", config.color)
        c10, config.color_rare      = imgui.color_edit_argb("Цвет ценных находок", config.color_rare)

        if c1 or c2 or c3 or c4 or c5 or c6 or c7 or c8 or c9 or c10 or c11 or c13 then
            save_config()
        end
        imgui.tree_pop()
    end
end)

-- ── Цикл отрисовки (ИСПРАВЛЕНО: убрана принудительная замена на "Растение") ───
re.on_frame(function()
    if not config.enabled then return end
    if not ensure_managers() then return end

    frame = frame + 1
    if frame % config.scan_interval == 0 then refresh_positions() end

    local cm = sdk.get_managed_singleton("app.CharacterManager")
    if not cm then return end
    
    local p, p_go, ppos
    local ok_player = pcall(function()
        p = cm:call("get_ManualPlayer")
        if p then p_go = p:call("get_GameObject") end
        if p_go then ppos = p_go:get_Transform():call("get_Position") end
    end)
    
    if not ok_player or not ppos then return end
    
    local d2max = config.max_distance * config.max_distance
    local screen_size = imgui.get_display_size()
    local sw, sh = screen_size.x, screen_size.y

    for _, data in ipairs(cached_loot) do
        if data.ctrl then
            local alive = false
            pcall(function()
                alive = sdk.is_managed_object(data.ctrl) and data.ctrl:get_IsEnablePickup()
            end)
            if not alive then goto continue end
        elseif data.gimmick then
            if not is_active_realtime(data.gimmick) then goto continue end
        end

        local pos = data.pos
        local dx, dy, dz = pos.x - ppos.x, pos.y - ppos.y, pos.z - ppos.z
        local dist_sq = dx*dx + dy*dy + dz*dz
        if dist_sq < d2max then
            local category = rare_lookup[data.name]
            local is_rare  = category ~= nil

            if config.show_rare_only then
                if not is_rare then goto continue end
                if category == "token"     and not config.filter_tokens    then goto continue end
                if category == "beetle"    and not config.filter_beetles   then goto continue end
                if category == "chest"     and not config.filter_chests    then goto continue end
                if category == "riftstone" and not config.filter_riftstones then goto continue end
                if category == "wakestone"     and not config.filter_wakestones then goto continue end
            end

            local base_name = data.name
            -- ИСПРАВЛЕНИЕ: Мягкий дефолт без искажения кучи костей/дров
            if not base_name or base_name == "" or base_name:match("^gm%d+") or base_name:match("^[%d_%-]+$") then
                base_name = "Точка сбора"
            end

            if config.use_symbols then
                base_name = "◈"
            end
            local label = config.show_names and base_name or "●"

            if config.show_distance and not config.use_symbols and config.show_names then
                local dist_m = math.floor(math.sqrt(dist_sq) + 0.5)
                label = label .. " [" .. dist_m .. "м]"
            end

            local col = is_rare and config.color_rare or (data.color or config.color)
            local draw_pos = Vector3f.new(pos.x, pos.y + config.height_offset, pos.z)

            local is_offscreen = false
            local sx, sy = -1, -1
            
            local screen_pos = draw.world_to_screen(draw_pos)
            if screen_pos then
                sx, sy = screen_pos.x, screen_pos.y
                if sx < 0 or sx > sw or sy < 0 or sy > sh then
                    is_offscreen = true
                end
            else
                is_offscreen = true
            end

            -- Радар
            if is_offscreen and config.show_edge_arrows then
                local cx, cy = sw / 2, sh / 2
                local dx = draw_pos.x - ppos.x
                local dy = draw_pos.y - ppos.y
                local dz = draw_pos.z - ppos.z
                
                local camera = sdk.get_primary_camera()
                local x, y, z, w = 0, 0, 0, 1
                if camera then
                    local rot = camera:get_GameObject():get_Transform():get_Rotation()
                    if rot then x, y, z, w = rot.x, rot.y, rot.z, rot.w end
                end
                
                local r_x = 1 - 2 * (y*y + z*z)
                local r_z = 2 * (x*z - w*y)
                local f_x = 2 * (x*z + w*y)
                local f_z = 1 - 2 * (x*x + y*y)
                
                local proj_right = dx * r_x + dz * r_z
                local proj_fwd   = dx * f_x + dz * f_z
                
                local atan2 = math.atan2 or math.atan
                local angle = atan2(proj_fwd, proj_right)
                
                local radius = config.radar_radius
                local ax = cx + math.cos(angle) * radius
                local ay = cy + math.sin(angle) * radius
                
                local pi = math.pi
                local a = angle
                if a < 0 then a = a + 2 * pi end
                local slice = (a + pi/8) / (pi/4)
                local idx = math.floor(slice) % 8 + 1
                local arrows = {"▶", "◢", "▼", "◣", "◀", "◤", "▲", "◥"}
                
                draw.text(arrows[idx], ax, ay, col)
                goto continue
            end

            -- Вывод текста
            if screen_pos and not is_offscreen then
                draw.text(label, sx, sy, col)
            end
        end
        ::continue::
    end
end)

log.info("[LootLocator] dd2_loot_locator успешно загружен.")
-- ╔══════════════════════════════════════════════════════════════╗
-- ║              Combined Mods - Dragon's Dogma 2                ║
-- ╚══════════════════════════════════════════════════════════════╝
local sdk = sdk
local log = log
local json = json
local re = re
local imgui = imgui
local hk = require("Hotkeys.Hotkeys")
local HelpersA = {}
do
    function HelpersA.GetCharacterManager()
        return sdk.get_managed_singleton("app.CharacterManager")
    end

    function HelpersA.gm_pla_hum_char()
        local cm = sdk.get_managed_singleton("app.CharacterManager")
        if not cm then return nil, nil, nil end
        local p_player = cm:get_field("<ManualPlayerPlayer>k__BackingField")
        local p_human = cm:get_field("<ManualPlayerHuman>k__BackingField")
        local p_character = cm:get_field("<ManualPlayer>k__BackingField")
        return p_player, p_human, p_character
    end

    function HelpersA.get_app_pawn_list()
        local result = {}
        local pm = sdk.get_managed_singleton("app.PawnManager")
        if not pm then return result end
        local pawnList = pm:get_field("_PartyPawnList")
        if not pawnList then return result end
        local items = pawnList:get_field("_items")
        if not items then return result end
        local arr_elems = items:get_elements()
        if not arr_elems then return result end
        local count = pawnList:call("get_Count") or #arr_elems
        for i = 1, math.min(count, #arr_elems) do
            if arr_elems[i] then table.insert(result, arr_elems[i]) end
        end
        return result
    end

    function HelpersA.get_pawn_chara_list()
        local pawns = HelpersA.get_app_pawn_list()
        local result = {}
        for _, pawn in ipairs(pawns) do
            local character = pawn:get_field("<CachedCharacter>k__BackingField")
            if character then table.insert(result, character) end
        end
        return result
    end

    function HelpersA.get_pawn_human_list()
        local pawns = HelpersA.get_app_pawn_list()
        local result = {}
        for _, pawn in ipairs(pawns) do
            local human = pawn:get_field("<CachedHuman>k__BackingField")
            if human then table.insert(result, human) end
        end
        return result
    end

    function HelpersA.get_main_app_pawn()
        local pm = sdk.get_managed_singleton("app.PawnManager")
        if not pm then return nil end
        return pm:get_field("_MainPawn")
    end

    function HelpersA.get_main_pawn_chara()
        local pawn = HelpersA.get_main_app_pawn()
        if not pawn then return nil end
        return pawn:get_field("<CachedCharacter>k__BackingField") or pawn:call("get_CachedCharacter")
    end

    function HelpersA.get_main_pawn_human()
        local pawn = HelpersA.get_main_app_pawn()
        if not pawn then return nil end
        return pawn:get_field("<CachedHuman>k__BackingField") or pawn:call("get_CachedHuman")
    end
end

-- ════════════════════════════════════════════════════════════════
-- 1. ARCHER FAST AIM (БЫСТРОЕ ПРИЦЕЛИВАНИЕ ЛУЧНИКА)
-- ════════════════════════════════════════════════════════════════
local ArcherFastAim = {}
do
    local config_file = "archer_fast_aim.json"
    local config = { enabled = false, aim_draw_ratio = 1.0, draw_keep_time = 1000.0 }

    local function load_config()
        local success, loaded = pcall(function() return json.load_file(config_file) end)
        if success and loaded then
            if type(loaded.enabled) == 'boolean' then config.enabled = loaded.enabled end
            if type(loaded.aim_draw_ratio) == 'number' then config.aim_draw_ratio = loaded.aim_draw_ratio end
            if type(loaded.draw_keep_time) == 'number' then config.draw_keep_time = loaded.draw_keep_time end
        end
    end

    local function save_config()
        pcall(function() json.dump_file(config_file, config) end)
    end

    load_config()

    local function is_aiming_node(node_name, human)
        if not node_name then return false end
        local name = tostring(node_name):lower()
        if name:find("locomotion.strafe") then
            if human and human:get_IsDrawedWeapon() then return true end
        end
        return false
    end

    local motion_fsm2_type = sdk.typeof("via.motion.MotionFsm2")
    local function process_human(human)
        if not human then return end
        local go = human:call("get_GameObject")
        if not go then return end
        local motion_fsm2 = go:call("getComponent(System.Type)", motion_fsm2_type)
        if motion_fsm2 then
            local current_node = motion_fsm2:getCurrentNodeName(0)
            if current_node and is_aiming_node(current_node, human) then
                local current_ratio = human:get_field("_DrawBowRatio")
                if current_ratio and current_ratio < config.aim_draw_ratio then
                    human:set_field("_DrawBowRatio", config.aim_draw_ratio)
                end
                human:set_field("DrawBowKeepTimer", config.draw_keep_time)
            else
                local current_timer = human:get_field("DrawBowKeepTimer")
                if current_timer and current_timer > 0.0 then
                    human:set_field("DrawBowKeepTimer", 0.0)
                end
            end
        end
    end

    re.on_application_entry("LateUpdateBehavior", function()
        if not config.enabled then return end
        local _, player_human = HelpersA.gm_pla_hum_char()
        local pawns = HelpersA.get_pawn_human_list()

        if player_human then process_human(player_human) end
        for _, pawn in ipairs(pawns) do process_human(pawn) end
    end)

    function ArcherFastAim.draw_ui()
        if imgui.tree_node("Быстрое прицеливание лучника") then
            local changed = false
            local c1, v1 = imgui.checkbox("Включить быстрое прицеливание", config.enabled)
            if c1 then
                config.enabled = v1; changed = true
            end
            if config.enabled then
                imgui.text("Выстрел при прицеливании (Твёрдый лук)")
                local c3, v3 = imgui.drag_float("Натяжение при прицеливании (Мгновенно)", config.aim_draw_ratio, 0.05, 0.0, 1.0)
                if c3 then
                    config.aim_draw_ratio = v3; changed = true
                end
                imgui.text("Время удержания — влияет на дальность и силу полёта стрелы.")
                local c4, v4 = imgui.drag_float("Удержание прицела (Таймер удержания)", config.draw_keep_time, 0.1, 0.0,
                    120.0)
                if c4 then
                    config.draw_keep_time = v4; changed = true
                end
            end
            if changed then save_config() end
            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 2. ENABLE SKILLS (РАЗБЛОКИРОВКА НАВЫКОВ)
-- ════════════════════════════════════════════════════════════════
local EnableSkillsMod = {}
do
    local SKILL_ID_OFFSET     = 0x10
    local SKILL_ENABLE_OFFSET = 0x14
    local SKILL_LEVEL_OFFSET  = 0x14
    local START_ID_NORMAL     = 4
    local END_ID_NORMAL       = 37
    local START_ID_CUSTOM     = 1
    local END_ID_CUSTOM       = 101
    local CUSTOM_SKILL_LEVEL  = 2
    local START_ID_ABILITY    = 4
    local END_ID_ABILITY      = 50
    local MEISTER_IDS         = {
        [12] = true,
        [23] = true,
        [37] = true,
        [42] = true,
        [61] = true,
        [68] = true,
        [69] = true,
        [79] = true,
        [91] = true,
        [99] = true,
        [100] = true,
        [101] = true
    }

    local config              = json.load_file('enable_skills.json') or {}
    if config.NormalEnabled == nil then config.NormalEnabled = true end
    if config.AbilitiesEnabled == nil then config.AbilitiesEnabled = true end
    if config.CustomMode == nil then config.CustomMode = 1 end
    if config.ApplyToPawns == nil then config.ApplyToPawns = true end

    local function ProcessCharacterWeaponOnly(char, label)
        if not char then return end
        if config.CustomMode == 0 then return end
        local human = char:get_field("<Human>k__BackingField") or
            char:get_field("Human") or char:call("get_Human") or char:call("get_CachedHuman") or char
        local skill_context = human:get_field("<SkillContext>k__BackingField") or
            human:call("get_SkillContext") or human:call("get_HumanSkillContext") or human:read_ptr(0x380)
        if not skill_context then return end
        local custom_skills = skill_context:get_field("EnabledCustomSkills") or skill_context:read_ptr(0x28)
        if not custom_skills then return end
        local count = custom_skills:call("get_Count")
        if not count or count == 0 then return end
        for i = 0, count - 1 do
            local item = custom_skills:call("get_Item", i)
            if item then
                local id = item:read_dword(SKILL_ID_OFFSET)
                local is_meister = MEISTER_IDS[id] == true
                if config.CustomMode == 1 then
                    if not is_meister and id >= START_ID_CUSTOM and id <= END_ID_CUSTOM then
                        item:write_dword(SKILL_LEVEL_OFFSET, CUSTOM_SKILL_LEVEL)
                    end
                elseif config.CustomMode == 2 then
                    if is_meister then
                        item:write_dword(SKILL_LEVEL_OFFSET, 1)
                    elseif id >= START_ID_CUSTOM and id <= END_ID_CUSTOM then
                        item:write_dword(SKILL_LEVEL_OFFSET, CUSTOM_SKILL_LEVEL)
                    end
                elseif config.CustomMode == 3 then
                    if id >= START_ID_CUSTOM and id <= END_ID_CUSTOM then
                        item:write_dword(SKILL_LEVEL_OFFSET, 0)
                    end
                end
            end
        end
    end

    local function ProcessCharacterNoWeapon(char, label)
        if not char then return end
        local human = char:get_field("<Human>k__BackingField") or
            char:get_field("Human") or char:call("get_Human") or char:call("get_CachedHuman") or char
        local skill_context = human:get_field("<SkillContext>k__BackingField") or
            human:call("get_SkillContext") or human:call("get_HumanSkillContext") or human:read_ptr(0x380)
        if skill_context then
            if config.NormalEnabled then
                local normal_skills = skill_context:get_field("EnableNormalSkills") or skill_context:read_ptr(0x20)
                if normal_skills then
                    local count = normal_skills:call("get_Count")
                    if count and count > 0 then
                        for i = 0, count - 1 do
                            local item = normal_skills:call("get_Item", i)
                            if item then
                                local id = item:read_dword(SKILL_ID_OFFSET)
                                if id >= START_ID_NORMAL and id <= END_ID_NORMAL then
                                    item:write_byte(SKILL_ENABLE_OFFSET, 1)
                                end
                            end
                        end
                    end
                end
            end
        end
        if config.AbilitiesEnabled then
            local ability_context = human:get_field("<AbilityContext>k__BackingField") or
                human:call("get_AbilityContext") or human:read_ptr(0x3D0)
            if ability_context then
                local abilities = ability_context:get_field("EnableAbilities") or ability_context:read_ptr(0x20)
                if abilities then
                    local count = abilities:call("get_Count")
                    if count and count > 0 then
                        for i = 0, count - 1 do
                            local item = abilities:call("get_Item", i)
                            if item then
                                local id = item:read_dword(0x10)
                                if id >= START_ID_ABILITY and id <= END_ID_ABILITY then
                                    item:write_byte(0x14, 1)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local function RunWithTargets(zzz)
        local _, p_human, p_character = HelpersA.gm_pla_hum_char()
        local player_target = p_human or p_character
        if player_target then zzz(player_target, "Player") end
        if config.ApplyToPawns then
            local pawns = HelpersA.get_pawn_human_list()
            for i, pawn in ipairs(pawns) do zzz(pawn, "Pawn " .. (i - 1)) end
        end
    end

    local weapon_mode_names = { "Отключено", "Открыть все без Мейстеров", "Открыть абсолютно все", "Удалить все навыки" }
    local weapon_mode_tooltips = {
        "Никаких изменений для оружейных навыков",
        "Открыть все оружейные навыки, кроме уникальных приёмов Мейстеров",
        "Открыть абсолютно все навыки оружия, включая навыки Мейстеров",
        "Полностью удалить/сбросить все оружейные навыки, включая навыки Мейстеров"
    }

    function EnableSkillsMod.draw_ui()
        if imgui.tree_node("Разблокировщик навыков") then
            local cfg_changed = false
            imgui.separator()
            changed, val = imgui.checkbox("Применить к пешкам (Основной и нанятым)", config.ApplyToPawns)
            if changed then
                config.ApplyToPawns = val; cfg_changed = true
            end
            imgui.separator()
            local changed, val = imgui.checkbox("Открыть все базовые умения (Core Skills)", config.NormalEnabled)
            if changed then
                config.NormalEnabled = val; cfg_changed = true
            end
            imgui.separator()
            changed, val = imgui.checkbox("Открыть все пассивные навыки (Augments)", config.AbilitiesEnabled)
            if changed then
                config.AbilitiesEnabled = val; cfg_changed = true
            end
            if imgui.button("Разблокировать базовые и пассивные сейчас") then RunWithTargets(ProcessCharacterNoWeapon) end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Открывает только базовые умения и пассивки (без боевых приемов оружия)")
            end
            imgui.separator()

            imgui.text("Режим боевых навыков оружия:")
            local combo_changed, combo_val = imgui.combo("##WeaponMode", config.CustomMode + 1, weapon_mode_names)
            if combo_changed then
                config.CustomMode = combo_val - 1; cfg_changed = true
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip(weapon_mode_tooltips[config.CustomMode + 1])
            end

            if imgui.button("Применить режим боевых навыков") then RunWithTargets(ProcessCharacterWeaponOnly) end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Применяет выбранный выше режим к оружейным слотам")
            end
            if cfg_changed then
                json.dump_file('enable_skills.json', config)
            end
            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 3. INSTANT CHARGE (МГНОВЕННАЯ ЗАРЯДКА/КАСТ)
-- ════════════════════════════════════════════════════════════════
local InstantCharge = {}
do
    local config_file = "instant_charge.json"
    local config = {
        enabled = false,
        instant_gungnir = false,
        gungnir_multiplier = 10.0,
        block_job01_tusk_toss = true,
        block_job05_prepare_normal_attack = true,
        block_jobmagicuser_prepare_normal_shot = true,
    }

    local function load_config()
        local success, loaded = pcall(function() return json.load_file(config_file) end)
        if success and loaded then
            if type(loaded.enabled) == 'boolean' then config.enabled = loaded.enabled end
            if type(loaded.instant_gungnir) == 'boolean' then config.instant_gungnir = loaded.instant_gungnir end
            if type(loaded.gungnir_multiplier) == 'number' then config.gungnir_multiplier = loaded.gungnir_multiplier end
            if type(loaded.block_job01_tusk_toss) == 'boolean' then
                config.block_job01_tusk_toss = loaded
                    .block_job01_tusk_toss
            end
            if type(loaded.block_job05_prepare_normal_attack) == 'boolean' then
                config.block_job05_prepare_normal_attack =
                    loaded.block_job05_prepare_normal_attack
            end
            if type(loaded.block_jobmagicuser_prepare_normal_shot) == 'boolean' then
                config.block_jobmagicuser_prepare_normal_shot =
                    loaded.block_jobmagicuser_prepare_normal_shot
            end
        end
    end

    local function save_config() pcall(function() json.dump_file(config_file, config) end) end
    load_config()

    local blocked_until = {}
    local job01_block_duration = 0.35
    local job05_block_duration = 0.30
    local jobmagicuser_block_duration = 0.30

    local function get_go_addr(obj)
        local go = obj:get_GameObject()
        return go and go:get_address() or nil
    end

    local function is_player_or_pawn(human)
        if not human then return false end
        local h_go_addr = get_go_addr(human)
        local h_addr = human:get_address()
        local _, player_human = HelpersA.gm_pla_hum_char()
        if player_human then
            if player_human == human or player_human:get_address() == h_addr then return true end
            if h_go_addr and h_go_addr == get_go_addr(player_human) then return true end
        end
        local pawns = HelpersA.get_pawn_human_list()
        for _, p_human in ipairs(pawns) do
            if p_human == human or p_human:get_address() == h_addr then return true end
            if h_go_addr and h_go_addr == get_go_addr(p_human) then return true end
        end
        return false
    end

    local function block_human_for(human, duration_sec)
        if not human then return end
        local addr = human:get_address()
        if not addr then return end
        local now = os.clock()
        local until_time = now + (duration_sec or 0.25)
        local prev = blocked_until[addr] or 0
        if until_time > prev then blocked_until[addr] = until_time end
    end

    local function is_human_blocked(human)
        if not human then return false end
        local addr = human:get_address()
        if not addr then return false end
        local until_time = blocked_until[addr]
        if not until_time then return false end
        if os.clock() > until_time then
            blocked_until[addr] = nil; return false
        end
        return true
    end

    local function apply_fast_chant(human)
        if not human then return end
        if is_human_blocked(human) then return end
        local sec_prepare = human:get_field("SecPrepareSkill")
        if sec_prepare and sec_prepare > 0 then
            human:set_field("<TimerPrepareSkill>k__BackingField", sec_prepare)
        end
    end

    local job01_input_type = sdk.find_type_definition("app.Job01InputProcessor")
    if job01_input_type then
        local methods = job01_input_type:get_methods()
        if methods then
            for _, method in pairs(methods) do
                local method_name = method:get_name()
                if method_name and (method_name:find("processTuskToss", 1, true) or method_name:find("startTuskToss", 1, true) or method_name:find("updateTuskToss", 1, true) or method_name:find("checkTuskTossInput", 1, true)) then
                    sdk.hook(method, function(_)
                        if not config.enabled or not config.block_job01_tusk_toss then return end
                        local _, player_human = HelpersA.gm_pla_hum_char()
                        if player_human then block_human_for(player_human, job01_block_duration) end
                    end, function(retval) return retval end)
                end
            end
        end
    end

    local job05_prepare_type = sdk.find_type_definition("app.Job05PrepareNormalAttack")
    if job05_prepare_type then
        local update_method = job05_prepare_type:get_method("update(via.behaviortree.ActionArg)")
        if update_method then
            local function job05_hook_logic(args)
                if not config.enabled or not config.block_job05_prepare_normal_attack then return end
                local this = sdk.to_managed_object(args[2])
                if not this then return end
                local human = this:get_field("Human")
                if not human or not is_player_or_pawn(human) then return end
                block_human_for(human, job05_block_duration)
            end
            sdk.hook(update_method, function(args)
                job05_hook_logic(args)
            end, function(retval) return retval end)
        end
    end

    local magicuser_prepare_type = sdk.find_type_definition("app.JobMagicUserPrepareNormalShot")
    if magicuser_prepare_type then
        local update_method = magicuser_prepare_type:get_method("update(via.behaviortree.ActionArg)")
        if update_method then
            local function magicuser_hook_logic(args)
                if not config.enabled or not config.block_jobmagicuser_prepare_normal_shot then return end
                local this = sdk.to_managed_object(args[2])
                if not this then return end
                local human = this:get_field("Human")
                if not human or not is_player_or_pawn(human) then return end
                block_human_for(human, jobmagicuser_block_duration)
            end
            sdk.hook(update_method, function(args)
                magicuser_hook_logic(args)
            end, function(retval) return retval end)
        end
    end

    re.on_frame(function()
        if not config.enabled then return end
        local _, player_human = HelpersA.gm_pla_hum_char()
        if player_human then apply_fast_chant(player_human) end
        local pawns = HelpersA.get_pawn_human_list()
        for _, p_human in ipairs(pawns) do apply_fast_chant(p_human) end
    end)

    local gungnir_type = sdk.find_type_definition("app.Job07Gungnir")
    if gungnir_type then
        local gungnir_update = gungnir_type:get_method("update(via.behaviortree.ActionArg)")
        if gungnir_update then
            local function gungnir_hook_logic(args)
                if not config.instant_gungnir then return end
                local this = sdk.to_managed_object(args[2])
                if not this then return end
                local human = this:get_field("Human")
                if not human or not is_player_or_pawn(human) then return end
                local consume = this:get_field("ConsumeStamina")
                if consume and type(consume) == "number" and consume > 0 then
                    this:set_field("ConsumeStamina", consume * config.gungnir_multiplier)
                end
            end
            sdk.hook(gungnir_update, function(args)
                gungnir_hook_logic(args)
            end, function(retval) return retval end)
        end
    end

    function InstantCharge.draw_ui()
        if imgui.tree_node("Мгновенный каст / Зарядка") then
            local changed = false
            imgui.separator()
            local c1, v1 = imgui.checkbox("Активировать мгновенное чтение заклинаний и умений", config.enabled)
            if c1 then
                config.enabled = v1; changed = true
            end
            imgui.separator()
            if config.enabled then
                imgui.text("Исключить указанные ниже навыки из мгновенной зарядки:")
                local c4, v4 = imgui.checkbox("Исключить навык Бойца: Подброс на щит (Tusk Toss)", config.block_job01_tusk_toss)
                if c4 then
                    config.block_job01_tusk_toss = v4; changed = true
                end
                local c5, v5 = imgui.checkbox("Исключить навык Воина: Мощный замах (Mighty Sweep)",
                    config.block_job05_prepare_normal_attack)
                if c5 then
                    config.block_job05_prepare_normal_attack = v5; changed = true
                end
                local c6, v6 = imgui.checkbox("Исключить усиленные выстрелы Мага и Колдуна",
                    config.block_jobmagicuser_prepare_normal_shot)
                if c6 then
                    config.block_jobmagicuser_prepare_normal_shot = v6; changed = true
                end
            end

            if config.enabled then
                local c2, v2 = imgui.checkbox("Включить мгновенную магию Лучника-мага", config.instant_gungnir)
                if c2 then
                    config.instant_gungnir = v2; changed = true
                end
                if config.instant_gungnir then
                    local c3, v3 = imgui.slider_float("Множитель скорости магии", config.gungnir_multiplier, 1.0, 10.0)
                    if c3 then
                        config.gungnir_multiplier = v3; changed = true
                    end
                end
            end
            if changed then save_config() end
            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 4. LOCK-ON RANGE MOD (ДАЛЬНОСТЬ ЗАХВАТА ЦЕЛИ)
-- ════════════════════════════════════════════════════════════════
local LockOnRange = {}
do
    local config_file = "lock_on_range_mod.json"
    local config = { enabled = false, multiplier = 2.0 }
    local base_values = { job_ranges = {}, max_distances = {}, ranges = {} }
    local last_applied_multiplier = nil

    local function load_config()
        local success, loaded = pcall(function() return json.load_file(config_file) end)
        if success and loaded then
            if type(loaded.enabled) == 'boolean' then config.enabled = loaded.enabled end
            if type(loaded.multiplier) == 'number' then config.multiplier = loaded.multiplier end
        end
    end
    local function save_config() pcall(function() json.dump_file(config_file, config) end) end
    load_config()

    local function apply_mod()
        local current_multiplier = config.enabled and config.multiplier or 1.0
        if last_applied_multiplier == current_multiplier then return end
        local _, human = HelpersA.gm_pla_hum_char()
        if not human then return end
        local human_param = human:get_field("Parameter")
        if not human_param then return end
        local list_wrapper = human_param:get_field("LockOnRangeParam")
        if not list_wrapper then return end
        local parameters = list_wrapper:get_field("Parameters")
        if not parameters then return end
        local size = parameters:call("get_Count") or parameters:call("get_Length")
        if not size then return end
        for i = 0, size - 1 do
            local entry = parameters[i]
            if entry then
                if base_values.job_ranges[i] == nil then
                    base_values.job_ranges[i] = {
                        dark_max = entry:get_field("MaxLockOnRangeTargetDark"),
                        dark_abort = entry:get_field("AbortLockOnRangeTargetDark"),
                        grass_max = entry:get_field("MaxLockOnRangeTargetInGrass"),
                        grass_abort = entry:get_field("AbortLockOnRangeTargetInGrass")
                    }
                end
                if (last_applied_multiplier ~= current_multiplier) and base_values.job_ranges[i].dark_max then
                    local bv = base_values.job_ranges[i]
                    entry:set_field("MaxLockOnRangeTargetDark", bv.dark_max * current_multiplier)
                    entry:set_field("AbortLockOnRangeTargetDark", bv.dark_abort * current_multiplier)
                    entry:set_field("MaxLockOnRangeTargetInGrass", bv.grass_max * current_multiplier)
                    entry:set_field("AbortLockOnRangeTargetInGrass", bv.grass_abort * current_multiplier)
                end
                local type_params = entry:get_field("Parameters")
                if type_params then
                    local tp_size = type_params:call("get_Count") or type_params:call("get_Length")
                    for tp_idx = 0, tp_size - 1 do
                        local tp_entry = type_params[tp_idx]
                        if tp_entry then
                            local tp_key = i .. "_" .. tp_idx
                            if base_values.max_distances[tp_key] == nil then
                                base_values.max_distances[tp_key] = tp_entry:get_field("MaxDistance")
                            end
                            if (last_applied_multiplier ~= current_multiplier) and base_values.max_distances[tp_key] then
                                tp_entry:set_field("MaxDistance", base_values.max_distances[tp_key] * current_multiplier)
                            end
                            local ranges = tp_entry:get_field("Ranges")
                            if ranges then
                                local r_size = ranges:get_size()
                                for range_idx = 0, r_size - 1 do
                                    local range = ranges[range_idx]
                                    if range then
                                        local key = string.format("%d_%d_%d", i, tp_idx, range_idx)
                                        if base_values.ranges[key] == nil then
                                            base_values.ranges[key] = range:get_field("Distance")
                                        end
                                        if last_applied_multiplier ~= current_multiplier and base_values.ranges[key] then
                                            range:set_field("Distance", base_values.ranges[key] * current_multiplier)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        last_applied_multiplier = current_multiplier
    end

    re.on_frame(apply_mod)

    function LockOnRange.draw_ui()
        if imgui.tree_node("Множитель дистанции захвата (Lock-On)") then
            local changed = false
            local c1, v1 = imgui.checkbox("Включено##LockOn", config.enabled)
            if c1 then
                config.enabled = v1; changed = true
            end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Увеличивает максимальное расстояние для автозахвата целей у всех персонажей")
            end
            if config.enabled then
                local c2, v2 = imgui.drag_float("Множитель расстояния", config.multiplier, 0.01, 0.1, 10.0)
                if c2 then
                    config.multiplier = v2; changed = true
                end
                if imgui.is_item_hovered() then
                    imgui.set_tooltip(
                        "Коэффициент для всех дистанций прицеливания (В темноте, в траве и т.д.). x1.0 = Стандарт")
                end
            end
            if changed then save_config() end
            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 5. MAGIC ARCHER BUFF (БАФФ МАГИЧЕСКОГО ЛУЧНИКА)
-- ════════════════════════════════════════════════════════════════
local MagicArcherBuff = {}
do
    local config_file = "magic_archer_buff.json"
    local config = { enabled = false, lock_on_count = 100, lock_on_frame = 0.01 }

    local function load_config()
        local success, loaded = pcall(function() return json.load_file(config_file) end)
        if success and loaded then
            if type(loaded.enabled) == 'boolean' then config.enabled = loaded.enabled end
            if type(loaded.lock_on_count) == 'number' then config.lock_on_count = loaded.lock_on_count end
            if type(loaded.lock_on_frame) == 'number' then config.lock_on_frame = loaded.lock_on_frame end
        end
    end
    local function save_config() pcall(function() json.dump_file(config_file, config) end) end

    local base_values = { max_count = nil, multi_frames = {}, multi_counts = {} }
    local last_applied_enabled = nil
    local last_applied_count = nil
    local last_applied_frame = nil
    load_config()

    re.on_frame(function()
        if last_applied_enabled == config.enabled
            and last_applied_count == config.lock_on_count
            and last_applied_frame == config.lock_on_frame
            and base_values.max_count ~= nil then
            return
        end
        local current_count = config.enabled and config.lock_on_count or base_values.max_count
        local player, human = HelpersA.gm_pla_hum_char()
        if not player and not human then return end
        if player then
            local lock_on_option = player:get_field("MagicBowLockOnOption")
            if lock_on_option then
                if base_values.max_count == nil then
                    base_values.max_count = lock_on_option:get_field("MaxLockOnCount")
                end
                if not config.enabled then current_count = base_values.max_count end
                if current_count then lock_on_option:set_field("MaxLockOnCount", current_count) end
            end
        end
        if human then
            local job08_ctrl = human:get_field("<Job08ActionCtrl>k__BackingField")
            if job08_ctrl then
                local human_param = human:get_field("Parameter")
                if human_param then
                    local job_param = human_param:get_field("JobParam")
                    if job_param then
                        local job08_param = job_param:get_field("Job08Parameter")
                        if job08_param then
                            local aim_arrow_param = job08_param:get_field("AimArrowParam")
                            if aim_arrow_param then
                                local multi_lock_on_param = aim_arrow_param:get_field("MultiLockOnParam")
                                if multi_lock_on_param then
                                    local settings = { "Setting", "SettingFocus", "SettingLv2", "SettingFocusAndLv2" }
                                    for _, setting_name in ipairs(settings) do
                                        local setting = multi_lock_on_param:get_field(setting_name)
                                        if setting then
                                            if base_values.multi_frames[setting_name] == nil then
                                                base_values.multi_frames[setting_name] = setting:get_field(
                                                    "MultiLockOnFrame")
                                            end
                                            if base_values.multi_counts[setting_name] == nil then
                                                base_values.multi_counts[setting_name] = setting:get_field(
                                                    "MultiLockOnCount")
                                            end
                                            local target_frame = config.enabled and config.lock_on_frame or
                                                base_values.multi_frames[setting_name]
                                            local target_count = config.enabled and config.lock_on_count or
                                                base_values.multi_counts[setting_name]
                                            if target_frame then setting:set_field("MultiLockOnFrame", target_frame) end
                                            if target_count then setting:set_field("MultiLockOnCount", target_count) end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        last_applied_enabled = config.enabled
        last_applied_count = config.lock_on_count
        last_applied_frame = config.lock_on_frame
    end)

    function MagicArcherBuff.draw_ui()
        if imgui.tree_node("Улучшение Магического лучника") then
            local changed = false
            local c1, v1 = imgui.checkbox("Активировать бафф", config.enabled)
            if c1 then
                config.enabled = v1; changed = true
            end

            if config.enabled then
                local c2, v2 = imgui.drag_int("Макс. количество целей", config.lock_on_count, 1, 1, 100)
                if c2 then
                    config.lock_on_count = v2; changed = true
                end
                if imgui.is_item_hovered() then
                    -- table.insert(result, "[cite: 1]")
                    imgui.set_tooltip("Максимальное число одновременно захватываемых целей")
                end
                local c3, v3 = imgui.drag_float("Скорость захвата рамки", config.lock_on_frame, 0.005, 0.0, 1.0)
                if c3 then
                    config.lock_on_frame = v3; changed = true
                end
                if imgui.is_item_hovered() then
                    imgui.set_tooltip("Время в секундах на фиксацию одной цели. Чем меньше = тем быстрее")
                end
            end

            if changed then save_config() end
            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 6. SHOW CURRENT HP (ПАНЕЛЬ ИНДИКАТОРОВ ЗДОРОВЬЯ И СТАМИНЫ)
-- ════════════════════════════════════════════════════════════════
local ShowCurrentHP = {}
do
    local configPath                = "ShowCurrentHP.json"
    local config_loaded             = false
    local show_hud                  = false
    local show_player               = true
    local show_pawns                = true
    local show_stamina              = true
    local show_job_icons            = true
    local show_status_icons         = true
    local status_display_mode       = 0 -- 0: Иконки, 1: Текст
    local background_style          = 1 -- 0: Выкл, 1: Темный, 2: Светлый
    local hide_labels               = false
    local hud_x                     = 20
    local hud_y                     = 60
    local font_name                 = "FOTPrentice.otf"
    local font_size                 = 14
    local font_r, font_g, font_b    = 224, 224, 224

    local line_height, bar_width, bar_height
    local status_display_mode_names = { "Иконки", "Текст" }
    local background_style_names    = { "Выключен", "Тёмный", "Светлый" }

    local function rebuild_layout()
        local scale = font_size / 14
        line_height = math.floor(18 * scale)
        bar_width   = math.floor(180 * scale)
        bar_height  = math.floor(12 * scale)
    end

    local GuiManager                 = nil
    local gui_manager_missing_logged = false
    rebuild_layout()


    local function rgba(r, g, b, a) return (a * 0x1000000) + (b * 0x10000) + (g * 0x100) + r end

    local function abgr_to_float4(c)
        return { (c % 0x100) / 255, (math.floor(c / 0x100) % 0x100) / 255, (math.floor(c / 0x10000) % 0x100) / 255, (math.floor(c / 0x1000000) % 0x100) /
        255 }
    end

    local function float4_to_abgr(f)
        local r, g, b, a = math.floor(f[1] * 255 + 0.5), math.floor(f[2] * 255 + 0.5), math.floor(f[3] * 255 + 0.5),
            math.floor(f[4] * 255 + 0.5)
        return (a * 0x1000000) + (b * 0x10000) + (g * 0x100) + r
    end

    local function abgr_to_argb(c)
        local r, g, b, a = c % 0x100, math.floor(c / 0x100) % 0x100, math.floor(c / 0x10000) % 0x100,
            math.floor(c / 0x1000000) % 0x100
        return (a * 0x1000000) + (r * 0x10000) + (g * 0x100) + b
    end

    local COLOR_HP_HIGH, COLOR_HP_MID, COLOR_HP_LOW, COLOR_ST_BAR = 0xFF50D94A, 0xFF30CCEE, 0xFF4040FF, 0xFF30AAEE
    local COLOR_STATUS_BG, COLOR_BAR_BG, COLOR_LABEL = 0xA0202020, 0x80303030, 0

    local function rebuild_font_colors()
        COLOR_LABEL = rgba(font_r, font_g, font_b, 220)
    end
    rebuild_font_colors()

    local function get_hp_color(ratio)
        if ratio > 0.6 then return COLOR_HP_HIGH end
        if ratio > 0.3 then return COLOR_HP_MID end
        return COLOR_HP_LOW
    end

    local function get_overlay_background_color()
        if background_style == 1 then return rgba(8, 10, 14, 185) end
        if background_style == 2 then return rgba(245, 245, 245, 115) end
        return nil
    end

    local function save_config()
        json.dump_file(configPath, {
            show_hud            = show_hud,
            show_player         = show_player,
            show_pawns          = show_pawns,
            show_stamina        = show_stamina,
            show_job_icons      = show_job_icons,
            show_status_icons   = show_status_icons,
            status_display_mode = status_display_mode,
            background_style    = background_style,
            hide_labels         = hide_labels,
            hud_x               = hud_x,
            hud_y               = hud_y,
            font_name           = font_name,
            font_size           = font_size,
            font_r              = font_r,
            font_g              = font_g,
            font_b              = font_b,
            COLOR_HP_HIGH       = COLOR_HP_HIGH,
            COLOR_HP_MID        = COLOR_HP_MID,
            COLOR_HP_LOW        = COLOR_HP_LOW,
            COLOR_ST_BAR        = COLOR_ST_BAR,
        })
    end

    local function load_config()
        if config_loaded then return end
        config_loaded = true
        local data = json.load_file(configPath)
        if not data then return end

        local function set(target, key) if data[key] ~= nil then return data[key] else return target end end

        show_hud            = set(show_hud, "show_hud")
        show_player         = set(show_player, "show_player")
        show_pawns          = set(show_pawns, "show_pawns")
        show_stamina        = set(show_stamina, "show_stamina")
        show_job_icons      = set(show_job_icons, "show_job_icons")
        show_status_icons   = set(show_status_icons, "show_status_icons")
        status_display_mode = set(status_display_mode, "status_display_mode")
        background_style    = set(background_style, "background_style")
        hide_labels         = set(hide_labels, "hide_labels")
        hud_x               = set(hud_x, "hud_x")
        hud_y               = set(hud_y, "hud_y")
        font_name           = (data.font_name and data.font_name ~= "") and data.font_name or font_name

        if data.font_size then
            font_size = data.font_size
            rebuild_layout()
        end

        font_r        = set(font_r, "font_r")
        font_g        = set(font_g, "font_g")
        font_b        = set(font_b, "font_b")
        COLOR_HP_HIGH = set(COLOR_HP_HIGH, "COLOR_HP_HIGH")
        COLOR_HP_MID  = set(COLOR_HP_MID, "COLOR_HP_MID")
        COLOR_HP_LOW  = set(COLOR_HP_LOW, "COLOR_HP_LOW")
        COLOR_ST_BAR  = set(COLOR_ST_BAR, "COLOR_ST_BAR")

        rebuild_font_colors()
    end
    load_config()

    local d2d_available = false
    local d2d_font = nil
    local d2d_text_queue = {}
    local d2d_image_queue = {}
    local d2d_font_dirty = true
    local load_status_icon_images
    local load_job_icon_images
    local status_enum_values = nil
    local status_enum_labels = {}
    local status_cache = {}
    local status_scan_interval = 0.25
    local max_status_icons = 12
    local status_icon_images = {}
    local status_icons_loaded = false
    local job_icon_images = {}
    local job_icons_loaded = false
    local status_icons_attempted = false
    local job_icons_attempted = false
    local character_meta_cache = {}
    local character_meta_interval = 0.35
    local status_icon_subdir = "combinedicons/"

    local function reset_status_icon_images()
        status_icon_images = {}
        status_icons_loaded = false
        job_icon_images = {}
        job_icons_loaded = false
        status_icons_attempted = false
        job_icons_attempted = false
    end


    local function get_status_display_size()
        return math.max(12, line_height)
    end

    local function estimate_text_width(text, size)
        if not text then return 0 end
        return math.max(1, math.floor(#tostring(text) * size * 0.55))
    end


    local function push_unique(list, value)
        if not value or value == "" then return end
        for _, existing in ipairs(list) do
            if existing == value then return end
        end
        table.insert(list, value)
    end

    local function build_font_candidates()
        local base = tostring(font_name or "")
        local candidates = {}
        local has_extension = base:match("%.[^%.\\/]+$") ~= nil
        local looks_like_path = base:find("[/\\]") ~= nil

        push_unique(candidates, base)

        if not looks_like_path then
            push_unique(candidates, "reframework/fonts/" .. base)
            push_unique(candidates, "fonts/" .. base)
            if not has_extension then
                push_unique(candidates, base .. ".ttf")
                push_unique(candidates, base .. ".otf")
                push_unique(candidates, "reframework/fonts/" .. base .. ".ttf")
                push_unique(candidates, "reframework/fonts/" .. base .. ".otf")
                push_unique(candidates, "fonts/" .. base .. ".ttf")
                push_unique(candidates, "fonts/" .. base .. ".otf")
            end
        elseif not has_extension then
            push_unique(candidates, base .. ".ttf")
            push_unique(candidates, base .. ".otf")
        end

        push_unique(candidates, "FOTPrentice")
        push_unique(candidates, "reframework/fonts/FOTPrentice.otf")
        push_unique(candidates, "Times New Roman")
        push_unique(candidates, "Arial")
        return candidates
    end

    local function create_d2d_font()
        for _, candidate in ipairs(build_font_candidates()) do
            local ok, font = pcall(function()
                return d2d.Font.new(candidate, font_size)
            end)
            if ok and font then
                return font
            end
        end
        return nil
    end

    if _G.d2d then
        d2d_available = true
        d2d.register(function()
            d2d_font = create_d2d_font()
            d2d_font_dirty = false
            reset_status_icon_images()
            if load_status_icon_images then
                load_status_icon_images()
            end
            if load_job_icon_images then
                load_job_icon_images()
            end
        end, function()
            if d2d_font_dirty then
                d2d_font = create_d2d_font()
                d2d_font_dirty = false
            end
            if load_status_icon_images then
                load_status_icon_images()
            end
            if load_job_icon_images then
                load_job_icon_images()
            end
            for _, img in ipairs(d2d_image_queue) do
                if img and img.image then
                    d2d.image(img.image, img.x, img.y, img.w, img.h)
                end
            end
            if d2d_font then
                for _, t in ipairs(d2d_text_queue) do
                    d2d.text(d2d_font, t.text, t.x, t.y, t.color)
                end
            end
            d2d_image_queue = {}
            d2d_text_queue = {}
        end)
    end

    local function hp_draw_text(text, x, y, abgr_color)
        if d2d_available then
            table.insert(d2d_text_queue, {
                text = text,
                x = x,
                y = y,
                color = abgr_to_argb(abgr_color),
            })
        else
            draw.text(text, x, y, abgr_color)
        end
    end

    local function get_gui_manager()
        if not GuiManager then
            GuiManager = sdk.get_managed_singleton("app.GuiManager")
            if not GuiManager and not gui_manager_missing_logged then
                gui_manager_missing_logged = true
                log.info("[Combined Mods][Show Current HP] app.GuiManager singleton not found")
            end
        end
        return GuiManager
    end

    local gui_base_get_name = nil

    local function managed_string_to_text(v)
        if not v then return nil end
        if type(v) == "string" then return v ~= "" and v or nil end
        local ok, s = pcall(function() return v:ToString() end)
        return (ok and s and s ~= "") and s or nil
    end

    local function same_managed_object(a, b)
        if not a or not b then return false end
        return a == b or tostring(a) == tostring(b)
    end

    local function get_character_name_from_id(id)
        if not id then return nil end
        if not gui_base_get_name then
            local td = sdk.find_type_definition("app.GUIBase")
            gui_base_get_name = td and td:get_method("getName(app.CharacterID)")
        end
        if not gui_base_get_name then return nil end
        return managed_string_to_text(gui_base_get_name:call(nil, id))
    end

    local function get_character_human(c)
        return c and (c:get_field("<Human>k__BackingField") or c:call("get_Human")) or nil
    end

    local function get_character_level(c)
        local h = get_character_human(c)
        if not h then return nil end
        local ctx = h:get_field("<StatusContext>k__BackingField") or h:call("get_StatusContext")
        if not ctx then return nil end
        local lvl = ctx:get_field("_Level") or ctx:call("get_Level")
        return (type(lvl) == "number" and lvl > 0) and lvl or nil
    end

    local function get_character_job_id(c)
        local h = get_character_human(c)
        if not h then return nil end
        local ctx = h:get_field("<JobContext>k__BackingField") or h:call("get_JobContext")
        if not ctx then return nil end
        local id = ctx:get_field("CurrentJob") or ctx:call("get_CurrentJob")
        return tonumber(id)
    end

    local function get_player_name(character)
        local cm = HelpersA.GetCharacterManager()
        if cm then
            local player = cm:get_field("<ManualPlayer>k__BackingField")
            if player then
                local chara_id = player:call("get_CharaID") or player:get_field("CharacterID")
                if chara_id then
                    local name = get_character_name_from_id(chara_id)
                    if name then return name end
                end
            end
        end
        local chara_id = character:call("get_CharaID") or character:get_field("CharacterID")
        if chara_id then
            return get_character_name_from_id(chara_id)
        end
        return nil
    end

    local function get_pawn_name(character)
        for _, pawn in ipairs(HelpersA.get_app_pawn_list()) do
            local pawn_character = pawn:get_field("<CachedCharacter>k__BackingField")
            if pawn_character and same_managed_object(pawn_character, character) then
                local pawn_data_context = nil
                local goal_planning = pawn:get_field("<CachedAIGoalPlanning>k__BackingField")
                if goal_planning then
                    pawn_data_context = goal_planning:get_field("_CachedPawnContext")
                end
                if pawn_data_context then
                    local data_name = pawn_data_context:get_field("_Name")
                    data_name = managed_string_to_text(data_name)
                    if data_name then
                        return data_name
                    end
                end
                local chara_id = pawn_character:call("get_CharaID") or pawn_character:get_field("CharacterID")
                if chara_id then
                    local name = get_character_name_from_id(chara_id)
                    if name then return name end
                end
                break
            end
        end
        return nil
    end

    local function get_name(character)
        local _, _, player_character = HelpersA.gm_pla_hum_char()
        if player_character and same_managed_object(player_character, character) then
            local player_name = get_player_name(character)
            if player_name then return player_name end
        end
        local pawn_name = get_pawn_name(character)
        if pawn_name then return pawn_name end
        local chara_id = character:call("get_CharaID") or character:get_field("CharacterID")
        if chara_id then
            local resolved_name = get_character_name_from_id(chara_id)
            if resolved_name then return resolved_name end
        end
        local obj = character:call("get_GameObject")
        if obj then
            local name = obj:call("get_Name")
            if name then return name end
        end
        return "???"
    end

    local function get_character_meta_cached(character)
        local key = tostring(character)
        local now = os.clock()
        local cached = character_meta_cache[key]
        if cached and (now - cached.t) < character_meta_interval then
            return cached
        end
        local meta = {
            t = now,
            name = get_name(character),
            level = get_character_level(character),
            job_id = get_character_job_id(character),
        }
        character_meta_cache[key] = meta
        return meta
    end

    local function build_status_enum_cache()
        if status_enum_values then return end
        status_enum_values = {}
        local td = sdk.find_type_definition("app.StatusConditionDef.StatusConditionEnum")
        if not td then return end
        local seen = {}
        for _, field in ipairs(td:get_fields()) do
            if field and field:is_static() then
                local name = field:get_name()
                local value = field:get_data()
                if type(value) == "number" and not seen[value] and name and name ~= "Invalid" and name ~= "Start" and name ~= "End" and name ~= "None" then
                    seen[value] = true
                    status_enum_labels[value] = name
                    table.insert(status_enum_values, value)
                end
            end
        end
        table.sort(status_enum_values)
    end

    local job_icon_name_by_id = {
        [1] = "fighter",
        [2] = "archer",
        [3] = "mage",
        [4] = "thief",
        [5] = "warrior",
        [6] = "sorcerer",
        [7] = "mystic_spearhand",
        [8] = "magick_archer",
        [9] = "trickster",
        [10] = "warfarer",
    }

    local function try_load_img(name, subdir)
        if not name or name == "" then return nil end
        local base = (subdir or "") .. name
        local paths = { base .. ".png", string.lower(base) .. ".png", name .. ".png", string.lower(name) .. ".png" }
        for _, p in ipairs(paths) do
            local ok, img = pcall(function() return d2d.Image.new(p) end)
            if ok and img then return img end
        end
        return nil
    end

    load_job_icon_images = function()
        if job_icons_attempted or not d2d_available then return end
        job_icons_attempted = true
        local count = 0
        for id, name in pairs(job_icon_name_by_id) do
            local img = try_load_img(name, status_icon_subdir)
            if img then
                job_icon_images[id] = img; count = count + 1
            end
        end
        job_icons_loaded = count > 0
    end

    load_status_icon_images = function()
        if status_icons_attempted or not d2d_available then return end
        status_icons_attempted = true
        build_status_enum_cache()
        local count = 0
        for _, id in ipairs(status_enum_values or {}) do
            local img = try_load_img(status_enum_labels[id], status_icon_subdir)
            if img then
                status_icon_images[id] = img; count = count + 1
            end
        end
        status_icons_loaded = count > 0
    end

    local function format_status_name(raw_name)
        if not raw_name then return "?" end
        local name = tostring(raw_name)
        name = name:gsub("^StatusCondition", "")
        name = name:gsub("^SC_", "")
        name = name:gsub("[<>]", "")
        name = name:gsub("_", " ")
        name = name:gsub("(%l)(%u)", "%1 %2")
        name = name:gsub("%s+", " ")
        name = name:gsub("^%s+", "")
        name = name:gsub("%s+$", "")
        if #name == 0 then
            return "?"
        end
        return name
    end

    local function get_active_statuses(character)
        local active = {}
        if not character then return active end
        build_status_enum_cache()
        if not status_enum_values or #status_enum_values == 0 then return active end
        local statusCtrl = character:get_field("<StatusConditionCtrl>k__BackingField") or
            character:call("get_StatusConditionCtrl")
        if not statusCtrl then return active end
        for _, status_id in ipairs(status_enum_values) do
            local isActive = statusCtrl:call("IsStatusConditionActive", status_id, false)
            if isActive then
                table.insert(active, {
                    id = status_id,
                    label = format_status_name(status_enum_labels[status_id] or tostring(status_id)),
                })
            end
        end
        return active
    end

    local function get_active_statuses_cached(character)
        local key = tostring(character)
        local now = os.clock()
        local cached = status_cache[key]
        if cached and (now - cached.t) < status_scan_interval then
            return cached.list
        end
        local list = get_active_statuses(character)
        status_cache[key] = { t = now, list = list }
        return list
    end

    local function build_status_text_lines(statuses)
        local lines = {}
        if not statuses or #statuses == 0 then
            return lines
        end
        local current_line = ""
        for i = 1, #statuses do
            local label = statuses[i].label
            local next_line = current_line == "" and label or (current_line .. " - " .. label)
            if current_line ~= "" and estimate_text_width(next_line, font_size) > bar_width then
                table.insert(lines, current_line)
                current_line = label
            else
                current_line = next_line
            end
        end
        if current_line ~= "" then
            table.insert(lines, current_line)
        end
        return lines
    end

    local function measure_status_block(statuses)
        if not statuses or #statuses == 0 then
            return 0
        end
        if status_display_mode == 1 then
            local lines = build_status_text_lines(statuses)
            return (#lines * line_height) + 2
        end

        local icon_h = get_status_display_size()
        local text_w = math.max(1, math.floor(font_size * 0.55))
        local cur_x = 0
        local rows = 1
        local shown = 0

        local function reserve_width(item_w)
            if cur_x > 0 and (cur_x + item_w) > bar_width then
                rows = rows + 1
                cur_x = 0
            end
            cur_x = cur_x + item_w + 3
        end

        for i = 1, #statuses do
            if shown >= max_status_icons then
                local remaining = #statuses - shown
                if remaining > 0 then
                    local overflow_w = math.max(icon_h, estimate_text_width("+" .. tostring(remaining), font_size) + 8)
                    reserve_width(overflow_w)
                end
                break
            end

            local status = statuses[i]
            local img = status_icon_images[status.id]
            local item_w = (img and d2d_available) and icon_h or math.max(icon_h, #status.label * text_w + 8)
            reserve_width(item_w)
            shown = shown + 1
        end

        return (rows * icon_h) + ((rows - 1) * 2) + 4
    end

    local function draw_status_icons(statuses, x, y)
        if not statuses or #statuses == 0 then return y end
        if status_display_mode == 1 then
            local lines = build_status_text_lines(statuses)
            for _, line in ipairs(lines) do
                hp_draw_text(line, x, y, COLOR_LABEL)
                y = y + line_height
            end
            return y + 2
        end
        local icon_h = get_status_display_size()
        local icon_w = icon_h
        local status_text_size = font_size
        local text_w = math.max(1, math.floor(status_text_size * 0.55))
        local max_x = x + bar_width
        local cur_x = x
        local shown = 0

        local function draw_badge(label)
            local badge_w = math.max(icon_h, #label * text_w + 8)
            if cur_x + badge_w > max_x then
                cur_x = x
                y = y + icon_h + 2
            end
            draw.filled_rect(cur_x, y, badge_w, icon_h, COLOR_STATUS_BG)
            hp_draw_text(label, cur_x + 4, y + (icon_h - status_text_size) / 2, COLOR_LABEL)
            cur_x = cur_x + badge_w + 3
        end

        local function draw_icon(status)
            local img = status_icon_images[status.id]
            if not img or not d2d_available then
                draw_badge(status.label)
                return
            end
            if cur_x + icon_w > max_x then
                cur_x = x
                y = y + icon_h + 2
            end
            table.insert(d2d_image_queue, {
                image = img,
                x = cur_x,
                y = y,
                w = icon_w,
                h = icon_h,
            })
            cur_x = cur_x + icon_w + 3
        end

        for i = 1, #statuses do
            if shown >= max_status_icons then
                local remaining = #statuses - shown
                if remaining > 0 then
                    draw_badge("+" .. tostring(remaining))
                end
                break
            end
            draw_icon(statuses[i])
            shown = shown + 1
        end
        return y + icon_h + 4
    end

    local function draw_hp_bar(x, y, hp, maxHp, w, h)
        if not maxHp or maxHp <= 0 then return end
        local ratio = math.max(0, math.min(hp / maxHp, 1))
        draw.filled_rect(x, y, w, h, COLOR_BAR_BG)
        if ratio > 0 then draw.filled_rect(x, y, math.floor(w * ratio), h, get_hp_color(ratio)) end
    end

    local function draw_character_hp(c, label, x, y)
        if not c or not c:call("get_Valid") then return y end

        local meta      = get_character_meta_cached(c)
        local job_img   = (show_job_icons and meta.job_id) and job_icon_images[meta.job_id] or nil
        local statuses  = show_status_icons and get_active_statuses_cached(c) or nil
        local name      = (meta.name and meta.name ~= "" and meta.name ~= "???") and meta.name or (label or "???")

        local start_y   = y
        local pad       = math.max(4, math.floor(font_size * 0.35))
        local job_sz    = math.max(18, math.floor(font_size * 2))
        local content_x = x

        if job_img and d2d_available then
            table.insert(d2d_image_queue, { image = job_img, x = math.max(0, x), y = start_y, w = job_sz, h = job_sz })
            content_x = x + job_sz + pad
        end

        local hp          = c:call("get_Hp") or 0
        local maxHp, oMax = 0, 0
        local hit         = c:get_field("<Hit>k__BackingField") or c:call("get_Hit")
        if hit then
            maxHp = hit:call("get_ReducedMaxHp()") or 0; oMax = hit:call("get_OriginalMaxHp()") or 0
        end

        local hp_text = string.format("%.0f / %.0f", hp, maxHp)
        if oMax > 0 and oMax ~= maxHp then hp_text = hp_text .. string.format(" (Макс: %.0f)", oMax) end

        local st, mSt, st_text = 0, 0, nil
        if show_stamina then
            local sm = c:call("get_StaminaManager")
            if sm then
                st = sm:call("get_RemainingAmount"); mSt = sm:call("get_MaxValue")
            end
            if mSt and mSt > 0 then st_text = string.format("%.0f / %.0f", st, mSt) end
        end

        local hp_w    = estimate_text_width(hp_text, font_size)
        local p_right = math.max(content_x + bar_width + 4 + hp_w, content_x + bar_width)
        if st_text then p_right = math.max(p_right, content_x + bar_width + 4 + estimate_text_width(st_text, font_size)) end
        if not hide_labels then
            p_right = math.max(p_right, content_x + estimate_text_width(name, font_size))
            if meta.level then p_right = math.max(p_right, content_x + bar_width) end
        end

        local p_height = (hide_labels and 0 or line_height) + bar_height + 4 + (st_text and (bar_height + 4) or 0) +
            measure_status_block(statuses)
        local p_color  = get_overlay_background_color()
        if p_color then
            draw.filled_rect(x - pad, start_y - 2, (p_right - x) + (pad * 2), p_height + 4, p_color)
        end

        if not hide_labels then
            hp_draw_text(name, content_x, y, COLOR_LABEL)
            if meta.level then
                local lt = "Уровень " .. tostring(meta.level)
                hp_draw_text(lt,
                    math.max(content_x + estimate_text_width(name, font_size) + 10,
                        content_x + bar_width - estimate_text_width(lt, font_size)), y, COLOR_LABEL)
            end
            y = y + line_height
        end

        draw_hp_bar(content_x, y, hp, maxHp, bar_width, bar_height)
        hp_draw_text(hp_text, content_x + bar_width + 4, y + (bar_height - font_size) / 2, COLOR_LABEL)
        y = y + bar_height + 4

        if show_stamina and st_text then
            draw.filled_rect(content_x, y, bar_width, bar_height, COLOR_BAR_BG)
            local sR = math.max(0, math.min(st / mSt, 1))
            if sR > 0 then draw.filled_rect(content_x, y, math.floor(bar_width * sR), bar_height, COLOR_ST_BAR) end
            hp_draw_text(st_text, content_x + bar_width + 4, y + (bar_height - font_size) / 2, COLOR_LABEL)
            y = y + bar_height + 4
        end

        if show_status_icons then y = draw_status_icons(statuses, content_x, y) end
        return y
    end

    local function update_show_current_hp_overlay()
        if not show_hud then return end
        d2d_image_queue = {}
        d2d_text_queue = {}
        local guiMgr = get_gui_manager()
        if guiMgr and guiMgr:call("isPausedGUI") then return end
        local _, _, character = HelpersA.gm_pla_hum_char()
        if not character then return end
        local x, y = hud_x, hud_y
        if show_player then
            local lbl = not hide_labels and "Игрок" or nil
            y = draw_character_hp(character, lbl, x, y); y = y + 2
        end
        if show_pawns then
            local pawns = HelpersA.get_pawn_chara_list()
            if #pawns > 0 then
                local lbl = not hide_labels and "Пешка" or nil
                for _, pawn in ipairs(pawns) do y = draw_character_hp(pawn, lbl, x, y) end
            end
        end
    end

    re.on_frame(function()
        update_show_current_hp_overlay()
    end)

    local function draw_color_sliders(label, color_val)
        local c = abgr_to_float4(color_val)
        local r = math.floor(c[1] * 255 + 0.5)
        local g = math.floor(c[2] * 255 + 0.5)
        local b = math.floor(c[3] * 255 + 0.5)
        local a = math.floor(c[4] * 255 + 0.5)
        local any_changed = false
        local ch
        if imgui.tree_node(label) then
            ch, r = imgui.slider_int("R##" .. label, r, 0, 255); if ch then any_changed = true end
            ch, g = imgui.slider_int("G##" .. label, g, 0, 255); if ch then any_changed = true end
            ch, b = imgui.slider_int("B##" .. label, b, 0, 255); if ch then any_changed = true end
            ch, a = imgui.slider_int("A##" .. label, a, 0, 255); if ch then any_changed = true end
            imgui.tree_pop()
        end
        if any_changed then return true, float4_to_abgr({ r / 255, g / 255, b / 255, a / 255 }) end
        return false, color_val
    end

    function ShowCurrentHP.draw_ui()
        if not imgui.tree_node("Полоски здоровья и выносливости (HUD)") then return end

        local changed
        changed, show_hud = imgui.checkbox("Показывать HUD оверлей", show_hud); if changed then save_config() end
        if imgui.is_item_hovered() then imgui.set_tooltip("Включить/выключить отображение кастомных панелей HP/Стамины") end

        if show_hud then
            imgui.indent()
            local function check(lbl, val, tip)
                local c, v = imgui.checkbox(lbl, val)
                if c then save_config() end
                if tip and imgui.is_item_hovered() then imgui.set_tooltip(tip) end
                return v
            end

            show_player       = check("Показывать Игрока", show_player, "Включить панель здоровья Восставшего")
            show_pawns        = check("Показывать Пешек", show_pawns, "Включить панели здоровья для всех пешек отряда")
            show_stamina      = check("Показывать Выносливость", show_stamina, "Отображать синюю полоску стамины под полоской HP")
            show_job_icons    = check("Показывать иконки классов", show_job_icons, "Выводить слева от имени иконку текущего призвания")
            show_status_icons = check("Показывать эффекты/статусы", show_status_icons, "Показывать активные негативные или позитивные состояния")

            if show_status_icons then
                local mc, mv = imgui.combo("Вид статусов", status_display_mode + 1, status_display_mode_names)
                if mc then
                    status_display_mode = mv - 1; save_config()
                end
            end

            local bc, bv = imgui.combo("Стиль заднего фона", background_style + 1, background_style_names)
            if bc then
                background_style = bv - 1; save_config()
            end

            hide_labels = check("Скрыть имена персонажей", hide_labels, "Убирает текстовые подписи имен над полосками здоровья")

            imgui.separator()
            local function drag(lbl, val, sp, min, max, tip)
                local c, v = imgui.drag_int(lbl, val, sp, min, max)
                if c then save_config() end
                if tip and imgui.is_item_hovered() then imgui.set_tooltip(tip) end
                return v
            end

            hud_x = drag("Позиция HUD X", hud_x, 1, 0, 3840, "Смещение панелей по горизонтали (в пикселях)")
            hud_y = drag("Позиция HUD Y", hud_y, 1, 0, 2160, "Смещение панелей по вертикали (в пикселях)")

            local fc, fv = imgui.drag_int("Размер шрифта", font_size, 1, 8, 48)
            if fc then
                font_size = fv; rebuild_layout(); d2d_font_dirty = true; save_config()
            end
            if imgui.is_item_hovered() then imgui.set_tooltip("Общее масштабирование элементов интерфейса мода") end

            local tc, tv = imgui.input_text("Имя файла шрифта", font_name)
            if tc then
                font_name = tv; d2d_font_dirty = true; save_config()
            end

            if imgui.tree_node("Редактор цветов") then
                local function color_edit(lbl, val)
                    local ok, nv = draw_color_sliders(lbl, val)
                    if ok then save_config() end
                    return nv
                end

                local cc, cr = imgui.slider_int("Шрифт: R", font_r, 0, 255); if cc then
                    font_r = cr; rebuild_font_colors(); save_config()
                end
                local cg, cv = imgui.slider_int("Шрифт: G", font_g, 0, 255); if cg then
                    font_g = cv; rebuild_font_colors(); save_config()
                end
                local cb, cvb = imgui.slider_int("Шрифт: B", font_b, 0, 255); if cb then
                    font_b = cvb; rebuild_font_colors(); save_config()
                end

                imgui.separator()
                COLOR_HP_HIGH = color_edit("HP: Высокое (Зеленый)", COLOR_HP_HIGH)
                COLOR_HP_MID  = color_edit("HP: Среднее (Желтый)", COLOR_HP_MID)
                COLOR_HP_LOW  = color_edit("HP: Низкое (Красный)", COLOR_HP_LOW)
                COLOR_ST_BAR  = color_edit("Полоса выносливости", COLOR_ST_BAR)

                imgui.tree_pop()
            end
            imgui.unindent()
        end
        imgui.tree_pop()
    end
end

-- ════════════════════════════════════════════════════════════════
-- 7. DISABLE KILLED BY BRINE (ОТКЛЮЧЕНИЕ СМЕРТИ ОТ НЕСЫТИ / ВОДЫ)
-- ════════════════════════════════════════════════════════════════
local DisableBrine = {}
do
    local config_file = "disable_brine.json"
    local cfg = {
        enable_disable_brine = false,
        apply_to_player = true,
        apply_to_pawns = true,
    }
    local was_enabled_last_frame = false

    local function load_config()
        local success, loaded = pcall(function() return json.load_file(config_file) end)
        if success and loaded then
            if type(loaded.enable_disable_brine) == "boolean" then
                cfg.enable_disable_brine = loaded
                    .enable_disable_brine
            end
            if type(loaded.apply_to_player) == "boolean" then cfg.apply_to_player = loaded.apply_to_player end
            if type(loaded.apply_to_pawns) == "boolean" then cfg.apply_to_pawns = loaded.apply_to_pawns end
        end
    end
    local function save_config() pcall(function() json.dump_file(config_file, cfg) end) end
    load_config()

    local function set_brine_enable(character, value)
        if not character then return end
        local brine_proc = character:get_field("<BrineProcessor>k__BackingField")
        if brine_proc then
            brine_proc:set_field("<IsEnable>k__BackingField", value)
        end
    end

    local function restore_all()
        local _, _, player = HelpersA.gm_pla_hum_char()
        if player then set_brine_enable(player, true) end
        local pawns = HelpersA.get_pawn_chara_list()
        for _, pawn in ipairs(pawns) do set_brine_enable(pawn, true) end
    end

    re.on_frame(function()
        if not cfg.enable_disable_brine then
            if was_enabled_last_frame then
                restore_all()
                was_enabled_last_frame = false
            end
            return
        end
        was_enabled_last_frame = true

        if cfg.apply_to_player then
            local _, _, character = HelpersA.gm_pla_hum_char()
            if character then set_brine_enable(character, false) end
        end

        if cfg.apply_to_pawns then
            local pawns = HelpersA.get_pawn_chara_list()
            for _, pawn in ipairs(pawns) do set_brine_enable(pawn, false) end
        end
    end)

    function DisableBrine.draw_ui()
        if imgui.tree_node("Бессмертие в воде (Анти-Несыть)") then
            local changed = false
            local c
            c, cfg.enable_disable_brine = imgui.checkbox("Запретить Несыти убивать при падении в воду", cfg.enable_disable_brine)
            if c then changed = true end
            if cfg.enable_disable_brine then
                imgui.text("Цели для защиты:")
                c, cfg.apply_to_player = imgui.checkbox("Применить к Игроку", cfg.apply_to_player); changed = changed or c
                c, cfg.apply_to_pawns = imgui.checkbox("Применить к Пешкам", cfg.apply_to_pawns); changed = changed or c
            end
            if changed then save_config() end
            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 8. UNCAP STATS GROWTH (СНЯТИЕ ЛИМИТОВ НА ПРОКАЧКУ ХАРАКТЕРИСТИК)
-- ════════════════════════════════════════════════════════════════
local UncapStatsGrowth = {}
do
    local MOD_NAME = "UncapStatsGrowth"
    local config_file = MOD_NAME .. ".json"

    local CAP_FIELDS = {
        "Hitpoint", "Stamina", "Attack", "Defence",
        "MagicAttack", "MagicDefence", "Weight", "Blow", "BlowResistance"
    }
    
    local russian_fields = {
        Hitpoint       = "Очки здоровья (HP)",
        Stamina        = "Выносливость (Stamina)",
        Attack         = "Сила физической атаки",
        Defence        = "Физическая защита",
        MagicAttack    = "Сила магической атаки",
        MagicDefence   = "Магическая защита",
        Weight         = "Макс. переносимый вес",
        Blow           = "Сила сбивания с ног",
        BlowResistance = "Сопротивление сбиванию"
    }

    local CustomCaps = {
        Hitpoint       = 999999.0,
        Stamina        = 999999.0,
        Attack         = 9999.0,
        Defence        = 9999.0,
        MagicAttack    = 9999.0,
        MagicDefence   = 9999.0,
        Weight         = 9999.0,
        Blow           = 9999.0,
        BlowResistance = 9999.0
    }

    local cfg = {
        enabled = false,
        caps = CustomCaps,
        enableLvupMultiplier = false,
        lvupMultiplier = 1.0
    }

    local function load_config()
        local success, loaded = pcall(function() return json.load_file(config_file) end)
        if success and loaded then
            if type(loaded.enabled) == 'boolean' then cfg.enabled = loaded.enabled end
            if type(loaded.caps) == 'table' then
                for _, field in ipairs(CAP_FIELDS) do
                    if loaded.caps[field] ~= nil then
                        cfg.caps[field] = loaded.caps[field]
                    end
                end
            end
            if type(loaded.enableLvupMultiplier) == 'boolean' then
                cfg.enableLvupMultiplier = loaded
                    .enableLvupMultiplier
            end
            if type(loaded.lvupMultiplier) == 'number' then cfg.lvupMultiplier = loaded.lvupMultiplier end
        end
    end

    local function save_config()
        pcall(function() json.dump_file(config_file, cfg) end)
    end
    load_config()

    local applied = false
    local statusMsg = "Ожидание загрузки игрока..."
    local origCap = {}
    local origLvupParams = {}

    local function get_lvup_data()
        local _, human = HelpersA.gm_pla_hum_char()
        if not human then return nil end

        local param = human:get_field("Parameter")
        if not param then return nil end

        return param:get_field("LVupInfoParam")
    end

    local function snapshot_fields(source, fields)
        local snapshot = {}
        for _, field in ipairs(fields) do
            snapshot[field] = source:get_field(field)
        end
        return snapshot
    end

    local function raise_caps()
        if applied then return end

        local lvupData = get_lvup_data()
        if not lvupData then return end

        local cap = lvupData:get_field("CapLVupParam")
        if not cap then
            statusMsg = "ОШИБКА: Компонент лимитов CapLVupParam не найден"
            return
        end

        if not next(origCap) then
            origCap = snapshot_fields(cap, CAP_FIELDS)
        end

        for _, field in ipairs(CAP_FIELDS) do
            if cfg.enabled then
                local targetCap = cfg.caps[field]
                if targetCap ~= nil then
                    cap:set_field(field, targetCap)
                end
            else
                if origCap[field] ~= nil then
                    cap:set_field(field, origCap[field])
                end
            end
        end

        local lvupParams = lvupData:get_field("LVupParams")
        if lvupParams then
            local count = lvupParams:call("get_Count")
            if count then
                if not next(origLvupParams) and count > 0 then
                    for i = 0, count - 1 do
                        local entry = lvupParams[i]
                        if entry then
                            origLvupParams[i] = snapshot_fields(entry, CAP_FIELDS)
                        end
                    end
                end

                for i = 0, count - 1 do
                    local entry = lvupParams[i]
                    local origEntry = origLvupParams[i]
                    if entry and origEntry then
                        for _, field in ipairs(CAP_FIELDS) do
                            if cfg.enabled and cfg.enableLvupMultiplier then
                                local targetCap = origEntry[field]
                                if targetCap ~= nil then
                                    entry:set_field(field, targetCap * cfg.lvupMultiplier)
                                end
                            else
                                if origEntry[field] ~= nil then
                                    entry:set_field(field, origEntry[field])
                                end
                            end
                        end
                    end
                end
            end
        end

        if cfg.enabled then
            statusMsg = "Кастомные лимиты успешно применены"
        else
            statusMsg = "Применены стандартные ограничения игры"
        end

        applied = true
    end

    local last_enabled_state = cfg.enabled
    re.on_frame(function()
        if cfg.enabled ~= last_enabled_state then
            applied = false
            last_enabled_state = cfg.enabled
        end
        if not applied then
            raise_caps()
        end
    end)

    local function reset_humanstr(human)
        if not human then return end

        local ctx = human:get_field("<StatusContext>k__BackingField")
        if not ctx then return end

        ctx:set_field("_Level", 1)
        ctx:set_field("_Exp", 0)

        local inc = ctx:get_field("_IncreaseParams")
        if inc then
            inc:set_field("_HitPoint", 0)
            inc:set_field("_Stamina", 0)
            inc:set_field("_Attack", 0)
            inc:set_field("_Defence", 0)
            inc:set_field("_MagicAttack", 0)
            inc:set_field("_MagicDefence", 0)
            inc:set_field("_Weight", 0)
            inc:set_field("_Blow", 0)
        end
    end

    function UncapStatsGrowth.draw_ui()
        if imgui.tree_node("Прокачка характеристик без лимитов") then
            local changed = false
            local c

            c, cfg.enabled = imgui.checkbox("Включить бесконечную прокачку параметров", cfg.enabled)
            changed = changed or c

            imgui.separator()
            if cfg.enabled then
                imgui.text("Статус системы: " .. statusMsg)

                imgui.separator()

                for _, field in ipairs(CAP_FIELDS) do
                    local original = origCap[field] or 0
                    local field_label = russian_fields[field] or field
                    imgui.push_id(field)
                    c, cfg.caps[field] = imgui.drag_float(field_label, cfg.caps[field], 10.0, 1.0, 999999.0, "%.1f")

                    if original > 0 or original == 0 then
                        imgui.same_line()
                        imgui.text_colored(string.format("(Оригинал: %.0f)", original), 0xffaaaaaa)
                    end
                    imgui.pop_id()

                    if c then
                        applied = false
                        changed = true
                    end
                end

                imgui.separator()
                c, cfg.enableLvupMultiplier = imgui.checkbox("Включить множитель прироста статов", cfg
                    .enableLvupMultiplier)
                if imgui.is_item_hovered() then
                    imgui.set_tooltip("Умножает количество очков характеристик, получаемых при каждом повышении уровня")
                end
                if c then
                    applied = false
                    changed = true
                end

                if cfg.enableLvupMultiplier then
                    c, cfg.lvupMultiplier = imgui.drag_float("Коэффициент множителя", cfg.lvupMultiplier, 0.1, 1.0, 100.0,
                        "%.1fx")
                    if c then
                        applied = false
                        changed = true
                    end
                end

                imgui.separator()

                if imgui.button("Сбросить Восставшего (Игрока)") then
                    pcall(function()
                        local _, human = HelpersA.gm_pla_hum_char()
                        if human then
                            reset_humanstr(human)
                            statusMsg = "Уровень Восставшего успешно сброшен на 1-й уровень!"
                        else
                            statusMsg = "Восставший не обнаружен в памяти движка."
                        end
                    end)
                end
                if imgui.is_item_hovered() then
                    imgui.set_tooltip("Внимание! Полностью сбрасывает уровень вашего персонажа на 1, EXP на 0, и обнуляет весь полученный за уровни прирост статов")
                end

                imgui.same_line()

                if imgui.button("Сбросить Основную пешку") then
                    pcall(function()
                        local human = HelpersA.get_main_pawn_human()
                        if human then
                            reset_humanstr(human)
                            statusMsg = "Уровень Основной пешки успешно сброшен на 1-й уровень!"
                        else
                            statusMsg = "Основная пешка не найдена."
                        end
                    end)
                end
                if imgui.is_item_hovered() then
                    imgui.set_tooltip("Внимание! Полностью сбрасывает уровень вашей главной пешки на 1, EXP на 0, и обнуляет весь полученный прирост статов")
                end
            else
                imgui.text("Статус системы: Мод отключен")
            end

            if changed then
                save_config()
            end

            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 9. NO EQUIP REQUIREMENT (СНЯТИЕ КЛАССОВЫХ ОГРАНИЧЕНИЙ НА ОРУЖИЕ/БРОНЮ)
-- ════════════════════════════════════════════════════════════════
local NoEquipRequirement = {}
do
    local MOD_NAME = "Экипировка без ограничений классов"
    local config_file = "noequiprequirement.json"

    local cfg = {
        enable_equipment_bypass = true
    }

    local function load_config()
        local success, loaded = pcall(function() return json.load_file(config_file) end)
        if success and loaded then
            if type(loaded.enable_equipment_bypass) == 'boolean' then
                cfg.enable_equipment_bypass = loaded.enable_equipment_bypass
            end
        end
    end

    local function save_config()
        pcall(function() json.dump_file(config_file, cfg) end)
    end

    load_config()

    local function on_is_job_post(retval)
        if cfg.enable_equipment_bypass then
            return sdk.to_ptr(true)
        end
        return retval
    end

    local type_item_equip = sdk.find_type_definition("app.ItemEquipParam")
    if type_item_equip then
        local method = type_item_equip:get_method("IsJob(app.Character)")
        if method then
            sdk.hook(method, function(args) end, on_is_job_post)
        end
    end

    function NoEquipRequirement.draw_ui()
        if imgui.tree_node(MOD_NAME) then
            local changed = false

            local c_bypass, v_bypass = imgui.checkbox("Разрешить любое снаряжение и пухи для всех призваний", cfg.enable_equipment_bypass)
            if c_bypass then
                cfg.enable_equipment_bypass = v_bypass
                changed = true
            end

            if imgui.is_item_hovered() then
                imgui.set_tooltip(
                    "Предупреждение: Экипировка несовместимого оружия (например, двуручный меч в руках у Мага) может приводить к Т-позам персонажа или отсутствию анимации боевых умений.")
            end

            if changed then
                save_config()
            end

            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 10. REVEAL ALL MAP (ПОЛНОЕ ОТКРЫТИЕ КАРТЫ МИРА И ИКОНОК)
-- ════════════════════════════════════════════════════════════════
local RevealAllMap = {}
do
    local MOD_NAME = "Открыть всю карту мира"
    local statusMsg = "В режиме ожидания"

    local function getGuiManager()
        return sdk.get_managed_singleton("app.GuiManager")
    end

    local map_backup = {
        MapMaskField = {},
        MapMaskCurrentArea = {},
        MapMaskLocalArea = {}
    }
    local has_backup = false

    local function setMapMaskAll(fillValue, silent)
        local guiMgr = getGuiManager()
        if not guiMgr then
            statusMsg = "Компонент GuiManager не найден"
            return
        end

        local function processMask(mask, backup_table, is_backup_mode, is_restore_mode)
            if not mask then return 0 end
            local maskBit = mask:get_field("MapMaskField") or mask:get_field("MaskBit")
            if not maskBit then return 0 end
            local count = maskBit:call("get_Count")
            if not count or count == 0 then return 0 end

            for i = 0, count - 1 do
                if is_backup_mode then
                    table.insert(backup_table, maskBit:call("Get", i) or 0)
                elseif is_restore_mode then
                    if backup_table[i + 1] ~= nil then
                        maskBit:call("Set", i, backup_table[i + 1])
                    end
                else
                    maskBit:call("Set", i, fillValue)
                end
            end
            return count
        end

        local total = 0
        local is_restore = (fillValue == "RESTORE")

        if not is_restore then
            map_backup.MapMaskField = {}
            map_backup.MapMaskCurrentArea = {}
            map_backup.MapMaskLocalArea = {}

            processMask(guiMgr:get_field("MapMaskField"), map_backup.MapMaskField, true, false)
            processMask(guiMgr:get_field("MapMaskCurrentArea"), map_backup.MapMaskCurrentArea, true, false)

            local localAreas = guiMgr:get_field("MapMaskLocalArea")
            if localAreas then
                local areaCount = localAreas:call("get_Count")
                if areaCount and areaCount > 0 then
                    for a = 0, areaCount - 1 do
                        map_backup.MapMaskLocalArea[a] = {}
                        processMask(localAreas:call("Get", a), map_backup.MapMaskLocalArea[a], true, false)
                    end
                end
            end
            has_backup = true
        end

        if is_restore and not has_backup then
            statusMsg = "Нет сохраненного состояния карты для восстановления!"
            return
        end

        total = total + processMask(guiMgr:get_field("MapMaskField"), map_backup.MapMaskField, false, is_restore)
        total = total +
            processMask(guiMgr:get_field("MapMaskCurrentArea"), map_backup.MapMaskCurrentArea, false, is_restore)

        local localAreas = guiMgr:get_field("MapMaskLocalArea")
        if localAreas then
            local areaCount = localAreas:call("get_Count")
            if areaCount and areaCount > 0 then
                for a = 0, areaCount - 1 do
                    local backup_subtable = map_backup.MapMaskLocalArea[a] or {}
                    total = total + processMask(localAreas:call("Get", a), backup_subtable, false, is_restore)
                end
            end
        end

        if not silent then
            if is_restore then
                statusMsg = string.format("Туман войны успешно возвращен!")
            else
                statusMsg = string.format("Вся карта мира полностью открыта!")
            end
        end
    end

    local icon_method = 1
    local icon_method_active = false
    local icon_method_names = { "Отключено", "Хук перехвата", "Максимальная дистанция" }
    local icon_method_tooltips = {
        "",
        "Временный метод. Не меняет параметры игры. Иконки появятся только на большой Карте мира (на мини-карте отображаться не будут).",
        "Увеличивает дальность обнаружения точек до максимума. Чтобы открыть маркеры подземелий, встаньте перед их входом."
    }

    local type_gui_mgr = sdk.find_type_definition("app.GuiManager")
    if type_gui_mgr then
        local method = type_gui_mgr:get_method("<getMapIconList>b__321_0(app.MapIconParam)")
        if method then
            sdk.hook(method,
                function(args) end,
                function(retval)
                    if icon_method_active and icon_method == 2 then
                        return sdk.to_ptr(1)
                    end
                    return retval
                end
            )
        end
    end

    local dist_backup = {}
    local has_dist_backup = false

    local function setMapIconDist(is_restore)
        local guiMgr = getGuiManager()
        if not guiMgr then return end

        local iconList = guiMgr:get_field("MapIconList")
        if not iconList then return end

        local count = iconList:call("get_Count")
        if not count or count == 0 then return end

        if not is_restore then
            dist_backup = {}
            for i = 0, count - 1 do
                local icon = iconList:call("get_Item", i)
                if icon then
                    dist_backup[i] = icon:get_field("_Dist") or 0.0
                    icon:set_field("_Dist", 99999.0)
                end
            end
            has_dist_backup = true
        else
            if not has_dist_backup then return end
            for i = 0, count - 1 do
                local icon = iconList:call("get_Item", i)
                if icon and dist_backup[i] then
                    icon:set_field("_Dist", dist_backup[i])
                end
            end
            has_dist_backup = false
        end
    end

    local function deactivateCurrentMethod()
        if icon_method == 3 and has_dist_backup then
            setMapIconDist(true)
        end
        icon_method_active = false
    end

    local function activateCurrentMethod()
        if icon_method == 3 then
            setMapIconDist(false)
        end
        icon_method_active = true
        statusMsg = "Маркеры карты: метод [" .. icon_method_names[icon_method] .. "] запущен"
    end

    function RevealAllMap.draw_ui()
        if imgui.tree_node(MOD_NAME) then
            if imgui.button("Убрать полностью весь туман войны с карты") then
                setMapMaskAll(0xFFFFFFFF, false)
            end
            imgui.same_line()
            if imgui.button("Вернуть туман обратно") then
                setMapMaskAll("RESTORE", false)
            end

            imgui.spacing()
            imgui.separator()
            imgui.text("Отображение всех скрытых иконок/маркеров:")

            local combo_changed, combo_val = imgui.combo("Метод показа", icon_method, icon_method_names)
            if combo_changed then
                deactivateCurrentMethod()
                icon_method = combo_val
            end
            if imgui.is_item_hovered() and icon_method_tooltips[icon_method] ~= "" then
                imgui.set_tooltip(icon_method_tooltips[icon_method])
            end

            if icon_method > 1 then
                if imgui.button("Отобразить маркеры на карте") then
                    activateCurrentMethod()
                end
                if imgui.is_item_hovered() then
                    imgui.set_tooltip("Применить выбранный алгоритм: " .. icon_method_names[icon_method])
                end
                imgui.same_line()
                if imgui.button("Сбросить маркеры к оригиналу") then
                    deactivateCurrentMethod()
                    icon_method = 1
                    statusMsg = "Иконки карты возвращены в исходное состояние"
                end
            end

            imgui.spacing()
            imgui.text_colored("Текущий статус: " .. statusMsg, 0xFF88FF88)
            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 11. DEPOSIT TO WAREHOUSE (УДАЛЕННАЯ СДАЧА ВЕЩЕЙ НА СКЛАД)
-- ════════════════════════════════════════════════════════════════
local DepositToWarehouse = {}
do
    local MOD_NAME = "Авто-отправка предметов на склад"
    local config_file = "deposit_to_warehouse.json"
    local config = {
        Categories = { ["0"] = true },
        ScanArisen = true,
        ScanMainPawn = true,
        Hotkeys = { ["Process Warehouse Deposit"] = "F11" },
        CategoryMode = 1
    }

    local function load_config()
        local success, loaded = pcall(function() return json.load_file(config_file) end)
        if success and loaded then
            if type(loaded.Categories) == 'table' then config.Categories = loaded.Categories end
            if type(loaded.ScanArisen) == 'boolean' then config.ScanArisen = loaded.ScanArisen end
            if type(loaded.ScanMainPawn) == 'boolean' then config.ScanMainPawn = loaded.ScanMainPawn end
            if type(loaded.Hotkeys) == 'table' then config.Hotkeys = loaded.Hotkeys end
            if type(loaded.CategoryMode) == 'number' then config.CategoryMode = loaded.CategoryMode end
        end
    end

    local function save_config()
        pcall(function() json.dump_file(config_file, config) end)
    end

    load_config()
    hk.setup_hotkeys(config.Hotkeys)

    local ItemManagerType = sdk.find_type_definition("app.ItemManager")
    local forceGetItemToWarehouse = ItemManagerType:get_method(
        "forceGetItemToWarehouse(System.Int32, System.Int32, app.ItemDefine.EnhanceParam, System.Boolean, System.Boolean, System.Boolean, app.ItemManager.GetItemEventType, System.Boolean)")
    local subStorageNoLock = ItemManagerType:get_method(
        "subStorageNoLock(app.ItemDefine.StorageData, System.Int32, System.Boolean)")

    local function get_enum_members(type_name)
        local type_def = sdk.find_type_definition(type_name)
        if not type_def then return {} end
        local members = {}
        for _, field in ipairs(type_def:get_fields()) do
            if field:is_static() and field:get_name() ~= "value__" then
                local ok, val = pcall(function() return field:get_data(nil) end)
                if ok and val ~= nil then
                    local num = type(val) == "number" and val
                        or (type(val) == "userdata" and tonumber(val:get_field("value__"))) or nil
                    if num and num >= 0 then members[num] = field:get_name() end
                end
            end
        end
        return members
    end

    local CategoryLabels = get_enum_members("app.ItemSubCategory")

    local function ensure_config_defaults()
        for k in pairs(CategoryLabels) do
            local sk = tostring(k)
            if config.Categories[sk] == nil then config.Categories[sk] = false end
        end
    end
    ensure_config_defaults()

    local function process_warehouse_transfer()
        local ItemManager = sdk.get_managed_singleton("app.ItemManager")
        if not ItemManager then return end
        if not forceGetItemToWarehouse or not subStorageNoLock then return end

        local storage_dict = ItemManager:get_field("StorageDict")
        if not storage_dict then return end
        local entries = storage_dict:get_field("_entries")
        if not entries then return end

        for entry_idx = 0, 1 do
            local is_active = (entry_idx == 0 and config.ScanArisen) or (entry_idx == 1 and config.ScanMainPawn)
            if is_active and entries[entry_idx] then
                local item_list = entries[entry_idx]:get_field("value") or entries[entry_idx]:get_field("Value")
                if item_list then
                    local count = item_list:call("get_Count")
                    if count and count > 0 then
                        for i = count - 1, 0, -1 do
                            local master_data = item_list:call("get_Item", i)
                            if master_data then
                                local storage_data = master_data:get_field("_Param")
                                if storage_data and not storage_data:get_field("_IsEquipped") then
                                    local item_data = storage_data:call("get_ItemData")
                                    if item_data then
                                        local is_match = false
                                        if config.CategoryMode == 1 then
                                            local sub_cat_raw = item_data:get_field("_SubCategory")
                                            local sub_cat_num = type(sub_cat_raw) == "number" and sub_cat_raw
                                                or (type(sub_cat_raw) == "userdata" and tonumber(sub_cat_raw:get_field("value__"))) or
                                                -1
                                            if config.Categories[tostring(sub_cat_num)] then
                                                is_match = true
                                            end
                                        elseif config.CategoryMode == 2 then
                                            local cat_raw = item_data:get_field("_Category")
                                            if cat_raw then
                                                local cat_num = type(cat_raw) == "number" and cat_raw
                                                    or (type(cat_raw) == "userdata" and tonumber(cat_raw:get_field("value__"))) or
                                                    -1
                                                if cat_num == 3 then
                                                    is_match = true
                                                end
                                            end
                                        end

                                        if is_match then
                                            local item_id      = item_data:get_field("_Id") or -1
                                            local amount       = storage_data:get_field("_Num") or 0
                                            local enhance_data = storage_data:get_field("_Enhance")
                                            forceGetItemToWarehouse:call(ItemManager, item_id, amount, enhance_data,
                                                false, false, false, 0, false)
                                            subStorageNoLock:call(ItemManager, storage_data, amount, false)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    re.on_frame(function()
        if hk.check_hotkey("Process Warehouse Deposit", nil, true) then
            process_warehouse_transfer()
        end
    end)

    function DepositToWarehouse.draw_ui()
        if imgui.tree_node(MOD_NAME) then
            local changed = false
            if imgui.button("Выполнить разгрузку сумок на склад") then
                process_warehouse_transfer()
            end
            imgui.separator()
            imgui.text("Очищать инвентарь у следующих персонажей:")
            local sa_c, sa_v = imgui.checkbox("Включая инвентарь Восставшего", config.ScanArisen)
            if sa_c then
                config.ScanArisen = sa_v; changed = true
            end
            local sp_c, sp_v = imgui.checkbox("Включая инвентарь Основной пешки", config.ScanMainPawn)
            if sp_c then
                config.ScanMainPawn = sp_v; changed = true
            end
            imgui.separator()
            imgui.text("Режим фильтрации предметов:")
            local mode_c, mode_v = imgui.combo("Метод отбора", config.CategoryMode,
                { "Фильтровать по подкатегориям", "Всю экипировку и снаряжение" })
            if mode_c then
                config.CategoryMode = mode_v; changed = true
            end
            imgui.separator()
            imgui.text("Горячая клавиша для мгновенного сброса:")
            if hk.hotkey_setter("Process Warehouse Deposit") then
                config.Hotkeys["Process Warehouse Deposit"] = hk.hotkeys["Process Warehouse Deposit"]
                changed = true
            end
            if config.CategoryMode == 1 then
                imgui.separator()
                imgui.text("Доступные подкатегории ресурсов:")
                if imgui.tree_node("Показать полный список фильтров") then
                    local keys = {}
                    for k in pairs(CategoryLabels) do table.insert(keys, k) end
                    table.sort(keys)
                    for _, k in ipairs(keys) do
                        local label = string.format("%s  (%d)", CategoryLabels[k], k)
                        local sk    = tostring(k)
                        local c, nv = imgui.checkbox(label, config.Categories[sk] or false)
                        if c then
                            config.Categories[sk] = nv; changed = true
                        end
                    end
                    imgui.tree_pop()
                end
            else
                imgui.separator()
                imgui.text("Активен режим сброса всей экипировки.")
                imgui.text("Сортировка по подкатегориям временно заблокирована.")
            end
            if changed then save_config() end
            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 12. WEAPON ELEMENT (ПОСТОЯННЫЙ ЭЛЕМЕНТАЛЬНЫЙ УРОН ОРУЖИЯ)
-- ════════════════════════════════════════════════════════════════
local WeaponElement = {}
do
    local elements_string    = { "Отсутствует", "Огонь (Fire)", "Лёд (Ice)", "Молния (Thunder)", "Святость (Light)" }
    local element_status_ids = { [2] = 15, [3] = 16, [4] = 17 }
    local all_ids_effect     = { 15, 16, 17, 24 }

    local config_file        = "weapon_element.json"
    local config             = { enabled = false, elementType = 1, applyToPawns = false }

    local function load_config()
        local success, loaded = pcall(function() return json.load_file(config_file) end)
        if success and loaded then
            if type(loaded.enabled) == 'boolean' then config.enabled = loaded.enabled end
            if type(loaded.elementType) == 'number' then config.elementType = loaded.elementType end
            if type(loaded.applyToPawns) == 'boolean' then config.applyToPawns = loaded.applyToPawns end
        end
    end

    local function save_config()
        pcall(function() json.dump_file(config_file, config) end)
    end

    load_config()

    local WEC_REFRESH_INTERVAL = 0.5
    local lastWecRefresh       = 0.0
    local wasEnabled           = false
    local lastElementType      = 0

    local function getPlayerChara()
        local _, _, chara = HelpersA.gm_pla_hum_char()
        return chara
    end

    local function getTargetCharas()
        local targets = {}
        local myChara = getPlayerChara()
        if not myChara then return targets end
        table.insert(targets, myChara)
        if config.applyToPawns then
            local pawnChars = HelpersA.get_pawn_chara_list()
            for _, pc in ipairs(pawnChars) do
                table.insert(targets, pc)
            end
        end
        return targets
    end

    local function isPartyMember(chara)
        if not chara then return false end
        local h = chara:get_field("<CachedHuman>k__BackingField") or chara:call("get_Human")
        if not h then return false end
        return h:call("isPlayerOrPartyPawn") or false
    end

    local function activateWecVisual(chara, elemIdx)
        local elemCtrl = chara:get_field("_WeaponElementController")
        if not elemCtrl then return end
        local effectId = element_status_ids[elemIdx]
        if effectId then
            elemCtrl:call("StatusConditionCtrl_StatusConditionActiveHandler", effectId, 0, false)
        end
    end

    local function deactivateAllWecVisuals(chara)
        local elemCtrl = chara:get_field("_WeaponElementController")
        if not elemCtrl then return end
        for _, eid in ipairs(all_ids_effect) do
            elemCtrl:call("StatusConditionCtrl_StatusConditionInactiveHandler", eid)
        end
    end

    re.on_frame(function()
        local tick = os.clock()

        if wasEnabled and not config.enabled then
            wasEnabled = false
            local targets = getTargetCharas()
            for _, chara in ipairs(targets) do
                deactivateAllWecVisuals(chara)
            end
            lastElementType = 0
            return
        end

        if not config.enabled then return end

        if config.elementType ~= lastElementType then
            local targets = getTargetCharas()
            for _, chara in ipairs(targets) do
                deactivateAllWecVisuals(chara)
                if config.elementType > 1 then
                    activateWecVisual(chara, config.elementType)
                end
            end
            lastElementType = config.elementType
            lastWecRefresh = tick
        end

        if tick - lastWecRefresh < WEC_REFRESH_INTERVAL then return end
        lastWecRefresh = tick
        wasEnabled = true

        if config.elementType <= 1 then return end

        local targets = getTargetCharas()
        for _, chara in ipairs(targets) do
            activateWecVisual(chara, config.elementType)
        end
    end)

    sdk.hook(
        sdk.find_type_definition("app.HitController"):get_method("damageProc(app.HitController.DamageInfo)"),
        function(args)
            if not config.enabled or config.elementType <= 1 then return end

            local dmgInfo = sdk.to_managed_object(args[3])
            if not dmgInfo then return end

            local srcHitCtrl = dmgInfo:get_AttackOwnerHitController()
            if not srcHitCtrl then return end

            local srcChara = srcHitCtrl:get_CachedCharacter()
            if not srcChara then return end

            if not isPartyMember(srcChara) then return end
            if not config.applyToPawns then
                local myChara = getPlayerChara()
                if srcChara ~= myChara then return end
            end

            local elemValue = config.elementType - 1
            dmgInfo:set_ElementType(elemValue)
        end,
        nil
    )

    function WeaponElement.draw_ui()
        if imgui.tree_node("Стихийный урон оружия (Зачарование)") then
            local changed = false
            local c

            c, config.enabled = imgui.checkbox("Активировать постоянный стихийный урон", config.enabled)
            if c then changed = true end

            if config.enabled then
                imgui.same_line()
                c, config.elementType = imgui.combo("##WepElemType", config.elementType, elements_string)
                if c then changed = true end

                c, config.applyToPawns = imgui.checkbox("Применить зачарование к оружию пешек отряда", config.applyToPawns)
                if c then changed = true end
            end

            if changed then save_config() end
            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- 13. USE ALL PAWN SPECIALIZATIONS (ВСЕ СПЕЦИАЛИЗАЦИИ ПЕШЕК СРАЗУ)
-- ════════════════════════════════════════════════════════════════
local PawnSpecializations = {}
do
    local config_file = "pawn_specializations.json"
    local pawn_spec_cfg = {
        unlock_all_specs = false,
        enable_logistician = false,
        logistician_timer = 30.0,
        logistician_auto_move = true,
        logistician_auto_mix = true
    }

    local function load_config()
        local success, loaded = pcall(function() return json.load_file(config_file) end)
        if success and loaded then
            if type(loaded.unlock_all_specs) == 'boolean' then pawn_spec_cfg.unlock_all_specs = loaded.unlock_all_specs end
            if type(loaded.enable_logistician) == 'boolean' then
                pawn_spec_cfg.enable_logistician = loaded
                    .enable_logistician
            end
            if type(loaded.logistician_timer) == 'number' then
                pawn_spec_cfg.logistician_timer = loaded
                    .logistician_timer
            end
            if type(loaded.logistician_auto_move) == 'boolean' then
                pawn_spec_cfg.logistician_auto_move = loaded
                    .logistician_auto_move
            end
            if type(loaded.logistician_auto_mix) == 'boolean' then
                pawn_spec_cfg.logistician_auto_mix = loaded
                    .logistician_auto_mix
            end
        end
    end

    local function save_config()
        pcall(function() json.dump_file(config_file, pawn_spec_cfg) end)
    end

    load_config()

    local enabled_subskills = {
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true
    }

    local function should_force_subskill(id)
        return pawn_spec_cfg.unlock_all_specs and enabled_subskills[id] == true
    end

    local pawn_manager_type = sdk.find_type_definition("app.PawnManager")
    if pawn_manager_type then
        local is_subskill_equipped = pawn_manager_type:get_method(
            "isSubskillEquipped(app.Character, app.PawnDefine.SubSkillID, System.Boolean)")
        local is_subskill_equipped_in_party = pawn_manager_type:get_method(
            "isSubskillEquippedInParty(app.PawnDefine.SubSkillID, System.Boolean)")

        local force_true = false
        if is_subskill_equipped then
            sdk.hook(
                is_subskill_equipped,
                function(args)
                    force_true = false
                    local id = sdk.to_int64(args[4])
                    if should_force_subskill(id) then
                        force_true = true
                    end
                end,
                function(retval)
                    if force_true then
                        return sdk.to_ptr(1)
                    end
                    return retval
                end
            )
        end

        local force_true_in_party = false
        if is_subskill_equipped_in_party then
            sdk.hook(
                is_subskill_equipped_in_party,
                function(args)
                    force_true_in_party = false

                    local id = sdk.to_int64(args[3])
                    if should_force_subskill(id) then
                        force_true_in_party = true
                    end
                end,
                function(retval)
                    if force_true_in_party then
                        return sdk.to_ptr(1)
                    end
                    return retval
                end
            )
        end
    end

    local PawnSubskillType = sdk.find_type_definition("app.decision.condition.PawnSubskill")
    if PawnSubskillType then
        local evaluateImpl = PawnSubskillType:get_method("evaluateImpl(app.decision.condition.ConditionArg)")
        if evaluateImpl then
            local function set_condition_arg_valid(args, value01)
                local cond_arg = sdk.to_valuetype(args[3], "app.decision.condition.ConditionArg")
                if not cond_arg then return end

                cond_arg:set_field("<Valid>k__BackingField", value01)
                args[3] = sdk.to_ptr(cond_arg:get_address())
            end

            sdk.hook(
                evaluateImpl,
                function(args)
                    if not pawn_spec_cfg.unlock_all_specs then return end

                    local this = sdk.to_managed_object(args[2])
                    if not this then return end

                    local subskill_id = this:call("get_SubskillID")
                    local force_enable = should_force_subskill(subskill_id)
                    set_condition_arg_valid(args, force_enable and 1 or 0)
                    if not force_enable then return end

                    this:set_field("_Not", false)
                end,
                nil
            )
        end
    end

    local last_logistician_time = 0

    local ItemManagerType_spec = sdk.find_type_definition("app.ItemManager")
    if ItemManagerType_spec then
        local update_method = ItemManagerType_spec:get_method("onUpdate()")
        local item_mgr = sdk.get_managed_singleton("app.ItemManager")
        if update_method then
            sdk.hook(update_method,
                function(args)
                    if pawn_spec_cfg.enable_logistician and pawn_spec_cfg.unlock_all_specs then
                        local current_time = os.clock()
                        if current_time - last_logistician_time >= pawn_spec_cfg.logistician_timer then
                            if item_mgr then
                                if pawn_spec_cfg.logistician_auto_move then
                                    item_mgr:set_field("IsExecAutoMoveInventory", true)
                                end
                                if pawn_spec_cfg.logistician_auto_mix then
                                    item_mgr:set_field("IsExecAutoMix", true)
                                end
                            end
                        end
                        last_logistician_time = current_time
                    end
                end,
                function(retval) return retval end
            )
        end
    end

    function PawnSpecializations.draw_ui()
        if imgui.tree_node("Специализации пешек") then
            local changed = false
            local c

            c, pawn_spec_cfg.unlock_all_specs = imgui.checkbox("Использовать все 6 специализаций пешек одновременно",
                pawn_spec_cfg.unlock_all_specs)
            if c then changed = true end
            if imgui.is_item_hovered() then
                imgui.set_tooltip("Позволяет отряду одновременно использовать Лекаря, Снабженца, Лесоруба, Переводчика эльфийского и др.")
            end

            imgui.separator()

            if pawn_spec_cfg.unlock_all_specs then
                c, pawn_spec_cfg.enable_logistician = imgui.checkbox("Использовать тонкую настройку Снабженца (Logistician)",
                    pawn_spec_cfg.enable_logistician)
                if c then changed = true end
                if imgui.is_item_hovered() then
                    imgui.set_tooltip("Включает кастомные алгоритмы поведения пешки со специализацией Снабженец")
                end

                if pawn_spec_cfg.enable_logistician then
                    c, pawn_spec_cfg.logistician_timer = imgui.slider_float("Интервал срабатывания (в сек.)",
                        pawn_spec_cfg.logistician_timer, 1.0, 120.0, "%.1f")
                    if c then changed = true end
                    if imgui.is_item_hovered() then
                        imgui.set_tooltip("Как часто Снабженец будет анализировать рюкзаки на перемещение и крафт")
                    end

                    c, pawn_spec_cfg.logistician_auto_move = imgui.checkbox("Разрешить пешке автоматически перераспределять вес по сумкам",
                        pawn_spec_cfg.logistician_auto_move)
                    if c then changed = true end

                    c, pawn_spec_cfg.logistician_auto_mix = imgui.checkbox("Разрешить пешке автоматически объединять/крафтить предметы",
                        pawn_spec_cfg.logistician_auto_mix)
                    if c then changed = true end
                end

                imgui.separator()
            end

            if changed then save_config() end

            imgui.tree_pop()
        end
    end
end

-- ════════════════════════════════════════════════════════════════
-- UNIFIED UI DISPATCHER (ЕДИНЫЙ ДИСПЕТЧЕР ИНТЕРФЕЙСА)
-- ════════════════════════════════════════════════════════════════
re.on_draw_ui(function()
    if imgui.tree_node("Сборник объединенных модов (Combined Mods)") then
        if imgui.tree_node("Боевая система и Геймплей") then
            if ArcherFastAim and ArcherFastAim.draw_ui then ArcherFastAim.draw_ui() end
            if InstantCharge and InstantCharge.draw_ui then InstantCharge.draw_ui() end
            if LockOnRange and LockOnRange.draw_ui then LockOnRange.draw_ui() end
            if MagicArcherBuff and MagicArcherBuff.draw_ui then MagicArcherBuff.draw_ui() end
            if WeaponElement and WeaponElement.draw_ui then WeaponElement.draw_ui() end
            imgui.tree_pop()
        end

        if imgui.tree_node("Утилиты и Помощники") then
            if DepositToWarehouse and DepositToWarehouse.draw_ui then DepositToWarehouse.draw_ui() end
            if DisableBrine and DisableBrine.draw_ui then DisableBrine.draw_ui() end
            if NoEquipRequirement and NoEquipRequirement.draw_ui then NoEquipRequirement.draw_ui() end
            if PawnSpecializations and PawnSpecializations.draw_ui then PawnSpecializations.draw_ui() end
            if EnableSkillsMod and EnableSkillsMod.draw_ui then EnableSkillsMod.draw_ui() end
            if UncapStatsGrowth and UncapStatsGrowth.draw_ui then UncapStatsGrowth.draw_ui() end
            imgui.tree_pop()
        end

        if imgui.tree_node("Визуальные элементы / Карта") then
            if RevealAllMap and RevealAllMap.draw_ui then RevealAllMap.draw_ui() end
            if ShowCurrentHP and ShowCurrentHP.draw_ui then ShowCurrentHP.draw_ui() end
            imgui.tree_pop()
        end

        imgui.tree_pop()
    end
end)
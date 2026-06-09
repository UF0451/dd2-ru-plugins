--/////////////////////////////////////--
-- Fall Damage Manager

-- Author: SilverEzredes
-- Updated: 03/31/2024
-- Version: v1.0.2
-- Special Thanks to: praydog; alphaZomega

--/////////////////////////////////////--
local func = require("_SharedCore\\Functions")
local ui = require("_SharedCore\\Imgui")
local hk = require("Hotkeys\\Hotkeys")

local changed = false
local wc = false
local FDM_PresetsTable = {}

local default_fall_damage_settings = {
    current_preset_indx = 1,
    ---------------------------------------
    HeightDamageForHuman = 8.0,
    BaseDamageForHuman = 200.0,
    DamagePerHeightForHuman = 150.0,
    HeightDieForHuman = 20.0,
    ---------------------------------------
    HeightDamageForHumanVSCh258 = 14.0,
    BaseDamageForHumanVSCh258 = 200.0,
    DamagePerHeightForHumanVSCh258 = 75.0,
    HeightDieForHumanVSCh258 = 24.0,
    ---------------------------------------
    HeightDamageForSmall = 3.5,
    BaseDamageRateForSmall = 0.5,
    HeightDamageForSmall_Normal = 8.0,
    BaseDamageRateForSmall_Normal = 0.3,
    DamageRatePerHeightForSmall = 0.1,
    HeightDieForSmall = 8.0,
    HeightDieForSmall_Normal = 12.0,
    ---------------------------------------
    HeightDamageForLarge = 10.0,
    BaseDamageRateForLarge = 0.1,
    HeightDamageForLarge_Normal = 10.0,
    BaseDamageRateForLarge_Normal = 0.05,
    DamageRatePerHeightForLarge = 0.1,
    HeightDieForLarge = 15.0,
    HeightDieForLarge_Normal = 15.0,
}

local fall_damage_settings = hk.merge_tables({}, default_fall_damage_settings) and hk.recurse_def_settings(json.load_file("SILVER/FallDamage_Settings.json") or {}, default_fall_damage_settings)

local function dump_default_rally_settings()
    json.dump_file("SILVER/FallDamageManager/Default Settings.json", default_fall_damage_settings)
end

dump_default_rally_settings()

local function cache_FDM_json_files()
    local fdm_presets = fall_damage_settings

    if fdm_presets then
        local json_names = FDM_PresetsTable or {}
        local json_filepaths = fs.glob([[SILVER\\FallDamageManager\\.*.json]])

        if json_filepaths then
            for i, filepath in ipairs(json_filepaths) do
                local name = filepath:match("^.+\\(.+)%.")
                local nameExists = false
                local nameIndex
                
                for index, existingName in ipairs(json_names) do
                    if existingName == name then
                        nameExists = true
                        break
                    end
                end
                
                if not nameExists then
                    log.info("[Loaded " .. filepath .. " for Fall Damage Manager]")
                    table.insert(json_names, name)
                end
            end

            for i = #json_names, 1, -1 do
                local nameExists = false
                local name = json_names[i]
                for _, filepath in ipairs(json_filepaths) do
                    if filepath:match("^.+\\(.+)%.") == name then
                        nameExists = true
                        break
                    end
                end
                if not nameExists then
                    log.info("[Removed " .. name .. " from Fall Damage Manager]")
                    table.remove(json_names, i)
                end
            end

        else
            log.info("[No Fall Damage Manager JSON files found.]")
        end
    end
end

cache_FDM_json_files()

local characterManager = sdk.get_managed_singleton("app.CharacterManager")
local function get_CharacterManager()
    if characterManager == nil then characterManager = sdk.get_managed_singleton("app.CharacterManager") end
	return characterManager
end

local function update_PlayerFallDMG()
    if characterManager then
        local manualPlayer = characterManager:call("get_ManualPlayer()")

        if manualPlayer then
            local manualPlayer_FallDMGCalc = manualPlayer:get_field("<FallDamageParamCalc>k__BackingField")

            if manualPlayer_FallDMGCalc then
                local manualPlayer_FallDMGCalc_Param = manualPlayer_FallDMGCalc:get_field("<Param>k__BackingField")

                if manualPlayer_FallDMGCalc_Param then
                    manualPlayer_FallDMGCalc_Param.HeightDamageForHuman = fall_damage_settings.HeightDamageForHuman
                    manualPlayer_FallDMGCalc_Param.BaseDamageForHuman = fall_damage_settings.BaseDamageForHuman
                    manualPlayer_FallDMGCalc_Param.DamagePerHeightForHuman = fall_damage_settings.DamagePerHeightForHuman
                    manualPlayer_FallDMGCalc_Param.HeightDieForHuman = fall_damage_settings.HeightDieForHuman

                    manualPlayer_FallDMGCalc_Param.HeightDamageForHumanVSCh258 = fall_damage_settings.HeightDamageForHumanVSCh258
                    manualPlayer_FallDMGCalc_Param.BaseDamageForHumanVSCh258 = fall_damage_settings.BaseDamageForHumanVSCh258
                    manualPlayer_FallDMGCalc_Param.DamagePerHeightForHumanVSCh258 = fall_damage_settings.DamagePerHeightForHumanVSCh258
                    manualPlayer_FallDMGCalc_Param.HeightDieForHumanVSCh258 = fall_damage_settings.HeightDieForHumanVSCh258

                    manualPlayer_FallDMGCalc_Param.HeightDamageForSmall = fall_damage_settings.HeightDamageForSmall
                    manualPlayer_FallDMGCalc_Param.BaseDamageRateForSmall = fall_damage_settings.BaseDamageRateForSmall
                    manualPlayer_FallDMGCalc_Param.HeightDamageForSmall_Normal = fall_damage_settings.HeightDamageForSmall_Normal
                    manualPlayer_FallDMGCalc_Param.BaseDamageRateForSmall_Normal = fall_damage_settings.BaseDamageRateForSmall_Normal
                    manualPlayer_FallDMGCalc_Param.DamageRatePerHeightForSmall = fall_damage_settings.DamageRatePerHeightForSmall
                    manualPlayer_FallDMGCalc_Param.HeightDieForSmall = fall_damage_settings.HeightDieForSmall
                    manualPlayer_FallDMGCalc_Param.HeightDieForSmall_Normal = fall_damage_settings.HeightDieForSmall_Normal

                    manualPlayer_FallDMGCalc_Param.HeightDamageForLarge = fall_damage_settings.HeightDamageForLarge
                    manualPlayer_FallDMGCalc_Param.BaseDamageRateForLarge = fall_damage_settings.BaseDamageRateForLarge
                    manualPlayer_FallDMGCalc_Param.HeightDamageForLarge_Normal = fall_damage_settings.HeightDamageForLarge_Normal
                    manualPlayer_FallDMGCalc_Param.BaseDamageRateForLarge_Normal = fall_damage_settings.BaseDamageRateForLarge_Normal
                    manualPlayer_FallDMGCalc_Param.DamageRatePerHeightForLarge = fall_damage_settings.DamageRatePerHeightForLarge
                    manualPlayer_FallDMGCalc_Param.HeightDieForLarge = fall_damage_settings.HeightDieForLarge
                    manualPlayer_FallDMGCalc_Param.HeightDieForLarge_Normal = fall_damage_settings.HeightDieForLarge_Normal
                end
            end
        end
    end
end

re.on_frame(function ()
    get_CharacterManager()
    update_PlayerFallDMG()
end)

re.on_draw_ui(function()
    if imgui.tree_node("Настройки урона от падения") then
        imgui.begin_rect()
        if imgui.button("Сбросить") then
            wc = true
            changed = true
            cache_FDM_json_files()
            fall_damage_settings = hk.recurse_def_settings({}, default_fall_damage_settings)
        end
        func.tooltip("Сбросить все параметры.")
        imgui.same_line()
        imgui.button("|")
        imgui.same_line()
        
        if imgui.button("Обновить список") then
            wc = true
            cache_FDM_json_files()
        end

        imgui.same_line()
        imgui.button("|")
        imgui.same_line()

        if imgui.button("Сохранить пресет") then
            json.dump_file("SILVER/FallDamageManager/SavedPreset.json", fall_damage_settings)
            cache_FDM_json_files()
        end
        func.tooltip("Сохранить текущий пресет в 'SavedPreset.json' (файл можно переименовать) в [Dragons Dogma 2/reframework/data/SILVER/FallDamageManager/]")

        changed, fall_damage_settings.current_preset_indx = imgui.combo("Пресет", fall_damage_settings.current_preset_indx or 1, FDM_PresetsTable); wc = wc or changed
        func.tooltip("Выберите файл из выпадающего меню для загрузки настроек.")
        if changed then
            local selected_preset = FDM_PresetsTable[fall_damage_settings.current_preset_indx]
            local json_filepath = [[SILVER\\FallDamageManager\\]] .. selected_preset .. [[.json]]
            local temp_parts = json.load_file(json_filepath)
            
            temp_parts.Presets = nil
            temp_parts.current_preset_indx = nil

            for key, value in pairs(temp_parts) do
                fall_damage_settings[key] = value
            end
        end

        imgui.spacing()
        
        changed, fall_damage_settings.HeightDamageForHuman = imgui.drag_float("Порог урона от падения", fall_damage_settings.HeightDamageForHuman, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Высота, с которой персонажи обычного размера начинают получать урон от падения. Чем выше, тем лучше.")
        changed, fall_damage_settings.BaseDamageForHuman = imgui.drag_float("Базовый урон от падения", fall_damage_settings.BaseDamageForHuman, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Базовое значение урона от падения для персонажей обычного размера. Чем ниже, тем лучше.")
        changed, fall_damage_settings.DamagePerHeightForHuman = imgui.drag_float("Дополнительный урон от падения", fall_damage_settings.DamagePerHeightForHuman, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Дополнительное значение урона от падения для персонажей обычного размера. Чем ниже, тем лучше.")
        changed, fall_damage_settings.HeightDieForHuman = imgui.drag_float("Смертельная высота", fall_damage_settings.HeightDieForHuman, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Высота, при падении с которой персонажи обычного размера погибают. Чем выше, тем лучше.")
                              
        imgui.spacing()
        
        changed, fall_damage_settings.HeightDamageForHumanVSCh258 = imgui.drag_float("Порог урона от падения (Ch258)", fall_damage_settings.HeightDamageForHumanVSCh258, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("TDB")
        changed, fall_damage_settings.BaseDamageForHumanVSCh258 = imgui.drag_float("Базовый урон от падения (Ch258)", fall_damage_settings.BaseDamageForHumanVSCh258, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("TDB")
        changed, fall_damage_settings.DamagePerHeightForHumanVSCh258 = imgui.drag_float("Дополнительный урон от падения (Ch258)", fall_damage_settings.DamagePerHeightForHumanVSCh258, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("TDB")
        changed, fall_damage_settings.HeightDieForHumanVSCh258 = imgui.drag_float("Смертельная высота (Ch258)", fall_damage_settings.HeightDieForHumanVSCh258, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("TDB")

        imgui.spacing()

        changed, fall_damage_settings.HeightDamageForSmall = imgui.drag_float("Порог урона от падения (Маленькие)", fall_damage_settings.HeightDamageForSmall, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Высота, с которой маленькие персонажи начинают получать урон от падения. Чем выше, тем лучше.")
        changed, fall_damage_settings.BaseDamageRateForSmall = imgui.drag_float("Множитель базового урона от падения (Маленькие)", fall_damage_settings.BaseDamageRateForSmall, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Множитель базового урона от падения для маленьких персонажей. Чем ниже, тем лучше.")
        changed, fall_damage_settings.HeightDamageForSmall_Normal = imgui.drag_float("Порог урона от падения (Мал-Обычные)", fall_damage_settings.HeightDamageForSmall_Normal, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Высота, с которой обычные маленькие персонажи начинают получать урон от падения. Чем выше, тем лучше.")
        changed, fall_damage_settings.BaseDamageRateForSmall_Normal = imgui.drag_float("Множитель базового урона от падения (Мал-Обычные)", fall_damage_settings.BaseDamageRateForSmall_Normal, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Множитель базового урона от падения для обычных маленьких персонажей. Чем ниже, тем лучше.")
        changed, fall_damage_settings.DamageRatePerHeightForSmall = imgui.drag_float("Множитель доп. урона от падения (Маленькие)", fall_damage_settings.DamageRatePerHeightForSmall, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Множитель дополнительного урона от падения для маленьких персонажей. Чем ниже, тем лучше.")
        changed, fall_damage_settings.HeightDieForSmall = imgui.drag_float("Смертельная высота (Маленькие)", fall_damage_settings.HeightDieForSmall, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Высота, при падении с которой маленькие персонажи погибают. Чем выше, тем лучше.")
        changed, fall_damage_settings.HeightDieForSmall_Normal = imgui.drag_float("Смертельная высота (Мал-Обычные)", fall_damage_settings.HeightDieForSmall_Normal, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Высота, при падении с которой обычные маленькие персонажи погибают. Чем выше, тем лучше.")

        imgui.spacing()

        changed, fall_damage_settings.HeightDamageForLarge = imgui.drag_float("Порог урона от падения (Большие)", fall_damage_settings.HeightDamageForLarge, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Высота, с которой большие персонажи начинают получать урон от падения. Чем выше, тем лучше.")
        changed, fall_damage_settings.BaseDamageRateForLarge = imgui.drag_float("Множитель базового урона от падения (Большие)", fall_damage_settings.BaseDamageRateForLarge, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Множитель базового урона от падения для больших персонажей. Чем ниже, тем лучше.")
        changed, fall_damage_settings.HeightDamageForLarge_Normal = imgui.drag_float("Порог урона от падения (Бол-Обычные)", fall_damage_settings.HeightDamageForLarge_Normal, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Высота, с которой обычные большие персонажи начинают получать урон от падения. Чем выше, тем лучше.")
        changed, fall_damage_settings.BaseDamageRateForLarge_Normal = imgui.drag_float("Множитель базового урона от падения (Бол-Обычные)", fall_damage_settings.BaseDamageRateForLarge_Normal, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Множитель базового урона от падения для обычных больших персонажей. Чем ниже, тем лучше.")
        changed, fall_damage_settings.DamageRatePerHeightForLarge = imgui.drag_float("Множитель доп. урона от падения (Большие)", fall_damage_settings.DamageRatePerHeightForLarge, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Множитель дополнительного урона от падения для больших персонажей. Чем ниже, тем лучше.")
        changed, fall_damage_settings.HeightDieForLarge = imgui.drag_float("Смертельная высота (Большие)", fall_damage_settings.HeightDieForLarge, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Высота, при падении с которой большие персонажи погибают. Чем выше, тем лучше.")
        changed, fall_damage_settings.HeightDieForLarge_Normal = imgui.drag_float("Смертельная высота (Бол-Обычные)", fall_damage_settings.HeightDieForLarge_Normal, 0.01, 0.01, 10000.0); wc = wc or changed
        func.tooltip("Высота, при падении с которой обычные большие персонажи погибают. Чем выше, тем лучше.")

        imgui.spacing()

        -- ui.button_n_colored_txt("Current Version:", "v1.0.2 | 03/31/2024", 0xFF00FF00)
        imgui.same_line()
        imgui.text("| by SilverEzredes")

        if changed or wc then
            json.dump_file("SILVER/FallDamage_Settings.json", fall_damage_settings)
        end

        imgui.end_rect(1)
        imgui.tree_pop()
    end
end)
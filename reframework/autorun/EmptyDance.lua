local re = re
local sdk = sdk
local log = log
local json = json
local hotkeys = require("Hotkeys/Hotkeys")

log.info("[Empty Dance] Успешно загружен");

local Config = {}

Config.Hotkeys = {
    ["Input Key"] = "Space",
}

if Config.EnableMod == nil then
    Config.EnableMod = true
end

if Config.EnableInfinite == nil then
    Config.EnableInfinite = false
end

if Config.Mode == nil then
    Config.Mode = {
        "Двойной прыжок",
        "Левитация"
    }
end

if Config.CurMode == nil then
    Config.CurMode = 1
end

local configFilePath = "EmptyDance\\EmptyDance.json"

hotkeys.setup_hotkeys(Config.Hotkeys)

local function saveConfig()
    local success, err = pcall(json.dump_file, configFilePath, Config)
    if not success then
        log.error("Ошибка сохранения конфигурации EmptyDance: " .. tostring(err))
    end
end

local function loadConfig()
    local status, data = pcall(json.load_file, configFilePath)
    if not status or not data then
        return
    end

    if type(data) == "table" then
        if data.Hotkeys then
            Config.Hotkeys = data.Hotkeys
            hotkeys.setup_hotkeys(Config.Hotkeys)
        end
        Config.EnableMod = data.EnableMod
        -- Перезаписываем режимы на русский, чтобы интерфейс ImGui всегда оставался локализованным
        Config.Mode = { "Двойной прыжок", "Левитация" }
        Config.CurMode = data.CurMode
        Config.EnableInfinite = data.EnableInfinite
    end
end

loadConfig()

local InputState = {
    ["None"] = 0,
    ["LevitateStart"] = 1,
    ["LevitateKeep"] = 2,
    ["LevitateEnd"] = 3,
}

local currentState = InputState["None"]

function getPlayer()
    local cm = sdk.get_managed_singleton("app.CharacterManager")
    if not cm then return nil end
    local player = cm:get_ManualPlayer()
    return player
end

local function generate_enum(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

            enum[name] = raw_value
        end
    end

    return enum
end

local UpDownModeEnum = generate_enum("app.LevitateController.UpDownModeEnum")
local IDEnum = generate_enum("app.CharacterID")

local set_node_method = sdk.find_type_definition("via.motion.MotionFsm2Layer"):get_method("setCurrentNode(System.String, via.behaviortree.SetNodeInfo, via.motion.SetMotionTransitionInfo)")

local pIP = nil

sdk.hook(
    sdk.find_type_definition("app.PlayerInputProcessor"):get_method("processMove()"),
    function(args)
        pIP = sdk.to_managed_object(args[2])
    end,
    function(rtVal)
        if pIP ~= nil then
            if Config.EnableMod and Config.CurMode == 2 then
                local chara = pIP:get_Chara()
                if chara and chara:get_CharaID() == IDEnum["ch000000_00"] and (currentState == InputState["LevitateStart"] or currentState == InputState["LevitateKeep"]) then
                    local job03Detail = pIP.DetailInstances and pIP.DetailInstances[2]
                    if job03Detail then
                        sdk.call_object_func(job03Detail, "processMoveSpecial")
                    end
                end
            end
        end
        return rtVal
    end
)

local isDoubleJumping = false

local setn = ValueType.new(sdk.find_type_definition("via.behaviortree.SetNodeInfo"))
setn:call("set_Fullname", true)
local interper = sdk.create_instance("via.motion.SetMotionTransitionInfo"):add_ref()
interper:set_InterpolationFrame(20.0)

local player = nil
local notInGroundFrameCounter = 0
local levitateKeyPressingCounter = 0

re.on_application_entry("LateUpdateBehavior", function()
    if Config.EnableMod then
        player = getPlayer()

        -- ИСПРАВЛЕНО: Строгая проверка на существование игрока перед любыми физическими запросами
        if player ~= nil and sdk.is_managed_object(player) then
            
            local isGroundOk, isGround = pcall(function() return player:get_IsGround() end)
            if not isGroundOk then return end -- Безопасно выходим из кадра, если движок выбросил исключение

            if not isGround then
                notInGroundFrameCounter = notInGroundFrameCounter + 1
            else
                currentState = InputState["None"]
                notInGroundFrameCounter = 0
                isDoubleJumping = false
            end

            if notInGroundFrameCounter > 5 then
                local human = player:get_Human()
                local levitate = human and human:get_LevitateCtrl()
                if not levitate then return end

                if Config.CurMode == 1 and (not isDoubleJumping or Config.EnableInfinite) and not levitate:get_IsActive() and hotkeys.check_hotkey("Input Key", false, true) then
                    local gameobj = player:get_GameObject()
                    local mfsm2 = gameobj and gameobj:call("getComponent(System.Type)", sdk.typeof("via.motion.MotionFsm2"))
                    
                    if mfsm2 then
                        local setn_local = ValueType.new(sdk.find_type_definition("via.behaviortree.SetNodeInfo"))
                        setn_local:call("set_Fullname", true)
                        local interper_local = sdk.create_instance("via.motion.SetMotionTransitionInfo"):add_ref()
                        interper_local:set_InterpolationFrame(20.0)

                        set_node_method:call(mfsm2:getLayer(0), "Job04.Job04_SkillAttack.Job04_CS10.Job04_WindWaveAir", setn_local, interper_local)
                        isDoubleJumping = true
                        notInGroundFrameCounter = 0
                    end
                elseif Config.CurMode == 2 then
                    if hotkeys.check_hotkey("Input Key", true, false) then
                        levitateKeyPressingCounter = levitateKeyPressingCounter + 1
                    elseif hotkeys.chk_up("Input Key") then
                        levitateKeyPressingCounter = 0
                    end

                    if levitateKeyPressingCounter > 5 and (currentState == InputState["None"] or Config.EnableInfinite) then
                        currentState = InputState["LevitateStart"]
                        local gameobj = player:get_GameObject()
                        local mfsm2 = gameobj and gameobj:call("getComponent(System.Type)", sdk.typeof("via.motion.MotionFsm2"))
                        if mfsm2 then
                            set_node_method:call(mfsm2:getLayer(0), "JobMagicUser.JobMagicUser_StartLevitate", setn, interper)
                        end
                    end

                    if currentState == InputState["LevitateStart"] then
                        if hotkeys.chk_up("Input Key") or (levitateKeyPressingCounter > 60 and not Config.EnableInfinite) then
                            levitate.UpDownMode = UpDownModeEnum["Keep"]
                            currentState = InputState["LevitateKeep"]
                            levitateKeyPressingCounter = 0
                        end
                    end

                    if currentState == InputState["LevitateKeep"] then
                        if hotkeys.check_hotkey("Input Key", false, true) then
                            local gameobj = player:get_GameObject()
                            local mfsm2 = gameobj and gameobj:call("getComponent(System.Type)", sdk.typeof("via.motion.MotionFsm2"))
                            if mfsm2 then
                                set_node_method:call(mfsm2:getLayer(0), "JobMagicUser.JobMagicUser_EndLevitate", setn, interper)
                                currentState = InputState["LevitateEnd"]
                                levitateKeyPressingCounter = 0
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ── РУСИФИЦИРОВАННЫЙ ИНТЕРФЕЙС НАСТРОЕК ──────────────────────────────────────
re.on_draw_ui(function()
    if imgui.tree_node("Воздушный танец (Empty Dance)") then
        local changed = false
        local EnableInfiniteChanged = false
        local CurModeChanged = false
        local KeyChanged = false

        changed, Config.EnableMod = imgui.checkbox("Включить мод", Config.EnableMod)

        EnableInfiniteChanged, Config.EnableInfinite = imgui.checkbox("Бесконечные прыжки / Левитация", Config.EnableInfinite)

        CurModeChanged, Config.CurMode = imgui.combo("Выбор режима", Config.CurMode, Config.Mode)

        local fakeName = "Клавиша двойного прыжка"
        if Config.CurMode == 2 then
            fakeName = "Клавиша левитации"
        end
        KeyChanged = hotkeys.hotkey_setter("Input Key", false, fakeName)

        if changed or EnableInfiniteChanged or CurModeChanged or KeyChanged then
            hotkeys.update_hotkey_table(Config.Hotkeys)
            saveConfig() 
        end

        imgui.tree_pop()
    end
end)
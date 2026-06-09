--[[ EnemySpawner 1.1.0
[BUGFIX] fix issue with DD2 update released on 10-03-2024
[BUGFIX] fixed issue with multispawn causing game crash
[BUGFIX] fix issue where Hobgoblin and Knackers would spawn with incorrect size (Spawn+)
+ ability to remove spawn limit by setting limit to 0
+ prevent Spawn+ from spawning duplicates of certain monsters
]]

-- GLOBALS
local modName = "EnemySpawner"
local enableLog = false
local enableDebugUI = false
local common = require("EnemySpawner/common")
local spawnRequest = require("EnemySpawner/spawnRequest")
local charRef = require("EnemySpawner/charRef")
local input = require("EnemySpawner/input")
--local toastManager = require("EnemySpawner/REToast")
local SpawnEdit = require("EnemySpawner/spawnEdit")
-- local toastLvl = 99 --[[ 1: DEBUG  /  99: DIST ]]
-- if enableDebugUI then toastLvl = 1 end
-- local tm = toastManager:new(toastLvl)

local _log = function(a,b) common.log.log(enableLog, modName, a,b) end
local logArgs = function(args, _from, types) _log(_from, common.log.hookArgs(args,types)) end
-- GameObjects


_log('MOD','STARTED')
-- tm:toast("[MOD_START] EnemySpawner")
-- if enableLog then
--     tm:toast("DEBUG", tm.DEBUG)
--     tm:toast("NORMAL", tm.NORMAL)
--     tm:toast("SUCCESS", tm.SUCCESS)
--     tm:toast("WARNING", tm.WARNING)
--     tm:toast("ERROR", tm.FAIL)
--     tm:toast("NONE", tm.NONE)
--     tm:toast("INFO", tm.INFO)
--     tm:toast("ALERT", tm.ALERT)
-- end

local default_config = {
    ["spawnCharRefID"] = 1,
    ["ovrScale"] = {
        ["enable"] = false,
        ["scale"] = 1.000,
        ["normalizeSpeed"] = false,
    },
    ["asBoss"] = false,
    ["spawnIdle"] = true,
    ["instLimit"] = 50,
    ["spawnMultiple"] = {
        ["enable"] = false,
        ["qty"] = 10
    },
    ["forceClimb"] = false,
    ["globalSpawn"] = {
        ["StrayPawn"] = {["disable"] = false, ["limit"] = nil},
        ["Monster"] = {["disable"] = false, ["limit"] = nil},
        ["NPC"] = {["disable"] = false, ["limit"] = nil},
        ["Gimmick"] = {["disable"] = false, ["limit"] = nil},
        ["Other"] = {["disable"] = false, ["limit"] = nil},    
    },
    ["bigHead"] = false,
    ["debug_human_only"] = false,
    ["spawnEdit"] = {
        ["repl"] = {
            ["enable"] = false,
            ["qty"] = 1
        },
        ["ovrScale"] = {
            ["enable"] = false,
            ["scale"] = 1.000,
            ["normalizeSpeed"] = false,
        },
        ["attr"] = {
            ["attack"] = 1.000,
            ["defense"] = 1.000,
        },
        ["randomBoss"] = false,
        ["NPC"] = {
            ["naked"] = false,
            ["kidSized"] = false,
            ["sonic"] = false,
            ["drunk"] = false,
            
        }
    },
    ["hotkeys"] = {
        ["enable"] = true,
        ["spawn"] = 107,
        ["deleteLast"] = 109,
        ["deleteAll"] = 106
    }
}

local goList = {
    {
        ["GuiManager"] = {"app.GuiManager", "MS"},
        ["CharacterManager"] = {"app.CharacterManager", "MS"}
    },
    {
        ["Character"] = {"CharacterManager", "get_ManualPlayer"}
    }

}

--[[ load json configuration from json file or use default configuration if
file does not exist in the game data folder ]]
--local config = json.load_file(configfile) or default_config
local config = common.config.get(modName,default_config)
local _changed = false
-- prevent freezing the load screen by ensuring that NPC Spawning is not disabled
config.globalSpawn.NPC.disable = false
-- update the json configfile within the game folder
local saveConfig = function() 
    common.config.save(modName,config) 
end

--[[ GLOBALS ]]
local go = nil
local spawner = nil
local spawnEditor = nil
input:init()
local btnState = {}
for k,_ in pairs(config.hotkeys) do
    btnState[k] = 0
end
local triggerHold = {
    ["spawn"] = false,
}
local hotkeyLabels = {
    spawn = "Спавн",
    deleteLast = "Удалить последний",
    deleteAll = "Удалить всё",
}
local catLabels = {
    StrayPawn = "Чужая пешка",
    Monster = "Монстр",
    NPC = "NPC",
    Gimmick = "Гиммик",
    Other = "Прочее",
}
local catType = {"Pawn","StrayPawn","Monster","NPC","Gimmick","Other"}

--[[ DEBUG GLOBALS]]
local debug_spawner_reference = nil
local hookArgHist = {}
local captureCharacterData = nil
local captureScaleArgsList = {}
local vecBigHead = nil
local firstGetScaleReturn = nil
local objTitleCache = {}

--[[ UTILITY METHODS]]
local function isInitialized()
    return 
        go ~= nil
        and go.Character ~= nil
        and go.GuiManager ~= nil
        and spawner ~= nil
        and spawnEditor ~= nil
end 

local function deleteLast() 
    if spawner ~= nil then spawner:deleteLast() end
end

local function deleteAll() 
    if spawner ~= nil then spawner:deleteAll() end
end

local function modCleanup()
    if go ~= nil then 
        go.cleanup()
        deleteAll()
    end
end

-- setup managed objects that need to wait until runtime availability
local function initManagedObjects(_force)
    if not isInitialized() or _force then
        --tm:toast("INITIALIZE",tm.WARNING)
        if _force then 
            modCleanup()
            --tm:toast("FORCE INITIALIZE", tm.ERROR)     
        end
        go = common.gameObjects
        go.init(goList)
        if go and go.GuiManager and go.GuiManager.IsPlayerEnable then
            spawner = spawnRequest:new()
            spawner:updateConfig(config)
            if config and config.spawnEdit then
                spawnEditor = SpawnEdit:new(config.spawnEdit)
            end
        end
    end
end
initManagedObjects()

-- apply changes in gui value and save current configuration
local function saveAndApply(_changed)
    if _changed then 
        saveConfig()
        if not isInitialized() then 
            --tm:toast("[saveAndApply] not initialized", tm.WARNING)
            initManagedObjects() 
        end 
        if spawnEditor then spawnEditor:updateConfig(config.spawnEdit) end
        if spawner then spawner:updateConfig(config) end
        _changed = false
    end
end



local function getCharPos()
    if go and go.Character and sdk.is_managed_object(go.Character) then
        local ok, pos = pcall(go.Character.call, go.Character, "get_LastGroundPosition")
        if ok then return pos end
    end
    return nil
end

local function setSpawnTriggers(_state)
    local state = _state or false
    triggerHold.spawn = state
end

local function getSpawnQty()
    local _n = 1 
    if config and config.spawnMultiple and config.spawnMultiple.enable then 
        _n = config.spawnMultiple.qty 
    end
    return _n
end

local function isAnySpawnDisabled()
    for _,cnf in pairs(config.globalSpawn) do 
        if cnf.disable then return true end
    end
    return false
end

local function isAnimalPrefabCtrl(a)
    local isAnimal = false
    local status, e = pcall(function()
        local pfbCtrl = sdk.to_managed_object(a)
        if pfbCtrl then 
            local pfb = pfbCtrl:get_Item()
            if pfb then 
                local path = pfb:get_Path()
                if path then 
                    if string.match(path, "ch299") then 
                        --tm:toast("ISANIMAL: True")
                        isAnimal =  true
                    end
                end
            end
        end
    end)
    return isAnimal
end

local function posString(_name, _pos)
    if _pos and _pos.x then 
        return string.format("[%s] [%.2f||%.2f||%.2f]", _name, _pos.x, _pos.y, _pos.z)
    end
    return string.format("[%s] Н/Д",_name)
end

local function startSpawn()
    --tm:toast("SPAWN TRIGGER", tm.WARNING)
    if not isInitialized() then initManagedObjects() end
    if isInitialized() then 
        local charPosRot = go.Character:get_field("<PosRotContext>k__BackingField")
        --tm:toast("[SPAWN][NORMAL]")
        spawner:requestAddInstances(
            charRef.enemyList[config.spawnCharRefID].cid, 
            getCharPos(), 
            charPosRot:get_Rot(),
            config,
            getSpawnQty()
        )
        setSpawnTriggers(false)
        if debug_spawner_reference == nil then  
            debug_spawner_reference = spawner
        end
    end
end

-- [[ WIP FUNCTIONS ]]
--NOT WORKING YET
local function getCharaName(cid)
    if go and go.GUIBase then 
        local _res = go.GUIBase:getName(cid)
        --tm:toast(string.format("[%s] --> %s", tostring(cid), tostring(_res)))
        if _res then
            return _res
        else
            return "Н/Д"
        end
    end
    return "Не инициализировано"
end

--[[ DEBUG ONLY METHODS ]]
local function getObjTitle(_h,i)
    local h = nil
    if _h ~= nil and _h["argObjs"] ~= nil then 
        h = _h["argObjs"] 
    end
    if #objTitleCache >= i then return objTitleCache[i] end
    local _outTitle = string.format("[%s]",i) 
    if h ~= nil and #h >= 3 and h[3]:get_type_definition():get_full_name() == 'app.GenerateInfo.GenerateInfoContainer' then 
        --TEMP 
        _outTitle = _outTitle .."C"
        local cInfo = h[3]:get_field("_CommonInfo")
        local cat = nil 
        local objID = nil
        local charID = nil
        local gmckID = nil
        if cInfo then 
            cat = cInfo:get_field("_Category")
            if cat > 0 and cat <= 6 then 
                _outTitle = _outTitle .. string.format("[%s] ", catType[cat])
            end
            objID = cInfo:get_field("_ObjectID")
            if objID then 
                charID = objID:get_field("_SelectedCharacterID")
                if spawner and charID > 0 then
                    _outTitle = _outTitle .. spawner.enums.charID.byValue[charID]
                end
                gmckID = objID:get_field("_SelectedGimmickID")
                if spawner and gmckID > 0 then
                    _outTitle = _outTitle .. spawner.enums.gmckID.byValue[gmckID]
                end
            end
        end
    end
    table.insert(objTitleCache, _outTitle)
    return _outTitle
end


--[[ HOOK/TRIGGERS]]
re.on_application_entry("UpdateHID", 
    function() 
        if config.hotkeys.enable then
            local debugStrings = ""
            local change = false
            for k,v in pairs(btnState) do 
                if k ~= 'enable' then
                    if config.hotkeys and config.hotkeys[k] then
                        local oldState = btnState[k]
                        btnState[k] = input:checkState('kb', config.hotkeys[k])
                        if btnState[k] ~= oldState then change = true end
                        debugStrings = debugStrings .. string.format("[%s] %s ", k, btnState[k])
                    end
                end
            end
            if change then 
                _log('btnstate', debugStrings) 
                --tm:toast(debugStrings, 1)
                end

            if btnState.spawn == 2 then 
                --() 
                setSpawnTriggers(true)
            end
            if btnState.deleteLast == 2 then deleteLast() end
            if btnState.deleteAll == 2 then deleteAll() end
        end
    end)

sdk.hook(sdk.find_type_definition("app.MainFlowManager"):get_method("LoadSaveDataSuccess"),nil,
function(r)
    --tm:toast("[DONE] LoadSaveDataSuccess", tm.WARNING)
    if config and config.globalSpawn and config.globalSpawn.NPC then
        config.globalSpawn.NPC.disable = false
    end
    return r
end)

sdk.hook(sdk.find_type_definition("app.CharacterManager"):get_method("requestSetUpPlayer"),nil,
function(r)
    --tm:toast("[DONE] requestSetUpPlayer", tm.WARNING)
    initManagedObjects()
    return r
end)

sdk.hook(sdk.find_type_definition("app.GenerateManager"):get_method('requestCreateInstance(app.PrefabController, app.GenerateInfo.GenerateInfoContainer, System.Int32, app.InstanceInfo, System.Action`2<app.PrefabInstantiateResults,app.DummyArg>, System.Action`2<app.PrefabInstantiateResults,app.DummyArg>)'),
    function(args)
        if enableLog then 
            --logArgs(args, 'requestCreateInstance', {nil,nil,'int',nil,nil,nil,nil,nil,nil})
            local haText = common.log.hookArgs(args,{nil,nil,'int',nil,nil,nil,nil,nil,nil})
            if #common.log.hookArgObjs > 0 then 
                table.insert(hookArgHist, {["text"] = haText, ["argObjs"] = common.log.hookArgObjs})
                if #common.log.hookArgObjs > 40 then 
                    table.remove(common.log.hookArgObjs,1)
                end
            end
            
        end
    end,
    function(retval) return retval end
)

sdk.hook(sdk.find_type_definition("app.GenerateManager"):get_method('requestCreateInstance(app.GeneratorCategory, app.PrefabController, app.GenerateInfo.GenerateInfoContainer, System.Int32, System.Action`2<app.PrefabInstantiateResults,app.DummyArg>, System.Action`2<app.PrefabInstantiateResults,app.DummyArg>)'),
    function(args)
        local genCat = sdk.to_int64(args[3])
        local reqID = sdk.to_int64(args[6])
        if not isInitialized() then initManagedObjects() end
        if genCat == 3
            and spawner ~= nil
            and not isAnimalPrefabCtrl(args[4])
            --and not spawner:isUsedRequestID(reqID)
            --and spawnEditor ~= nil 
            and config
            and config.spawnEdit
            and config.spawnEdit.repl
            and config.spawnEdit.repl.enable 
            and config.spawnEdit.repl.qty
        then 
            local pfbCtrl = sdk.to_managed_object(args[4])
            local container = sdk.to_managed_object(args[5])
            --local fPre = sdk.to_managed_object(args[7])
            --local fPost = sdk.to_managed_object(args[8])
            if pfbCtrl ~= nil and container ~= nil then 
                spawner:requestReplInstances(pfbCtrl,container,config.spawnEdit.repl.qty)

            end
        -- elseif genCat == 4 
        --     and spawnEditor ~= nil 
        --     and config
        --     and config.spawnEdit 
        --     and config.spawnEdit.NPC 
        --     and #args >= 5 then
        --     spawnEditor:modifyNPCContainer(args[5])
        end


        --[[
            app.GeneratorCategory
                0   Arisen
                1   Pawn 
                2   StrayPawn
                3   Monster
                4   NPC
                5   Gimmick -- such as oxcarts
                6   Other -- misc interactable objects
        ]]
        if isAnySpawnDisabled() then 
            if args and args[3] then 
                --for i,cnd in ipairs({false, config.globalSpawn.StrayPawn, config.disableSpawn.Monster, config.disableSpawn.NPC, config.disableSpawn.Gimmick, config.disableSpawn.Other}) do 
                for i,cat in ipairs({"StrayPawn","Monster","NPC","Gimmick","Other"}) do 
                    if config.globalSpawn[cat].disable and genCat == i+1 then 
                        --tm:toast(string.format("[SKIP] %s spawning disabled", cat),tm.WARNING)
                        return sdk.PreHookResult.SKIP_ORIGINAL 
                    end
                end
            end
        end
    end,
    function(retval) return retval end
)



-- REFramework gui menu setup
re.on_draw_ui(function()
    if imgui.tree_node(modName) then
        imgui.set_next_item_open(true)
        if imgui.collapsing_header("Спавнер врагов") then
            _changed, config.spawnCharRefID = imgui.combo("##SpawnChar", config.spawnCharRefID, charRef.selectOptions)
            saveAndApply(_changed)
            imgui.same_line()
            if imgui.button("Спавн") then setSpawnTriggers(true) end
            imgui.begin_table("spawnOpts",3,1,{200, 200})
            imgui.table_next_row()
            
            imgui.table_next_column()
            if imgui.button("Удалить последний") then deleteLast() end
            imgui.table_next_column()
            if imgui.button("Удалить всё##created") then deleteAll() end
            imgui.table_next_column()
            if spawner ~= nil and spawner.instances then imgui.text(string.format("Активные: %d",#spawner.instances)) end
            imgui.table_next_row()
            imgui.table_next_column()
            _changed, config.spawnMultiple.enable = imgui.checkbox("Мультиспавн", config.spawnMultiple.enable)
            saveAndApply(_changed)
            imgui.table_next_column()
            if config.spawnMultiple.enable then
                _changed, config.spawnMultiple.qty = imgui.drag_int("Кол-во", config.spawnMultiple.qty , 1, 1, 50)
                saveAndApply(_changed)
            end
            imgui.table_next_column()
            _changed, config.instLimit = imgui.drag_int("Лимит", config.instLimit , 1, 1, 250)
            saveAndApply(_changed)
            imgui.table_next_row()
            imgui.table_next_column()
            _changed, config.ovrScale.enable = imgui.checkbox("Масштаб", config.ovrScale.enable )
            saveAndApply(_changed)
            if config.ovrScale.enable  then
                imgui.table_next_column()
                _changed, config.ovrScale.scale = imgui.drag_float("##Scale", config.ovrScale.scale , 0.1, 0.1, 10.00)
                saveAndApply(_changed)
                imgui.table_next_column()
                _changed, config.ovrScale.normalizeSpeed = imgui.checkbox("Синхр. скорость", config.ovrScale.normalizeSpeed)
                saveAndApply(_changed)
            end
            imgui.table_next_row()
            imgui.table_next_column()
            _changed, config.spawnIdle = imgui.checkbox("Спавн без движения", config.spawnIdle)
            saveAndApply(_changed)
            -- imgui.table_next_column()
            -- _changed, config.asBoss = imgui.checkbox("Make Boss", config.asBoss)
            -- saveAndApply(_changed)
            -- imgui.table_next_column()
            -- _changed, config.initSet = imgui.drag_int("InitSet", config.initSet , 1, 1, 207)
            -- saveAndApply(_changed)

            -- [[ BIG HEADS WIP (NOT WORKING) ]]
            -- imgui.table_next_column()
            -- _changed, config.bigHead = imgui.checkbox("Big Heads", config.bigHead)
            -- saveAndApply(_changed)
            -- [[ FORCE CLIMB WIP (MISSING INITIALIZATION STEPS)]]
            -- imgui.table_next_column()
            -- _changed, config.forceClimb = imgui.checkbox("Force Climbable", config.forceClimb)
            -- saveAndApply(_changed)
            
            imgui.end_table()
        end
        
        if imgui.collapsing_header("Глобальные настройки") then 
            imgui.begin_table("gOpts",4,1,{200, 200})
            for _,h in ipairs({"Категория","Спавн","Удалить всё","Кол-во"}) do 
                imgui.table_next_column()
                imgui.table_header(h)
            end
            
            for i,cat in ipairs({"StrayPawn","Monster","NPC","Gimmick","Other"}) do
                imgui.table_next_row()
                imgui.table_next_column()
                imgui.text(catLabels[cat] or cat)
                imgui.table_next_column()
                _changed, config.globalSpawn[cat].disable = imgui.checkbox("Откл.##"..cat, config.globalSpawn[cat].disable)
                saveAndApply(_changed)
                imgui.table_next_column()
                if imgui.button("удалить##"..cat) then 
                    if spawner then 
                        spawner:deleteAllCategory(i+1) 
                    end
                    -- if spawnEditor and cat == 'Monster' then 
                    --     spawnEditor:deleteAll()
                    -- end
                end
                imgui.table_next_column()
                if spawner and spawner.gm then 
                    --imgui.text("---")
                    imgui.text(tostring(spawner.instanceCounts[i]))
                    --imgui.text(tostring(spawner:getInstCatCount(i+1)))
                end
            end
            imgui.table_next_row()
            imgui.table_next_column()
            imgui.text("НАСТРОЙКИ МОНСТРОВ")
            imgui.table_next_row()
            imgui.table_next_column()
            _changed, config.spawnEdit.repl.enable = imgui.checkbox("Спавн+", config.spawnEdit.repl.enable)
            saveAndApply(_changed)
            if config.spawnEdit.repl.enable then 
                imgui.table_next_column()
                _changed, config.spawnEdit.repl.qty = imgui.drag_int("Доп.", config.spawnEdit.repl.qty, 1, 1, 10)
                saveAndApply(_changed)
            end
            imgui.table_next_row()
            imgui.table_next_column()
            _changed, config.spawnEdit.ovrScale.enable = imgui.checkbox("Свой масштаб##Monster", config.spawnEdit.ovrScale.enable )
            saveAndApply(_changed)
            if config.spawnEdit.ovrScale.enable  then
                imgui.table_next_column()
                _changed, config.spawnEdit.ovrScale.scale = imgui.drag_float("##ScaleMonster", config.spawnEdit.ovrScale.scale , 0.1, 0.25, 10.00)
                saveAndApply(_changed)
                imgui.table_next_column()
                _changed, config.spawnEdit.ovrScale.normalizeSpeed = imgui.checkbox("Синхр. скорость##Monster", config.spawnEdit.ovrScale.normalizeSpeed)
                saveAndApply(_changed)
            end
            -- imgui.table_next_row()
            -- imgui.table_next_column()
            -- _changed, config.spawnEdit.attr.attack = imgui.drag_float("Attack##Monster", config.spawnEdit.attr.attack , 0.1, 0.25, 100.00)
            -- saveAndApply(_changed)
            -- imgui.table_next_column()
            -- _changed, config.spawnEdit.attr.defense = imgui.drag_float("Defense##Monster", config.spawnEdit.attr.defense , 0.1, 0.25, 100.00)
            -- saveAndApply(_changed)
            -- imgui.table_next_row()
            -- imgui.table_next_column()
            -- _changed, config.spawnEdit.randomBoss = imgui.checkbox("Random Boss", config.spawnEdit.randomBoss )
            -- saveAndApply(_changed)
            imgui.end_table()

        end

        if imgui.collapsing_header("Хоткеи") then 
            _changed, config.hotkeys.enable = imgui.checkbox("Вкл. хоткеи", config.hotkeys.enable)
            saveAndApply(_changed)
            if config.hotkeys.enable then
                imgui.begin_table("hotkeys",3,1,{200, 200})
                for k,_ in pairs(config.hotkeys) do 
                    if k ~= 'enable' then
                        imgui.table_next_row()
                        imgui.table_next_column()
                        imgui.text(hotkeyLabels[k] or k)
                        imgui.table_next_column()
                        _changed, config.hotkeys[k] = imgui.combo("##"..k, config.hotkeys[k], input.kb.byValue)
                        saveAndApply(_changed)
                        imgui.table_next_column()
                    end
                end
                imgui.end_table()
            end
        end

        --DEBUGUI
        if enableDebugUI and go ~= nil then 
            if spawner and spawner.charData then 
                if imgui.collapsing_header("CharData") then 
                    object_explorer:manage_address(spawner.charData)
                end
            end
            if ame and #ame.trackedList > 0 then 
                if imgui.collapsing_header("ОБРАБОТЧИКИ ENTRY") then 
                    for nm, mi in ipairs(ame.trackedList) do 
                        local cnt = mi:getCallCount()
                        if cnt and cnt > 0 then 
                            imgui.text(mi.name)
                            imgui.same_line()
                            imgui.text(": " .. cnt)
                        end
                    end

                end
            end
            if spawner and spawner.instances and #spawner.instances > 0 then 
                if imgui.collapsing_header("ЗАСПАВНЕННЫЕ ОБЪЕКТЫ") then 
                    for i,inst in ipairs(spawner.instances) do 
                        if imgui.collapsing_header(string.format("[%d] %s",i,inst.char)) then 
                            object_explorer:handle_address(inst.instance)
                        end
                    end
                end
            end
            if captureCharacterData then 
                local getNew = imgui.button("Обновить")
                imgui.text(captureCharacterData:get_Name())
                object_explorer:handle_address(captureCharacterData)
                if getNew then captureCharacterData = nil end
            end
            if imgui.collapsing_header("ОТЛАДКА ОБЪЕКТОВ") then 
                if imgui.button("init") then initManagedObjects() end
                go.debugUI()
                if spawner and spawner.gm then 
                    if imgui.collapsing_header("спавнер") then object_explorer:handle_address(spawner.gm) end
                end
            end 
            if #captureScaleArgsList > 0 then 
                if imgui.collapsing_header("captureScaleArgsList") then 
                    for i,h in ipairs(captureScaleArgsList) do
                        if imgui.collapsing_header(i) then 
                            if h and h.argObjs then 
                                for _,o in ipairs(h.argObjs) do
                                    imgui.text(string.format("[%d]", _))
                                    object_explorer:handle_address(o) 
                                end
                            end
                        end
                    end
                end
            end
            if #hookArgHist > 0 then 
                if imgui.collapsing_header("История хуков") then 
                    for i,h in ipairs(hookArgHist) do 
                        local hookArgTitle = getObjTitle(h,i)
                        if imgui.collapsing_header(tostring(hookArgTitle)) then 
                            if h and h.text then imgui.text(h.text) end
                            if h and h.argObjs then 
                                for _,o in ipairs(h.argObjs) do 
                                    if o ~= nil then 
                                        local typeName = o:get_type_definition():get_full_name()
                                        local desc = "---"
                                        if typeName == 'app.PrefabController' then 
                                            local pfb = o:get_Item()
                                            if pfb then desc = pfb:get_Path() end
                                            --if char ~= nil then desc = char:get_Field("Name") end
                                        elseif typeName == 'app.GenerateInfo.GenerateInfoContainer' then 
                                            local cinfo = o:get_field('_CommonInfo')
                                            if cinfo then 
                                                local initPos = cinfo:get_field("_InitialPosition")
                                                local contPos = cinfo:get_field("_ContextPosition")
                                                desc = string.format("I:[%.2f,%.2f,%.2f] C:[%.2f,%.2f,%.2f]",
                                                    initPos.x, initPos.y, initPos.z,
                                                    contPos.x, contPos.y, contPos.z
                                                )
                                            end
                                        end
                                        imgui.text(string.format("[%d] %s", _, desc))
                                        object_explorer:handle_address(o) 
                                    end
                                end
                            end
                        end
                    end
                end
                -- if #common.log.hookArgObjs > 0 then 
                --     for i,o in ipairs(common.log.hookArgObjs) do 
                --         imgui.text("HookArgs" .. tostring(i))
                --         if o then object_explorer:handle_address(o) end
                --     end
                -- end
            end
        end
        -- if enableDebugUI and tm then 
        --     if imgui.collapsing_header("TOAST HISTORY") then 
        --         tm:showAll()
        --     end
        -- end
        if enableDebugUI then
            if spawner ~= nil and spawner.catalogs ~= nil and spawner.catalogs.Enemy ~= nil then 
                if imgui.collapsing_header("Каталог врагов") then 
                    imgui.text(string.format("Количество ключей: %d", spawner.catalogs.Enemy:get_Count()))
                    object_explorer:handle_address(spawner.catalogs.Enemy)
                end
            end
            if spawner ~= nil and spawner.genTables then 
                if #spawner.genTables < 1 then spawner:getGenTables() end
                if imgui.collapsing_header("Таблицы генерации") then 
                    for nm, gt in pairs(spawner.genTables) do 
                        if imgui.collapsing_header(nm) then 
                            object_explorer:handle_address(gt)
                        end
                    end
                end
            end
            -- NOT WORKING YET
            -- if imgui.collapsing_header("Character Lookup") then 
            --     _changed, searchText = imgui.input_text("CharaID", searchText)
            --     imgui.same_line()
            --     if imgui.button("Search") then 
            --         res = getCharaName(searchText)
            --     end
            --     imgui.text(res)
            -- end
        end
        imgui.tree_pop() 
    end
end
)


local CHECK_DELAY = 30
local check_count = 0
--re.on_frame(function() 
re.on_application_entry( "UpdateBehavior", function()
    --if check_count == 0 then
        if triggerHold.spawn then 
            startSpawn()
        end
        if spawner then
            spawner:updateInstanceCounts()
            spawner:requestSpawnOutstanding()
            if spawner:hasAnyOutstandingPostProc() then
                --print("PostProcs Exist Outstanding")
                spawner:processPostProc()
            end
        end
    --     check_count = CHECK_DELAY
    -- else 
    --     check_count = check_count - 1
    -- end


    -- if spawnEditor ~= nil then 
    --     spawnEditor:frameUpdate()
    -- end
    -- if go then 
    --     --player pos
    --     if go.Character then 
    --         tm:bread(posString("PLAYER", go.Character:get_LastGroundPosition()))
    --     end
    --     --camera aim pos
    --     -- if go.MainCamera and go.WorldOffsetSystem then 
    --     --     local v3Pos = go.MainCamera:get_LookAtPosition()
    --     --     local uPos = go.WorldOffsetSystem:toUniversalPosition(v3Pos)
    --     --     tm:bread(posString("LOOKAT", uPos))
    --     -- end
    -- end
    --tm:update()
    
end
)




-- local vecBigHead = sdk.create_instance("via.vec3"):add_ref()
-- vecBigHead.x = 2.000
-- vecBigHead.y = 2.000
-- vecBigHead.z = 2.000
--local vBigHeadPtr = sdk.to_ptr(vecBigHead)


-- [[ WIP HOOKS ]]
-- HOOK intended to target only character heads and change the joint scale to 2X size.
-- this implementation is buggy and often just spawns chars with no head
--[[
sdk.hook(sdk.find_type_definition('via.Joint'):get_method('set_BaseLocalScale'),
    function(args)
        --tm:toast("[Hook] via.Joint:get_LocalScale")
        local tvals = thread.get_hook_storage()
        local ownerName = "UNK"
        tvals["alter"] = false
        if args and #args >= 2 then 
            local _joint = sdk.to_managed_object(args[2])
            if _joint then 
                local jointName = _joint:get_Name()
                if jointName and jointName == 'Head_0' then 
                    local o = _joint:get_Owner()
                    if o then 
                        local ownerGO = o:get_GameObject() 
                        if ownerGO then 
                            ownerName = ownerGO:get_Name()
                            if string.sub(ownerName,1,2) == "ch" then 
                                tm:toast(string.format("[JOINT] %s:%s", ownerName, jointName))
                                tvals["alter"] = true
                                if not vecBigHead then 
                                    vecBigHead = _joint:get_LocalScale()
                                    vecBigHead.x = 0.5
                                    vecBigHead.y = 0.5
                                    vecBigHead.z = 0.5
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if enableLog and captureScaleArgsList and #captureScaleArgsList < 20 then 
            --logArgs(args, 'requestCreateInstance', {nil,nil,'int',nil,nil,nil,nil,nil,nil})
            local haText = common.log.hookArgs(args,{nil,nil,nil,nil,nil,nil,nil,nil,nil})
            if #common.log.hookArgObjs > 0 then 
                table.insert(captureScaleArgsList, {["text"] = haText, ["argObjs"] = common.log.hookArgObjs})
            end
        end

    end,
    function(retval) 
        local alter = thread.get_hook_storage()["alter"]
        if config.bigHead and alter then 
            return sdk.to_ptr(vecBigHead)
        end
        if not firstGetScaleReturn then 
            firstGetScaleReturn = sdk.create_userdata("via.vec3",retval)
        end
        return retval 
    end
)
]]


-- sdk.hook(sdk.find_type_definition("app.Ch253001SubdueCtrl"):get_method("onAtkCalcDamageEnd(app.HitController.DamageInfo)"),
--     function(args)
--         tm:toast("onAtkCalcDamageEnd(app.DI)", 4)
--         --return sdk.PreHookResult.SKIP_ORIGINAL
--     end, nil
-- )

--[[ ch253001_00 dead fix -- Change FreeBit to 0????
        removing meta field from spawn container fixed this issue.
app.InstanceInfo
    <Context>k__BackingField
        Contexts
            _entries[]
                [12]
                    value
                        <CurrentContext>k__BackingField
                            FreeBit = 0


]]
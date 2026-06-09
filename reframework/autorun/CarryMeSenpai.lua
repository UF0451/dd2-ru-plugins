local sdk = sdk
local log = log

local App = {
    _version = "1.2.0",

    config = {
        enabled = true,
        bridal = true,
        bridalOnHighAffinity = false,
        nonBridleStruggle = true,

        forceEveryone = false,
    },
    cache = {
        pawnMgr = nil,
        playerChar = nil,
        charMgr = nil,
    }
}

local configfile = "CarryMeSenpai.json"

local DEBUG = true

local ResistSec = 10000.0
local NearlyEscapeSec = 10000.0

function Log(msg)
    log.info("[CarryMeSenpai] " .. tostring(msg))
    if DEBUG then
        print(msg)
    end
end

local noop = function()
    --
end

App.CHARACTER_TYPE = {
    PLAYER = 0,
    PARTY_PAWN = 1,
    OTHER = 2
}

local function getCharacterManager()
    return sdk.get_managed_singleton("app.CharacterManager")
end

local pawnList = {}
local function getPlayerCharacter()
    return getCharacterManager():call("get_ManualPlayer")
end

local function getCharacterType(character)
    if character == nil then
        return App.CHARACTER_TYPE.OTHER
    end

    if character == getPlayerCharacter() then
        return App.CHARACTER_TYPE.PLAYER
    end

    if pawnList then
        for i = 1, #pawnList do
            if pawnList[i] == character then
                return App.CHARACTER_TYPE.PARTY_PAWN
            end
        end
    end

    return App.CHARACTER_TYPE.OTHER
end



local function getPawnManager()
    return sdk.get_managed_singleton("app.PawnManager")
end

local function updatePawnList(args)
    local pm = getPawnManager()
    if pm == nil then
        return
    end

    for i = 1, #pawnList do
        pawnList[i] = nil
    end

    local getAllPawnsResult = pm:call("get_PawnCharacterList()")
    if getAllPawnsResult == nil then
        pawnList = {}
        return
    end

    local pawns = {}
    for i = 0, getAllPawnsResult:call("get_Count") - 1 do
        pawns[i + 1] = getAllPawnsResult:get_Item(i)
    end

    pawnList = pawns
end

local function try(cb)
    local ok, res = pcall(cb)
    if not ok then
        print(tostring(res))
    end
end

local function isPlayerCarrier(character)
    return character == getPlayerCharacter()
end

-- get_CachedCharacter()
local function onStartCatch(args)
    if not App.config.enabled then
        return sdk.PreHookResult.CALL_ORIGINAL
    end

    -- if App.config.bridal then
    --     return sdk.PreHookResult.CALL_ORIGINAL
    -- end

    updatePawnList()


    local character = sdk.to_managed_object(args[3])
    local settings = sdk.to_managed_object(args[4])
    local characterType = getCharacterType(character)
    local isPawn = characterType == App.CHARACTER_TYPE.PARTY_PAWN

    if isPawn or App.config.forceEveryone then
        if not App.config.nonBridleStruggle then
            settings:set_field("ResistSec", ResistSec)
        end
        settings:set_field("NearlyEscapeSec", NearlyEscapeSec)
    end

end

function IsInLove(character)
    local pm = sdk.get_managed_singleton("app.PawnManager")
    local mainpawn = pm:get_MainPawn()
    local mainPawnCharacter = mainpawn:get_CachedCharacter()
    local mainpawnCtx = mainpawn.MainPawnDataContext
    try(function ()
        Log(character == mainPawnCharacter)
        Log(mainpawnCtx:get_IsLove())
    end)
    return character == mainPawnCharacter and mainpawnCtx:get_IsLove()
end

function App.Init()
    sdk.hook(sdk.find_type_definition("app.CatchController"):get_method("startCatch"), onStartCatch, noop)
    sdk.hook(sdk.find_type_definition("app.HumanCatchProcessor"):get_method("startCarry"), function(args)
        if App.config.enabled and App.config.bridal and isPlayerCarrier(sdk.to_managed_object(args[2]).Chara) then
            
            updatePawnList()
            local character = sdk.to_managed_object(args[3])

            if App.config.bridalOnHighAffinity and not IsInLove(character) then
                return
            end

            local characterType = getCharacterType(character)
            local isPawn = characterType == App.CHARACTER_TYPE.PARTY_PAWN
            if isPawn or App.config.forceEveryone then
                sdk.to_managed_object(args[2]):startBridalCarry(args[3])
                return sdk.PreHookResult.SKIP_ORIGINAL
            end
        end
    end, noop)
end

local function loadconfig()
    return json.load_file(configfile)
end
local function saveconfig()
    json.dump_file(configfile, App.config)
end

re.on_config_save(function()
    saveconfig()
end)

re.on_draw_ui(function()
    if imgui.tree_node("Настройки CarryMeSenpai") then
        local changed, value = imgui.checkbox("Включить мод", App.config.enabled)
        if changed then
            App.config.enabled = value
            saveconfig()
        end

        if App.config.enabled then
            local changed, value = imgui.checkbox("Свадебный захват при высокой симпатии", not not App.config.bridalOnHighAffinity)
            if changed then
                App.config.bridalOnHighAffinity = value
                saveconfig()
            end

            if not App.config.bridalOnHighAffinity then
                local changed, value = imgui.checkbox("Свадебный захват (всегда)", App.config.bridal)
                if changed then
                    App.config.bridal = value
                    saveconfig()
                end
            end
        
            if not App.config.bridal or App.config.bridalOnHighAffinity then
                local changed, value = imgui.checkbox("Анимация борьбы", App.config.nonBridleStruggle)
                if changed then
                    App.config.nonBridleStruggle = value
                    saveconfig()
                end
            end
        end
        imgui.tree_pop()
    end
end)


App.config = loadconfig() or App.config
App.config.forceEveryone = false
saveconfig()

App.Init()
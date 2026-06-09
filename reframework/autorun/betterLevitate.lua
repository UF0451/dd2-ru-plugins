local re = re
local sdk = sdk

-- CONFIGURATION:
local MAX_HEIGHT = 6     --if you fall from this height you wont take any damage but if you decide to go higher you will take fall damage.
local MAX_DURATION = 15  --how long you will be levitating for in seconds.
local MOVE_SPEED = 6     --this is the speed at which the player will move while levitating, be careful going to fast makes controlling it much harder.

local PlayerManager = sdk.get_managed_singleton("app.CharacterManager")
local function GetPlayerManager()
    if PlayerManager == nil then PlayerManager = sdk.get_managed_singleton("app.CharacterManager") end
	return PlayerManager
end

local HumanPlayer
local function GetPlayerHuman()
    playerMgr = GetPlayerManager()
    if playerMgr then
        if HumanPlayer == nil then HumanPlayer = playerMgr:call("get_ManualPlayerHuman()") end
	    return HumanPlayer
    end
    return nil
end

local LevitateController
local function GetLevitateController()
    human = GetPlayerHuman()
    if human then
        -- Используем локальную переменную внутри, чтобы избежать проблем с кешированием nil
        local ctrl = human:call("get_LevitateCtrl()")
        if ctrl then LevitateController = ctrl end
        return LevitateController
    end
    return nil
end

local initBetterLevitate = false

local function resetScript()
    PlayerManager = nil
    HumanPlayer = nil
    LevitateController = nil
end

re.on_frame(function ()
    
    -- INIT
    if not initBetterLevitate then
        local levitateCtrl = GetLevitateController();
        if levitateCtrl then
            leviParams = levitateCtrl:get_field("Param")
            -- Убедимся, что currentPos определен, иначе замени на vec3.new(0,0,0)
            local currentPos = levitateCtrl:get_field("StartPosition") 
            levitateCtrl:set_field("StartPosition", currentPos)
            if leviParams then
                leviParams:set_field("MaxHeight", MAX_HEIGHT)
                leviParams:set_field("MaxKeepSec", MAX_DURATION)
                initBetterLevitate = true
            end
        end
    end

    -- KEEP MOVING AT A GOOD SPEED WHILE LEVITATING
    human = GetPlayerHuman()
    if human then
        moveSpeed = human:get_field("MoveSpeedTypeValueInternal")
        if moveSpeed > 0 then
            local levitateCtrl = GetLevitateController();
            -- ИСПРАВЛЕНИЕ: Проверка на существование контроллера перед использованием
            if levitateCtrl then
                levitateCtrl:set_field("HorizontalSpeed", MOVE_SPEED * (moveSpeed / 3))
            end
        end
    end

    playerMgr = GetPlayerManager()
    if playerMgr then
        isDead = playerMgr:call("get_IsManualPlayerDead()")
        if isDead then
            resetScript()
        end
    end
 
end)
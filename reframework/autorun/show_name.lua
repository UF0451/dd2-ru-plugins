
local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw


local GuiManager = sdk.get_managed_singleton("app.GuiManager")
local function GetGuiManager()
    if GuiManager == nil then GuiManager = sdk.get_managed_singleton("app.GuiManager") end
	return GuiManager
end
local CharacterType = sdk.find_type_definition("app.Character"):get_runtime_type()

sdk.hook(sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),
function (args)
end, function()
    GuiManager = nil

    GetGuiManager()
end
)

local character
sdk.hook(sdk.find_type_definition("app.ui021301"):get_method("reqDisp(via.GameObject, System.Single, System.Guid)"),
function(args)
    local obj = sdk.to_managed_object(args[3])
    character = obj:call("getComponent(System.Type)", CharacterType)
    -- if character then
        -- log.info("got chara")
    -- end
end, function(ret)
    return ret
end
)

local GetNameByCharID = sdk.find_type_definition("app.GUIBase"):get_method("getName(app.CharacterID)")

-- app.ui021301.
-- setFlowId(app.ui021301.FlowId)
local ui
sdk.hook(sdk.find_type_definition("app.ui021301"):get_method("reqDispCommon(System.Single, System.Guid)"),
function (args)
    -- local id = sdk.to_int64(args[3])
    -- if id == 0 then
    --     ui = nil
    --     return
    -- end

    ui = sdk.to_managed_object(args[2])
end, function(ret)
    if ui and character then
        local text = ui.TxtTalk
        if text then
            -- local msg = text:get_Message()
            -- log.info("text: " .. tostring(msg))
            local name = GetNameByCharID(nil, character:get_CharaID())
            -- log.info(name)

            local gui = GetGuiManager()
            if gui then
                if gui:isFavoriteNPCId(character:get_CharaID()) then
                    name = "* " .. name
                end
            end

            text:set_Message(name)
        end
    end
    character = nil
    return ret
end
)

local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw


local VALUE = sdk.to_ptr(0)
sdk.hook(sdk.find_type_definition("app.TalkEventManager"):get_method("isElfSpeakingCharacter(app.CharacterID)"),
function (args)
end, function(ret)
    return VALUE
end
)

local modname = "PawnsSurviveBrine"
local configfile = modname .. '.json'

local defaultconfig = {
	enabled = true,
	warp_to_player = false
}

local config = json.load_file(configfile) or defaultconfig


local function warpPawn(Character, position, rotation)
	if warp_to_player then
		Character:get_TelepotorProp():teleport(sdk.get_managed_singleton("app.CharacterManager"):get_ManualPlayerPlayer():get_PrevSafePosForNPC())
	else
		Character:get_TelepotorProp():teleport(position)
	end
end

local function summonPawns()
	local vec = sdk.get_managed_singleton("app.CharacterManager"):get_ManualPlayer():get_Transform():get_Position()
	sdk.get_managed_singleton("app.PawnManager"):followWarp(vec)
end

re.on_draw_ui(function ()
	if imgui.tree_node(modname) then
		enable_changed, config.enabled = imgui.checkbox("Включено", config.enabled)
		warp_changed, config.warp_to_player = imgui.checkbox("Телепортировать к игроку", config.warp_to_player)
        if warp_changed or enable_changed then 
			if json.load_file(configfile) ~= config then
                json.dump_file(configfile, config)
            end
        end
		summon_pressed = imgui.button("Призвать пешек")
		if summon_pressed then summonPawns() end
		imgui.tree_pop()
	end
end
)

sdk.hook(sdk.find_type_definition("app.BrineProcessor"):get_method("onKillCommon()"),
function (args)
	if config.enabled then
		local BrineProcessor = sdk.to_managed_object(args[2])
		local Chara = BrineProcessor:get_field("Chara")
		if not Chara then return sdk.PreHookResult.CALL_ORIGINAL end
		if not Chara:isKindOf(2) then return sdk.PreHookResult.CALL_ORIGINAL end
		if Chara:get_Human():isPlayerOrPartyPawn() then
			local pos = BrineProcessor:get_field("CalcRevivePosRotHandler")
			warpPawn(Chara, pos)
			return sdk.PreHookResult.SKIP_ORIGINAL
		end
	end
end, function(retval)
    return retval
end
)
local modname = "NoSpaCensor"
local configfile = modname .. '.json'

local defaultconfig = {
	enabled_female = true,
	enabled_male = true
}

local config = json.load_file(configfile) or defaultconfig
NoSpaCensorInstalled = true
NoSpaCensorOverride = {}


local function toggleEffect(Character)
	if not Character then return end
	local isFemale = Character:get_Human():get_IsFemaleLooks()
	local UndressCtrl = Character:get_Human():get_UndressCtrl()
	if (config.enabled_female and isFemale) or (config.enabled_male and not isFemale) then
		UndressCtrl:finishEffect() 
	elseif UndressCtrl:get_IsUndress() then
		UndressCtrl:generateEffect() 
	end
end


local function pre_function(args)
	local UndressController = sdk.to_managed_object(args[2])
	local isFemale = UndressController:get_field("IsFemale")
	local Human = UndressController:get_field("Human")
	if ((config.enabled_female and isFemale) or (config.enabled_male and not isFemale)) and not NoSpaCensorOverride[Human] then
		return sdk.PreHookResult.SKIP_ORIGINAL
	elseif NoSpaCensorOverride[Human] then NoSpaCensorOverride[Human] = nil
	end
end

local function post_function(retval)
    return retval
end

re.on_draw_ui(function ()
	if imgui.tree_node(modname) then
		female_changed, config.enabled_female = imgui.checkbox("Женские", config.enabled_female)
		imgui.same_line()
		male_changed, config.enabled_male = imgui.checkbox("Мужские", config.enabled_male)
		if female_changed or male_changed then
			toggleEffect(sdk.get_managed_singleton("app.CharacterManager"):get_ManualPlayer())
			local PartyList = sdk.get_managed_singleton("app.PawnManager"):get_PawnCharacterList():ToArray():get_elements()
			if #PartyList > 0 then
				for i,obj in ipairs(PartyList) do
					toggleEffect(obj)
				end
			end
			local NPCManager = sdk.get_managed_singleton("app.NPCManager")
			local EntityList = NPCManager:get_NPCHolder_EntityList():ToArray():get_elements()
			if #EntityList > 0 then
				for i,obj in ipairs(EntityList) do
					toggleEffect(obj:get_chara())
				end
			end
			if json.load_file(configfile) ~= config then
                json.dump_file(configfile, config)
            end
        end
		imgui.tree_pop()
	end
end
)

sdk.hook(sdk.find_type_definition("app.HumanUndressController"):get_method("changeEffect()"), pre_function, post_function)
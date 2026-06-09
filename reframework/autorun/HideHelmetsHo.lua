local hotkeys = require("Hotkeys/Hotkeys")
local modname="[Hide Helmets Ho]"

local settings = {
    hide_arisen_helmet = false,
    hide_pawn_helmet = false,
	Hotkeys = {
        ["hide_arisen_helmet"] = "H",
        ["hide_pawn_helmet"] = "H"
    }
}

local settings_path = "HideHelmetsHo/settings.json"
local settings_file = json.load_file(settings_path)
if settings_file ~= nil then
    settings= settings_file
else
    json.dump_file(settings_path,settings)
end

hotkeys.setup_hotkeys(settings.Hotkeys)

local PlayerManager = sdk.get_managed_singleton("app.CharacterEditManager")
local function GetCharacterEditManager()
    if PlayerManager == nil then PlayerManager = sdk.get_managed_singleton("app.CharacterEditManager") end
	return PlayerManager
end

local function applyChanges(hide_arisen_helmet,hide_pawn_helmet)
	characterEditManager = GetCharacterEditManager()
	characterEditManager:set_field("_HidePlayerHelm", hide_arisen_helmet)
	characterEditManager:set_field("_HidePawnHelm", hide_pawn_helmet)
end

re.on_draw_ui(function ()
	if imgui.tree_node(modname) then
        changed_arisen, settings.hide_arisen_helmet = imgui.checkbox("Скрыть шлем Восставшего", settings.hide_arisen_helmet)
        changed_pawn, settings.hide_pawn_helmet = imgui.checkbox("Скрыть шлем пешек", settings.hide_pawn_helmet)
        changed_key_arisen = hotkeys.hotkey_setter("hide_arisen_helmet")
        changed_key_pawn = hotkeys.hotkey_setter("hide_pawn_helmet")

        if changed_arisen or changed_pawn then 
			saveSettings = true
            applyChanges(settings.hide_arisen_helmet,settings.hide_pawn_helmet)
        end

        if changed_key_arisen or changed_key_pawn then
            hotkeys.update_hotkey_table(settings.Hotkeys)
            saveSettings = true
        end

        if saveSettings then
            if json.load_file(settings_path) ~= settings then
                json.dump_file(settings_path,settings)
            end
        end
		imgui.tree_pop()
	end
end
)

sdk.hook(sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),
function (args)
end, function(ret)
-- do things here
    applyChanges(settings.hide_arisen_helmet,settings.hide_pawn_helmet)
return ret
end
)

re.on_frame(function ()
    if hotkeys.check_hotkey("hide_arisen_helmet", false) then
        settings.hide_arisen_helmet = not settings.hide_arisen_helmet
        applyChanges(settings.hide_arisen_helmet,settings.hide_pawn_helmet)
        if json.load_file(settings_path) ~= settings then
            json.dump_file(settings_path,settings)
        end
    end
    if hotkeys.check_hotkey("hide_pawn_helmet", false) then
        settings.hide_pawn_helmet = not settings.hide_pawn_helmet
        applyChanges(settings.hide_arisen_helmet,settings.hide_pawn_helmet)
        if json.load_file(settings_path) ~= settings then
            json.dump_file(settings_path,settings)
        end
    end

end)
-- default settings
local default_settings = {
Main_Map_Alpha = true,
Main_Map_toggle = true,
minimap_Compass = true,
minimap_Arisen = true
}

-- make sure default settings are there:
MinimapConfig = json.load_file("b00/MinimapConfig.json") or { }
for k, v in pairs(default_settings) do 
    if MinimapConfig[k] == nil then MinimapConfig[k]=v end
end

--Step 1, get singleton (app.GuiManager) - "who"
local GuiManager = sdk.get_managed_singleton("app.GuiManager")
local function get_GuiManager()
    if GuiManager == nil then GuiManager = sdk.get_managed_singleton("app.GuiManager")
end
	return GuiManager
end

--Step 2, Get values - "where"
local function update_MinimapAlpha()
	if GuiManager then
	gui_list = GuiManager:get_field("_GUIList")
		if gui_list == nil then return false end
		count = gui_list:get_Count()
			for i = 0, count - 1 do
			gui_list_minimap1 = gui_list:get_Item(i)
				if gui_list_minimap1:get_type_definition():get_name() == 'ui020301' then -- #37
				if gui_list_minimap1 then
						gui_list_minimap1_Texture = gui_list_minimap1:get_field("TexSplit")
						if gui_list_minimap1_Texture then
							if MinimapConfig.Main_Map_Alpha then
								gui_list_minimap1_Texture:set_LinearAlphaBlend(true)
								gui_list_minimap1_Texture:set_IgnoreAlpha(true)
							else
								gui_list_minimap1_Texture:set_LinearAlphaBlend(false)
								gui_list_minimap1_Texture:set_IgnoreAlpha(false)
							end
							if MinimapConfig.Main_Map_toggle then
								gui_list_minimap1_Texture:set_Visible(true)
							else
								gui_list_minimap1_Texture:set_Visible(false)
							end
						end
						gui_list_minimap1_Compass = gui_list_minimap1:get_field("Compass")
						if gui_list_minimap1_Compass then
							if MinimapConfig.minimap_Compass then
								gui_list_minimap1_Compass:set_Visible(true)
							else
								gui_list_minimap1_Compass:set_Visible(false)
							end
						end
						gui_list_minimap1_Arisen = gui_list_minimap1:get_field("Arisen")
						if gui_list_minimap1_Arisen then
							if MinimapConfig.minimap_Arisen then
								gui_list_minimap1_Arisen:set_Visible(true)
							else
								gui_list_minimap1_Arisen:set_Visible(false)
							end
						end
					end
			end
		end
	end
end

--Step 4, Set options/values (1x checkbox) "what"
re.on_draw_ui(function()
	imgui.begin_rect()
		if imgui.tree_node("Редактор миникарты") then
			imgui.text("Основная карта:")
				imgui.same_line()
					changed, MinimapConfig.Main_Map_Alpha = imgui.checkbox(":Прозрачность", MinimapConfig.Main_Map_Alpha); wc = wc or changed
						imgui.same_line()
					changed, MinimapConfig.Main_Map_toggle = imgui.checkbox(":Вкл/Выкл##Main_Map", MinimapConfig.Main_Map_toggle); wc = wc or changed
					was_changed = changed or was_changed
			imgui.text("Компас:")
				imgui.same_line()
					changed, MinimapConfig.minimap_Compass = imgui.checkbox(":Вкл/Выкл##minimap_Compass", MinimapConfig.minimap_Compass); wc = wc or changed
					was_changed = changed or was_changed
			imgui.text("Восставший:")
				imgui.same_line()
					changed, MinimapConfig.minimap_Arisen = imgui.checkbox(":Вкл/Выкл##minimap_Arisen", MinimapConfig.minimap_Arisen); wc = wc or changed
					was_changed = changed or was_changed
			if changed or wc then
				json.dump_file("b00/MinimapConfig.json", MinimapConfig)
			end
			imgui.tree_pop()
		end
		imgui.end_rect()
	end
)
--Step 5, on frame function of script "when"
re.on_draw_ui(function ()
	get_GuiManager()
	update_MinimapAlpha()
end)
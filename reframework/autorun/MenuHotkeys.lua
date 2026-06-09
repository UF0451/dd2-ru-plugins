local CATEID_INVENTORY = 0
local CATEID_QUESTS    = 2
local CATEID_EQUIP     = 3

local gui_manager = nil
local enabled = true

local key_values = {}
pcall(function()
    local t = sdk.find_type_definition("via.hid.KeyboardKey")
    for i, field in ipairs(t:get_fields()) do
        if field:is_static() then
            local ok, val = pcall(function() return field:get_data(nil) end)
            if ok and val ~= nil then key_values[field:get_name()] = val end
        end
    end
end)

local defaults = {
    key_inventory = "I",
    key_quests = "J",
    key_equip = "K",
}

local settings = {}
local function load_settings()
    settings = json.load_file("MenuHotkeys.json") or {}
    for k, v in pairs(defaults) do
        if settings[k] == nil then settings[k] = v end
    end
end
local function save_settings() json.dump_file("MenuHotkeys.json", settings) end
load_settings()

local kb_singleton, kb_typedef, kb

local function update_keyboard()
    if not kb_singleton then
        kb_singleton = sdk.get_native_singleton("via.hid.Keyboard")
        kb_typedef = sdk.find_type_definition("via.hid.Keyboard")
    end
    if kb_singleton and kb_typedef then
        pcall(function()
            kb = sdk.call_native_func(kb_singleton, kb_typedef, "get_Device")
        end)
    end
end

local function is_key_released(key_name)
    local val = key_values[key_name]
    if not val or not kb then return false end
    local ok, r = pcall(function() return kb:call("isRelease", val) end)
    return ok and r
end

local function get_pressed_key()
    if not kb then return nil end
    for name, val in pairs(key_values) do
        local ok, r = pcall(function() return kb:call("isTrigger", val) end)
        if ok and r then return name end
    end
    return nil
end

local function can_open_menu()
    if not gui_manager then return false end
    if reframework:is_drawing_ui() then return false end
    if gui_manager:call("isPausedGUI") then return false end
    local ok, block = pcall(function() return gui_manager:call("get_BlockMenu") end)
    if ok and block and block > 0 then return false end
    return true
end

local function open_pause_to_tab(cate_id)
    if not can_open_menu() then return end
    gui_manager:call("set_DirectOpenPauseSubMenu", cate_id)
    gui_manager:call("set_IsForceOpenPauseMenu", true)
end

re.on_frame(function()
    if not gui_manager then
        gui_manager = sdk.get_managed_singleton("app.GuiManager")
    end
    if not enabled or not gui_manager then return end

    update_keyboard()
    if not kb then return end

    if is_key_released(settings.key_inventory) then
        open_pause_to_tab(CATEID_INVENTORY)
    end
    if is_key_released(settings.key_quests) then
        open_pause_to_tab(CATEID_QUESTS)
    end
    if is_key_released(settings.key_equip) then
        open_pause_to_tab(CATEID_EQUIP)
    end
end)

local binding = nil

re.on_draw_ui(function()
    if imgui.tree_node("Горячие клавиши меню") then
        local changed
        changed, enabled = imgui.checkbox("Включено", enabled)
        imgui.text("")

        if binding then
            update_keyboard()
            local pressed = get_pressed_key()
            if pressed then
                settings[binding] = pressed
                save_settings()
                binding = nil
            end
        end

        local function key_row(label, setting_name)
            imgui.text(label .. ": ")
            imgui.same_line()
            if binding == setting_name then
                imgui.text("[Нажмите клавишу...]")
            else
                if imgui.button(settings[setting_name] .. "##" .. setting_name) then
                    binding = setting_name
                end
            end
        end

        key_row("Инвентарь", "key_inventory")
        key_row("Задания", "key_quests")
        key_row("Экипировка", "key_equip")

        imgui.text("")
        if imgui.button("Сбросить на стандартные") then
            for k, v in pairs(defaults) do settings[k] = v end
            save_settings()
            binding = nil
        end

        imgui.tree_pop()
    end
end)

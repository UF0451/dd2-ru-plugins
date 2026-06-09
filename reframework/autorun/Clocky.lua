local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw

local config = json.load_file("clocky.json") or {}
local loc = json.load_file("clocky-loc.json")

local font_name = "Shadower.otf"
local glyph_ranges = {
    0x0020, 0x00FF, -- Basic Latin + Latin Supplement
	0x0400, 0x04FF, -- Cyrillic
    0x2000, 0x206F, -- General Punctuation
	0,
}

-- 
if config.Language == nil then
    config.Language = 1
end

if config.ShowOnPause == nil then
	config.ShowOnPause = false
end
--
if config.InGameFontPrefs == nil then
    config.InGameFontPrefs = {}
end

if config.InGameFontPrefs.TwoRow == nil then
	config.InGameFontPrefs.TwoRow = false
end

if config.InGameFontPrefs.AMPM == nil then
    config.InGameFontPrefs.AMPM = false
end

if config.InGameFontPrefs.FontSize == nil then
    config.InGameFontPrefs.FontSize = 24
end

if config.InGameFontPrefs.Aligment == nil then
    config.InGameFontPrefs.Aligment = 1
end

if config.InGameFontPrefs.FontColor == nil then
    config.InGameFontPrefs.FontColor = "0x99f0f0f0"
end

if config.InGameFontPrefs.Background == nil then
    config.InGameFontPrefs.Background = false
end

if config.InGameFontPrefs.BackgroundColor == nil then
    config.InGameFontPrefs.BackgroundColor = 2420393028
end

if config.InGameFontPrefs.PositionHeightOffset == nil then
    config.InGameFontPrefs.PositionHeightOffset = 50
end

if config.InGameFontPrefs.PositionWidthOffset == nil then
    config.InGameFontPrefs.PositionWidthOffset = 50
end

if config.InGameFontPrefs.FormatMain == nil then
    config.InGameFontPrefs.FormatMain = "{D} {d}, {h} : {m}{ampm} - {tod}"
end

if config.InGameFontPrefs.FormatSecond == nil then
    config.InGameFontPrefs.FormatSecond = "{D} {d} - {tod}"
end

if config.InGameFontPrefs.SecondLineAligment == nil then
    config.InGameFontPrefs.SecondLineAligment = 1
end

config.InGameFontPrefs.AxsKey = "InGame"

--
if config.OnPauseFontPrefs == nil then
    config.OnPauseFontPrefs = {}
end

if config.OnPauseFontPrefs.TwoRow == nil then
	config.OnPauseFontPrefs.TwoRow = false
end

if config.OnPauseFontPrefs.AMPM == nil then
    config.OnPauseFontPrefs.AMPM = false
end

if config.OnPauseFontPrefs.FontSize == nil then
    config.OnPauseFontPrefs.FontSize = 24
end

if config.OnPauseFontPrefs.Aligment == nil then
    config.OnPauseFontPrefs.Aligment = 1
end

if config.OnPauseFontPrefs.FontColor == nil then
    config.OnPauseFontPrefs.FontColor = "0x99f0f0f0"
end

if config.OnPauseFontPrefs.Background == nil then
    config.OnPauseFontPrefs.Background = false
end

if config.OnPauseFontPrefs.BackgroundColor == nil then
    config.OnPauseFontPrefs.BackgroundColor = 2420393028
end

if config.OnPauseFontPrefs.PositionHeightOffset == nil then
    config.OnPauseFontPrefs.PositionHeightOffset = 50
end

if config.OnPauseFontPrefs.PositionWidthOffset == nil then
    config.OnPauseFontPrefs.PositionWidthOffset = 50
end

if config.OnPauseFontPrefs.FormatMain == nil then
    config.OnPauseFontPrefs.FormatMain = "{D} {d}, {h} : {m}{ampm} - {tod}"
end

if config.OnPauseFontPrefs.FormatSecond == nil then
    config.OnPauseFontPrefs.FormatSecond = "{D} {d} - {tod}"
end

if config.OnPauseFontPrefs.SecondLineAligment == nil then
    config.OnPauseFontPrefs.SecondLineAligment = 1
end

config.OnPauseFontPrefs.AxsKey = "OnPause"

local axs = {
    ["OnPause"] = {
        ["Font"] = imgui.load_font(font_name, config.OnPauseFontPrefs.FontSize, glyph_ranges),
        ["FontResize"] = config.OnPauseFontPrefs.FontSize,
        ["FontSizeChanged"] = false,
        ["O"] = "  "
    },
    ["InGame"] = {
        ["Font"] = imgui.load_font(font_name, config.InGameFontPrefs.FontSize, glyph_ranges),
        ["FontResize"] = config.InGameFontPrefs.FontSize,
        ["FontSizeChanged"] = false,
        ["O"] = " "
    }
}

-- -- -- -- -- -- --
local is_in_game
local is_pause
local is_menu_bg
local hud_alpha = 0
local font_size_changed
local font_resize = config.FontSize
local font_size_changed_on_pause
local font_resize_on_pause = config.FontSizeOnPause
local font = imgui.load_font(font_name, config.FontSize, glyph_ranges)
local font_on_pause = imgui.load_font(font_name, config.FontSizeOnPause, glyph_ranges)
local ui_font = imgui.load_font("NotoSancSB.ttf", 18, glyph_ranges)
local languages_value = {"English", "Русский"}

local gui_manager = sdk.get_managed_singleton("app.GuiManager")
local time_manager = sdk.get_managed_singleton("app.TimeManager")
local main_flow_manager = sdk.get_managed_singleton("app.MainFlowManager")

local function get_gui_manager()
    if gui_manager == nil then gui_manager = sdk.get_managed_singleton("app.GuiManager") end
	return gui_manager
end

local function get_time_manager()
    if time_manager == nil then time_manager = sdk.get_managed_singleton("app.TimeManager") end
	return time_manager
end

local function get_main_flow_manager()
    if main_flow_manager == nil then main_flow_manager = sdk.get_managed_singleton("app.MainFlowManager") end
	return main_flow_manager
end

local function check_is_in_game_phase()
    is_in_game = get_main_flow_manager():get_IsInGamePhase()
    return is_in_game
end

sdk.hook(sdk.find_type_definition("app.MainFlowManager"):get_method("changeFlowPhase"), nil,
function()
    check_is_in_game_phase()
end)

sdk.hook(sdk.find_type_definition("app.ui022601"):get_method("calcAlpha"), nil,
function(retval)
    if retval then
        local alpha = sdk.to_float(retval)

        if hud_alpha ~= alpha then
            hud_alpha = alpha
        end
    end

    return retval
end)

sdk.hook(sdk.find_type_definition("app.ui060101"):get_method("setActiveMenuBg"), 
    function(args)
        is_menu_bg = (sdk.to_int64(args[3]) & 1) == 1
    end,
nil)

sdk.hook(sdk.find_type_definition("app.GuiManager"):get_method("requestGUIPause"), 
    function(args)
        is_pause = (sdk.to_int64(args[3]) & 1) == 1
    end,
nil)

local function calc_color(color, hud_alpha)
    local hex = string.format("%X", color)
    local alpha_color = tonumber("0x" .. hex:sub(1,2))
    local alpha_gui = math.floor(hud_alpha * alpha_color)

    return string.format("0x%02X%s", alpha_gui, hex:sub(3,8))
end

local function init()
    check_is_in_game_phase()
    is_pause = sdk.get_managed_singleton("app.PauseManager"):isPausedAny()
    is_menu_bg = is_pause
end

local function get_start_position(x, size, aligment)
    local x = x

    if aligment == 2 then
        x = x - size / 2
    elseif aligment == 3 then 
        x = x - size
    end

    return x
end

local function get_time_string(time, format)
    local t = format

    t = string.gsub(t, "{D}", loc[config.Language].day)
    t = string.gsub(t, "{D_}", loc[config.Language].day_)
    t = string.gsub(t, "{d}", tostring(time.d))
    t = string.gsub(t, "{tod}", time.tod)
    t = string.gsub(t, "{h}", string.format("%02d", time.h))
    t = string.gsub(t, "{m}", string.format("%02d", time.m))
    t = string.gsub(t, "{ampm}", time.ampm == nil and "" or time.ampm)

    return t
end

local function draw_time(key, alpha)
    local color = alpha and calc_color(config[key].FontColor, hud_alpha) or config[key].FontColor
    local bg_color = alpha and calc_color(config[key].BackgroundColor, hud_alpha) or config[key].BackgroundColor

    local time = {}

    time.d = time_manager:get_InGameDay()
    time.h = time_manager:get_InGameHour()
    time.m = time_manager:get_InGameMinute()

-- Сначала проверяем время суток, но добавляем приоритет для утренних часов
    if time_manager:isNight() then
        time.tod = loc[config.Language].night
    elseif time_manager:isDawn() or (time.h >= 6 and time.h < 10) then
        -- Рассвет или раннее утро (с 6 до 10 утра)
        time.tod = loc[config.Language].dawn 
    elseif time_manager:isNoon() and time.h >= 10 then
        -- Полднем считаем время только после 10 утра
        time.tod = loc[config.Language].noon
    else
        time.tod = loc[config.Language].dusk
    end

    if config[key].AMPM then
        time.ampm = time.h < 12 and loc[config.Language].am or loc[config.Language].pm
        
        if time.h > 12 then
            time.h = time.h % 12
        end
    end

    imgui.push_font(axs[config[key].AxsKey].Font)

    local time_string = get_time_string(time, config[key].FormatMain)
    local string_size = imgui.calc_text_size(time_string)
    local paddings = config[key].BackgroundPaddings

    local x = get_start_position(config[key].PositionWidthOffset, string_size.x, config[key].Aligment)
    local y = config[key].PositionHeightOffset

    if config[key].Background then
        draw.filled_rect(x - 10, y - 10, string_size.x + 20, string_size.y + 20, bg_color)
    end

    draw.text(time_string, x, y, color)

    if config[key].TwoRow then
        local slt = config[key].SecondLineAligment == 1

        time_string = get_time_string(time, config[key].FormatSecond)
        string_size = imgui.calc_text_size(time_string)
        x = get_start_position(config[key].PositionWidthOffset, string_size.x, config[key].Aligment)
        y = y + config[key].FontSize + 10 - (slt and (string_size.y * 2 + 20) or 0)

        if config[key].Background then
            draw.filled_rect(x - 10, y - (slt and 10 or 0), string_size.x + 20, string_size.y + 10, bg_color)
        end

        draw.text(time_string, x, y, color)
    end

    imgui.pop_font()
end

re.on_frame(function()
    if is_in_game then
        if not is_pause then
            draw_time("InGameFontPrefs", true)
        elseif config.ShowOnPause and is_menu_bg then
            draw_time("OnPauseFontPrefs")
        end
    end
end)

local function draw_font_prefs_ui(prefs)
    local lang = config.Language
    local loc = loc[lang]

    local config = prefs
    local config_changed = false
    local changed = false

    local ax = axs[config.AxsKey]

    imgui.text(loc.font)

    imgui.push_item_width(89)

    changed, ax.FontResize = imgui.drag_int(loc.size, ax.FontResize, 1, 4, 100)
    ax.FontSizeChanged = ax.FontSizeChanged or changed

    if ax.FontSizeChanged and not imgui.is_item_active() and ax.FontResize ~= config.FontSize then
        ax.FontSizeChanged = false
        config.FontSize = ax.FontResize
        ax.Font = imgui.load_font(font_name, config.FontSize, glyph_ranges)
        config_changed = config_changed or changed
    end
    
    imgui.same_line()

    changed, config.Aligment = imgui.combo(loc.aligment, config.Aligment, loc.aligments)
    config_changed = config_changed or changed

    imgui.pop_item_width()

    imgui.push_item_width(238)

    changed, config.FontColor = imgui.color_edit(loc.color, config.FontColor)
    config_changed = config_changed or changed

    imgui.pop_item_width()

    changed, config.Background = imgui.checkbox(loc.background, config.Background)
    config_changed = config_changed or changed

    if config.Background then
        imgui.push_item_width(238)

        changed, config.BackgroundColor = imgui.color_edit(loc.bg_color, config.BackgroundColor)
        config_changed = config_changed or changed

        imgui.pop_item_width()
    end

    imgui.pop_item_width()

    imgui.spacing()
    imgui.spacing()

    imgui.push_item_width(89)

    imgui.text(loc.indents)

    changed, config.PositionHeightOffset = imgui.drag_int(loc.top, config.PositionHeightOffset, 1, 0, 4000, "%d px")
    config_changed = config_changed or changed

    imgui.same_line()

    changed, config.PositionWidthOffset = imgui.drag_int(loc.left, config.PositionWidthOffset, 1, 0, 4000, "%d px")
    config_changed = config_changed or changed

    imgui.pop_item_width()

    imgui.spacing()
    imgui.spacing()

    imgui.text(loc.format)

    if imgui.is_item_hovered() then
        imgui.set_tooltip(loc.tooltip)
    end

    changed, config.TwoRow = imgui.checkbox(loc.tlines, config.TwoRow)
    config_changed = config_changed or changed

    imgui.same_line()

    changed, config.AMPM = imgui.checkbox(loc.am_pm, config.AMPM)
    config_changed = config_changed or changed

    imgui.push_item_width(238)

    changed, config.FormatMain = imgui.input_text(config.TwoRow and loc.fline or loc.line, config.FormatMain)
    config_changed = config_changed or changed

    if config.TwoRow then
        changed, config.FormatSecond = imgui.input_text(loc.sline, config.FormatSecond)
        config_changed = config_changed or changed

        changed, config.SecondLineAligment = imgui.combo(loc.sline_aligment, config.SecondLineAligment, loc.sline_aligments)
        config_changed = config_changed or changed
    end

    imgui.pop_item_width()

    return config_changed, config
end

re.on_draw_ui(function()
    local config_changed = false

    if imgui.tree_node("Часы") then
        local changed = false

        imgui.push_font(ui_font)
        
        imgui.text(loc[config.Language].language)

        imgui.push_item_width(240)

        changed, config.Language = imgui.combo("   ", config.Language, languages_value)
        config_changed = config_changed or changed

        imgui.pop_item_width()

        imgui.spacing()

        changed, config.ShowOnPause = imgui.checkbox(loc[config.Language].pause, config.ShowOnPause)
        config_changed = config_changed or changed

        imgui.spacing()
        imgui.spacing()

        if config.ShowOnPause then
            if imgui.tree_node(loc[config.Language].in_game) then
                changed, config.InGameFontPrefs = draw_font_prefs_ui(config.InGameFontPrefs)
                config_changed = config_changed or changed

                imgui.tree_pop();
            end

            imgui.spacing()

            if imgui.tree_node(loc[config.Language].on_pause) then
                changed, config.OnPauseFontPrefs = draw_font_prefs_ui(config.OnPauseFontPrefs)
                config_changed = config_changed or changed

                imgui.tree_pop();
            end
        else
            changed, config.InGameFontPrefs = draw_font_prefs_ui(config.InGameFontPrefs)
            config_changed = config_changed or changed
        end

        imgui.pop_font()

        imgui.spacing()
        imgui.spacing()
        imgui.spacing()
        imgui.spacing()

        imgui.tree_pop();
    end

    if config_changed then
        json.dump_file("clocky.json", config)
    end
end)

re.on_config_save(function()
	json.dump_file("clocky.json", config)
end)

init()
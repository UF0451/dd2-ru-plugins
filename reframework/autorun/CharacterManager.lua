local modName = "CharacterManager"
local file = _io_file
local dir = _io_dir
local hotkeys = require("Hotkeys/Hotkeys")
local _parse = sdk.find_type_definition("via.Color"):get_method("Parse")
local options = json.load_file(modName..".json") or {
    ignoreLoadEquipments = false
}

if not options.hotkeys then
    options.hotkeys = { showWindowHotkey = "NumPad0", loadHotkeyPrefix = "NumPad" }
elseif options.hotkeys.loadHotkeyPrefix == "Numpad" then
    options.hotkeys.loadHotkeyPrefix = "NumPad"
end

local function file_exists(fileName)
    local f = io.open(fileName, "r")
    ret = f ~= nil
    if ret then
        f:close()
    end
    return ret
end
local function remove_ext(fileName)
	local idx = fileName:match(".+()%.%w+$")
	if idx then
		return fileName:sub(1, idx-1)
	else
		return fileName
	end
end
local function get_fields(type)
    local fields = type:get_fields()
    if type:get_parent_type() == nil or type:get_parent_type() == type then return fields end
    local parentFields = get_fields(type:get_parent_type())
    for _, field in ipairs(parentFields) do
        table.insert(fields, field)
    end
    return fields
end
local function check(field, type)
    return field:get_type():is_a(type)
end
local function color_to_valuestr(color)
    return tostring(color:get_r())..","..tostring(color:get_g())..","..tostring(color:get_b())..","..tostring(color:get_a())
end
local function obj_to_table(obj, table)
    table = table or {}
    if not sdk.is_managed_object(obj) then return table end

    local fields = get_fields(obj:get_type_definition())
    for _, field in ipairs(fields) do
        if not field:is_static() then
            local name = field:get_name()
            local value = field:get_data(obj)
            if value ~= nil then
                local result = value
                if check(field, "via.Color") then
                    result = color_to_valuestr(value)
                elseif check(field, "app.charaedit.ch000.Scars.SlotData[]") or check(field, "app.charaedit.ch000.Tattoos.SlotData[]") or check(field, "app.CharacterEditDefine.EditValue[]") then
                    result = {}
                    for i, v in pairs(value) do
                        result[i+1] = obj_to_table(v, result[i+1])
                        result[i+1]["type"] = v:get_type_definition():get_full_name()
                    end
                elseif check(field, "app.CharacterEditDefine.HierarchySlider") then -- ignore
                    result = nil
                elseif not field:get_type():is_value_type() then
                    result = obj_to_table(result, table[name])
                    result["type"] = field:get_type():get_full_name()
                end
                table[name] = result
            end
        end
    end
    return table
end
local function table_to_obj(table, objType)
    objType = objType or table["type"]
    if objType == nil then return nil end

    local instance = sdk.create_instance(objType)
    if instance == nil then
        log.warn("["..modName.."] table_to_obj: create "..objType.." instance fail.")
        return nil
    end
    local obj = instance:add_ref()
    for k, v in pairs(table) do
        local t = obj:get_type_definition()
        local field = t:get_field(k)
        local method = t:get_method("set"..k)
        if field ~= nil then
            if check(field, "via.Color") then
                local color = _parse:call(nil, v)
                if method ~= nil then
                    method:call(obj, color)
                else
                    obj:set_field(k, color)
                end
            elseif type(v) ~= "table" then
                if method ~= nil then
                    method:call(obj, v)
                else
                    obj:set_field(k, v)
                end
            else
                if k == "_SlotDatas" or k == "_EditValues" then
                    local dataType = ""
                    local datas = nil
                    for i = 0, #v-1 do
                        dataType = v[i+1]["type"]
                        if datas == nil then
                            datas = sdk.create_managed_array(dataType, #v):add_ref()
                        end
                        datas[i] = table_to_obj(v[i+1], dataType)
                    end
                    if datas ~= nil then
                        if method ~= nil then
                            method:call(obj, datas)
                        else
                            obj:set_field(k, datas)
                        end
                    end
                else
                    local ret = table_to_obj(v)
                    if ret ~= nil then
                        if method ~= nil then
                            method:call(obj, ret)
                        else
                            obj:set_field(k, ret)
                        end
                    end
                end
            end
        end
    end
    return obj
end
local function get_chara_data_list()
    local names = {}
    local files = dir.get_files(modName, ".json", true)
    for i, file in ipairs(files) do
        names[i] = remove_ext(file)
    end
    return names
end
local function save(name)
    local previewModel = sdk.get_managed_singleton("app.GuiManager")._CharaEditCtrl:get_ModelEditor():get_PreviewModelObj()
    local head = previewModel:call("getComponent(System.Type)", sdk.typeof("via.Transform")):find("head"):get_GameObject()
    local headFaceEditor = head:call("getComponent(System.Type)", sdk.typeof("app.FaceEditor"))
    local bodyEditor = previewModel:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
    local bodyEditorBodyEditContext = bodyEditor._BodyEditContext
    local bodyEditorPretenderContext = bodyEditor._PretenderContext -- It's not a Pretender, it's a pose
    local partSwapper = previewModel:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
    local partSwapperHumanContext = partSwapper._HumanContext
    local bodyDetailEditor = previewModel:call("getComponent(System.Type)", sdk.typeof("app.BodyDetailEditor"))
    local bodyDetailEditorContext = bodyDetailEditor._Context

    bodyEditorPretenderContext._Age = bodyEditor._PretenderData._Age
    bodyEditorPretenderContext._SexLowerBody = bodyEditor._PretenderData._SexLowerBody
    bodyEditorPretenderContext._SexUpperBody = bodyEditor._PretenderData._SexUpperBody
    bodyEditorPretenderContext._SpineBend = bodyEditor._PretenderData._SpineBend
    bodyDetailEditorContext:copyFrom(bodyDetailEditor)

    local exportData = {}
    exportData["HeadFaceEditor._Context"] = obj_to_table(headFaceEditor._Context)
    exportData["BodyEditor._BodyEditContext"] = obj_to_table(bodyEditorBodyEditContext)
    exportData["BodyEditor._PretenderContext"] = obj_to_table(bodyEditorPretenderContext)
    exportData["PartSwapper._HumanContext"] = obj_to_table(partSwapperHumanContext)
    exportData["BodyDetailEditor._Context"] = obj_to_table(bodyDetailEditorContext)
    return json.dump_file(modName.."\\"..name..".json", exportData)
end
local function load(name)
    local importData = json.load_file(modName.."\\"..name..".json")
    if importData == nil then return false end

    local headFaceEditor_Context = table_to_obj(importData["HeadFaceEditor._Context"], "app.FaceEditContext")
    local bodyEditor_BodyEditContext = table_to_obj(importData["BodyEditor._BodyEditContext"], "app.BodyEditContext")
    local bodyEditor_PretenderContext = table_to_obj(importData["BodyEditor._PretenderContext"], "app.PretenderContext")
    local partSwapper_HumanContext = table_to_obj(importData["PartSwapper._HumanContext"], "app.PartSwapHumanContext")
    -- local bodyDetailEditorContext = table_to_obj(importData["BodyDetailEditor._Context"], "app.BodyDetailContext")
    local bdec = importData["BodyDetailEditor._Context"]
    local bdec_Skin = table_to_obj(bdec["_Skin"])
    local bdec_Claws = table_to_obj(bdec["_Claws"])
    local bdec_Hair = table_to_obj(bdec["_Hair"])
    local bdec_Beard = table_to_obj(bdec["_Beard"])
    local bdec_BodyHair = table_to_obj(bdec["_BodyHair"])
    local bdec_FurPattern = table_to_obj(bdec["_FurPattern"])
    local bdec_FurFacePattern = table_to_obj(bdec["_FurFacePattern"])
    local bdec_FurFaceMask = table_to_obj(bdec["_FurFaceMask"])
    local bdec_FurForehead = table_to_obj(bdec["_FurForehead"])
    local bdec_FurEyes = table_to_obj(bdec["_FurEyes"])
    local bdec_FurCheeks = table_to_obj(bdec["_FurCheeks"])
    local bdec_FurNose = table_to_obj(bdec["_FurNose"])
    local bdec_Eyes = table_to_obj(bdec["_Eyes"])
    local bdec_Eyelashes = table_to_obj(bdec["_Eyelashes"])
    local bdec_Eyebrows = table_to_obj(bdec["_Eyebrows"])
    local bdec_Eyeliner = table_to_obj(bdec["_Eyeliner"])
    local bdec_Eyeshadow = table_to_obj(bdec["_Eyeshadow"])
    local bdec_Cheek = table_to_obj(bdec["_Cheek"])
    local bdec_Lips = table_to_obj(bdec["_Lips"])
    local bdec_Teeth = table_to_obj(bdec["_Teeth"])
    local bdec_Freckles = table_to_obj(bdec["_Freckles"])
    local bdec_Nose = table_to_obj(bdec["_Nose"])
    local bdec_Dirt = table_to_obj(bdec["_Dirt"])
    local bdec_Tattoos = table_to_obj(bdec["_Tattoos"])
    local bdec_Scars = table_to_obj(bdec["_Scars"])

    local previewModel = sdk.get_managed_singleton("app.GuiManager")._CharaEditCtrl:get_ModelEditor():get_PreviewModelObj()
    local head = previewModel:call("getComponent(System.Type)", sdk.typeof("via.Transform")):find("head"):get_GameObject()
    local headFaceEditor = head:call("getComponent(System.Type)", sdk.typeof("app.FaceEditor"))
    local headBodyEditor = head:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
    local bodyEditor = previewModel:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
    local partSwapper = previewModel:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
    local bodyDetailEditor = previewModel:call("getComponent(System.Type)", sdk.typeof("app.BodyDetailEditor"))

    if headFaceEditor_Context ~= nil then
        headFaceEditor:call("restore(app.FaceEditContext)", headFaceEditor_Context)
    end
    if bodyEditor_BodyEditContext ~= nil and bodyEditor_PretenderContext ~= nil then
        bodyEditor:call("restore(app.BodyEditContext, app.PretenderContext)", bodyEditor_BodyEditContext, bodyEditor_PretenderContext)
        headBodyEditor:copyEditValueFrom(bodyEditor)
    end
    if partSwapper_HumanContext ~= nil then
        if options.ignoreLoadEquipments then
            partSwapper_HumanContext._Meta._BackpackStyle = partSwapper._HumanContext._Meta._BackpackStyle
            partSwapper_HumanContext._Meta._FacewearStyle = partSwapper._HumanContext._Meta._FacewearStyle
            partSwapper_HumanContext._Meta._FacewearVariationStyle = partSwapper._HumanContext._Meta._FacewearVariationStyle
            partSwapper_HumanContext._Meta._HelmStyle = partSwapper._HumanContext._Meta._HelmStyle
            partSwapper_HumanContext._Meta._HelmVariationStyle = partSwapper._HumanContext._Meta._HelmVariationStyle
            partSwapper_HumanContext._Meta._MantleStyle = partSwapper._HumanContext._Meta._MantleStyle
            partSwapper_HumanContext._Meta._MantleVariationStyle = partSwapper._HumanContext._Meta._MantleVariationStyle
            partSwapper_HumanContext._Meta._PantsStyle = partSwapper._HumanContext._Meta._PantsStyle
            partSwapper_HumanContext._Meta._PantsVariationStyle = partSwapper._HumanContext._Meta._PantsVariationStyle
            partSwapper_HumanContext._Meta._TopsStyle = partSwapper._HumanContext._Meta._TopsStyle
            partSwapper_HumanContext._Meta._TopsVariationStyle = partSwapper._HumanContext._Meta._TopsVariationStyle
            partSwapper_HumanContext._Meta._UnderwearStyle = partSwapper._HumanContext._Meta._UnderwearStyle
            partSwapper_HumanContext._Meta._UnderwearVariationStyle = partSwapper._HumanContext._Meta._UnderwearVariationStyle
        end
        partSwapper_HumanContext._Meta._SpecialScar = partSwapper._HumanContext._Meta._SpecialScar
        partSwapper:call("restore(app.PartSwapHumanContext)", partSwapper_HumanContext)
    end
    if true then
        -- bodyDetailEditor:call("restore(app.BodyDetailContext)", bodyDetailEditorContext)
        bodyDetailEditor._Skin:call("restore(app.BodyDetailContext.SkinContext)", bdec_Skin)
        bodyDetailEditor._Claws:call("restore(app.BodyDetailContext.ClawsContext)", bdec_Claws)
        bodyDetailEditor._Hair:call("restore(app.BodyDetailContext.HairContext)", bdec_Hair)
        bodyDetailEditor._Beard:call("restore(app.BodyDetailContext.BeardContext)", bdec_Beard)
        bodyDetailEditor._BodyHair:call("restore(app.BodyDetailContext.BodyHairContext)", bdec_BodyHair)
        bodyDetailEditor._FurPattern:call("restore(app.BodyDetailContext.FurPatternsContext)", bdec_FurPattern)
        bodyDetailEditor._FurFacePattern:call("restore(app.BodyDetailContext.FurFacePatternContext)", bdec_FurFacePattern)
        bodyDetailEditor._FurFaceMask:call("restore(app.BodyDetailContext.FurFaceMaskContext)", bdec_FurFaceMask)
        bodyDetailEditor._FurForehead:call("restore(app.BodyDetailContext.FurForeheadContext)", bdec_FurForehead)
        bodyDetailEditor._FurEyes:call("restore(app.BodyDetailContext.FurEyesContext)", bdec_FurEyes)
        bodyDetailEditor._FurCheeks:call("restore(app.BodyDetailContext.FurCheeksContext)", bdec_FurCheeks)
        bodyDetailEditor._FurNose:call("restore(app.BodyDetailContext.FurNoseContext)", bdec_FurNose)
        bodyDetailEditor._Eyes:call("restore(app.BodyDetailContext.EyesContext)", bdec_Eyes)
        bodyDetailEditor._Eyelashes:call("restore(app.BodyDetailContext.EyelashesContext)", bdec_Eyelashes)
        bodyDetailEditor._Eyebrows:call("restore(app.BodyDetailContext.EyebrowsContext)", bdec_Eyebrows)
        bodyDetailEditor._Makeup:call("restore(app.BodyDetailContext.EyelinerContext, app.BodyDetailContext.EyeshadowContext, app.BodyDetailContext.CheekContext, app.BodyDetailContext.LipsContext)", 
            bdec_Eyeliner, bdec_Eyeshadow, bdec_Cheek, bdec_Lips)
        bodyDetailEditor._Teeth:call("restore(app.BodyDetailContext.TeethContext)", bdec_Teeth)
        bodyDetailEditor._Freckles:call("restore(app.BodyDetailContext.FrecklesContext)", bdec_Freckles)
        bodyDetailEditor._Nose:call("restore(app.BodyDetailContext.NoseContext)", bdec_Nose)
        bodyDetailEditor._Dirt:call("restore(app.BodyDetailContext.DirtContext)", bdec_Dirt)
        bodyDetailEditor._Tattoos:call("restore(app.charaedit.ch000.Tattoos.SlotData[], System.Boolean)", bdec_Tattoos:get_SlotDatas(), true)
        bodyDetailEditor._Scars:call("restore(app.charaedit.ch000.Scars.SlotData[], System.Boolean)", bdec_Scars:get_SlotDatas(), true)
    end
    return true
end

local editName = "Untitled"
local selected = 1
local charaList = {}
local filterList = {}
local filterText = ""
local updateList = true
local confirm = 0
local confirmItem = ""
local msg = ""
local nextTip = ""
local showWindow = false
local windowInited = false
-- [[ pagination
local maxPageCount = 9
local pages = 0
local page = 1
local jumpPageText = ""
-- ]]
local _showWindowHotkey = modName.."Show Window Hotkey"
local _prevPageHotkey = modName.."Prev Page"
local _nextPageHotkey = modName.."Next Page"
local _refreshHotkey = modName.."Refresh"
local _hotkeys = {
    [_showWindowHotkey] = options.hotkeys.showWindowHotkey,
    [_prevPageHotkey] = "Subtract",
    [_nextPageHotkey] = "Add",
    [_refreshHotkey] = "Multiply",
}

for i = 1, maxPageCount do
    if i <= 9 then
        _hotkeys["Load Preset "..tostring(i)] = options.hotkeys.loadHotkeyPrefix..tostring(i)
    else
        break
    end
end

hotkeys.setup_hotkeys(_hotkeys)

local function tree_pop()
    if msg ~= "" then
        imgui.text_colored("msg: "..msg, 0xff0000ff)
    end
    imgui.tree_pop()
end
local function set_table_colmun(text1, text2)
    imgui.table_next_column()
    imgui.spacing()
    imgui.text(text1)
    imgui.spacing()
    imgui.table_next_column()
    imgui.spacing()
    imgui.text(text2)
    imgui.spacing()
end
local function get_chara_idx(offset)
    return ((page-1)*maxPageCount)+offset
end
local function update_pages()
    if filterText ~= "" and #charaList > 0 then
        filterList = {}
        for i = 1, #charaList do
            local v = charaList[i]
            if v and string.find(v, filterText) ~= nil then
                table.insert(filterList, v)
            end
        end
    end

    pages = ((#filterList > 0 and #filterList or #charaList) / maxPageCount) + 1
    pages, _ = math.modf(pages)
    page = 1
end
local function get_chedit_ui()
    local scene = sdk.call_native_func(sdk.get_native_singleton("via.SceneManager"), sdk.find_type_definition("via.SceneManager"), "get_CurrentScene()")
    local charaEditModelCtrl = scene:call("findGameObject(System.String)", "CharaEditModelCtrl")
    
    if charaEditModelCtrl == nil then
        nextTip = "=D Plz into the \"Modify Appearance\""
        return -1, nil
    end

    local ui070406_01 = charaEditModelCtrl:call("getComponent(System.Type)", sdk.typeof("via.Transform")):find("ui070406_01")
    if ui070406_01 == nil then
        nextTip = "=D Plz into the \"Detailed Customization\""
        return 0, nil
    end

    nextTip = ""
    return 1, ui070406_01
end

re.on_frame(function() 
    local changed = false

    if updateList then
        charaList = get_chara_data_list()
        updateList = false
        update_pages()
        local i = 1
        for i = 3, 1, -1 do
            for _, n in ipairs(charaList) do
                if n == "Untitled"..(i > 1 and tostring(i) or "") then
                    i = i + 1
                    editName = "Untitled"..tostring(i)
                end
            end
        end
    end
    if hotkeys.check_hotkey(_showWindowHotkey, false, true) then
        showWindow = not showWindow
        if not showWindow then 
            windowInited = false
        end
    end
    if not showWindow then
        return
    end
    local ret, headui = get_chedit_ui()
    if ret == 1 then
        for index = 1, maxPageCount do
            local i = get_chara_idx(index)
            local c = hotkeys.check_hotkey("Load Preset " .. tostring(index), false, true)
            if #filterList > 0 then
                if i < #filterList+1 and c then 
                    load(filterList[i])
                    break
                end
            elseif i < #charaList+1 and c then
                load(charaList[i])
                break
            end
        end
    end
    if hotkeys.check_hotkey(_prevPageHotkey) then
        page = page - 1
        if page < 1 then
            page = pages
        end
    elseif hotkeys.check_hotkey(_nextPageHotkey) then
        page = page + 1
        if page > pages then
            page = 1
        end
    end
    if hotkeys.check_hotkey(_refreshHotkey) then
        updateList = true
    end
    if not windowInited then
        local displaySize = imgui.get_display_size()
        local windowWidth = 320
        local windowHeight = 470
        local centerX = displaySize.x - windowWidth / 2 - 40
        local centerTopY = windowHeight / 2 + 40
    
        imgui.set_next_window_pos(Vector2f.new(centerX, centerTopY), 0, Vector2f.new(0.5, 0.5))
        imgui.set_next_window_size(Vector2f.new(windowWidth, windowHeight), 0)

        windowInited = true
    end

    showWindow = imgui.begin_window(modName, true, 0)
    imgui.indent(10)
    imgui.spacing()
    imgui.spacing()

    if nextTip ~= "" then
        imgui.text_colored(nextTip, 0xff00ff00)
    else
        imgui.text("Введите клавишу для загрузки пресета.")
    end

    imgui.spacing()
    changed, filterText = imgui.input_text("Поиск", filterText)
    if changed then
        filterList = {}
        update_pages()
    end
    
    imgui.spacing()
    imgui.text(" Стр. "..tostring(page).."/"..tostring(pages))
    imgui.spacing()
    imgui.spacing()
    imgui.begin_table("1", 2, nil, Vector2f.new(325, 100), 10.0)
    imgui.table_setup_column("Клавиша")
    imgui.table_setup_column("Пресет")
    imgui.table_headers_row()

    for index = 1, maxPageCount do
        local key = " ".._hotkeys["Load Preset "..tostring(index)]
        local i = get_chara_idx(index)

        if #filterList > 0 then
            set_table_colmun(key, i < #filterList + 1 and filterList[i] or " ")
        else
            set_table_colmun(key, i < #charaList + 1 and charaList[i] or " ")
        end
    end

    set_table_colmun(" - | +", "Назад | Вперёд")
    set_table_colmun(" * | "..options.hotkeys.showWindowHotkey, "Обновить | Закрыть")

    imgui.end_table()
    imgui.end_window()
end)

re.on_draw_ui(function()
	if imgui.tree_node(modName) then
		local changed = false
        local ret, headui = get_chedit_ui()
        
        _, showWindow = imgui.checkbox("Видимый", showWindow)

        imgui.text("-------- Сохранить --------")
        changed, editName = imgui.input_text("*", editName)
        if changed then confirm = 0 end
        if editName ~= "" and ret == 1 then
            imgui.text_colored("=D вернитесь в интерфейс с кнопкой \"Завершить\" после редактирования для сохранения.", 0xff00ff00)
        end
        if editName ~= "" and ret == 0 then
            imgui.same_line()
            if confirm ~= 1 and imgui.button("Сохранить") then
                if not file_exists(modName.."\\"..editName..".json") or fs.read(modName.."\\"..editName..".json") == "" then
                    msg = ""
                    if save(editName) then
                        updateList = true
                    else
                        msg = "Сохранение "..editName.." не удалось!"
                    end
                    confirm = 0
                else
                    msg = "Файл с таким именем уже существует."
                    confirm = 1
                    confirmItem = editName
                end
            end
            if confirm == 1 then
                imgui.same_line()
                if imgui.button("Подтвердить замену") then
                    msg = ""
                    if save(confirmItem) then
                        updateList = true
                    else
                        msg = "Сохранение "..confirmItem.." не удалось!"
                    end
                    confirm = 0
                end
            end
        else
            if ret == -1 then
                imgui.text_colored(nextTip, 0xff00ff00)
            end    
        end

        imgui.text("-------- Пресеты ["..tostring(#charaList).."] --------")

        changed, selected = imgui.combo(" ", selected, charaList)
        if changed then confirm = 0 end

        imgui.same_line()
        if confirm ~= 2 and imgui.button("Удалить") then
            confirm = 2
            confirmItem = charaList[selected]
        end
        if confirm == 2 then
            imgui.same_line()
            if imgui.button("Подтвердить удаление") then
                file.delete(modName.."\\"..confirmItem..".json")
                updateList = true
                confirm = 0
            end
        end
        if ret == 0 then
            imgui.text_colored(nextTip, 0xff00ff00)
        elseif #charaList > 0 then
            local isLoaded = false
            if imgui.button("Загрузить") then
                if load(charaList[selected]) then
                    isLoaded = true
                end
                msg = isLoaded and "" or "Загрузка "..charaList[selected].." не удалось!"
                confirm = 0
            end
            imgui.same_line()
            if imgui.button("Обновить") then
                updateList = true
            end
            if isLoaded then
                headui:get_GameObject():call("getComponent(System.Type)", sdk.typeof("app.ui070406_01")):reset()
            end
        end

        imgui.text("-------- Опции загрузки --------")
        changed, options.ignoreLoadEquipments = imgui.checkbox("Игнорировать экипировку", options.ignoreLoadEquipments)
        imgui.text("-------- Опции клавиш --------")
        if hotkeys.hotkey_setter(_showWindowHotkey, nil, "Клавиша показа/скрытия", "Установить клавишу для окна пресетов.") then changed = true end
        imgui.text("-------- Префикс клавиши загрузки --------")
        local _changed = false
        _changed, options.hotkeys.loadHotkeyPrefix = imgui.input_text("Изменить", options.hotkeys.loadHotkeyPrefix)
        if _changed then changed = true end
        if changed then
            options.hotkeys.showWindowHotkey = hotkeys.hotkeys[_showWindowHotkey]
            json.dump_file(modName..".json", options)
        end

        tree_pop()
	end
end)
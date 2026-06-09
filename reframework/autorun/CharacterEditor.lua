local re = re
local sdk = sdk
local log = log
local json = json

log.info("[Character Customization Clone] Loaded")

local Config = {}
if Config.EnableMod == nil then Config.EnableMod = true end
local configFilePath = "CharacterCustomizationClone\\CharacterCustomizationClone.json"

local function saveConfig()
    local success, err = pcall(json.dump_file, configFilePath, Config)
    if not success then log.error("Error saving configuration: " .. tostring(err)) end
end

local function loadConfig()
    local status, data = pcall(json.load_file, configFilePath)
    if status and data and type(data) == "table" then Config.EnableMod = data.EnableMod end
end
loadConfig()

local function generate_enumIndex(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end
    local fields = t:get_fields()
    local enum = {}
    for i, field in ipairs(fields) do
        if field:is_static() then
            local raw_value = field:get_data(nil)
            enum[raw_value] = raw_value
        end
    end
    return enum 
end

function getPlayer()
    local cm = sdk.get_managed_singleton("app.CharacterManager")
    if cm == nil then return nil end
    return cm:get_ManualPlayer()
end

-- Переменные для экспорта
local ExportFaceEditData = {}
local ExportBodyEditData = {}
local ExportBodyDetail_SkinContext, ExportBodyDetail_ClawContext, ExportBodyDetail_HairContext, ExportBodyDetail_BeardContext, ExportBodyDetail_BodyHairContext = nil, nil, nil, nil, nil
local ExportBodyDetail_FurPatternContext, ExportBodyDetail_FurFacePatternContext, ExportBodyDetail_FurFaceMaskContext, ExportBodyDetail_FurForeheadContext, ExportBodyDetail_FurEyesContext = nil, nil, nil, nil, nil
local ExportBodyDetail_FurCheeksContext, ExportBodyDetail_FurNoseContext, ExportBodyDetail_EyesContext, ExportBodyDetail_EyebrowsContext, ExportBodyDetail_EyelashesContext = nil, nil, nil, nil, nil
local ExportBodyDetail_EyelinerContext, ExportBodyDetail_EyeshadowContext, ExportBodyDetail_CheekContext, ExportBodyDetail_LipsContext, ExportBodyDetail_TeethContext = nil, nil, nil, nil, nil
local ExportBodyDetail_FrecklesContext, ExportBodyDetail_NoseContext, ExportBodyDetail_DirtContext, ExportBodyDetail_TattoosContext, ExportBodyDetail_ScarsContext = nil, nil, nil, nil, nil
local ExportBodyDetail_partSwapHumanContext = nil

local faceIDEnum = generate_enumIndex("app.FaceEditID")
local bodyIDEnum = generate_enumIndex("app.BodyEditID")

local isExported = false
local curName = ""
local characterNameObjKvp = {}
local characterNameList = {}

re.on_draw_ui(function()
    if imgui.tree_node("Клон кастомизации") then
        local changed = false
        changed, Config.EnableMod = imgui.checkbox("Включить мод", Config.EnableMod)
 
        local player = getPlayer()
        if player ~= nil then
            if not isExported then
                characterNameList = {}
                local playerContextholder = player:get_Context()
                if playerContextholder ~= nil then
                    local playerContextList = playerContextholder.Contexts
                    local personalRuntimeType = sdk.find_type_definition("app.PlayerPersonalDataContext"):get_runtime_type()
                    local personalContextInfo = playerContextList[personalRuntimeType]
                    if personalContextInfo ~= nil then
                        local personalContext = personalContextInfo:get_CurrentContext()
                        local playerName = personalContext:get_NameProp()
                        characterNameList[0] = playerName
                        characterNameObjKvp[playerName] = player
                    end
                end

                local pawnMgr = sdk.get_managed_singleton("app.PawnManager")
                if pawnMgr ~= nil then
                    local cList = pawnMgr:get_PawnCharacterList()
                    local count = cList:get_Count()
                    for i = 0, count - 1 do
                        local pawnChara = cList:get_Item(i)
                        local pawnContextholder = pawnChara:get_Context()
                        local pawnContextList = pawnContextholder.Contexts
                        local pawnDataRuntimeType = sdk.find_type_definition("app.PawnDataContext"):get_runtime_type()
                        local pawnDataContextInfo = pawnContextList[pawnDataRuntimeType]
                        local pawnDataContext = pawnDataContextInfo:get_CurrentContext()
                        local pawnName = pawnDataContext:get_Nickname()
                        characterNameList[i + 1] = pawnName
                        characterNameObjKvp[pawnName] = pawnChara
                    end
                end

                changed, curName = imgui.combo("Список персонажей", curName, characterNameList)
                if imgui.button("Копировать") and characterNameList[curName] ~= nil then
                    local contextholder = characterNameObjKvp[characterNameList[curName]]:get_Context()
                    local contextList = contextholder.Contexts
                    
                    local faceEditContext = contextList[sdk.find_type_definition("app.FaceEditContext"):get_runtime_type()]:get_CurrentContext()
                    local faceEditList = faceEditContext:get_EditValues()
                    for i = 0, faceEditList:get_Count() - 1 do
                        local item = faceEditList:get_Item(i)
                        ExportFaceEditData[item._EditKeyHash] = item._Value
                    end
                    
                    local bodyEditContext = contextList[sdk.find_type_definition("app.BodyEditContext"):get_runtime_type()]:get_CurrentContext()
                    local bodyEditList = bodyEditContext:get_EditValues()
                    for i = 0, bodyEditList:get_Count() - 1 do
                        local item = bodyEditList:get_Item(i)
                        ExportBodyEditData[item._EditKeyHash] = item._Value
                    end
                    
                    ExportBodyDetail_partSwapHumanContext = contextList[sdk.find_type_definition("app.PartSwapHumanContext"):get_runtime_type()]:get_CurrentContext()
                    local bodyDetailEditContext = contextList[sdk.find_type_definition("app.BodyDetailContext"):get_runtime_type()]:get_CurrentContext()
                    
                    ExportBodyDetail_SkinContext, ExportBodyDetail_ClawContext, ExportBodyDetail_HairContext = bodyDetailEditContext._Skin, bodyDetailEditContext._Claws, bodyDetailEditContext._Hair
                    ExportBodyDetail_BeardContext, ExportBodyDetail_BodyHairContext, ExportBodyDetail_FurPatternContext = bodyDetailEditContext._Beard, bodyDetailEditContext._BodyHair, bodyDetailEditContext._FurPattern
                    ExportBodyDetail_FurFacePatternContext, ExportBodyDetail_FurFaceMaskContext, ExportBodyDetail_FurForeheadContext = bodyDetailEditContext._FurFacePattern, bodyDetailEditContext._FurFaceMask, bodyDetailEditContext._FurForehead
                    ExportBodyDetail_FurEyesContext, ExportBodyDetail_FurCheeksContext, ExportBodyDetail_FurNoseContext = bodyDetailEditContext._FurEyes, bodyDetailEditContext._FurCheeks, bodyDetailEditContext._FurNose
                    ExportBodyDetail_EyesContext, ExportBodyDetail_EyebrowsContext, ExportBodyDetail_EyelashesContext = bodyDetailEditContext._Eyes, bodyDetailEditContext._Eyebrows, bodyDetailEditContext._Eyelashes
                    ExportBodyDetail_EyelinerContext, ExportBodyDetail_EyeshadowContext, ExportBodyDetail_CheekContext = bodyDetailEditContext._Eyeliner, bodyDetailEditContext._Eyeshadow, bodyDetailEditContext._Cheek
                    ExportBodyDetail_LipsContext, ExportBodyDetail_TeethContext, ExportBodyDetail_FrecklesContext = bodyDetailEditContext._Lips, bodyDetailEditContext._Teeth, bodyDetailEditContext._Freckles
                    ExportBodyDetail_NoseContext, ExportBodyDetail_DirtContext, ExportBodyDetail_TattoosContext, ExportBodyDetail_ScarsContext = bodyDetailEditContext._Nose, bodyDetailEditContext._Dirt, bodyDetailEditContext._Tattoos, bodyDetailEditContext._Scars

                    isExported = true
                end
            end
        end

        if isExported then
            local scene = sdk.call_native_func(sdk.get_native_singleton("via.SceneManager"), sdk.find_type_definition("via.SceneManager"), "get_CurrentScene()")
            if scene ~= nil then
                local charaEditModelCtrlObj = scene:call("findGameObject(System.String)", "CharaEditModelCtrl")
                if charaEditModelCtrlObj ~= nil then
                    local charaEditModelCtrlTransform = charaEditModelCtrlObj:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
                    local uiTrans = charaEditModelCtrlTransform:find("ui070406_01")
                    if uiTrans ~= nil and imgui.button("Вставить " .. tostring(characterNameList[curName])) then
                        local guiMgr = sdk.get_managed_singleton("app.GuiManager")
                        local modelEditor = guiMgr._CharaEditCtrl:get_ModelEditor()
                        local previewObj = modelEditor:get_PreviewModelObj()
                        local headGameObj = previewObj:call("getComponent(System.Type)", sdk.typeof("via.Transform")):find("head"):get_GameObject()
                        local headFaceEditor = headGameObj:call("getComponent(System.Type)", sdk.typeof("app.FaceEditor"))
                        
                        -- Восстановление параметров (с проверками)
                        for key, value in pairs(ExportFaceEditData) do headFaceEditor:setEditValue(faceIDEnum[key], value, false) headFaceEditor:applyEdit() end
                        
                        local headbodyEditor = headGameObj:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
                        for key, value in pairs(ExportBodyEditData) do headbodyEditor:setEditValue(bodyIDEnum[key], value, false) headbodyEditor:applyEdit() end
                        
                        local bodyEditor = previewObj:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
                        for key, value in pairs(ExportBodyEditData) do bodyEditor:setEditValue(bodyIDEnum[key], value, false) bodyEditor:applyEdit() end

                        local partSwapper = previewObj:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
                        if ExportBodyDetail_partSwapHumanContext then partSwapper:call("restore(app.PartSwapHumanContext)", ExportBodyDetail_partSwapHumanContext) end

                        local bodyDetailEditor = previewObj:call("getComponent(System.Type)", sdk.typeof("app.BodyDetailEditor"))
                        if ExportBodyDetail_SkinContext then bodyDetailEditor._Skin:call("restore(app.BodyDetailContext.SkinContext)", ExportBodyDetail_SkinContext) end
                        if ExportBodyDetail_ClawContext then bodyDetailEditor._Claws:call("restore(app.BodyDetailContext.ClawsContext)", ExportBodyDetail_ClawContext) end
                        if ExportBodyDetail_HairContext then bodyDetailEditor._Hair:call("restore(app.BodyDetailContext.HairContext)", ExportBodyDetail_HairContext) end
                        if ExportBodyDetail_BeardContext then bodyDetailEditor._Beard:call("restore(app.BodyDetailContext.BeardContext)", ExportBodyDetail_BeardContext) end
                        if ExportBodyDetail_BodyHairContext then bodyDetailEditor._BodyHair:call("restore(app.BodyDetailContext.BodyHairContext)", ExportBodyDetail_BodyHairContext) end
                        if ExportBodyDetail_FurPatternContext then bodyDetailEditor._FurPattern:call("restore(app.BodyDetailContext.FurPatternsContext)", ExportBodyDetail_FurPatternContext) end
                        if ExportBodyDetail_FurFacePatternContext then bodyDetailEditor._FurFacePattern:call("restore(app.BodyDetailContext.FurFacePatternContext)", ExportBodyDetail_FurFacePatternContext) end
                        if ExportBodyDetail_FurFaceMaskContext then bodyDetailEditor._FurFaceMask:call("restore(app.BodyDetailContext.FurFaceMaskContext)", ExportBodyDetail_FurFaceMaskContext) end
                        if ExportBodyDetail_FurForeheadContext then bodyDetailEditor._FurForehead:call("restore(app.BodyDetailContext.FurForeheadContext)", ExportBodyDetail_FurForeheadContext) end
                        if ExportBodyDetail_FurEyesContext then bodyDetailEditor._FurEyes:call("restore(app.BodyDetailContext.FurEyesContext)", ExportBodyDetail_FurEyesContext) end
                        if ExportBodyDetail_FurCheeksContext then bodyDetailEditor._FurCheeks:call("restore(app.BodyDetailContext.FurCheeksContext)", ExportBodyDetail_FurCheeksContext) end
                        if ExportBodyDetail_FurNoseContext then bodyDetailEditor._FurNose:call("restore(app.BodyDetailContext.FurNoseContext)", ExportBodyDetail_FurNoseContext) end
                        if ExportBodyDetail_EyesContext then bodyDetailEditor._Eyes:call("restore(app.BodyDetailContext.EyesContext)", ExportBodyDetail_EyesContext) end
                        if ExportBodyDetail_EyelashesContext then bodyDetailEditor._Eyelashes:call("restore(app.BodyDetailContext.EyelashesContext)", ExportBodyDetail_EyelashesContext) end
                        if ExportBodyDetail_EyebrowsContext then bodyDetailEditor._Eyebrows:call("restore(app.BodyDetailContext.EyebrowsContext)", ExportBodyDetail_EyebrowsContext) end
                        if ExportBodyDetail_EyelinerContext and ExportBodyDetail_EyeshadowContext and ExportBodyDetail_CheekContext and ExportBodyDetail_LipsContext then
                            bodyDetailEditor._Makeup:call("restore(app.BodyDetailContext.EyelinerContext, app.BodyDetailContext.EyeshadowContext, app.BodyDetailContext.CheekContext, app.BodyDetailContext.LipsContext)", ExportBodyDetail_EyelinerContext, ExportBodyDetail_EyeshadowContext, ExportBodyDetail_CheekContext, ExportBodyDetail_LipsContext)
                        end
                        if ExportBodyDetail_TeethContext then bodyDetailEditor._Teeth:call("restore(app.BodyDetailContext.TeethContext)", ExportBodyDetail_TeethContext) end
                        if ExportBodyDetail_FrecklesContext then bodyDetailEditor._Freckles:call("restore(app.BodyDetailContext.FrecklesContext)", ExportBodyDetail_FrecklesContext) end
                        if ExportBodyDetail_NoseContext then bodyDetailEditor._Nose:call("restore(app.BodyDetailContext.NoseContext)", ExportBodyDetail_NoseContext) end
                        if ExportBodyDetail_DirtContext then bodyDetailEditor._Dirt:call("restore(app.BodyDetailContext.DirtContext)", ExportBodyDetail_DirtContext) end
                        if ExportBodyDetail_TattoosContext then bodyDetailEditor._Tattoos:call("restore(app.charaedit.ch000.Tattoos.SlotData[], System.Boolean)", ExportBodyDetail_TattoosContext:get_SlotDatas(), true) end
                        if ExportBodyDetail_ScarsContext then bodyDetailEditor._Scars:call("restore(app.charaedit.ch000.Scars.SlotData[], System.Boolean)", ExportBodyDetail_ScarsContext:get_SlotDatas(), true) end
                        
                        uiTrans:get_GameObject():call("getComponent(System.Type)", sdk.typeof("app.ui070406_01")):reset()
                        isExported = false
                    end
                end
            end
        end

        if changed then saveConfig() end
        imgui.tree_pop()
    end
end)
local re = re
local sdk = sdk
local log = log
local json = json
local hotkeys = require("Hotkeys/Hotkeys")
local TrulyWizzard = {}

log.debug("[TrulyWizzard] Мод успешно загружен");

local Config = {}

if Config.EnableMod == nil then
	Config.EnableMod = true
end

if Config.LevitateParam == nil then
	Config.LevitateParam = {
		MaxHeight = 20.0,
		MaxKeepSec = 30.0,
		HorizontalAcceleration = 10.0,
		KeepLevitateMoveSpeedRate = 2.0
	}
end

if Config.Hotkeys == nil then
	Config.Hotkeys = {
		["ConcentrateKey"] = "Y",
	}
end

if Config.MagicSkillLockOnRangeRate == nil then
	Config.MagicSkillLockOnRangeRate = 2.0
end

if Config.ConcentrateRate == nil then
	Config.ConcentrateRate = 2.75
end

local configFilePath = "TrulyWizzard\\TrulyWizzard.json"

function TrulyWizzard.saveConfig()
    local success, err = pcall(json.dump_file, configFilePath, Config)
    if not success then
        log.error("Ошибка сохранения конфигурации: " .. tostring(err))
    end
end

function TrulyWizzard.loadConfig()
    local status, data = pcall(json.load_file, configFilePath)
    if not status or not data then
        return
    end

    if type(data) == "table" then
		Config.EnableMod = data.EnableMod
		Config.LevitateParam = data.LevitateParam
		if data.MagicSkillLockOnRangeRate ~= nil then
			Config.MagicSkillLockOnRangeRate = data.MagicSkillLockOnRangeRate
		end
		if data.Hotkeys ~= nil then
			Config.Hotkeys = data.Hotkeys
		end
		if data.ConcentrateRate ~= nil then
			Config.ConcentrateRate = data.ConcentrateRate
		end
    end
end

TrulyWizzard.loadConfig()

hotkeys.setup_hotkeys(Config.Hotkeys)

function TrulyWizzard.generate_enum(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

            enum[name] = raw_value
        end
    end

    return enum
end

local characterMgr = sdk.get_managed_singleton("app.CharacterManager")
local player = nil
local tempStatusEnum = TrulyWizzard.generate_enum("app.Character.TempStatusEnum")
local skillIdEnum = TrulyWizzard.generate_enum("app.HumanCustomSkillID")
local jobEnum = TrulyWizzard.generate_enum("app.Character.JobEnum")
local lockOnParamActionType = TrulyWizzard.generate_enum("app.LockOnRangeParameter.ActionTypeEnum")

local MaxLockOnRangeTargetDarkDefalut = 10.0
local AbortLockOnRangeTargetDarkDefalut = 12.0
local MaxLockOnRangeTargetInGrassDefalut = 3.0
local AbortLockOnRangeTargetInGrassDefalut = 5.0
local MaxDistanceDefalut = 32.0
local concentrateRateDefault = 2.75

local isInLevitate = false
local isCasting = false
local notCastingTimer = nil
local isConcentrate = false

function TrulyWizzard.getPlayer()
	local player = characterMgr:get_ManualPlayer()
	return player
end

function TrulyWizzard.ActionOwnerIsCharacter(action)
	if action == nil then
		return false
	end
	local chara = action.Chara
	if chara == nil then
		chara = action['<Character>k__BackingField']
	end
	player = TrulyWizzard.getPlayer()

	if player == nil or chara == nil then
		return false
	end

	if player == chara then
		return true
	end
	return false
end

-- Системная проверка состояния лестницы (Слой локомоции + нативные статусы)
local function checkIsOnLadder(pl)
    if pl == nil then return false end
    
    local locomotionCtrl = pl:get_field("LocomotionController") or pl:call("get_LocomotionController")
    if locomotionCtrl ~= nil then
        local locMode = locomotionCtrl:get_field("CurrLocomotionMode") or locomotionCtrl:call("get_CurrLocomotionMode")
        if locMode ~= nil then
            local modeVal = type(locMode) == "number" and locMode or locMode:get_field("value__")
            if modeVal == 6 or modeVal == 7 or modeVal == 8 then return true end
        end
    end

    local charaStatus = pl.get_Status and pl:get_Status() or pl.Status
    if charaStatus ~= nil then
        if charaStatus.isClimbLadder and charaStatus:isClimbLadder() then return true
        elseif charaStatus.call and charaStatus:call("isClimbLadder") then return true end
    end

    return false
end

function TrulyWizzard.getCurNodeNameAndFrame(layerIndex)
	player = TrulyWizzard.getPlayer()
	local nodeName = ""
	local curFrame = 0
	if player ~= nil then
		local gameobj = player:get_GameObject()
		local motion = gameobj:call("getComponent(System.Type)", sdk.typeof("via.motion.Motion"))
		local mfsm2 = gameobj:call("getComponent(System.Type)", sdk.typeof("via.motion.MotionFsm2"))
		if mfsm2 then
			nodeName = mfsm2:getCurrentNodeName(layerIndex) or ""
		end
		if motion then
			local layer = motion:getLayer(layerIndex)
			if layer then curFrame = layer:get_Frame() or 0 end
		end
	end

	return nodeName, curFrame
end

function TrulyWizzard.RequestKeepLevitate()
	player = TrulyWizzard.getPlayer()
	local gameobj = player:get_GameObject()
	local actionMgr = gameobj:call("getComponent(System.Type)", sdk.typeof("app.ActionManager"))
	actionMgr:requestActionCore(0, "JobMagicUser_KeepLevitate", 0)
end

function TrulyWizzard.resetFreeFallCtrl()
	player = TrulyWizzard.getPlayer()
	local freeFallCtrl = player:get_FreeFallCtrl()
	if freeFallCtrl then
		freeFallCtrl.DefaultFrameGravity = 0.003
		freeFallCtrl:set_IsActive(true)
		freeFallCtrl:set_IsRise(false)
	end
end

function TrulyWizzard.resetLockRange()
	TrulyWizzard.SetLockOnRangeParameters(1)
end

function TrulyWizzard.resetStatus()
	isInLevitate = false
	isCasting = false
	notCastingTimer = nil
end

function TrulyWizzard.SetLockOnRangeParameters(rate)
	player = TrulyWizzard.getPlayer()
	if player ~= nil then
		local gameobj = player:get_GameObject()
		local appPlayer = gameobj:call("getComponent(System.Type)", sdk.typeof("app.Player"))
		local lockOnCtrl = appPlayer:get_LockOnCtrl()
		local paramList = lockOnCtrl['<ParamList>k__BackingField']
		local params = paramList.Parameters
		local paramsSize = params:get_size()
		for i = 0, paramsSize - 1 do
			local param = params[i]
			if param ~= nil then
				if param.Job == jobEnum["Job06"] or param.Job == jobEnum["Job03"] then
					param.MaxLockOnRangeTargetDark = MaxLockOnRangeTargetDarkDefalut * rate
					param.AbortLockOnRangeTargetDark = AbortLockOnRangeTargetDarkDefalut * rate
					param.MaxLockOnRangeTargetInGrass = MaxLockOnRangeTargetInGrassDefalut * rate
					param.AbortLockOnRangeTargetInGrass = AbortLockOnRangeTargetInGrassDefalut * rate
					local paramTypeParams = param.Parameters
					local paramTypeParamsSize = paramTypeParams:get_size()
					for j = 0, paramTypeParamsSize - 1 do
						local paramTypeParam = paramTypeParams[j]
						if paramTypeParam ~= nil and paramTypeParam.ActionType == lockOnParamActionType["CustomSkill"] then
							paramTypeParam.MaxDistance = MaxDistanceDefalut * rate
						end
					end
				end
			end
		end
	end
end

--========================================================--
-- ГЛОБАЛЬНЫЙ ПЕРЕХВАТЧИК ЭКШЕНОВ (Фикс автоматического захвата лестниц)
--========================================================--
sdk.hook(
    sdk.find_type_definition("app.ActionManager"):get_method("requestActionCore(System.Int32, System.String, System.Int32)"),
    function(args)
        if Config.EnableMod then
            local actionName = sdk.to_string(args[3])
            if actionName ~= nil then
                local nameL = string.lower(actionName)
                -- Если движок игры запрашивает перевод персонажа на лестницу
                if string.find(nameL, "ladder") or string.find(nameL, "climb") or string.find(nameL, "ladd") then
                    player = TrulyWizzard.getPlayer()
                    if player ~= nil then
                        local actionMgr = player:call("getComponent(System.Type)", sdk.typeof("app.ActionManager"))
                        if actionMgr ~= nil and args[2] == actionMgr:get_address() then
                            -- Мгновенно аннулируем всё парение скрипта ДО того, как игра сломает коллизии
                            isInLevitate = false
                            isCasting = false
                            isConcentrate = false
                            TrulyWizzard.resetFreeFallCtrl()
                            
                            local tempStat = player:get_TempStatus() or player:call("get_TempStatus")
                            if tempStat then
                                tempStat:call("remove(app.Character.TempStatusEnum)", tempStatusEnum["DisabledGravity"])
                                tempStat:call("remove(app.Character.TempStatusEnum)", tempStatusEnum["DisableAutoFallAction"])
                            end
                        end
                    end
                end
            end
        end
    end,
    function(retval) return retval end
)

sdk.hook(
	sdk.find_type_definition("app.HumanReadySpell"):get_method("start(via.behaviortree.ActionArg)"),
	function (args)
		local storage = thread.get_hook_storage()
        storage["this"] = sdk.to_managed_object(args[2])
	end,
	function (rtVal)
		if Config.EnableMod then
			local this = thread.get_hook_storage()["this"]
			if TrulyWizzard.ActionOwnerIsCharacter(this) and isInLevitate then
				if checkIsOnLadder(player) then return rtVal end

				local humanActionSelector = player:get_HumanActionSelector()
				local currentSelector = humanActionSelector.CurrentSelector
				local prepareSpellAction = currentSelector:call("getCustomSkillAction(app.HumanCustomSkillID, app.LocomotionSpeedTypeEnum)", this.StockSkillID, 1)

				local castSpellAction = ""
				if prepareSpellAction ~= nil then
					castSpellAction = prepareSpellAction:gsub("Prepare", "Cast")
				end

				if this.StockSkillID == skillIdEnum["Job03_HolyGlare"] then
					castSpellAction = "Job03_CastHolyGlare"
				end

				player = TrulyWizzard.getPlayer()
				player:get_TempStatus():call("add(app.Character.TempStatusEnum)", tempStatusEnum["DisabledGravity"])
				player:get_TempStatus():call("add(app.Character.TempStatusEnum)", tempStatusEnum["DisableAutoFallAction"])

				currentSelector:requestActionImpl(castSpellAction, 0)
				currentSelector:requestActionImpl(castSpellAction, 1)
				isCasting = true
			end
		end
		return rtVal
	end
)

sdk.hook(
	sdk.find_type_definition("app.JobMagicUserCastMagic"):get_method("start(via.behaviortree.ActionArg)"),
	function (args)
		local storage = thread.get_hook_storage()
		storage["this"] = sdk.to_managed_object(args[2])
	end,
	function(rtVal)
		if Config.EnableMod then
			local this = thread.get_hook_storage()["this"]
			if TrulyWizzard.ActionOwnerIsCharacter(this) and isInLevitate then
				if checkIsOnLadder(player) then return rtVal end

				player = TrulyWizzard.getPlayer()
				player:get_TempStatus():call("add(app.Character.TempStatusEnum)", tempStatusEnum["DisabledGravity"])
				player:get_TempStatus():call("add(app.Character.TempStatusEnum)", tempStatusEnum["DisableAutoFallAction"])
				local freeFallCtrl = player:get_FreeFallCtrl()
				if freeFallCtrl then freeFallCtrl.DefaultFrameGravity = 0.0 end
				isCasting = true
			end
		end
		return rtVal
	end
)

sdk.hook(
	sdk.find_type_definition("app.Job06CastMagic"):get_method("start(via.behaviortree.ActionArg)"),
	function (args)
		local storage = thread.get_hook_storage()
		storage["this"] = sdk.to_managed_object(args[2])
	end,
	function(rtVal)
		if Config.EnableMod then
			local this = thread.get_hook_storage()["this"]
			if TrulyWizzard.ActionOwnerIsCharacter(this) and isInLevitate then
				if checkIsOnLadder(player) then return rtVal end

				player = TrulyWizzard.getPlayer()
				player:get_TempStatus():call("add(app.Character.TempStatusEnum)", tempStatusEnum["DisabledGravity"])
				player:get_TempStatus():call("add(app.Character.TempStatusEnum)", tempStatusEnum["DisableAutoFallAction"])
				local freeFallCtrl = player:get_FreeFallCtrl()
				if freeFallCtrl then freeFallCtrl.DefaultFrameGravity = 0.0 end
				isCasting = true
			end
		end

		return rtVal
	end
)

sdk.hook(
	sdk.find_type_definition("app.EndLevitateAction"):get_method("start(via.behaviortree.ActionArg)"),
	function (args)
		if Config.EnableMod then
			local this = sdk.to_managed_object(args[2])
			if TrulyWizzard.ActionOwnerIsCharacter(this) then
				if not isCasting then
					isInLevitate = false
					player = TrulyWizzard.getPlayer()
					local freeFallCtrl = player:get_FreeFallCtrl()
					if freeFallCtrl then
						freeFallCtrl.DefaultFrameGravity = 0.003
						freeFallCtrl:set_IsActive(true)
						freeFallCtrl:set_IsRise(false)
					end
					
					player:get_TempStatus():call("add(app.Character.TempStatusEnum)", tempStatusEnum["DisableAutoFallAction"])
				end
				
				local human = player:get_Human()
				local humanCommonActionCtrl = human:get_HumanCommonActionCtrl()
				
				humanCommonActionCtrl['<IsEnableLevitate>k__BackingField'] = true
			end
		end
	end,
	nil
)

sdk.hook(
	sdk.find_type_definition("app.LevitateAction"):get_method("start(via.behaviortree.ActionArg)"),
	function (args)
		if Config.EnableMod then
			local this = sdk.to_managed_object(args[2])
			if TrulyWizzard.ActionOwnerIsCharacter(this) then
				if checkIsOnLadder(TrulyWizzard.getPlayer()) then return end
				isInLevitate = true
				local storage = thread.get_hook_storage()
				storage["this"] = this
			end
		end
	end,
	function (rtVal)
		if Config.EnableMod then
			local this = thread.get_hook_storage()["this"]
			if this ~= nil and TrulyWizzard.ActionOwnerIsCharacter(this) then
				local human = this.Human
				local levitateCtrl = human:get_LevitateCtrl()
				levitateCtrl.Param.MaxHeight = Config.LevitateParam.MaxHeight
				levitateCtrl.Param.MaxKeepSec = Config.LevitateParam.MaxKeepSec
				levitateCtrl.Param.HorizontalAccel = Config.LevitateParam.HorizontalAcceleration
			end
		end
		return rtVal
	end
)

sdk.hook(
	sdk.find_type_definition("app.LevitateAction"):get_method("update(via.behaviortree.ActionArg)"),
	function (args)
		if Config.EnableMod then
			local this = sdk.to_managed_object(args[2])
			if TrulyWizzard.ActionOwnerIsCharacter(this) then
				if checkIsOnLadder(player) then
					isInLevitate = false
					TrulyWizzard.resetStatus()
					TrulyWizzard.resetFreeFallCtrl()
					return
				end
				isInLevitate = true
				
				local human = this.Human
				local levitateCtrl = human:get_LevitateCtrl()
				if human["MoveSpeedTypeValueInternal"] > 0 then
					levitateCtrl.HorizontalSpeed =  human["MoveSpeedTypeValueInternal"] * Config.LevitateParam.KeepLevitateMoveSpeedRate
				end
			end
		end
	end,
	nil
)

sdk.hook(
	sdk.find_type_definition("app.JobMagicLetterInputProcessor") and sdk.find_type_definition("app.JobMagicLetterInputProcessor"):get_method("processCustomSkill(app.HumanCustomSkillID, System.UInt64, app.LockOnController.Option, System.Boolean, System.Boolean, System.Boolean, app.LocomotionSpeedTypeEnum, System.Boolean)") or sdk.find_type_definition("app.JobMagicUserInputProcessor"):get_method("processCustomSkill(app.HumanCustomSkillID, System.UInt64, app.LockOnController.Option, System.Boolean, System.Boolean, System.Boolean, app.LocomotionSpeedTypeEnum, System.Boolean)"),
	function(args)
		local storage = thread.get_hook_storage()
		storage["args"] = args
	end,
	function(rtVal)
		if Config.EnableMod then
			local args = thread.get_hook_storage()["args"]
			local skillID = sdk.to_int64(args[3])
			local isDrawWeapon = (sdk.to_int64(args[10]) & 1) == 1

			if isInLevitate and (skillID == skillIdEnum["Job06_MeteorFall"] or skillID == skillIdEnum["Job06_VortexRage"] or skillID == skillIdEnum["Job03_HolyGlare"] ) and isDrawWeapon then
				player = TrulyWizzard.getPlayer()
				if checkIsOnLadder(player) then return rtVal end

				local gameobj = player:get_GameObject()
				local actionMgr = gameobj:call("getComponent(System.Type)", sdk.typeof("app.ActionManager"))
				if skillID == skillIdEnum["Job06_MeteorFall"] then
					actionMgr:requestActionCore(0, "Job06_PrepareMeteorFall", 1)
				elseif skillID == skillIdEnum["Job06_VortexRage"] then
					actionMgr:requestActionCore(0, "Job06_PrepareVortexRage", 1)
				elseif skillID == skillIdEnum["Job03_HolyGlare"] then
					actionMgr:requestActionCore(0, "Job03_PrepareHolyGlare", 1)
				end
			end
		end

		return rtVal
	end
)

sdk.hook(
	sdk.find_type_definition("app.Job06PrepareSpell"):get_method("getTimeRatio()"),
	function(args)
		local storage = thread.get_hook_storage()
		storage["this"] = sdk.to_managed_object(args[2])
	end,
	function(rtVal)
		if Config.EnableMod then
			local this = thread.get_hook_storage()["this"]
			if TrulyWizzard.ActionOwnerIsCharacter(this) then
				if isConcentrate then
					return sdk.float_to_ptr(Config.ConcentrateRate)
				else
					return rtVal
				end
			end
		end
		return rtVal
	end
)

sdk.hook(
	sdk.find_type_definition("app.Job03PrepareSpell"):get_method("getTimeRatio()"),
	function(args)
		local storage = thread.get_hook_storage()
		storage["this"] = sdk.to_managed_object(args[2])
	end,
	function(rtVal)
		if Config.EnableMod then
			local this = thread.get_hook_storage()["this"]
			if TrulyWizzard.ActionOwnerIsCharacter(this) then
				if isConcentrate then
					return sdk.float_to_ptr(Config.ConcentrateRate)
				else
					return rtVal
				end
			end
		end
		return rtVal
	end
)

re.on_frame(function ()
	if Config.EnableMod then
		if hotkeys.check_hotkey("ConcentrateKey", false, true) and isInLevitate and not isCasting then
			isConcentrate = true
		end

		if hotkeys.chk_up("ConcentrateKey") then
			isConcentrate = false
		end
	end
end)

--========================================================--
-- LateUpdateBehavior
--========================================================--
re.on_application_entry("LateUpdateBehavior", function()
	if Config.EnableMod then
		player = TrulyWizzard.getPlayer()
		if player ~= nil then
			
			local isLadderActive = checkIsOnLadder(player)

			-- Дополнительный рубеж по текстовым нодам
			if not isLadderActive then
				local nodeName0, _ = TrulyWizzard.getCurNodeNameAndFrame(0)
				local nodeName1, _ = TrulyWizzard.getCurNodeNameAndFrame(1)
				if nodeName0 ~= "" or nodeName1 ~= "" then
					local nameL = string.lower(nodeName0 .. " " .. nodeName1)
					if string.find(nameL, "ladder") or string.find(nameL, "climb") or string.find(nameL, "mount") or string.find(nameL, "ladd") then
						isLadderActive = true
					end
				end
			end

			-- Если мы коснулись лестницы — принудительно возвращаем стандартную игровую гравитацию
			if isLadderActive then
				if isInLevitate or isCasting then
					isInLevitate = false
					isCasting = false
					isConcentrate = false
					
					local freeFallCtrl = player:get_FreeFallCtrl()
					if freeFallCtrl then
						freeFallCtrl.DefaultFrameGravity = 0.003
						freeFallCtrl:set_IsActive(true)
						freeFallCtrl:set_IsRise(false)
						
						local velocity = freeFallCtrl:get_field("Velocity") or freeFallCtrl:call("get_Velocity")
						if velocity then velocity.y = 0.0 end
					end
					
					local tempStat = player:get_TempStatus() or player:call("get_TempStatus")
					if tempStat then
						tempStat:call("remove(app.Character.TempStatusEnum)", tempStatusEnum["DisabledGravity"])
						tempStat:call("remove(app.Character.TempStatusEnum)", tempStatusEnum["DisableAutoFallAction"])
					end
				end
				return 
			end

			local staminaMgr = player:get_StaminaManager()
			if staminaMgr ~= nil then
				local remainStamina = staminaMgr:get_RemainingAmount()
				if isInLevitate and remainStamina <= 0 then
					isInLevitate = false
					local gameobj = player:get_GameObject()
					local actionMgr = gameobj:call("getComponent(System.Type)", sdk.typeof("app.ActionManager"))
					actionMgr:requestActionCore(0, "JobMagicUser_EndLevitate", 0)
					TrulyWizzard.resetFreeFallCtrl()
					TrulyWizzard.resetStatus()
				end
			end
		end

		if isInLevitate and isCasting then
			local nodeName0, curFrame0 = TrulyWizzard.getCurNodeNameAndFrame(0)
			local nodeName1, curFrame1 = TrulyWizzard.getCurNodeNameAndFrame(1)

			local isCastInMeteorFall = isCasting and string.find(nodeName0, "MeteorFall") 
			if (string.find(nodeName0, "Cast") == nil and string.find(nodeName1, "Cast") == nil) or (isCastInMeteorFall and curFrame0 >= 90) then
				if notCastingTimer == nil then
					notCastingTimer = os.clock()
				end
				local currentTime = os.clock()
				if currentTime - notCastingTimer > 0.5 and player ~= nil then
					local human = player:get_Human()
					local humanCommonActionCtrl = human:get_HumanCommonActionCtrl()
					humanCommonActionCtrl['<IsEnableLevitate>k__BackingField'] = true
					TrulyWizzard.RequestKeepLevitate()
					isCasting = false
					local freeFallCtrl = player:get_FreeFallCtrl()
					if freeFallCtrl then freeFallCtrl.DefaultFrameGravity = 0.003 end
					notCastingTimer = nil
				end
			end
		end
	end
end)

sdk.hook(
	sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType(app.MainFlowManager.SceneType, app.GuiDefine.GuiType)"),
	nil,
	function(rtVal)
		if Config.EnableMod then
			TrulyWizzard.SetLockOnRangeParameters(Config.MagicSkillLockOnRangeRate)
		end
		return rtVal
	end
)

--========================================================--
-- Окно настроек REFramework GUI (Полная русская локализация)
--========================================================--
re.on_draw_ui(function()
	if imgui.tree_node("Настройки чародея (TrulyWizzard)") then
		local changed = false
		local MaxHeightChanged = false
		local MaxKeepSecChanged = false
		local HorizontalAccelerationChanged = false
		local KeepLevitateMoveSpeedRateChanged = false
		local MagicSkillLockOnRangeRateChanged = false
		local ConcentrateKeyChanged = false
		local ConcentrateRateChanged = false

		changed, Config.EnableMod = imgui.checkbox("Включить модификацию", Config.EnableMod)
		
		imgui.separator()
		imgui.text("Управление концентрацией (Ускорение заклинаний):")
		ConcentrateKeyChanged = hotkeys.hotkey_setter("ConcentrateKey", false, "Клавиша концентрации в левитации")
		ConcentrateRateChanged, Config.ConcentrateRate = imgui.drag_float("Скорость концентрации в левитации", Config.ConcentrateRate, 0.01, 2.75, 5)
		
		imgui.separator()
		imgui.text("Параметры парения / левитации:")
		MaxHeightChanged, Config.LevitateParam.MaxHeight = imgui.drag_float("Максимальная высота парения", Config.LevitateParam.MaxHeight, 0.1, 2, 100)
		MaxKeepSecChanged, Config.LevitateParam.MaxKeepSec = imgui.drag_float("Макс. время удержания левитации (сек)", Config.LevitateParam.MaxKeepSec, 0.1, 2.8, 60)
		HorizontalAccelerationChanged, Config.LevitateParam.HorizontalAcceleration = imgui.drag_float("Горизонтальное ускорение", Config.LevitateParam.HorizontalAcceleration, 0.1, 3, 100)
		KeepLevitateMoveSpeedRateChanged, Config.LevitateParam.KeepLevitateMoveSpeedRate = imgui.drag_float("Множитель скорости движения в левитации", Config.LevitateParam.KeepLevitateMoveSpeedRate, 0.1, 1, 5)
		
		imgui.separator()
		imgui.text("Дальность захвата целей:")
		MagicSkillLockOnRangeRateChanged, Config.MagicSkillLockOnRangeRate = imgui.drag_float("Множитель дальности захвата магии", Config.MagicSkillLockOnRangeRate, 0.1, 1, 4)

		if not Config.EnableMod then
			TrulyWizzard.resetFreeFallCtrl()
			TrulyWizzard.resetLockRange()
			TrulyWizzard.resetStatus()
		end

		if changed or MaxHeightChanged or MaxKeepSecChanged or HorizontalAccelerationChanged or KeepLevitateMoveSpeedRateChanged or MagicSkillLockOnRangeRateChanged or ConcentrateKeyChanged or ConcentrateRateChanged then
			hotkeys.update_hotkey_table(Config.Hotkeys)
			TrulyWizzard.saveConfig() 
		end

		imgui.tree_pop()
	end
end)
local printScriptReset = json.load_file("NickCore/ScriptReset.json")
if printScriptReset == nil then
	printScriptReset = true
end
json.dump_file("_NickCore/ScriptReset.json",printScriptReset)

if printScriptReset then
	local appType = sdk.find_type_definition("via.Application")
	local getElapsedSecond = appType:get_method("get_UpTimeSecond")

	print("----------------")
	print("SCRIPT RESET")
	print("Elapsed seconds",math.floor(getElapsedSecond:call(nil)))
	print("----------------")
end

local files = require("_NickCore/Files")
local dataFiles = fs.glob(".*")
for _,file in ipairs(dataFiles) do
	table.insert(files,file)
end

require("_NickCore/Installed")
require("_NickCore/Hooks")

local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")

local CharacterManager = sdk.get_managed_singleton("app.CharacterManager")
local GuiManager = sdk.get_managed_singleton("app.GuiManager")
local ItemManager = sdk.get_managed_singleton('app.ItemManager')

local lastTime = os.clock()
local to_run = {}
re.on_application_entry(
	"LateUpdateBehavior",
	function()
		for key,fn in pairs(fns.run_once) do
			local success = fn()
			if success then
				fns.run_once[key] = nil
			end
		end
	
		if p.player ~= CharacterManager["<ManualPlayer>k__BackingField"] then
			p.player = CharacterManager["<ManualPlayer>k__BackingField"]
			if p.player then
				p.staminaManager = p.player:get_StaminaManager()
				p.transform = p.player:get_Transform()
				p.object = p.player:get_GameObject()
				p.actionManager = p.player:get_ActionManager()
				p.statusConditionCtrl = p.player:get_StatusConditionCtrl()
				p.human = p.player:get_Human()
				p.motion = p.player:get_Motion()
				p.fullLayer = p.motion:getLayer(0)
				p.upperLayer = p.motion:getLayer(1)
				p.input = p.player:get_Input()
				p.job04Controller = p.human:get_Job04ActionCtrl()
				p.job08Controller = p.human:get_Job08ActionCtrl()
				p.job07Controller = p.human:get_Job07ActionCtrl()
				p.holyGlareEnchanter = p.human:get_HolyGlareEnchanter()
				p.jobContext = p.human["<JobContext>k__BackingField"]
				p.skillContext = p.human["<SkillContext>k__BackingField"]
				p.abilityContext = p.human["<AbilityContext>k__BackingField"]
				p.lockOnCtrl = CharacterManager:get_ManualPlayerPlayer():get_LockOnCtrl()
				p.jobParams = CharacterManager["<HumanParam>k__BackingField"].JobParam
				p.staminaParams = CharacterManager["<HumanParam>k__BackingField"].StaminaParam
				p.hitController = p.player:get_Hit()
				p.track = p.human.Track
				p.workRate = p.player.WorkRate
				p.zealValue = CharacterManager["<HumanParam>k__BackingField"].AbilityParam.JobAbilityParameters[9].Abilities[0].Value
				local params = CharacterManager["<HumanParam>k__BackingField"].ActionParam.BodyScaleActionParam.RateAttackParam
				p.bodyScaleDamage = {
					[0] = params.RateAttackXS,
					[1] = params.RateAttackS,
					[2] = params.RateAttackM,
					[3] = params.RateAttackL,
					[4] = params.RateAttackXL,
				}
			end
		end
		
		if p.player == nil then return end
		if not p.player:get_Valid() then return end
		
		p.deltaTime = os.clock() - lastTime
		lastTime = os.clock()
		
		p.isPaused = GuiManager:isPausedGUI()
		
		if p.isPaused then
			p.deltaTime = 0
			return
		end
	
		p.gameTime = p.gameTime + p.deltaTime
		p.job = p.jobContext.CurrentJob
		p.weaponJob = p.player.WeaponJob
		p.skillState = p.human["<CustomSkillState>k__BackingField"]
		p.fullNode = p.actionManager.CurrentActionList[0].Name
		p.upperNode = p.actionManager.CurrentActionList[1].Name
		
		-- Motion data is just too important not to have
		p.frame = p.fullLayer:get_Frame()
		p.upperFrame = p.upperLayer:get_Frame()

		p.bankID = p.fullLayer:get_MotionBankID()
		p.motionID = p.fullLayer:get_MotionID()
	
		p.upperBankID = p.upperLayer:get_MotionBankID()
		p.upperMotionID = p.upperLayer:get_MotionID()
		
		p.isGround = p.player:get_IsGround()
		
		-- local weapon = ItemManager:getEquipData(2891076981).Data.Equips[0]._ItemData -- Calling this every frame isn't ideal
		-- p.weaponID = weapon and weapon:get_ItemId()
		p.position = p.transform:get_Position() -- Calling this every frame isn't idea. Look into this in the future

		for key, fn in pairs(fns.on_frame) do
			to_run[key] = fn
		end

		for key, fn in pairs(to_run) do
			if fns.on_frame[key] == fn then
				fn()
			end
			to_run[key] = nil
		end
		
		p.inputSkill = 0
	end
)

re.on_application_entry(
	"UpdateBehavior",
	function()
		if p.player == nil then return end
		if not p.player:get_Valid() then return end
		
		if p.isPaused then
			return
		end

		for _,fn in pairs(fns.on_update_behavior) do
			fn()
		end
	end
)
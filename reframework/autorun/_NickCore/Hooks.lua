local p = require("_NickCore/Properties")
local fns = require("_NickCore/Functions")

local function get_component(object, name)
	if not object or not object:get_Valid() then return end
	object = object.get_GameObject and object:get_GameObject() or object
	return object:call("getComponent(System.Type)", sdk.typeof(name))
end

-- Going through the attack/damage hit controller is a bit faster, but doesn't give the correct attacker in some cases
local function get_attacker(damageInfo)
	if not damageInfo then return end
	local go = damageInfo["<AttackOwnerObject>k__BackingField"]
	return get_component(go,"app.Character")
end

local function get_receiver(damageInfo)
	if not damageInfo then return end
	local go = damageInfo["<DamageGameObject>k__BackingField"]
	return get_component(go,"app.Character")
end


sdk.hook(
	sdk.find_type_definition("app.HumanStaminaController"):get_method("Chara_OnConsumeStaminaHandler(System.Single, app.StaminaParameterBase.Parameter)"),
	function(args)
		local this = sdk.to_managed_object(args[2])
		local owner = this["Chara"]
		if owner ~= p.player then return end
		local human = owner["<Human>k__BackingField"]		
		local skillState = human["<CustomSkillState>k__BackingField"]
		-- For some reason updating the skill state on frame doesn't work for some skills, so we need to update it here as well
		p.skillState = skillState
		local addValue = sdk.to_float(args[3])
		
		for _,fn in pairs(fns.on_pre_consume_stamina) do
			addValue = fn(addValue) or addValue
		end
		
		args[3] = sdk.float_to_ptr(addValue)
	end
)

sdk.hook(
	sdk.find_type_definition("app.ActionManager"):get_method("requestActionCore(app.ActionManager.Priority, System.String, System.UInt32)"),
	function(args)
		if not p.player or not p.player:get_Valid() then return end
		
		local this = sdk.to_managed_object(args[2])
		local owner = this:get_GameObject()
		if not owner:get_Valid() then return end		
		
		local data = {}
		data.character = get_component(owner,"app.Character")
		data.charaID = data.character:get_CharaIDString()
		data.layer = sdk.to_int64(args[5]) & 0xffffffff
		data.priority = sdk.to_int64(args[3]) & 0xffffffff
		data.node = sdk.to_managed_object(args[4]):ToString()
		
		if data.character["<Human>k__BackingField"] and data.character["<Human>k__BackingField"]:isPlayerOrPartyPawn() then
			local motion = data.character["<Motion>k__BackingField"]
			local mlayer = motion:getLayer(data.layer)
			mlayer:set_Speed(1.0)
		end
		
		local skip = false
		for _,fn in pairs(fns.on_pre_action_request) do
			-- Order very much matters for this one
			-- skip = fn(args,data) or skip
			skip = skip or fn(args,data)
		end

		if skip then
			return sdk.PreHookResult.SKIP_ORIGINAL 
		end
	end
)


sdk.hook(
    sdk.find_type_definition("app.StatusConditionCtrl"):get_method("reqStatusConditionApplyCore(app.StatusConditionDef.StatusConditionEnum, app.HitController.DamageInfo, app.StatusConditionDef.RequestInfo, System.Boolean)"),
    function(args)
		local this = sdk.to_managed_object(args[2])
		local character = this.OwnerCharacter
		local status = sdk.to_int64(args[3])
		
		local data = {}
		data.character = character
		data.status = status
		
		local skip = false
		for _,fn in pairs(fns.on_pre_status_apply) do
			skip = fn(args,data) or skip
		end
		if skip then
            return sdk.PreHookResult.SKIP_ORIGINAL 
        end
    end
)

sdk.hook(
	sdk.find_type_definition("app.StatusConditionInfo"):get_method("applyStatusConditionDamage(System.Single, app.HitController.DamageInfo)"), 
	function(args)
		local this = sdk.to_managed_object(args[2])
		local damage = sdk.to_float(args[3])
		local damageInfo = sdk.to_managed_object(args[4])
		
		local attacker = get_attacker(damageInfo)
		if attacker ~= p.player then return end
		
		local data = {}
		
		local attackHitController = damageInfo["<AttackHitController>k__BackingField"]
		local shell = attackHitController and attackHitController["<CachedShell>k__BackingField"]
		local requestID = shell and shell["<RequestId>k__BackingField"]

		data.requestID = requestID
		data.shellHash = shell and shell["<ShellParamId>k__BackingField"]
		data.damage = damage
		
		local skip = false
		for _,fn in pairs(fns.on_pre_status_damage) do
			skip = fn(args,data) or skip
		end
		
		if skip then
            return sdk.PreHookResult.SKIP_ORIGINAL 
        end
	end
)

-- Expensive hook, but necessary
sdk.hook(
	sdk.find_type_definition("via.effect.script.CreatedEffectContainer"):get_method("getParent(System.Int32)"),
	function(args)
		if not p.player or not p.player:get_Valid() then return end
		
		local storage = thread.get_hook_storage()
		local this = sdk.to_managed_object(args[2])
		local owner = this:get_Owner()
		if not owner or not owner:get_Valid() then return end
		local name = owner:get_Name()

		storage.container = this
		storage.owner = owner
		if name == "ShellBase" then
			local shell = get_component(owner,"app.Shell")
			local requestID = shell["<RequestId>k__BackingField"]
			storage.requestID = requestID
			storage.shell = shell
		end
	end,
	function(retval)
		local storage = thread.get_hook_storage()
		if not storage.container then return end
		
		local data = {}
		data.container = storage.container
		data.requestID = storage.requestID
		data.shell = storage.shell
		data.owner = storage.owner
		data.character = data.shell and data.shell["<OwnerCharacter>k__BackingField"] or get_component(data.owner,"app.Character")
		data.shellHash = data.shell and data.shell["<ShellParamId>k__BackingField"]
		data.ID = data.container:getEPVDataElement()._items[0] and data.container:getEPVDataElement()._items[0].ID

		for _,fn in pairs(fns.on_post_create_effect) do
			fn(data)
		end
	
		return retval
	end
)

sdk.hook(
	sdk.find_type_definition("app.Character"):get_method("onDieFromAttack(app.HitController.DamageInfo)"),
	function(args)
		local this = sdk.to_managed_object(args[2])
		for _,fn in pairs(fns.on_pre_die_character) do
			fn(this)
		end
	end
)

sdk.hook(
	sdk.find_type_definition("app.HitController"):get_method("onDestroy()"),
	function(args)
		local this = sdk.to_managed_object(args[2])
		local character = this["<CachedCharacter>k__BackingField"]
		if not character then return end
		for _,fn in pairs(fns.on_pre_destroy_hit) do
			fn(character)
		end
	end
)

sdk.hook(
	sdk.find_type_definition("app.ShellManager"):get_method("requestCreateShell(via.GameObject, via.vec3, via.Quaternion, app.ShellRequest.ShellCreateInfo, app.ShellParamData, app.ShellRequest.EventCreateShellSuccess, app.ShellRequest.EventBeforeShellInstantiate)"),
	function(args)
		local owner = sdk.to_managed_object(args[3])
		if not owner:get_Valid() then return end
		local shellRequest = sdk.to_managed_object(args[6])
		local udata = sdk.to_managed_object(args[7])
		local shellHash = shellRequest.ShellParamIdHash
		
		local shellID
		local items = udata.ShellParams._items
		for i=0,items:get_Count()-1 do
			if items[i]._ShellParamIdHash == shellHash then
				shellID = i
				break
			end
		end
		
		local position = sdk.to_valuetype(args[4],"via.vec3")
		
		local data = {}
		data.owner = owner
		data.shellHash = shellHash
		data.position = position
		data.shellID = shellID
		data.udata = udata
		
		local skip = false
		for _,fn in pairs(fns.on_pre_create_shell) do
			skip = fn(args,data) or skip
		end
		if skip then
			return sdk.PreHookResult.SKIP_ORIGINAL
		end
	end
)

sdk.hook(
	sdk.find_type_definition("app.ShellManager"):get_method("registShell(app.Shell)"),
	function(args)
		local shell = sdk.to_managed_object(args[3])
		for _,fn in pairs(fns.on_pre_regist_shell) do
			fn(shell)
		end
	end
)

sdk.hook(
	sdk.find_type_definition("app.ShellManager"):get_method("unregistShell(app.Shell)"),
	function(args)
		local shell = sdk.to_managed_object(args[3])
		for _,fn in pairs(fns.on_pre_unregist_shell) do
			fn(shell)
		end
	end
)

-- Expensive hook, likely necessary
sdk.hook(
	sdk.find_type_definition("app.Shell"):get_method("checkFinish()"), 
	function(args)
		local storage = thread.get_hook_storage()
		local shell = sdk.to_managed_object(args[2])
		for _,fn in pairs(fns.on_pre_check_finish) do
			fn(shell,storage)
		end
	end,
	function(retval)
		return thread.get_hook_storage().retval or retval
	end
)

sdk.hook(
	sdk.find_type_definition("app.HitController"):get_method("calcDamageValue(app.HitController.DamageInfo)"), 
	function(args)
		local storage = thread.get_hook_storage()
		local damageInfo = sdk.to_managed_object(args[3])
		storage.damageInfo = damageInfo
		local data = {}
		storage.data = data
		
		local receiver = get_receiver(damageInfo)
		if not receiver or receiver:get_IsDead() then return end
		data.attacker = get_attacker(damageInfo)
		data.receiver = receiver
		
		local attackHitController = damageInfo["<AttackHitController>k__BackingField"]
		local shell = attackHitController and attackHitController["<CachedShell>k__BackingField"]
		data.shellHash = shell and shell["<ShellParamId>k__BackingField"]
		data.requestID = shell and shell["<RequestId>k__BackingField"]
		
		for _,fn in pairs(fns.on_pre_calc_damage) do
			fn(damageInfo,data,storage)
		end
	end,
	function(retval)
		local storage = thread.get_hook_storage()
		local damageInfo = storage.damageInfo
		local data = storage.data
		if not data.receiver then return end
		for _,fn in pairs(fns.on_post_calc_damage) do
			fn(damageInfo,data,storage)
		end
	end
)

sdk.hook(
	sdk.find_type_definition("app.ExceptPlayerDamageCalculator"):get_method("calcDamageValueDefence(app.HitController.DamageInfo)"),
	function(args)
		local storage = thread.get_hook_storage()
		local damageInfo = sdk.to_managed_object(args[3])
		storage.damageInfo = damageInfo
		local data = {}
		storage.data = data
		
		local receiver = get_receiver(damageInfo)
		if not receiver or receiver:get_IsDead() then return end
		data.attacker = get_attacker(damageInfo)
		data.receiver = receiver
		
		local attackHitController = damageInfo["<AttackHitController>k__BackingField"]
		local shell = attackHitController and attackHitController["<CachedShell>k__BackingField"]
		data.shellHash = shell and shell["<ShellParamId>k__BackingField"]
		data.requestID = shell and shell["<RequestId>k__BackingField"]
		
		for _,fn in pairs(fns.on_pre_calc_damage_defence) do
			fn(damageInfo,data,storage)
		end
	end
)

sdk.hook(
	sdk.find_type_definition("app.HitController"):get_method("calcRegionDamageRate(app.HitController.DamageInfo)"), 
	function(args)
		local storage = thread.get_hook_storage()
		local damageInfo = sdk.to_managed_object(args[3])
		storage.damageInfo = damageInfo
		local data = {}
		storage.data = data
		
		local receiver = get_receiver(damageInfo)
		if not receiver or receiver:get_IsDead() then return end
		data.attacker = get_attacker(damageInfo)
		data.receiver = receiver
		
		local attackHitController = damageInfo["<AttackHitController>k__BackingField"]
		local shell = attackHitController and attackHitController["<CachedShell>k__BackingField"]
		data.shellHash = shell and shell["<ShellParamId>k__BackingField"]
		data.requestID = shell and shell["<RequestId>k__BackingField"]
		
		for _,fn in pairs(fns.on_pre_calc_damage_rate) do
			fn(damageInfo,data,storage)
		end
	end,
	function(retval)
		local storage = thread.get_hook_storage()
		local damageInfo = storage.damageInfo
		local data = storage.data
		if not data.receiver then return end
		for _,fn in pairs(fns.on_post_calc_damage_rate) do
			fn(damageInfo,data,storage)
		end
	end
)

sdk.hook(
	sdk.find_type_definition("app.HitController"):get_method("calcDamageReaction(app.HitController.DamageInfo)"), 
	function(args)
		local storage = thread.get_hook_storage()
		local damageInfo = sdk.to_managed_object(args[3])
		storage.damageInfo = damageInfo
		local data = {}
		storage.data = data
		
		local receiver = get_receiver(damageInfo)
		if not receiver or receiver:get_IsDead() then return end
		data.attacker = get_attacker(damageInfo)
		data.receiver = receiver
		
		local attackHitController = damageInfo["<AttackHitController>k__BackingField"]
		local shell = attackHitController and attackHitController["<CachedShell>k__BackingField"]
		data.shellHash = shell and shell["<ShellParamId>k__BackingField"]
		data.requestID = shell and shell["<RequestId>k__BackingField"]
		
		for _,fn in pairs(fns.on_pre_calc_damage_reaction) do
			fn(damageInfo,data,storage)
		end
	end,
	function(retval)
		local storage = thread.get_hook_storage()
		local damageInfo = storage.damageInfo
		local data = storage.data
		if not data.receiver then return end
		for _,fn in pairs(fns.on_post_calc_damage_reaction) do
			fn(damageInfo,data,storage)
		end
	end
)

sdk.hook(
	sdk.find_type_definition("app.WwiseContainerApp"):get_method("trigger(soundlib.SoundManager.RequestInfo)"),
	function(args)
		local this = sdk.to_managed_object(args[2])
		local data = {}
		
		local go = this:get_GameObject()
		if go:get_Name() == "ShellBase" then
			data.shell =  get_component(go,"app.Shell")
		end
		
		if go ~= p.object and (not data.shell or data.shell["<OwnerCharacter>k__BackingField"] ~= p.player) and go:get_Transform():get_Parent() ~= p.transform then return end
		
		data.app = this
		data.soundRequest = sdk.to_managed_object(args[3])
		data.triggerID = data.soundRequest:get_TriggerId()
		data.requestID = data.shell and data.shell["<RequestId>k__BackingField"] 
		data.shellHash = data.shell and data.shell["<ShellParamId>k__BackingField"]
	
		local skip = false
		for _,fn in pairs(fns.on_pre_trigger_sound) do
			skip = fn(data) or skip
		end
		
		if skip then return sdk.PreHookResult.SKIP_ORIGINAL end
	end
)

sdk.hook(
	sdk.find_type_definition("app.MaterialInterpolationRequestManager"):get_method("requestMaterialMode(System.UInt32, app.MaterialInterpolationRequestManager.RequestListCategory, System.Int32, System.Int32)"),
	function(args)
		local this = sdk.to_managed_object(args[2])
		if this:get_GameObject() ~= p.object then return end

		local data = {}
		data.this = this
		data.mode = sdk.to_int64(args[3])
		data.category = sdk.to_int64(args[4])
		
		local skip = false
		for _,fn in pairs(fns.on_pre_request_material) do
			skip = fn(data) or skip
		end
		
		if skip then return sdk.PreHookResult.SKIP_ORIGINAL end
	end
)

-- Highly specific hooks
sdk.hook(
	sdk.find_type_definition("app.Job08ShellAdditionalFlameLance"):get_method("updateMoveVector()"), 
	function(args)
		local skip = false
		for _,fn in pairs(fns.on_pre_move_flamelance) do
			skip = fn(args) or skip
		end

		if skip then return sdk.PreHookResult.SKIP_ORIGINAL end
	end
)

sdk.hook(
	sdk.find_type_definition("app.LocomotionControllerBase"):get_method("setMotion(System.UInt32, System.UInt32, app.tram.TramMatchingResult)"), 
	function(args)
		if not p.player or not p.player:get_Valid() then return end
		
		local this = sdk.to_managed_object(args[2])
		local skip = false
		for _,fn in pairs(fns.on_pre_change_locomotion) do
			skip = fn(this) or skip
		end

		if skip then return sdk.PreHookResult.SKIP_ORIGINAL end
	end
)
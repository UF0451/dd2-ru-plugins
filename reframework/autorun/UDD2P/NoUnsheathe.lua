local config = require("UDD2P/Config")
if not config.NO_UNSHEATHE then return end
local p = require("_NickCore/Properties")

-- Note: we don't care about buffering cause the methods get called constantly from the point you buffer the attack/skill until it's available
local function is_attack_available()
	local track = p.human.Track
	return track.All or track.NormalAttack
end

local function is_skill_available()
	local track = p.human.Track
	return track.All or track.Skill
end

local function force_unsheathe(args)
	if p.human:isSheathedWeaponPlayer() then
		p.human:forceChangeDrawingWeapon(true)
		args[9] = sdk.to_ptr(false)
	end
end

sdk.hook(
	sdk.find_type_definition("app.PlayerInputProcessorDetail"):get_method("processNormalAttack(System.UInt64, app.LockOnController.Option, System.Boolean, System.Boolean, System.Boolean, app.LocomotionSpeedTypeEnum, System.Boolean)"),
	function(args)
		if not p.player then return end
		if not is_attack_available() then return end
		
		-- Exceptions for Archer
		if p.weaponJob == 2 then
			local inputFlag = sdk.to_int64(args[3]) & 0xffffffff
			if inputFlag == 4 or not p.player:get_IsGround() then return end
		end
		
		force_unsheathe(args)
	end
)

-- Skill IDs to job
local skillIDs = {
	[1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1, [9] = 1, [10] = 1, [11] = 1, [12] = 1, [106] = 1,
	[13] = 2, [14] = 2, [15] = 2, [16] = 2, [17] = 2, [18] = 2, [19] = 2, [20] = 2, [21] = 2, [22] = 2, [23] = 2, [109] = 2,
	[24] = 3, [25] = 3, [26] = 3, [27] = 3, [28] = 3, [29] = 3, [30] = 3, [31] = 3, [32] = 3, [33] = 3, [34] = 3, [35] = 3, [36] = 3, [37] = 3,
	[38] = 4, [39] = 4, [40] = 4, [41] = 4, [42] = 4, [43] = 4, [44] = 4, [45] = 4, [46] = 4, [47] = 4, [48] = 4, [49] = 4, [101] = 4,
	[50] = 5, [51] = 5, [52] = 5, [53] = 5, [54] = 5, [55] = 5, [56] = 5, [57] = 5, [58] = 5, [59] = 5, [60] = 5, [61] = 5, [102] = 5,
	[62] = 6, [63] = 6, [64] = 6, [65] = 6, [66] = 6, [67] = 6, [68] = 6, [69] = 6, [103] = 6, [104] = 6, [105] = 6,
	[70] = 7, [71] = 7, [72] = 7, [73] = 7, [74] = 7, [75] = 7, [76] = 7, [77] = 7, [78] = 7, [79] = 7, [107] = 7, [108] = 7,
	[80] = 8, [81] = 8, [82] = 8, [83] = 8, [84] = 8, [85] = 8, [86] = 8, [87] = 8, [88] = 8, [89] = 8, [90] = 8, [91] = 8,
	[92] = 9, [93] = 9, [94] = 9, [95] = 9, [96] = 9, [97] = 9, [98] = 9, [99] = 9, [100] = 9,
}
local mageSorcererSkillIDs = {
	[24] = true,
	[25] = true,
	[26] = true,
	[27] = true,
}

sdk.hook(
	sdk.find_type_definition("app.PlayerInputProcessorDetail"):get_method("processCustomSkill(app.HumanCustomSkillID, System.UInt64, app.LockOnController.Option, System.Boolean, System.Boolean, System.Boolean, app.LocomotionSpeedTypeEnum, System.Boolean)"),
	function(args)
		if not p.player then return end
		local skillID = sdk.to_int64(args[3])
		if skillID == 0 then return end
		if p.weaponJob == 0 then return end
		local expectedJob = skillIDs[skillID]
		if expectedJob == nil or expectedJob == p.weaponJob or (mageSorcererSkillIDs[skillID] and (p.weaponJob == 3 or p.weaponJob == 6)) then
			if not is_skill_available() then return end
			force_unsheathe(args)
		end
	end
)
-- For some reason Tidal Wrath and Windstorm Slash don't go through the previous method
sdk.hook(
	sdk.find_type_definition("app.Job05InputProcessor"):get_method("processCustomSkill(app.HumanCustomSkillID, System.UInt64, app.LockOnController.Option, System.Boolean, System.Boolean, System.Boolean, app.LocomotionSpeedTypeEnum, System.Boolean)"),
	function(args)
		if not p.player then return end
		if p.weaponJob ~= 5 then return end
		if not is_skill_available() then return end
		
		local skillID = sdk.to_int64(args[3])
		if skillID == 55 or skillID == 53 then
			force_unsheathe(args)
		end
	end
)
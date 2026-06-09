local config = require("UDD2P/Config")
if not config.HIDE_WYRMFIRE then return end
local fns = require("_NickCore/Functions")
local p = require("_NickCore/Properties")
local timers = require("_NickCore/Timers")
local h = require("UDD2P/Helpers")

local guidMethod = sdk.find_type_definition("System.Guid"):get_method("NewGuid()")

local equipmentParts = {
	"_HelmObj","_HelmSubObj",
	"_PantsLgObj","_PantsLgSubObj","_PantsWlObj","_PantsWlSubObj",
	"_TopsBdObj","_TopsBdSubObj","_TopsWbObj","_TopsWbSubObj","_TopsAmObj","_TopsAmSubObj","_TopsBtObj","_TopsBtSubObj"
}

local function generate_equipment_list(character)
	local partSwapper = character["<HumanPartSwapper>k__BackingField"]
	if not partSwapper then return nil end
	local equipmentList = {}
	for _,partName in pairs(equipmentParts) do
		table.insert(equipmentList,partSwapper[partName])
	end
	local rightWeapon = character:get_RightWeapon()
	if rightWeapon and rightWeapon:get_Valid() then
		table.insert(equipmentList,rightWeapon:get_GameObject())
	end
	local leftWeapon = character:get_LeftWeapon()
	if leftWeapon and leftWeapon:get_Valid() then
		table.insert(equipmentList,leftWeapon:get_GameObject())
	end
	return equipmentList
end

local function remove_wyrmfire_character(equipmentList)
	if not equipmentList then return end
	for _,obj in pairs(equipmentList) do
		if obj:get_Valid() then
			local mesh = h.get_component(obj,"via.render.Mesh")
			if mesh then
				for materialIndex = 0,mesh:getMaterialsEnableIndicesCount()-1 do
					local varIndex = mesh:getMaterialVariableIndex(materialIndex,0xF969A839)
					mesh:setMaterialFloat(materialIndex,varIndex,0)
				end
			end
		end
	end
end

local function remove_wyrmfire_global()
	local party = h.get_party()
	for i,character in pairs(party) do
		local equipmentList = generate_equipment_list(character)
		remove_wyrmfire_character(equipmentList)
	end
end

local function remove_wyrmfire_hook(retval)
	timers.set_timer(2.0,function()
		remove_wyrmfire_global(false)
	end)
	return retval
end


sdk.hook(sdk.find_type_definition("app.Job10WeaponManager"):get_method("changeToCurrentWeapon"), nil, remove_wyrmfire_hook) -- Warfarer weapon swap
sdk.hook(sdk.find_type_definition("app.GUIMenuBg"):get_method("setActive"), nil, remove_wyrmfire_hook) -- Unpause
sdk.hook(sdk.find_type_definition("app.SaveDataManager"):get_method("saveGameSaveData"), nil, remove_wyrmfire_hook) -- Game save
sdk.hook(sdk.find_type_definition("app.SaveDataManager"):get_method("loadGameSaveData"), nil, remove_wyrmfire_hook) -- Game load
sdk.hook(sdk.find_type_definition("app.Pawn"):get_method(".ctor"), nil, remove_wyrmfire_hook) -- Main pawn spawn
sdk.hook(sdk.find_type_definition("app.ItemManager"):get_method("onHirePawn"), nil, remove_wyrmfire_hook) -- Pawn is hired
sdk.hook(sdk.find_type_definition("app.BootGUIController"):get_method("onDestroy"), nil, remove_wyrmfire_hook) -- Game load
sdk.hook(sdk.find_type_definition("app.ui040101_00"):get_method("onDestroy"),nil,remove_wyrmfire_hook) -- Vocation menu
sdk.hook(
	sdk.find_type_definition("app.Character"):get_method("start"),
	function(args)
		local this = sdk.to_managed_object(args[2])
		if this["<Human>k__BackingField"] and this["<Human>k__BackingField"]:isPlayerOrPartyPawn() then
			timers.set_timer(2.0,function()
				local equipmentList = generate_equipment_list(this)
				remove_wyrmfire_character(equipmentList)
			end)
		end
	end
)

-- Turns off wyrmfire effect in the equipment menu, status menu, etc
sdk.hook(
	sdk.find_type_definition("app.MockupBuilder"):get_method("reqEquipWeapon(app.ItemWeaponParam, System.Boolean)"),
	function(args)
		args[4] = sdk.to_ptr(false)
	end
)
sdk.hook(
	sdk.find_type_definition("app.MockupBuilder"):get_method("reqEquipArmor(app.ItemArmorParam, System.Boolean)"),
	function(args)
		args[4] = sdk.to_ptr(false)
	end
)
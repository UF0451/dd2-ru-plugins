local fs = fs

local jointlist = json.load_file("ExtendedCharacterEditor/Jointlist.json")
local preset_list, preset_names = {}, {}
local config = {}
local bodyscale = {}
local bodypos = {}
local characterEditor

local presets = json.load_file("ExtendedCharacterEditor/Presetslist.json") or {
	arisen = {
		m = 1,
		f = 2
	},
	pawn = {
		m = 3,
		f = 4
	},
	list = {"Default Preset 1", "Default Preset 2", "Default Preset 3", "Default Preset 4"}
}

local preset_amount = 0
for i, filepath in ipairs(fs.glob([[^ExtendedCharacterEditor\\Presets\\.+\.[jJ][sS][oO][nN]$]])) do
	local exists = false
    local preset_name = filepath:sub(33, -6)
	for _,value in pairs(presets.list) do
		if preset_name == value then
			exists = true
		end
	end
	if not exists then 
		table.insert(presets.list, preset_name)
	end
    preset_list[preset_name] = filepath
	preset_amount = preset_amount + 1
end

for _,value in pairs(presets.list) do
    preset_names[#preset_names + 1] = value
end

local function save_preset(preset)
	if preset then
		json.dump_file(preset_list[preset_names[preset]], config[preset])
	else
		for i=1,preset_amount,1 do
			json.dump_file(preset_list[preset_names[i]], config[i])
			end
			json.dump_file("ExtendedCharacterEditor/Presetslist.json", presets)
	end
end

local function load_presets()
	for i=1,preset_amount,1 do
		config[i] = json.load_file(preset_list[preset_names[i]]) or {
			bulge_enabled = true,
			body = {
				arm = {},
				upperbody = {},
				lowerbody = {},
				breasts = {},
				butt = {}
			},
			face = {
				brow = {},
				eyes = {},
				nose = {},
				cheeks = {},
				lips = {},
				chin = {},
				symmetry = {}
			},
			jiggle = {
				jiggle = {}
			}
		}
	end

	function table.copy(chartype)
	  local t2 = {};
	  for k,v in pairs(jointlist) do
		t2[k] = {}
		if type(jointlist[k]) ~= "boolean" then
			for k2,v2 in pairs(jointlist[k]) do
				t2[k][k2] = {}
				if chartype[k2] ~= nil then
					for k3, v3 in pairs(chartype[k2]) do	
						t2[k][k2][k3] = v3
					end
				end
			end
		end
	  end
	  t2.bulge_enabled = true
	  return t2;
	end

	charType_table = {}
	for i = 1,preset_amount,1 do 
		if config[i].arm then 
			config[i] = table.copy(config[i])
		end
		table.insert(charType_table, config[i])
		
	end

	for i = 1,preset_amount,1 do 
		for k,v in pairs(jointlist) do
			if charType_table[i][k] == nil then
				charType_table[i][k] = {}
			end
			if type(jointlist[k]) ~= "boolean" then
				for k2,v2 in pairs(jointlist[k]) do
					if charType_table[i][k][k2] == nil then
						charType_table[i][k][k2] = {}
					end
					for k3, v3 in pairs(jointlist[k][k2]) do
						if charType_table[i][k][k2][k3] == nil then
							charType_table[i][k][k2][k3] = v3
						end
					end
				end
			end
		end
	end
end

load_presets()

for i=1,preset_amount,1 do
	json.dump_file(preset_list[preset_names[i]], config[i])
end

json.dump_file("ExtendedCharacterEditor/Presetslist.json", presets)

re.on_config_save(function()
	for i=1,preset_amount,1 do
    json.dump_file(preset_list[preset_names[i]], config[i])
	end
end)

local player_id = 2891076981
local pawn_id = 2283028347
--local pawn_id = 2482422138 
local player_gender_m = 2776536455
local player_gender_f = 1910070090

local function resource()
	local newres = sdk.create_resource('via.motion.ChainResource', 'character/_kit/body/_common/secondary/body_chain_m.chain')
	if newres then
		newres = newres:add_ref()
		local target = sdk.create_instance('via.motion.ChainResourceHolder', true):add_ref()
		target:call('.ctor()')
		target:write_qword(0x10, newres:get_address())
		return target
	end
	return nil
end
local target = resource()
--print(target)

local function apply_scale_transforms(root_editor, charType, ifpreviewModel)
	local joints = root_editor:get_Joints()
	local edit_scale1
	local edit_scale2
	
	if joints:Get(100):get_Name() ~= "L_Elbow_PointOffset" then
		jnt = "jnt2"
	else
		jnt = "jnt1"
	end
	--print(joints:Get(100):get_Name())
	local values = {}
	local keys = {}
	local amount = 0
	if ifpreviewModel then
		for key,_ in pairs(charType.body) do	
			for value,_ in pairs(charType.body[key]) do
				if value == "L_Hip_Rear_A2" then
				else
					table.insert(values, value)
					table.insert(keys, key)
					amount = amount + 1
				end
			end	
		end
	else
		
		for key,_ in pairs(charType.body) do
			for value,_ in pairs(charType.body[key]) do
				if value == "root" or value == "root2" then
				else
					table.insert(values, value)
					table.insert(keys, key)
					amount = amount + 1
				end
			end
		end
	end
	for i = 1,amount,1 do
		if charType.body[tostring(keys[i])][tostring(values[i])].pos then
			edit_scale1 = Vector3f.new(-charType.body[tostring(keys[i])][tostring(values[i])].pos[1]/3000, 
			-charType.body[tostring(keys[i])][tostring(values[i])].pos[2]/3000, charType.body[tostring(keys[i])][tostring(values[i])].pos[3]/3000)
			edit_scale2 = Vector3f.new(-charType.body[tostring(keys[i])][tostring(values[i])].pos[1]/3000, 
			charType.body[tostring(keys[i])][tostring(values[i])].pos[2]/3000, charType.body[tostring(keys[i])][tostring(values[i])].pos[3]/3000)	
			if joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):get_LocalPosition() == Vector3f.new(-0.045, 
			-0.125, -0.130)then
				print("dhjoixvxoivcxoivcxoi")
			end
			if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] 
				and joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalPosition() ~= Vector3f.new(-0.045, 
			-0.125, -0.130)then
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalPosition(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalPosition())
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):set_LocalPosition(edit_scale2 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):get_LocalPosition())
			else
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalPosition(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalPosition())
			end
		end
		if charType.body[tostring(keys[i])][tostring(values[i])].pos2 then
			edit_scale1 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].pos2[1]/3000, 
			-charType.body[tostring(keys[i])][tostring(values[i])].pos2[2]/3000, -charType.body[tostring(keys[i])][tostring(values[i])].pos2[3]/3000)
			edit_scale2 = Vector3f.new(-charType.body[tostring(keys[i])][tostring(values[i])].pos2[1]/3000, 
			charType.body[tostring(keys[i])][tostring(values[i])].pos2[2]/3000, charType.body[tostring(keys[i])][tostring(values[i])].pos2[3]/3000)			
			if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalPosition(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalPosition())
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):set_LocalPosition(edit_scale2 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):get_LocalPosition())
			else
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalPosition(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalPosition())
			end
		end
		if charType.body[tostring(keys[i])][tostring(values[i])].rot then
			edit_scale1 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].rot[1]/100, 
			charType.body[tostring(keys[i])][tostring(values[i])].rot[2]/100, charType.body[tostring(keys[i])][tostring(values[i])].rot[3]/100)
			edit_scale2 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].rot[1]/100, 
			charType.body[tostring(keys[i])][tostring(values[i])].rot[2]/100, charType.body[tostring(keys[i])][tostring(values[i])].rot[3]/100)
			if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalEulerAngle(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalEulerAngle())
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):set_LocalEulerAngle(edit_scale2 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):get_LocalEulerAngle())
			else
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalEulerAngle(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalEulerAngle())
			end	
		end
		if charType.body[tostring(keys[i])][tostring(values[i])].rot1 then
			edit_scale1 = Vector3f.new(-charType.body[tostring(keys[i])][tostring(values[i])].rot1[1]/100, 
			charType.body[tostring(keys[i])][tostring(values[i])].rot1[2]/100, -charType.body[tostring(keys[i])][tostring(values[i])].rot1[3]/100)
			edit_scale2 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].rot1[1]/100, 
			charType.body[tostring(keys[i])][tostring(values[i])].rot1[2]/100, charType.body[tostring(keys[i])][tostring(values[i])].rot1[3]/100)
			if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalEulerAngle(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalEulerAngle())
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):set_LocalEulerAngle(edit_scale2 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):get_LocalEulerAngle())
			else
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalEulerAngle(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalEulerAngle())
			end	
		end
		if charType.body[tostring(keys[i])][tostring(values[i])].scl then
			edit_scale1 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].scl[1]/100, 
			charType.body[tostring(keys[i])][tostring(values[i])].scl[2]/100, charType.body[tostring(keys[i])][tostring(values[i])].scl[3]/100)
			edit_scale2 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].scl[1]/100, 
			charType.body[tostring(keys[i])][tostring(values[i])].scl[2]/100, charType.body[tostring(keys[i])][tostring(values[i])].scl[3]/100)
			if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalScale(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalScale())
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):set_LocalScale(edit_scale2 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):get_LocalScale())
			elseif values[i] == "root2" then
				joints:Get(0):set_LocalScale(Vector3f.new(edit_scale1.y, 0, edit_scale1.z) + 
				joints:Get(0):get_LocalScale())
			else
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalScale(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalScale())
			end
		end
		if charType.body[tostring(keys[i])][tostring(values[i])].scl4 then
			edit_scale1 = Vector3f.new(-charType.body[tostring(keys[i])][tostring(values[i])].scl4[1]/400, 
			-charType.body[tostring(keys[i])][tostring(values[i])].scl4[2]/400, -charType.body[tostring(keys[i])][tostring(values[i])].scl4[3]/400)
			edit_scale2 = Vector3f.new(-charType.body[tostring(keys[i])][tostring(values[i])].scl4[1]/400, 
			-charType.body[tostring(keys[i])][tostring(values[i])].scl4[2]/400, -charType.body[tostring(keys[i])][tostring(values[i])].scl4[3]/400)
			if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalScale(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalScale())
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):set_LocalScale(edit_scale2 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):get_LocalScale())
			else
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalScale(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalScale())
			end
		end
		if charType.body[tostring(keys[i])][tostring(values[i])].scl1 then
			edit_scale1 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].scl1[1]/100, 
			charType.body[tostring(keys[i])][tostring(values[i])].scl1[2]/100, charType.body[tostring(keys[i])][tostring(values[i])].scl1[3]/100)
			for j = 1, 36, 1 do
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][j]):set_LocalScale(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][j]):get_LocalScale())
			end
		end
		if charType.body[tostring(keys[i])][tostring(values[i])].scl2 then	
			edit_scale1 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].scl2[1]/100, 
			charType.body[tostring(keys[i])][tostring(values[i])].scl2[2]/200, charType.body[tostring(keys[i])][tostring(values[i])].scl2[3]/100)
			for j = 1, 2, 1 do
				joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][j]):set_LocalScale(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][j]):get_LocalScale())
			end
		end
		if charType.body[tostring(keys[i])][tostring(values[i])].pos1 then
			edit_scale1 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].pos1[1]/200, 
			charType.body[tostring(keys[i])][tostring(values[i])].pos1[2], charType.body[tostring(keys[i])][tostring(values[i])].pos1[3]/1000)

			joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalScale(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalScale())
			
		end
		if charType.body[tostring(keys[i])][tostring(values[i])].pos5 then
			edit_scale1 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].pos5[1]/200, 
			charType.body[tostring(keys[i])][tostring(values[i])].pos5[2]/200, charType.body[tostring(keys[i])][tostring(values[i])].pos5[3]/1000)

			joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalPosition(edit_scale1 + joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalPosition())
			
		end
	end
end
local function apply_face_transforms(root_editor, charType)	
	local joints = root_editor:get_Joints()
	local edit_scale1
	local edit_scale2
	
	if joints then
		if joints:Get(100):get_Name() == "L_Brow_Mid_03" then
			jnt = "jnt1"
		elseif joints:Get(100):get_Name() == "L_NosalabialFold_02" then
			jnt = "jnt3"
		elseif joints:Get(100):get_Name() == "L_Nostril" then
			jnt = "jnt4"
		else
			jnt = "jnt2"
		end
		
		local values = {}
		local keys = {}
		local amount = 0
		
		for key,_ in pairs(charType.face) do	
			for value,_ in pairs(charType.face[key]) do
				table.insert(values, value)
				table.insert(keys, key)
				amount = amount + 1
			end	
		end

		for i = 1,amount,1 do
			if charType.face[tostring(keys[i])][tostring(values[i])].pos then
				edit_scale1 = Vector3f.new(charType.face[tostring(keys[i])][tostring(values[i])].pos[1]/3000, 
				charType.face[tostring(keys[i])][tostring(values[i])].pos[2]/3000, charType.face[tostring(keys[i])][tostring(values[i])].pos[3]/3000)
				edit_scale2 = Vector3f.new(-charType.face[tostring(keys[i])][tostring(values[i])].pos[1]/3000, 
				charType.face[tostring(keys[i])][tostring(values[i])].pos[2]/3000, charType.face[tostring(keys[i])][tostring(values[i])].pos[3]/3000)
				
				if charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalPosition(edit_scale1 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalPosition())
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):set_LocalPosition(edit_scale2 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):get_LocalPosition())
				else
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalPosition(edit_scale1 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalPosition())
				end
			end
			if charType.face[tostring(keys[i])][tostring(values[i])].rot then
				edit_scale1 = Vector3f.new(charType.face[tostring(keys[i])][tostring(values[i])].rot[1]/3000, 
				charType.face[tostring(keys[i])][tostring(values[i])].rot[2]/3000, charType.face[tostring(keys[i])][tostring(values[i])].rot[3]/3000)
				edit_scale2 = Vector3f.new(-charType.face[tostring(keys[i])][tostring(values[i])].rot[1]/3000, 
				charType.face[tostring(keys[i])][tostring(values[i])].rot[2]/3000, charType.face[tostring(keys[i])][tostring(values[i])].rot[3]/3000)
				if charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalPosition(edit_scale1 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalPosition())
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):set_LocalPosition(edit_scale2 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):get_LocalPosition())
				else
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalPosition(edit_scale1 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalPosition())
				end
			end
			if charType.face[tostring(keys[i])][tostring(values[i])].rot1 then
				edit_scale1 = Vector3f.new(charType.face[tostring(keys[i])][tostring(values[i])].rot1[1]/100, 
				-charType.face[tostring(keys[i])][tostring(values[i])].rot1[2]/100, -charType.face[tostring(keys[i])][tostring(values[i])].rot1[3]/100)
				edit_scale2 = Vector3f.new(charType.face[tostring(keys[i])][tostring(values[i])].rot1[1]/100, 
				charType.face[tostring(keys[i])][tostring(values[i])].rot1[2]/100, charType.face[tostring(keys[i])][tostring(values[i])].rot1[3]/100)
				if charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalEulerAngle(edit_scale1 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalEulerAngle())
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):set_LocalEulerAngle(edit_scale2 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):get_LocalEulerAngle())
				else
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalEulerAngle(edit_scale1 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalEulerAngle())
				end	
			end
			if charType.face[tostring(keys[i])][tostring(values[i])].scl then
				edit_scale1 = Vector3f.new(charType.face[tostring(keys[i])][tostring(values[i])].scl[1]/100, 
				charType.face[tostring(keys[i])][tostring(values[i])].scl[2]/100, charType.face[tostring(keys[i])][tostring(values[i])].scl[3]/100)
				edit_scale2 = Vector3f.new(-charType.face[tostring(keys[i])][tostring(values[i])].scl[1]/100, 
				charType.face[tostring(keys[i])][tostring(values[i])].scl[2]/100, charType.face[tostring(keys[i])][tostring(values[i])].scl[3]/100)
				if charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalScale(edit_scale1 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalScale())
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):set_LocalScale(edit_scale2 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2]):get_LocalScale())
				else
					joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):set_LocalScale(edit_scale1 + joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1]):get_LocalScale())
				end
			end
		end
	end
end

local function apply_bodyscale(root_editor, charType, body_editor, part_swapper, chain_editor)
	if chain_editor:getGroupCount() == 15 then
		local values = {}
		local amount = 0
		for value,_ in pairs(charType.jiggle.jiggle) do
			table.insert(values, value)
			amount = amount + 1
		end
		for i = 1,amount,1 do
			local chain
			for j = 1, #charType.jiggle.jiggle[tostring(values[i])].group,1 do 
				chain = chain_editor:getGroup(charType.jiggle.jiggle[tostring(values[i])].group[j])
				--local cs = sdk.create_instance("via.motion.ChainCustomSetting")
				--chain:set_CustomSetting(cs)

				chain:set_BlendRate(charType.jiggle.jiggle[tostring(values[i])].str/5)
				chain:set_DampingRate(charType.jiggle.jiggle[tostring(values[i])].damp)
				chain:set_SubReduceDistance(1-charType.jiggle.jiggle[tostring(values[i])].dist)
				chain:set_GravityRate(charType.jiggle.jiggle[tostring(values[i])].grav)
			end
		end	
	end
	if 	body_editor ~= nil then
		local jiggle_table = {0, 0.15, 0.30, 0.45, 0.60, 0.75, 0.9, 1.05, 1.2, -1.2, -2.0, -3.0}
		local joints = root_editor:get_Joints()
		body_editor:set_BustSizeRate(jiggle_table[charType.jiggle.jiggle.breast.str+1])
		bodypos[joints:Get(14)] = Vector3f.new(0, 0, 0)
		bodypos[joints:Get(16)] = Vector3f.new(0, 0, 0)
		part_swapper._UpdateStatusOfSwapObjects = true
	end
	if root_editor ~= nil then
		local joints = root_editor:get_Joints()
		local edit_scale1
		edit_scale1 = Vector3f.new(1+charType.body.upperbody.root.scl[1]/100, 1+charType.body.upperbody.root.scl[2]/100, 
		1+charType.body.upperbody.root.scl[3]/100)
		joint = joints:Get(0)
		bodyscale[joint] = edit_scale1
		edit_scale1 = Vector3f.new(1+charType.body.upperbody.root2.scl[1]/100, 1+charType.body.upperbody.root2.scl[2]/100, 
		1+charType.body.upperbody.root2.scl[3]/100)
		joint = joints:Get(1)
		bodyscale[joint] = edit_scale1
	end
end

re.on_application_entry("PrepareRendering", function()	
	for joint, value in pairs(bodyscale) do
		if joint:get_Valid() then
		joint:call("set_LocalScale", value)	
		end
	end
	for joint, value in pairs(bodypos) do
		if joint:get_Valid() then
		joint:call("set_LocalPosition", value)	
		end
	end
end)

local function pre_EditScales(args)
    thread.get_hook_storage().body_editor = sdk.to_managed_object(args[2])
end

local function post_EditScales(retval)

	local body_editor = thread.get_hook_storage().body_editor
    local game_object = body_editor:get_GameObject()
	
	if characterEditor then	
		if characterEditor[3] == "arisen_m" then
			apply_scale_transforms(characterEditor[1], config[presets.arisen.m], 1)
			apply_face_transforms(characterEditor[2], config[presets.arisen.m])
		elseif characterEditor[3] == "arisen_f" then
			apply_scale_transforms(characterEditor[1], config[presets.arisen.f], 1)
			apply_face_transforms(characterEditor[2], config[presets.arisen.f])
		elseif characterEditor[3] == "pawn_m" then
			apply_scale_transforms(characterEditor[1], config[presets.pawn.m], 1)
			apply_face_transforms(characterEditor[2], config[presets.pawn.m])
		elseif characterEditor[3] == "pawn_f" then
			apply_scale_transforms(characterEditor[1], config[presets.pawn.f], 1)
			apply_face_transforms(characterEditor[2], config[presets.pawn.f])
		end
	elseif game_object:get_Name():find('^MockupModel_ch1') or game_object:get_Name():find('ch1')
		or game_object:get_Name():find('^MockupModel_ch00') or game_object:get_Name():find('ch000') or game_object:get_Name():find('PreviewModel') then
	
		local gender
		local charType
		local character = game_object:call("getComponent(System.Type)", sdk.typeof("app.Character"))
		local character_id
		local root_editor = game_object:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
		local face_editor = root_editor:find("head")
		local ifpreviewModel = false
		
		if character then
			gender = body_editor._PrevGender:call("get_Value")
			character_id = character:get_CharaID()
		else
			local mock_builder = game_object:call("getComponent(System.Type)", sdk.typeof("app.MockupBuilder"))
			local clone_builder = game_object:call("getComponent(System.Type)", sdk.typeof("app.CloneBuilder"))	
			if mock_builder then
				character_id = mock_builder:get_BuildCharaID()
				if (game_object:get_Name() == "MockupModel_ch000000_00") or (game_object:get_Name() == "MockupModel_ch100000_00") then
					gender = body_editor._PrevGender:call("get_Value")
				end    
			elseif clone_builder then
				character_id = clone_builder:get_BuildCharaID()
				gender = body_editor._PrevGender:call("get_Value")
			elseif root_editor:get_Parent() then
				local previewModel = root_editor:get_Parent():get_GameObject():call("getComponent(System.Type)", sdk.typeof("app.HumanEditController"))
				if previewModel then
					gender = body_editor._PrevGender:call("get_Value")
					character_id = previewModel:get_PreviewCharacterID()
					ifpreviewModel = true
				end
			end
		end
		if character_id == player_id then
			if gender == player_gender_m and config[presets.arisen.m].bulge_enabled then
				charType = config[presets.arisen.m]
				apply_scale_transforms(root_editor, charType, ifpreviewModel)
				if face_editor ~= nil then
					apply_face_transforms(face_editor, charType)
				end
			elseif gender == player_gender_f and config[presets.arisen.f].bulge_enabled then
				charType = config[presets.arisen.f]
				apply_scale_transforms(root_editor, charType, ifpreviewModel)
				if face_editor ~= nil then
					apply_face_transforms(face_editor, charType)
				end
			end
		elseif character_id == pawn_id then		
			if gender == player_gender_m and config[presets.pawn.m].bulge_enabled then
				charType = config[presets.pawn.m]
				apply_scale_transforms(root_editor, charType, ifpreviewModel)
				if face_editor ~= nil then
					apply_face_transforms(face_editor, charType)
				end
			elseif gender == player_gender_f and config[presets.pawn.f].bulge_enabled then
				charType = config[presets.pawn.f]
				apply_scale_transforms(root_editor, charType, ifpreviewModel)
				if face_editor ~= nil then
					apply_face_transforms(face_editor, charType)
				end
			end
		end
	end
    return retval
end

local function pre_BodyScale(args)
	thread.get_hook_storage().chain_editor = sdk.to_managed_object(args[1])
	
end

local function post_function(retval)
    local chain_editor = thread.get_hook_storage().chain_editor
	--chain_editor:set_ChainAsset(target)
	--chain_editor:get_Group()
	local game_object = chain_editor:get_GameObject()
	local gender
	local charType
	local character = game_object:call("getComponent(System.Type)", sdk.typeof("app.Character"))
	local character_id
	local root_editor = game_object:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
	local body_editor = game_object:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
	if character and body_editor then
		gender = body_editor._PrevGender:call("get_Value")
        character_id = character:get_CharaID()
	else
        local mock_builder = game_object:call("getComponent(System.Type)", sdk.typeof("app.MockupBuilder"))
		local clone_builder = game_object:call("getComponent(System.Type)", sdk.typeof("app.CloneBuilder"))	
        if mock_builder then
			character_id = mock_builder:get_BuildCharaID()
			
				gender = body_editor._PrevGender:call("get_Value")
			   
		elseif clone_builder then
			character_id = clone_builder:get_BuildCharaID()
			gender = body_editor._PrevGender:call("get_Value")
		end
	end
    if character_id == player_id then
		chain_editor:set_GravityFreezeRate(0.5)
		chain_editor:setGravityCoord(2)
		if gender == player_gender_m and config[presets.arisen.m].bulge_enabled then
			charType = config[presets.arisen.m]
			apply_bodyscale(root_editor, charType, nil, nil, chain_editor)
		elseif gender == player_gender_f and config[presets.arisen.f].bulge_enabled then
			charType = config[presets.arisen.f]
			part_swapper = game_object:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
			apply_bodyscale(root_editor, charType, body_editor, part_swapper, chain_editor)
		end
	elseif character_id == pawn_id then
		chain_editor:set_GravityFreezeRate(0.5)
		chain_editor:setGravityCoord(2)
		if gender == player_gender_m and config[presets.pawn.m].bulge_enabled then
			charType = config[presets.pawn.m]
			apply_bodyscale(root_editor, charType, nil, nil, chain_editor)
		elseif gender == player_gender_f and config[presets.pawn.f].bulge_enabled then
			charType = config[presets.pawn.f]
			part_swapper = game_object:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
			apply_bodyscale(root_editor, charType, body_editor, part_swapper, chain_editor)
		end
	end
	return retval
end

sdk.hook(
	sdk.find_type_definition("via.motion.Chain"):get_method("set_ChainAsset"), 
	function(args)
		local game_object = sdk.to_managed_object(args[2]):get_GameObject()
		if game_object:get_Name():find('^MockupModel_ch1') or game_object:get_Name():find('ch1')
			or game_object:get_Name():find('^MockupModel_ch00') or game_object:get_Name():find('ch000') then
				args[3] = sdk.to_ptr(target)
		end
	end
)

sdk.hook(sdk.find_type_definition("app.BodyEditor"):get_method("setupApplyEditScales"), pre_EditScales, post_EditScales)
sdk.hook(sdk.find_type_definition("via.motion.Chain"):get_method("resetModelCollisionScale"), pre_BodyScale, post_function)	
sdk.hook(sdk.find_type_definition("app.GUICharaEditCtrl"):get_method("applyContext"), 
	function(args)
		thread.get_hook_storage().root_editor = sdk.to_managed_object(args[2])
	end,
	function(retval)
		local game_object = thread.get_hook_storage().root_editor:get_GameObject():call("getComponent(System.Type)", sdk.typeof("via.Transform")):find("PreviewModel"):get_GameObject()
		local root_editor = game_object:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
		local body_editor = game_object:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
		local face_editor = root_editor:find("head")
		gender = body_editor._PrevGender:call("get_Value")
		character_id = root_editor:get_Parent():get_GameObject():call("getComponent(System.Type)", sdk.typeof("app.HumanEditController")):get_PreviewCharacterID()
		local ifpreviewModel = true
		local charType
		
		if character_id == player_id then
			--print("hello")
			if gender == player_gender_m and config[presets.arisen.m].bulge_enabled then
				--print("bye")
				charType = config[presets.arisen.m]
				characterEditor = {root_editor, face_editor, "arisen_m"}
			elseif gender == player_gender_f and config[presets.arisen.f].bulge_enabled then
				characterEditor = {root_editor, face_editor, "arisen_f"}
			end
		elseif character_id == pawn_id then		
			if gender == player_gender_m and config[presets.pawn.m].bulge_enabled then
				characterEditor = {root_editor, face_editor, "pawn_m"}
			elseif gender == player_gender_f and config[presets.pawn.f].bulge_enabled then
				characterEditor = {root_editor, face_editor, "pawn_f"}
			end
		end
	end
)
sdk.hook(sdk.find_type_definition("app.GUICharaEditCtrl"):get_method("onDestroy"), 
	function(args)
		if characterEditor then
			characterEditor = nil
		end
	end
)


local update
re.on_frame(function()
	--local ispaused = sdk.get_managed_singleton("app.GuiManager"):isPausedGUI()
   -- if not ispaused then
	--	return
    --end

	if not update then
		return
	end
	update = false
	if not characterEditor then
		
		local scene = sdk.call_native_func(sdk.get_native_singleton("via.SceneManager"), sdk.find_type_definition("via.SceneManager"), "get_CurrentScene")
		local mockups = sdk.call_native_func(scene, sdk.find_type_definition("via.Scene"), "findComponents(System.Type)", sdk.typeof("app.CloneBuilder"))
		
		if sdk.get_managed_singleton("app.CharacterListHolder"):getCharacter(player_id) then
			local arisen = sdk.get_managed_singleton("app.CharacterListHolder"):getCharacter(player_id):get_GameObject()
			local body_editor = arisen:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
			local chain_editor = arisen:call("getComponent(System.Type)", sdk.typeof("via.motion.Chain"))
			if body_editor._PrevGender:call("get_Value") == player_gender_f then
				local root_editor = arisen:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
				local part_swapper = arisen:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
				apply_bodyscale(root_editor, config[presets.arisen.f], body_editor, part_swapper, chain_editor)
				part_swapper._UpdateStatusOfSwapObjects = true
			else
				apply_bodyscale(nil, config[presets.arisen.m], nil, nil, chain_editor)
			end
		end
		
		if sdk.get_managed_singleton("app.CharacterListHolder"):getCharacter(pawn_id) then
			local pawn = sdk.get_managed_singleton("app.CharacterListHolder"):getCharacter(pawn_id):get_GameObject()
			local body_editor = pawn:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
			local chain_editor = pawn:call("getComponent(System.Type)", sdk.typeof("via.motion.Chain"))
			if body_editor._PrevGender:call("get_Value") == player_gender_f then
				local root_editor = pawn:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
				local part_swapper = pawn:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
				apply_bodyscale(root_editor, config[presets.pawn.f], body_editor, part_swapper, chain_editor)
				part_swapper._UpdateStatusOfSwapObjects = true
			else
				apply_bodyscale(nil, config[presets.pawn.m], nil, nil, chain_editor)
			end
		end
		
		if mockups ~= nil then
			for i = 0, mockups:get_size() - 1  do
				if (mockups[i]:get_BuildCharaID() == player_id) then 
					local mockup_object = mockups[i]:get_GameObject()
					local body_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
					local chain_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("via.motion.Chain"))
					if body_editor._PrevGender:call("get_Value") == player_gender_f then
						local root_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
						local part_swapper = mockup_object:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
						apply_bodyscale(root_editor, config[presets.arisen.f], body_editor, part_swapper, chain_editor)
						part_swapper._UpdateStatusOfSwapObjects = true
					else
						apply_bodyscale(nil, config[presets.arisen.m], nil, nil, chain_editor)
					end

				elseif (mockups[i]:get_BuildCharaID() == pawn_id) then 
					local mockup_object = mockups[i]:get_GameObject()
					local body_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
					local chain_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("via.motion.Chain"))
					if body_editor._PrevGender:call("get_Value") == player_gender_f then
						local root_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
						local part_swapper = mockup_object:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
						apply_bodyscale(root_editor, config[presets.pawn.f], body_editor, part_swapper, chain_editor)
						part_swapper._UpdateStatusOfSwapObjects = true
					else
						apply_bodyscale(nil, config[presets.pawn.m], nil, nil, chain_editor)
					end
				end		
			end
		end
	end
end)

local function vec3_to_array(vec3) 
return {vec3.x, vec3.y, vec3.z} 
end

local function array_to_vec3(array) 
return Vector3f.new(array[1], array[2], array[3]) 
end

local function armsUI (character)
	changed, vec3 = imgui.drag_float("Масштаб руки", character.R_Arm_Upper.scl[1], 1, -100, 100)
	update = update or changed
	character.R_Arm_Upper.scl = {vec3, 0, 0}
	character.R_Arm_Lower.scl = {vec3, 0, 0}
	character.R_Arm_Lower_Twist_0.scl = {vec3, 0, 0}
	character.R_Arm_Lower_Twist_1.scl = {vec3, 0, 0}
	character.R_Arm_Lower_Twist_2.scl = {vec3, 0, 0}
	character.R_Arm_Upper_Twist_0.scl = {vec3, 0, 0}
	character.R_Arm_Upper_Twist_1.scl = {vec3, 0, 0}
	character.R_Arm_Upper_Twist_2.scl = {vec3, 0, 0}
	character.R_Arm_Edit_Triceps_A.scl = {vec3, 0, 0}
	character.R_Arm_Edit_Biceps_A.scl = {vec3, 0, 0}
	
	changed, vec3 = imgui.drag_float3("Масштаб плеча", array_to_vec3(character.clavicle.scl), 1, -100, 100)
	update = update or changed
	character.clavicle.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб мышц плеча", array_to_vec3(character.shoulders.scl), 1, -100, 100)
	update = update or changed
	character.shoulders.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб верхней части руки", array_to_vec3(character.upper_arm.scl), 1, -100, 100)
	update = update or changed
	character.upper_arm.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб трицепса", array_to_vec3(character.triceps.scl), 1, -100, 100)
	update = update or changed
	character.triceps.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб бицепса", array_to_vec3(character.biceps.scl), 1, -100, 100)
	update = update or changed
	character.biceps.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб верхней части предплечья", array_to_vec3(character.forearm_upper.scl), 1, -100, 100)
	update = update or changed
	character.forearm_upper.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб нижней части предплечья", array_to_vec3(character.forearm_lower.scl), 1, -100, 100)
	update = update or changed
	character.forearm_lower.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб кистей", array_to_vec3(character.hands.scl1), 1, -100, 100)
	update = update or changed
	character.hands.scl1 = {vec3.x, vec3.y, vec3.z}
	
	
end

local function bodyUI (character)
	changed, vec3 = imgui.drag_float3("Масштаб верхней части шеи", array_to_vec3(character.neck_upper.scl), 1, -100, 100)
	update = update or changed
	character.neck_upper.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб нижней части шеи", array_to_vec3(character.neck_lower.scl), 1, -100, 100)
	update = update or changed
	character.neck_lower.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб трапеций", array_to_vec3(character.traps_upper.scl), 1, -100, 100)
	update = update or changed
	character.traps_upper.scl = vec3_to_array(vec3)
	character.traps_lower.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб верхней части груди/спины", array_to_vec3(character.upper_back.scl), 1, -100, 100)
	update = update or changed
	character.upper_back.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб средней части груди/спины", array_to_vec3(character.mid_back.scl), 1, -100, 100)
	update = update or changed
	character.mid_back.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб нижней части спины", array_to_vec3(character.lower_back.scl), 1, -100, 100)
	update = update or changed
	character.lower_back.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб нижней части спины 2", array_to_vec3(character.lower_back2.scl), 1, -100, 100)
	update = update or changed
	character.lower_back2.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб зубчатых мышц", array_to_vec3(character.serratus.scl), 1, -100, 100)
	update = update or changed
	character.serratus.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Подкожный масштаб", array_to_vec3(character.subcutaneous.scl), 1, -100, 100)
	update = update or changed
	character.subcutaneous.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб широчайших мышц", array_to_vec3(character.lats.scl), 1, -100, 100)
	update = update or changed
	character.lats.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб живота", array_to_vec3(character.belly.scl), 1, -100, 100)
	update = update or changed
	character.belly.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Масштаб живота 2", array_to_vec3(character.belly2.scl), 1, -100, 100)
	update = update or changed
	character.belly2.scl = vec3_to_array(vec3)
	character.belly3.scl = vec3_to_array(vec3)
end

local function legsUI (character)
	changed, vec = imgui.drag_float("Масштаб ног", character.traps_upper.scl4[1], 1, -100, 100)
	update = update or changed
	character.hip1.pos5 = {0, vec/2.5, 0}
	character.leg_lower.scl4 = {-vec, 0, 0}
	character.lower_twist_1.scl4 = {-vec, 0, 0}
	character.legs_scale2.scl4 = {-vec, 0, 0}
	character.Leg_Upper_Twist_1.scl4 = {-vec, 0, 0}
	character.Leg_Upper_Twist_0.scl4 = {-vec, 0, 0}
	character.lats.scl4 = {1.5*vec, 0, 0}
	character.subcutaneous.scl4 = {-vec, 0, 0}
	character.calves2.scl4 = {-vec, 0, 0}
	character.traps_upper.scl4 = {vec, 0, 0}
	character.traps_lower.scl4 = {vec, 0, 0}
	character.Spine_0.scl4 = {1.45*vec, 0, 0}
	character.Spine_1.scl4 = {1.45*vec, 0, 0}
	character.Spine_2.scl4 = {1.45*vec, 0, 0}
	character.belly2.scl4 = {1.5*vec, 0, 0}
	character.belly.scl4 = {1.5*vec, 0, 0}
	
	changed, vec3 = imgui.drag_float("Ширина бёдер", character.hipwidth.scl[2], 1, -100, 100)
	update = update or changed
	character.hipwidth.scl = {0, vec3, 0}
	
	changed, vec3 = imgui.drag_float3("Масштаб верхней части бедра", array_to_vec3(character.upper_thigh.scl), 1, -100, 100)
	update = update or changed
	character.upper_thigh.scl = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Масштаб нижней части бедра", array_to_vec3(character.lower_thigh.scl), 1, -100, 100)
	update = update or changed
	character.lower_thigh.scl = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Масштаб икр", array_to_vec3(character.calves.scl), 1, -100, 100)
	update = update or changed
	character.calves.scl = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Масштаб ступней", array_to_vec3(character.feet1.scl2), 1, -100, 100)
	update = update or changed
	character.feet1.scl2 = {vec3.x, vec3.y, vec3.z}
	character.feet2.scl2 = {vec3.x/30, vec3.y, vec3.z/2.5}
	character.feet3.scl2 = {vec3.x, vec3.y, vec3.z/1.5}
	character.feetl.pos1 = {-vec3.x, 0, -vec3.z}
	character.feetr.pos1 = {-vec3.x, 0, -vec3.z}
end


local function breastsUI (character)
	changed, vec3 = imgui.drag_float3("Масштаб", array_to_vec3(character.breast.scl), 1, -100, 100)
	update = update or changed
	character.breast.scl = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Поворот", array_to_vec3(character.breast.rot), 1, -100, 100)
	update = update or changed
	character.breast.rot = vec3_to_array(vec3)
	changed, vec3 = imgui.drag_float3("Положение", array_to_vec3(character.breast.pos), 1, -100, 100)
	update = update or changed
	character.breast.pos = vec3_to_array(vec3)
end

local function buttUI (character)
	changed, vec3 = imgui.drag_float3("Масштаб", array_to_vec3(character._01butt.scl), 1, -100, 100)
	update = update or changed
	character._01butt.scl = {vec3.x, vec3.y, vec3.z}
	changed, vec2 = imgui.drag_float2("Поворот", Vector2f.new(character._01butt.rot[1], character._01butt.rot[3]), 1, -100, 100)
	update = update or changed
	character._01butt.rot = {vec2.x, 0, vec2.y}
	changed, vec3 = imgui.drag_float3("Положение", array_to_vec3(character._01butt.pos), 1, -100, 100)
	update = update or changed
	character._01butt.pos = {vec3.x, vec3.y, vec3.z}
	changed, vec3 = imgui.drag_float3("Нижний масштаб", array_to_vec3(character._02lower_butt.scl), 1, -100, 100)
	update = update or changed
	character._02lower_butt.scl = {vec3.x, vec3.y, vec3.z}
	changed, vec3 = imgui.drag_float3("Нижний поворот", array_to_vec3(character._02lower_butt.rot1), 1, -100, 100)
	update = update or changed
	character._02lower_butt.rot1 = {vec3.x, vec3.y, vec3.z}
	changed, vec3 = imgui.drag_float3("Нижнее положение", array_to_vec3(character._02lower_butt.pos2), 1, -100, 100)
	update = update or changed
	character._02lower_butt.pos2 = {vec3.x, vec3.y, vec3.z}
end

local function headUI (character, upperbody)
	changed, vec3 = imgui.drag_float3("Масштаб головы", array_to_vec3(upperbody.head.scl), 1, -100, 100)
	upperbody.head.scl = vec3_to_array(vec3)
	update = update or changed	
	
	changed, vec3 = imgui.drag_float3("Масштаб лица", array_to_vec3(character.Facialjnt_Face.scl), 1, -100, 100)
	character.Facialjnt_Face.scl = vec3_to_array(vec3)
	update = update or changed	
	
	changed, vec3 = imgui.drag_float3("Верхний лоб", array_to_vec3(character._13C_Brow_Upper.pos), 1, -100, 100)
	update = update or changed
	character._13C_Brow_Upper.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Средний лоб", array_to_vec3(character._14C_Brow_Mid.pos), 1, -100, 100)
	update = update or changed
	character._14C_Brow_Mid.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Верхний висок", array_to_vec3(character._04L_Brow_Upper_04.pos), 1, -100, 100)
	update = update or changed
	character._04L_Brow_Upper_04.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Средний висок", array_to_vec3(character._12L_Brow_Mid_04.pos), 1, -100, 100)
	update = update or changed
	character._12L_Brow_Mid_04.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение лба", array_to_vec3(character._01L_Brow_Upper_01.pos), 1, -100, 100)
	update = update or changed
	character._01L_Brow_Upper_01.pos = {vec3.x, vec3.y, vec3.z}
	character._02L_Brow_Upper_02.pos = {vec3.x, vec3.y, vec3.z}
	character._03L_Brow_Upper_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот лба", array_to_vec3(character._01L_Brow_Upper_01.rot), 1, -100, 100)
	update = update or changed
	character._01L_Brow_Upper_01.rot = {vec3.x, vec3.y, vec3.z}
	character._03L_Brow_Upper_03.rot = {-vec3.x, -vec3.y, -vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение уха", array_to_vec3(character._21L_Ear.pos), 1, -100, 100)
	update = update or changed
	character._21L_Ear.pos = {vec3.x, vec3.y, vec3.z}
	changed, vec3 = imgui.drag_float3("Поворот уха", array_to_vec3(character._21L_Ear.rot1), 1, -100, 100)
	update = update or changed
	character._21L_Ear.rot1 = {vec3.x, vec3.y, vec3.z}
	changed, vec3 = imgui.drag_float3("Масштаб уха", array_to_vec3(character._21L_Ear.scl), 1, -100, 100)
	update = update or changed
	character._21L_Ear.scl = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение завитка уха", array_to_vec3(character._22L_Ear_Helix.pos), 1, -100, 100)
	update = update or changed
	character._22L_Ear_Helix.pos = {vec3.x, vec3.y, vec3.z}
	changed, vec3 = imgui.drag_float3("Поворот завитка уха", array_to_vec3(character._22L_Ear_Helix.rot1), 1, -100, 100)
	update = update or changed
	character._22L_Ear_Helix.rot1 = {vec3.x, vec3.y, vec3.z}
	changed, vec3 = imgui.drag_float3("Масштаб завитка уха", array_to_vec3(character._22L_Ear_Helix.scl), 1, -100, 100)
	update = update or changed
	character._22L_Ear_Helix.scl = {vec3.x, vec3.y, vec3.z}
	
end

local function browUI (character)
	
	changed, vec3 = imgui.drag_float3("Переносица (глабелла)", array_to_vec3(character._15C_Brow_Lower.pos), 1, -100, 100)
	update = update or changed
	character._15C_Brow_Lower.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение середины брови", array_to_vec3(character._09L_Brow_Mid_01.pos), 1, -100, 100)
	update = update or changed
	character._09L_Brow_Mid_01.pos = {vec3.x, vec3.y, vec3.z}
	character._10L_Brow_Mid_02.pos = {vec3.x, vec3.y, vec3.z}
	character._11L_Brow_Mid_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот середины брови", array_to_vec3(character._09L_Brow_Mid_01.rot), 1, -100, 100)
	update = update or changed
	character._09L_Brow_Mid_01.rot = {vec3.x, vec3.y, vec3.z}
	character._11L_Brow_Mid_03.rot = {-vec3.x, -vec3.y, -vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение нижней части брови", array_to_vec3(character._05L_Brow_Lower_01.pos), 1, -100, 100)
	update = update or changed
	character._05L_Brow_Lower_01.pos = {vec3.x, vec3.y, vec3.z}
	character._06L_Brow_Lower_02.pos = {vec3.x, vec3.y, vec3.z}
	character._07L_Brow_Lower_03.pos = {vec3.x, vec3.y, vec3.z}
	character._08L_Brow_Lower_04.pos = {vec3.x, vec3.y, vec3.z}
	character._18L_EyeFat_Upper_01p.pos = {vec3.x, vec3.y, vec3.z}
	character._19L_EyeFat_Upper_02p.pos = {vec3.x, vec3.y, vec3.z}
	character._20L_EyeFat_Upper_03p.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот нижней части брови", array_to_vec3(character._06L_Brow_Lower_02.rot), 1, -100, 100)
	update = update or changed
	character._05L_Brow_Lower_01.rot = {0.1*vec3.x, 0.1*vec3.y, 0.1*vec3.z}
	character._06L_Brow_Lower_02.rot = {vec3.x, vec3.y, vec3.z}
	character._07L_Brow_Lower_03.rot = {0.5 *-vec3.x, 0.5 *-vec3.y, 0.5 *-vec3.z}
	character._08L_Brow_Lower_04.rot = {0.5 *-vec3.x, 0.5 *-vec3.y, 0.5 *-vec3.z}
end

local function eyesUI (character)
	changed, vec3 = imgui.drag_float3("Положение верхнего века", array_to_vec3(character._01L_UpperLid_01.pos), 1, -100, 100)
	update = update or changed
	character._01L_UpperLid_01.pos = {vec3.x, vec3.y, vec3.z}
	character._02L_UpperLid_02.pos = {vec3.x, vec3.y, vec3.z}
	character._03L_UpperLid_03.pos = {vec3.x, vec3.y, vec3.z}
	character._04L_UpperLid_04.pos = {vec3.x, vec3.y, vec3.z}
	character._05L_UpperLid_05.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот верхнего века", array_to_vec3(character._01L_UpperLid_01.rot), 1, -100, 100)
	update = update or changed
	character._01L_UpperLid_01.rot = {vec3.x, vec3.y, vec3.z}
	character._02L_UpperLid_02.rot = {0.5 * vec3.x, 0.5 * vec3.y, 0.5 * vec3.z}
	character._04L_UpperLid_04.rot = {0.5 * -vec3.x, 0.5 * -vec3.y, 0.5 * -vec3.z}
	character._05L_UpperLid_05.rot = {-vec3.x, -vec3.y, -vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение глазного яблока", array_to_vec3(character._21L_Eye.pos), 1, -100, 100)
	update = update or changed
	character._21L_Eye.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение нижнего века", array_to_vec3(character._06L_LowerLid_01.pos), 1, -100, 100)
	update = update or changed
	character._06L_LowerLid_01.pos = {vec3.x, vec3.y, vec3.z}
	character._07L_LowerLid_02.pos = {vec3.x, vec3.y, vec3.z}
	character._08L_LowerLid_03.pos = {vec3.x, vec3.y, vec3.z}
	character._09L_LowerLid_04.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот нижнего века", array_to_vec3(character._06L_LowerLid_01.rot), 1, -100, 100)
	update = update or changed
	character._06L_LowerLid_01.rot = {vec3.x, vec3.y, vec3.z}
	character._07L_LowerLid_02.rot = {0.5 * vec3.x, 0.5 * vec3.y, 0.5 * vec3.z}
	character._08L_LowerLid_03.rot = {0.5 * -vec3.x, 0.5 * -vec3.y, 0.5 * -vec3.z}
	character._09L_LowerLid_04.rot = {-vec3.x, -vec3.y, -vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение верхнего жира глаза", array_to_vec3(character._10L_EyeFat_Upper_01.pos), 1, -100, 100)
	update = update or changed
	character._10L_EyeFat_Upper_01.pos = {vec3.x, vec3.y, vec3.z}
	character._11L_EyeFat_Upper_02.pos = {vec3.x, vec3.y, vec3.z}
	character._12L_EyeFat_Upper_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот верхнего жира глаза", array_to_vec3(character._10L_EyeFat_Upper_01.rot), 1, -100, 100)
	update = update or changed
	character._10L_EyeFat_Upper_01.rot = {vec3.x, vec3.y, vec3.z}
	character._12L_EyeFat_Upper_03.rot = {-vec3.x, -vec3.y, -vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение нижнего жира глаза", array_to_vec3(character._13L_EyeFat_Lower_01.pos), 1, -100, 100)
	update = update or changed
	character._13L_EyeFat_Lower_01.pos = {vec3.x, vec3.y, vec3.z}
	character._14L_EyeFat_Lower_02.pos = {vec3.x, vec3.y, vec3.z}
	character._15L_EyeFat_Lower_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот нижнего жира глаза", array_to_vec3(character._13L_EyeFat_Lower_01.rot), 1, -100, 100)
	update = update or changed
	character._13L_EyeFat_Lower_01.rot = {vec3.x, vec3.y, vec3.z}
	character._15L_EyeFat_Lower_03.rot = {-vec3.x, -vec3.y, -vec3.z}
	
	changed, vec3 = imgui.drag_float3("Eye Outer Corner", array_to_vec3(character._16L_EyeOuter_Corner.pos), 1, -100, 100)
	update = update or changed
	character._16L_EyeOuter_Corner.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Eye Inner Corner", array_to_vec3(character._17L_EyeInner_Corner.pos), 1, -100, 100)
	update = update or changed
	character._17L_EyeInner_Corner.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение складки века", array_to_vec3(character._18L_EyeFold_01.pos), 1, -100, 100)
	update = update or changed
	character._18L_EyeFold_01.pos = {vec3.x, vec3.y, vec3.z}
	character._19L_EyeFold_02.pos = {vec3.x, vec3.y, vec3.z}
	character._20L_EyeFold_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот складки века", array_to_vec3(character._18L_EyeFold_01.rot), 1, -100, 100)
	update = update or changed
	character._18L_EyeFold_01.rot = {vec3.x, vec3.y, vec3.z}
	character._20L_EyeFold_03.rot = {-vec3.x, -vec3.y, -vec3.z}
	
	if imgui.tree_node("Расширенные слайдеры глаз") then
		changed, vec3 = imgui.drag_float3("Верхнее веко 1", array_to_vec3(character.UpperLid_01.pos), 1, -100, 100)
		update = update or changed
		character.UpperLid_01.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Верхнее веко 2", array_to_vec3(character.UpperLid_02.pos), 1, -100, 100)
		update = update or changed
		character.UpperLid_02.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Верхнее веко 3", array_to_vec3(character.UpperLid_03.pos), 1, -100, 100)
		update = update or changed
		character.UpperLid_03.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Верхнее веко 4", array_to_vec3(character.UpperLid_04.pos), 1, -100, 100)
		update = update or changed
		character.UpperLid_04.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Верхнее веко 5", array_to_vec3(character.UpperLid_05.pos), 1, -100, 100)
		update = update or changed
		character.UpperLid_05.pos = {vec3.x, vec3.y, vec3.z}
		
		changed, vec3 = imgui.drag_float3("Нижнее веко 1", array_to_vec3(character.LowerLid_01.pos), 1, -100, 100)
		update = update or changed
		character.LowerLid_01.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Нижнее веко 2", array_to_vec3(character.LowerLid_02.pos), 1, -100, 100)
		update = update or changed
		character.LowerLid_02.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Нижнее веко 3", array_to_vec3(character.LowerLid_03.pos), 1, -100, 100)
		update = update or changed
		character.LowerLid_03.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Нижнее веко 4", array_to_vec3(character.LowerLid_04.pos), 1, -100, 100)
		update = update or changed
		character.LowerLid_04.pos = {vec3.x, vec3.y, vec3.z}
		
		changed, vec3 = imgui.drag_float3("Верхний жир глаза 1", array_to_vec3(character.EyeFat_Upper_01.pos), 1, -100, 100)
		update = update or changed
		character.EyeFat_Upper_01.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Верхний жир глаза 2", array_to_vec3(character.EyeFat_Upper_02.pos), 1, -100, 100)
		update = update or changed
		character.EyeFat_Upper_02.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Верхний жир глаза 3", array_to_vec3(character.EyeFat_Upper_03.pos), 1, -100, 100)
		update = update or changed
		character.EyeFat_Upper_03.pos = {vec3.x, vec3.y, vec3.z}
		
		changed, vec3 = imgui.drag_float3("Нижний жир глаза 1", array_to_vec3(character.EyeFat_Lower_01.pos), 1, -100, 100)
		update = update or changed
		character.EyeFat_Lower_01.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Нижний жир глаза 2", array_to_vec3(character.EyeFat_Lower_02.pos), 1, -100, 100)
		update = update or changed
		character.EyeFat_Lower_02.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Нижний жир глаза 3", array_to_vec3(character.EyeFat_Lower_03.pos), 1, -100, 100)
		update = update or changed
		character.EyeFat_Lower_03.pos = {vec3.x, vec3.y, vec3.z}
		
		changed, vec3 = imgui.drag_float3("Складка века 1", array_to_vec3(character.EyeFold_01.pos), 1, -100, 100)
		update = update or changed
		character.EyeFold_01.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Складка века 2", array_to_vec3(character.EyeFold_02.pos), 1, -100, 100)
		update = update or changed
		character.EyeFold_02.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Складка века 3", array_to_vec3(character.EyeFold_03.pos), 1, -100, 100)
		update = update or changed
		character.EyeFold_03.pos = {vec3.x, vec3.y, vec3.z}
		
		imgui.tree_pop()
	end
end

local function noseUI (character)
	changed, vec3 = imgui.drag_float3("Боковая часть носа 1", array_to_vec3(character._01L_Nose_side.pos), 1, -100, 100)
	update = update or changed
	character._01L_Nose_side.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Боковая часть носа 2", array_to_vec3(character._02L_Nose_Bridge.pos), 1, -100, 100)
	update = update or changed
	character._02L_Nose_Bridge.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Боковая часть носа 3", array_to_vec3(character._03L_NoseBulge_Bridge.pos), 1, -100, 100)
	update = update or changed
	character._03L_NoseBulge_Bridge.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Ноздря 1", array_to_vec3(character._04L_Nose_Corner.pos), 1, -100, 100)
	update = update or changed
	character._04L_Nose_Corner.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Ноздря 2", array_to_vec3(character._05L_Nostril_Corner.pos), 1, -100, 100)
	update = update or changed
	character._05L_Nostril_Corner.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Ноздря 3", array_to_vec3(character._06L_NostrilThickness.pos), 1, -100, 100)
	update = update or changed
	character._06L_NostrilThickness.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Ноздря 4", array_to_vec3(character._07L_Nostril.pos), 1, -100, 100)
	update = update or changed
	character._07L_Nostril.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Спинка носа 1", array_to_vec3(character._08C_NoseBulge_Bridge.pos), 1, -100, 100)
	update = update or changed
	character._08C_NoseBulge_Bridge.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Спинка носа 2", array_to_vec3(character._09C_Nose_Bridge.pos), 1, -100, 100)
	update = update or changed
	character._09C_Nose_Bridge.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Ость носа", array_to_vec3(character._10C_Nose_Spine.pos), 1, -100, 100)
	update = update or changed
	character._10C_Nose_Spine.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Кончик носа", array_to_vec3(character._11C_Nose_Tip.pos), 1, -100, 100)
	update = update or changed
	character._11C_Nose_Tip.pos = {vec3.x, vec3.y, vec3.z}
end

local function cheeksUI (character)
	changed, vec3 = imgui.drag_float3("Cheek 1", array_to_vec3(character._01L_CheekFat_01.pos), 1, -100, 100)
	update = update or changed
	character._01L_CheekFat_01.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Cheek 2", array_to_vec3(character._02L_CheekFat_02.pos), 1, -100, 100)
	update = update or changed
	character._02L_CheekFat_02.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Cheek 3", array_to_vec3(character._03L_CheekFat_03.pos), 1, -100, 100)
	update = update or changed
	character._03L_CheekFat_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Cheek 4", array_to_vec3(character._04L_CheekFat_04.pos), 1, -100, 100)
	update = update or changed
	character._04L_CheekFat_04.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Cheek 5", array_to_vec3(character._05L_CheekFat_05.pos), 1, -100, 100)
	update = update or changed
	character._05L_CheekFat_05.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Cheek 6", array_to_vec3(character._06L_CheekFat_06.pos), 1, -100, 100)
	update = update or changed
	character._06L_CheekFat_06.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Cheek 7", array_to_vec3(character._07L_CheekFat_07.pos), 1, -100, 100)
	update = update or changed
	character._07L_CheekFat_07.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Cheek 8", array_to_vec3(character._08L_CheekFat_08.pos), 1, -100, 100)
	update = update or changed
	character._08L_CheekFat_08.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Cheek 9", array_to_vec3(character._09L_CheekFat_09.pos), 1, -100, 100)
	update = update or changed
	character._09L_CheekFat_09.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Cheek Bone", array_to_vec3(character._10L_CheekBone.pos), 1, -100, 100)
	update = update or changed
	character._10L_CheekBone.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Nosalabia Fold 1", array_to_vec3(character._11L_NosalabiaFold_01.pos), 1, -100, 100)
	update = update or changed
	character._11L_NosalabiaFold_01.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("NosalabialFold 2", array_to_vec3(character._12L_NosalabialFold_02.pos), 1, -100, 100)
	update = update or changed
	character._12L_NosalabialFold_02.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("NosalabialFold 3", array_to_vec3(character._13L_NosalabialFold_03.pos), 1, -100, 100)
	update = update or changed
	character._13L_NosalabialFold_03.pos = {vec3.x, vec3.y, vec3.z}
	
end

local function lipsUI (character)
	changed, vec3 = imgui.drag_float3("Фильтрум", array_to_vec3(character._07L_UpperLip.pos), 1, -100, 100)
	update = update or changed
	character._07L_UpperLip.pos = {vec3.x, vec3.y, vec3.z}
	character._23C_UpperLip.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float("Поворот фильтрума", character._07L_UpperLip.rot1[1], 1, -100, 100)
	update = update or changed
	character._07L_UpperLip.rot1 = {vec3, 0, 0}
	character._23C_UpperLip.rot1 = {vec3, 0, 0}
	
	changed, vec3 = imgui.drag_float3("Масштаб фильтрума", array_to_vec3(character._07L_UpperLip.scl), 1, -100, 100)
	update = update or changed
	character._07L_UpperLip.scl = {vec3.x, vec3.y, vec3.z}
	character._23C_UpperLip.scl = {vec3.x, vec3.y, vec3.z}

	changed, vec3 = imgui.drag_float3("Upper Lip Position", array_to_vec3(character._01L_UpperLip_01_Edge.pos), 1, -100, 100)
	update = update or changed
	character._01L_UpperLip_01_Edge.pos = {vec3.x, vec3.y, vec3.z}
	character._02L_UpperLip_02_Edge.pos = {vec3.x, vec3.y, vec3.z}
	character._03L_UpperLip_03_Edge.pos = {vec3.x, vec3.y, vec3.z}
	character._20C_UpperLip_Mid_Edge.pos = {vec3.x, vec3.y, vec3.z}
	
	character._04L_UpperLip_01_Volume.pos = {vec3.x, vec3.y, vec3.z}
	character._05L_UpperLip_02_Volume.pos = {vec3.x, vec3.y, vec3.z}
	character._06L_UpperLip_03_Volume.pos = {vec3.x, vec3.y, vec3.z}
	character._21C_UpperLip_Mid_Volume.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение середины верхней губы", array_to_vec3(character._30C_UpperLip_Mid_Edge.pos), 1, -100, 100)
	update = update or changed
	character._30C_UpperLip_Mid_Edge.pos = {vec3.x, vec3.y, vec3.z}
	character._31C_UpperLip_Mid_Volume.pos = {vec3.x, vec3.y, vec3.z}
	
	character._20C_UpperLip_Mid_Edge.pos = {vec3.x, vec3.y, vec3.z}
	changed, vec3 = imgui.drag_float("Upper Lip Rotation", character._01L_UpperLip_01_Edge.rot1[1], 1, -100, 100)
	update = update or changed
	character._01L_UpperLip_01_Edge.rot1 = {vec3, 0, 0}
	character._02L_UpperLip_02_Edge.rot1 = {vec3, 0, 0}
	character._03L_UpperLip_03_Edge.rot1 = {vec3, 0, 0}
	character._20C_UpperLip_Mid_Edge.rot1 = {vec3, 0, 0}
	
	character._04L_UpperLip_01_Volume.rot1 = {vec3, 0, 0}
	character._05L_UpperLip_02_Volume.rot1 = {vec3, 0, 0}
	character._06L_UpperLip_03_Volume.rot1 = {vec3, 0, 0}
	character._21C_UpperLip_Mid_Volume.rot1 = {vec3, 0, 0}
	
	
	changed, vec3 = imgui.drag_float3("Upper Lip Scale", array_to_vec3(character._01L_UpperLip_01_Edge.scl), 1, -100, 100)
	update = update or changed
	character._01L_UpperLip_01_Edge.scl = {vec3.x, vec3.y, vec3.z}
	character._02L_UpperLip_02_Edge.scl = {vec3.x, vec3.y, vec3.z}
	character._03L_UpperLip_03_Edge.scl = {vec3.x, vec3.y, vec3.z}
	character._20C_UpperLip_Mid_Edge.scl = {vec3.x, vec3.y, vec3.z}
	
	character._04L_UpperLip_01_Volume.scl = {vec3.x, vec3.y, vec3.z}
	character._05L_UpperLip_02_Volume.scl = {vec3.x, vec3.y, vec3.z}
	character._06L_UpperLip_03_Volume.scl = {vec3.x, vec3.y, vec3.z}
	character._21C_UpperLip_Mid_Volume.scl = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Lower Lip Position", array_to_vec3(character._11L_LowerLip_01_Edge.pos), 1, -100, 100)
	update = update or changed
	character._11L_LowerLip_01_Edge.pos = {vec3.x, vec3.y, vec3.z}
	character._12L_LowerLip_02_Edge.pos = {vec3.x, vec3.y, vec3.z}
	character._13L_LowerLip_03_Edge.pos = {vec3.x, vec3.y, vec3.z}
	character._24C_LowerLip_Mid_Edge.pos = {vec3.x, vec3.y, vec3.z}
	
	character._14L_LowerLip_01_Volume.pos = {vec3.x, vec3.y, vec3.z}
	character._15L_LowerLip_02_Volume.pos = {vec3.x, vec3.y, vec3.z}
	character._16L_LowerLip_03_Volume.pos = {vec3.x, vec3.y, vec3.z}
	character._25C_LowerLip_Mid_Volume.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение середины нижней губы", array_to_vec3(character._28C_LowerLip_Mid_Edge.pos), 1, -100, 100)
	update = update or changed
	character._28C_LowerLip_Mid_Edge.pos = {vec3.x, vec3.y, vec3.z}
	character._29C_LowerLip_Mid_Volume.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float("Lower Lip Rotation", character._11L_LowerLip_01_Edge.rot1[1], 1, -100, 100)
	update = update or changed
	character._11L_LowerLip_01_Edge.rot1 = {vec3, 0, 0}
	character._12L_LowerLip_02_Edge.rot1 = {vec3, 0, 0}
	character._13L_LowerLip_03_Edge.rot1 = {vec3, 0, 0}
	character._24C_LowerLip_Mid_Edge.rot1 = {vec3, 0, 0}
	character._14L_LowerLip_01_Volume.rot1 = {vec3, 0, 0}
	character._15L_LowerLip_02_Volume.rot1 = {vec3, 0, 0}
	character._16L_LowerLip_03_Volume.rot1 = {vec3, 0, 0}
	character._25C_LowerLip_Mid_Volume.rot1 = {vec3, 0, 0}
	
	changed, vec3 = imgui.drag_float3("Lower Lip Scale", array_to_vec3(character._11L_LowerLip_01_Edge.scl), 1, -100, 100)
	update = update or changed
	character._11L_LowerLip_01_Edge.scl = {vec3.x, vec3.y, vec3.z}
	character._12L_LowerLip_02_Edge.scl = {vec3.x, vec3.y, vec3.z}
	character._13L_LowerLip_03_Edge.scl = {vec3.x, vec3.y, vec3.z}
	character._24C_LowerLip_Mid_Edge.scl = {vec3.x, vec3.y, vec3.z}
	character._14L_LowerLip_01_Volume.scl = {vec3.x, vec3.y, vec3.z}
	character._15L_LowerLip_02_Volume.scl = {vec3.x, vec3.y, vec3.z}
	character._16L_LowerLip_03_Volume.scl = {vec3.x, vec3.y, vec3.z}
	character._25C_LowerLip_Mid_Volume.scl = {vec3.x, vec3.y, vec3.z}
end

local function chinUI (character)
	changed, vec3 = imgui.drag_float3("Chin Side 1", array_to_vec3(character._01L_Stretch_01.pos), 1, -100, 100)
	update = update or changed
	character._01L_Stretch_01.pos = {vec3.x, vec3.y, vec3.z}
	character._02L_Stretch_02.pos = {vec3.x, vec3.y, vec3.z}
	character._03L_Stretch_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Chin Side 2", array_to_vec3(character._04L_Chin_01.pos), 1, -100, 100)
	update = update or changed
	character._04L_Chin_01.pos = {vec3.x, vec3.y, vec3.z}
	character._05L_Chin_02.pos = {vec3.x, vec3.y, vec3.z}
	character._06L_Chin_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Mid Chin", array_to_vec3(character._07C_Chin_Mid_01.pos), 1, -100, 100)
	update = update or changed
	character._07C_Chin_Mid_01.pos = {vec3.x, vec3.y, vec3.z}
	character._08C_Chin_Mid_02.pos = {vec3.x, vec3.y, vec3.z}
	character._09C_Chin_Mid_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Челюсть 1", array_to_vec3(character._10L_JawOpen_Depress.pos), 1, -100, 100)
	update = update or changed
	character._10L_JawOpen_Depress.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Челюсть 2", array_to_vec3(character._11L_JawClench.pos), 1, -100, 100)
	update = update or changed
	character._11L_JawClench.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Neck 1", array_to_vec3(character._15L_Neck_01.pos), 1, -100, 100)
	update = update or changed
	character._15L_Neck_01.pos = {vec3.x, vec3.y, vec3.z}
	character._16R_Neck_01.pos = {-vec3.x, vec3.y, vec3.z}
	character._14C_Neck_01.pos = {0, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Шея 2", array_to_vec3(character._13Facialjnt1_Neck_1.pos), 1, -100, 100)
	update = update or changed
	character._13Facialjnt1_Neck_1.pos = {vec3.x, vec3.y, vec3.z}
end

local function symmetryUI (character)
	changed, vec3 = imgui.drag_float3("Ear Position", array_to_vec3(character._21L_Ear.pos), 1, -100, 100)
	update = update or changed
	character._21L_Ear.pos = {vec3.x, vec3.y, vec3.z}
	changed, vec3 = imgui.drag_float3("Ear Helix Position", array_to_vec3(character._22L_Ear_Helix.pos), 1, -100, 100)
	update = update or changed
	character._22L_Ear_Helix.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Brow Position", array_to_vec3(character._22L_Brow_Lower_01.pos), 1, -100, 100)
	update = update or changed
	character._22L_Brow_Lower_01.pos = {vec3.x, vec3.y, vec3.z}
	character._23L_Brow_Lower_02.pos = {vec3.x, vec3.y, vec3.z}
	character._24L_Brow_Lower_03.pos = {vec3.x, vec3.y, vec3.z}
	character._25L_Brow_Lower_04.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Brow Rotation", array_to_vec3(character._23L_Brow_Lower_02.rot), 1, -100, 100)
	update = update or changed
	character._22L_Brow_Lower_01.rot = {0.1*vec3.x, 0.1*vec3.y, 0.1*vec3.z}
	character._23L_Brow_Lower_02.rot = {vec3.x, vec3.y, vec3.z}
	character._24L_Brow_Lower_03.rot = {0.5 *-vec3.x, 0.5 *-vec3.y, 0.5 *-vec3.z}
	character._25L_Brow_Lower_04.rot = {0.5 *-vec3.x, 0.5 *-vec3.y, 0.5 *-vec3.z}
		
	changed, vec3 = imgui.drag_float3("Положение глаза", array_to_vec3(character._21L_Eye.pos), 1, -100, 100)
	update = update or changed
	character._21L_Eye.pos = {vec3.x, vec3.y, vec3.z}
	character._06L_LowerLid_01.pos = {vec3.x, vec3.y, vec3.z}
	character._07L_LowerLid_02.pos = {vec3.x, vec3.y, vec3.z}
	character._08L_LowerLid_03.pos = {vec3.x, vec3.y, vec3.z}
	character._09L_LowerLid_04.pos = {vec3.x, vec3.y, vec3.z}
	character._13L_EyeFat_Lower_01.pos = {vec3.x, vec3.y, vec3.z}
	character._14L_EyeFat_Lower_02.pos = {vec3.x, vec3.y, vec3.z}
	character._15L_EyeFat_Lower_03.pos = {vec3.x, vec3.y, vec3.z}	
	character._16L_EyeOuter_Corner.pos = {vec3.x, vec3.y, vec3.z}
	character._17L_EyeInner_Corner.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Eye Rotation", array_to_vec3(character._01L_UpperLid_01.rot), 1, -100, 100)
	update = update or changed
	character._01L_UpperLid_01.rot = {vec3.x, vec3.y, vec3.z}
	character._02L_UpperLid_02.rot = {0.5 * vec3.x, 0.5 * vec3.y, 0.5 * vec3.z}
	character._04L_UpperLid_04.rot = {0.5 * -vec3.x, 0.5 * -vec3.y, 0.5 * -vec3.z}
	character._05L_UpperLid_05.rot = {-vec3.x, -vec3.y, -vec3.z}
	character._06L_LowerLid_01.rot = {vec3.x, vec3.y, vec3.z}
	character._07L_LowerLid_02.rot = {0.5 * vec3.x, 0.5 * vec3.y, 0.5 * vec3.z}
	character._08L_LowerLid_03.rot = {0.5 * -vec3.x, 0.5 * -vec3.y, 0.5 * -vec3.z}
	character._09L_LowerLid_04.rot = {-vec3.x, -vec3.y, -vec3.z}
	character._10L_EyeFat_Upper_01.rot = {vec3.x, vec3.y, vec3.z}
	character._12L_EyeFat_Upper_03.rot = {-vec3.x, -vec3.y, -vec3.z}
	character._13L_EyeFat_Lower_01.rot = {vec3.x, vec3.y, vec3.z}
	character._15L_EyeFat_Lower_03.rot = {-vec3.x, -vec3.y, -vec3.z}
	character._18L_EyeFold_01.rot = {vec3.x, vec3.y, vec3.z}
	character._20L_EyeFold_03.rot = {-vec3.x, -vec3.y, -vec3.z}
	
	changed, vec3 = imgui.drag_float3("Eyelid Position", array_to_vec3(character._01L_UpperLid_01.pos), 1, -100, 100)
	update = update or changed
	character._01L_UpperLid_01.pos = {vec3.x, vec3.y, vec3.z}
	character._02L_UpperLid_02.pos = {vec3.x, vec3.y, vec3.z}
	character._03L_UpperLid_03.pos = {vec3.x, vec3.y, vec3.z}
	character._04L_UpperLid_04.pos = {vec3.x, vec3.y, vec3.z}
	character._05L_UpperLid_05.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Eyefold Position", array_to_vec3(character._18L_EyeFold_01.pos), 1, -100, 100)
	update = update or changed
	character._18L_EyeFold_01.pos = {vec3.x, vec3.y, vec3.z}
	character._19L_EyeFold_02.pos = {vec3.x, vec3.y, vec3.z}
	character._20L_EyeFold_03.pos = {vec3.x, vec3.y, vec3.z}
	character._10L_EyeFat_Upper_01.pos = {vec3.x, vec3.y, vec3.z}
	character._11L_EyeFat_Upper_02.pos = {vec3.x, vec3.y, vec3.z}
	character._12L_EyeFat_Upper_03.pos = {vec3.x, vec3.y, vec3.z}
end

local function jiggleUI (character)
	changed, vec = imgui.slider_int("Сила колыхания ягодиц", character.butt.str, 0, 10)
	update = update or changed
	character.butt.str = vec
	changed, vec = imgui.slider_float("Дальность колыхания ягодиц", character.butt.dist, 0, 1)
	update = update or changed
	character.butt.dist = vec
	changed, vec = imgui.slider_float("Затухание колыхания ягодиц", character.butt.damp, 0, 10)
	update = update or changed
	character.butt.damp = vec
	changed, vec = imgui.slider_float("Гравитация ягодиц", character.butt.grav, -10, 10)
	update = update or changed
	character.butt.grav = vec
	
	imgui.new_line()
	
	changed, vec = imgui.slider_int("Сила колыхания бёдер", character.thigh.str, 0, 10)
	update = update or changed
	character.thigh.str = vec
	changed, vec = imgui.slider_float("Дальность колыхания бёдер", character.thigh.dist, 0, 1)
	update = update or changed
	character.thigh.dist = vec
	changed, vec = imgui.slider_float("Затухание колыхания бёдер", character.thigh.damp, 0, 10)
	update = update or changed
	character.thigh.damp = vec
	
	imgui.new_line()
	
	changed, vec = imgui.slider_int("Сила колыхания грудных мышц", character.pecs.str, 0, 10)
	update = update or changed
	character.pecs.str = vec
	changed, vec = imgui.slider_float("Дальность колыхания грудных мышц", character.pecs.dist, 0, 1)
	update = update or changed
	character.pecs.dist = vec
	changed, vec = imgui.slider_float("Затухание колыхания грудных мышц", character.pecs.damp, 0, 10)
	update = update or changed
	character.pecs.damp = vec
	changed, vec = imgui.slider_float("Гравитация/упругость грудных мышц", character.pecs.grav, -10, 10)
	update = update or changed
	character.pecs.grav = vec
end
local preset_name = ""

local function callMenu(preset, gender)
	if imgui.tree_node("Редактор лица") then
		if imgui.tree_node("Форма головы/ушей") then
			headUI(preset.face.brow, preset.body.upperbody)
			imgui.tree_pop()
		end
		
		if imgui.tree_node("Брови") then
			browUI(preset.face.brow)
			imgui.tree_pop()
		end
		
		if imgui.tree_node("Глаза") then
			eyesUI(preset.face.eyes)
			imgui.tree_pop()
		end
		
		if imgui.tree_node("Нос") then
			noseUI(preset.face.nose)
			imgui.tree_pop()
		end
		
		if imgui.tree_node("Щёки") then
			cheeksUI(preset.face.cheeks)
			imgui.tree_pop()
		end
		
		if imgui.tree_node("Губы") then
			lipsUI(preset.face.lips)
			imgui.tree_pop()
		end
		
		if imgui.tree_node("Подбородок/челюсть") then
			chinUI(preset.face.chin)
			imgui.tree_pop()
		end
		
		if imgui.tree_node("Симметрия") then
			symmetryUI(preset.face.symmetry)
			imgui.tree_pop()
		end
		imgui.tree_pop()
	end
	if imgui.tree_node("Редактор тела") then
		changed, vec3 = imgui.drag_float("Масштаб тела", preset.body.upperbody.root2.scl[2], 1, -100, 100)
		update = update or changed
		preset.body.upperbody.root2.scl = {0,vec3,vec3}
		preset.body.upperbody.L_Hip_Rear_A2.pos = {-0.66*vec3,-3.3*vec3,2.25*vec3}
		changed, vec3 = imgui.drag_float("Высота тела", preset.body.upperbody.root.scl[2], 1, -100, 100)
		update = update or changed
		preset.body.upperbody.root.scl = {0,vec3,0}
		
		if imgui.tree_node("Торс") then 
			
			bodyUI(preset.body.upperbody)
			imgui.tree_pop()
		end
		
		if gender then 
			if imgui.tree_node("Грудь (ж)") then 
				breastsUI(preset.body.breasts)
				changed, vec3 = imgui.drag_float3("Масштаб нагрудника", array_to_vec3(preset.body.breasts.chestpos.scl), 1, -100, 100)
				update = update or changed
				preset.body.breasts.chestpos.scl = vec3_to_array(vec3)
				imgui.tree_pop()
			end
		else
			if imgui.tree_node("Грудные мышцы") then 
				breastsUI(preset.body.breasts)
				imgui.tree_pop()
			end
		end
		
		if imgui.tree_node("Руки/кисти") then
			armsUI(preset.body.arm)
			imgui.tree_pop()
		end
		
		if imgui.tree_node("Ноги/ступни") then 
			legsUI(preset.body.lowerbody)
			imgui.tree_pop()
		end
		
		if imgui.tree_node("Ягодицы") then 
			buttUI(preset.body.butt)
			imgui.tree_pop()
		end
		imgui.tree_pop()
	end
	if imgui.tree_node("Редактор колыхания") then
		imgui.text("[Редактор колыхания работает только во время игры или в меню инвентаря]")	
		if gender then 
			changed, vec = imgui.slider_int("Сила колыхания груди", preset.jiggle.jiggle.breast.str, 0, 11)
			if (preset.jiggle.jiggle.breast.str < 0 or preset.jiggle.jiggle.breast.str > 11) then 
				preset.jiggle.jiggle.breast.str = 0
			end
			update = update or changed
			preset.jiggle.jiggle.breast.str = vec	
			
			changed, vec = imgui.slider_float("Дальность колыхания груди", preset.jiggle.jiggle.breast.dist, 0, 1)
			update = update or changed
			preset.jiggle.jiggle.breast.dist = vec	
			
			changed, vec = imgui.slider_float("Затухание колыхания груди", preset.jiggle.jiggle.breast.damp, 0, 10)
			update = update or changed
			preset.jiggle.jiggle.breast.damp = vec	
			
			imgui.new_line()
		end
		jiggleUI(preset.jiggle.jiggle)
		imgui.tree_pop()
	end

end

re.on_draw_ui(function()
	config_a_m = config[presets.arisen.m]
	config_a_f = config[presets.arisen.f]
	config_p_m = config[presets.pawn.m]
	config_p_f = config[presets.pawn.f]
	
	if imgui.tree_node("Расширенный редактор персонажа") then	
		local changed
		if imgui.tree_node("Включение") then
			imgui.text("[Перезагрузите сцену для применения изменений]")
			if imgui.tree_node("Избранный") then
				changed, config_a_m.bulge_enabled = imgui.checkbox("Мужской", config_a_m.bulge_enabled)
				update = update or changed
				changed, config_a_f.bulge_enabled = imgui.checkbox("Женский", config_a_f.bulge_enabled)
				update = update or changed
				imgui.tree_pop()
			end	
			if imgui.tree_node("Главная пешка") then
				changed, config_p_m.bulge_enabled = imgui.checkbox("Мужской", config_p_m.bulge_enabled)
				update = update or changed
				changed, config_p_f.bulge_enabled = imgui.checkbox("Женский", config_p_f.bulge_enabled)
				update = update or changed
				imgui.tree_pop()
			end
			imgui.tree_pop()
		end	
		if imgui.tree_node("Редактор") then
			imgui.text("[Можно редактировать в реальном времени в редакторе персонажа (посетите парикмахера)]")	
			
			if imgui.tree_node("Пресеты") then
				
				changed, preset_name = imgui.input_text("Имя нового пресета", preset_name, 1 << 4)
				if imgui.button("Создать новый пресет") then
					if preset_list[preset_name] then
						re.msg("Ошибка: пресет с таким именем уже существует")
					elseif preset_name == "" then
						re.msg("Ошибка: введите имя пресета")
					else
						config_filename = "ExtendedCharacterEditor\\Presets\\"..preset_name..".json"
						preset_list[preset_name] = config_filename
						preset_names[#preset_names + 1] = preset_name
						table.insert(presets.list, preset_name)
						preset_amount = preset_amount + 1
						for i = 1,preset_amount,1 do 
							table.insert(charType_table, config[i])
						end	
						load_presets()
						save_preset()
						re.msg("Пресет создан!")
						update = true
					end
				end
				imgui.new_line()
				
				changed, index = imgui.combo("Избранный (муж.)", presets.arisen.m, preset_names)
				if changed then
					presets.arisen.m = index
					config_a_m = config[index]
					json.dump_file("ExtendedCharacterEditor/Presetslist.json", presets)
				end
				update = update or changed
				changed, index = imgui.combo("Избранный (жен.)", presets.arisen.f, preset_names)
				if changed then
					presets.arisen.f = index
					config_a_f = config[index]
					json.dump_file("ExtendedCharacterEditor/Presetslist.json", presets)
				end
				update = update or changed
				changed, index = imgui.combo("Пешка (муж.)", presets.pawn.m, preset_names)
				if changed then
					presets.pawn.m = index
					config_p_m = config[index]
					json.dump_file("ExtendedCharacterEditor/Presetslist.json", presets)
				end
				update = update or changed
				changed, index = imgui.combo("Пешка (жен.)", presets.pawn.f, preset_names)
				if changed then
					presets.pawn.f = index
					config_p_f = config[index]
					json.dump_file("ExtendedCharacterEditor/Presetslist.json", presets)
				end
				update = update or changed
				imgui.tree_pop()
			end
					
			if imgui.tree_node("Избранный") then			
				if imgui.tree_node("Мужской") then
					imgui.begin_rect()
					if imgui.button("Сохранить", 5) then 
						save_preset(presets.arisen.m)
						re.msg("Изменения сохранены!")
					end
					imgui.same_line()
					imgui.text_colored("(?)", 0xFFFFFFFF)
					if imgui.is_item_hovered() then
						imgui.set_tooltip("Изменения также сохраняются автоматически при закрытии окна REFramework.")
					end
					imgui.same_line()
					imgui.text('		')
					imgui.same_line()
					if imgui.button("Отменить") then 
						config[presets.arisen.m] = json.load_file(preset_list[preset_names[presets.arisen.m]])
						re.msg("Изменения отменены!")
					end
					imgui.same_line()
					imgui.text_colored("(?)", 0xFFFFFFFF)
					if imgui.is_item_hovered() then
						imgui.set_tooltip("Отменяет изменения, сделанные с момента последнего сохранения.")
					end
					
					callMenu(config_a_m)
					imgui.end_rect(4, 3)
					imgui.tree_pop()
				end
				
				if imgui.tree_node("Женский") then
					imgui.begin_rect()
					if imgui.button("Сохранить") then 
						save_preset(presets.arisen.f)
						re.msg("Edit saved!")
					end
					imgui.same_line()
					imgui.text_colored("(?)", 0xFFFFFFFF)
					if imgui.is_item_hovered() then
						imgui.set_tooltip("Изменения также сохраняются автоматически при закрытии окна REFramework.")
					end
					imgui.same_line()
					imgui.text('		')
					imgui.same_line()
					if imgui.button("Undo") then 
						config[presets.arisen.f] = json.load_file(preset_list[preset_names[presets.arisen.f]])
						re.msg("Undone!")
					end
					imgui.same_line()
					imgui.text_colored("(?)", 0xFFFFFFFF)
					if imgui.is_item_hovered() then
						imgui.set_tooltip("Отменяет изменения, сделанные с момента последнего сохранения.")
					end
					
					callMenu(config_a_f, 1)
					imgui.end_rect(4, 3)
					imgui.tree_pop()
				end				
				imgui.tree_pop()
			end
			
			if imgui.tree_node("Главная пешка") then
				
				if imgui.tree_node("Мужской") then
					imgui.begin_rect()
					if imgui.button("Save") then 
						save_preset(presets.pawn.m)
						re.msg("Edit saved!")
					end
					imgui.same_line()
					imgui.text_colored("(?)", 0xFFFFFFFF)
					if imgui.is_item_hovered() then
						imgui.set_tooltip("Изменения также сохраняются автоматически при закрытии окна REFramework.")
					end
					imgui.same_line()
					imgui.text('		')
					imgui.same_line()
					if imgui.button("Undo") then 
						config[presets.pawn.m] = json.load_file(preset_list[preset_names[presets.pawn.m]])
						re.msg("Undone!")
					end
					imgui.same_line()
					imgui.text_colored("(?)", 0xFFFFFFFF)
					if imgui.is_item_hovered() then
						imgui.set_tooltip("Отменяет изменения, сделанные с момента последнего сохранения.")
					end
			
					callMenu(config_p_m)
					imgui.end_rect(4, 3)
					imgui.tree_pop()
				end
				
				if imgui.tree_node("Женский") then
					imgui.begin_rect()
					if imgui.button("Сохранить") then 
						save_preset(presets.pawn.f)
						re.msg("Edit saved!")
					end
					imgui.same_line()
					imgui.text_colored("(?)", 0xFFFFFFFF)
					if imgui.is_item_hovered() then
						imgui.set_tooltip("Изменения также сохраняются автоматически при закрытии окна REFramework.")
					end
					imgui.same_line()
					imgui.text('		')
					imgui.same_line()
					if imgui.button("Undo") then 
						config[presets.pawn.f] = json.load_file(preset_list[preset_names[presets.pawn.f]])
						re.msg("Undone!")
					end
					imgui.same_line()
					imgui.text_colored("(?)", 0xFFFFFFFF)
					if imgui.is_item_hovered() then
						imgui.set_tooltip("Отменяет изменения, сделанные с момента последнего сохранения.")
					end
					
					callMenu(config_p_f, 1)
					imgui.end_rect(4, 3)
					imgui.tree_pop()
				end				
				imgui.tree_pop()
			end
			imgui.tree_pop()
		end			
		imgui.tree_pop()
	end
			
	if update then
		--for i=1,preset_amount,1 do
		--json.dump_file(preset_list[preset_names[i]], config[i])
		--end
		--json.dump_file("ExtendedCharacterEditor/Presetslist.json", presets)
		--update = false
	end	
end)
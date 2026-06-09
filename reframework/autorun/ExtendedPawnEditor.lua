local fs = fs

local jointlist = json.load_file("HiredPawnEditor/Jointlist.json")
local preset_list, preset_names = {}, {}
local config = {}

local scalelist = {}
local poslist = {}
local rotlist = {}
local jiggle = {}
local fscalelist = {}
local fposlist = {}
local frotlist = {}

local function nil_list()
	scalelist = {}
	poslist = {}
	rotlist = {}
	jiggle = {}
	fscalelist = {}
	fposlist = {}
	frotlist = {}
end

local presets = json.load_file("HiredPawnEditor/Presetslist.json") or {
	
	pawn2 = 1,
	pawn3 = 1,
	list = {"Default"}
}

local preset_amount = 0
for i, filepath in ipairs(fs.glob([[^HiredPawnEditor\\Presets\\.+\.[jJ][sS][oO][nN]$]])) do
	local exists = false
    local preset_name = filepath:sub(25, -6)
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

local charType_table

local function save_preset(preset)
	if preset then
		json.dump_file(preset_list[preset_names[preset]], config[preset])
	else
		for i=1,preset_amount,1 do
			json.dump_file(preset_list[preset_names[i]], config[i])
		end
		json.dump_file("HiredPawnEditor/Presetslist.json", presets)
	end
end

local function load_presets()
	for i=1,preset_amount,1 do
		config[i] = json.load_file(preset_list[preset_names[i]]) or {
			bulge_enabled = true,
			body = {
				body = {}
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

json.dump_file("HiredPawnEditor/Presetslist.json", presets)

re.on_config_save(function()
	for i=1,preset_amount,1 do
    json.dump_file(preset_list[preset_names[i]], config[i])
	end
end)

local function apply_scale_transforms(root_editor, charType, body_editor, part_swapper, chain_editor)	
	local jiggle_table = {0, 0.15, 0.30, 0.45, 0.60, 0.75, 0.9, 1.05, 1.2, 1.5, 5.0, 10.0}
	if chain_editor ~= nil then	
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
					chain:set_BlendRate(charType.jiggle.jiggle[tostring(values[i])].str/5)
					chain:set_DampingRate(charType.jiggle.jiggle[tostring(values[i])].damp)
					chain:set_SubReduceDistance(1-charType.jiggle.jiggle[tostring(values[i])].dist)
					if values[i] == "breast" then
						chain:set_GravityRate(charType.jiggle.jiggle[tostring(values[i])].grav/2.5)
					else
						chain:set_GravityRate(charType.jiggle.jiggle[tostring(values[i])].grav)
					end
				end
			end	
		end
	end
	if body_editor:get_BustSizeRate() ~= jiggle_table[charType.jiggle.jiggle.breast.str+1] then
		body_editor:set_BustSizeRate(jiggle_table[charType.jiggle.jiggle.breast.str+1])
		part_swapper._UpdateStatusOfSwapObjects = true
	end
	
	if root_editor ~= nil then 
		local joints = root_editor:get_Joints()
		local edit_scale1
		local edit_scale2
		
		if joints:Get(100):get_Name() ~= "L_Elbow_PointOffset" then
			jnt = "jnt2"
		else
			jnt = "jnt1"
		end
		
		local values = {}
		local keys = {}
		local amount = 0

		for key,_ in pairs(charType.body) do
			for value,_ in pairs(charType.body[key]) do
				table.insert(values, value)
				table.insert(keys, key)
				amount = amount + 1
			end
		end
		
		for i = 1,amount,1 do
			if charType.body[tostring(keys[i])][tostring(values[i])].pos then
				edit_scale1 = Vector3f.new(-charType.body[tostring(keys[i])][tostring(values[i])].pos[1]/1000, 
				charType.body[tostring(keys[i])][tostring(values[i])].pos[2]/1000, -charType.body[tostring(keys[i])][tostring(values[i])].pos[3]/1000)
				edit_scale2 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].pos[1]/1000, 
				-charType.body[tostring(keys[i])][tostring(values[i])].pos[2]/1000, charType.body[tostring(keys[i])][tostring(values[i])].pos[3]/1000)
				if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)] then
					if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
						joint = joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local pos = joint:get_BaseLocalPosition()
						if poslist[joint] and poslist[joint][1] then
							poslist[joint] = {poslist[joint][1] + edit_scale1, pos}
						else
							poslist[joint] = {edit_scale1, pos}
						end
						joint = joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2])
						local pos = joint:get_BaseLocalPosition()
						if poslist[joint] and poslist[joint][1] then
							poslist[joint] = {poslist[joint][1] + edit_scale2, pos}
						else
						poslist[joint] = {edit_scale2, pos}
						end
					else
						joint = joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local pos = joint:get_BaseLocalPosition()
						poslist[joint] = {edit_scale1, pos}
					end
				end
			end
			if charType.body[tostring(keys[i])][tostring(values[i])].rot then
				edit_scale1 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].rot[1]/100, 
				charType.body[tostring(keys[i])][tostring(values[i])].rot[2]/100, charType.body[tostring(keys[i])][tostring(values[i])].rot[3]/100)
				edit_scale2 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].rot[1]/100, 
				charType.body[tostring(keys[i])][tostring(values[i])].rot[2]/100, charType.body[tostring(keys[i])][tostring(values[i])].rot[3]/100)
				if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)] then
					if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
						joint = joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						rotlist[joint] = edit_scale1
						joint = joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2])
						rotlist[joint] = edit_scale2
					else
						joint = joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						rotlist[joint] = edit_scale1
					end
				end
			end
			
			if charType.body[tostring(keys[i])][tostring(values[i])].scl then
				edit_scale1 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].scl[1]/100, 
				charType.body[tostring(keys[i])][tostring(values[i])].scl[2]/100, charType.body[tostring(keys[i])][tostring(values[i])].scl[3]/100)
				edit_scale2 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].scl[1]/100, 
				charType.body[tostring(keys[i])][tostring(values[i])].scl[2]/100, charType.body[tostring(keys[i])][tostring(values[i])].scl[3]/100)
				if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)] then
					if charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
						joint = joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local scl = joint:get_BaseLocalScale()
						scalelist[joint] = {edit_scale1, scl}
						joint = joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2])
						local scl = joint:get_BaseLocalScale()
						scalelist[joint] = {edit_scale2, scl}
					else			
						joint = joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local scl = joint:get_BaseLocalScale()
						scalelist[joint] = {edit_scale1, scl}
					end
				end
			end
			
			if charType.body[tostring(keys[i])][tostring(values[i])].scl1 then
				edit_scale1 = Vector3f.new(charType.body[tostring(keys[i])][tostring(values[i])].scl1[1]/100, 
				charType.body[tostring(keys[i])][tostring(values[i])].scl1[2]/100, charType.body[tostring(keys[i])][tostring(values[i])].scl1[3]/100)
					joint = joints:Get(charType.body[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
					local scl = joint:get_BaseLocalScale()
					scalelist[joint] = {edit_scale1, scl}
			end
		end
		for joint, value in pairs(poslist) do
			if value[2] then
				poslist[joint] = value[1] + value[2]
			end
		end
		for joint, value in pairs(scalelist) do
			if value[2] then
				scalelist[joint] = value[1] + joint:get_BaseLocalScale()
			end
		end
	end
end

local function apply_face_transforms(root_editor, charType)	
	local joints = root_editor:get_Joints()
	local edit_scale1
	local edit_scale2
	
	if joints then
		if joints:Get(100):get_Name() == "C_LowerLip_Mid_Bag" then
			jnt = "jnt"
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
				if edit_scale1 ~= Vector3f.new(0.0, 0.0, 0.0) then
					if charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local pos = joint:get_BaseLocalPosition()
						if fposlist[joint] and fposlist[joint][1] then
							fposlist[joint] = {fposlist[joint][1] + edit_scale1, pos}
						else
							fposlist[joint] = {edit_scale1, pos}
						end
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2])
						local pos = joint:get_BaseLocalPosition()
						if fposlist[joint] and fposlist[joint][1] then
							fposlist[joint] = {fposlist[joint][1] + edit_scale2, pos}
						else
							fposlist[joint] = {edit_scale2, pos}
						end
					else				
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local pos = joint:get_BaseLocalPosition()
						if fposlist[joint] and fposlist[joint][1] then
							fposlist[joint] = {fposlist[joint][1] + edit_scale1, pos}
						else
							fposlist[joint] = {edit_scale1, pos}
						end
					end
				end
			end
			if charType.face[tostring(keys[i])][tostring(values[i])].rot then
				edit_scale1 = Vector3f.new(charType.face[tostring(keys[i])][tostring(values[i])].rot[1]/3000, 
				charType.face[tostring(keys[i])][tostring(values[i])].rot[2]/3000, charType.face[tostring(keys[i])][tostring(values[i])].rot[3]/3000)
				edit_scale2 = Vector3f.new(-charType.face[tostring(keys[i])][tostring(values[i])].rot[1]/3000, 
				charType.face[tostring(keys[i])][tostring(values[i])].rot[2]/3000, charType.face[tostring(keys[i])][tostring(values[i])].rot[3]/3000)
				if edit_scale1 ~= Vector3f.new(0.0, 0.0, 0.0) then
					if charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local pos = joint:get_BaseLocalPosition()
						if fposlist[joint] and fposlist[joint][1] then
							fposlist[joint] = {fposlist[joint][1] + edit_scale1, pos}
						else
							fposlist[joint] = {edit_scale1, pos}
						end
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2])
						local pos = joint:get_BaseLocalPosition()
						if fposlist[joint] and fposlist[joint][1] then
							fposlist[joint] = {fposlist[joint][1] + edit_scale2, pos}
						else
							fposlist[joint] = {edit_scale2, pos}
						end
					else				
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local pos = joint:get_BaseLocalPosition()
						if fposlist[joint] and fposlist[joint][1] then
							fposlist[joint] = {fposlist[joint][1] + edit_scale1, pos}
						else
							fposlist[joint] = {edit_scale1, pos}
						end
					end
				end
			end
			if charType.face[tostring(keys[i])][tostring(values[i])].rot1 then
				edit_scale1 = Vector3f.new(charType.face[tostring(keys[i])][tostring(values[i])].rot1[1]/100, 
				-charType.face[tostring(keys[i])][tostring(values[i])].rot1[2]/100, -charType.face[tostring(keys[i])][tostring(values[i])].rot1[3]/100)
				edit_scale2 = Vector3f.new(charType.face[tostring(keys[i])][tostring(values[i])].rot1[1]/100, 
				charType.face[tostring(keys[i])][tostring(values[i])].rot1[2]/100, charType.face[tostring(keys[i])][tostring(values[i])].rot1[3]/100)
				if edit_scale1 ~= Vector3f.new(0.0, 0.0, 0.0) then
					if charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local rot = {}
						if frotlist[joint] and frotlist[joint][1] then
							frotlist[joint] = {frotlist[joint][1] + edit_scale1, rot}
						else
							frotlist[joint] = {edit_scale1, rot}
						end
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2])
						local rot = joint:get_BaseLocalPosition()
						if frotlist[joint] and frotlist[joint][1] then
							frotlist[joint] = {frotlist[joint][1] + edit_scale2, rot}
						else
							frotlist[joint] = {edit_scale2, rot}
						end
					else				
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local rot = joint:get_BaseLocalPosition()
						if frotlist[joint] and frotlist[joint][1] then
							frotlist[joint] = {frotlist[joint][1] + edit_scale1, rot}
						else
							frotlist[joint] = {edit_scale1, rot}
						end
					end
				end
			end
			if charType.face[tostring(keys[i])][tostring(values[i])].scl then
				edit_scale1 = Vector3f.new(charType.face[tostring(keys[i])][tostring(values[i])].scl[1]/100, 
				charType.face[tostring(keys[i])][tostring(values[i])].scl[2]/100, charType.face[tostring(keys[i])][tostring(values[i])].scl[3]/100)
				edit_scale2 = Vector3f.new(charType.face[tostring(keys[i])][tostring(values[i])].scl[1]/100, 
				charType.face[tostring(keys[i])][tostring(values[i])].scl[2]/100, charType.face[tostring(keys[i])][tostring(values[i])].scl[3]/100)
				if edit_scale1 ~= Vector3f.new(0.0, 0.0, 0.0) then
					if charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2] then
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local scl = joint:get_BaseLocalScale()
						if fscalelist[joint] and fscalelist[joint][1] then
							fscalelist[joint] = {fscalelist[joint][1] + edit_scale1, scl}
						else
							fscalelist[joint] = {edit_scale1, scl}
						end
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][2])
						local scl = joint:get_BaseLocalPosition()
						if fscalelist[joint] and fscalelist[joint][1] then
							fscalelist[joint] = {fscalelist[joint][1] + edit_scale2, scl}
						else
							fscalelist[joint] = {edit_scale2, scl}
						end
					else				
						joint = joints:Get(charType.face[tostring(keys[i])][tostring(values[i])][tostring(jnt)][1])
						local scl = joint:get_BaseLocalPosition()
						if fscalelist[joint] and fscalelist[joint][1] then
							fscalelist[joint] = {fscalelist[joint][1] + edit_scale1, scl}
						else
							fscalelist[joint] = {edit_scale1, scl}
						end
					end
				end
			end
		end
		for joint, value in pairs(fposlist) do
			if value[2] then
			fposlist[joint] = value[1] + value[2]
			end
		end
		for joint, value in pairs(fscalelist) do
			if value[2] then
			fscalelist[joint] = value[1] + joint:get_BaseLocalScale()
			end
		end
	end
end

re.on_application_entry("PrepareRendering", function()
	for joint, value in pairs(fposlist) do
		if joint:get_Valid() then
			joint:set_LocalPosition(value)
		end
	end
	
	for joint, value in pairs(frotlist) do
		if joint:get_Valid() then
			joint:set_LocalEulerAngle(value[1])		
		end
	end
	
	for joint, value in pairs(fscalelist) do
		if joint:get_Valid() then
			joint:set_LocalScale(value)
		end
	end
	
	
	
	for joint, value in pairs(poslist) do
		if joint:get_Valid() then
		joint:set_LocalPosition(value)
		end
	end
	
	for joint, value in pairs(rotlist) do
		if joint:get_Valid() then
		joint:set_LocalEulerAngle(value)
		end
	end
	
	for joint, value in pairs(scalelist) do
		if joint:get_Valid() then
		joint:set_LocalScale(value)
		end
	end
end)
local updatePawn
local function pre_EditScales(args)
	-- print("update")
    updatePawn = true
end

local function post_EditScales(retval)
    return retval
end

local function pre_Chain(args)
    thread.get_hook_storage().chain_editor = sdk.to_managed_object(args[1])
end

local function post_Chain(retval)
	local chain_editor = thread.get_hook_storage().chain_editor
    local game_object = chain_editor:get_GameObject()
	local pawnIDs = sdk.get_managed_singleton("app.PawnManager"):get_SavedPartyPawnList()
	local character = game_object:call("getComponent(System.Type)", sdk.typeof("app.Character"))
	local body_editor = game_object:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
	local root_editor = game_object:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
	local face_editor = root_editor:find("head")
	local character_id
	if character then
        character_id = character:get_CharaID()
	else
        local mock_builder = game_object:call("getComponent(System.Type)", sdk.typeof("app.MockupBuilder"))
		local clone_builder = game_object:call("getComponent(System.Type)", sdk.typeof("app.CloneBuilder"))	
        if mock_builder then
			character_id = mock_builder:get_BuildCharaID()
		elseif clone_builder then
			character_id = clone_builder:get_BuildCharaID()
		end
	end
    if pawnIDs:IndexOf(character_id) >= 1 then
		chain_editor:set_GravityFreezeRate(0.5)
		chain_editor:setGravityCoord(2)
		local part_swapper = game_object:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
		if pawnIDs:IndexOf(character_id) == 1 then
			apply_scale_transforms(root_editor, config[presets.pawn2], body_editor, part_swapper, chain_editor)
			if face_editor ~= nil then
				apply_face_transforms(face_editor, config[presets.pawn2])
			end
		else
			apply_scale_transforms(root_editor, config[presets.pawn3], body_editor, part_swapper, chain_editor)
			if face_editor ~= nil then
				apply_face_transforms(face_editor, config[presets.pawn3])
			end
		end
	end
    return retval
end
--hirePawn dismissPawn
sdk.hook(sdk.find_type_definition("app.PawnManager"):get_method("getPartyPawnID"), pre_EditScales, post_EditScales)
sdk.hook(sdk.find_type_definition("app.PawnManager"):get_method("hirePawn(app.Character, System.Boolean)"), pre_EditScales, post_EditScales)
sdk.hook(sdk.find_type_definition("via.motion.Chain"):get_method("resetModelCollisionScale"), pre_Chain, post_Chain)
--partSwapper onCompletedBuild onDestroy
local update

re.on_frame(function()
	--local ispaused = sdk.get_managed_singleton("app.GuiManager"):isPausedGUI()
    --if not ispaused then
	--	return
    --end
	if not update then
        return
    end
	nil_list()
	update = false
	local pawnIDs = sdk.get_managed_singleton("app.PawnManager"):get_SavedPartyPawnList()
	local scene = sdk.call_native_func(sdk.get_native_singleton("via.SceneManager"), sdk.find_type_definition("via.SceneManager"), "get_CurrentScene")
	local pawns = sdk.call_native_func(scene, sdk.find_type_definition("via.Scene"), "findComponents(System.Type)", sdk.typeof("app.SpecialPawn"))
    local mockups = sdk.call_native_func(scene, sdk.find_type_definition("via.Scene"), "findComponents(System.Type)", sdk.typeof("app.CloneBuilder"))
	--
	if pawns ~= nil and pawns:get_Count() then
        for i = 0, pawns:get_Count() - 1 do
            local pawn = pawns[i]
			local pawn_object = pawn:get_GameObject()
			pawn = pawn_object:call("getComponent(System.Type)", sdk.typeof("app.Character"))
			
			if pawnIDs:IndexOf(pawn:get_CharaID()) >= 1 then
			
				if pawnIDs:IndexOf(pawn:get_CharaID()) == 1 then
					local root_editor = pawn_object:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
					local face_editor = root_editor:find("head")
					local body_editor = pawn_object:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
					local part_swapper = pawn_object:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
					local chain_editor = pawn_object:call("getComponent(System.Type)", sdk.typeof("via.motion.Chain"))
					apply_scale_transforms(root_editor, config[presets.pawn2], body_editor, part_swapper, chain_editor)
					if face_editor ~= nil then
						apply_face_transforms(face_editor, config[presets.pawn2])
					end
				else
					local root_editor = pawn_object:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
					local face_editor = root_editor:find("head")
					local body_editor = pawn_object:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
					local part_swapper = pawn_object:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
					local chain_editor = pawn_object:call("getComponent(System.Type)", sdk.typeof("via.motion.Chain"))
					apply_scale_transforms(root_editor, config[presets.pawn3], body_editor, part_swapper, chain_editor)
					if face_editor ~= nil then
						apply_face_transforms(face_editor, config[presets.pawn3])
					end
				end
			end
        end
    end
	
	
	if mockups ~= nil and mockups:get_Count() then
        for i = 0, mockups:get_Count() - 1  do
            local mockup = mockups[i]
			local mockup_object = mockup:get_GameObject()
			if pawnIDs:IndexOf(mockup:get_BuildCharaID()) >= 1 then
				if pawnIDs:IndexOf(mockup:get_BuildCharaID()) == 1 then
					local root_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
					local face_editor = root_editor:find("head")
					local body_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
					local part_swapper = mockup_object:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
					local chain_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("via.motion.Chain"))
					apply_scale_transforms(root_editor, config[presets.pawn2], body_editor, part_swapper, chain_editor)
					if face_editor ~= nil then
						apply_face_transforms(face_editor, config[presets.pawn2])
					end
				else
					local root_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
					local face_editor = root_editor:find("head")
					local body_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("app.BodyEditor"))
					local part_swapper = mockup_object:call("getComponent(System.Type)", sdk.typeof("app.PartSwapper"))
					local chain_editor = mockup_object:call("getComponent(System.Type)", sdk.typeof("via.motion.Chain"))
					apply_scale_transforms(root_editor, config[presets.pawn3], body_editor, part_swapper, chain_editor)
					if face_editor ~= nil then
						apply_face_transforms(face_editor, config[presets.pawn3])
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
	
	changed, vec3 = imgui.drag_float("Масштаб тела", character.root.scl1[2], 1, -100, 100)
	update = update or changed
	character.root.scl1 = {0,vec3,vec3}
	character.L_Hip_Rear_A2.pos = {0.22*vec3,1.1*vec3,0.75*vec3}
	
	changed, vec3 = imgui.drag_float("Рост тела", character.root2.scl1[2], 1, -100, 100)
	update = update or changed
	character.root2.scl1 = {0,vec3,0}
	
	changed, vec3 = imgui.drag_float3("Масштаб торса", array_to_vec3(character.Spine_1.scl), 1, -100, 100)
	update = update or changed
	character.Spine_1.scl = vec3_to_array(vec3)
	imgui.new_line()
	
	changed, vec3 = imgui.drag_float3("Масштаб плеча (внутр.)", array_to_vec3(character.R_Arm_Upper_Twist_1.scl), 1, -100, 100)
	update = update or changed
	character.R_Arm_Upper_Twist_1.scl = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Масштаб плеча (внешн.)", array_to_vec3(character.R_Delt_Side_A.scl), 1, -100, 100)
	update = update or changed
	character.R_Delt_Side_A.scl = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Масштаб предплечья", array_to_vec3(character.R_Arm_Lower_Twist_1.scl), 1, -100, 100)
	update = update or changed
	character.R_Arm_Lower_Twist_1.scl = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Масштаб кисти", array_to_vec3(character.R_Arm_Hand.scl), 1, -100, 100)
	update = update or changed
	character.R_Arm_Hand.scl = vec3_to_array(vec3)
	imgui.new_line()
	
	changed, vec3 = imgui.drag_float3("Масштаб грудной клетки", array_to_vec3(character.R_Pec_A.scl), 1, -100, 100)
	update = update or changed
	character.R_Pec_A.scl = vec3_to_array(vec3)
	character.L_Pec_B.scl = vec3_to_array(vec3)
	character.Boob_Rot.scl = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Поворот груди", array_to_vec3(character.R_Pec_A.rot), 1, -100, 100)
	update = update or changed
	character.R_Pec_A.rot = vec3_to_array(vec3)
	character.L_Pec_B.rot = vec3_to_array(vec3)
	character.Boob_Rot.rot = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Положение груди", array_to_vec3(character.R_Pec_A.pos), 1, -100, 100)
	update = update or changed
	character.R_Pec_A.pos = vec3_to_array(vec3)
	character.L_Pec_B.pos = {-vec3.x,-vec3.y,-vec3.z}
	character.Boob_Pos.pos = {vec3.x,vec3.y,vec3.z}
	character.Boob_Pos2.pos = {vec3.x,-vec3.y,vec3.z}
	
	changed, vec3 = imgui.drag_float3("Масштаб зубчатых мышц", array_to_vec3(character.R_Serratus_A.scl), 1, -100, 100)
	update = update or changed
	character.R_Serratus_A.scl = vec3_to_array(vec3)

	changed, vec3 = imgui.drag_float3("Масштаб широчайших", array_to_vec3(character.R_Lat_A.scl), 1, -100, 100)
	update = update or changed
	character.R_Lat_A.scl = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Масштаб трапеций", array_to_vec3(character.L_Trap_A.scl), 1, -100, 100)
	update = update or changed
	character.L_Trap_A.scl = vec3_to_array(vec3)
	imgui.new_line()
	
	changed, vec3 = imgui.drag_float3("Масштаб ягодиц", array_to_vec3(character.L_Hip_Rear_A.scl), 1, -100, 100)
	update = update or changed
	character.L_Hip_Rear_A.scl = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Поворот ягодиц", array_to_vec3(character.L_Hip_Rear_A.rot), 1, -100, 100)
	update = update or changed
	character.L_Hip_Rear_A.rot = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Положение ягодиц", array_to_vec3(character.L_Hip_Rear_A.pos), 1, -100, 100)
	update = update or changed
	character.L_Hip_Rear_A.pos = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Масштаб бедер", array_to_vec3(character.R_Leg_Upper_Twist_0.scl), 1, -100, 100)
	update = update or changed
	character.R_Leg_Upper_Twist_0.scl = vec3_to_array(vec3)

	changed, vec3 = imgui.drag_float3("Масштаб икр", array_to_vec3(character.R_Leg_Lower_Twist_0.scl), 1, -100, 100)
	update = update or changed
	character.R_Leg_Lower_Twist_0.scl = vec3_to_array(vec3)
	
	changed, vec3 = imgui.drag_float3("Масштаб стоп", array_to_vec3(character.R_Leg_Ankle.scl), 1, -100, 100)
	update = update or changed
	character.R_Leg_Ankle.scl = vec3_to_array(vec3)
end


local function headUI (character, upperbody)
	changed, vec3 = imgui.drag_float3("Масштаб головы", array_to_vec3(upperbody.Head_0.scl), 1, -100, 100)
	upperbody.Head_0.scl = vec3_to_array(vec3)
	update = update or changed	
	
	changed, vec3 = imgui.drag_float3("Масштаб лица", array_to_vec3(character.Facialjnt_Face.scl), 1, -100, 100)
	character.Facialjnt_Face.scl = vec3_to_array(vec3)
	update = update or changed	
	
	changed, vec3 = imgui.drag_float3("Верхняя часть лба", array_to_vec3(character._13C_Brow_Upper.pos), 1, -100, 100)
	update = update or changed
	character._13C_Brow_Upper.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Средняя часть лба", array_to_vec3(character._14C_Brow_Mid.pos), 1, -100, 100)
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
	
	changed, vec3 = imgui.drag_float3("Переносица", array_to_vec3(character._15C_Brow_Lower.pos), 1, -100, 100)
	update = update or changed
	character._15C_Brow_Lower.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение средней брови", array_to_vec3(character._09L_Brow_Mid_01.pos), 1, -100, 100)
	update = update or changed
	character._09L_Brow_Mid_01.pos = {vec3.x, vec3.y, vec3.z}
	character._10L_Brow_Mid_02.pos = {vec3.x, vec3.y, vec3.z}
	character._11L_Brow_Mid_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот средней брови", array_to_vec3(character._09L_Brow_Mid_01.rot), 1, -100, 100)
	update = update or changed
	character._09L_Brow_Mid_01.rot = {vec3.x, vec3.y, vec3.z}
	character._11L_Brow_Mid_03.rot = {-vec3.x, -vec3.y, -vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение нижней брови", array_to_vec3(character._05L_Brow_Lower_01.pos), 1, -100, 100)
	update = update or changed
	character._05L_Brow_Lower_01.pos = {vec3.x, vec3.y, vec3.z}
	character._06L_Brow_Lower_02.pos = {vec3.x, vec3.y, vec3.z}
	character._07L_Brow_Lower_03.pos = {vec3.x, vec3.y, vec3.z}
	character._08L_Brow_Lower_04.pos = {vec3.x, vec3.y, vec3.z}
	character._18L_EyeFat_Upper_01p.pos = {vec3.x, vec3.y, vec3.z}
	character._19L_EyeFat_Upper_02p.pos = {vec3.x, vec3.y, vec3.z}
	character._20L_EyeFat_Upper_03p.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот нижней брови", array_to_vec3(character._05L_Brow_Lower_01.rot), 1, -100, 100)
	update = update or changed
	character._06L_Brow_Lower_02.rot = {0.1*vec3.x, 0.1*vec3.y, 0.1*vec3.z}
	character._05L_Brow_Lower_01.rot = {vec3.x, vec3.y, vec3.z}
	character._07L_Brow_Lower_03.rot = {0.5 *-vec3.x, 0.5 *-vec3.y, 0.5 *-vec3.z}
	character._08L_Brow_Lower_04.rot = {0.5 *-vec3.x, 0.5 *-vec3.y, 0.5 *-vec3.z}
end

local function eyesUI (character)
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
	
	changed, vec3 = imgui.drag_float3("Положение верхнего века", array_to_vec3(character._10L_EyeFat_Upper_01.pos), 1, -100, 100)
	update = update or changed
	character._10L_EyeFat_Upper_01.pos = {vec3.x, vec3.y, vec3.z}
	character._11L_EyeFat_Upper_02.pos = {vec3.x, vec3.y, vec3.z}
	character._12L_EyeFat_Upper_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот верхнего века", array_to_vec3(character._10L_EyeFat_Upper_01.rot), 1, -100, 100)
	update = update or changed
	character._10L_EyeFat_Upper_01.rot = {vec3.x, vec3.y, vec3.z}
	character._12L_EyeFat_Upper_03.rot = {-vec3.x, -vec3.y, -vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение нижней припухлости", array_to_vec3(character._13L_EyeFat_Lower_01.pos), 1, -100, 100)
	update = update or changed
	character._13L_EyeFat_Lower_01.pos = {vec3.x, vec3.y, vec3.z}
	character._14L_EyeFat_Lower_02.pos = {vec3.x, vec3.y, vec3.z}
	character._15L_EyeFat_Lower_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот нижней припухлости", array_to_vec3(character._13L_EyeFat_Lower_01.rot), 1, -100, 100)
	update = update or changed
	character._13L_EyeFat_Lower_01.rot = {vec3.x, vec3.y, vec3.z}
	character._15L_EyeFat_Lower_03.rot = {-vec3.x, -vec3.y, -vec3.z}
	
	changed, vec3 = imgui.drag_float3("Внешний уголок глаза", array_to_vec3(character._16L_EyeOuter_Corner.pos), 1, -100, 100)
	update = update or changed
	character._16L_EyeOuter_Corner.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Внутренний уголок глаза", array_to_vec3(character._17L_EyeInner_Corner.pos), 1, -100, 100)
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
	
	if imgui.tree_node("Расширенные настройки глаз") then
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
		
		changed, vec3 = imgui.drag_float3("Верхнее веко 1", array_to_vec3(character.EyeFat_Upper_01.pos), 1, -100, 100)
		update = update or changed
		character.EyeFat_Upper_01.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Верхнее веко 2", array_to_vec3(character.EyeFat_Upper_02.pos), 1, -100, 100)
		update = update or changed
		character.EyeFat_Upper_02.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Верхнее веко 3", array_to_vec3(character.EyeFat_Upper_03.pos), 1, -100, 100)
		update = update or changed
		character.EyeFat_Upper_03.pos = {vec3.x, vec3.y, vec3.z}
		
		changed, vec3 = imgui.drag_float3("Нижняя припухлость 1", array_to_vec3(character.EyeFat_Lower_01.pos), 1, -100, 100)
		update = update or changed
		character.EyeFat_Lower_01.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Нижняя припухлость 2", array_to_vec3(character.EyeFat_Lower_02.pos), 1, -100, 100)
		update = update or changed
		character.EyeFat_Lower_02.pos = {vec3.x, vec3.y, vec3.z}
		changed, vec3 = imgui.drag_float3("Нижняя припухлость 3", array_to_vec3(character.EyeFat_Lower_03.pos), 1, -100, 100)
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
	changed, vec3 = imgui.drag_float3("Бок носа 1", array_to_vec3(character._01L_Nose_side.pos), 1, -100, 100)
	update = update or changed
	character._01L_Nose_side.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Бок носа 2", array_to_vec3(character._02L_Nose_Bridge.pos), 1, -100, 100)
	update = update or changed
	character._02L_Nose_Bridge.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Бок носа 3", array_to_vec3(character._03L_NoseBulge_Bridge.pos), 1, -100, 100)
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
	
	changed, vec3 = imgui.drag_float3("Переносица 1", array_to_vec3(character._08C_NoseBulge_Bridge.pos), 1, -100, 100)
	update = update or changed
	character._08C_NoseBulge_Bridge.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Переносица 2", array_to_vec3(character._09C_Nose_Bridge.pos), 1, -100, 100)
	update = update or changed
	character._09C_Nose_Bridge.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Спинка носа", array_to_vec3(character._10C_Nose_Spine.pos), 1, -100, 100)
	update = update or changed
	character._10C_Nose_Spine.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Кончик носа", array_to_vec3(character._11C_Nose_Tip.pos), 1, -100, 100)
	update = update or changed
	character._11C_Nose_Tip.pos = {vec3.x, vec3.y, vec3.z}
end

local function cheeksUI (character)
	changed, vec3 = imgui.drag_float3("Щека 1", array_to_vec3(character._01L_CheekFat_01.pos), 1, -100, 100)
	update = update or changed
	character._01L_CheekFat_01.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Щека 2", array_to_vec3(character._02L_CheekFat_02.pos), 1, -100, 100)
	update = update or changed
	character._02L_CheekFat_02.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Щека 3", array_to_vec3(character._03L_CheekFat_03.pos), 1, -100, 100)
	update = update or changed
	character._03L_CheekFat_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Щека 4", array_to_vec3(character._04L_CheekFat_04.pos), 1, -100, 100)
	update = update or changed
	character._04L_CheekFat_04.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Щека 5", array_to_vec3(character._05L_CheekFat_05.pos), 1, -100, 100)
	update = update or changed
	character._05L_CheekFat_05.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Щека 6", array_to_vec3(character._06L_CheekFat_06.pos), 1, -100, 100)
	update = update or changed
	character._06L_CheekFat_06.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Щека 7", array_to_vec3(character._07L_CheekFat_07.pos), 1, -100, 100)
	update = update or changed
	character._07L_CheekFat_07.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Щека 8", array_to_vec3(character._08L_CheekFat_08.pos), 1, -100, 100)
	update = update or changed
	character._08L_CheekFat_08.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Щека 9", array_to_vec3(character._09L_CheekFat_09.pos), 1, -100, 100)
	update = update or changed
	character._09L_CheekFat_09.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Скула", array_to_vec3(character._10L_CheekBone.pos), 1, -100, 100)
	update = update or changed
	character._10L_CheekBone.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Носогубная складка 1", array_to_vec3(character._11L_NosalabiaFold_01.pos), 1, -100, 100)
	update = update or changed
	character._11L_NosalabiaFold_01.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Носогубная складка 2", array_to_vec3(character._12L_NosalabialFold_02.pos), 1, -100, 100)
	update = update or changed
	character._12L_NosalabialFold_02.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Носогубная складка 3", array_to_vec3(character._13L_NosalabialFold_03.pos), 1, -100, 100)
	update = update or changed
	character._13L_NosalabialFold_03.pos = {vec3.x, vec3.y, vec3.z}
	
end

local function lipsUI (character)
	changed, vec3 = imgui.drag_float("Поворот фильтрума", character._07L_UpperLip.rot1[1], 1, -100, 100)
	update = update or changed
	character._07L_UpperLip.rot1 = {vec3, 0, 0}
	character._23C_UpperLip.rot1 = {vec3, 0, 0}
	
	changed, vec3 = imgui.drag_float3("Масштаб фильтрума", array_to_vec3(character._07L_UpperLip.scl), 1, -100, 100)
	update = update or changed
	character._07L_UpperLip.scl = {vec3.x, vec3.y, vec3.z}
	character._23C_UpperLip.scl = {vec3.x, vec3.y, vec3.z}
	
	character._20C_UpperLip_Mid_Edge.pos = {vec3.x, vec3.y, vec3.z}
	changed, vec3 = imgui.drag_float("Поворот верхней губы", character._01L_UpperLip_01_Edge.rot1[1], 1, -100, 100)
	update = update or changed
	character._01L_UpperLip_01_Edge.rot1 = {vec3, 0, 0}
	character._02L_UpperLip_02_Edge.rot1 = {vec3, 0, 0}
	character._03L_UpperLip_03_Edge.rot1 = {vec3, 0, 0}
	character._20C_UpperLip_Mid_Edge.rot1 = {vec3, 0, 0}
	
	character._04L_UpperLip_01_Volume.rot1 = {vec3, 0, 0}
	character._05L_UpperLip_02_Volume.rot1 = {vec3, 0, 0}
	character._06L_UpperLip_03_Volume.rot1 = {vec3, 0, 0}
	character._21C_UpperLip_Mid_Volume.rot1 = {vec3, 0, 0}
	
	
	changed, vec3 = imgui.drag_float3("Масштаб верхней губы", array_to_vec3(character._01L_UpperLip_01_Edge.scl), 1, -100, 100)
	update = update or changed
	character._01L_UpperLip_01_Edge.scl = {vec3.x, vec3.y, vec3.z}
	character._02L_UpperLip_02_Edge.scl = {vec3.x, vec3.y, vec3.z}
	character._03L_UpperLip_03_Edge.scl = {vec3.x, vec3.y, vec3.z}
	character._20C_UpperLip_Mid_Edge.scl = {vec3.x, vec3.y, vec3.z}
	
	character._04L_UpperLip_01_Volume.scl = {vec3.x, vec3.y, vec3.z}
	character._05L_UpperLip_02_Volume.scl = {vec3.x, vec3.y, vec3.z}
	character._06L_UpperLip_03_Volume.scl = {vec3.x, vec3.y, vec3.z}
	character._21C_UpperLip_Mid_Volume.scl = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float("Поворот нижней губы", character._11L_LowerLip_01_Edge.rot1[1], 1, -100, 100)
	update = update or changed
	character._11L_LowerLip_01_Edge.rot1 = {vec3, 0, 0}
	character._12L_LowerLip_02_Edge.rot1 = {vec3, 0, 0}
	character._13L_LowerLip_03_Edge.rot1 = {vec3, 0, 0}
	character._24C_LowerLip_Mid_Edge.rot1 = {vec3, 0, 0}
	character._14L_LowerLip_01_Volume.rot1 = {vec3, 0, 0}
	character._15L_LowerLip_02_Volume.rot1 = {vec3, 0, 0}
	character._16L_LowerLip_03_Volume.rot1 = {vec3, 0, 0}
	character._25C_LowerLip_Mid_Volume.rot1 = {vec3, 0, 0}
	
	changed, vec3 = imgui.drag_float3("Масштаб нижней губы", array_to_vec3(character._11L_LowerLip_01_Edge.scl), 1, -100, 100)
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
	changed, vec3 = imgui.drag_float3("Бок подбородка 1", array_to_vec3(character._01L_Stretch_01.pos), 1, -100, 100)
	update = update or changed
	character._01L_Stretch_01.pos = {vec3.x, vec3.y, vec3.z}
	character._02L_Stretch_02.pos = {vec3.x, vec3.y, vec3.z}
	character._03L_Stretch_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Бок подбородка 2", array_to_vec3(character._04L_Chin_01.pos), 1, -100, 100)
	update = update or changed
	character._04L_Chin_01.pos = {vec3.x, vec3.y, vec3.z}
	character._05L_Chin_02.pos = {vec3.x, vec3.y, vec3.z}
	character._06L_Chin_03.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Центр подбородка", array_to_vec3(character._07C_Chin_Mid_01.pos), 1, -100, 100)
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
	
	changed, vec3 = imgui.drag_float3("Шея 1", array_to_vec3(character._15L_Neck_01.pos), 1, -100, 100)
	update = update or changed
	character._15L_Neck_01.pos = {vec3.x, vec3.y, vec3.z}
	character._16R_Neck_01.pos = {-vec3.x, vec3.y, vec3.z}
	character._14C_Neck_01.pos = {0, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Шея 2", array_to_vec3(character._13Facialjnt1_Neck_1.pos), 1, -100, 100)
	update = update or changed
	character._13Facialjnt1_Neck_1.pos = {vec3.x, vec3.y, vec3.z}
end

local function symmetryUI (character)
	changed, vec3 = imgui.drag_float3("Положение уха", array_to_vec3(character._21L_Ear.pos), 1, -100, 100)
	update = update or changed
	character._21L_Ear.pos = {vec3.x, vec3.y, vec3.z}
	changed, vec3 = imgui.drag_float3("Положение завитка уха", array_to_vec3(character._22L_Ear_Helix.pos), 1, -100, 100)
	update = update or changed
	character._22L_Ear_Helix.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Положение брови", array_to_vec3(character._22L_Brow_Lower_01.pos), 1, -100, 100)
	update = update or changed
	character._22L_Brow_Lower_01.pos = {vec3.x, vec3.y, vec3.z}
	character._23L_Brow_Lower_02.pos = {vec3.x, vec3.y, vec3.z}
	character._24L_Brow_Lower_03.pos = {vec3.x, vec3.y, vec3.z}
	character._25L_Brow_Lower_04.pos = {vec3.x, vec3.y, vec3.z}
	
	changed, vec3 = imgui.drag_float3("Поворот брови", array_to_vec3(character._22L_Brow_Lower_01.rot), 1, -100, 100)
	update = update or changed
	character._23L_Brow_Lower_02.rot = {0.1*vec3.x, 0.1*vec3.y, 0.1*vec3.z}
	character._22L_Brow_Lower_01.rot = {vec3.x, vec3.y, vec3.z}
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
	
	changed, vec3 = imgui.drag_float3("Положение складки века", array_to_vec3(character._18L_EyeFold_01.pos), 1, -100, 100)
	update = update or changed
	character._18L_EyeFold_01.pos = {vec3.x, vec3.y, vec3.z}
	character._19L_EyeFold_02.pos = {vec3.x, vec3.y, vec3.z}
	character._20L_EyeFold_03.pos = {vec3.x, vec3.y, vec3.z}
	character._10L_EyeFat_Upper_01.pos = {vec3.x, vec3.y, vec3.z}
	character._11L_EyeFat_Upper_02.pos = {vec3.x, vec3.y, vec3.z}
	character._12L_EyeFat_Upper_03.pos = {vec3.x, vec3.y, vec3.z}
end

local function jiggleUI (character)
	imgui.begin_rect()
	imgui.text("Только для женских персонажей:")
	changed, vec = imgui.slider_int("Сила физики груди", character.breast.str, 0, 11)
	if (character.breast.str < 0 or character.breast.str > 11) then 
		character.breast.str = 0
	end
	update = update or changed
	character.breast.str = vec	
	
	changed, vec = imgui.slider_float("Дистанция физики груди", character.breast.dist, 0, 1)
	update = update or changed
	character.breast.dist = vec	
	
	changed, vec = imgui.slider_float("Затухание физики груди", character.breast.damp, 0, 10)
	update = update or changed
	character.breast.damp = vec	
	
	changed, vec = imgui.slider_float("Гравитация груди", character.breast.grav, -10, 10)
	update = update or changed
	character.breast.grav = vec	
	imgui.end_rect(2,0)
	
	imgui.new_line()

	changed, vec = imgui.slider_int("Сила физики ягодиц", character.butt.str, 0, 10)
	update = update or changed
	character.butt.str = vec
	changed, vec = imgui.slider_float("Дистанция физики ягодиц", character.butt.dist, 0, 1)
	update = update or changed
	character.butt.dist = vec
	changed, vec = imgui.slider_float("Затухание физики ягодиц", character.butt.damp, 0, 10)
	update = update or changed
	character.butt.damp = vec
	changed, vec = imgui.slider_float("Гравитация ягодиц", character.butt.grav, -10, 10)
	update = update or changed
	character.butt.grav = vec
	
	imgui.new_line()
	
	changed, vec = imgui.slider_int("Сила физики бедер", character.thigh.str, 0, 10)
	update = update or changed
	character.thigh.str = vec
	changed, vec = imgui.slider_float("Дистанция физики бедер", character.thigh.dist, 0, 1)
	update = update or changed
	character.thigh.dist = vec
	changed, vec = imgui.slider_float("Затухание физики бедер", character.thigh.damp, 0, 10)
	update = update or changed
	character.thigh.damp = vec
	
	imgui.new_line()
	
	changed, vec = imgui.slider_int("Сила физики пекторальных мышц", character.pecs.str, 0, 10)
	update = update or changed
	character.pecs.str = vec
	changed, vec = imgui.slider_float("Дистанция физики пекторальных", character.pecs.dist, 0, 1)
	update = update or changed
	character.pecs.dist = vec
	changed, vec = imgui.slider_float("Затухание физики пекторальных", character.pecs.damp, 0, 10)
	update = update or changed
	character.pecs.damp = vec
	changed, vec = imgui.slider_float("Гравитация/Упругость пекторальных", character.pecs.grav, -10, 10)
	update = update or changed
	character.pecs.grav = vec
end

local savedName1
local savedName2

local function callMenu(preset)
	if imgui.tree_node("Редактор тела") then
		armsUI(preset.body.body)
		imgui.tree_pop()
	end
	if imgui.tree_node("Редактор лица") then
		if imgui.tree_node("Форма головы / Ушей") then
				headUI(preset.face.brow, preset.body.body)
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
			
			if imgui.tree_node("Щеки") then
				cheeksUI(preset.face.cheeks)
				imgui.tree_pop()
			end
			
			if imgui.tree_node("Губы") then
				lipsUI(preset.face.lips)
				imgui.tree_pop()
			end
			
			if imgui.tree_node("Подбородок / Челюсть") then
				chinUI(preset.face.chin)
				imgui.tree_pop()
			end
			
			if imgui.tree_node("Симметрия") then
				symmetryUI(preset.face.symmetry)
				imgui.tree_pop()
			end
			imgui.tree_pop()
	end
	if imgui.tree_node("Редактор физики (Jiggle)") then
		imgui.text("[Требуется Extended Character Editor]")	
		jiggleUI(preset.jiggle.jiggle)
		imgui.tree_pop()
	end
end


re.on_draw_ui(function()	
	if imgui.tree_node("Редактор нанятых пешек") then	
		local changed
		local name1
		local name2
		
		local ispaused = sdk.get_managed_singleton("app.GuiManager"):isPausedGUI()
		
		if (updatePawn or not savedName1) and ispaused then
			print("1")
			local pawnObject
			local pawnContext
			local pawns = sdk.get_managed_singleton("app.PawnManager"):get_PawnCharacterList()
			
			if sdk.get_managed_singleton("app.PawnManager"):get_PawnCharacterList()[2] or sdk.get_managed_singleton("app.PawnManager"):getAllPartyPawn()[2]  then
				local pawn_id = sdk.get_managed_singleton("app.PawnManager"):get_SavedPartyPawnList()[1]		
				print("2")
				if pawn_id == pawns[1]:get_CharaID() then
					print("3")
					pawnContext = sdk.get_managed_singleton("app.PawnManager"):call("getPartyPawn(app.Character, System.Boolean)", pawns[1], true):get_CachedAIGoalPlanning():get_CachedPawnContext()
					name1 = pawnContext:get_Name() .. " (" .. pawnContext:get_Nickname() .. ")"
					pawnContext = sdk.get_managed_singleton("app.PawnManager"):call("getPartyPawn(app.Character, System.Boolean)", pawns[2], true):get_CachedAIGoalPlanning():get_CachedPawnContext()
					name2 = pawnContext:get_Name() .. " (" .. pawnContext:get_Nickname() .. ")"
				else
					print("4")
					pawnContext = sdk.get_managed_singleton("app.PawnManager"):call("getPartyPawn(app.Character, System.Boolean)", pawns[1], true):get_CachedAIGoalPlanning():get_CachedPawnContext()
					name2 = pawnContext:get_Name() .. " (" .. pawnContext:get_Nickname() .. ")"
					pawnContext = sdk.get_managed_singleton("app.PawnManager"):call("getPartyPawn(app.Character, System.Boolean)", pawns[2], true):get_CachedAIGoalPlanning():get_CachedPawnContext()
					name1 = pawnContext:get_Name() .. " (" .. pawnContext:get_Nickname() .. ")"
				end
			elseif sdk.get_managed_singleton("app.PawnManager"):get_PawnCharacterList()[1] or sdk.get_managed_singleton("app.PawnManager"):getAllPartyPawn()[1] then
				pawnContext = sdk.get_managed_singleton("app.PawnManager"):call("getPartyPawn(app.Character, System.Boolean)", pawns[1], true):get_CachedAIGoalPlanning():get_CachedPawnContext()
				print("5")
				name1 = pawnContext:get_Name() .. " (" .. pawnContext:get_Nickname() .. ")"
			end
			if not name1 then
				print("6")
				name1 = 'no pawn'
			end
			if not name2 then
				print("7")
				name2 = 'no pawn'
			end
			
			if not savedName1 then
				print("8")
				savedName1 = name1
			end
			if not savedName2 then
				print("9")
				savedName2 = name2
			end
			
			if savedName1 ~= name1 and savedName2 ~= 'no pawn' then
				print("10")
				presets.pawn2 = presets.pawn3
				presets.pawn3 = 1
				savedName1 = name1
				savedName2 = name2
				update = true
			elseif savedName1 ~= name1 then
				print("11")
				presets.pawn2 = 1
				savedName1 = name1
				update = true
			end
			if savedName2 ~= name2 then
				print("12")
				presets.pawn3 = 1
				savedName2 = name2
				update = true
			end
			updatePawn = false
		end
		
		config_p2 = config[presets.pawn2]
		config_p3 = config[presets.pawn3]
			if savedName1 == 'no pawn' and savedName2 == 'no pawn' then
					imgui.text("В группе нет нанятых пешек!")	
			else
				imgui.text("[Вы можете редактировать пешек в реальном времени в меню инвентаря/снаряжения]")
			
				if imgui.tree_node("Пресеты") then
					imgui.begin_rect()
					changed, preset_name = imgui.input_text("Имя нового пресета", preset_name, 1 << 4)
					if imgui.button("Создать новый пресет") then
						if preset_list[preset_name] then
							re.msg("Oshibka: Preset s takim imenem uzhe sushestvuet!")
						elseif preset_name == "" then
							re.msg("Oshibka: Ne ukazano imya preseta!")
						else
							config_filename = "HiredPawnEditor\\Presets\\"..preset_name..".json"
							preset_list[preset_name] = config_filename
							preset_names[#preset_names + 1] = preset_name
							table.insert(presets.list, preset_name)
							preset_amount = preset_amount + 1
							for i = 1,preset_amount,1 do 
								table.insert(charType_table, config[i])
							end	
							load_presets()
							save_preset()
							re.msg("Preset uspeshno sozdan!")
							update = true
						end
					end
					imgui.new_line()
					if savedName1 ~= 'no pawn' and savedName1 ~= nil then
						changed, index = imgui.combo(savedName1, presets.pawn2, preset_names)
						if changed then
							presets.pawn2 = index
							config_p2 = config[index]
							update = changed
						end
					end
					if savedName2 ~= 'no pawn' and savedName2 ~= nil then
						changed, index = imgui.combo(savedName2, presets.pawn3, preset_names)
						if changed then
							presets.pawn3 = index
							config_p3 = config[index]
							update = changed
						end
					end
					
					if imgui.tree_node("Изменить настройки пресета по умолчанию") then
						callMenu(config[1])
						imgui.tree_pop()
					end
	
					imgui.end_rect(4,2)
					imgui.tree_pop()
				end
				if (savedName1 == 'no pawn' and savedName2 == 'no pawn') or (not savedName1 and not savedName2) then
					imgui.text("В группе нет нанятых пешек!")	
				end
				if savedName1 ~= 'no pawn' and savedName1 ~= nil then
					if imgui.tree_node(savedName1) then	
						if presets.pawn2 ~= 1 then
							imgui.begin_rect()
							if imgui.button("Сохранить", 5) then 
								save_preset(presets.pawn2)
								re.msg("Izmeneniya uspeshno sohraneny!")
							end
							imgui.same_line()
							imgui.text_colored("(?)", 0xFFFFFFFF)
							if imgui.is_item_hovered() then
								imgui.set_tooltip("Примечание: изменения также автоматически сохраняются при закрытии окна REFramework.")
							end
							imgui.same_line()
							imgui.text('		')
							imgui.same_line()
							if imgui.button("Отменить") then 
								config[presets.pawn2] = json.load_file(preset_list[preset_names[presets.pawn2]])
								update = true
								re.msg("Izmeneniya otmeneny!")
							end
							imgui.same_line()
							imgui.text_colored("(?)", 0xFFFFFFFF)
							if imgui.is_item_hovered() then
								imgui.set_tooltip("Отменяет изменения, сделанные с момента последнего сохранения.")
							end
							
							callMenu(config_p2)
							imgui.end_rect(4, 3)
						else
							imgui.text("Назначьте кастомный пресет в меню пресетов")
						end
						imgui.tree_pop()
					end
				end
				if savedName2 ~= 'no pawn' and savedName2 ~= nil then
					if imgui.tree_node(savedName2) then
						if presets.pawn3 ~= 1 then
							imgui.begin_rect()
							if imgui.button("Сохранить", 5) then 
								save_preset(presets.pawn3)
								re.msg("Izmeneniya uspeshno sohraneny!")
							end
							imgui.same_line()
							imgui.text_colored("(?)", 0xFFFFFFFF)
							if imgui.is_item_hovered() then
								imgui.set_tooltip("Примечание: изменения также автоматически сохраняются при закрытии окна REFramework.")
							end
							imgui.same_line()
							imgui.text('		')
							imgui.same_line()
							if imgui.button("Отменить") then 
								config[presets.pawn3] = json.load_file(preset_list[preset_names[presets.pawn3]])
								update = true
								re.msg("Izmeneniya otmeneny!")
							end
							imgui.same_line()
							imgui.text_colored("(?)", 0xFFFFFFFF)
							if imgui.is_item_hovered() then
								imgui.set_tooltip("Отменяет изменения, сделанные с момента последнего сохранения.")
							end
							
							callMenu(config_p3)
							imgui.end_rect(4, 3)
						else
							imgui.text("Назначьте кастомный пресет в меню пресетов")
						end
						imgui.tree_pop()
					end
				end
			end
				imgui.tree_pop()
	end
end)
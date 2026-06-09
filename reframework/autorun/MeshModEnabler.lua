--Mesh Mod Enabler
--By alphaZomega
--Deactivates GpuCloth in-game for any mesh files found in Dragon's Dogma 2's 'natives' folder. Also removes 'WrapDeformers' from helms
--This allows modding of meshes that use 'gpuc' files, since their verts will explode and the game will crash if they're allowed to exist with modded meshes
--To exclude files from this script (if you want to leave Gpuc enabled), create them as pak mods
--Also supports editing the costume database using json files in the 'reframework\data\MeshModManager\Database' folder, or adding new prefabs from the 'prefabs' folder

local version = "v1.05" -- Nov 7, 2024
print("Executing Mesh Mod Enabler "..version)

--Fixed an issue with the script sometimes attempting to load before the game has loaded, which caused an error

local do_apply = true --Writes JSON files from the MeshModEnabler/database folder to objects in the game

--Converts a System.Enum into a Lua table
local function generate_statics(typename, no_reverse)
	local t = sdk.find_type_definition(typename)
	local fields = t:get_fields()
	local enum = {}
	local names = {}
	for i, field in ipairs(fields) do
		if field:is_static() then
			local raw_value = field:get_data(nil)
			if raw_value ~= nil then
				local name = field:get_name()
				enum[name] = raw_value 
				if not no_reverse then
					enum[raw_value] = name 
				end
				table.insert(names, name)
			end
		end
	end
	return enum, names
end

--Gets a dictionary from a RE Managed Object
local function get_dict(dict)
	if not dict._entries then return output end
	local output = {}
	for i, value_obj in pairs(dict._entries) do
		if value_obj.value ~= nil then
			output[value_obj.key] = output[value_obj.key] or value_obj.value
		end
	end
	return output
end

local sex_names = {"Male", "Female"}
local tops_names = {"_Bd", "_Wb", "_Am", "_Bt", "_BdSub", "_WbSub", "_AmSub", "_BtSub",}
local pants_names = {"_Lg", "_Wl", "_LgSub", "_WlSub",}

local enums = {}
local exists = {}
local jsons = {}
local add_chains = {}
local mod_json_dict = {}

for i, json_file in ipairs(fs.glob("MeshModEnabler\\\\mod\\\\.*json")) do
	local json_data = json.load_file(json_file)
	if json_data.name then
		mod_json_dict[json_data.name] = json_data
	end
end

for i, filepath in ipairs(fs.glob("MeshModEnabler\\\\database\\\\.*json")) do
	exists[filepath] = true
end

local pfb_json_dict = {
	TopsWb = 	{Chain={}, Mesh={}, Skin={}, CollisionShapePreset={}, GpuCloth={}}, 
	TopsBd = 	{Chain={}, Mesh={}, Skin={}, CollisionShapePreset={}, GpuCloth={}}, 
	TopsAm = 	{Chain={}, Mesh={}, Skin={}, CollisionShapePreset={}, GpuCloth={}}, 
	TopsBt = 	{Chain={}, Mesh={}, Skin={}, CollisionShapePreset={}, GpuCloth={}},
	PantsLg =	{Chain={}, Mesh={}, Skin={}, CollisionShapePreset={}, GpuCloth={}},
	PantsWl =	{Chain={}, Mesh={}, Skin={}, CollisionShapePreset={}, GpuCloth={}},
	Helm =		{Chain={}, Mesh={}, Skin={}, CollisionShapePreset={}, GpuCloth={}},
	Mantle = 	{Chain={}, Mesh={}, Skin={}, CollisionShapePreset={}, GpuCloth={}},
	Backpack =	{Chain={}, Mesh={}, Skin={}, CollisionShapePreset={}, GpuCloth={}},
	Facewear =	{Chain={}, Mesh={}, Skin={}, CollisionShapePreset={}, GpuCloth={}},
	Underwear =	{Chain={}, Mesh={}, Skin={}, CollisionShapePreset={}, GpuCloth={}},
}

local prefabs_glob = fs.glob("MeshModEnabler\\\\prefabs\\\\.*json")

for folder_name, type_tbl in pairs(pfb_json_dict) do
	for j, json_file in ipairs(prefabs_glob) do
		if json_file:find(folder_name.."\\") then
			for filetype, path_tbl in pairs(type_tbl) do
				local json_data = json.load_file(json_file)
				local pfb_key = (filetype=="CollisionShapePreset" and "clsp" or filetype=="GpuCloth" and "gpuc" or filetype:lower()).."_pfb_path"
				local key_id = (filetype=="Skin") and "skin_id" or "mesh_id"
				local id = json_data[key_id]
				
				if type(json_data[pfb_key]) == "string" and type(id) == "number" then
					path_tbl[id] = json_data[pfb_key]
				end
			end
		end
	end
end

local function apply_json_data(entry, filename)
	if not do_apply then return end
	local json_path = "MeshModEnabler\\database\\"..filename..".json"
	
	if exists[json_path] then
		print("Applying data from Json file:", json_path)
		local json_data = jsons[json_path] or json.load_file(json_path)
		jsons[json_path] = json_data
		
		for i, field in ipairs(entry:get_type_definition():get_fields()) do
			local fname = field:get_name()
			
			if json_data[fname] ~= nil then
				local data = json_data[fname]
				data = tonumber(data) or data
				local f_td = field:get_type()
				
				if f_td:is_a("System.Enum") then
					local f_td_name = f_td:get_full_name()
					local enum = enums[f_td_name] or generate_statics(f_td_name, true)
					enums[f_td_name] = enum
					data = enum[data] or data
					if not tonumber(data) then goto continue end
				end
				
				if f_td:is_a("System.Array") then
					local converted = {}
					for key, element in pairs(data) do
						converted[tonumber(key)+1] = element
					end
					local new_arr = sdk.create_managed_array(f_td:get_full_name():sub(1,-3), #converted):add_ref()
					for i, element in pairs(converted) do
						new_arr[i-1] = element
					end
					entry[fname] = new_arr
				elseif tonumber(data) and data > 9223372036854775807  then
					if reframework:get_commit_count() >= 1596 then
						entry[fname] = data --there was an issue with writing large uint64s before this build
					end
				else
					entry[fname] = data
				end
				::continue::
			end
		end
	end
end

local completed = {}
local subs_completed = {}
local chr_edit_mgr = sdk.get_managed_singleton("app.CharacterEditManager")

local e = {
	Tops_styles = generate_statics("app.TopsStyle"),
	Pants_styles = generate_statics("app.PantsStyle"),
	Helm_styles = generate_statics("app.HelmStyle"),
	Mantle_styles = generate_statics("app.MantleStyle"),
	Backpack_styles = generate_statics("app.BackpackStyle"),
	Facewear_styles = generate_statics("app.FacewearStyle"),
	Underwear_styles = generate_statics("app.UnderwearStyle"),
	TopsBd = generate_statics("app.CharacterEditDefine.TopsBdMeshID"),
	TopsWb = generate_statics("app.CharacterEditDefine.TopsWbMeshID"),
	TopsAm = generate_statics("app.CharacterEditDefine.TopsAmMeshID"),
	TopsBt = generate_statics("app.CharacterEditDefine.TopsBtMeshID"),
	PantsLg = generate_statics("app.CharacterEditDefine.PantsLgMeshID"),
	PantsWl = generate_statics("app.CharacterEditDefine.PantsWlMeshID"),
	Helm = generate_statics("app.CharacterEditDefine.HelmMeshID"),
	Mantle = generate_statics("app.CharacterEditDefine.MantleMeshID"),
	Backpack = generate_statics("app.CharacterEditDefine.BackpackMeshID"),
	Facewear = generate_statics("app.CharacterEditDefine.FacewearMeshID"),
	Underwear = generate_statics("app.CharacterEditDefine.UnderwearMeshID"),
}

local t = {
	Tops_mesh_entries = {[1]={}, [2]={}},
	Tops_submesh_entries = {[1]={}, [2]={}},
	Pants_mesh_entries = {[1]={}, [2]={}},
	Pants_submesh_entries = {[1]={}, [2]={}},
	Helm_mesh_entries = {[1]={}, [2]={}},
	Helm_submesh_entries = {[1]={}, [2]={}},
	Mantle_mesh_entries = {[1]={}, [2]={}},
	Backpack_mesh_entries = {[1]={}, [2]={}},
	Facewear_mesh_entries = {[1]={}, [2]={}},
	Underwear_mesh_entries = {[1]={}, [2]={}},
}

local chain_entries = {}
--local func = require("_SharedCore\\Functions")

local ran_once = false

re.on_application_entry("UpdateBehavior", function()
	
	if not ran_once then
		ran_once = true
		
		for i, sex_id in ipairs({2776536455, 1910070090}) do
			
			local sex = sex_names[i]
			
			for enum_id, entry in pairs(get_dict(chr_edit_mgr._TopsDB[sex_id])) do
				--if not do_apply then json.dump_file("MeshModEnabler\\database\\tops\\"..sex.."\\"..e.Tops_styles[entry._TopsStyle]..".json", func.convert_to_json_tbl(entry, nil, nil, nil, nil, true, true)) end
				
				for j, name in ipairs(tops_names) do
					local entries_tbl = j <= 4 and t.Tops_mesh_entries or t.Tops_submesh_entries
					local mesh_id = entry[name.."MeshID"]
					if mesh_id ~= 0 then
						local enum = e["Tops"..name:sub(2,3)]
						local mesh_name = enum[mesh_id] or mesh_id
						entries_tbl[i][mesh_name] = entries_tbl[i][mesh_name] or {}
						table.insert(entries_tbl[i][mesh_name], entry)
					end
				end
				apply_json_data(entry, "tops\\"..sex.."\\"..e.Tops_styles[entry._TopsStyle])
			end

			
			for enum_id, entry in pairs(get_dict(chr_edit_mgr._PantsDB[sex_id])) do
				--if not do_apply then json.dump_file("MeshModEnabler\\database\\pants\\"..sex.."\\"..e.Pants_styles[entry._PantsStyle]..".json", func.convert_to_json_tbl(entry, nil, nil, nil, nil, true, true)) end
				
				for j, name in ipairs(pants_names) do
					local entries_tbl = j <= 2 and t.Pants_mesh_entries or t.Pants_submesh_entries
					local mesh_id = entry[name.."MeshID"]
					if mesh_id ~= 0 then
						local enum = e["Pants"..name:sub(2,3)]
						local mesh_name = enum[mesh_id] or mesh_id
						entries_tbl[i][mesh_name] = entries_tbl[i][mesh_name] or {}
						table.insert(entries_tbl[i][mesh_name], entry)
					end
				end
				apply_json_data(entry, "pants\\"..sex.."\\"..e.Pants_styles[entry._PantsStyle])
			end
			
			for enum_id, entry in pairs(get_dict(chr_edit_mgr._HelmDB[sex_id])) do
				--if not do_apply then json.dump_file("MeshModEnabler\\database\\helms\\"..sex.."\\"..e.Helm_styles[entry._HelmStyle]..".json", func.convert_to_json_tbl(entry, nil, nil, nil, nil, true, true)) end
				
				if entry._MeshID ~= 0 then
					local mesh_name = e.Helm[entry._MeshID] or entry._MeshID
					t.Helm_mesh_entries[i][mesh_name] = t.Helm_mesh_entries[i][mesh_name] or {}
					table.insert(t.Helm_mesh_entries[i][mesh_name], entry)
				end
				if entry._SubMeshID ~= 0 then
					local mesh_name = e.Helm[entry._SubMeshID] or entry._SubMeshID
					t.Helm_submesh_entries[i][mesh_name] = t.Helm_submesh_entries[i][mesh_name] or {}
					table.insert(t.Helm_submesh_entries[i][mesh_name], entry)
				end
				apply_json_data(entry, "helms\\"..sex.."\\"..e.Helm_styles[entry._HelmStyle])
			end
			
			for enum_id, entry in pairs(get_dict(chr_edit_mgr._MantleDB[sex_id])) do
				--if not do_apply then json.dump_file("MeshModEnabler\\database\\mantles\\"..sex.."\\"..e.Mantle_styles[entry._MantleStyle]..".json", func.convert_to_json_tbl(entry, nil, nil, nil, nil, true, true)) end
				
				if entry._MeshID ~= 0 then
					local mesh_name = e.Mantle[entry._MeshID] or entry._MeshID
					t.Mantle_mesh_entries[i][mesh_name] = t.Mantle_mesh_entries[i][mesh_name] or {}
					table.insert(t.Mantle_mesh_entries[i][mesh_name], entry)
				end
				apply_json_data(entry, "mantles\\"..sex.."\\"..e.Mantle_styles[entry._MantleStyle])
			end
			
			for enum_id, entry in pairs(get_dict(chr_edit_mgr._BackpackDB[sex_id])) do
				--if not do_apply then json.dump_file("MeshModEnabler\\database\\backpacks\\"..sex.."\\"..e.Backpack_styles[entry._BackpackStyle]..".json", func.convert_to_json_tbl(entry, nil, nil, nil, nil, true, true)) end
				
				if entry._MeshID ~= 0 then
					local mesh_name = e.Backpack[entry._MeshID] or entry._MeshID
					t.Backpack_mesh_entries[i][mesh_name] = t.Backpack_mesh_entries[i][mesh_name] or {}
					table.insert(t.Backpack_mesh_entries[i][mesh_name], entry)
				end
				apply_json_data(entry, "backpacks\\"..sex.."\\"..e.Backpack_styles[entry._BackpackStyle])
			end
			
			for enum_id, entry in pairs(get_dict(chr_edit_mgr._FacewearDB[sex_id])) do
				--if not do_apply then json.dump_file("MeshModEnabler\\database\\facewear\\"..sex.."\\"..e.Facewear_styles[entry._Style]..".json", func.convert_to_json_tbl(entry, nil, nil, nil, nil, true, true)) end
				
				if entry._MeshID ~= 0 then
					local mesh_name = e.Facewear[entry._MeshID] or entry._MeshID
					t.Facewear_mesh_entries[i][mesh_name] = t.Facewear_mesh_entries[i][mesh_name] or {}
					table.insert(t.Facewear_mesh_entries[i][mesh_name], entry)
				end
				apply_json_data(entry, "facewear\\"..sex.."\\"..e.Facewear_styles[entry._Style])
			end
			
			for enum_id, entry in pairs(get_dict(chr_edit_mgr._UnderwearDB[sex_id])) do
				--if not do_apply then json.dump_file("MeshModEnabler\\database\\underwear\\"..sex.."\\"..e.Underwear_styles[entry._Style]..".json", func.convert_to_json_tbl(entry, nil, nil, nil, nil, true, true)) end
				
				if entry._MeshID ~= 0 then
					local mesh_name = e.Underwear[entry._MeshID] or entry._MeshID
					t.Underwear_mesh_entries[i][mesh_name] = t.Underwear_mesh_entries[i][mesh_name] or {}
					table.insert(t.Underwear_mesh_entries[i][mesh_name], entry)
				end
				apply_json_data(entry, "underwear\\"..sex.."\\"..e.Underwear_styles[entry._Style])
			end
		end

		for folder_name, type_tbl in pairs(pfb_json_dict) do
			for filetype, path_tbl in pairs(type_tbl) do
				local catalog_key = (folder_name == "Mantle" and filetype == "CollisionShapePreset" and "Clsp") or filetype
				
				for id, pfb_path in pairs(path_tbl) do
					for b, beast_id in ipairs({3666037007, 2501532887}) do
						local catalog_name = "_"..folder_name..catalog_key.."Catalog"
						local catalog = chr_edit_mgr[catalog_name]
						catalog = catalog and catalog[beast_id] or catalog
						
						if catalog then
							if pfb_path == "nil" then
								catalog[id] = nil
							else
								local pfb_holder = catalog[id] or sdk.create_instance("app.PrefabController"):add_ref()
								pfb_holder._Item = pfb_holder._Item or sdk.create_instance("via.Prefab"):add_ref()
								pfb_holder._Item:set_Path(pfb_path)
								catalog[id] = pfb_holder
							end
							print("\nSet " .. filetype .. " prefab entry "..catalog_name.."["..id.."]:\n", pfb_path)
							
							if filetype == "Chain" or filetype == "GpuCloth" then
								local type_name = folder_name:match("(.+)%u") or folder_name
								local mesh_name = e[folder_name][id] or id
								local loop_ct = (folder_name == "Mantle") and 1 or 2
								
								for k=1, loop_ct do
									local container = t[type_name..(k==2 and "_submesh_entries" or "_mesh_entries")] 
									local field_name = "_"..folder_name:gsub(type_name, "")..(k==2 and "SubUse" or "Use")..filetype
									
									for s, sex in ipairs(sex_names) do
										local entries = container[s][mesh_name]
										
										if entries then
											for i, entry in ipairs(entries) do
												entry[field_name] = (pfb_path ~= "nil")
												local style_id = entry["_"..type_name.."Style"]
												
												print("	Set "..sex.."."..e[type_name.."_styles"][style_id].."."..field_name, (pfb_path ~= "nil"))
											end
										end
									end
								end
							end
							if chr_edit_mgr[catalog_name] and not chr_edit_mgr[catalog_name][beast_id] then break end
						end
					end
				end
			end
		end

		for f, filepath in ipairs(fs.glob(".*mesh.2.*", "$natives")) do
			
			local lname = filepath:lower():gsub("\\", "/")
			local sex_idx = lname:find("_m") and 1 or 2
			local sex = sex_names[sex_idx]
			local sex_id = (sex_idx==1 and 2776536455) or 1910070090
			local beast_name = (lname:find("_beast") and "Beast") or "Human"
			local beast_id = (beast_name=="Beast" and 3666037007) or 2501532887
			
			local tops_name = lname:match("(tops_%d%d%d%d?.-)%.")
			
			if tops_name then
				
				local is_bd = tops_name:find("_bd")
				local is_wb = tops_name:find("_wb")
				local is_am = tops_name:find("_am")
				--local is_bt = tops_name:find("_bt")
				local entries = t.Tops_mesh_entries[sex_idx][tops_name]
				
				if entries and not completed[tops_name] then
					completed[tops_name] = true
					print("\nDisabling Mesh GpuCloth:", tops_name, sex, beast_name, lname)
					
					if is_bd then
						for i, entry in ipairs(entries) do
							entry._BdUseGpuCloth = false
							chr_edit_mgr._TopsBdGpuClothCatalog[entry._BdMeshID] = nil
							print("", e.Tops_styles[entry._TopsStyle])
						end
					elseif is_wb then
						for i, entry in ipairs(entries) do
							entry._WbUseGpuCloth = false
							chr_edit_mgr._TopsWbGpuClothCatalog[entry._WbMeshID] = nil
							print("", e.Tops_styles[entry._TopsStyle])
						end
					elseif is_am then
						for i, entry in ipairs(entries) do
							entry._AmUseGpuCloth = false
							chr_edit_mgr._TopsAmGpuClothCatalog[entry._AmMeshID] = nil
							print("", e.Tops_styles[entry._TopsStyle])
						end
					end
				end
				
				local sub_entries = t.Tops_submesh_entries[sex_idx][tops_name]
				
				if sub_entries and not subs_completed[tops_name] then
					subs_completed[tops_name] = true
					print("\nDisabling SubMesh GpuCloth:", tops_name, sex, beast_name, lname)
					
					if is_bd then
						for i, entry in ipairs(sub_entries) do
							entry._BdSubUseGpuCloth = false
							chr_edit_mgr._TopsBdGpuClothCatalog[entry._BdSubMeshID] = nil
							print("", e.Tops_styles[entry._TopsStyle])
						end
					elseif is_wb then
						for i, entry in ipairs(sub_entries) do
							entry._WbSubUseGpuCloth = false
							chr_edit_mgr._TopsWbGpuClothCatalog[entry._WbSubMeshID] = nil
							print("", e.Tops_styles[entry._TopsStyle])
						end
					elseif is_am then
						for i, entry in ipairs(sub_entries) do
							entry._AmSubUseGpuCloth = false
							chr_edit_mgr._TopsAmGpuClothCatalog[entry._AmSubMeshID] = nil
							print("", e.Tops_styles[entry._TopsStyle])
						end
					end
				end
			end
			
			local pants_name = lname:match("(pants_%d%d%d%d?.-)%.")
			
			if pants_name then
				
				local is_lg = pants_name:find("_lg")
				local is_wl = pants_name:find("_wl")
				local entries = not completed[pants_name] and t.Pants_mesh_entries[sex_idx][pants_name]
				
				if entries then
					completed[pants_name] = true
					print("\nDisabling Pants GpuCloth:", pants_name, sex, beast_name, lname)
					
					if is_lg then
						for i, entry in ipairs(entries) do
							entry._LgUseGpuCloth = false
							chr_edit_mgr._PantsLgGpuClothCatalog[entry._LgMeshID] = nil
							print("", e.Pants_styles[entry._PantsStyle])
						end
					elseif is_wl then
						for i, entry in ipairs(entries) do
							entry._WlUseGpuCloth = false
							chr_edit_mgr._PantsWlGpuClothCatalog[entry._WlMeshID] = nil
							print("", e.Pants_styles[entry._PantsStyle])
						end
					end
				end
				
				local sub_entries = not subs_completed[pants_name] and t.Pants_submesh_entries[sex_idx][pants_name]
				
				if sub_entries then
					subs_completed[pants_name] = true
					print("\nDisabling SubPants GpuCloth:", pants_name, sex, beast_name, lname)
					
					if is_lg then
						for i, entry in ipairs(sub_entries) do
							entry._LgSubUseGpuCloth = false
							chr_edit_mgr._PantsLgGpuClothCatalog[entry._LgSubMeshID] = nil
							print("", e.Pants_styles[entry._PantsStyle])
						end
					elseif is_wl then
						for i, entry in ipairs(sub_entries) do
							entry._WlSubUseGpuCloth = false
							chr_edit_mgr._PantsWlGpuClothCatalog[entry._WlSubMeshID] = nil
							print("", e.Pants_styles[entry._PantsStyle])
						end
					end
				end
			end
			
			local helm_name = lname:match("(helm_%d%d%d%d?.-)%.")
			
			if helm_name then
				for i, entries_tbl in ipairs({t.Helm_mesh_entries, t.Helm_submesh_entries}) do
			
					local entries = entries_tbl[sex_idx][helm_name]
					local completed_tbl = (i==1 and completed) or subs_completed
					
					if entries and not completed_tbl[helm_name] then
						
						completed_tbl[helm_name] = true
						print("\nDisabling "..(i==2 and "Sub" or "").."Helm GpuCloth:", helm_name, sex, beast_name, lname)
						
						for j, entry in ipairs(entries) do
							local msh_id = (i==1 and entry._MeshID) or entry._SubMeshID
							if i == 1 then
								entry._UseGpuCloth = false
							else
								entry._SubUseGpuCloth = false
							end
							chr_edit_mgr._HelmGpuClothCatalog[msh_id] = nil
							local wrap_hash = chr_edit_mgr._HelmWrapDeformerCatalogHash[msh_id]
							chr_edit_mgr._HelmWrapDeformerCatalogHash[msh_id] = nil
							if wrap_hash then
								chr_edit_mgr._HelmWrapDeformerCatalog[beast_id][sex_id][wrap_hash] = nil
							end
							if pfb_json_dict.Helm.Chain[entry._MeshID] then 
								if i == 1 then
									entry._UseChain = true
								else
									entry._SubUseChain = true
								end
							end
							print("", e.Helm_styles[entry._HelmStyle])
						end
						
						if mod_json_dict[helm_name] then
							local helm_json = mod_json_dict[helm_name]
							print("Applying helm json file", helm_name)
							for j, entry in ipairs(entries) do
								if type(helm_json.show_hair) == "boolean" then
									entry._HairDisp = helm_json.show_hair and 0 or 1
								end
								if type(helm_json.show_ears) == "boolean" then
									entry._EarDisp = helm_json.show_ears and 0 or 1
								end
								if helm_json.disable then
									if i == 1 then
										entry._MeshID = 0
									else
										entry._SubMeshID = 0
									end
								end
							end
						end
					end
				end
			end
			
			local mantle_name = lname:match("(mantle_%d%d%d%d?.-)%.")
			
			if mantle_name then
				local entries = t.Mantle_mesh_entries[sex_idx][mantle_name]
				
				if entries and not completed[mantle_name] then
					completed[mantle_name] = true
					print("\nDisabling Mantle GpuCloth:", mantle_name, sex, beast_name, lname)
					
					for i, entry in ipairs(entries) do
						entry._UseGpuCloth = false
						print("", e.Mantle_styles[entry._MantleStyle])
					end
				end
			end
		end
	end
end)
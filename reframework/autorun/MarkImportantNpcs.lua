local modname = "MarkImportantNpcs"
local configfile = modname .. ".json"
log.info("[" .. modname .. "]" .. " Start")

local _config = {
	{name = "show_names", type = "bool", default=false},
	{name = "show_circle", type = "bool", default=true},
    {name = "font_size", type = "float", default = 30},
	{name = "circle_size", type = "float", default=.05, min=0.05, max=0.2},
	{name = "y", type = "float", default = 2},
	{name = "name_color", type = "rgba32", default = 0xffa6e0dd},
	{name = "circle_color", type = "rgba32", default = 0xffe19b46}
}

local myapi = require("_XYZApi/_XYZApi")
local config = myapi.InitFromFile(_config, configfile)

local font = imgui.load_font("MarkImportantNpcs.otf",config.font_size)

local cam_mgr = sdk.get_managed_singleton("app.CameraManager")
local chr_mgr = sdk.get_managed_singleton("app.CharacterManager")
local player_list_holder = sdk.get_managed_singleton("app.CharacterListHolder")
local npc_manager = sdk.get_managed_singleton("app.NPCManager")
local camera
local cam_matrix
local contact_pt_td = sdk.find_type_definition("via.physics.ContactPoint")
local ray_result = sdk.create_instance("via.physics.CastRayResult"):add_ref()
local ray_method = sdk.find_type_definition("via.physics.System"):get_method("castRay(via.physics.CastRayQuery, via.physics.CastRayResult)")
local ray_query = sdk.create_instance("via.physics.CastRayQuery"):add_ref()
ray_query:clearOptions()
ray_query:enableAllHits()
ray_query:enableNearSort()
local filter_info = ray_query:get_FilterInfo()
filter_info:set_Group(0)
local shape_cast_result = sdk.create_instance("via.physics.ShapeCastResult"):add_ref()
local shape_ray_method = sdk.find_type_definition("via.physics.System"):get_method("castSphere(via.Sphere, via.vec3, via.vec3, System.UInt32, via.physics.FilterInfo, via.physics.ShapeCastResult)")
local shape_ray_method2 = sdk.find_type_definition("via.physics.System"):get_method("castShape(via.physics.ShapeCastQuery, via.physics.ShapeCastResult)")
local shape_cast_result = sdk.create_instance("via.physics.ShapeCastResult"):add_ref()
local sphere = ValueType.new(sdk.find_type_definition("via.Sphere"))
local box = ValueType.new(sdk.find_type_definition("via.physics.BoxShape"))
box:set_UserData(sdk.create_instance("via.physics.UserData"):add_ref())
local shape_cast_query = sdk.create_instance("via.physics.ShapeCastQuery"):add_ref()
shape_cast_query:set_Shape(box)
shape_cast_query:set_FilterInfo(filter_info)
local ray_size = 30.0

local function cast_ray(start_position, end_position, layer, maskbits, shape_radius, options, do_reverse)
	local result = {}
	local result_obj = shape_radius and shape_cast_result or ray_result
	filter_info:set_Layer(layer)
	filter_info:set_MaskBits(maskbits)
	result_obj:clear()
	if shape_radius then
		sphere:set_Radius(shape_radius)
		shape_ray_method:call(nil, sphere, start_position, end_position, options or 1, filter_info, result_obj)
	else
		ray_query:call("setRay(via.vec3, via.vec3)", start_position, end_position)
		ray_method:call(via_physics_system, ray_query, result_obj)
	end
	local num_contact_pts = result_obj:get_NumContactPoints()
	if num_contact_pts > 0 then
		for i=1, num_contact_pts do
			local new_contactpoint = result_obj:call("getContactPoint(System.UInt32)", i-1)
			local new_collidable = result_obj:call("getContactCollidable(System.UInt32)", i-1)
			local contact_pos = sdk.get_native_field(new_contactpoint, contact_pt_td, "Position")
			local game_object = new_collidable:call("get_GameObject")
			if do_reverse then
				table.insert(result, 1, {game_object, contact_pos})
			else
				table.insert(result, {game_object, contact_pos})
			end
		end
	end
	return result
end

local function is_obscured(position, start_mat, ray_layer, ray_maskbits, leeway)
	start_mat = start_mat or cam_matrix
	local ray_results = cast_ray(start_mat[3], position, ray_layer or 2, ray_maskbits or 0)
	return ray_results[1] and (start_mat[3] - ray_results[1][2]):length() + (leeway or 0.25) < (start_mat[3] - position):length()
end

local te_manager = sdk.get_managed_singleton("app.TalkEventManager")
local function is_quest_npc(npc_chara_id)
	if te_manager:isQuestTalkEventInteractableCharacter(npc_chara_id) or npc_manager:isNPCQuestLayer(npc_chara_id) then
		return true
	end
end

re.on_frame(function()
	imgui.push_font()
    local player = sdk.get_managed_singleton('app.CharacterManager'):call("get_ManualPlayer")
    camera = sdk.get_primary_camera()
    cam_matrix = camera and camera:get_GameObject():get_Transform():get_WorldMatrix()
    if not cam_matrix then return end
    local results = cast_ray(cam_matrix[3] + cam_matrix[2] * -(ray_size), cam_matrix[3] + cam_matrix[2], 3, 1, ray_size)
    if player and player_list_holder and npc_manager then
        local all_chars = player_list_holder:getAllCharacters()
        local char_count = all_chars:get_Count()
        for i = 0, char_count - 1 do
            local char = all_chars:get_Item(i)
            local char_game_object = char:get_GameObject()
            for _, result in ipairs(results) do
                if result[1] == char_game_object and not is_obscured(result[2]) then
                    local npc_data = npc_manager:getNPCData(char:get_CharaID())
					if char ~= player and is_quest_npc(char:get_CharaID()) then
						local pos = char_game_object:get_Transform():get_Position()
                        local text_pos = Vector3f.new(pos.x, pos.y+config.y, pos.z)
						if config.show_circle then draw.sphere(text_pos, config.circle_size, config.circle_color, true) end
						if config.show_names and npc_data then 
							local text = npc_data:get_Name()
							draw.world_text(text, text_pos, config.name_color) 
						end
                    end
                    break
                end
            end
        end
    end
	imgui.pop_font()
end)
myapi.DrawIt(modname, configfile, _config, config, nil, true)

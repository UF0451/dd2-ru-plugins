--[[ Coords to show
  app.CharacterPosRotContext .get_Pos()
  app.CommonPositionController .get_SearchPosition()
  app.GenerateManager .get_LoadRefPosition()
  app.LookAtRequest .get_Position()
  app.MainCameraController .get_TargetPositionPrev()
  app.TargetController .get_TargetAimPosition()

  app.Camera.get_LookAtPosition()
]]

-- convert vec3 to via.Position
--     app.Vec3Extension:getUniversalPosition(via.vec3)
--     app.WorldOffsetSystem:toUniversalPosition(via.vec3)
-- !!!! look this up --> app.GenerateUtil

local common = require("common")
local go = common.gameObjects
        

local goList = {
    {
        ["CharacterManager"] = {"app.CharacterManager", "MS"},
        ["PawnManager"] = {"app.PawnManager", "MS"},
        ["WorldOffsetSystem"] = {"app.WorldOffsetSystem", "MS"},
        ["CameraManager"] = {"app.CameraManager", "MS"},
    },
    {
        ["Character"] = {"CharacterManager", "get_ManualPlayer"},
        ["Player"] = {'CharacterManager','get_ManualPlayerPlayer'},
        ["Concierge"] = {'PawnManager','get_PawnConcierge'},
        ["MainCameraController"] = {"CameraManager", {"getMainCameraController",0}}
    },
    {
        ["LastGroundPos"] = {"Character", "get_LastGroundPosition"},
        ["MainCamera"] = {"MainCameraController", "get_Camera"}
    }

}
go.init(goList)
local coordsList = {
    {"LastGroundPosition", "Character", "get_LastGroundPosition"},
    {"get_PositionBindToWall", "Character", "get_PositionBindToWall"},
    {"get_AimTargetUniversalPosition", "Character", "get_AimTargetUniversalPosition"},
    {"getSetUpPlayerPos", "CharacterManager", "getSetUpPlayerPos"},
    {"get_LastAimLineEndPosition", "Player", "get_LastAimLineEndPosition"},
    {"get_PrevSafePosForNPC", "Player", "get_PrevSafePosForNPC"},
    {"get_CurrentTargetPos", "Concierge", "get_CurrentTargetPos"},
    {"get_CurrentTargetNodePos", "Concierge", "get_CurrentTargetNodePos"},
} 
local coordsVec3List = {
    {"get_AimTargetPosition", "Character", "get_AimTargetPosition"},
    {"get_AimTargetRootPosition", "Character", "get_AimTargetRootPosition"},
    {"get_LookAtPosition", "MainCamera", "get_LookAtPosition"}
}

local function showCoordsRow(args, _type)
    if go and go[args[2]] then 
        local posItem = common.gameObjects.getGameObject(args[2], args[3], nil)
        if _type == "vec3" then 
            posItem = go.WorldOffsetSystem:toUniversalPosition(posItem)
        end
        if posItem ~= nil and posItem["x"] and posItem["y"] and posItem["z"] then 
            imgui.table_next_row()
            imgui.table_next_column()
            imgui.text(args[1])
            imgui.table_next_column()
            imgui.text(string.format("%.2f", posItem.x))
            imgui.table_next_column()
            imgui.text(string.format("%.2f", posItem.y))
            imgui.table_next_column()
            imgui.text(string.format("%.2f", posItem.z))
        end
    end
end

re.on_draw_ui(function()
    if imgui.tree_node("Координаты") then 
        imgui.begin_table("coords",4,1,{200, 200})
        
        for i,args in ipairs(coordsList) do 
            showCoordsRow(args)
        end
        for i,args in ipairs(coordsVec3List) do
            showCoordsRow(args, "vec3")
        end
        imgui.end_table()
        if imgui.collapsing_header("DEBUG_OBJECTS") then 
            if imgui.button("init") then go.init(goList) end
            go.debugUI()
            if spawner and spawner.gm then 
                if imgui.collapsing_header("spawner") then object_explorer:handle_address(spawner.gm) end
            end
        end 
        imgui.tree_pop()
    end
end
)
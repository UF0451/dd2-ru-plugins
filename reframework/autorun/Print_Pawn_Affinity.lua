local re = re
local sdk = sdk
local imgui = imgui
local json = json

local PawnManager

PawnManager = sdk.get_managed_singleton("app.PawnManager")



local function PrintPawnFavor()
	if PawnManager == nil then PawnManager = sdk.get_managed_singleton("app.PawnManager") end
    local mainpawn = PawnManager:get_MainPawn()
	if not mainpawn then
        --print("Main pawn not found")
        return
    end
	local mpawn = mainpawn:get_CachedCharacter()
	if not mpawn then
        --print("Mpawn not found")
        return
    end
	local mainPawnDataContext = mainpawn.MainPawnDataContext
    if not mainPawnDataContext then
        --print("Main pawn's data context not found")
        return
    end
	mainpawn_affinityamount = mainPawnDataContext:get_FavorabilityRating() 
	if not mainpawn_affinityamount then
        --print("Main pawn's favorability rating not found")
        return
    end
	--print(tostring(mainpawn_affinityamount))
end

PrintPawnFavor()

local function SetMaxPawnFavor()
	if PawnManager == nil then PawnManager = sdk.get_managed_singleton("app.PawnManager") end
    local mainpawn = PawnManager:get_MainPawn()
	if not mainpawn then
        --print("Main pawn not found")
        return
    end
	local mpawn = mainpawn:get_CachedCharacter()
	if not mpawn then
        --print("Mpawn not found")
        return
    end
	local mainPawnDataContext = mainpawn.MainPawnDataContext
    if not mainPawnDataContext then
        --print("Main pawn's data context not found")
        return
    end
	local mainpawn_orgaffinityamount = mainPawnDataContext:get_FavorabilityRating() 
	mainPawnDataContext:setFavorabilityRating(1000.0)
	local mainpawn_currentaffinityamount = mainPawnDataContext:get_FavorabilityRating()
	--print(tostring(mainpawn_orgaffinityamount))
	--print(tostring(mainpawn_currentaffinityamount))
	PrintPawnFavor()
end

sdk.hook(sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),
function() 
end, function()
	PrintPawnFavor()
end)

sdk.hook(
	sdk.find_type_definition("app.SaveDataManager"):get_method("loadGameSaveData"),
	function(args)
	end,
	function(retval)
		PrintPawnFavor()
	return retval
	end
)

re.on_draw_ui(function()
    if imgui.tree_node("Просмотр симпатии главной пешки") then
        imgui.text("Главная пешка");
		imgui.spacing()
		imgui.spacing()
		imgui.text_colored(mainpawn_affinityamount, 0xFF7269C8)
		imgui.spacing()
		imgui.indent()
        imgui.text("Значения: Мин: 0.0, Макс: 1000.0, Влюблена: 620.0")
		imgui.unindent()
        imgui.separator()
		imgui.spacing()
            if imgui.button("Показать/Обновить симпатию") then
                PrintPawnFavor();
            end
			if imgui.button("Максимальная симпатия") then
                SetMaxPawnFavor();
            end
        imgui.tree_pop()
    end
end)


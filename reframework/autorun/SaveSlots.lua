local modName = "SaveSlots"

log.info("["..modName.."] loaded")


--load config file
local configFile = modName..".json"
local Config = json.load_file(configFile) or {}

if Config.Slot == nil then
	Config.Slot = 1
end
if Config.Data == nil then
	Config.Data = {}
	for i = 1, 20 do
		Config.Data[tonumber(i)] = "no save data"
	end
end


--main function
local saveDef = sdk.find_type_definition("app.SaveDataManager")

local t = os.time()

sdk.hook(saveDef:get_method("requestLoad"),
function(args)
	if sdk.to_int64(args[3]) == 1 then
		args[3] = sdk.to_ptr(Config.Slot)
	end
end,
function(retval)
	return retval
end)

sdk.hook(saveDef:get_method("requestSaveManual"),
function(args)
	if sdk.to_int64(args[3]) == 1 then
		args[3] = sdk.to_ptr(Config.Slot)
		
		t = os.time()
		Config.Data[tonumber(Config.Slot)] = os.date("%c", t)
	end
end,
function(retval)
	return retval
end)


-- Поиск пути к сохранениям
local save_path
pcall(function()
	local env = sdk.find_type_definition("System.Environment")
	if not env then return end
	local method = env:get_method("GetEnvironmentVariable")
	if not method then return end
	local user = method:call(nil, "USERPROFILE")
	if not user or user == "" then return end
	local base = user .. "\\Documents\\My Games\\Dragons Dogma 2\\Steam"
	-- Проверяем существует ли папка Steam
	pcall(function()
		local h = io.popen('dir "' .. base .. '" /b 2>nul')
		if h then
			local r = h:read("*a")
			h:close()
			if r and r ~= "" then save_path = base; return end
		end
	end)
	if save_path then return end
	-- Если папки Steam нет, проверяем Dragons Dogma 2
	pcall(function()
		local parent = user .. "\\Documents\\My Games\\Dragons Dogma 2"
		local h = io.popen('dir "' .. parent .. '" /b 2>nul')
		if h then
			local r = h:read("*a")
			h:close()
			if r and r ~= "" then save_path = parent; return end
		end
	end)
	if save_path then return end
	-- Проверяем GSE Saves (AppData)
	pcall(function()
		local appdata = method:call(nil, "APPDATA")
		if not appdata or appdata == "" then return end
		local gse = appdata .. "\\GSE Saves\\2054970\\remote\\win64_save"
		local h = io.popen('dir "' .. gse .. '" /b 2>nul')
		if h then
			local r = h:read("*a")
			h:close()
			if r and r ~= "" then save_path = gse; return end
		end
	end)
end)
if not save_path then
	save_path = "C:\\Users\\<имя>\\Documents\\My Games\\Dragons Dogma 2\\Steam\nили AppData\\Roaming\\GSE Saves\\2054970\\remote\\win64_save"
end

--gui
re.on_draw_ui(function()
    local configChanged = false
    if imgui.tree_node(modName) then
        imgui.text_colored("Путь к сохранениям:", 0xFF888888)
        imgui.same_line()
        imgui.text_colored(save_path, 0xFFAACCFF)
        imgui.separator()
        local changed = false
		
		changed, Config.Slot = imgui.slider_int("Слот сохранения", Config.Slot, 1, 20)
		configChanged = configChanged or changed
		if imgui.is_item_hovered() then
			imgui.set_tooltip(Config.Data[tonumber(Config.Slot)])
		end
		
        imgui.tree_pop();
    end
    if configChanged then
        json.dump_file(configFile, Config)
    end
end)

re.on_config_save(function()
	json.dump_file(configFile, Config)
end)
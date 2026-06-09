local modName = "QuickSave"

log.info("["..modName.."] loaded")

local found, hk = pcall(require, "Hotkeys/Hotkeys")
if not found then
	log.debug("_ScriptCore not found!")
	hk = nil
end


--load config file
local configFile = modName..".json"
local Config = json.load_file(configFile) or {}

if Config.Hotkeys == nil then
	Config.Hotkeys = {
		["AutoSave"] = "F5",
		["InnSave"] = "F8",
	}
end
if hk~=nil then
	hk.setup_hotkeys(Config.Hotkeys)
end

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


--main function
local AUTO = 0
local INN = 1
local flowMgr = sdk.get_managed_singleton("app.MainFlowManager")

re.on_application_entry("UpdateHID", function()
	if hk ~= nil then
		if hk.check_hotkey("AutoSave") then
			qSave(AUTO)
		end
		if hk.check_hotkey("InnSave") then
			qSave(INN)
		end
	end
end)

function qSave(slot)
	flowMgr:requestSaveGameData(slot, 0, 0, 0)
	flowMgr:requestSaveSystemData(0, 0, 29)
end

function qLoad(slot)
	--flowMgr:requestLoadGameData(slot) --don't use this, it crashes the game
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
		
		if hk ~= nil then
			if hk.hotkey_setter("AutoSave") then
				configChanged = true
				hk.update_hotkey_table(Config.Hotkeys)
			end
			
			if hk.hotkey_setter("InnSave") then
				configChanged = true
				hk.update_hotkey_table(Config.Hotkeys)
			end
		else
			if imgui.button("Автосохранение") then
				qSave(AUTO)
			end
			if imgui.button("В гостинице") then
				qSave(INN)
			end
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
local modname="FasterRun"
local configfile=modname..".json"
log.info("["..modname.."]".."Start")

-- §¯§Ñ§ã§ä§â§à§Û§Ü§Ú §Þ§à§Õ§Ñ §á§à§Õ§ã§ä§â§Ñ§Ú§Ó§Ñ§Ö§Þ §á§à§Õ §Ø§Ö§ã§ä§Ü§Ú§Ö §à§Ô§â§Ñ§ß§Ú§é§Ö§ß§Ú§ñ _XYZApi
local _config={
    {name="mod_enabled",type="int",default=1,min=0,max=1}, -- 0 = §£§í§Ü§Ý, 1 = §£§Ü§Ý
    {name="Speed1",type="float",default=9.0,min=0.1,max=1000.0},
    {name="Speed2",type="float",default=24.0,min=0.1,max=1000.0},
    {name="Speed3",type="float",default=30.0,min=0.1,max=1000.0},
    {name="Speed4",type="float",default=39.0,min=0.1,max=1000.0},
    {name="Speed5",type="float",default=24.0,min=0.1,max=1000.0},
}

-- §°§â§Ú§Ô§Ú§ß§Ñ§Ý§î§ß§í§Ö (§Ó§Ñ§ß§Ú§Ý§î§ß§í§Ö) §Ù§ß§Ñ§é§Ö§ß§Ú§ñ §ã§Ü§à§â§à§ã§ä§Ú §Ú§Ô§â§í §Õ§Ý§ñ §à§ä§Ü§Ñ§ä§Ñ
local vanilla_speeds = {
    [0] = 6.047,  -- §£§â§Ñ§Ù§Ó§Ñ§Ý§à§é§Ü§å
    [1] = 17.71,  -- §°§Ò§í§é§ß§Ñ§ñ §ç§à§Õ§î§Ò§Ñ
    [2] = 23.32,  -- §³§á§â§Ú§ß§ä §ã §à§â§å§Ø§Ú§Ö§Þ §Ó §â§å§Ü§Ñ§ç
    [3] = 26.92,  -- §³§á§â§Ú§ß§ä §ã §å§Ò§â§Ñ§ß§ß§í§Þ §à§â§å§Ø§Ú§Ö§Þ
    [5] = 15.98   -- §·§à§Õ§î§Ò§Ñ §Ó§à §Ó§â§Ö§Þ§ñ §Ò§à§ñ
}

-- §³§Ý§Ú§ñ§ß§Ú§Ö §æ§Ñ§Û§Ý§Ñ §Ü§à§ß§æ§Ú§Ô§å§â§Ñ§è§Ú§Ú §ã §Õ§Ö§æ§à§Ý§ä§ß§í§Þ§Ú §ß§Ñ§ã§ä§â§à§Û§Ü§Ñ§Þ§Ú
local function recurse_def_settings(tbl, new_tbl)
	for key, value in pairs(new_tbl) do
		if type(tbl[key]) == type(value) then
		    if type(value) == "table" then
			    tbl[key] = recurse_def_settings(tbl[key], value)
            else
    		    tbl[key] = value
            end
		end
	end
	return tbl
end

local config = {} 
for key,para in pairs(_config) do
    config[para.name]=para.default
end
config = recurse_def_settings(config, json.load_file(configfile) or {})

local function Log(msg)
    log.info(modname..msg)
end

local function getplayer()
    local player_man=sdk.get_managed_singleton("app.CharacterManager")
    if not player_man then return nil end
    local player=player_man:get_ManualPlayer()
    return player
end

-- §ª§ß§Ú§è§Ú§Ñ§Ý§Ú§Ù§Ñ§è§Ú§ñ §Ú §á§â§Ú§Þ§Ö§ß§Ö§ß§Ú§Ö §ã§Ü§à§â§à§ã§ä§Ú
local function Init()
    local player=getplayer()
    if player~=nil then
        local speedpara=player:get_Human():get_Param():get_Speed()
        local list=speedpara.SpeedDataList
        
        -- §±§â§à§Ó§Ö§â§ñ§Ö§Þ §ß§Ñ§ê§Ö §é§Ú§ã§Ý§à§Ó§à§Ö §å§ã§Ý§à§Ó§Ú§Ö (1 ¡ª §Ó§Ü§Ý§ð§é§Ö§ß§à, §Ó§ã§× §à§ã§ä§Ñ§Ý§î§ß§à§Ö ¡ª §Ó§í§Ü§Ý§ð§é§Ö§ß§à)
        if config.mod_enabled == 1 then
            Log(": §±§â§Ú§Þ§Ö§ß§Ö§ß§Ú§Ö §Ü§Ñ§ã§ä§à§Þ§ß§à§Û §ã§Ü§à§â§à§ã§ä§Ú")
            list[0].BaseSpeed = config.Speed1
            list[1].BaseSpeed = config.Speed2
            list[2].BaseSpeed = config.Speed3
            list[3].BaseSpeed = config.Speed4
            list[5].BaseSpeed = config.Speed5
        else
            Log(": §£§à§Ù§Ó§â§Ñ§ä §à§â§Ú§Ô§Ú§ß§Ñ§Ý§î§ß§à§Û §ã§Ü§à§â§à§ã§ä§Ú (§®§à§Õ §à§ä§Ü§Ý§ð§é§Ö§ß)")
            list[0].BaseSpeed = vanilla_speeds[0]
            list[1].BaseSpeed = vanilla_speeds[1]
            list[2].BaseSpeed = vanilla_speeds[2]
            list[3].BaseSpeed = vanilla_speeds[3]
            list[5].BaseSpeed = vanilla_speeds[5]
        end
    end
end

-- §·§å§Ü §ß§Ñ §ã§Þ§Ö§ß§å §Ý§à§Ü§Ñ§è§Ú§Ú/§ã§è§Ö§ß§í
sdk.hook(sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"), nil, Init)

-- §±§à§á§í§ä§Ü§Ñ §Ù§Ñ§Ô§â§å§Ù§Ú§ä§î api §Ú §ß§Ñ§â§Ú§ã§à§Ó§Ñ§ä§î ui
local function prequire(...)
    local status, lib = pcall(require, ...)
    if(status) then return lib end
    return nil
end

local function OnChanged()    
    Init()
end

local myapi = prequire("_XYZApi/_XYZApi")
if myapi~=nil then 
    myapi.DrawIt(modname,configfile,_config,config,OnChanged) 
end
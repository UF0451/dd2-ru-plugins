local modname="AutoLootBody"
local configfile=modname..".json"
local myapi = require("_XYZApi/_XYZApi")
local _config={
    {name="Настройки сбора",type="mutualbox"},
    {name="range",type="int",default=30,label="Радиус сбора"},
    {name="lootBody",type="bool",default=true,label="Собирать с тел"},
    {name="lootBodyPart",type="bool",default=true,label="Собирать с частей тел"},
    {name="lootDropItem",type="bool",default=true,label="Собирать выпавшие предметы"},
    {name="lootDirectItem",type="bool",default=true,label="Собирать лежащие предметы"},
    {name="lootGatherSpot",type="bool",default=true,label="Собирать точки ресурсов"},
    {name="lootSeekerToken",type="bool",default=false,label="Собирать жетоны искателя"},
    {name="lootChest",type="bool",default=false,label="Открывать сундуки"},

    {name="disableOnBattle",type="bool",default=false,label="Отключать в бою"},

    {name="Настройки сообщений",type="mutualbox"},
    {name="showLootMessage",type="bool",default=true,label="Показывать сообщения"},
    {name="messageFontsize",type="fontsize",default=30,label="Размер шрифта"},
}   
local config= myapi.InitFromFile(_config,configfile)
local msgTime=120
local posDelta=2/(msgTime)
local colorDelta=math.floor(0xff000000/msgTime)&0xff000000
local rangeSq=config.range*config.range

local waitingBodyControllerList={}
local lootMessageList={}
local gimmickManager = sdk.get_managed_singleton("app.GimmickManager")
local battleManager = sdk.get_managed_singleton("app.BattleManager")
local playerManager=sdk.get_managed_singleton("app.CharacterManager")

local font = imgui.load_font("times.ttf", config.messageFontsize)

local function Log(...)
    print(...)
    for k,v in ipairs{...} do
        log.info("["..modname.."]"..tostring(v))
    end
end

local function refreshplayer()
    playerManager=sdk.get_managed_singleton("app.CharacterManager")
end
sdk.hook(sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),nil,
function ()
    refreshplayer()
    waitingBodyControllerList={}
    lootMessageList={}
end
)
refreshplayer()

local function getCharacterPos(char)
    local joint=char:get_GameObject():get_Transform():getJointByName("Head_0")
    local ground_joint=char:get_GameObject():get_Transform():getJointByName("root")
    if joint == nil then
        return ground_joint:get_Position()
    end
    if joint:get_Position().y - ground_joint:get_Position().y >2 then
        return ground_joint:get_Position()
    end
    return joint:get_Position()
end

local function AddMessage(msg,pos)
    if config.showLootMessage then
        local lootMsg={
            msg=msg,
            pos=pos,
            color=0xffeeeeee
        }
        lootMessageList[lootMsg]=msgTime
    end
end

local function DistanceSq(r)
    local player = playerManager:get_ManualPlayer()
    if player == nil or player:get_GameObject() == nil then 
        return 0
    end
    local l = player:get_GameObject():get_Transform():getJointByName("root"):get_Position()
    return (l.x-r.x)*(l.x-r.x)
           +(l.y-r.y)*(l.y-r.y)
           +(l.z-r.z)*(l.z-r.z)
end

local function DistanceSqGimmick(gimmick)
    return DistanceSq(gimmick:getPos(gimmick:get_GameObject()))
end

local function LootBody(deadBodyController)
    if deadBodyController==nil or (not sdk.is_managed_object(deadBodyController)) or deadBodyController:get_IsEnablePickup()==false then
        waitingBodyControllerList[deadBodyController]=nil
        return
    end
    
    local distance=deadBodyController.InteractiveObject:getDistanceSqFromPlayer(0)
    if distance~=0.0 and distance<rangeSq then
        local pos=getCharacterPos(deadBodyController.Chara)
        local ct=0

        local maxNum=deadBodyController.GatherContext._Num
        if deadBodyController.ItemDropInfo~=nil then
            local lotlist=deadBodyController.ItemDropInfo._LotList
            for i=0,lotlist:get_Count()-1 do
                if maxNum<lotlist[i]._Num then
                    maxNum=lotlist[i]._Num
                end
            end
        end
        
        while deadBodyController:get_IsEnablePickup()==true and deadBodyController:isInteractEnable(0) and ct<50 and ct<maxNum do
            deadBodyController:executeInteract(0, playerManager:get_ManualPlayer())
            ct=ct+1
        end

        AddMessage("Loot "..ct,pos)
        waitingBodyControllerList[deadBodyController]=nil
    end
end

local function LootBodyPart(dropPartsController)
    if dropPartsController==nil 
        or (not sdk.is_managed_object(dropPartsController)) 
        or (not dropPartsController:get_DropObject()) 
        or (not dropPartsController:get__DropPartsContext()) then
        waitingBodyControllerList[dropPartsController]=nil
        return
    end
    
    local interObject=dropPartsController:get_DropObject()

    if dropPartsController.PartsRoot==nil then
        waitingBodyControllerList[dropPartsController]=nil
        return
    end

    local distance=DistanceSq(dropPartsController.PartsRoot:get_Position())

    if  distance~=0.0 and distance<rangeSq then
        local pos=interObject:getInteractPointPosition(0)
        local ct=0

        local maxNum=dropPartsController:getDropItemData().Item2

        while ct<20 and ct<maxNum do
            dropPartsController:executeInteract(0, playerManager:get_ManualPlayer())
            ct=ct+1
        end
        if maxNum>0 then
            dropPartsController:unregisterInteractiveObject()
        end
        AddMessage("Loot "..ct,pos)
        waitingBodyControllerList[dropPartsController]=nil
    end
end

local function LootBodyOrBodyPart(controller)
    if controller:get_type_definition():is_a("app.DropPartsController") then
        LootBodyPart(controller)
    elseif controller:get_type_definition():is_a("app.SearchDeadBodyInteractController") then
        LootBody(controller)
    else
        waitingBodyControllerList[controller]=nil
    end
    if waitingBodyControllerList[controller]~=nil then
        waitingBodyControllerList[controller] = waitingBodyControllerList[controller]-1
        if waitingBodyControllerList[controller] < -7200 then
            waitingBodyControllerList[controller]=nil  
        end
    end
end

local function LootGm82_009(gimmick)
    if gimmick:isInteractEnable(0)==true then
        local distance=DistanceSqGimmick(gimmick)
        if distance~=0.0 and distance<rangeSq then
            gimmick:onExecuteInteractBase(0, playerManager:get_ManualPlayer())
            AddMessage("Loot 1",gimmick:get_GameObject():get_Transform():get_Position())
        end
    end
end

local function LootGm82_000_001(gimmick)
    if gimmick:isInteractEnable(0)==true then
        local distance= DistanceSqGimmick(gimmick)
        if distance~=0.0 and distance<rangeSq then
            local msg="Loot "..gimmick:getItemNum()
            gimmick:onStartInteractBase(0, playerManager:get_ManualPlayer())
            AddMessage(msg,gimmick:get_GameObject():get_Transform():get_Position())
        end
    end
end

local function LootGm82_000(gimmick)
    if gimmick:isInteractEnable(0)==true then
        local distance = DistanceSqGimmick(gimmick)
        if distance~=0.0 and distance<rangeSq then
            local msg="Loot "..gimmick:getItemNum()
            gimmick:requestForceInteract(0, playerManager:get_ManualPlayer())
            AddMessage(msg,gimmick:get_GameObject():get_Transform():get_Position())
            return true
        end
    end
    return false
end

local function LootGm82_036(gimmick)
    if gimmick:isInteractEnable(0)==true then
        local distance = DistanceSqGimmick(gimmick)
        if distance~=0.0 and distance<rangeSq then
            gimmick:requestForceInteract(0, playerManager:get_ManualPlayer())
            AddMessage("Loot Seeker's Token",gimmick:get_GameObject():get_Transform():get_Position())
            return true
        end
    end
    return false
end

local function LootGm80_001(gimmick)
    if gimmick:isInteractEnable(0)==true then
        local distance = DistanceSqGimmick(gimmick)
        if distance~=0.0 and distance<rangeSq then
            gimmick:onExecuteInteractBase(0, playerManager:get_ManualPlayer())
            gimmick:open(true, playerManager:get_ManualPlayer())
            AddMessage("Loot Chest",gimmick:get_GameObject():get_Transform():get_Position())
            return true
        end
    end
    return false
end

local interval=0
sdk.hook(
    sdk.find_type_definition("app.InteractManager"):get_method("onUpdate()"),
    function()
        if config.disableOnBattle and battleManager:get_IsBattleMode() then return end
        interval = interval+1
        if interval >30 then
            for k,v in pairs(waitingBodyControllerList) do
                if waitingBodyControllerList[k]<=0 then
                    LootBodyOrBodyPart(k)
                else
                    waitingBodyControllerList[k]=waitingBodyControllerList[k]-1
                end
            end
            interval=0
        end
    end,
    nil
)

local getGimmickListMethod=sdk.find_type_definition("app.GimmickManager"):get_method("getGimmickList(app.GimmickID)")
local gimmick82_036=sdk.find_type_definition("app.GimmickID"):get_field("Gm82_036"):get_data(nil)
local gimmick82_000=sdk.find_type_definition("app.GimmickID"):get_field("Gm82_000"):get_data(nil)

local interval2=0
sdk.hook(
    sdk.find_type_definition("app.GimmickManager"):get_method("lateUpdate()"),
    function()
        if config.disableOnBattle and battleManager:get_IsBattleMode() then return end
        interval2 = interval2+1
        if interval2 >90 then
            if config.lootGatherSpot then
                local gimmicks=gimmickManager:get_CollectionGimmicks()
                local g_ct=gimmicks:get_Count()-1
                for i=0,g_ct do
                    LootGm82_009(gimmicks[i])
                end
            end
            if config.lootDropItem then
                local gimmicks=gimmickManager:get_DropItemGimmicks()
                local g_ct=gimmicks:get_Count()-1
                for i=0,g_ct do
                    LootGm82_000_001(gimmicks[i])
                end
            end
            if config.lootDirectItem then
                local gimmicks=getGimmickListMethod(gimmickManager,gimmick82_000)
                local g_ct=gimmicks:get_Count()-1
                for i=0,g_ct do
                    if LootGm82_000(gimmicks[i]) then
                        break
                    end
                end
            end
            if config.lootSeekerToken then
                local gimmicks=getGimmickListMethod(gimmickManager,gimmick82_036)
                local g_ct=gimmicks:get_Count()-1
                for i=0,g_ct do
                    if LootGm82_036(gimmicks[i]) then
                        break
                    end
                end
            end
            if config.lootChest then
                local gimmicks=gimmickManager:get_TreasureBoxGimmicks()
                local g_ct=gimmicks:get_Count()-1
                for i=0,g_ct do
                    if LootGm80_001(gimmicks[i]) then
                        break
                    end
                end
            end
            interval2=0
        end
    end,
    nil
)

sdk.hook(
    sdk.find_type_definition("app.SearchDeadBodyInteractController"):get_method("setupInteractiveObject()"),
    function(args)
        local this=sdk.to_managed_object(args[2])
        if this:get_IsEnablePickup() and config.lootBody then
            waitingBodyControllerList[this] = 1
        end
    end,
    nil
)

sdk.hook(
    sdk.find_type_definition("app.DropPartsController"):get_method("onPartsBroken(via.GameObject, System.Boolean)"),
    function(args)
        local this=sdk.to_managed_object(args[2])
        if config.lootBodyPart and this:getDropItemData().Item2>=0 then
            waitingBodyControllerList[this] = 1
        end
    end,
    nil
)
sdk.hook(
    sdk.find_type_definition("app.DropPartsController"):get_method("setupInteractiveObject"),
    function(args)
        local this=sdk.to_managed_object(args[2])
        if config.lootBodyPart and this:getDropItemData().Item2>=0 then
            waitingBodyControllerList[this] = 1
        end
    end,
    nil
)

re.on_frame(function()
    if config.showLootMessage==true then
        imgui.push_font(font)
        for lootMessage,v in pairs(lootMessageList) do
            if lootMessage.msg~=nil then
                draw.world_text(lootMessage.msg,lootMessage.pos,lootMessage.color)
            end
            lootMessageList[lootMessage]=lootMessageList[lootMessage]-1
            lootMessage.pos.y=lootMessage.pos.y+posDelta
            lootMessage.color=lootMessage.color-colorDelta
            if lootMessageList[lootMessage] < 0 then
                lootMessageList[lootMessage]=nil
            end    
        end
        imgui.pop_font()
    end
end)

myapi.DrawIt(modname,configfile,_config,config,function () 
    rangeSq=config.range*config.range
end)
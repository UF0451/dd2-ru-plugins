local common = require('EnemySpawner/common')

local PostProcItem = {}
PostProcItem.__index = PostProcItem
function PostProcItem:new(fName, _limit, _delay)
    local ppi = {}
    setmetatable(ppi,PostProcItem)
    ppi.limit = _limit or 10
    ppi.attempts = 0
    ppi.fName = fName
    ppi.delay = _delay or 0
    ppi.addAttempt = function(self)
        self.attempts = self.attempts + 1
    end
    ppi.isDelayComplete = function(self)
        return self.delay == 0 or self.attempts >= self.delay
    end
    ppi.isExhausted = function(self)
        return self.attempts >= self.limit 
    end
    return ppi
end

local SpawnInstance = {}
SpawnInstance.__index = SpawnInstance
--[[
    STATUS  DESC
    0       initial/reset
    1       setup
    2       spawn requested
    3       spawn prefab not ready
    4       spawn complete
    5       error
]]
function SpawnInstance:new(char, charID, pfbCtrl, genWrap, container, rid, config, pos, rot) --, tm)
    local si = {}
    setmetatable(si,SpawnInstance)
    si.status = 0
    si.char = char or nil
    si.charID = charID or nil
    si.config = config or {}
    --si.tm = tm or nil
    si.instance = sdk.create_instance("app.InstanceInfo"):add_ref()
    --si.container = container or sdk.create_instance("app.GenerateInfo.GenerateInfoContainer"):add_ref()
    si.container = container or si.instance:get_Container()
    si.prefabCtrl = pfbCtrl or nil
    si.requestID = rid or nil
    si.genIdWrapper = genWrap or nil
    si.postProc = {}
    si.genCat = 3
    si.pos = pos or nil
    si.rot = rot or nil
    si.fPreSpawn = nil
    si.fPostSpawn = nil
    return si
end
-- SpawnInstance.toast = function(self, msg, _type)
--     if self.tm then 
--         self.tm:toast("[SpawnInstance]"..msg, _type)
--     end
-- end
SpawnInstance.addPostProc = function(self, pp)
    table.insert(self.postProc, pp)
end
SpawnInstance.hasPostProc = function(self)
    return #self.postProc > 0
end
SpawnInstance.setPostProcs = function(self)
    --self:toast("setupPostProcs")
    if self.config then
        if self.config.normalizeSpeed and self.config.ovrScale.scale ~= 1 then 
            --self:toast("setupPostprocs -> add normalizeSpeed")
            table.insert(self.postProc, PostProcItem:new("normalizeSpeed"))
        end
        if self.config.postProcScale and self.config.ovrScale.scale ~= 1.000 then
            table.insert(self.postProc, PostProcItem:new("postProcScale",20,10))
        end
        -- if self.char and self.char:match("ch%d%d%d") == 'ch230' then
        --     --self:toast("setupPostprocs -> add dress")
        --     table.insert(self.postProc, PostProcItem:new("dress"))
        -- end
        -- if self.config.bigHead then 
        --     --self:toast("setupPostprocs -> add bighead")
        --     table.insert(self.postProc, PostProcItem:new("bigHead"))
        -- end
        -- if self.char and self.char:match("ch%d%d%d") == 'ch220' then
        --     --self:toast("setupPostprocs -> add ch220")
        --     table.insert(self.postProc, PostProcItem:new("buildParts220"))
        -- end
    end
end
SpawnInstance.isPrefabReady = function(self)
    if self.prefabCtrl and self.prefabCtrl:get_Item() then 
        return self.prefabCtrl:get_Item():get_Ready() 
    end 
    return false
end
SpawnInstance.isNPC = function(self)
    if self.char and string.sub(self.char ,3,3) == '3' then
        --self:toast("isNPC")
        return true 
    end
    return false
end
SpawnInstance.isHuman = function(self)
    if self.char and 
        (self:isNPC() or string.sub(self.char ,3,5) == "230") then
        --self:toast("isHuman")
        return true 
    end
    return false
end
SpawnInstance.isAnimal = function(self)
    if self.char and string.sub(self.char ,3,5) == '299' then
        --self:toast("isAnimal")
        return true 
    end
    return false
end

--INITIALIZE 
SpawnInstance.init = function(self)
    --self:toast("SpawnInstance Init")
    if self.prefabCtrl then 
        self.prefabCtrl:get_Item():set_Standby(true)
    end
    if self.genIdWrapper then 
        --self:toast("getGenWrapper 2")
        self.container._CommonInfo:set_ObjectID(sdk.to_ptr(self.genIdWrapper))
        --self:toast(string.format("genIDWrap used for ObjID: %d %s",
            -- self.container._CommonInfo._ObjectID._SelectedCharacterID,
            -- self.container._CommonInfo._ObjectID._Hash
            -- ))
    else 
        --self:toast("using charID for _SelectedCharacterID")
        self.container._CommonInfo._ObjectID._SelectedCharacterID = self.charID
    end
    self.container._CommonInfo:setContextPosition(self.pos)
    self.container._CommonInfo:setContextAngle(self.rot)
    if self.config and self.config.ovrScale and self.config.ovrScale.enable then 
        print(string.format("OVERRIDING SCALE: %.2f", self.config.ovrScale.scale or 1.000 ))
        self.container._StatusInfo["<ScaleRate>k__BackingField"] = self.config.ovrScale.scale or 1.000
    end
    if self.config and self.config.spawnIdle then 
        self.container._CharaInfo._IsThinkStop = self.config.spawnIdle
    end
    -- if self.config and self.config.initSet > 1 then 
    --     self.container._CommonInfo._InitSetType = self.config.initSet
    -- end
    self.status = 1
    --print(string.format("SpawnInstance.RequestID: %s", self.RequestID))
    self:setPostProcs()

end
SpawnInstance.initRepl = function(self)
    if self.prefabCtrl then 
        self.prefabCtrl:get_Item():set_Standby(true)
    end
    if self.config and self.config.ovrScale and self.config.ovrScale.enable then 
        print(string.format("OVERRIDING SCALE: %.2f", self.config.ovrScale.scale or 1.000 ))
        self.container._StatusInfo["<ScaleRate>k__BackingField"] = self.config.ovrScale.scale or 1.000
    end
    -- print(string.format("ScaleOvr: %s, scale: %.2f, ScaleRate: %.2f", 
    --     self.config.ovrScale.enable, 
    --     self.config.ovrScale.scale, 
    --     self.container._StatusInfo["<ScaleRate>k__BackingField"]
    --     )
    -- )
    self.status = 1
    --print(string.format("SpawnInstance.RequestID: %s", self.RequestID))
    self:setPostProcs()
end

--DESTROY
SpawnInstance.destroy = function(self)
    local s,e = pcall(function() 
        if self.instance and self.instance ~= nil then 
            local go = self.instance:get_Instance()
            if go and go ~= nil then
                go:destroy(go) 
            end
            self.instance:release() 
        end
        if self.container then self.container:release() end
    end)
end

local SpawnRequest = {}
SpawnRequest.__index = SpawnRequest
--[[
    STATUS  DESC
    0       initial/reset
    1       setup
    2       spawn requested
    3       spawn prefab not ready
    4       spawn complete
]]
function SpawnRequest:new()--tm) 
    local sr = {}
    setmetatable(sr,SpawnRequest)
    --ATTRIBUTES
    sr.gm = sdk.get_managed_singleton("app.GenerateManager")
    sr.instInfoMngr = nil
    sr.npcMgr = sdk.get_managed_singleton("app.NPCManager")
    sr.instances = {}
    --sr.tm = tm or nil -- Optional toastManager Reference
    sr.enums = {
        ["charID"] = common.enumHelper:getTranslations("app.CharacterID"),
        ["gmckID"] = common.enumHelper:getTranslations("app.GimmickID"),
        ["helm"] = common.enumHelper:getTranslations("app.HelmStyle"),
        ["tops"] = common.enumHelper:getTranslations("app.TopsStyle"),
        ["pants"] = common.enumHelper:getTranslations("app.PantsStyle"),
        ["capes"] = common.enumHelper:getTranslations("app.MantleStyle"),
    }
    sr.catalogs = {
        ["Enemy"] = sr.gm._CatalogCtrl._EnemyCatalog:get_field("<MergedCatalog>k__BackingField")
        
    }
    sr.config = {
        ["spawnIdle"] = true,
        ["instLimit"] = 50,
        ["spawnMultiple"] = {
            ["enable"] = false,
            ["qty"] = 1
        }
    }
    sr.instanceCounts = {1,2,3,4,5}
    sr.charData = nil
    return sr
end

-- DEBUG METHODS (NOT FOR DIST)
-- SpawnRequest.getGenTables = function(self)
--     self.genTables["ichikawa_chicken"] = self.gm:call("getTable(app.GenerateTableName)",2)
--     self.genTables["Table0000"] = self.gm:call("getTable(app.GenerateTableName)",4)
--     self.genTables["Table0001"] = self.gm:call("getTable(app.GenerateTableName)",5)
--     self.genTables["Table0121"] = self.gm:call("getTable(app.GenerateTableName)",125)
--     self.genTables["FrontTable000"] = self.gm:call("getTable(app.GenerateTableName)",379)
--     self.genTables["BackTable000"] = self.gm:call("getTable(app.GenerateTableName)",392)
--     self.genTables["NPCTable000"] = self.gm:call("getTable(app.GenerateTableName)",413)
--     self.genTables["NPCTable000"] = self.gm:call("getTable(app.GenerateTableName)",452)
-- end

-- METHODS
-- SpawnRequest.toast = function(self, msg, _type)
--     if self.tm then 
--         self.tm:toast("[SpawnRequest]"..msg, _type)
--     end
-- end
SpawnRequest.getInstInfoMngr = function(self)
    if self.instInfoMngr == nil and self.gm ~= nil then 
        self.instInfoMngr = self.gm:get_InstanceInfoManager()
    end
end
SpawnRequest.getInstCatCount = function(self, cat)
    local _count = 0
    if not self.instInfoMngr then 
        self:getInstInfoMngr()
    elseif cat and cat > 0 then 
        _count = self.instInfoMngr:getInstanceCount(cat)
    end
    return _count
end
SpawnRequest.updateInstanceCounts = function(self)
    for i,_ in ipairs(self.instanceCounts) do 
        self.instanceCounts[i] = self:getInstCatCount(i+1)
        ----self:toast(string.format("[%d][%d]",i,self:getInstCatCount(i+1)))
    end
end
SpawnRequest.hasAnyOutstandingPostProc = function(self)
    if self.instances and #self.instances > 0 then 
        for _,inst in pairs(self.instances) do 
            if inst:hasPostProc() then return true end
        end
    end
    return false
end
SpawnRequest.deleteAllCategory = function(self, cat)
    if cat and cat > 1 and self.gm then 
        self.gm._InstanceInfoManager:requestDestroyAllInstance(cat)
        --self.gm:requestDestroy(cat, false)
    end
end
SpawnRequest.deleteLast = function(self)
    if self.instances and #self.instances > 0 then 
        local inst = table.remove(self.instances)
        --inst:destroy()
        local s,e = pcall(function() inst:destroy() end)
    end
end
SpawnRequest.deleteOldest = function(self)
    if self.instances and #self.instances > 0 then 
        local inst = table.remove(self.instances, 1)
        inst:destroy()
    end
end
SpawnRequest.deleteAll = function(self)
    while #self.instances > 0 do self:deleteLast() end   
end
SpawnRequest.updateConfig = function(self, config)
    if config then self.config = config end
end
SpawnRequest.processPostProc = function(self)
    for _,inst in pairs(self.instances) do 
        if inst:hasPostProc() then 
            for i,pp in pairs(inst.postProc) do 
                if pp:isDelayComplete() and (not self[pp.fName](self, inst) or pp:isExhausted()) then 
                    table.remove(inst.postProc, i) 
                    --print("complete postproc: " .. pp.fName)
                else
                    pp:addAttempt()
                    --print(string.format("%s %d/%d postproc: %s",pp:isDelayComplete() and "retry" or "delay", pp.attempts, pp.limit, pp.fName))
                end
            end
        end
    end
end
-- NOT WORKING
SpawnRequest.bigHead = function(self,inst)
    -- --self:toast("Start BigHead postProcess")
    -- local char = nil
    -- local headScale = nil
    -- if inst and inst.instance then 
    --     char = inst.instance:get_Chara()
    --     if char ~= nil then 
    --         head = char:get_field("Head")
    --         if head ~= nil then 
    --             sdk.hook_vtable(
    --                 inst.instance:get_Chara():get_field("Head"),
    --                 sdk.find_type_definition('via.Joint'):get_method('get_LocalScale'),
    --                 function(args)
    --                     --self:toast("[VHOOK] get_LocalScale")
    --                     --return sdk.PreHookResult.SKIP_ORIGINAL
    --                 end,
    --                 function(retval) return retval end
    --             )
    --             headScale = head:get_LocalScale()
    --             headScale.x = 2.000
    --             headScale.y = 2.000
    --             headScale.z = 2.000
    --             head:set_LocalScale(headScale)
    --             if headScale ~= nil and headScale.x and headScale.y and headScale.z then 
    --                 --self:toast(string.format("Initial scale for bigHead: %.0f, %.0f, %.0f", headScale.x, headScale.y, headScale.z))
                    
    --                 head:set_LocalScale(headScale)
    --                 --self:toast(string.format("actual scale for bigHead: %.0f, %.0f, %.0f", headScale.x, headScale.y, headScale.z))
    --                 return false
    --             end
    --         end
    --     end
    -- end
    return true
end
SpawnRequest.normalizeSpeed = function(self, inst)
    local char = nil
    local thisScale = nila
    local spdCtrl = nil
    local wr = nil
    if inst ~= nil and inst.instance ~= nil and inst.instance['<Chara>k__BackingField'] ~= nil then
        print("Instance")
        char = inst.instance:get_Chara()
        if char ~= nil then 
            thisScale = char:get_Transform():get_Scale()
            local spdCtrl = spdCtrl or char:get_field('SpeedController')
            if spdCtrl ~= nil then 
                local wr = spdCtrl:get_field('Rate')
                if wr ~= nil and thisScale ~= nil and thisScale.x then 
                    local adjWR = 1/thisScale.x
                    if adjWR > 2 then adjWR = 2.000
                    elseif adjWR < 0.4 then adjWR = 0.400 end
                    print(string.format("[thisScale] %s, [adjWR] %s", tostring(thisScale), tostring(adjWR)))
                    wr:set_field('UseParentRate', true)
                    wr:set_field('Calculated', false)
                    wr:set_field('NextApplyRate', adjWR)
                    wr:set_field('<ParentRateWhenCreating>k__BackingField', adjWR)
                    wr:set_field('NextRateValue', adjWR)
                    return false
                end
            end
        end
    end    
    return true  
end
SpawnRequest.postProcScale = function(self, inst)
    if inst ~= nil and inst.instance ~= nil and inst.instance['<Instance>k__BackingField'] ~= nil then
        go = inst.instance:get_Instance()
        if go ~= nil then 
            goTrans = go:get_Transform()
            if goTrans ~= nil then 
                
                v3Scale = Vector3f.new(
                    inst.config.ovrScale.X or inst.config.ovrScale.scale or 1.000, 
                    inst.config.ovrScale.Y or inst.config.ovrScale.scale or 1.000,
                    inst.config.ovrScale.Z or inst.config.ovrScale.scale or 1.000
                    )
                -- print(string.format("New Scale: %.2f, %.2f, %.2f", 
                --     v3Scale.x, 
                --     v3Scale.y, 
                --     v3Scale.z
                -- ))
                goTrans:set_LocalScale(v3Scale)
                --print("goTrans:set_LocalScale")
                --cTrans:set_field("LocalScale", v3Scale)
                return false
            end
        end
    end
    return true
end
SpawnRequest.dress = function(self, inst)
    local char = nil
    --self:toast("buildParts230 START")

    if inst and inst.instance then 
        char = inst.instance:get_Chara()
        if char ~= nil then 
            if self.charData == nil then 
                self.charData = self.npcMgr:getNPCData(char:get_CharaID())
            end
            local chCtrl = char:get_CharaEditWarpController()
            -- if chCtrl then 
            --     chCtrl:call("<buildPartsFromCh230>b__28_1")
            --     --self:toast("buildParts230 THROUGH")
            -- end
            local ps = char:get_HumanPartSwapper()
            if chCtrl ~= nil and ps ~= nil then
                --chCtrl:commonBuildPartsPrepare(false)
                --chCtrl:call('buildPartsFromContext(System.Byte)', 1)
                --ps._Meta._HelmStyle = self.enums["helm"]['byIndexV'][10]
                --ps._Meta._TopsStyle = self.enums["tops"]['byName']['Tops_4000']
                --ps._Meta._PantsStyle = self.enums["pants"]['byName']['Pants_4000']
                --ps._Meta._MantleStyle = self.enums["capes"]['byIndexV'][10]
                -- print(
                --     tostring(self.enums["tops"]['byName']['Tops_4000']),
                --     tostring(self.enums["pants"]['byName']['Pants_4000'])
                -- )
                ps:requestSwap()
                --self:toast("buildParts230 THROUGH")
                return false
            end
        end
    end
    return true
end
SpawnRequest.buildParts220 = function(self, inst)
    --self:toast("buildParts220 ATTEMPT")
    if inst and inst.instance then 
        local char = inst.instance:get_Chara()
        if char then 
            local cewc = char:get_CharaEditWarpController()
            if cewc then 
                --cewc:call("<buildPartsFromCh220>b__27_0(via.GameObject)", inst.instance:get_Instance())
                --cewc:call("buildPartsFromCh220(System.UInt16, System.UInt16, System.UInt16)", 1, 1, 1)
                --self:toast("buildParts220 THROUGH")
                return false
            end
        end
    end
    return true
end
--[[ 
    FORCE CLIMB not currently working correctly
]]
SpawnRequest.forceClimb = function(self, inst)
    local char = nil
    if inst and inst.instance then 
        char = inst:get_Chara()
        if char ~= nil then 
            --setup climber object
            local objClimber = char:get_ClimbCtrl()
            --disable carry object
            --local objCarry = char:get_ObjectCarry()
            -- change valid caught types
            char:set_field('<ValidCaughtTypes>k__BackingField', 3)
            --objCarry:set_IsActive(false)
            -- need to call on char --> set_RequestClimbCoord(app.ObjectClimber.TargetCood)
            --local OCTCood = sdk.create_instance("app.ObjectClimber.TargetCood"):add_ref()
            -- char:set_RequestClimbCoord(OCTCood)

            -- setup app.Monster.set_ClimbPointController(app.ClimbPointController)

            return false
        end
    end
    return true
end
SpawnRequest.getPfbCtrl = function(self, charID)
    if self.gm then 
        --local catalog = self.gm._CatalogCtrl._EnemyCatalog:get_field("<MergedCatalog>k__BackingField")
        if self.catalogs and self.catalogs.Enemy then 
            print(string.format("SpawnRequest.getPfbCtrl(%d)", charID))
            local charCatItem = self.catalogs.Enemy:get_Item(charID)
            if charCatItem then 
                local charPathCtrl = charCatItem:get_Item()
                if charPathCtrl then 
                    local _path = charPathCtrl:get_Item():get_Path()
                    --self:toast("[getPfbCtrl] ".._path, self.tm.SUCCESS)
                    return charPathCtrl
                else
                    --self:toast("[setPfbCtrl] No charPathCtrl", self.tm.ERROR)
                end
            else
                --self:toast("[setPfbCtrl] No charCatItem", self.tm.ERROR)
            end
        else
            --self:toast("[setPfbCtrl] No Catalog", self.tm.ERROR)
        end
    end
    return nil
end
SpawnRequest.getCharID = function(self, charString)
    if charString and self.enums and self.enums.charID and self.enums.charID.byName then
        --self:toast(string.format("found charID for %s --> %d", charString, self.enums.charID.byName[charString]))
        return self.enums.charID.byName[charString]
    end
    --self:toast("could not find charID for " .. charString)
    return nil
end
SpawnRequest.getChar = function(self, charID)
    if charID and self.enums and self.enums.charID and self.enums.charID.byValue then 
        return self.enums.charID.byValue[charID]
    end
    return nil
end
SpawnRequest.newReqId = function(self, charID)
    local _rid = nil
    if self.gm and charID then 
        -- No longer working after latest update (2024_09_17)
        --_rid = self.gm:getRequestIDfromCharacterID(self.charID)
        _rid = nil
    end
    if not _rid then 
        local _r = sdk.create_instance("app.RequestID"):add_ref()
        _rid = _r:makeNewRequestID() 
        --_r:release()
    end
    return _rid
end
SpawnRequest.getGenIDWrapper = function(self, charID)
    --self:toast(string.format("TEST CHARID: %d", charID))
    if self.gm and charID then 
        --self:toast("getGenWrapper 1")
        local genIdWrapper = self.gm:getIdWrapper(charID)
        if genIdWrapper then 
            return genIdWrapper 
        end
    end
    return nil
end

SpawnRequest.addInstance = function(self, char, pos, rot, config)
    local charID = self:getCharID(char)
    local s = SpawnInstance:new(
        char, 
        charID, 
        self:getPfbCtrl(charID), 
        self:getGenIDWrapper(charID),
        nil,
        self:newReqId(charID), 
        config, 
        pos,
        rot)
        --self.tm)
    s:init()
    table.insert(self.instances, s)
    --self:toast("[INITIALIZED] SpawnRequest:addInstance "..tostring(char), self.tm.SUCCESS)
    
end
SpawnRequest.addReplInstance = function(self, pfbCtrl, container)
    local charID = container._CommonInfo._ObjectID._SelectedCharacterID
    local char = self:getChar(charID)
    log.debug(string.format("replSpawn: %s", char))
    local _config = {
        ["ovrScale"] = {
            ["enable"] = false,
            ["scale"] = 1.000,
            ["normalizeSpeed"] = false,
        },
        ["postProcScale"] = false 
    }
    local _genWrap = nil
    local _container = container
    local _pos = nil
    local _rot = nil
    local char3ID = string.sub(char,3,5)
    local char6ID = string.sub(char,3,8)
    if char6ID == "220001" -- Hobgoblin
        or char6ID == "220003" -- Knacker
    then 
        print("OVR Scale ch220")
        _config.ovrScale.enable = true
        _config.ovrScale.scale = 1.600
        _config.postProcScale = true
        --_container = nil
        --_genWrap =  self:getGenIDWrapper(charID)
        --_pos = container._CommonInfo._InitialPosition
        --_rot = container._CommonInfo._InitialAngle
    end

    if char3ID ~= "230" --no humans
        and char3ID ~= "253" -- no sphinx, griffen, purgenor
        and char3ID ~= "255" -- no medusa or pergenor
        and char3ID ~= "226" -- no skeletons
        and char3ID ~= "258" -- no end dragon
    then
        local s = SpawnInstance:new(
            char, 
            charID, 
            pfbCtrl, 
            _genWrap,
            _container,
            self:newReqId(charID), 
            _config, 
            _pos,
            _rot)
        s:initRepl()
        table.insert(self.instances, s)
    end
    
end
SpawnRequest.requestAddInstances = function(self, char, pos, rot, config, _n)
    local n = _n or 1
    while n > 0 do 
        self:addInstance(char, pos, rot, config)
        n = n - 1
    end
end
SpawnRequest.requestReplInstances = function(self, pfbCtrl, container,_n)
    local n = _n or 1
    while n > 0 do 
        self:addReplInstance(pfbCtrl, container)
        n = n - 1
    end
end
SpawnRequest.pSpawn = function(self, inst)
    local success, e = pcall(function()   
        self.gm:call("requestCreateInstance(app.PrefabController, app.GenerateInfo.GenerateInfoContainer, System.Int32, app.InstanceInfo, System.Action`2<app.PrefabInstantiateResults,app.DummyArg>, System.Action`2<app.PrefabInstantiateResults,app.DummyArg>)",
            inst.prefabCtrl, 
            inst.container, 
            inst.requestID,
            inst.instance,
            inst.fPreSpawn,
            inst.fPostSpawn
        )
    end)
    if success then 
         inst.status = 4
    else
        inst.status = 5
        --self:toast("[error] " .. tostring(e), self.tm.ERROR) 
    end
end
SpawnRequest.enforceInstanceLimit = function(self)
    if self.config.instLimit > 0 and self.instances and #self.instances > self.config.instLimit then 
        while #self.instances > self.config.instLimit do 
            self:deleteOldest()
        end
    end
end
SpawnRequest.requestSpawnOutstanding = function(self)
    self:enforceInstanceLimit()
    for i,inst in pairs(self.instances) do 
        if inst.status > 0 and inst.status < 4 then
            if inst:isPrefabReady() then 
                --self:toast(string.format("requestSpawnInstances [%d]", i)) 
                self:pSpawn(inst)
            else 
                inst.status = 3
            end
        end
    end

end
SpawnRequest.spawn = function(self, genCat)
    genCat = genCat or nil
    --print("SpawnRequest.spawn -- Start")
    --self:toast("[START] SpawnRequest", self.tm.WARNING)
    if self.status < 2 then self.status = 2 end
    local spawnQty = self.config["spawnMultiple"]["enable"] and self.config["spawnMultiple"]["qty"] or 1
    if self.prefabCtrl:get_Item():get_Ready() then
        --print("SpawnRequest.spawn -- Prefab Ready")
        --self:toast("[PREFAB] Ready", self.tm.WARNING)
        while spawnQty > 0 do
            self:pSpawn(genCat)
            spawnQty = spawnQty - 1
            
        end
        self.status = 4
        --self:toast("[DONE] SpawnRequest", self.tm.SUCCESS)
        --self:setupPostProc()
        self.fPreSpawn = nil
        self.fPostSpawn = nil
        return true
    else 
        --self:toast("[PREFAB] Standby", self.tm.WARNING)
        self.status = 3
        return false
    end
end

return SpawnRequest
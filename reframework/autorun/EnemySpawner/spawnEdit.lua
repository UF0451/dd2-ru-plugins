--[[
Edit the monsters/characters that get spawned by the game normally
    FEATURES
    -- Spawn Size
    -- health/attack rate/power
    -- no weapons
    -- big heads???
    --  app.Character.Head:set_LocalScale(via.vec3)
    
    -- multiply each monster spawn
    --      Exclude Animals/Human
    -- random scaled boss enemy
    -- everyone loves the arisen
    -- everyone hates the arisen
    -- Laundry Day -- no clothes
    -- kid mode -- 0.5 scale
    -- Sonic mode -- 3x speed
    -- drunk mode -- npcs offbalance constantly



]]
--local spawnRequest = require('EnemySpawner/spawnRequest')
local SpawnEdit = {}
SpawnEdit.__index = SpawnEdit
--SpawnEdit.new = function(self, spawner, config)
SpawnEdit.new = function(self, config)
    local se = {}
    setmetatable(se, SpawnEdit)
    --se.spawner = spawner or nil
    --se.tm = tm or nil
    --se.frame = 0
    --se.UPDATEFRAME = 120 -- update every 120 frames
    --se.replQueue = {}
    se.config = config
    return se
end

SpawnEdit.updateConfig = function(self,config)
    if config then self.config = config end
end
-- SpawnEdit.toast = function(self, msg, _type)
--     if self.tm then 
--         self.tm:toast("[SpawnEdit]"..msg, _type)
--     end
-- end
-- SpawnEdit.replicateSpawnArgs = function(self, pfbCtrl, container, _n, _pre, _post)
--     local n = _n or 1 
--     local pre = _pre or nil
--     local post = _post or nil
--     self.spawner.prefabCtrl = sdk.to_managed_object(pfbCtrl)
--     self.spawner.prefabCtrl:get_Item():set_Standby(true)
--     self.spawner.container = sdk.to_managed_object(container)
--     self.spawner.container._CommonInfo:setRequestID(self.spawner:newReqId())
--     self.spawner.fPreSpawn = pre
--     self.spawner.fPostSpawn = post
--     if n ~= nil and n > 1 then 
--         self.spawner.config.spawnMultiple.enable = true
--         self.spawner.config.spawnMultiple.qty = n
--     end
-- end
-- SpawnEdit.addReplQueue = function(self, pfbCtrl, container, _n, _pre, _post)
--     if pfbCtrl and container and _n and _n > 0 then 
--         table.insert(self.replQueue, {pfbCtrl,container,_n,_pre,_post})
--         self:toast("replQueue size: %d", #self.replQueue)
--     end
-- end
-- SpawnEdit.addReplQueue = function(self, pfbCtrl, container, _n, _pre, _post)

-- end
-- SpawnEdit.tryQueueSpawn = function(self)
--     self:toast("replQueue pending: " .. tostring(#self.replQueue))
--     if self.spawner.status ~= 2 and self.spawner.status ~=3  then 
--         local args = self.replQueue[1]
--         self:replicateSpawnArgs(table.unpack(args))
--     end
--     if self.spawner:spawn(3) then 
--         table.remove(self.replQueue, 1) 
--         self.spawner.status = 1
--     end

-- end
-- SpawnEdit.deleteAll = function(self) self.spawner:deleteAll() end
-- SpawnEdit.frameUpdate = function(self)
--     self.frame = self.frame + 1
--     if self.frame == self.UPDATEFRAME then 
--         self.frame = 0 
--         if #self.replQueue > 0 then self:tryQueueSpawn() end
--     end 
-- end

-- SpawnEdit.modifyNPCContainer = function(self, c)
--     local cInfo = sdk.to_managed_object(c)
--     local hMetaBase = nil
--     if cInfo and self.config and self.config.NPC then 
--         self:toast("cInfo Good")
--         -- if self.config.NPC.kidSized then 
--         --     self:toast("kidSized checked Good")
--         --     cInfo._StatusInfo:set_ScaleRate(1.1)
--         -- end
--         if self.config.NPC.naked then 
--             self:toast("naked checked Good")
--             local hInfo = cInfo:get_HumanInfo()
--             if hInfo then 
--                 self:toast("hInfo Good")
--                 -- local hMetaBase = hInfo:_get_Meta()
--                 hMetaBase = sdk.create_instance("app.CharacterEditDefine.MetaData")
--                 if hMetaBase then 
--                     self:toast("hMetaBase Good")
--                     if cInfo:get_HumanInfo():get_Meta() ~= nil then 
--                         self:toast("UND_BEFORE: " .. tostring(cInfo:get_HumanInfo():get_Meta():get_UnderwearStyle()))
--                     else 
--                         self:toast("origDoesNotHaveMetaBEFORE: " .. tostring(hMetaBase._UnderwearStyle))
--                     end
--                         -- mess with hMetaBase
--                     hMetaBase._FacewearStyle = -1251966817
--                     hMetaBase._UnderwearStyle = 905051872
--                     hInfo:set_Meta(hMetaBase)
--                     cInfo:set_HumanInfo(hInfo)
--                     if cInfo:get_HumanInfo():get_Meta() ~= nil then 
--                         self:toast("UND_AFTER: " .. tostring(cInfo:get_HumanInfo():get_Meta():get_UnderwearStyle()))
--                     else
--                         self:toast("origDoesNotHaveMetaAFTER")
--                     end
--                 end
--             end
--         end
--     else
--         self:toast("returning default container")
--         --return c
--     end
--     --return sdk.to_ptr(cInfo)
--     -- self:toast("returning modified container")
--     -- return hMetaBase
-- end

return SpawnEdit
local common = {}
common.log = {}

-- wrapper for logging actions -- logging turned off when enableLog = false
common.log.log = function(enabled, modName,_cat,msg)
    if enabled then 
        log.debug("[" .. tostring(modName) .. "][" .. tostring(_cat) .. "] " .. tostring(msg))
    end
end

common.log.hookArgObjs = {}

-- used to print the argument types of a table of objects.  Particularly useful for hook args
common.log.hookArgs = function(args, types)
    local tString = "[ARGS] "
    local types = types or {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil}
    common.log.hookArgObjs = {}
    for i,a in ipairs(args) do 
        local mo = nil
        local t = string.format("[%d]: ", i)
        local _s = false
        local tOf = nil
        _s, mo = pcall(sdk.to_managed_object, a)
        if _s and mo ~= nil then 
            local moTypeDef = mo:get_type_definition()
            table.insert(common.log.hookArgObjs, mo)
            if moTypeDef then t = t .. string.format("%s [MO]<%s>",tostring(mo),tostring(moTypeDef:get_full_name())) end 
        else 
            _s, tOf = pcall(sdk.typeof, a)
            if _s and tOf then 
                t = t .. string.format("%s <%s>",tostring(a), tostring(tOf))
            elseif types[i] == 'int' then 
                t = t .. string.format("%s <int64>",tostring(sdk.to_int64(a)))
            else 
                t = t .. string.format("%s <?>",tostring(a))
            end
        end 
        tString = tString .. t .. " \n "
    end
    return tString
end

common.log.toValString = function(t)
    local _temp = ""
    for k,v in pairs(t) do 
        _temp = _temp .. string.format("[%s: %s]",k,v)
    end 
    return _temp
end

common.config = {}

-- get filename for mod config json
common.config.getPath = function(modName)
    return string.format('%s.json', modName)
end

-- return contents of mod config as table
common.config.loadFile = function(modName)
    return json.load_file(common.config.getPath(modName))
end

-- return contents of mod config file coalesing from default config table
common.config.get = function(modName,def)
    local _json = common.config.loadFile(modName)
    if not _json then return def end
    for k,v in pairs(_json) do 
        def[k] = v
    end
    return def
end

-- save configuration to json file
common.config.save = function(modName, config)
    if common.config.loadFile(modName) ~= config then 
        json.dump_file(common.config.getPath(modName), config)
    end
end


--[[INTITIALIZE FROM TABLE
given a list of objects and subObjects, create a container for
all gameobjects which the mod requires

]]
common.gameObjects = {}


--[[
USAGE
NATIVE SINGLETON
SINGLETION
MANAGED OBJECT
NATIVE FUNCTION
FIELD
METHOD
]]
common.gameObjects.getGameObject = function(ref, _type, t)
    if _type == "NS" then 
        return sdk.get_native_singleton(ref)
    elseif _type =="MS" then 
        return sdk.get_managed_singleton(ref)
    elseif _type =="MO" then
        return sdk.to_managed_object(ref)
    elseif common.gameObjects[ref] ~= nil and t ~= nil and t[ref] ~= nil and t[ref][2] == "NS" then 
        local go = common.gameObjects[ref]
        local td = sdk.find_type_definition(t[ref][1])
        return sdk.call_native_func(go,td,_type)
    elseif common.gameObjects[ref] ~= nil and type(_type) == 'table' then 
        if _type[1] == "FLD" then 
            return common.gameObjects[ref]:get_field(_type[2])
        elseif #_type > 1 then 
            local func = table.remove(_type,1)
            return common.gameObjects[ref]:call(func, table.unpack(_type))
        end
    elseif common.gameObjects[ref] ~= nil then 
        return common.gameObjects[ref]:call(_type)
    else 
        return nil
    end
end

common.gameObjects.goList = {}
-- initialize gameobjects from table
-- array[1] -- native and managed objects
-- array[2] -- objects created from array[1]
-- array[..] .. n-1
common.gameObjects.init = function(t) 
    common.gameObjects.goList = {}
    for i,grp in ipairs(t) do 
        local parentGroup = i -1
        local parentTable = nil
        if parentGroup > 0 then 
            parentTable = t[i-1]
        end
        for k,v in pairs(grp) do 
            common.gameObjects[k] = common.gameObjects.getGameObject(v[1],v[2],parentTable)
            table.insert(common.gameObjects.goList, k)
        end
    end
end

common.gameObjects.cleanup = function()
    for k,g in pairs(common.gameObjects) do 
        if g ~= nil then 
            local s,e = pcall(function() g:release() end)
        end
    end
end

common.gameObjects.debugUI = function()
    imgui.text("DEBUG GAME OBJECTS")
    for _,k in pairs(common.gameObjects.goList) do 
        if imgui.collapsing_header(k) then
            if common.gameObjects[k] ~= nil then 
                object_explorer:handle_address(common.gameObjects[k])
            else 
                imgui.text("NA")
            end
        end
    end
end

common.argObjects = {}
common.argObjects.argList = {}

common.argObjects.getManagedObjects = function(t)
    common.argObjects.argList = {}
    for i,v in ipairs(t) do 
        local s = false 
        local _temp = nil 
        s, _temp = pcall(sdk.to_managed_object, v)
        table.insert(common.argObjects.argList, _temp)
    end
end

common.argObjects.debugUI = function()
    imgui.text("DEBUG FUNCTION ARGS")
    for i,v in ipairs(common.argObjects.argList) do 
        local _ttl = string.format("ARG[%d]", i)
        if imgui.collapsing_header(_ttl) then
            if v ~= nil then 
                object_explorer:handle_address(v)
            else 
                imgui.text("NA")
            end
        end
    end
end

common.enumHelper = {}
common.enumHelper.getTranslations = function(self, eName) 
        local td = sdk.find_type_definition(eName)
        local _fields = td:get_fields()
        local _temp = {['byIndex'] = {}, ['byName'] = {}, ['byValue']={}, ['byIndexV'] = {}}
        for _,f in ipairs(_fields) do 
            if f:is_static() then 
                local v = f:get_data()
                if v ~= nil then 
                    local name = f:get_name()
                    _temp.byName[name] = v 
                    _temp.byValue[v] = name
                    table.insert(_temp.byIndex, name)
                    table.insert(_temp.byIndexV, v)
                end
            end
        end
        return _temp
    end

common.inTable = function(t,val)
    for _,v in pairs(t) do 
        if v == val then return true end
    end
    return false
end

common.valIndexOf = function(t,val)
    for i,v in ipairs(t) do 
        if v == val then return i end
    end
    return nil
end

common.keyInTable = function(t,key)
    for k,_ in pairs(t) do 
        if k == key then return true end
    end
    return false
end

common.sameTableContents = function(a,b)
    --same object type test
    local typeA, typeB = type(a), type(b)
    if typeA ~= typeB then return false end
    --not working with tables
    if typeA ~= 'table' then return a == b end
    --not same length
    if #a ~= #b then return false end
    for k,v in pairs(a) do 
        if v ~= b[k] then return false end
    end
    return true
end

-- shorthand for using native singletons
common.nativeSimple = {}
common.nativeSimple.ns = nil
common.nativeSimple.typeDef = nil
common.nativeSimple.args = {}
common.nativeSimple.callFunc = function(self, def, f, args)
    if def then 
        self.ns = sdk.get_native_singleton(def)
        self.typeDef = sdk.find_type_definition(def)
    end
    if args ~= nil then 
        if type(args) == 'table' then 
            self.args = args
        else 
            self.args = {}
            table.insert(self.args, args) 
        end
        return sdk.call_native_func(self.ns, self.typeDef, f, table.unpack(self.args))
    else 
        return sdk.call_native_func(self.ns, self.typeDef, f)
    end
end

return common
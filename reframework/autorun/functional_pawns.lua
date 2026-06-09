local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw


local config = json.load_file('functional_pawns.json') or {}
if config.Vocation == nil then
	config.Vocation = true
end
if config.Storage == nil then
	config.Storage = true
end
if config.CampOnly == nil then
    config.CampOnly = false
end

-- sdk.hook(sdk.find_type_definition("app.SpeechController"):get_method("requestSpeech(app.TalkEventDefine.ID, app.Character, app.Character, System.Collections.Generic.List`1<app.Character>, System.Boolean)"),
-- function (args)
--     local speaker = sdk.to_managed_object(args[4])
--     local listener = sdk.to_managed_object(args[5])

--     log.info("requestSpeech TEID: " .. tostring(sdk.to_int64(args[3])) .. ", spkear: " .. tostring(speaker:get_CharaID()) .. ", listener: " .. tostring(listener:get_CharaID()))
-- end, function(ret)
--     return ret
-- end)


-- sdk.hook(sdk.find_type_definition("app.SpeechController"):get_method("speechPlay(app.TalkEventDefine.ID, app.Character, app.Character, System.Collections.Generic.List`1<app.Character>, System.Boolean)"),
-- function (args)
--     local speaker = sdk.to_managed_object(args[4])
--     local listener = sdk.to_managed_object(args[5])

--     log.info("speechPlay TEID: " .. tostring(sdk.to_int64(args[3])) .. ", spkear: " .. tostring(speaker:get_CharaID()) .. ", listener: " .. tostring(listener:get_CharaID())) -- id is 0 - NONE
--     log.info("speechPlay IsTalkEventID: " .. tostring(sdk.to_managed_object(args[2]):get_IsTalkEventID()) .. ", spkear: " .. tostring(speaker:get_CharaID()) .. ", listener: " .. tostring(listener:get_CharaID())) -- id is 0 - NONE
-- end, function(ret)
--     return ret
-- end)


-- useless
-- sdk.hook(sdk.find_type_definition("app.TalkEventManager"):get_method("getPlayingTalkEventId(app.Character, System.Boolean)"),
-- function (args)
-- end, function(ret)
--     log.info("getPlayingTalkEventId TEID: " .. tostring(sdk.to_int64(ret))) -- is 1 - invalid
--     return ret
-- end)

-- good
-- -- speaker, listener, castList
-- sdk.hook(sdk.find_type_definition("app.TalkEventManager"):get_method("selectTalkEvent(app.Character, app.Character, System.Collections.Generic.Dictionary`2<app.CharacterID,app.Character>)"),
-- function (args)
-- end, function(ret)
--     -- pawn is selectTalkEvent TEID: 1936
--     -- 关口随从公会：selectTalkEvent TEID: 1926
--     log.info("selectTalkEvent TEID: " .. tostring(sdk.to_int64(ret)))

--     -- return sdk.to_ptr(1926)
--     return ret
-- end)

-- good
-- -- Obj is SpeechController
-- -- obj, id, speaker, listener, audienceList, playAction, finish action, change first camera action, isReuqestFadeEndSegmentFunc, isUnloadedAllowed, isTakeOcuppied, isPreLocked
-- sdk.hook(sdk.find_type_definition("app.TalkEventManager"):get_method("requestPlay(System.Object, app.TalkEventDefine.ID, app.Character, app.Character, System.Collections.Generic.Dictionary`2<app.CharacterID,app.Character>, System.Action, System.Action, System.Action, app.Job05Tackle.MotInfo[], System.Boolean, System.Boolean, System.Boolean)"),
-- function (args)
--     log.info("Obj: " .. sdk.to_managed_object(args[3]):GetType():ToString() .. ", " .. tostring(sdk.to_int64(args[4])))
-- end, function(ret)
--     return ret
-- end)


-- sdk.hook(sdk.find_type_definition("app.TalkEventPlayer"):get_method("startJobChangeNode()"),
-- function (args)
--     log.info("startJobChangeNode QuestID: " .. tostring(sdk.to_managed_object(args[2])._QuestId)) -- is -1
-- end, function(ret)
--     return ret
-- end)

-- SpeechController TalkInteractController InteractiveObj
-- TalkController



-- local function DoShopDatas(shopDatas)
--     local iter=shopDatas:GetEnumerator()
--     iter:MoveNext()
--     while iter:get_Current()~=nil do
--         local shopData=iter:get_Current()
--         local typeshopData=shopData:get_type_definition()
--         if typeshopData:get_full_name() == "app.NpcShopInnParam" then
--             shopData._Cost=0
--         end
--         iter:MoveNext()
--     end    
-- end

-- --re.on_frame(function()
-- --    ClearLog()
-- --end)

-- sdk.get_managed_singleton("app.TalkEventManager")._ResourceCatalog
-- sdk.get_managed_singleton("app.TalkEventManager")._ResourceCatalog:get_field("<MergedCatalog>k__BackingField"):get_Item(1914)._Item
-- sdk.get_managed_singleton("app.TalkEventManager")._ResourceCatalog:get_field("<MergedCatalog>k__BackingField"):get_Item(1936)._Item
-- sdk.get_managed_singleton("app.TalkEventManager")._ShopTalkEventDataCatalog
-- sdk.get_managed_singleton("app.TalkEventManager")._ShopChoiceTalkEventDataCatalog


local CAMP_CHECK_CONDITION = 52
local function NewCondition()
    local cond = sdk.create_instance("app.te.condition.TalkEventSelectConditionList"):add_ref()
    cond._EvaluationType = 0

    if config.CampOnly then
        cond._ConditionList = sdk.create_managed_array("app.te.condition.TalkEventSelectConditionList.TalkEventSelectCondition", 1):add_ref()

        cond._ConditionList[0] = sdk.create_instance("app.te.condition.TalkEventSelectConditionList.TalkEventSelectCondition"):add_ref()
        cond._ConditionList[0]._ConditionName = CAMP_CHECK_CONDITION
        cond._ConditionList[0]._Condition = sdk.create_instance("app.te.condition.CampCheckCondition"):add_ref()
    else
        cond._ConditionList = sdk.create_managed_array("app.te.condition.TalkEventSelectConditionList.TalkEventSelectCondition", 0):add_ref()
    end
    return cond
end

-- node is app.TalkEventSegmentNode
local function NewNextNodeCandidate(node)
    local candidate = sdk.create_instance("app.NextNodeCandidate"):add_ref()
    candidate._NextNodeName = node._NodeName
    candidate._NextNodeNameHash = node._NodeNameHash
    candidate._NextNodeId = node._NodeId
    candidate._IsReportCandidate = false
    candidate._Conditions = NewCondition()

    return candidate
end

-- pawnData is TalkEventData
local function Edit1936TalkEventDataChoices(pawnData)
    -- find root candidates and add it
    local len = pawnData._SegmentNodes:get_Count()
    for i = 0, len - 1, 1 do
        local node = pawnData._SegmentNodes:get_Item(i)
        if node._NodeId == "f48de449-1bca-4b17-abe7-5a8fb2c12224" then -- 基本选择支
            -- node is app.ShopChoiceNode
            local found = false
            local choices = node._Choices
            for j = 0, #choices - 1 do
                log.info("JKL: " .. tostring(j))
                if #(choices[j]._NextNodeCandidateOnSelect) == 1 and
                    choices[j]._NextNodeCandidateOnSelect[0]._NextNodeId == "63a5a7d0-d2d3-4ce4-9386-6568eed89999" then
                    found = true
                end
            end

            if not found then
                -- patch the root candidates
                local newLen = #choices + 1
                node._Choices = sdk.create_managed_array("app.TalkEventChoice", newLen)
                for j = 0, newLen - 2 do
                    node._Choices[j+1] = choices[j]
                end

                -- add new choice
                local idx = 0
                node._Choices[idx] = sdk.create_instance("app.TalkEventChoice")
                node._Choices[idx]._Choice = ""

                local guid = sdk.create_instance("System.Guid", false)
                guid = guid:Parse("1f3d3153-e1ab-475a-9ece-dedb1bae04c2")
                -- guid = guid:call("NewGuid")
                log.info("GUID: " .. guid:ToString())
                node._Choices[idx]._ChoiceId = guid

                node._Choices[idx]._NextNodeCandidateOnSelect = sdk.create_managed_array("app.NextNodeCandidate", 1)
                node._Choices[idx]._NextNodeCandidateOnSelect[0] = NewNextNodeCandidate({
                    _NodeId = "63a5a7d0-d2d3-4ce4-9386-6568eed89999",
                    _NodeName = "",
                    _NodeNameHash = 3982504307,
                })

                node._Choices[idx]._DisplayConditionList = NewCondition()

                -- -- exit
                -- node._Choices[newLen - 1] = choices[newLen - 2]

                log.info("[Pawns] Expand PawnData candidates")
            else
                log.info("[Pawns] PawnData candidates already expanded")
            end

            break;
        end
    end
end

local function _InitTest()
    local mgr = sdk.get_managed_singleton("app.TalkEventManager")
    local dictCatalog = mgr._ResourceCatalog
    local catalog = dictCatalog:get_field("<MergedCatalog>k__BackingField") -- Dict<ID, RefCounter<Data>>

    local guildNode = TryGetNode(1926, 2);
    local pawnData = catalog:get_Item(1936)._Item

    local len = pawnData._SegmentNodes:get_Count()
    for i = 0, len - 1, 1 do
        local node = pawnData._SegmentNodes:get_Item(i)
        if node._NodeId == "f48de449-1bca-4b17-abe7-5a8fb2c12224" then -- 随从的基本选择支
            -- node is app.ShopChoiceNode
            local found = false
            local choices = node._Choices
            for j = 0, #choices - 1 do
                if #(choices[j]._NextNodeCandidateOnSelect) == 1 and
                    choices[j]._NextNodeCandidateOnSelect[0]._NextNodeId == guildNode._NodeId then
                    found = true
                end
            end

            if not found then
                -- patch the root candidates
                local newLen = #choices + 1
                node._Choices = sdk.create_managed_array("app.TalkEventChoice", newLen)
                for j = 0, newLen - 2 do
                    node._Choices[j+1] = choices[j]
                end

                -- add new choice
                local idx = 0
                --     -- resue
                -- node._Choices[idx] = guildNodes:get_Item(20)._Choices[0]

                    -- self create
                node._Choices[idx] = sdk.create_instance("app.TalkEventChoice")
                node._Choices[idx]._Choice = ""

                local guid = sdk.create_instance("System.Guid", false)
                -- guid = guid:Parse("1f3d3153-e1ab-475a-9ece-dedb1bae04c2")
                guid = guid:call("NewGuid")
                log.info("GUID: " .. guid:ToString())
                node._Choices[idx]._ChoiceId = guid

                node._Choices[idx]._NextNodeCandidateOnSelect = sdk.create_managed_array("app.NextNodeCandidate", 1)
                node._Choices[idx]._NextNodeCandidateOnSelect[0] = NewNextNodeCandidate(guildNode)

                node._Choices[idx]._DisplayConditionList = NewCondition()

                log.info("[Pawns] Expand PawnData candidates");

                -- setup shop talk
                local shopTalkCatalog = mgr._ShopChoiceTalkEventDataCatalog -- Dict<TypeID, app.NpcShopChoiceTalkData>
                -- pawn talk id is 25
                local talkData = shopTalkCatalog:get_Item(25) -- app.NpcShopChoiceTalkData
                local talkChoices = talkData._Choices -- app.NpcShopChoiceTalkData.ShopChoice[]
                local newTalkLen = #talkChoices + 1
                talkData._Choices = sdk.create_managed_array("app.NpcShopChoiceTalkData.ShopChoice", newTalkLen)
                for j = 0, newTalkLen - 2 do
                    talkData._Choices[j+1] = talkChoices[j]
                end
                -- talkData._Choices[idx] = sdk.create_instance("app.NpcShopChoiceTalkData.ShopChoice")
                -- local msgId = sdk.create_instance("System.Guid", false)
                -- msgId = msgId:Parse("1f3d3153-e1ab-475a-9ece-dedb1bae04c2")
                talkData._Choices[idx] = shopTalkCatalog:get_Item(4)._Choices[0]
            else
                log.info("[Pawns] PawnData candidates already expanded")
            end
            break;
        end
    end




    if catalog:ContainsKey(1926) then
        local guildData = catalog:get_Item(1926) -- app.RefCounter<app.TalkEventDefine.TalkEventData>
        if not guildData then
            log.info("[Pawns] GuildData is nil")
            return
        end
        local guildNode = nil
        local guildNodes = guildData._Item._SegmentNodes
        if guildNodes then
            local len = guildNodes:get_Count()
            if len > 2 then
                guildNode = guildNodes:get_Item(2) -- app.JobChangeSegmentNode
            end
        else
            log.info("[Pawns] GuildNodes is nil")
        end

        if guildNode then
            log.info("guildNode: " .. json.dump_string(guildNode, 2))
            if catalog:ContainsKey(1936) then
                local pawnData = catalog:get_Item(1936)._Item -- app.RefCounter<app.TalkEventDefine.TalkEventData>
                if not pawnData._SegmentNodes:Contains(guildNode) then
                    pawnData._SegmentNodes:Add(guildNode)
                    -- guildNode:addRef(); --- I hope I am doing right
                    log.info("[Pawns] PawnData patched")
                else
                    log.info("[Pawns] PawnData already patched")
                end
                -- find root candidates and add it
                local len = pawnData._SegmentNodes:get_Count()
                for i = 0, len - 1, 1 do
                    local node = pawnData._SegmentNodes:get_Item(i)
                    if node._NodeId == "f48de449-1bca-4b17-abe7-5a8fb2c12224" then -- 随从的基本选择支
                        log.info("node: " .. json.dump_string(node, 2))
                        -- node is app.ShopChoiceNode
                        local found = false
                        local choices = node._Choices
                        for j = 0, #choices - 1 do
                            if #(choices[j]._NextNodeCandidateOnSelect) == 1 and
                                choices[j]._NextNodeCandidateOnSelect[0]._NextNodeId == guildNode._NodeId then
                                found = true
                            end
                        end

                        if not found then
                            -- patch the root candidates
                            local newLen = #choices + 1
                            node._Choices = sdk.create_managed_array("app.TalkEventChoice", newLen)
                            for j = 0, newLen - 2 do
                                node._Choices[j+1] = choices[j]
                            end

                            -- add new choice
                            local idx = 0
                            --     -- resue
                            -- node._Choices[idx] = guildNodes:get_Item(20)._Choices[0]

                                -- self create
                            node._Choices[idx] = sdk.create_instance("app.TalkEventChoice")
                            node._Choices[idx]._Choice = ""

                            local guid = sdk.create_instance("System.Guid", false)
                            -- guid = guid:Parse("1f3d3153-e1ab-475a-9ece-dedb1bae04c2")
                            guid = guid:call("NewGuid")
                            log.info("GUID: " .. guid:ToString())
                            node._Choices[idx]._ChoiceId = guid

                            node._Choices[idx]._NextNodeCandidateOnSelect = sdk.create_managed_array("app.NextNodeCandidate", 1)
                            node._Choices[idx]._NextNodeCandidateOnSelect[0] = NewNextNodeCandidate(guildNode)

                            node._Choices[idx]._DisplayConditionList = NewCondition()

                            log.info("[Pawns] Expand PawnData candidates");

                            -- setup shop talk
                            local shopTalkCatalog = mgr._ShopChoiceTalkEventDataCatalog -- Dict<TypeID, app.NpcShopChoiceTalkData>
                            -- pawn talk id is 25
                            local talkData = shopTalkCatalog:get_Item(25) -- app.NpcShopChoiceTalkData
                            local talkChoices = talkData._Choices -- app.NpcShopChoiceTalkData.ShopChoice[]
                            local newTalkLen = #talkChoices + 1
                            talkData._Choices = sdk.create_managed_array("app.NpcShopChoiceTalkData.ShopChoice", newTalkLen)
                            for j = 0, newTalkLen - 2 do
                                talkData._Choices[j+1] = talkChoices[j]
                            end
                            -- talkData._Choices[idx] = sdk.create_instance("app.NpcShopChoiceTalkData.ShopChoice")
                            -- local msgId = sdk.create_instance("System.Guid", false)
                            -- msgId = msgId:Parse("1f3d3153-e1ab-475a-9ece-dedb1bae04c2")
                            talkData._Choices[idx] = shopTalkCatalog:get_Item(4)._Choices[0]
                        else
                            log.info("[Pawns] PawnData candidates already expanded")
                        end
                        break;
                    end
                end

                if pawnData then
                    dictCatalog:register(1936, pawnData)
                end
            else
                log.info("[Pawns] PawnData is nil")
            end
        else
            log.info("[Pawns] GuildNode is nil")
        end
    else
        log.info("[Pawns] GuildData is nil")
    end

    local ev = dictCatalog:get_field("UpdateCatalogEvent")
    if ev then
        ev:Invoke() -- it is nil
    end
end

local function InitSegmentNodes()
    local mgr = sdk.get_managed_singleton("app.TalkEventManager")
    local dictCatalog = mgr._ResourceCatalog
    local catalog = dictCatalog:get_field("<MergedCatalog>k__BackingField") -- Dict<ID, RefCounter<Data>>

    if catalog:ContainsKey(1926) then
        local guildData = catalog:get_Item(1926) -- app.RefCounter<app.TalkEventDefine.TalkEventData>
        if not guildData then
            log.info("[Pawns] GuildData is nil")
            return
        end
        local guildNode = nil
        local guildNodes = guildData._Item._SegmentNodes
        if guildNodes then
            local len = guildNodes:get_Count()
            if len > 2 then
                guildNode = guildNodes:get_Item(2) -- app.JobChangeSegmentNode
            end
        else
            log.info("[Pawns] GuildNodes is nil")
        end

        if guildNode then
            if catalog:ContainsKey(1936) then
                local pawnData = catalog:get_Item(1936)._Item -- app.RefCounter<app.TalkEventDefine.TalkEventData>
                if not pawnData._SegmentNodes:Contains(guildNode) then
                    pawnData._SegmentNodes:Add(guildNode)
                    -- guildNode:addRef(); --- I hope I am doing right
                    log.info("[Pawns] PawnData _SegmentNodes patched")
                else
                    log.info("[Pawns] PawnData _SegmentNodes already patched")
                end
            else
                log.info("[Pawns] PawnData is nil")
            end
        else
            log.info("[Pawns] GuildNode is nil")
        end
    else
        log.info("[Pawns] GuildData is nil")
    end
end


local PAWN_EVENT_ID=1936
local PAWN_SHOP_ID=25


local function TryGetNode(catalog, eventId, segmentIndex)
    if not catalog:ContainsKey(eventId) then return end;

    local data = catalog:get_Item(eventId) -- app.RefCounter<app.TalkEventDefine.TalkEventData>
    if not data then return end;
    if not data._Item then return end;

    local segmentNodes = data._Item._SegmentNodes;
    if segmentNodes:get_Count() <= segmentIndex then return end;

    return segmentNodes:get_Item(segmentIndex);
end

local function NewChoiceFromExisted(choice, nextNode)
    local new = sdk.create_instance("app.TalkEventChoice"):add_ref()
    new._Choice = choice._Choice

    local offset = new:get_type_definition():get_field("_ChoiceId"):get_offset_from_base()
    new:write_qword(offset, choice._ChoiceId:read_qword(0))
    new:write_qword(offset+8, choice._ChoiceId:read_qword(8))

    new._NextNodeCandidateOnSelect = sdk.create_managed_array("app.NextNodeCandidate", 1):add_ref()
    new._NextNodeCandidateOnSelect[0] = NewNextNodeCandidate(nextNode)

    -- app.te.condition.TalkEvent
    new._DisplayConditionList = NewCondition()

    return new
end

-- Since this function is run at certain times,
-- and the segment list is short,
-- sacrifice performance to increase readablity
local function TryAddNodeToDataHead(label, mgr, pawnData, nodeToAdd, nodeChoice, nodeShopID, nodeShopIndex)
    if not nodeToAdd then return end;

    if not pawnData._SegmentNodes:Contains(nodeToAdd) then
        pawnData._SegmentNodes:Add(nodeToAdd)
        log.info(label .. " PawnData patched")
    else
        log.info(label .. " PawnData already patched")
    end

    local len = pawnData._SegmentNodes:get_Count()
    for i = 0, len - 1, 1 do
        local node = pawnData._SegmentNodes:get_Item(i)
        if node._NodeId == "f48de449-1bca-4b17-abe7-5a8fb2c12224" then -- 随从的基本选择支
            -- node is app.ShopChoiceNode
            local found = false
            local choices = node._Choices
            for j = 0, #choices - 1 do
                if #(choices[j]._NextNodeCandidateOnSelect) == 1 and
                    choices[j]._NextNodeCandidateOnSelect[0]._NextNodeId == nodeToAdd._NodeId then
                    found = true
                end
            end

            if not found then
                -- patch the root candidates
                local newLen = #choices + 1
                node._Choices = sdk.create_managed_array("app.TalkEventChoice", newLen):add_ref()
                for j = 0, newLen - 2 do
                    node._Choices[j+1] = choices[j]
                end

                -- add new choice
                local idx = 0

                node._Choices[idx] = NewChoiceFromExisted(nodeChoice, nodeToAdd)

                -- node._Choices[idx] = sdk.create_instance("app.TalkEventChoice")
                -- node._Choices[idx]._Choice = ""
                -- local guid = sdk.create_instance("System.Guid", false)
                -- guid = guid:call("NewGuid")
                -- log.info(label .. " GUID: " .. guid:ToString())
                -- node._Choices[idx]._ChoiceId = guid
                -- node._Choices[idx]._ChoiceId = talkData._Choices[idx]._MsgID

                log.info(label .. " Expand PawnData candidates");

                -- setup shop talk
                local shopTalkCatalog = mgr._ShopChoiceTalkEventDataCatalog -- Dict<TypeID, app.NpcShopChoiceTalkData>
                -- pawn talk id is 25
                local talkData = shopTalkCatalog:get_Item(PAWN_SHOP_ID) -- app.NpcShopChoiceTalkData
                local talkChoices = talkData._Choices -- app.NpcShopChoiceTalkData.ShopChoice[]
                local newTalkLen = #talkChoices + 1
                talkData._Choices = sdk.create_managed_array("app.NpcShopChoiceTalkData.ShopChoice", newTalkLen):add_ref()
                for j = 0, newTalkLen - 2 do
                    talkData._Choices[j+1] = talkChoices[j]
                end

                talkData._Choices[idx] = shopTalkCatalog:get_Item(nodeShopID)._Choices[nodeShopIndex]

            else
                log.info(label .. " PawnData candidates already expanded")
            end
            break;
        end
    end
end

local function TryPatch(label, mgr, catalog, pawnData,
    targetEventID, targetNodeIndex, targetParentNodeIndex, targetParentShopId, targetSelectionIndex)
    local node = TryGetNode(catalog, targetEventID, targetNodeIndex);
    local parentNode = TryGetNode(catalog, targetEventID, targetParentNodeIndex)

    if node and parentNode and parentNode._Choices and parentNode._Choices[targetSelectionIndex] then
        TryAddNodeToDataHead(label, mgr, pawnData,
            node, parentNode._Choices[targetSelectionIndex], targetParentShopId, targetSelectionIndex);
    end
end

local INN_EVENT_ID=1914
local STORAGE_PARENT_INDEX=28
local STORAGE_SHOP_INDEX=30

local GUILD_EVENT_ID=1926
local GUILD_PARENT_INDEX=20
local GUILD_SHOP_INDEX=4
-- sdk.get_managed_singleton("app.TalkEventManager")._ResourceCatalog:get_field("<MergedCatalog>k__BackingField"):get_Item(1936)._Item
-- sdk.get_managed_singleton("app.TalkEventManager")._ShopChoiceTalkEventDataCatalog:get_Item(25)
local function Init()
    local mgr = sdk.get_managed_singleton("app.TalkEventManager")
    if not mgr then return end;
    local dictCatalog = mgr._ResourceCatalog
    if not dictCatalog then return end;
    local catalog = dictCatalog:get_field("<MergedCatalog>k__BackingField") -- Dict<ID, RefCounter<Data>>
    if not catalog then return end;

    -- check pawn data
    if not catalog:ContainsKey(PAWN_EVENT_ID) then return end;

    local pawnDataRef = catalog:get_Item(PAWN_EVENT_ID)
    if not pawnDataRef then return end;

    local pawnData = pawnDataRef._Item
    if not pawnData then return end;


    -- eventId, index to self segment node, index to parent segment node, shop index of parnet, n-th of current page
    if config.Storage then
        TryPatch("[Pawn] StorageD -", mgr, catalog, pawnData, INN_EVENT_ID, 31, STORAGE_PARENT_INDEX, STORAGE_SHOP_INDEX, 4);
		TryPatch("[Pawn] StorageC -", mgr, catalog, pawnData, INN_EVENT_ID, 33, STORAGE_PARENT_INDEX, STORAGE_SHOP_INDEX, 2);
		TryPatch("[Pawn] StorageB -", mgr, catalog, pawnData, INN_EVENT_ID, 30, STORAGE_PARENT_INDEX, STORAGE_SHOP_INDEX, 1);
		TryPatch("[Pawn] StorageA -", mgr, catalog, pawnData, INN_EVENT_ID, 3, STORAGE_PARENT_INDEX, STORAGE_SHOP_INDEX, 0);
    end
    if config.Vocation then
        TryPatch("[Pawn] JobGuild -", mgr, catalog, pawnData, GUILD_EVENT_ID, 2, GUILD_PARENT_INDEX, GUILD_SHOP_INDEX, 0);
    end


    -- local guildNode = TryGetNode(catalog, 1926, 2);
    -- local storageStore = TryGetNode(catalog, 1914, 3);
    -- local storageTake = TryGetNode(catalog, 1914, 30);
    -- local storageMix = TryGetNode(catalog, 1914, 31);

    -- if storageMix then
    --     TryAddNodeToDataHead("[Pawn] StorageM -", mgr, pawnData, storageMix, TryGetNode(catalog, 1914, 28)._Choices[2], 30, 2);
    -- end

    -- if storageTake then
    --     TryAddNodeToDataHead("[Pawn] StorageT -", mgr, pawnData, storageTake, TryGetNode(catalog, 1914, 28)._Choices[1], 30, 1);
    -- end

    -- if storageStore then
    --     TryAddNodeToDataHead("[Pawn] StorageS -", mgr, pawnData, storageStore, TryGetNode(catalog, 1914, 28)._Choices[0], 30, 0);
    -- end

    -- if guildNode then
    --     TryAddNodeToDataHead("[Pawn] JobGuild -", mgr, pawnData, guildNode, TryGetNode(catalog, 1926, 20)._Choices[0], 4, 0);
    -- end
end


-- Init()

sdk.hook(sdk.find_type_definition("app.GuiManager"):get_method("OnChangeSceneType"),
function (args)
end, function(ret)
    Init()
    -- InitSegmentNodes()
    return ret
end
)

-- sdk.hook(sdk.find_type_definition("app.DictionaryCatalog`2<app.TalkEventDefine.ID,app.TalkEventDefine.TalkEventData>"):get_method("register(app.TalkEventDefine.ID, app.TalkEventDefine.TalkEventData)"),
-- function (args)
--     local id = sdk.to_int64(args[3])
--     log.info("register: " .. tostring(id))
--     if id == 1936 then
--         Edit1936TalkEventDataChoices(sdk.to_managed_object(args[4]))
--     end
-- end, function(ret)
--     return ret
-- end)


-- sdk.hook(sdk.find_type_definition("app.TalkEventManager"):get_method("registerDialoguePackCatalog(app.QuestDefine.ID, app.TalkEventDefine.TalkEventDialoguePack)"),
-- function (args)
--     log.info("QuestDefineID: " .. tostring(sdk.to_int64(args[3])))
-- end, function(ret)
--     return ret
-- end)

-- sdk.hook(sdk.find_type_definition("app.TalkEventManager"):get_method("registerCastListCatalog(app.TalkEventResourceCastListCatalog)"),
-- function (args)
--     local talkEventResourceCastListCatalog = sdk.to_managed_object(args[3])
--     local talkEventResourceCatalog = talkEventResourceCastListCatalog._Catalog
--     log.info("Reigster KeyName: " .. talkEventResourceCatalog._KeyName)
--     local resourceArray = talkEventResourceCatalog._ResourceArray
--     for i = 0, #resourceArray - 1 do
--         local resource = resourceArray[i]
--         local talkEventResourcePack = resource._Data;
--         local packResources = talkEventResourcePack._PackResources;
--         for j = 0, #packResources do
--             local packResource = packResources[j]
--             local data = packResource._Data;
--             if data._Id == 1936 then
--                 Edit1936TalkEventDataChoices(data);
--                 log.info("Edit 1936")
--                 return;
--             end
--         end
--     end
-- end, function(ret)
--     return ret
-- end)

re.on_draw_ui(function()
    local configChanged = false
    if imgui.tree_node("Функциональные пешки") then
        local changed = false

		changed, config.Vocation = imgui.checkbox("Профессии (нужна перезагрузка)", config.Vocation)
        configChanged = configChanged or changed

		changed, config.Storage = imgui.checkbox("Склад (нужна перезагрузка)", config.Storage)
        configChanged = configChanged or changed

		changed, config.CampOnly = imgui.checkbox("Только лагерь (нужна перезагрузка)", config.CampOnly)
        configChanged = configChanged or changed

        imgui.tree_pop();
    end
    if configChanged then
        json.dump_file("functional_pawns.json", config)
    end
end)

re.on_config_save(function()
	json.dump_file("functional_pawns.json", config)
end)

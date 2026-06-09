local M = {}

local DATA_PATH = "quest_tracker_data.json"

function M._count_keys(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    local out = {}
    for i = 1, n do out[i] = i end
    return out
end

local function load_data()
    local ok, data = pcall(json.load_file, DATA_PATH)
    if not ok or type(data) ~= "table" then
        log.error("[qdl] failed to load " .. DATA_PATH .. ": " .. tostring(data))
        return nil
    end
    log.info(string.format("[qdl] loaded %s: %d quests, %d keylocs",
        DATA_PATH,
        data.quests and #M._count_keys(data.quests) or 0,
        data.keyloc_id_to_name and #M._count_keys(data.keyloc_id_to_name) or 0))
    return data
end

M.DATA = nil
local function ensure_data()
    if M.DATA == nil then
        M.DATA = load_data() or {quests = {}, common_noise_cids = {}}
    end
    return M.DATA
end

-- CIDs appearing across many quests (common pawn / Arisen refs). Filtered out
-- so multi-pin doesn't pollute candidates with non-specific NPCs.
local _noise = nil
local function noise_set()
    if _noise then return _noise end
    _noise = {}
    for _, cid in ipairs(ensure_data().common_noise_cids or {}) do
        _noise[cid] = true
    end
    return _noise
end

local function q(qid)
    return ensure_data().quests[tostring(qid)]
end

function M.get_givers(qid)
    local qd = q(qid)
    if not qd then return {} end
    local out = {}
    local seen = {}
    local noise = noise_set()
    for _, cid in ipairs(qd.givers or {}) do
        if not noise[cid] and not seen[cid] then
            seen[cid] = true
            table.insert(out, cid)
        end
    end
    return out
end

function M.get_recommended_level(qid)
    local qd = q(qid)
    return qd and qd.rec_level or nil
end

return M

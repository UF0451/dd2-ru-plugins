local hasContentEditorDB, udb = pcall(require, 'content_editor.database')
local QuestManager = sdk.get_managed_singleton("app.QuestManager")
local AIAreaManager = sdk.get_managed_singleton("app.AIAreaManager")

local startup = {}

local function get_AIKeyLocation_uni_position(locationId)
    local node = AIAreaManager:getKeyLocationNode(locationId)
    if node == nil then return nil end
    return node:get_UniversalPosition()
end

function startup.get_launch_time()
	return os.time() - os.clock()
end

local lastLaunchTime = json.load_file("_NickCore/LastLaunchTime.json")
local currentLaunchTime = startup.get_launch_time()
json.dump_file("_NickCore/LastLaunchTime.json",currentLaunchTime)

function startup.is_startup()
	return lastLaunchTime == nil or (math.abs(currentLaunchTime - lastLaunchTime) > 2.0) -- 2 seconds of margin for numerical errors
end

local readyTimestamp
function startup.is_game_data_ready(delay)
	local isQuestDataReady = QuestManager.QuestCatalogDict and QuestManager.QuestCatalogDict:getCount() > 0
	local isCEReady = hasContentEditorDB == false or udb:is_ready()
	local isUniPosReady = get_AIKeyLocation_uni_position(2137) ~= nil -- Happens unusually late

	if not (isQuestDataReady and isCEReady and isUniPosReady) then
		-- Reset if readiness is lost
		readyTimestamp = nil
		return false
	end

	-- No extra delay requested
	if not delay or delay <= 0 then
		return true
	end

	-- Start delay timer on first ready frame
	if not readyTimestamp then
		readyTimestamp = os.clock()
		return false
	end

	return (os.clock() - readyTimestamp) >= delay
end

return startup
local lantern_mode_labels = {'Always show', 'Show when lantern is on', 'Never show'}
local lantern_modes = {
    AlwaysShow = 1,
    HideIfOn = 2,
    AlwaysHide = 3,
}

local config = {
    lantern_mode_player = lantern_modes.HideIfOn,
    lantern_mode_pawn_main = lantern_modes.HideIfOn,
    lantern_mode_pawns_other = lantern_modes.HideIfOn,
    auto_enable_at_night = false,
}

local function load_config()
    local f = json.load_file('automatic_lantern.json')
    if f ~= nil then
        if type(f.lantern_mode_player) == 'number' then config.lantern_mode_player = f.lantern_mode_player end
        if type(f.lantern_mode_pawn_main) == 'number' then config.lantern_mode_pawn_main = f.lantern_mode_pawn_main end
        if type(f.lantern_mode_pawns_other) == 'number' then config.lantern_mode_pawns_other = f.lantern_mode_pawns_other end
        config.auto_enable_at_night = f.auto_enable_at_night or false
    end
end

local function save_config()
    json.dump_file('automatic_lantern.json', config)
end

local charaManager = sdk.get_managed_singleton("app.CharacterManager")
local pawnManager = sdk.get_managed_singleton('app.PawnManager')
local timeManager = sdk.get_managed_singleton('app.TimeManager')
local type_character = sdk.typeof('app.Character')
local go_getcomp = sdk.find_type_definition('via.GameObject'):get_method('getComponent(System.Type)')
local mesh_get_enabled = sdk.find_type_definition('via.render.Mesh'):get_method('get_Enabled')
local mesh_set_enabled = sdk.find_type_definition('via.render.Mesh'):get_method('set_Enabled')
local t_get_day_seconds = sdk.find_type_definition('app.TimeManager'):get_method('get_InGameElapsedDaySeconds')
local method_get_player = sdk.find_type_definition('app.CharacterManager'):get_method('get_ManualPlayer')

-- all CharacterID ch1110xx entries, don't wanna bother generating the full enum for a lookup when consts work fine pls don't judge
local pawnIds = {[25445221] = true, [25702072] = true, [112032848] = true, [217969769] = true, [536210663] = true, [580420473] = true, [680851256] = true, [863242128] = true, [1088065928] = true, [1119352038] = true, [1185522626] = true, [1188289343] = true, [1277774675] = true, [1434183269] = true, [1520190659] = true, [1635838129] = true, [1737330270] = true, [1924471665] = true, [2041021794] = true, [2220649950] = true, [2245273799] = true, [2421963114] = true, [2453509494] = true, [2482422138] = true, [2518986198] = true, [2563190455] = true, [2569571822] = true, [2602283685] = true, [2644745694] = true, [2718967947] = true, [2745882988] = true, [2842331889] = true, [2906414396] = true, [3002133261] = true, [3184685702] = true, [3248959453] = true, [3290103255] = true, [3424724884] = true, [3459096238] = true, [3524808443] = true, [3637895451] = true, [3698332830] = true, [3707829632] = true, [3776368131] = true, [3830508133] = true, [3912900191] = true, [3991131757] = true, [4046114257] = true, [4095271692] = true, [4145320875] = true}

---@class CharacterDataCache
---@field lant_ctrl REManagedObject app.LanternController
---@field mode 0|1|2|3
---@field lant_mesh REManagedObject|nil via.render.Mesh

---@type table<string,CharacterDataCache>
local chara_cache = {}
local lantern_to_chara_cache = {}
local function get_chara_lantern_mode(chara)
    local id = chara:get_CharaID()
    if id == 2891076981 then -- ch000000_00
        return config.lantern_mode_player
    elseif id == 2283028347 then -- ch100000_00
        return config.lantern_mode_pawn_main
    elseif pawnIds[id] then
        return config.lantern_mode_pawns_other
    else
        return 0
    end
end

local function create_chara_cache_entry(chara, chara_cache_key, lantern_ctrl)
    local state = {}
    chara_cache[chara_cache_key] = state
    local human = chara:get_Human()
    if human == nil then return state end
    local lantern_mode = get_chara_lantern_mode(chara)
    state.mode = lantern_mode
    if lantern_mode ~= 0 then
        state.lant_ctrl = human:get_LanternCtrl()
        state.lant_mesh = state.lant_ctrl:get_LanternMesh()
        lantern_to_chara_cache[state.lant_ctrl:get_address()] = chara_cache_key
    end

    return state
end
local function refresh_lantern_state(chara, lantern_on)
    local cachekey = chara:get_address()
    local state
    if not chara_cache[cachekey] then
        state = create_chara_cache_entry(chara, cachekey)
    else
        state = chara_cache[cachekey]
        if state.mode == 0 then return end
        if not state.lant_mesh then
            state.lant_mesh = state.lant_ctrl:get_LanternMesh()
        end
    end

    if not state.lant_ctrl then return end

    if lantern_on == nil then
        lantern_on = state.lant_ctrl:get_IsLanternOn()
    end
    local should_show = true
    if state.mode == lantern_modes.AlwaysHide then
        should_show = false
    elseif state.mode == lantern_modes.HideIfOn then
        should_show = lantern_on
    end
    if not state.lant_mesh then
        print('lantern mesh is missing')
        return
    end
    local mesh_enabled = mesh_get_enabled:call(state.lant_mesh)
    -- print('lantern on: ', lantern_on, 'show:', should_show, 'mesh enabled:', mesh_enabled, lantern_mode_labels[state.mode], chara:get_CharaIDString())
    if should_show ~= mesh_enabled then
        mesh_set_enabled:call(state.lant_mesh, should_show)
    end
end

local function force_refresh()
    chara_cache = {}
    lantern_to_chara_cache = {}
    local player = charaManager:call('get_ManualPlayer')
    if player ~= nil then
        refresh_lantern_state(player)

        local pawnlist = pawnManager:call('get_PawnCharacterList')
        local cnt = pawnlist:get_Count()
        for i = 0, cnt-1 do
            local pawn = pawnlist:get_Item(i)
            refresh_lantern_state(pawn)
        end
    end
end

load_config()
force_refresh()

sdk.hook(
    sdk.find_type_definition('app.Character'):get_method('onDestroy'),
    function (args)
        -- clear out our cache on destroy so we don't keep infinite addresses in memory
        local ch_addr = sdk.to_managed_object(args[2]):get_address()
        local ch = chara_cache[ch_addr]
        if ch ~= nil then
            chara_cache[ch_addr] = nil
            if ch.lant_ctrl ~= nil then
                lantern_to_chara_cache[ch.lant_ctrl:get_address()] = nil
            end
        end
    end
)

sdk.hook(
    sdk.find_type_definition('app.Character'):get_method('onInitializeCharacterBegin'),
    function (args)
        -- local charId = sdk.to_int64(args[3])
        local chara = sdk.to_managed_object(args[2])
        refresh_lantern_state(chara)
    end
)


local function onTurn(lantern_ctrl, is_on)
    local ctrl_addr = lantern_ctrl:get_address()
    local ch_addr = lantern_to_chara_cache[ctrl_addr]
    local chara
    if ch_addr then
        chara = sdk.to_managed_object(ch_addr)
    else
        chara = go_getcomp:call(lantern_ctrl.OwnerTrans:get_GameObject(), type_character)
        if chara ~= nil then
            ch_addr = chara:get_address()
            lantern_to_chara_cache[ctrl_addr] = ch_addr
            local mode = get_chara_lantern_mode(chara)
            chara_cache[ch_addr] = {
                lant_ctrl = lantern_ctrl,
                mode = mode,
                lant_mesh = nil,
            }
            if mode == 0 then return end
        else
            return
        end
    end

    refresh_lantern_state(chara, is_on)
end

sdk.hook(
    sdk.find_type_definition('app.HumanLanternController'):get_method('set_IsLanternOn'),
    function (args)
        local is_on = (sdk.to_int64(args[3]) & 1) ~= 0
        onTurn(sdk.to_managed_object(args[2]), is_on)
    end
)

local seconds_per_hour = 120
local night_time_seconds = 19.5 * seconds_per_hour
local dawn_time_seconds = 4.5 * seconds_per_hour

local is_detecting_time = false
local function detect_time()
    if is_detecting_time then return end
    is_detecting_time = true

    local lastSeconds = nil
    re.on_frame(function ()
        -- unmoored has no concept of time so ignore in that case
        if not timeManager._IsBackWorld then
            local seconds = t_get_day_seconds:call(timeManager)
            local should_enable_last = lastSeconds ~= nil and (lastSeconds >= night_time_seconds or lastSeconds <= dawn_time_seconds)
            local should_enable_now = seconds >= night_time_seconds or seconds <= dawn_time_seconds
            if lastSeconds == nil or should_enable_last ~= should_enable_now then
                local player = method_get_player:call(charaManager)
                if player ~= nil then
                    local state = chara_cache[player:get_address()]
                    if state and state.lant_ctrl then
                        state.lant_ctrl:set_IsLanternOn(should_enable_now)
                        onTurn(state.lant_ctrl, should_enable_now)
                    end
                end
            end
            lastSeconds = seconds
        end
    end)
end
if config.auto_enable_at_night then detect_time() end

re.on_draw_ui(function()
    local changed

    if imgui.tree_node("Автоматический фонарь") then
        changed, config.lantern_mode_player = imgui.combo('Игрок', config.lantern_mode_player, lantern_mode_labels)
        if changed then save_config() force_refresh() end
        changed, config.lantern_mode_pawn_main = imgui.combo('Главная пешка', config.lantern_mode_pawn_main, lantern_mode_labels)
        if changed then save_config() force_refresh() end
        changed, config.lantern_mode_pawns_other = imgui.combo('Другие пешки', config.lantern_mode_pawns_other, lantern_mode_labels)
        if changed then save_config() force_refresh() end

        changed, config.auto_enable_at_night = imgui.checkbox('Автовключение ночью', config.auto_enable_at_night)
        if changed then
            save_config()
            force_refresh()
            if config.auto_enable_at_night then detect_time() end
        end

        imgui.tree_pop()
    end
end)

re.on_script_reset(function()
    -- reset visibility so we can cleanly disable
    for _, state in pairs(chara_cache) do
        if state.lant_mesh and state.lant_ctrl and not mesh_get_enabled:call(state.lant_mesh) then
            mesh_set_enabled:call(state.lant_mesh, true)
        end
    end
end)

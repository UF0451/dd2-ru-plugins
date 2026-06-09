log.info("[Stamina Mod] Успешно загружен")

-- Глобальные ссылки на менеджеры
local CharacterManagerSingleton = nil
local BattleManagerSingleton = nil
local BattleManager = nil
local CharacterManager = nil
local ManualPlayer = nil
local StaminaManager = nil

-- Функция безопасного получения синглтонов и ссылок
local function update_managers()
    if not CharacterManagerSingleton then
        CharacterManagerSingleton = sdk.get_managed_singleton('app.AppSingleton`1<app.CharacterManager>')
    end
    if not BattleManagerSingleton then
        BattleManagerSingleton = sdk.get_managed_singleton('app.AppSingleton`1<app.BattleManager>')
    end

    -- Если базовые синглтоны ещё не готовы, мягко выходим, не вызывая краш
    if not CharacterManagerSingleton or not BattleManagerSingleton then return false end

    if not BattleManager then
        local ok, res = pcall(function() return BattleManagerSingleton:call('get_Instance') end)
        if ok and res then BattleManager = res end
    end

    if not CharacterManager then
        local ok, res = pcall(function() return CharacterManagerSingleton:call('get_Instance') end)
        if ok and res then CharacterManager = res end
    end

    -- Проверяем цепочку игрока
    if CharacterManager then
        if not ManualPlayer then
            local ok, res = pcall(function() return CharacterManager:call("get_ManualPlayer") end)
            if ok and res and sdk.is_managed_object(res) then ManualPlayer = res end
        end
    end

    if ManualPlayer then
        if not StaminaManager then
            local ok, res = pcall(function() return ManualPlayer:call("get_StaminaManager") end)
            if ok and res and sdk.is_managed_object(res) then StaminaManager = res end
        end
    end

    return BattleManager ~= nil and StaminaManager ~= nil
end

-- Основной цикл обновления кадров
re.on_frame(function()
    update_managers()
end)

-- Перехват функции изменения выносливости
sdk.hook(
    sdk.find_type_definition("app.StaminaManager"):get_method("add"),
    function(args)
        -- Обязательно проверяем, инициализирован ли BattleManager, чтобы не ловить вылеты
        if not BattleManager or not sdk.is_managed_object(BattleManager) then return end

        local add_value = sdk.to_float(args[3])
        
        -- _BattleMode == 0 означает, что персонаж находится вне режима боя (в мирной зоне или просто без оружия)
        local battleModeOk, battleMode = pcall(function() return BattleManager:get_field("_BattleMode") end)
        
        if battleModeOk and battleMode == 0 and add_value < 0.0 then
            -- Если это трата выносливости (значение отрицательное) вне боя, принудительно обнуляем её расход
            add_value = 0.0
            args[3] = sdk.to_ptr(add_value)
        end
    end,
    function(retval) return retval end
)

-- Русифицированный и раскомментированный отладочный интерфейс в REFramework
re.on_draw_ui(function()
    if imgui.tree_node("Отладка выносливости вне боя") then
        -- Если менеджеры ещё не прогрузились в мире, пишем предупреждение вместо падения
        if not StaminaManager or not BattleManager or not ManualPlayer then
            imgui.text("Ожидание загрузки персонажа в мир...")
            imgui.tree_pop()
            return
        end

        local staminaOk, remainingStamina = pcall(function() return StaminaManager:call("get_RemainingAmount()") end)
        local townOk, townArea = pcall(function() return ManualPlayer:call("get_AITownArea()") end)
        local battleOk, battleMode = pcall(function() return BattleManager:get_field("_BattleMode") end)

        if staminaOk then
            imgui.drag_float("Текущая выносливость", remainingStamina)
        end
        if townOk then
            imgui.drag_int("Мирная зона (Город)?", townArea)
        end
        if battleOk then
            imgui.drag_int("Режим боя активен?", battleMode)
        end

        imgui.tree_pop()
    end
end)
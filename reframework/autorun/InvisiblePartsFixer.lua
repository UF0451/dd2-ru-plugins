-- Invisible Parts Fixer
-- By LordGregory

local version = "1.0"
log.info("Initializing `Invisible Parts Fixer` v"..version)

sdk.hook(
    sdk.find_type_definition("app.PartSwapper"):get_method("lateUpdate"),
    function (args)
        local partSwapper = sdk.to_managed_object(args[2])

        if partSwapper:get_field("_Human") ~= nil then
            partSwapper:get_HideSwapObjects()
            partSwapper:forceUpdateStatusOfSwapObjects()
            partSwapper:requestFurMask()
        end

        return sdk.PreHookResult.CALL_ORIGINAL
    end,
    function (retval)
        return retval
    end
)
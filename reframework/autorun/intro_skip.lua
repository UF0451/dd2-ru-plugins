sdk.hook(
    sdk.find_type_definition('app.GUIStartUp'):get_method('update'),
    function (args)
        sdk.to_managed_object(args[2]):set_DrawSelf(false)
    end
)

sdk.hook(
    sdk.find_type_definition('app.BootGUIController'):get_method('update'),
    function (args)
        local this = sdk.to_managed_object(args[2])
        local phase = this.CurrPhase
        if phase == 1 then
            this.NextPhase = 2
            this.TransitDelayTimer:finish()
        end
    end
)

sdk.hook(
    sdk.find_type_definition("app.ItemManager"):get_method("getWeightRank(System.Single, System.Single)"), 
    nil, 
    function(_)
        return sdk.to_ptr(0);
    end
)

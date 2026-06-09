local plugs = {
    ["В"]	=   "{A}",
    ["К"]	=   "{B}",
    ["Д"]	=   "{E}",
    ["Э"]	=   "{F}",
    ["И"]	=   "{I}",
    ["Р"]	=   "{R}",
}

local favors = {
    ["{A}"] = "Цветы, Фрукты, Золотых Жуков",
    ["{B}"] = "Цветы, Руду, Золотых жуков",
    ["{E}"] = "Редкую руду, Дорогую экипировку",
    ["{F}"] = "\r\nРедкие зелья, Книги заклинаний\r\nНеобычные части монстров         ",
    ["{I}"] = "Части монстров, Редкую экипировку",
    ["{R}"] = "Необычные и редкие части монстров",
    ["{A}{B}"] = "\r\nЦветы, Фрукты, Руду, Кристаллы,\r\nЗолотых жуков                               ",
    ["{A}{E}"] = "\r\nЦветы, Фрукты, Жуков, Редкую руду,\r\nДорогую экипировку                            ",
    ["{A}{F}"] = "\r\nЦветы, Фрукты, Жуков, Редкие зелья,\r\nЧасти монстров, Книги заклинаний   ",
    ["{A}{I}"] = "\r\nЦветы, Фрукты, Жуков, Необычные    \r\nчасти монстров, Редкую экипировку  ",
    ["{A}{R}"] = "\r\nЦветы, Фрукты, Жуков, Необычные и  \r\nредкие части монстров              ",
    ["{B}{E}"] = "\r\nЦветы, Руду (особенно редкую),         \r\nКристаллы, Жуков, Книги заклинаний",
    ["{B}{F}"] = "\r\nЦветы, Руду, Жуков, Кристаллы,     \r\nРедкие зелья, Книги заклинаний      ",
    ["{B}{I}"] = "\r\nЦветы, Руду, Жуков, Части монстров,\r\nКристаллы, Необычную экипировку    ",
    ["{B}{R}"] = "\r\nЦветы, Руду, Жуков, Кристаллы      \r\nНеобычные и редкие части монстров  ",
    ["{E}{F}"] = "\r\nРедкую руду, Дорогую экипировку,\r\nРедкие зелья, Книги заклинаний     ",
    ["{E}{I}"] = "\r\nРедкую руду, Части монстров,       \r\nНеобычную и дорогую экипировку",
    ["{E}{R}"] = "\r\nРедкую руду, Дорогую экипировку,  \r\nНеобычные и редкие части монстров",
    ["{F}{I}"] = "\r\nРедкие зелья, Книги заклинаний,     \r\nЧасти монстров, Редкую экипировку",
    ["{F}{R}"] = "\r\nРедки зелья, Книги заклиний,           \r\nНеобычные и редкие части монстров",
    ["{I}{R}"] = "\r\nЧасти монстров (особенно редкие),  \r\nНеобычную и редкую экипировку      "
}

function get_text_language()
    local option_manager = sdk.get_managed_singleton("app.OptionManager")
    local lang_option = option_manager._OptionItems:get_Item(sdk.find_type_definition("app.OptionID"):get_field("TextLanguage"):get_data())
    return lang_option:get_FixedValueModel():get_StringValue()
end

local text_language = get_text_language()
local sp

sdk.hook(sdk.find_type_definition("app.GUIBase"):get_method("getSeparateMsg(System.String, System.String[])"), 
	function(args)
		if text_language == "Russian" then
			local fsa = sdk.to_managed_object(args[3])
			
			if fsa and type(fsa) == "userdata" then
				local tp = {}
				
				for _, p in pairs(fsa) do
					local p = plugs[string.sub(p:ToString(), 1, 2)]
					
					if p then 
						table.insert(tp, p)
					end
				end
				
				table.sort(tp)
				sp = table.concat(tp)
			end
		end
	end, 
    function(retval)
        if text_language == "Russian" then
			msg = favors[sp]
			
            if msg then
				return sdk.to_ptr(sdk.create_managed_string(msg))
			end
        end

        return retval
    end
)

sdk.hook(sdk.find_type_definition("app.OptionManager"):get_method("saveConfigFile"), nil,
    function(retval)
        text_language = get_text_language()

        return retval
    end
)
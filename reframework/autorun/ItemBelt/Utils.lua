--========================================================--
-- Utils.lua
-- Author: Wandd3rer
-- Purpose: Assorted utilities.
--========================================================--

local Utils = {}


--- Prints out a table with optional indentation
--- @param t table Table to be printed out.
--- @param curly_indent number Indentation of curly braces.
--- @param item_indent number Indentation of items.
function Utils._print_table(t, curly_indent, item_indent)
    curly_indent = curly_indent or 0
    item_indent = item_indent or 0
    if type(t) == "table" then

        -- Skips printing new line before first opening curly bracket
        if curly_indent ~= 0 then
            io.write("\n")
        end

        io.write(string.rep("\t", curly_indent), "{\n")
        item_indent = item_indent + 1

        for key, value in pairs(t) do
            io.write(string.rep("\t", curly_indent + item_indent) .. string.format("[%s] = ", key))
            Utils._print_table(value, curly_indent + item_indent, item_indent)
            io.write(",\n")
        end

        io.write(string.rep("\t", curly_indent), "}")
    else
        io.write(tostring(t))
    end

    -- Prints new line after first closing curly bracket
    if curly_indent == 0 then
        io.write("\n")
    end

end


--- Prints out a table with optional indentation
--- @param t table Table to be printed out.
--- @param indent number Indentation of items.
function Utils.print_table(t, indent)
    indent = indent or 0

    if t == nil then
        io.write("Got nil.\n")
        return
    end
    if next(t) == nil then  -- Empty table
        io.write("{}\n")
        return
    end

    Utils._print_table(t, 0, indent)
    io.write("\n")
end


--- Prints out selected items.
--- @param t table Table to be printed out.
--- @param keys table Array of keys of selected items.
--- @param indent number Indentation of items.
function Utils.print_table_items(t, keys, indent)
    local sub_t = {}
    for _, key in ipairs(keys) do
        sub_t[key] = t[key]
    end
    Utils.print_table(sub_t, indent)
end


--- Gets table keys.
--- @param t table Table.
--- @return table -> Array of table keys.
function Utils.get_table_keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end


--- Gets table values.
--- @param t table Table.
--- @return table -> Array of table values.
function Utils.get_table_values(t)
    local values = {}
    for _, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end


--- Merges second array into first one.
--- @param t1 table Table.
--- @param t2 table Table.
--- @return table -> Array of table values.
function Utils.merge_arrays(t1, t2)
    for _, v in ipairs(t2) do
        t1[#t1 + 1] = v
    end
    return t1
end


--- Initializes an integer array.
--- @param t table Array.
--- @param n number Size of the array.
--- @param value number Initial value of all elements.
--- @return table -> Array.
function Utils.init_int_array(t, n, value)
    n = n or #t
    value = value or 0
    for i = 1, n do
        t[i] = value
    end
    return t
end


--- Creates and initializes an integer array.
--- @param n number Size of the array.
--- @param value number Initial value of all elements.
--- @return table -> Array.
function Utils.create_int_array(n, value)
    value = value or 0
    local t = {}
    for i = 1, n do
        t[i] = value
    end
    return t
end


--- Checks if an array contains a given element.
--- @param t table Array.
--- @param x number Element to be checked.
--- @return boolean -> true if it contains the element, false otherwise.
function Utils.contains(t, x)
	for _, v in ipairs(t) do
		if v == x then return true end
	end
	return false
end


--- Gets table length.
--- @param t table Any table.
--- @return number -> Table length.
function Utils.get_table_length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end


-- Calculates offset to horizontally center text in REFramework Direct2D GUI's.
-- @param font d2d.Font Font object. 
-- @param text string Text to be written. 
-- @param dim_len number Lenght of the dimension where text is to be fitted.
-- @return number -> Offset.
function Utils.hcenter_text(font, text, dim_len)
    local text_w, _ = font:measure(text)
    local offset = 0
    local text_dim = text_w

    if text_dim < dim_len then
        offset = (dim_len - text_dim) / 2.0
    else
        offset = 0
    end

    return offset
end


-- Calculates offset to right-justify text in REFramework Direct2D GUI's.
-- @param font d2d.Font Font object. 
-- @param text string Text to be written. 
-- @param dim_len number Lenght of the dimension where text is to be fitted.
-- @param pad number Gap between text and right boundary.
-- @return number -> Offset.
function Utils.right_text(font, text, dim_len, pad)
    pad = pad or 5
    local text_dim, _ = font:measure(text)
    local offset = nil
    local padded_text_dim = text_dim + pad

    if padded_text_dim < dim_len then
        offset = dim_len - padded_text_dim
    else
        offset = 0
    end

    return offset
end


--- Adds opacity to solid color given in HEX format.
--- @param hex number Solid color in HEX format.
--- @param opacity number Opacity level between 0.0 and 1.0
--- @return number -> Color in ARGB format.
function Utils.hex_to_argb(hex, opacity)
    local color_hex = string.format("%x", hex)

    if #color_hex ~= 6 then
        log.error("[Utils] Invalid HEX color: must be 6 hex digits (0xRRGGBB)")
    end

    local opacity_hex = string.format("%x", math.floor(255 * opacity + 0.5))
    local color_argb = opacity_hex .. color_hex
    return tonumber(color_argb, 16)
end


-- Prints out gamepad button numbers.
-- @param pad_device
function Utils.get_button(pad_device)
    local button = pad_device:get_Button()
    if button ~= 0 then
        print(string.format("Button = %s", tostring(button)))
    end
end

return Utils
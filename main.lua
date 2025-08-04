local utils = require("utils")

local utf8 = require("utf8")

local escapes = {
	['"'] = '"',
	["\\"] = "\\",
	["/"] = "/",
	["b"] = "\b",
	["f"] = "\f",
	["n"] = "\n",
	["r"] = "\r",
	["t"] = "\t",
}
local delimiters = { ",", "]", "}" }
local literals = { "true", "false", "null" }

---Parses a string value of a JSON string
---@param str string The entire JSON string
---@param i number The current index in the string
---@return string val Value of the string
---@return number end_pos The position after the ending of the number
local function parse_string(str, i)
	if string.sub(str, i, i) ~= '"' then
		utils.throw_decode_error(i, 'String not starting with "')
		return "", i
	end
	local val = ""
	local j = i + 1
	local k = j
	while j <= #str do
		local char_code = string.byte(str, j)
		if char_code < 32 then
			utils.throw_decode_error(j, "Found an invalid ascii code")
		end
		if char_code == 92 then
			val = val .. string.sub(str, k, j - 1)
			j = j + 1
			local char = string.sub(str, j, j)
			local escapes_keys = utils.create_key_array(escapes)
			if char == "u" then
				local hex = string.match(str, "^%x%x%x%x", j)
				--                TODO: Add surrogate pairs
				--                Also learn how to write surrogate
				--                local hex_value =

				local unicode = utf8.char(tonumber(hex, 16))
				val = val .. unicode
				j = j + string.len(hex)
			elseif utils.is_value_in_table(escapes_keys, char) then
				val = val .. escapes[char]
			else
				utils.throw_decode_error(j, "Unsupported escpae code")
			end
			k = j + 1
		elseif char_code == 34 then
			val = val .. string.sub(str, k, j - 1)
			return val, utils.next_non_space(str, j)
		end
		j = utils.next_non_space(str, j)
	end
	utils.throw_decode_error(i, "I have no idea how you got here")
	return "", i
end

---Parses a number value of a JSON string
---@param str string The entire JSON string
---@param i number The current index in the string
---@return number val Value of the number
---@return number end_pos The position after the ending of the string
local function parse_number(str, i)
	local j = i
	while j <= #str do
		local char = string.sub(str, j, j)
		if utils.is_value_in_table(delimiters, char) then
			break
		end
		j = j + 1
	end
	local val = tonumber(string.sub(str, i, j - 1))
	if not val then
		utils.throw_decode_error(i, "Cannot parse number")
		return 0, i
	end
	return val, j
end

---Parses an object value of a JSON string
---@param str string The entire JSON string
---@param i number The current index in the string
---@return table val Value of the object
---@return number end_pos The position after the ending of the object
local function parse_object(str, i)
	local val = {}
	local key = nil
	local j = utils.next_non_space(str, i)
	local possible_starts_array = utils.create_key_array(Value_function_map)
	while j <= #str do
		if string.sub(str, j, j) == "}" then
			return val, utils.next_non_space(str, j)
		end
		if key == nil then
			key, j = parse_string(str, j)
			j = utils.next_non_space(str, j - 1)
			local char = string.sub(str, j, j)
			if char ~= ":" then
				utils.throw_decode_error(j, string.format("Could not find : after key %s", key))
				return {}, i
			end
		else
			local char = string.sub(str, j, j)
			if utils.is_value_in_table(possible_starts_array, char) then
				val[key], j = Value_function_map[char](str, j)
				key = nil
				j = utils.next_non_space(str, j - 1)
				if string.sub(str, j, j) == "}" then
					return val, utils.next_non_space(str, j)
				end
			end
		end
		j = utils.next_non_space(str, j)
	end

	utils.throw_decode_error(i, "Could not finish object")
	return val, i
end

---Parses an array value of a JSON string
---@param str string The entire JSON string
---@param i number The current index in the string
---@return table val Value of the
---@return number end_pos The position after the ending of the array
local function parse_array(str, i)
	local val = {}
	local array_index = 1
	local j = i + 1
	while j <= #str do
		local char = string.sub(str, j, j)
		local key_array = utils.create_key_array(Value_function_map)

		if string.sub(str, j, j) == "]" then
			return val, utils.next_non_space(str, j)
		end
		if utils.is_value_in_table(key_array, char) then
			val[array_index], j = Value_function_map[char](str, j)
			array_index = array_index + 1
			if string.sub(str, j, j) == "]" then
				return val, utils.next_non_space(str, j)
			end
		end
		j = utils.next_non_space(str, j)
	end
	utils.throw_decode_error(i, "Array did not close")
	return val, i
end

---Parses a literal value of a JSON literal
---@param str string The entire JSON string
---@param i number The current index in the string
---@return boolean|nil val Value of the literal
---@return number end_pos The position after the ending of the literal
local function parse_literal(str, i)
	local j = i
	local val
	while j <= i + 5 do --5=Length of the longest literal(false)
		local sequence = string.sub(str, i, j)
		if utils.is_value_in_table(literals, sequence) then
			if sequence == "true" then
				val = true
			elseif sequence == "false" then
				val = false
			else
				val = nil
			end
			return val, j + 1
		end
		j = j + 1
	end
	utils.throw_decode_error(i, "Unsupported literal")
	return nil, i
end
local function parse(json_string)
	local i = utils.next_non_space(json_string, 0)
	local char = string.sub(json_string, i, i)
	local key_array = utils.create_key_array(Value_function_map)
	if utils.is_value_in_table(key_array, char) then
		return Value_function_map[char](json_string, i)
	else
		utils.throw_decode_error(1, "INVALID START")
	end
end

Value_function_map = {
	["{"] = parse_object,
	["["] = parse_array,
	["0"] = parse_number, -- Number
	["1"] = parse_number, -- Number
	["2"] = parse_number, -- Number
	["3"] = parse_number, -- Number
	["4"] = parse_number, -- Number
	["5"] = parse_number, -- Number
	["6"] = parse_number, -- Number
	["7"] = parse_number, -- Number
	["8"] = parse_number, -- Number
	["9"] = parse_number, -- Number
	["-"] = parse_number, -- Number (Negative)
	['"'] = parse_string,
	["t"] = parse_literal, -- true
	["f"] = parse_literal, -- false
	["n"] = parse_literal, -- null
}

return {
	parse_object = parse_object,
	parse = parse,
}

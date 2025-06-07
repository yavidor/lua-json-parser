---Is a value in a table
---@param tbl table The table to search in
---@param val any The value to find
---@return boolean is_found Is the value in the table
local function is_value_in_table(tbl, val)
	for _, value in pairs(tbl) do
		if val == value then
			return true
		end
	end
	return false
end

---comment
---@param tbl table
local function create_key_array(tbl)
	local ret = {}
	for key, _ in pairs(tbl) do
		table.insert(ret, key)
	end
	return ret
end

---Throws a json decoding error, shows index and message
---@param i number The index in the JSON string
---@param message string A description of the problem
local function throw_decode_error(i, message)
	error(string.format("ERROR in position %s: %s", i, message))
end

---Find the next non space character
---@param str string String to search
---@param i number starting index
---@return number next Index of next non space character
local function next_non_space(str, i)
	local j = i + 1
	while j <= #str do
		local char = string.sub(str, j, j)
		if char ~= " " then
			return j
		end
		j = j + 1
	end
	return i
end

---Find the next comma character
---@param str string String to search
---@param i number starting index
---@return number next Index of next comma character
local function next_non_comma(str, i)
	local j = i + 1
	while j <= #str do
		local char = string.sub(str, j, j)
		if char ~= "," then
			return j
		end
		j = j + 1
	end
	return i
end

local function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

return {
	throw_decode_error = throw_decode_error,
	is_value_in_table = is_value_in_table,
	next_non_space = next_non_space,
	next_non_comma = next_non_comma,
	dump = dump,
	create_key_array = create_key_array,
}

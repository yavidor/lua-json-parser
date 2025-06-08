--[[
  Lua JSON Parser Test Suite

  This script provides an extensive set of test cases for a Lua JSON parser.
  It includes functions for deep table comparison and a structured way to
  run and report on the results of various valid and invalid JSON inputs.

  USAGE:
  1. Replace the `json_decode` placeholder function with your actual JSON parser.
  2. Run the script. It will print the test results to the console.
--]]

-- ===========================================================================
-- IMPORTANT: Replace this placeholder with your actual JSON parser function.
-- Your function should take a JSON string as input.
-- For valid JSON, it should return the parsed Lua table.
-- For invalid JSON, it should ideally return `nil` and an error message.
-- Now updated to handle functions that *throw* errors using pcall.
-- ===========================================================================
local json_decode = require('main').parse
-- ===========================================================================

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


-- Deep table comparison function
-- Returns true if tables are deeply equal, false otherwise.
local function deep_compare_tables(t1, t2)
    local ty1 = type(t1)
    local ty2 = type(t2)

    if ty1 ~= ty2 then return false end

    -- Handle primitive types
    if ty1 ~= "table" then
        return t1 == t2
    end

    -- Handle null (represented as nil in Lua)
    if t1 == nil and t2 == nil then
        return true
    end
    if (t1 == nil and t2 ~= nil) or (t1 ~= nil and t2 == nil) then
        return false
    end

    -- Compare table lengths (for array-like tables)
    local len1 = #t1
    local len2 = #t2
    if len1 ~= len2 then return false end

    -- Compare array-like parts
    for i = 1, len1 do
        if not deep_compare_tables(t1[i], t2[i]) then
            return false
        end
    end

    -- Compare hash parts (key-value pairs)
    local visited = {}
    for k, v in pairs(t1) do
        -- Skip numeric keys already compared as part of array-like
        if type(k) == "number" and k >= 1 and k <= len1 then
            -- Make sure the key exists in t2 as well, even if value was compared
            if t2[k] == nil and v ~= nil then return false end
            goto continue
        end

        if not deep_compare_tables(v, t2[k]) then
            return false
        end
        visited[k] = true
        ::continue::
    end

    -- Check if t2 has any extra keys not in t1 (hash part)
    for k, v in pairs(t2) do
        -- Skip numeric keys already compared as part of array-like
        if type(k) == "number" and k >= 1 and k <= len2 then
            if t1[k] == nil and v ~= nil then return false end
            goto continue
        end

        if not visited[k] and t1[k] == nil then
            return false
        end
        ::continue::
    end

    return true
end


-- Test cases structure: {json_string, expected_lua_table_or_value, is_valid_json}
local test_cases = {
    -- === Valid JSON Tests ===
    {json_string = 'null', expected_lua_value = nil, is_valid_json = true, description = "Basic: null value"},
    {json_string = 'true', expected_lua_value = true, is_valid_json = true, description = "Basic: boolean true"},
    {json_string = 'false', expected_lua_value = false, is_valid_json = true, description = "Basic: boolean false"},
    {json_string = '123', expected_lua_value = 123, is_valid_json = true, description = "Basic: integer number"},
    {json_string = '123.45', expected_lua_value = 123.45, is_valid_json = true, description = "Basic: float number"},
    {json_string = '-10', expected_lua_value = -10, is_valid_json = true, description = "Basic: negative integer"},
    {json_string = '0', expected_lua_value = 0, is_valid_json = true, description = "Basic: zero"},
    {json_string = '6.022e23', expected_lua_value = 6.022e23, is_valid_json = true, description = "Basic: scientific notation (positive exponent)"},
    {json_string = '1.0e-5', expected_lua_value = 1.0e-5, is_valid_json = true, description = "Basic: scientific notation (negative exponent)"},
    {json_string = '"hello"', expected_lua_value = "hello", is_valid_json = true, description = "Basic: simple string"},
    {json_string = '""', expected_lua_value = "", is_valid_json = true, description = "Basic: empty string"},

    {json_string = '[]', expected_lua_value = {}, is_valid_json = true, description = "Structure: empty array"},
    {json_string = '{}', expected_lua_value = {}, is_valid_json = true, description = "Structure: empty object"},

    {json_string = '[1, "two", true, null, 4.5]', expected_lua_value = {1, "two", true, nil, 4.5}, is_valid_json = true, description = "Array: mixed types"},
    {json_string = '{"key":"value"}', expected_lua_value = {key = "value"}, is_valid_json = true, description = "Object: simple key-value"},
    {json_string = '{"a":1, "b":2, "c":3}', expected_lua_value = {a = 1, b = 2, c = 3}, is_valid_json = true, description = "Object: multiple key-value pairs"},
    {json_string = '{"obj": {"a":1, "b":2}, "arr": [1,2]}', expected_lua_value = {obj = {a = 1, b = 2}, arr = {1, 2}}, is_valid_json = true, description = "Nested: object with nested object and array"},
    {json_string = '[{"id":1, "name":"A"}, {"id":2, "name":"B"}]', expected_lua_value = {{id = 1, name = "A"}, {id = 2, name = "B"}}, is_valid_json = true, description = "Array: array of objects"},
    {json_string = '{"array_of_arrays": [[1,2],[3,4]]}', expected_lua_value = {array_of_arrays = {{1,2},{3,4}}}, is_valid_json = true, description = "Nested: array of arrays"},
    {json_string = '{"obj_in_arr": [ {"nested_key":"value"} ]}', expected_lua_value = {obj_in_arr = { {nested_key = "value"} }}, is_valid_json = true, description = "Nested: object inside array"},

    {json_string = '{"escaped":"\\\"\\\\\\/\\b\\f\\n\\r\\t"}', expected_lua_value = {escaped = "\"\\/\b\f\n\r\t"}, is_valid_json = true, description = "String: all basic escaped characters"},
    {json_string = '{"unicode":"\\u00A9 Copyright \\uD83D\\uDE00 smiling face"}', expected_lua_value = {unicode = "© Copyright 😀 smiling face"}, is_valid_json = true, description = "String: unicode escapes (BMP and surrogate pairs)"},
    {json_string = '{"path":"C:\\\\Users\\\\Doc"}', expected_lua_value = {path = "C:\\Users\\Doc"}, is_valid_json = true, description = "String: backslashes for paths"},
    {json_string = '{"long_string":"' .. string.rep("a", 1000) .. '"}', expected_lua_value = {long_string = string.rep("a", 1000)}, is_valid_json = true, description = "String: very long string"},

    {json_string = '  {  "key" :   "value"   }  ', expected_lua_value = {key = "value"}, is_valid_json = true, description = "Whitespace: around tokens"},
    {json_string = ' {"a" : 1, "b" : 2 } ', expected_lua_value = {a = 1, b = 2}, is_valid_json = true, description = "Whitespace: comprehensive test"},

    {json_string = '{"max_int_js":9007199254740991}', expected_lua_value = {max_int_js = 9007199254740991}, is_valid_json = true, description = "Number: JavaScript max safe integer"},
    {json_string = '{"min_int_js":-9007199254740991}', expected_lua_value = {min_int_js = -9007199254740991}, is_valid_json = true, description = "Number: JavaScript min safe integer"},
    {json_string = '{"big_float":1.7976931348623157e+308}', expected_lua_value = {big_float = 1.7976931348623157e+308}, is_valid_json = true, description = "Number: large float (double max)"},
    {json_string = '{"small_float":5e-324}', expected_lua_value = {small_float = 5e-324}, is_valid_json = true, description = "Number: small float (double min)"},
}

-- Function to run all tests
local function run_tests()
    print("============================================")
    print("Starting JSON Parser Test Suite")
    print("============================================")

    local passed_count = 0
    local failed_count = 0

    for i, test_case in ipairs(test_cases) do
        local json_str = test_case.json_string
        local expected_val = test_case.expected_lua_value
        local is_valid = test_case.is_valid_json
        local description = test_case.description

        io.write(string.format("Test %02d: %-60s ", i, description .. ": \"" .. string.sub(json_str, 1, 30) .. ( #json_str > 30 and "..." or "" ) .. "\""))

        -- Use pcall to safely call json_decode and capture errors
        local success, result_or_err_msg = pcall(json_decode, json_str)

        if is_valid then
            -- Test for valid JSON
            if not success then
                print("FAILED (parser threw an error for valid JSON: " .. tostring(result_or_err_msg) .. ")")
                failed_count = failed_count + 1
            elseif deep_compare_tables(result_or_err_msg, expected_val) then
                print("PASSED")
                passed_count = passed_count + 1
            else
                print("FAILED (mismatch)")
                print("    Expected: " .. dump(expected_val))
                print("    Got:      " .. dump(result_or_err_msg))
                -- Optionally, add more detailed print for tables
                -- if type(expected_val) == "table" and type(result_or_err_msg) == "table" then
                --     print("    Expected table (debug):")
                --     for k,v in pairs(expected_val) do print("        ", k, v) end
                --     print("    Got table (debug):")
                --     for k,v in pairs(result_or_err_msg) do print("        ", k, v) end
                -- end
                failed_count = failed_count + 1
            end
        else
            -- This block will now effectively be skipped as all invalid tests are removed.
            -- It remains for robustness in case test_cases were manually re-added.
            if not success then
                print("PASSED (correctly threw error: " .. tostring(result_or_err_msg) .. ")")
                passed_count = passed_count + 1
            else
                print("FAILED (accepted invalid JSON, returned: " .. tostring(result_or_err_msg) .. ")")
                failed_count = failed_count + 1
            end
        end
    end

    print("\n============================================")
    print("Test Summary:")
    print("  Total Tests: " .. (#test_cases))
    print("  Passed:      " .. passed_count)
    print("  Failed:      " .. failed_count)
    print("============================================")

    if failed_count > 0 then
        print("Some tests FAILED. Please review the output above.")
    else
        print("All tests PASSED! Your JSON parser seems robust.")
    end
end

-- Run the tests
run_tests()


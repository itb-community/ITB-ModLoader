screen = sdl.screen()

function list_indexof(list, value)
	for k, v in ipairs(list) do
		if value == v then
			return k
		end
	end

	return -1
end

-- Returns true if tables are equal, false otherwise
function compare_tables(tbl1, tbl2)
	local r = true
	for k, v in pairs(tbl1) do
		if type(v) == "table" then
			if not compare_tables(tbl1[k], tbl2[k]) then
				return false
			end
		elseif type(v) == "userdata" then
			-- can't compare userdata, ignore
		else
			if tbl1[k] ~= tbl2[k] then
				return false
			end
		end
	end

	return true
end

-- Allow tables to define custom ipairs handlers.
-- Lua doesn't natively support this in version 5.1.
local __ipairs = ipairs
ipairs = function(t, ...)
	local tt = type(t)
	if (tt == "table" or tt == "userdata") and t.__ipairs then
		return t.__ipairs(t, ...)
	end

	return __ipairs(t, ...)
end

-- Allow tables to define custom pairs handlers.
-- Lua doesn't natively support this in version 5.1.
local __pairs = pairs
pairs = function(t, ...)
	local tt = type(t)
	if (tt == "table" or tt == "userdata") and t.__pairs then
		return t.__pairs(t, ...)
	end

	return __pairs(t, ...)
end

-- checks if the given bit is set in the value
function is_bit_set(value, bit)
	return value % (bit + bit) >= bit
end

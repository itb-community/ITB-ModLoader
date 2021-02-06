
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

--[[
	A function construct to emulate try-catch-finally blocks from regular programming languages.

	Usage:
		try(function()
			-- some code that throw a lua error
			error("error!")
		end)
		:catch(function(err)
			-- function to handle the error
			LOG(err)
		end)
		:finally(function()
			-- actions to always perform, even when the function in `try` doesn't
			-- throw an error
			LOG("Finally block")
		end)
--]]
function try(func)
	local ok, err = pcall(func)
	local handled = ok
	return {
		catch = function(self, handle)
			if not ok then
				if handle then
					handle(err)
					handled = true
				end
			end
			return self
		end,
		finally = function(self, handle)
			handle()
			if not handled then
				error(err)
			end
			return self
		end
	}
end

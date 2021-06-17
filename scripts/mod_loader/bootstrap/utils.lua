
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

--[[
	A function construct to emulate switch blocks from regular programming languages.

	Usage:
		-- calling the function 'switch' on a table,
		-- adds the function 'case' to the table,
		-- and returns the same table.

		local my_switch = switch{
			-- functions to handle cases
			[1] = function() LOG("case 1") end,
			[2] = function() LOG("case 2") end,
			-- function to handle the default case
			default = function() LOG("default case") end,
		}

		my_switch:case(1)
		-- result: LOG("case 1")
		my_switch:case(2)
		-- result: LOG("case 2")
		my_switch:case(3)
		-- result: LOG("default case")
--]]
function switch(t)
	t.default = t.default or function() end
	t.case = function(self, case, ...)
		local f = self[case] or self.default
		local args = {...}
		-- pack case into return as the final parameter
		args[#args+1] = case

		return f(unpack(args))
	end
	return t
end


Assert = {}
Assert.Traceback = true

local function traceback()
	return Assert.Traceback and debug.traceback("\n", 3) or ""
end

function Assert.Equals(expected, actual, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected '%s', but was '%s'%s", tostring(expected), tostring(actual), traceback())
	assert(expected == actual, msg)
end

function Assert.NotEquals(notExpected, actual, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected '%s' to not be equal to '%s'%s", tostring(actual), tostring(notExpected), traceback())
	assert(notExpected ~= actual, msg)
end

function Assert.True(condition, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected 'true', but was '%s'%s", tostring(condition), traceback())
	assert(condition == true, msg)
end

function Assert.False(condition, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected 'false', but was '%s'%s", tostring(condition), traceback())
	assert(condition == false, msg)
end

function Assert.TypePoint(arg, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected Point, but was %s%s", tostring(type(arg)), traceback())
	assert(type(arg) == "userdata" and type(arg.x) == "number" and type(arg.y) == "number", msg)
end

function Assert.BoardStateEquals(expected, actual, msg)
	msg = (msg and msg .. ": ") or ""

	for index, expectedState in ipairs(expected.tiles) do
		local msg = msg .. expectedState.loc:GetLuaString()
		Assert.TableEquals(expectedState, actual.tiles[index], msg)
	end

	for index, expectedState in ipairs(expected.pawns) do
		local msg = msg .. expectedState.loc:GetLuaString()
		Assert.TableEquals(expectedState, actual.pawns[index], msg)
	end
end

function Assert.TableEquals(expected, actual, msg)
	local differences = {}
	for k, v in pairs(expected) do
		if v ~= actual[k] then
			table.insert(differences, k)
		end
	end

	msg = msg and (msg .. "\n") or ""
	msg = msg .. "Table state mismatch:\n"
	for _, k in ipairs(differences) do
		msg = msg .. string.format("- %s: expected %s, but was %s", k, tostring(expected[k]), tostring(actual[k]))
	end

	if #differences > 0 then
		error(msg .. traceback())
	end
end

function Assert.ResourceDatIsOpen(msg)
	msg = (msg and msg .. ": ") or ""
	assert(modApi.resource ~= nil, msg .. "Resource.dat is closed. It can only be modified while mods are initializing" .. traceback())
end

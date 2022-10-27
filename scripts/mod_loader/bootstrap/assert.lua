
Assert = {}
Assert.Traceback = true

local function traceback()
	return Assert.Traceback and debug.traceback("\n", 3) or ""
end

local function get_string(expected)
	if type(expected) == 'table' then
		local msg = ""
		
		for i, v in ipairs(expected) do
			msg = msg .."'".. tostring(v) .."'"
			
			if #expected > i then
				msg = msg .. (#expected == i+1 and " or " or ", ")
			end
		end
		
		return msg
	end
	
	return "'".. tostring(expected) .."'"
end

local function has_equal(expected, actual)
	if type(expected) == 'table' then
		for _, v in ipairs(expected) do
			if v == actual then
				return true
			end
		end
		
		return false
	end
	
	return expected == actual
end

function Assert.Error(msg)
	msg = (msg and msg .. ": ") or ""
	error(msg..traceback())
end

function Assert.ShouldError(func, args, msg)
	msg = (msg and msg .. ": ") or ""

	local ok = xpcall(function() func(unpack(args)) end, function(err) end)
	assert(not ok, msg)
end

function Assert.Equals(expected, actual, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected %s, but was '%s'%s", get_string(expected), tostring(actual), traceback())
	assert(has_equal(expected, actual), msg)
end

function Assert.NotEquals(notExpected, actual, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected '%s' to not be equal to %s%s", tostring(actual), get_string(notExpected), traceback())
	assert(not has_equal(notExpected, actual), msg)
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

function Assert.Range(from, to, actual, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected 'number' in range [%s,%s], but was '%s'%s", from, to, tostring(actual), traceback())
	assert(actual >= from and actual <= to, msg)
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

function Assert.ModInitializingOrLoading(msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .."No mod currently initializing or loading".. traceback()
	assert(modApi.currentMod ~= nil, msg)
end

function Assert.FileExists(filePath, msg)
	msg = (msg and msg .. ": ") or ""
	assert(type(filePath) == 'string', msg .. string.format("Expected 'string', but was '%s'%s", type(filePath), traceback()))
	assert(modApi:fileExists(filePath), msg .. string.format("File '%s' could not be found%s", filePath, traceback()))
end

function Assert.DirectoryExists(dirPath, msg)
	msg = (msg and msg .. ": ") or ""
	assert(type(dirPath) == 'string', msg .. string.format("Expected 'string', but was '%s'%s", type(dirPath), traceback()))
	assert(modApi:directoryExists(dirPath), msg .. string.format("Directory '%s' could not be found%s", dirPath, traceback()))
end

local function getCurrentModResourcePath()
	return mod_loader.mods[modApi.currentMod].resourcePath
end

function Assert.FileRelativeToCurrentModExists(filePathRelativeToCurrentMod, msg)
	Assert.ModInitializingOrLoading(msg)
	Assert.FileExists(getCurrentModResourcePath() .. filePathRelativeToCurrentMod, msg)
end

function Assert.DirectoryRelativeToCurrentModExists(dirPathRelativeToCurrentMod, msg)
	Assert.ModInitializingOrLoading(msg)
	Assert.DirectoryExists(getCurrentModResourcePath() .. dirPathRelativeToCurrentMod, msg)
end


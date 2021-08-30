--[[
	Loads the specified file, loading any global variable definitions
	into the specified table instead of the global namespace (_G).
	The file can still access variables defined in _G, but not write to
	them by default (unless specifically doing _G.foo = bar).

	Last arg can be omitted, defaulting to an empty table.
--]]
function modApi:loadIntoEnv(scriptPath, envTable)
	envTable = envTable or {}
	assert(type(envTable) == "table", "Environment must be a table")
	assert(type(scriptPath) == "string", "Path is not a string")

	setmetatable(envTable, { __index = _G })
	assert(pcall(setfenv(
		assert(loadfile(scriptPath)),
		envTable
	)))
	setmetatable(envTable, nil)

	return envTable
end

local function getUpvaluesOfFunction(func)
	local variables = {}

	local idx = 1
	while true do
		local ln, lv = debug.getupvalue(func, idx)
		if not ln then break end

		variables[ln] = lv

		idx = 1 + idx
	end

	return variables
end

local function setUpvalueForFunction(func, name, value)
	local idx = 1
	while true do
		local ln, lv = debug.getupvalue(func, idx)
		if not ln then break end

		if ln == name then
			debug.setupvalue(func, idx, value)
		end

		idx = 1 + idx
	end
end

local function buildFunctionWithReplacedExecutionEnvironment(func, env)
	return function(...)
		local realfenv = getfenv(func)

		local upvalues = getUpvaluesOfFunction(func)
		upvalues.__func = func
		table.insert(env.__upvalueStack, upvalues)

        setfenv(func, env)

		-- Execute the function
		local args = {...}
		local ok, result = xpcall(
			function()
				return { func(unpack(args)) }
			end,
			function(e)
				return string.format("%s\n%s", e, debug.traceback("Inner stack traceback:", 2))
			end
		)

		-- We can't detect nil upvalues, so look for new upvalues after we executed the function
		for uk, _ in pairs(getUpvaluesOfFunction(func)) do
			if not upvalues[uk] then
				-- Setting table fields to nil is the same as removing them; pairs() ignores them.
				-- Use a nil marker instead
				upvalues[uk] = env.__nil
			end
		end
		setfenv(func, realfenv)

		if ok and type(result) == "table" then
			return unpack(result)
        else
            -- Rethrow the error that occurred when executing the function
            error(result)
        end
	end
end

-- Blacklist built-in lua functions from setfenv override, since it fails
local envFuncBlacklist = {
	"basic",
	"assert",
	"collectgarbage",
	"dofile",
	"error",
	"getfenv",
	"getmetatable",
	"ipairs",
	"load",
	"loadfile",
	"loadstring",
	"module",
	"next",
	"pairs",
	"pcall",
	"print",
	"rawequal",
	"rawget",
	"rawset",
	"require",
	"select",
	"setfenv",
	"setmetatable",
	"tonumber",
	"tostring",
	"type",
	"unpack",
	"xpcall",
	"LOG"
}
local envTblBlacklist = {
	"coroutine",
	"debug",
	"io",
	"math",
	"os",
	"package",
	"string",
	"table"
}
local function isBlacklisted(inputTable, key, envTable)
	if key and inputTable == envTable and list_contains(envFuncBlacklist, key) then
		return true
	end

	for _, name in ipairs(envTblBlacklist) do
		if envTable[name] == inputTable then
			return true
		end
	end

	return false
end

local buildLazyIndexer = nil
buildLazyIndexer = function(parent, envTable)
	return function(inputTable, key)
		-- Fetch real value from parent table
		local v = parent[key]

        if type(v) == "table" then
			-- If the value is a table, replace it with a mock, too
			v = setmetatable({}, { __index = buildLazyIndexer(v, envTable) })
			-- Store the mock in fake table, so that we don't create it multiple times (lazy init)
			inputTable[key] = v
		elseif type(v) == "function" then
			if not isBlacklisted(inputTable, key, envTable) then
				-- Functions called from within the script need to be wrapped in order to have their environment replaced, too
				-- otherwise, simply doing a = 5 will create variable a in real _G
				v = buildFunctionWithReplacedExecutionEnvironment(v, envTable)
				inputTable[key] = v
			end
		end

		return v
	end
end

--[[
	Executes the function or script inside of a sandboxed environment, (hopefully completely) separate from the
	"real" environment used by the game. 

	Returns 3 values, in the specified order:
		- the table that served as the global table for the script, which holds all globals it defined;
		- boolean value indicating whether an error occurred during the script's exeuction;
		- result of the script's execution (if it returned any value, and no error occurred), or error text if an error occurred.
	
	Example usage:
		local env, ok, result = modApi:runInEnv("return 5")

		if ok then
			-- happy path, use the script's result
			LOG(5 + result)
		else
			-- script failed, handle errors
			LOG(result)
		end
--]]
function modApi:runInEnv(func, envTable)
	envTable = envTable or {}
	assert(type(func) == "function" or type(func) == "string", "Argument #1 must be a function or a string")
	assert(type(envTable) == "table", "Argument #2 must be a table")

	if type(func) == "string" then
		func = loadstring(func)
	end

	-- Prepare the sandbox environment
	envTable.__upvalueStack = {}
	envTable.__nil = function() end
	local realG = _G
	_G = envTable
	envTable._G = envTable

	envTable = setmetatable(envTable, {
		-- Whenever we try to read a value that doesn't exist in envTable, this function will be called
		__index = buildLazyIndexer(realG, envTable)
	})

	local upvalues = getUpvaluesOfFunction(func)
	upvalues.__func = func
	table.insert(envTable.__upvalueStack, upvalues)

	local realfenv = getfenv(func)
	setfenv(func, envTable)
	
	-- Execute the function in sandboxed environment
	local ok, result = xpcall(
		func,
		function(e)
			return string.format(
				"Error in function executed by modApi:runInEnv call: %s\n\n%s",
				e, debug.traceback("Outer stack traceback:", 2)
			)
		end
	)

	-- Undo sandbox, restore original upvalues
	for i = #envTable.__upvalueStack, 1, -1 do
		local upvalues = envTable.__upvalueStack[i]
		local func = upvalues.__func
		upvalues.__func = nil

		for k, v in pairs(upvalues) do
			if v == envTable.__nil then
				v = nil
			end

			setUpvalueForFunction(func, k, v)
		end
	end
	setmetatable(envTable, nil)
	_G = realG
	envTable.__nil = nil
	envTable.__upvalueStack = nil

	setfenv(func, realfenv)

	return envTable, ok, result
end

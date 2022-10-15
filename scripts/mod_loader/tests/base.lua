-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////
-- Useful things for tests
Tests = Tests or {}

function Tests.RequireBoard()
	assert(Board ~= nil, "Error: this test requires a Board to be available" .. "\n" .. debug.traceback("", 2))
end

function Tests.GetCleanTile()
	local tiles = randomize(extract_table(Board:GetTiles()))

	for i, p in ipairs(tiles) do
		if not Board:IsPawnSpace(p) then
			Board:ClearSpace(p)
			return p
		end
	end

	error("Error: no non-pawn tile available")
end

function Tests.GetNonUniqueBuildingTile()
	local tiles = randomize(extract_table(Board:GetTiles()))

	for i, p in ipairs(tiles) do
		if not Board:IsPawnSpace(p) then
			if not Board:IsUniqueBuilding(p) then
				Board:ClearSpace(p)
				return p
			end
		end
	end

	error("Error: no non-pawn, non-unique-building tile available")
end

function Tests.ExecuteWhenCondition(resultTable, executeFn, conditionFn)
	Assert.Equals("table", type(resultTable), "Argument #1")
	Assert.Equals("function", type(executeFn), "Argument #2")
	Assert.Equals("function", type(conditionFn), "Argument #3")

	modApi:conditionalHook(
		conditionFn,
		function()
			local ok, err = xpcall(
				executeFn,
				function(e)
					return string.format("%s:\n%s", e, debug.traceback("", 2))
				end
			)

			if not ok then
				resultTable.result = err
			end
		end
	)
end

function Tests.SafeRunLater(resultTable, fn)
	Assert.Equals("table", type(resultTable), "Argument #1")
	Assert.Equals("function", type(fn), "Argument #2")

	modApi:runLater(function()
		local ok, err = xpcall(
			fn,
			function(e)
				return string.format("%s:\n%s", e, debug.traceback("", 2))
			end
		)

		if not ok then
			resultTable.result = err
		end
	end)
end

function Tests.GetTileState(loc)
	Assert.Equals("userdata", type(loc), "Argument #1")

	local state = {}

	state.loc = loc
	state.terrain = Board:GetTerrain(loc)
	state.damaged = Board:IsDamaged(loc)
	state.fire = Board:IsFire(loc)
	state.acid = Board:IsAcid(loc)
	state.smoke = Board:IsSmoke(loc)
	state.pod = Board:IsPod(loc)
	state.frozen = Board:IsFrozen(loc)
	state.spawning = Board:IsSpawning(loc)

	return state
end

function Tests.GetPawnState(arg1)
	local typ = type(arg1)
	assert(typ == "userdata" or typ == "number", "Argument #1: Expected userdata or number, but got " .. typ)

	local pawn = nil
	if typ == "userdata" then
		if type(arg1.x) == "number" and type(arg1.y) == "number" then
			-- point
			pawn = Board:GetPawn(arg1)
		elseif type(arg1.GetId) == "function" then
			-- pawn userdata
			pawn = arg1
		end
	else
		-- id
		pawn = Board:GetPawn(arg1)
	end

	local pawnState = {}

	pawnState.id = pawn:GetId()
	pawnState.loc = pawn:GetSpace()
	pawnState.health = pawn:GetHealth()
	pawnState.isFrozen = pawn:IsFrozen()
	pawnState.isShield = pawn:IsShield()
	pawnState.isAcid = pawn:IsAcid()
	pawnState.isDead = pawn:IsDead()

	return pawnState
end

function Tests.PointToIndex(point, rowWidth)
	rowWidth = rowWidth or 8
	return point.y * rowWidth + point.x
end

function Tests.GetBoardState()
	local result = {}
	result.tiles = {}
	result.pawns = {}

	for y = 0, 7 do
		for x = 0, 7 do
			local point = Point(x, y)
			local index = Tests.PointToIndex(point)

			result.tiles[index] = Tests.GetTileState(point)
			if Board:IsPawnSpace(point) then
				result.pawns[index] = Tests.GetPawnState(point)
			end
		end
	end

	return result
end

--[[
	Builder function for pawn tests, handling most of the common boilerplate

	Input table can can contain several functions with the following names; the functions
	are executed in the order listed:
	- globalSetup   - Executed in non-sandboxed context. Should only be used to set up things that
	                  *have* to be global, eg. adding a new pawn type for Board:AddPawn()
	- prepare       - Executed in sandboxed context. Use to set up things used by the test, eg.
	                  create pawns, change the Board, etc.
	- execute       - Sandboxed. Execute the actions that the test is supposed to verify.
	- check         - Sandboxed, executed once the Board is no longer busy. Verify that the
	                  actions performed in 'execute' have had their intended outcome.
	- checkAwait    - Sandboxed. When this function returns true, the cleanup step is executed.
	                  Waits until the board is not busy by default.
	- cleanup       - Sandboxed. Cleanup the things that have been done in 'prepare', eg. remove
	                  the created pawns, undo Board changes, etc.
	- globalCleanup - Non-sandboxed. Should only be used to cleanup the things that have been
	                  done in 'globalSetup'.
--]]
function Tests.BuildPawnTest(testFunctionsTable)
	return function(resultTable)
		Tests.RequireBoard()
		resultTable = resultTable or {}

		local noop = function() end
		local handleError = function(err)
			resultTable.ok = false
			resultTable.result = err
		end

		local globalSetup = testFunctionsTable.globalSetup or noop
		local prepare = testFunctionsTable.prepare or noop
		local execute = testFunctionsTable.execute or noop
		local checkAwait = testFunctionsTable.checkAwait or function() return Board and not Board:IsBusy() end
		local check = testFunctionsTable.check or noop
		local cleanup = testFunctionsTable.cleanup or noop
		local globalCleanup = testFunctionsTable.globalCleanup or noop

		local fenv = setmetatable({}, { __index = _G })
		setfenv(prepare, fenv)
		setfenv(execute, fenv)
		setfenv(checkAwait, fenv)
		setfenv(check, fenv)
		setfenv(cleanup, fenv)

		local expectedBoardState = Tests.GetBoardState()

		try(function()
			globalSetup()

			prepare()

			execute()
		end)
		:catch(handleError)

		if resultTable.ok == nil and resultTable.result == nil then
			modApi:runLater(function()
				Tests.ExecuteWhenCondition(
					resultTable,
					function()
						try(function()
							try(check)
							:finally(cleanup)

							Assert.BoardStateEquals(expectedBoardState, Tests.GetBoardState(), "Tested operation had side effects")

							resultTable.result = true
						end)
						:finally(globalCleanup)
					end,
					checkAwait
				)
			end)
		else
			try(cleanup)
			:finally(globalCleanup)
		end
	end
end

-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////
-- Testsuite class

local function findTestsuiteName(testsuite, holder)
	holder = holder or Testsuites
	
	for k, v in pairs(holder) do
		if v == testsuite then
			return k, true
		elseif type(v) == "table" then
			local name, r = findTestsuiteName(testsuite, v)
			if r then
				return name
			end
		end
	end

	return "unknown testsuite", false
end

Tests.Testsuite = Class.new()

function Tests.Testsuite:new()
end

--[[
	Lists all tests in this Testsuite.
	All functions that start with "test_" are considered as tests.
	All tables whose __index is set to the Testsuite class are considered as testsuites.

	Returns two tables with the schema:
	- tests: [ { name, func } ]
	- testsuites: [ { name, suite } ]

	The tables are sorted by the objects' names.

	Usage:
		local tests, testsuites = myTestsuite:EnumerateTestsAndTestsuites()
--]]
function Tests.Testsuite:EnumerateTestsAndTestsuites()
	local tests = {}
	local testsuites = {}

	-- Enumerate all tests
	for k, v in pairs(self) do
		if type(v) == "function" and modApi:stringStartsWith(k, "test_") then
			table.insert(tests, { name = k, func = v, parent = self })
		elseif type(v) == "table" and Class.instanceOf(v, Tests.Testsuite) then
			table.insert(testsuites, { name = k, suite = v, parent = self })
		end
	end

	-- Sort them before returning
	local lexicalSort = function(a, b)
		return a.name < b.name
	end

	table.sort(tests, lexicalSort)
	table.sort(testsuites, lexicalSort)

	return tests, testsuites
end

function Tests.Testsuite:EnumerateTests(isRecursive, checkFn)
	local tests = {}

	-- Enumerate all tests
	for k, v in pairs(self) do
		if type(v) == "function" and modApi:stringStartsWith(k, "test_") then
			if not checkFn or checkFn(self, k, v) then
				table.insert(tests, { name = k, func = v, parent = self })
			end
		elseif isRecursive and type(v) == "table" and Class.instanceOf(v, Tests.Testsuite) then
			local nestedTests = v:EnumerateTests(isRecursive, checkFn)
			for i, v in ipairs(nestedTests) do
				table.insert(tests, v)
			end
		end
	end

	-- Sort them before returning
	local lexicalSort = function(a, b)
		return a.name < b.name
	end

	table.sort(tests, lexicalSort)

	return tests
end

--[[
	Returns a string representation of this testsuite, listing all tests it contains
	and nested testsuites.

	Usage:
		LOG(Testsuites:GetString())
--]]
function Tests.Testsuite:GetString(holder, indent)
	indent = indent or 0
	local buildIndent = function() return string.rep("    ", indent) end

	local testsuiteName = findTestsuiteName(self, holder)

	local tests, testsuites = self:EnumerateTestsAndTestsuites()

	local testsMsg = ""
	for _, entry in ipairs(tests) do
		testsMsg = testsMsg .. string.format(
				"\n%s- %s",
				buildIndent(),
				entry.name
		)
	end

	local testsuitesMsg = ""
	for _, entry in pairs(testsuites) do
		testsuitesMsg = testsuitesMsg .. string.format(
				"\n%s- %s",
				buildIndent(),
				entry.suite:GetString(self, indent + 1)
		)
	end

	return testsuiteName .. ": " .. testsMsg .. testsuitesMsg
end

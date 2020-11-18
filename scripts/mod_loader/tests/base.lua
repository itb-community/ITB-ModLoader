-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////
-- Useful things for tests
Tests = {}

function Tests.RequireBoard()
	assert(Board ~= nil, "Error: this test requires a Board to be available" .. "\n" .. debug.traceback("", 2))
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

Tests.Testsuite.STATUS_READY_TO_RUN_TEST = "READY_TO_RUN_TEST"
Tests.Testsuite.STATUS_WAITING_FOR_TEST_FINISH = "WAITING_FOR_TEST_FINISH"
Tests.Testsuite.STATUS_READY_TO_PROCESS_RESULTS = "READY_TO_PROCESS_RESULTS"
Tests.Testsuite.STATUS_READY_TO_RUN_NESTED_TESTS = "READY_TO_RUN_NESTED_TESTS"
Tests.Testsuite.STATUS_WAITING_FOR_NESTED_FINISH = "WAITING_FOR_NESTED_FINISH"
Tests.Testsuite.STATUS_COMPLETED = "COMPLETED"

function Tests.Testsuite:new()
	self.onTestsuiteStarting = Event()
	self.onTestsuiteCompleted = Event()
	self.onTestSubmitted = Event()
	self.onTestStarted = Event()
	self.onTestSuccess = Event()
	self.onTestFailed = Event()
	self.onStatusChanged = Event()

	self.status = Tests.Testsuite.STATUS_COMPLETED
end

function Tests.Testsuite:ChangeStatus(newStatus)
	local oldStatus = self.status
	self.status = newStatus

	self.onStatusChanged:fire(self, oldStatus, newStatus)
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
		local tests, testsuites = myTestsuite:EnumerateTests()
--]]
function Tests.Testsuite:EnumerateTests()
	local tests = {}
	local testsuites = {}

	-- Enumerate all tests
	for k, v in pairs(self) do
		if type(v) == "function" and modApi:stringStartsWith(k, "test_") then
			table.insert(tests, { name = k, func = v })
		elseif type(v) == "table" and Class.instanceOf(v, Tests.Testsuite) then
			table.insert(testsuites, { name = k, suite = v })
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

	local tests, testsuites = self:EnumerateTests()

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

function Tests.Testsuite:RunAllTests(testsuiteName, testEnumeratorFn, isSecondaryCall)
	testsuiteName = testsuiteName or findTestsuiteName(self)
	testEnumeratorFn = testEnumeratorFn or self.EnumerateTests
	isSecondaryCall = isSecondaryCall or false
	Assert.Equals("string", type(testsuiteName), "Argument #1")
	Assert.Equals("function", type(testEnumeratorFn), "Argument #2")
	Assert.Equals("boolean", type(isSecondaryCall), "Argument #3")

	local tests, testsuites = testEnumeratorFn(self)
	self.onTestsuiteStarting:fire(self, tests, testsuites)

	-- Shuffle the tests table so that we run tests in random order
	tests = randomize(tests)
	testsuites = randomize(testsuites)

	local message = string.format("Running testuite '%s'", testsuiteName)
	LOG(string.rep("=", string.len(message)))
	LOG(message)

	local resultsHolder = {}
	self:RunTests(tests, resultsHolder)

	self:ProcessResults(testsuiteName, resultsHolder)

	self:RunNestedTestsuites(testsuiteName, testsuites, testEnumeratorFn, true)

	modApi:conditionalHook(
		function()
			return self.status == Tests.Testsuite.STATUS_COMPLETED
		end,
		function()
			DoSaveGame()
			self.onTestsuiteCompleted:fire(self)
		end
	)

	self:ChangeStatus(Tests.Testsuite.STATUS_READY_TO_RUN_TEST)
end

function Tests.Testsuite:RunTests(tests, resultsHolder)
	Assert.Equals("table", type(tests), "Argument #1")
	Assert.Equals("table", type(resultsHolder), "Argument #2")

	modApi:conditionalHook(
		function()
			return self.status == Tests.Testsuite.STATUS_READY_TO_RUN_TEST
		end,
		function()
			-- Suppress log output so that the results stay somewhat readable
			local pendingTests = #tests
			for _, entry in ipairs(tests) do
				self.onTestSubmitted:fire(entry)

				modApi:conditionalHook(
					function()
						return self.status == Tests.Testsuite.STATUS_READY_TO_RUN_TEST
					end,
					function()
						self:ChangeStatus(Tests.Testsuite.STATUS_WAITING_FOR_TEST_FINISH)
						self.onTestStarted:fire(entry)

						LOG("    Running test", entry.name)

						local resultTable = {}
						resultTable.done = false
						resultTable.name = entry.name

						local ok, result = pcall(function()
							return entry.func(resultTable)
						end)

						resultTable.ok = resultTable.ok or ok
						resultTable.result = resultTable.result or result

						table.insert(resultsHolder, resultTable)

						modApi:conditionalHook(
							function()
								return not ok or not resultTable.ok or resultTable.result ~= nil or resultTable.done
							end,
							function()
								self:ChangeStatus(Tests.Testsuite.STATUS_READY_TO_RUN_TEST)
								if resultTable.ok and resultTable.result == true then
									self.onTestSuccess:fire(entry, resultTable)
									LOG("    Success:", entry.name)
								else
									self.onTestFailed:fire(entry, resultTable)
									LOG("    FAILURE:", entry.name)
								end
								pendingTests = pendingTests - 1
							end
						)
					end
				)
			end

			modApi:conditionalHook(
				function()
					return pendingTests == 0
				end,
				function()
					self:ChangeStatus(Tests.Testsuite.STATUS_READY_TO_PROCESS_RESULTS)
				end
			)
		end
	)
end

function Tests.Testsuite:ProcessResults(testsuiteName, results)
	Assert.Equals("string", type(testsuiteName), "Argument #1")
	Assert.Equals("table", type(results), "Argument #2")

	modApi:conditionalHook(
		function()
			return self.status == Tests.Testsuite.STATUS_READY_TO_PROCESS_RESULTS
		end,
		function()
			local failedTests = {}
			for _, entry in ipairs(results) do
				-- 'result' is also used to hold error information, so compare it to true
				if not (entry.ok and entry.result == true) then
					table.insert(failedTests, entry)
				end
			end

			if #results > 0 then
				LOG(string.format("Testsuite '%s' summary: passed %s / %s tests", testsuiteName, #results - #failedTests, #results))

				for _, entry in ipairs(failedTests) do
					LOG(string.format("%s.%s:", testsuiteName, entry.name), entry.result)
				end
			end

			self:ChangeStatus(Tests.Testsuite.STATUS_READY_TO_RUN_NESTED_TESTS)
		end
	)
end

function Tests.Testsuite:RunNestedTestsuites(testsuiteName, testsuites, testEnumeratorFn, isSecondaryCall)
	Assert.Equals("string", type(testsuiteName), "Argument #1")
	Assert.Equals("table", type(testsuites), "Argument #2")
	Assert.Equals("function", type(testEnumeratorFn), "Argument #3")
	Assert.Equals("boolean", type(isSecondaryCall), "Argument #4")

	modApi:conditionalHook(
		function()
			return self.status == Tests.Testsuite.STATUS_READY_TO_RUN_NESTED_TESTS
		end,
		function()
			local pendingNestedTests = #testsuites
			if pendingNestedTests > 0 then
				for _, entry in ipairs(testsuites) do
					modApi:conditionalHook(
						function()
							return self.status == Tests.Testsuite.STATUS_READY_TO_RUN_NESTED_TESTS
						end,
						function()
							self:ChangeStatus(Tests.Testsuite.STATUS_WAITING_FOR_NESTED_FINISH)
							entry.suite:RunAllTests(string.format("%s.%s", testsuiteName, entry.name), testEnumeratorFn, isSecondaryCall)

							modApi:conditionalHook(
								function()
									return entry.suite.status == nil or entry.suite.status == Tests.Testsuite.STATUS_COMPLETED
								end,
								function()
									self:ChangeStatus(Tests.Testsuite.STATUS_READY_TO_RUN_NESTED_TESTS)
									pendingNestedTests = pendingNestedTests - 1
								end
							)
						end
					)
				end
			end

			modApi:conditionalHook(
				function()
					return pendingNestedTests == 0
				end,
				function()
					self:ChangeStatus(Tests.Testsuite.STATUS_COMPLETED)
				end
			)
		end
	)
end

-- Useful things for tests
Tests = {}

function Tests.AssertEquals(expected, actual, msg)
	msg = msg or ""
	msg = msg .. string.format("Expected %s, but was %s", tostring(expected), tostring(actual))
	assert(expected == actual, msg)
end

function Tests.RequireBoard()
	assert(Board ~= nil, "Error: this test requires a Board to be available")
end

function Tests.SafeRunLater(resultTable, fn)
	Tests.AssertEquals(type(resultTable), "table", "Argument #1: ")
	Tests.AssertEquals(type(fn), "function", "Argument #2: ")

	modApi:conditionalHook(
		function()
			return Board and not Board:IsBusy()
		end,
		function()
			local ok, err = xpcall(
				fn,
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

function Tests.GetTileState(loc)
	Tests.AssertEquals(type(loc), "userdata", "Argument #1: ")

	local state = {}

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

function Tests.AssertTileStateEquals(expected, actual, msg)
	local differences = {}
	for k, v in pairs(expected) do
		if v ~= actual[k] then
			table.insert(differences, k)
		end
	end

	msg = msg and (msg .. "\n") or ""
	msg = msg .. "Tile state mismatch:\n"
	for _, k in ipairs(differences) do
		msg = msg .. string.format("- %s: expected %s, but was %s\n", k, expected[k], actual[k])
	end

	if #differences > 0 then
		error(msg)
	end
end


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

Tests.Testsuite.STATUS_PENDING = "PENDING"
Tests.Testsuite.STATUS_READY_TO_RUN_TEST = "READY_TO_RUN_TEST"
Tests.Testsuite.STATUS_WAITING_FOR_TEST_FINISH = "WAITING_FOR_TEST_FINISH"
Tests.Testsuite.STATUS_READY_TO_PROCESS_RESULTS = "READY_TO_PROCESS_RESULTS"
Tests.Testsuite.STATUS_READY_TO_RUN_NESTED_TESTS = "READY_TO_RUN_NESTED_TESTS"
Tests.Testsuite.STATUS_WAITING_FOR_NESTED_FINISH = "WAITING_FOR_NESTED_FINISH"

function Tests.Testsuite:new()
end

function Tests.Testsuite:RunAllTests(testsuiteName)
	testsuiteName = testsuiteName or findTestsuiteName(self)
	Tests.AssertEquals(type(testsuiteName), "string", "Argument #1: ")

	self.status = Tests.Testsuite.STATUS_PENDING

	local tests = {}
	local testsuites = {}

	-- Enumerate all tests
	for k, v in pairs(self) do
		if type(v) == "function" and modApi:stringStartsWith(k, "test_") then
			table.insert(tests, { name = k, func = v })
		elseif type(v) == "table" and modApi:stringStartsWith(k, "testsuite_") then
			table.insert(testsuites, { name = k, suite = v })
		end
	end

	-- Shuffle the tests table so that we run tests in random order
	tests = randomize(tests)
	testsuites = randomize(testsuites)
	
	local message = string.format("Running testuite '%s'\n", testsuiteName)
	LOG(string.rep("=", string.len(message)))
	LOG(message)

	-- Suppress log output so that the results stay somewhat readable
	local log = LOG
	LOG = function() end

	local resultsHolder = {}
	self:RunTests(tests, resultsHolder)

	self:ProcessResults(testsuiteName, resultsHolder)

	self:RunNestedTestsuites(testsuiteName, testsuites)

	modApi:conditionalHook(
		function()
			return self.status == Tests.Testsuite.STATUS_READY_TO_PROCESS_RESULTS
		end,
		function()
			LOG = log
		end
	)
end

function Tests.Testsuite:RunTests(tests, resultsHolder)
	Tests.AssertEquals(type(tests), "table", "Argument #1: ")
	Tests.AssertEquals(type(resultsHolder), "table", "Argument #2: ")

	self.status = Tests.Testsuite.STATUS_READY_TO_RUN_TEST

	local pendingTests = #tests
	for _, entry in ipairs(tests) do
		modApi:conditionalHook(
			function()
				return self.status == Tests.Testsuite.STATUS_READY_TO_RUN_TEST
			end,
			function()
				self.status = Tests.Testsuite.STATUS_WAITING_FOR_TEST_FINISH

				local resultTable = {}
				resultTable.done = false
				resultTable.name = entry.name

				local ok, result = pcall(function()
					return entry.func(resultTable)
				end)

				resultTable.ok = ok
				resultTable.result = result

				table.insert(resultsHolder, resultTable)

				modApi:conditionalHook(
					function()
						return not (ok and resultTable.result == nil and not resultTable.done)
					end,
					function()
						self.status = Tests.Testsuite.STATUS_READY_TO_RUN_TEST
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
			self.status = Tests.Testsuite.STATUS_READY_TO_PROCESS_RESULTS
		end
	)
end

function Tests.Testsuite:ProcessResults(testsuiteName, results)
	Tests.AssertEquals(type(testsuiteName), "string", "Argument #1: ")
	Tests.AssertEquals(type(results), "table", "Argument #2: ")

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

			LOG(string.format("Testsuite '%s' summary: passed %s / %s tests", testsuiteName, #results - #failedTests, #results))

			for _, entry in ipairs(failedTests) do
				LOG(string.format("%s.%s:", testsuiteName, entry.name), entry.result)
			end
		end
	)
end

function Tests.Testsuite:RunNestedTestsuites(testsuiteName, testsuites)
	Tests.AssertEquals(type(testsuiteName), "string", "Argument #1: ")
	Tests.AssertEquals(type(testsuites), "table", "Argument #2: ")

	modApi:conditionalHook(
		function()
			return self.status == Tests.Testsuite.STATUS_READY_TO_RUN_NESTED_TESTS
		end,
		function()
			local pendingNestedTests = #testsuites
			if pendingNestedTests > 0 then
				LOG(string.format("Testsuite '%s': running %s nested testuites", testsuiteName, #testsuites))
				for _, entry in ipairs(testsuites) do
					modApi:conditionalHook(
						function()
							return self.status == Tests.Testsuite.STATUS_READY_TO_RUN_NESTED_TESTS
						end,
						function()
							self.status = Tests.Testsuite.STATUS_WAITING_FOR_NESTED_FINISH
							entry.suite:RunAllTests(string.format("%s.%s", testsuiteName, entry.name))

							modApi:conditionalHook(
								function()
									return entry.suite.status == nil
								end,
								function()
									self.status = Tests.Testsuite.STATUS_READY_TO_RUN_NESTED_TESTS
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
					self.status = nil
				end
			)
		end
	)
end


-- Holder for testsuites
Testsuites = {}
function Testsuites.RunAllTests()
	for k, v in pairs(Testsuites) do
		if type(v) == "table" then
			v:RunAllTests(k)
		end
	end
end

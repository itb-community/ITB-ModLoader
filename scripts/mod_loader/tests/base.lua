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

function Tests.GetTileState(loc)
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

Tests.Testsuite = Class.new()
function Tests.Testsuite:new()
end

function Tests.Testsuite:RunAllTests(testsuiteName)
	Tests.AssertEquals(type(testsuiteName), "string", "Argument #1: ")

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
	
	local message = string.format("Testuite '%s'\n", testsuiteName)
	LOG(string.rep("=", string.len(message)))
	LOG(message)

	local resultsHolder = {}
	self:RunTests(tests, resultsHolder)

	self:ProcessResults(testsuiteName, resultsHolder)

	self:RunNestedTestsuites(testsuiteName, testsuites)
end

function Tests.Testsuite:RunTests(tests, resultsHolder)
	Tests.AssertEquals(type(tests), "table", "Argument #1: ")
	Tests.AssertEquals(type(resultsHolder), "table", "Argument #2: ")
	
	-- Suppress log output so that the results stay somewhat readable
	local log = LOG
	LOG = function() end

	for _, entry in ipairs(tests) do
		local resultTable = {}
		resultTable.name = entry.name

		local ok, result = pcall(function()
			return entry.func(resultTable)
		end)

		resultTable.ok = ok
		if not resultTable.result then
			resultTable.result = result
		end

		table.insert(resultsHolder, resultTable)
	end

	LOG = log
end

function Tests.Testsuite:ProcessResults(testsuiteName, results)
	Tests.AssertEquals(type(testsuiteName), "string", "Argument #1: ")
	Tests.AssertEquals(type(results), "table", "Argument #2: ")

	local successfulTestCount = 0

	for _, entry in ipairs(results) do
		if entry.ok and entry.result then
			successfulTestCount = successfulTestCount + 1
		end
	end

	LOG(string.format("Testsuite '%s' summary: passed %s / %s tests", testsuiteName, successfulTestCount, #results))
end

function Tests.Testsuite:RunNestedTestsuites(testsuiteName, testsuites)
	Tests.AssertEquals(type(testsuiteName), "string", "Argument #1: ")
	Tests.AssertEquals(type(testsuites), "table", "Argument #2: ")

	if #testsuites > 0 then
		LOG(string.format("Testsuite '%s': running %s nested testuites", testsuiteName, #testsuites))
		for _, entry in ipairs(testsuites) do
			entry.suite:RunAllTests(string.format("%s.%s", testsuiteName, entry.name))
		end
	end
end


-- /////////////////////////////////////////////////////////////////////////////////////////
-- BoardTestsuite class

Tests.BoardTestsuite = Class.inherit(Tests.Testsuite)
function Tests.BoardTestsuite:RunTests(tests, resultsHolder)
	local log = LOG
	LOG = function() end
	
	self.__super.RunTests(self, tests, resultsHolder)
	modApi:runLater(function()
		LOG = log
	end)
end

function Tests.BoardTestsuite:ProcessResults(testsuiteName, resultsHolder)
	modApi:runLater(function()
		self.__super.ProcessResults(self, testsuiteName, resultsHolder)
	end)
end

function Tests.BoardTestsuite:RunNestedTestsuites(testsuiteName, testsuites)
	modApi:runLater(function()
		self.__super.RunNestedTestsuites(self, testsuiteName, testsuites)
	end)
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

-- Useful things for tests
Tests = {}

function Tests.AssertEquals(expected, actual, msg)
	msg = msg or string.format("Expected %s, but was %s", tostring(expected), tostring(actual))
	assert(expected == actual, msg)
end

-- /////////////////////////////////////////////////////////////////////////////////////////
-- Testsuite class

Tests.Testsuite = Class.new()
function Tests.Testsuite:new()
end

function Tests.Testsuite:RunAllTests(testsuiteName)
	assert(type(testsuiteName) == "string", "Argument #1 must be a string")

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
	self:RunAllTests(tests, resultsHolder)

	self:ProcessResults(testsuiteName, resultsHolder)

	self:RunNestedTestsuites(testsuiteName, testsuites)
end

function Tests.Testsuite:RunTests(tests, resultsHolder)
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
	assert(type(testsuiteName) == "string", "Argument #1 must be a string")

	local successfulTestCount = 0

	for _, entry in ipairs(results) do
		if entry.ok and entry.result then
			successfulTestCount = successfulTestCount + 1
		end
	end

	LOG(string.format("Testsuite '%s' summary: passed %s / %s tests", testsuiteName, successfulTestCount, #results))
end

function Tests.Testsuite:RunNestedTestsuites(testsuiteName, testsuites)
	assert(type(testsuiteName) == "string", "Argument #1 must be a string")

	if #testsuites > 0 then
		LOG(string.format("Testsuite '%s': running %s nested testuites", testsuiteName, #testsuites))
		for _, entry in ipairs(testsuites) do
			entry.suite:RunAllTests(string.format("%s.%s", testsuiteName, entry.name))
		end
	end
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

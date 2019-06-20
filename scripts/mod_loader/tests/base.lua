Tests = {}

function Tests.AssertEquals(expected, actual, msg)
	msg = msg or string.format("Expected %s, but was %s", tostring(expected), tostring(actual))
	assert(expected == actual, msg)
end

Testsuites = {}

local runAllTestsInTestsuite = nil
runAllTestsInTestsuite = function(testsuiteName, testsuite)
	assert(type(testsuiteName) == "string", "RunAllTestsInTestsutie: argument #1 must be a string")
	assert(type(testsuite) == "table", "RunAllTestsInTestsuite: argument #2 must be a table")

	local tests = {}
	local testsuites = {}
	-- Enumerate all tests
	for k, v in pairs(testsuite) do
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

	local successfulTestCount = 0
	for _, entry in ipairs(tests) do
		LOG("Running:", entry.name, "...")

		local ok, result = pcall(entry.func)

		if ok and result then
			successfulTestCount = successfulTestCount + 1
		end
	end

	LOG(string.format("Testsuite '%s' summary: passed %s / %s tests", testsuiteName, successfulTestCount, #tests))

	if #testsuites > 0 then
		LOG(string.format("Testsuite '%s': running %s nested testuites", testsuiteName, #testsuites))
		for _, entry in ipairs(testsuites) do
			runAllTestsInTestsuite(string.format("%s.%s", testsuiteName, entry.name), entry.suite)
		end
	end
end

function Testsuites.RunAllTests(testsuiteName, testsuite)
	if type(testsuiteName) == "table" and not testsuite then
		testsuite = testsuiteName
		testsuiteName = "unknown"
	end

	assert(not testsuiteName or type(testsuiteName) == "string", "RunAlltests: argument #1 must be a string, table or nil")
	assert(not testsuite or type(testsuite) == "table", "RunAllTests: argument #2 must be a table or nil")

	if testsuite then
		runAllTestsInTestsuite(testsuiteName, testsuite)
	else
		for k, v in pairs(Testsuites) do
			if type(v) == "table" then
				runAllTestsInTestsuite(k, v)
			end
		end
	end
end

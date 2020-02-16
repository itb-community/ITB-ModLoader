-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////
-- Useful things for tests
Tests = {}

local function buildErrorMsg(signatures)
	local afterDivider = "^.-|"
	local msg = "No matching overload found, candidates:"
	
	for _, sig in ipairs(signatures) do
		msg = msg .. string.format("\n%s %s(", signatures.ret, signatures.func)
		
		for i = 1, #sig do
			msg = msg .. sig[i]:gsub(afterDivider, "")
			
			if i < #sig then
				msg = msg ..", "
			end
		end
		
		msg = msg ..")"
	end
	
	return msg
end

function Tests.AssertSignature(signatures)
	local beforeDivider = "|.+$"
	local signature_match_found
	
	for _, sig in ipairs(signatures) do
		signature_match_found = #sig == #signatures.params
		
		for i = 1, #sig do
			local param = signatures.params[i]
			local validParam = sig[i]:gsub(beforeDivider, "")
			
			if type(param) ~= validParam then
				signature_match_found = false
			end
		end
		
		if signature_match_found then
			break
		end
	end
	
	assert(signature_match_found, signature_match_found and "" or buildErrorMsg(signatures))
end

function Tests.AssertEquals(expected, actual, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected %s, but was %s", tostring(expected), tostring(actual))
	assert(expected == actual, msg)
end

function Tests.AssertTypePoint(arg, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected Point, but was %s", tostring(type(arg)))
	assert(type(arg) == "userdata" and type(arg.x) == "number" and type(arg.y) == "number", msg)
end

function Tests.AssertBoardStateEquals(expected, actual, msg)
	msg = (msg and msg .. ": ") or ""

	for index, expectedState in ipairs(expected.tiles) do
		local msg = msg .. p2s(expectedState.loc)
		Tests.AssertTableEquals(expectedState, actual.tiles[index], msg)
	end

	for index, expectedState in ipairs(expected.pawns) do
		local msg = msg .. p2s(expectedState.loc)
		Tests.AssertTableEquals(expectedState, actual.pawns[index], msg)
	end
end

function Tests.AssertTableEquals(expected, actual, msg)
	local differences = {}
	for k, v in pairs(expected) do
		if v ~= actual[k] then
			table.insert(differences, k)
		end
	end

	msg = msg and (msg .. "\n") or ""
	msg = msg .. "Table state mismatch:\n"
	for _, k in ipairs(differences) do
		msg = msg .. string.format("- %s: expected %s, but was %s\n", k, tostring(expected[k]), tostring(actual[k]))
	end

	if #differences > 0 then
		error(msg)
	end
end

function Tests.RequireBoard()
	assert(Board ~= nil, "Error: this test requires a Board to be available")
end

function Tests.WaitUntilBoardNotBusy(resultTable, fn)
	Tests.AssertEquals("table", type(resultTable), "Argument #1")
	Tests.AssertEquals("function", type(fn), "Argument #2")

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

function Tests.SafeRunLater(resultTable, fn)
	Tests.AssertEquals("table", type(resultTable), "Argument #1")
	Tests.AssertEquals("function", type(fn), "Argument #2")

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
	Tests.AssertEquals("userdata", type(loc), "Argument #1")

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

function Tests.Testsuite:new()
end

function Tests.Testsuite:RunAllTests(testsuiteName, isSecondaryCall)
	testsuiteName = testsuiteName or findTestsuiteName(self)
	isSecondaryCall = isSecondaryCall or false
	Tests.AssertEquals("string", type(testsuiteName), "Argument #1")
	Tests.AssertEquals("boolean", type(isSecondaryCall), "Argument #2")

	local tests = {}
	local testsuites = {}

	-- Enumerate all tests
	for k, v in pairs(self) do
		if type(v) == "function" and modApi:stringStartsWith(k, "test_") then
			table.insert(tests, { name = k, func = v })
		elseif type(v) == "table" and v.__index == Tests.Testsuite then
			table.insert(testsuites, { name = k, suite = v })
		end
	end

	-- Shuffle the tests table so that we run tests in random order
	tests = randomize(tests)
	testsuites = randomize(testsuites)

	local message = string.format("Running testuite '%s'", testsuiteName)
	LOG(string.rep("=", string.len(message)))
	LOG(message)

	local resultsHolder = {}
	self:RunTests(tests, resultsHolder)

	self:ProcessResults(testsuiteName, resultsHolder)

	self:RunNestedTestsuites(testsuiteName, testsuites, true)

	modApi:conditionalHook(
		function()
			return self.status == nil
		end,
		function()
			DoSaveGame()
		end
	)

	self.status = Tests.Testsuite.STATUS_READY_TO_RUN_TEST
end

function Tests.Testsuite:RunTests(tests, resultsHolder)
	Tests.AssertEquals("table", type(tests), "Argument #1")
	Tests.AssertEquals("table", type(resultsHolder), "Argument #2")

	modApi:conditionalHook(
		function()
			return self.status == Tests.Testsuite.STATUS_READY_TO_RUN_TEST
		end,
		function()
			-- Suppress log output so that the results stay somewhat readable
			local log = LOG
			LOG = function() end

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
					LOG = log
					log = nil
					self.status = Tests.Testsuite.STATUS_READY_TO_PROCESS_RESULTS
				end
			)
		end
	)
end

function Tests.Testsuite:ProcessResults(testsuiteName, results)
	Tests.AssertEquals("string", type(testsuiteName), "Argument #1")
	Tests.AssertEquals("table", type(results), "Argument #2")

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

			self.status = Tests.Testsuite.STATUS_READY_TO_RUN_NESTED_TESTS
		end
	)
end

function Tests.Testsuite:RunNestedTestsuites(testsuiteName, testsuites, isSecondaryCall)
	Tests.AssertEquals("string", type(testsuiteName), "Argument #1")
	Tests.AssertEquals("table", type(testsuites), "Argument #2")
	Tests.AssertEquals("boolean", type(isSecondaryCall), "Argument #3")

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
							self.status = Tests.Testsuite.STATUS_WAITING_FOR_NESTED_FINISH
							entry.suite:RunAllTests(string.format("%s.%s", testsuiteName, entry.name), isSecondaryCall)

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


-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////
-- Holder for testsuites

Testsuites = Tests.Testsuite()
function Testsuites:RunAllTests()
	self.__index.RunAllTests(self, "Testsuites", false)
end

--[[
	Usage, in console while in a mission:
			Testsuites:RunAllTests()
		or:
			Testsuites.name_of_testsuite:RunAllTests()
--]]


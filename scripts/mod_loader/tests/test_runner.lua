Tests.Runner = Class.new()

Tests.Runner.STATUS_READY_TO_RUN_TEST = "READY_TO_RUN_TEST"
Tests.Runner.STATUS_WAITING_FOR_TEST_FINISH = "WAITING_FOR_TEST_FINISH"
Tests.Runner.STATUS_READY_TO_PROCESS_RESULTS = "READY_TO_PROCESS_RESULTS"
Tests.Runner.STATUS_PROCESSING_RESULTS = "PROCESSING_RESULTS"
Tests.Runner.STATUS_COMPLETED = "COMPLETED"
Tests.Runner.STATUS_STARTED = "STARTED"

function Tests.Runner:new()
	self.onTestSubmitted = Event()
	self.onTestStarted = Event()
	self.onTestSuccess = Event()
	self.onTestFailed = Event()
	self.onStatusChanged = Event()

	self.status = Tests.Runner.STATUS_COMPLETED
end

function Tests.Runner:ChangeStatus(newStatus)
	local oldStatus = self.status
	self.status = newStatus

	self.onStatusChanged:dispatch(self, oldStatus, newStatus)
end

--- Convenience function for running directly via console
function Tests.Runner:RunAllTests(testsuite)
	testsuite = testsuite or Testsuites
	self:Start(function() return testsuite:EnumerateTests(true) end)
end

function Tests.Runner:Start(testEnumeratorFn)
	Assert.Equals("function", type(testEnumeratorFn), "Argument #1")

	self:ChangeStatus(Tests.Runner.STATUS_STARTED)

	local tests = testEnumeratorFn()

	-- Shuffle the tests table so that we run tests in random order
	tests = randomize(tests)

	local resultsHolder = {}
	self:RunTests(tests, resultsHolder)

	self:ProcessResults(resultsHolder)

	modApi:conditionalHook(
			function()
				return self.status == Tests.Runner.STATUS_COMPLETED
			end,
			function()
				DoSaveGame()
			end
	)

	self:ChangeStatus(Tests.Runner.STATUS_READY_TO_RUN_TEST)
end

function Tests.Runner:RunTests(tests, resultsHolder)
	Assert.Equals("table", type(tests), "Argument #1")
	Assert.Equals("table", type(resultsHolder), "Argument #2")

	modApi:conditionalHook(
			function()
				return self.status == Tests.Runner.STATUS_READY_TO_RUN_TEST
			end,
			function()
				-- Suppress log output so that the results stay somewhat readable
				local pendingTests = #tests
				for _, entry in ipairs(tests) do
					self.onTestSubmitted:dispatch(entry)

					modApi:conditionalHook(
							function()
								return self.status == Tests.Runner.STATUS_READY_TO_RUN_TEST
							end,
							function()
								self:ChangeStatus(Tests.Runner.STATUS_WAITING_FOR_TEST_FINISH)
								self.onTestStarted:dispatch(entry)

								local resultTable = {}
								resultTable.done = false
								resultTable.name = entry.name
								resultTable.parent = entry.parent

								local ok, result = pcall(function()
									return entry.func(resultTable)
								end)

								resultTable.ok = resultTable.ok or ok
								resultTable.result = resultTable.result or result

								if not resultsHolder[entry.parent] then
									resultsHolder[entry.parent] = {}
								end

								table.insert(resultsHolder[entry.parent], resultTable)

								modApi:conditionalHook(
										function()
											return not ok or not resultTable.ok or resultTable.result ~= nil or resultTable.done
										end,
										function()
											self:ChangeStatus(Tests.Runner.STATUS_READY_TO_RUN_TEST)
											if resultTable.ok and resultTable.result == true then
												self.onTestSuccess:dispatch(entry, resultTable)
											else
												self.onTestFailed:dispatch(entry, resultTable)
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
							self:ChangeStatus(Tests.Runner.STATUS_READY_TO_PROCESS_RESULTS)
						end
				)
			end
	)
end

function Tests.Runner:ProcessResults(results)
	Assert.Equals("table", type(results), "Argument #1")

	modApi:conditionalHook(
			function()
				return self.status == Tests.Runner.STATUS_READY_TO_PROCESS_RESULTS
			end,
			function()
				self:ChangeStatus(Tests.Runner.STATUS_PROCESSING_RESULTS)

				local failedTests = {}
				local failedCount = 0
				local totalCount = 0
				for testsuite, resultTable in pairs(results) do
					failedTests[testsuite] = {}
					local t = failedTests[testsuite]

					totalCount = totalCount + #resultTable
					for _, entry in ipairs(resultTable) do
						-- 'result' is also used to hold error information, so compare it to true
						if not (entry.ok and entry.result == true) then
							failedCount = failedCount + 1
							table.insert(t, entry)
						end
					end
				end

				if totalCount > 0 then
					LOGF("Tests summary: passed %s / %s tests", totalCount - failedCount, totalCount)

					for _, resultTable in pairs(failedTests) do
						for _, entry in ipairs(resultTable) do
							LOGF("%s.%s: %s", entry.parent.name, entry.name, entry.result)
						end
					end
				end

				self:ChangeStatus(Tests.Runner.STATUS_COMPLETED)
			end
	)
end

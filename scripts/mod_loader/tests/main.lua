local rootpath = GetParentPath(...)

local testsuite = Tests.Testsuite()
function testsuite:RunAllTests(testEnumeratorFn)
	self.__index.RunAllTests(self, "Root Testsuite", testEnumeratorFn)
end

testsuite.pawn = require(rootpath.."pawn")
testsuite.sandbox = require(rootpath.."sandbox")
testsuite.cutil = require(rootpath.."cutil/main")

--[[
	Usage, in console while in a mission:
			Testsuites:RunAllTests()
		or:
			Testsuites.name_of_testsuite:RunAllTests()
--]]

Testsuites = testsuite

function RunIndividualTest(testFn)
  local resultTable = {}

  local ok, result = pcall(function() return testFn(resultTable) end)
  resultTable.ok = resultTable.ok or ok
  resultTable.result = resultTable.result or result

  modApi:conditionalHook(
    function() return not ok or not resultTable.ok or resultTable.result ~= nil or resultTable.done end,
    function()
      if resultTable.ok and resultTable.result == true then
        LOG("SUCCESS")
      else
        LOG("FAILURE:", resultTable.result)
      end
    end
  )
end

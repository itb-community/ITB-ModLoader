local rootpath = GetParentPath(...)

local testsuite = Tests.Testsuite()
function testsuite:RunAllTests()
	self.__index.RunAllTests(self, "Root Testsuite", false)
end

testsuite.pawn = require(rootpath.."pawn")
testsuite.sandbox = require(rootpath.."sandbox")

--[[
	Usage, in console while in a mission:
			Testsuites:RunAllTests()
		or:
			Testsuites.name_of_testsuite:RunAllTests()
--]]

Testsuites = testsuite

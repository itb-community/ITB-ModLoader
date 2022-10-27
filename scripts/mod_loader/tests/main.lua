local rootpath = GetParentPath(...)

--[[
	Usage:
		Either use the Tests UI visible in test mech scenario when
		Mod Loader development mode is enabled (recommended),
		or execute one of the following commands in console while in a mission:
			Tests.Runner():RunAllTests()
		or:
			Tests.Runner():RunAllTests(Testsuites.name_of_testsuite)
			eg.: Tests.Runner():RunAllTests(Testsuites.pawn)
--]]
Testsuites = Tests.Testsuite()
Testsuites.name = "Root Testsuite"

Testsuites.pawn = require(rootpath.."pawn")
Testsuites.sandbox = require(rootpath.."sandbox")
Testsuites.classes = require(rootpath.."classes")
Testsuites.event = require(rootpath.."event")
Testsuites.modApi = require(rootpath.."modApi")
Testsuites.vector = require(rootpath.."vector")
Testsuites.text = require(rootpath.."text")
Testsuites.deque = require(rootpath.."deque")
Testsuites.binarySearch = require(rootpath.."binarySearch")

modApi.events.onTestsuitesCreated:dispatch()
modApi.events.onTestsuitesCreated:unsubscribeAll()
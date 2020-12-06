local rootpath = GetParentPath(...)

Testsuites = Tests.Testsuite()

Testsuites.pawn = require(rootpath.."pawn")
Testsuites.sandbox = require(rootpath.."sandbox")
Testsuites.classes = require(rootpath.."classes")
Testsuites.event = require(rootpath.."event")
Testsuites.modApi = require(rootpath.."modApi")


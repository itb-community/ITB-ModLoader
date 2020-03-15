local rootpath = GetParentPath(...)

local testsuite = Tests.Testsuite()
testsuite.pawn = require(rootpath.."pawn")


return testsuite

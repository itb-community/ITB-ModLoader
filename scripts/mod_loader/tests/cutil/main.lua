local rootpath = GetParentPath(...)

local testsuite = Tests.Testsuite()
testsuite.pawn = require(rootpath.."pawn")
testsuite.board = require(rootpath.."board")


return testsuite

local testsuite = Tests.Testsuite()
testsuite.name = "Mod API tests"

-- ///////////////////////////////////////////////////////////////
-- I/O Tests
testsuite.io = Tests.Testsuite()
testsuite.io.name = "I/O"

function testsuite.io.test_FileExistsSlashes()
	Assert.True(modApi:fileExists("./scripts/scripts.lua"))

	return true
end

function testsuite.io.test_FileExistsBackslashes()
	Assert.True(modApi:fileExists(".\\scripts\\scripts.lua"))

	return true
end

function testsuite.io.test_FileExistsMixed()
	Assert.True(modApi:fileExists(".\\scripts/scripts.lua"))

	return true
end

function testsuite.io.test_FileNotExistsGenerated()
	local name = os.date() .. modApi.timer:elapsed()
	Assert.False(modApi:fileExists("./tests/"..name))

	return true
end

function testsuite.io.test_DirectoryExistsSlashes()
	Assert.True(modApi:directoryExists("./scripts/mod_loader"))

	return true
end

function testsuite.io.test_DirectoryExistsBackslashes()
	Assert.True(modApi:directoryExists("./scripts/mod_loader"))

	return true
end

function testsuite.io.test_DirectoryExistsMixed()
	Assert.True(modApi:directoryExists(".\\scripts/mod_loader"))

	return true
end

function testsuite.io.test_DirectoryExistsCurrentDirectory()
	Assert.True(modApi:directoryExists("./scripts/."))

	return true
end

function testsuite.io.test_DirectoryExistsParentDirectory()
	Assert.True(modApi:directoryExists("./scripts/.."))

	return true
end

function testsuite.io.test_DirectoryNotExistsGenerated()
	local name = os.date() .. modApi.timer:elapsed()
	Assert.False(modApi:directoryExists("./tests/"..name))

	return true
end

function testsuite.io.test_GetFileNameSlashes()
	Assert.Equals("mod_loader", GetFileName("./scripts/mod_loader"))

	return true
end

function testsuite.io.test_GetFileNameBackslashes()
	Assert.Equals("mod_loader", GetFileName(".\\scripts\\mod_loader"))

	return true
end

function testsuite.io.test_GetFileNameMixed()
	Assert.Equals("mod_loader", GetFileName(".\\scripts/mod_loader"))

	return true
end

function testsuite.io.test_GetFileNameEmpty()
	Assert.Equals(nil, GetFileName(".\\scripts/mod_loader/"))

	return true
end

-- ///////////////////////////////////////////////////////////////
-- Geometry Tests
testsuite.geometry = Tests.Testsuite()
testsuite.geometry.name = "Geometry"

function testsuite.geometry.test_RectIntersectLeftEdge()
	local r1 = sdl.rect(10, 10, 10, 10)
	local r2 = sdl.rect(0,  10, 10, 10)
	Assert.False(rect_intersects(r1, r2))
	return true
end

function testsuite.geometry.test_RectIntersectTopEdge()
	local r1 = sdl.rect(10, 10, 10, 10)
	local r2 = sdl.rect(10, 0,  10, 10)
	Assert.False(rect_intersects(r1, r2))
	return true
end

function testsuite.geometry.test_RectIntersectRightEdge()
	local r1 = sdl.rect(10, 10, 10, 10)
	local r2 = sdl.rect(20, 10, 10, 10)
	Assert.False(rect_intersects(r1, r2))
	return true
end

function testsuite.geometry.test_RectIntersectBottomEdge()
	local r1 = sdl.rect(10, 10, 10, 10)
	local r2 = sdl.rect(10, 20, 10, 10)
	Assert.False(rect_intersects(r1, r2))
	return true
end

function testsuite.geometry.test_RectIntersectComplete()
	local r1 = sdl.rect(10, 10, 10, 10)
	local r2 = sdl.rect(12, 12, 6, 6)
	Assert.True(rect_intersects(r1, r2))
	return true
end

function testsuite.geometry.test_RectIntersectNone()
	local r1 = sdl.rect(10, 10, 10, 10)
	local r2 = sdl.rect(25, 10, 10, 10)
	Assert.False(rect_intersects(r1, r2))
	return true
end

function testsuite.geometry.test_RectIntersectPartialLeft()
	local r1 = sdl.rect(10, 10, 10, 10)
	local r2 = sdl.rect(5,  12, 10, 6)
	Assert.True(rect_intersects(r1, r2))
	return true
end

function testsuite.geometry.test_RectIntersectPartialTop()
	local r1 = sdl.rect(10, 10, 10, 10)
	local r2 = sdl.rect(12, 5, 6, 10)
	Assert.True(rect_intersects(r1, r2))
	return true
end

function testsuite.geometry.test_RectIntersectPartialRight()
	local r1 = sdl.rect(10, 10, 10, 10)
	local r2 = sdl.rect(15, 12, 10, 6)
	Assert.True(rect_intersects(r1, r2))
	return true
end

function testsuite.geometry.test_RectIntersectPartialBottom()
	local r1 = sdl.rect(10, 10, 10, 10)
	local r2 = sdl.rect(12, 15, 6, 10)
	Assert.True(rect_intersects(r1, r2))
	return true
end

function testsuite.geometry.test_RectContainsLeftEdge()
	local r1 = sdl.rect(0, 0, 10, 10)
	Assert.True(rect_contains(r1, 0, 5))
	return true
end

function testsuite.geometry.test_RectContainsTopEdge()
	local r1 = sdl.rect(0, 0, 10, 10)
	Assert.True(rect_contains(r1, 5, 0))
	return true
end

function testsuite.geometry.test_RectContainsBottomEdge()
	local r1 = sdl.rect(0, 0, 10, 10)
	Assert.False(rect_contains(r1, 5, 10))
	return true
end

function testsuite.geometry.test_RectContainsRightEdge()
	local r1 = sdl.rect(0, 0, 10, 10)
	Assert.False(rect_contains(r1, 10, 5))
	return true
end

function testsuite.geometry.test_RectContainsComplete()
	local r1 = sdl.rect(0, 0, 10, 10)
	Assert.True(rect_contains(r1, 5, 5))
	return true
end

function testsuite.geometry.test_RectContainsOutside()
	local r1 = sdl.rect(0, 0, 10, 10)
	Assert.False(rect_contains(r1, 5, 15))
	return true
end

-- ///////////////////////////////////////////////////////////////
-- Unsorted Tests

function testsuite.test_GetParentPathTerminatedSlashes()
	Assert.Equals("./scripts/", GetParentPath("./scripts/mod_loader/"))

	return true
end

function testsuite.test_GetParentPathNonTerminatedSlashes()
	Assert.Equals("./scripts/", GetParentPath("./scripts/mod_loader"))

	return true
end

function testsuite.test_GetParentPathTerminatedBackslashes()
	Assert.Equals(".\\scripts\\", GetParentPath(".\\scripts\\mod_loader\\"))

	return true
end

function testsuite.test_GetParentPathNonTerminatedBackslashes()
	Assert.Equals(".\\scripts\\", GetParentPath(".\\scripts\\mod_loader"))

	return true
end

function testsuite.test_GetParentPathTerminatedMixed()
	Assert.Equals(".\\scripts/", GetParentPath(".\\scripts/mod_loader/"))

	return true
end

function testsuite.test_GetParentPathNonTerminatedMixed()
	Assert.Equals(".\\scripts/", GetParentPath(".\\scripts/mod_loader"))

	return true
end

return testsuite

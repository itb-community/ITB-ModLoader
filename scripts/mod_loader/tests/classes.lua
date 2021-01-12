local testsuite = Tests.Testsuite()
testsuite.name = "Classes system tests"

local assertTrue = Assert.True
local assertFalse = Assert.False

function testsuite.test_ClassHierarchy()
	local rootClass = Class.new()
	local subClass = rootClass:extend()

	assertTrue(rootClass:isSuperclassOf(subClass))
	assertTrue(subClass:isSubclassOf(rootClass))

	return true
end

function testsuite.test_Instance()
	local rootClass = Class.new()
	local subClass = rootClass:extend()

	local rootInstance = rootClass()
	local subInstance = subClass()

	assertTrue(Class.instanceOf(rootInstance, rootClass))
	assertTrue(Class.instanceOf(subInstance, subClass))

	assertTrue(Class.instanceOf(subInstance, rootClass))
	assertFalse(Class.instanceOf(rootInstance, subClass))

	return true
end

return testsuite

local testsuite = Tests.Testsuite()
testsuite.name = "Classes system tests"

function testsuite.test_ClassHierarchy()
	local rootClass = Class.new()
	local subClass = rootClass:extend()

	Assert.True(rootClass:isSuperclassOf(subClass))
	Assert.True(subClass:isSubclassOf(rootClass))

	return true
end

function testsuite.test_Instance()
	local rootClass = Class.new()
	local subClass = rootClass:extend()

	local rootInstance = rootClass()
	local subInstance = subClass()

	Assert.True(Class.instanceOf(rootInstance, rootClass))
	Assert.True(Class.instanceOf(subInstance, subClass))

	Assert.True(Class.instanceOf(subInstance, rootClass))
	Assert.False(Class.instanceOf(rootInstance, subClass))

	return true
end

return testsuite

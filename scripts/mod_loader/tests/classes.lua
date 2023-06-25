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

function testsuite.test_IterateInstanceAndParents_Vanilla_Class()
	local Object = {
		weight = 10,
		color = "Brown",
	}
	CreateClass(Object)

	local LivingBeing = Object:new{
		breathes = true,
		walks = true,
	}

	local Animal = LivingBeing:new{
		name = "Animal",
		sound = "Roar",
	}

	local output = {}
	local expected = {
		weight = 10,
		color = "Brown",
		breathes = true,
		walks = true,
		name = "Animal",
		sound = "Roar",
	}

	for key, value in iterateInstanceAndParents(Animal:new()) do
		output[key] = value
	end

	Assert.TableEquals(output, expected)

	return true
end

function testsuite.test_IterateInstanceAndParents_ModLoader_Class()
	local Object = Class.new()
	function Object:new()
		self.weight = 10
		self.color = "Brown"
	end

	local LivingBeing = Class.inherit(Object)
	function LivingBeing:new()
		Object.new(self)
		self.breathes = true
		self.walks = true
	end

	local Animal = Class.inherit(LivingBeing)
	function Animal:new()
		LivingBeing.new(self)
		self.name = "Animal"
		self.sound = "Roar"
	end

	local output = {}
	local expected = {
		weight = 10,
		color = "Brown",
		breathes = true,
		walks = true,
		name = "Animal",
		sound = "Roar",
	}

	for key, value in iterateInstanceAndParents(Animal()) do
		output[key] = value
	end

	Assert.TableEquals(output, expected)

	return true
end

return testsuite

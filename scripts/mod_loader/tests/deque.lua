local testsuite = Tests.Testsuite()
testsuite.name = "Double-ended queue tests"

local DequeList = require("scripts/mod_loader/deque_list")

function testsuite.test_constructorValues()
	local list = DequeList(1, 2, 3)

	Assert.Equals(3, list:size())
	Assert.Equals(1, list:peekLeft())
	Assert.Equals(3, list:peekRight())

	return true
end

function testsuite.test_constructorTable()
	local t = {1, 2, 3}
	local list = DequeList(t)

	Assert.Equals(3, list:size())
	Assert.Equals(1, list:peekLeft())
	Assert.Equals(3, list:peekRight())

	return true
end

function testsuite.test_pushAllLeftValues()
	local list = DequeList()

	list:pushAllLeft(1, 2, 3)

	Assert.Equals(3, list:size())
	Assert.Equals(3, list:peekLeft())
	Assert.Equals(1, list:peekRight())

	return true
end

function testsuite.test_pushAllLeftTable()
	local list = DequeList()

	list:pushAllLeft({1, 2, 3})

	Assert.Equals(3, list:size())
	Assert.Equals(3, list:peekLeft())
	Assert.Equals(1, list:peekRight())

	return true
end

function testsuite.test_pushAllRightValues()
	local list = DequeList()

	list:pushAllRight(1, 2, 3)

	Assert.Equals(3, list:size())
	Assert.Equals(1, list:peekLeft())
	Assert.Equals(3, list:peekRight())

	return true
end

function testsuite.test_ipairsOverload()
	local list = DequeList(1, 2, 3)

	local s = ""
	for _, v in ipairs(list) do
		s = s .. v
	end

	Assert.Equals("123", s)

	return true
end

function testsuite.test_pushAllRightTable()
	local list = DequeList()

	list:pushAllRight({1, 2, 3})

	Assert.Equals(3, list:size())
	Assert.Equals(1, list:peekLeft())
	Assert.Equals(3, list:peekRight())

	return true
end

function testsuite.test_ipairsLeft()
	local list = DequeList(1, 2, 3)

	local s = ""
	for _, v in list:ipairsLeft() do
		s = s .. v
	end

	Assert.Equals("123", s)

	return true
end

function testsuite.test_ipairsRight()
	local list = DequeList(1, 2, 3)

	local s = ""
	for _, v in list:ipairsRight() do
		s = s .. v
	end

	Assert.Equals("321", s)

	return true
end

return testsuite
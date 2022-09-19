local testsuite = Tests.Testsuite()
testsuite.name = "BinarySearch tests"

local TEXT_ERROR = "Returned index of binary search for %s"

local function err(key)
	return string.format(TEXT_ERROR, key)
end

function testsuite.test_binary_search_exact()
	local array = {10, 20, 30}

	Assert.Equals(1, BinarySearch(10, array), err("value 10"))
	Assert.Equals(2, BinarySearch(20, array), err("value 20"))
	Assert.Equals(3, BinarySearch(30, array), err("value 30"))
	Assert.Equals(nil, BinarySearch(0, array), err("value 0"))
	Assert.Equals(nil, BinarySearch(19, array), err("value 19"))
	Assert.Equals(nil, BinarySearch(21, array), err("value 21"))
	Assert.Equals(nil, BinarySearch(40, array), err("value 40"))

	return true
end

function testsuite.test_binary_search_nearest()
	local array = {10, 20, 30}

	Assert.Equals(1, BinarySearch(10, array, "nearest"), err("value 10"))
	Assert.Equals(2, BinarySearch(20, array, "nearest"), err("value 20"))
	Assert.Equals(3, BinarySearch(30, array, "nearest"), err("value 30"))
	Assert.Equals(1, BinarySearch(0, array, "nearest"), err("value 0"))
	Assert.Equals(2, BinarySearch(19, array, "nearest"), err("value 19"))
	Assert.Equals(2, BinarySearch(21, array, "nearest"), err("value 21"))
	Assert.Equals(3, BinarySearch(40, array, "nearest"), err("value 40"))

	return true
end

function testsuite.test_binary_search_up()
	local array = {10, 20, 30}

	Assert.Equals(1, BinarySearch(10, array, "up"), err("value 10"))
	Assert.Equals(2, BinarySearch(20, array, "up"), err("value 20"))
	Assert.Equals(3, BinarySearch(30, array, "up"), err("value 30"))
	Assert.Equals(1, BinarySearch(0, array, "up"), err("value 0"))
	Assert.Equals(2, BinarySearch(19, array, "up"), err("value 19"))
	Assert.Equals(3, BinarySearch(21, array, "up"), err("value 21"))
	Assert.Equals(3, BinarySearch(40, array, "up"), err("value 40"))

	return true
end

function testsuite.test_binary_search_down()
	local array = {10, 20, 30}

	Assert.Equals(1, BinarySearch(10, array, "down"), err("value 10"))
	Assert.Equals(2, BinarySearch(20, array, "down"), err("value 20"))
	Assert.Equals(3, BinarySearch(30, array, "down"), err("value 30"))
	Assert.Equals(1, BinarySearch(0, array, "down"), err("value 0"))
	Assert.Equals(1, BinarySearch(19, array, "down"), err("value 19"))
	Assert.Equals(2, BinarySearch(21, array, "down"), err("value 21"))
	Assert.Equals(3, BinarySearch(40, array, "down"), err("value 40"))

	return true
end

function testsuite.test_binary_search_noarray_exact()
	local array = {10, 20, 30}
	local low, high = 1, #array

	local function getValue(key)
		return array[key]
	end

	Assert.Equals(1, BinarySearch(10, low, high, getValue), err("value 10"))
	Assert.Equals(2, BinarySearch(20, low, high, getValue), err("value 20"))
	Assert.Equals(3, BinarySearch(30, low, high, getValue), err("value 30"))
	Assert.Equals(nil, BinarySearch(0, low, high, getValue), err("value 0"))
	Assert.Equals(nil, BinarySearch(19, low, high, getValue), err("value 19"))
	Assert.Equals(nil, BinarySearch(21, low, high, getValue), err("value 21"))
	Assert.Equals(nil, BinarySearch(40, low, high, getValue), err("value 40"))

	return true
end

function testsuite.test_binary_search_noarray_nearest()
	local array = {10, 20, 30}
	local low, high = 1, #array

	local function getValue(key)
		return array[key]
	end

	Assert.Equals(1, BinarySearch(10, low, high, getValue, "nearest"), err("value 10"))
	Assert.Equals(2, BinarySearch(20, low, high, getValue, "nearest"), err("value 20"))
	Assert.Equals(3, BinarySearch(30, low, high, getValue, "nearest"), err("value 30"))
	Assert.Equals(1, BinarySearch(0, low, high, getValue, "nearest"), err("value 0"))
	Assert.Equals(2, BinarySearch(19, low, high, getValue, "nearest"), err("value 19"))
	Assert.Equals(2, BinarySearch(21, low, high, getValue, "nearest"), err("value 21"))
	Assert.Equals(3, BinarySearch(40, low, high, getValue, "nearest"), err("value 40"))

	return true
end

function testsuite.test_binary_search_noarray_up()
	local array = {10, 20, 30}
	local low, high = 1, #array

	local function getValue(key)
		return array[key]
	end

	Assert.Equals(1, BinarySearch(10, low, high, getValue, "up"), err("value 10"))
	Assert.Equals(2, BinarySearch(20, low, high, getValue, "up"), err("value 20"))
	Assert.Equals(3, BinarySearch(30, low, high, getValue, "up"), err("value 30"))
	Assert.Equals(1, BinarySearch(0, low, high, getValue, "up"), err("value 0"))
	Assert.Equals(2, BinarySearch(19, low, high, getValue, "up"), err("value 19"))
	Assert.Equals(3, BinarySearch(21, low, high, getValue, "up"), err("value 21"))
	Assert.Equals(3, BinarySearch(40, low, high, getValue, "up"), err("value 40"))

	return true
end

function testsuite.test_binary_search_noarray_down()
	local array = {10, 20, 30}
	local low, high = 1, #array

	local function getValue(key)
		return array[key]
	end

	Assert.Equals(1, BinarySearch(10, low, high, getValue, "down"), err("value 10"))
	Assert.Equals(2, BinarySearch(20, low, high, getValue, "down"), err("value 20"))
	Assert.Equals(3, BinarySearch(30, low, high, getValue, "down"), err("value 30"))
	Assert.Equals(1, BinarySearch(0, low, high, getValue, "down"), err("value 0"))
	Assert.Equals(1, BinarySearch(19, low, high, getValue, "down"), err("value 19"))
	Assert.Equals(2, BinarySearch(21, low, high, getValue, "down"), err("value 21"))
	Assert.Equals(3, BinarySearch(40, low, high, getValue, "down"), err("value 40"))

	return true
end

return testsuite

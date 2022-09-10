
local array_mt = {
	__index = function(self, key)
		return self.__getValue(key)
	end
}

function BinarySearch(key, array, approximation, arg4, arg5)
	local low, high

	if type(array) == 'table' then
		low, high = 1, #array
	else
		local getValue

		-- Pass over variables from alternate signature.
		key, low, high, getValue, approximation = key, array, approximation, arg4, arg5

		array = { __getValue = getValue }
		setmetatable(array, array_mt)
	end

	if high <= low then
		return nil
	end

	-- Run binary search until there are 2 or fewer values left.
	while high - low > 1 do
		local mid = math.floor((low + high) / 2)
		local val = array[mid]

		if key > val then
			low = mid
		else
			high = mid
		end
	end

	-- There are only 1 or 2 values left, 'low' and 'high'.
	if approximation == "nearest" then
		local low_diff = math.abs(key - array[low])
		local high_diff = math.abs(key - array[high])

		if low_diff < high_diff then
			return low
		else
			return high
		end
	elseif approximation == "up" then
		if key > array[low] then
			return high
		else
			return low
		end
	elseif approximation == "down" then
		if key < array[high] then
			return low
		else
			return high
		end
	else
		if key == array[low] then
			return low
		elseif key == array[high] then
			return high
		end
	end
end

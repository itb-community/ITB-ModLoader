
-- Find the element with the smallest return, larger than target.
-- Assumes a list with sorted returns in ascending order.
function BinarySearchMin(left, right, target, compareFn)
	local floor = math.floor
	while left < right do
		local middle = floor((left + right) / 2)
		if compareFn(middle) < target then
			left = middle + 1
		else
			right = middle
		end
	end

	return left
end

-- Find the element with the largest return, smaller than target.
-- Assumes a list with sorted returns in ascending order.
function BinarySearchMax(left, right, target, compareFn)
	local ceil = math.ceil
	while left < right do
		local middle = ceil((left + right) / 2)
		if compareFn(middle) > target then
			right = middle - 1
		else
			left = middle
		end
	end

	return left
end

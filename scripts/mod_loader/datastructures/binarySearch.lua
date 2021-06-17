
function min(left, right, target, compareFn)
	local floor = math.floor
	while left < right do
		local m = floor((left + right) / 2)
		if compareFn(m) < target then
			left = m + 1
		else
			right = m
		end
	end

	return left
end

function max(left, right, target, compareFn)
	local ceil = math.ceil
	while left < right do
		local m = ceil((left + right) / 2)
		if compareFn(m) > target then
			right = m - 1
		else
			left = m
		end
	end

	return left
end

return {
	min = min,
	max = max
}

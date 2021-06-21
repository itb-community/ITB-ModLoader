
--[[
	Gap Buffer:

	A data structure that keeps an imaginary gap between
	positive right side, and the negative left sid out
	to infinity. The lua table will resize when needed.
	Due to how lua works, the table will never shrink.


	imagined:
	[1][2][3]_____[-2][-1][0]
	         ^   ^
	  gap_left   gap_right


	actual:
	_____[-2][-1][0][1][2][3]_____
	    ^                    ^
	gap_right             gap_left


	It works by shifting values from positive to negative
	indices around [0], thus moving the gap.

	To insert or delete values, the gap must be moved to
	the correct index first.

	Values are accessed by indices [1,size]

	Inserting values is O(1) while at the gap
	Inserting values is at worst O(n)
	Deleting values is O(1) while at the gap
	Deleting values is at worst O(n)
	Replacing values is always O(1)
	Reading values are always O(1)
]]

local GapBuffer = Class.new()

function GapBuffer:new()
	self.gap_left = 1
	self.gap_right = 0
end

function GapBuffer:size()
	return self.gap_left - self.gap_right - 1
end

function GapBuffer:move(index)
	if index < self.gap_left then
		self:left(index)
	else
		self:right(index)
	end
end

function GapBuffer:left(index)
	local gap_left = self.gap_left
	local gap_right = self.gap_right

	while index < gap_left do
		gap_left = gap_left - 1
		gap_right = gap_right - 1
		self[gap_right+1] = self[gap_left]
		self[gap_left] = nil
	end

	self.gap_left = gap_left
	self.gap_right = gap_right
end

function GapBuffer:right(index)
	local gap_left = self.gap_left
	local gap_right = self.gap_right

	while index > gap_left do
		gap_left = gap_left + 1
		gap_right = gap_right + 1
		self[gap_left-1] = self[gap_right]
		self[gap_right] = nil
	end

	self.gap_left = gap_left
	self.gap_right = gap_right
end

function GapBuffer:get(index)
	local size = self:size()
	if index < 1 or index > size then
		return nil
	end

	if index >= self.gap_left then
		index = index - self:size()
	end

	return self[index]
end

function GapBuffer:set(index, value)
	Assert.Range(1, self:size(), index, "index is out of bounds")

	if index >= self.gap_left then
		index = index - self:size()
	end

	self[index] = value
end

function GapBuffer:insert(index, value)
	Assert.Range(1, self:size() + 1, index, "index is out of bounds")
	
	if index ~= self.gap_left then
		self:move(index)
	end

	self[self.gap_left] = value
	self.gap_left = self.gap_left + 1
end

function GapBuffer:delete(index, length)
	if length == nil then length = 1 end
	self:deleteAfter(index, length)
end

function GapBuffer:deleteBefore(index, length)
	local size = self:size()

	if index < 1 or index > size + 1 then
		return
	end

	if length > index - 1 then
		length = index - 1
	end

	if index ~= self.gap_left then
		self:move(index)
	end

	local gap_left = self.gap_left
	while gap_left > index - length do
		self[gap_left-1] = nil
		gap_left = gap_left - 1
	end

	self.gap_left = gap_left
end

function GapBuffer:deleteAfter(index, length)
	local size = self:size()

	if index < 1 or index > size then
		return
	end

	if length > size + 1 - index then
		length = size + 1 - index
	end

	if index + length ~= self.gap_left then
		self:move(index + length)
	end

	local gap_left = self.gap_left
	while gap_left > index do
		self[gap_left-1] = nil
		gap_left = gap_left - 1
	end

	self.gap_left = gap_left
end

function GapBuffer:GetLuaString()
    local buffer = {"{"}

	local size = self:size()

	for i = 1, size do
		local value = self:get(i)
		if type(value) == 'userdata' and value.GetLuaString then
			value = value:GetLuaString()
		end
		buffer[#buffer+1] = string.format("    [%s] = %s", i, tostring(value))
	end

	buffer[#buffer+1] = "}"

	return table.concat(buffer, "\n")
end

local StringGapBuffer = Class.inherit(GapBuffer)

function StringGapBuffer:getSingle(index)
	local size = self:size()
	if index < 1 or index > size then
		return nil
	end

	if index >= self.gap_left then
		index = index - size
	end

	return self[index]
end

function StringGapBuffer:get(index, length)
	local size = self:size()
	if index < 1 or index > size then
		return nil
	end

	if length == nil then
		length = 1
	elseif length < 1 then
		return nil
	elseif length > size + 1 - index then
		length = size + 1 - index
	end

	local buffer = {}
	local gap_left = self.gap_left
	for i = 1, length do
		if index >= gap_left then
			index = index - size
		end
		buffer[#buffer+1] = self[index]
		index = index + 1
	end

	return table.concat(buffer)
end

function StringGapBuffer:insert(index, string)
	Assert.Range(1, self:size() + 1, index, "index is out of bounds")

	local length = string:len()

	if index ~= self.gap_left then
		self:move(index)
	end

	local gap_left = self.gap_left
	for i = 1, length do
		self[gap_left] = string:sub(i,i)
		gap_left = gap_left + 1
	end

	self.gap_left = gap_left
end

function StringGapBuffer:GetLuaString()
	return self:get(1, self:size())
end

return {
	obj = GapBuffer,
	string = StringGapBuffer
}

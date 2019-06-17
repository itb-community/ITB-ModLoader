---------------------------------------------------------------
-- Deque list object (queue/stack)

--[[
	Double-ended queue implementation via www.lua.org/pil/11.4.html
	Modified to use the class system from ItB mod loader.

	To use like a queue: use either pushLeft() and popRight()  OR  pushRight() and popLeft()

	To use like a stack: use either pushLeft() and popLeft()  OR  pushRight() and popRight()
--]]
local List = Class.new()

function List:new(tbl)
	self.first = 0
	self.last = -1

	if tbl then
		for _, v in ipairs(tbl) do
			self:pushRight(v)
		end
	end
end

--[[
	Pushes the element onto the left side of the dequeue (start)
--]]
function List:pushLeft(value)
	local first = self.first - 1
	self.first = first
	self[first] = value
end

--[[
	Pushes the element onto the right side of the dequeue (end)
--]]
function List:pushRight(value)
	local last = self.last + 1
	self.last = last
	self[last] = value
end

--[[
	Removes and returns an element from the left side of the dequeue (start)
--]]
function List:popLeft()
	local first = self.first
	if first > self.last then error("list is empty") end
	local value = self[first]
	self[first] = nil -- to allow garbage collection
	self.first = first + 1
	return value
end

--[[
	Removes and returns an element from the right side of the dequeue (end)
--]]
function List:popRight()
	local last = self.last
	if self.first > last then error("list is empty") end
	local value = self[last]
	self[last] = nil -- to allow garbage collection
	self.last = last - 1
	return value
end

--[[
	Returns an element from the left side of the dequeue (start) without removing it
--]]
function List:peekLeft(index)
	if self.first > self.last then error("list is empty") end
	if not index then index = 1 end
	return self[self.first + index - 1]
end

--[[
	Returns an element from the right side of the dequeue (end) without removing it
--]]
function List:peekRight()
	if self.first > self.last then error("list is empty") end
	if not index then index = 1 end
	return self[self.last - index + 1]
end

--[[
	Returns true if this dequeue is empty
--]]
function List:isEmpty()
	return self.first > self.last
end

--[[
	Returns size of the dequeue
--]]
function List:size()
	if self:isEmpty() then
		return 0
	else
		return self.last - self.first + 1
	end
end

return List

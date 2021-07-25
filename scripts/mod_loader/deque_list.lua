--- Deque list object (queue/stack)
local List = Class.new()

--- Double-ended queue implementation via www.lua.org/pil/11.4.html
--- Modified to use the class system from ItB mod loader.
---
--- To use like a queue: use either pushLeft() and popRight()  OR  pushRight() and popLeft()
---
--- To use like a stack: use either pushLeft() and popLeft()  OR  pushRight() and popRight()
function List:new(t, ...)
	self.first = 0
	self.last = -1

	if t then
		self:pushAllRight(t, ...)
	end
end

--- Pushes the element onto the left side of the deque (start)
function List:pushLeft(value)
	local first = self.first - 1
	self.first = first
	self[first] = value
end

--- Pushes the element onto the right side of the deque (end)
function List:pushRight(value)
	local last = self.last + 1
	self.last = last
	self[last] = value
end

--- Convenience shorthand function for List:pushAllLeftTable and List:pushAllLeftVarargs
--- Elements in the deque will be in reverse order compared to the values passed in argument.
function List:pushAllLeft(t, ...)
	if type(t) == "table" then
		self:pushAllLeftTable(t)
	else
		self:pushAllLeftVarargs(t, ...)
	end
end

--- Pushes all elements of the table passed in argument onto the left side of the deque (start)
--- Elements in the deque will be in reverse order compared to the table passed in argument.
function List:pushAllLeftTable(t)
	if Class.instanceOf(t, List) then
		for i, v in t:ipairsLeft() do
			self:pushLeft(v)
		end
	else
		for i, v in ipairs(t) do
			self:pushLeft(v)
		end
	end
end

--- Pushes all arguments onto the left side of the deque (start)
--- Elements in the deque will be in reverse order compared to the values passed in argument.
function List:pushAllLeftVarargs(...)
	for i, v in ipairs({...}) do
		self:pushLeft(v)
	end
end

--- Convenience shorthand function for List:pushAllRightTable and List:pushAllRightVarargs
function List:pushAllRight(t, ...)
	if type(t) == "table" then
		self:pushAllRightTable(t)
	else
		self:pushAllRightVarargs(t, ...)
	end
end

--- Pushes all elements of the table passed in argument onto the right side of the deque (end)
function List:pushAllRightTable(t)
	if Class.instanceOf(t, List) then
		for i, v in t:ipairsLeft() do
			self:pushRight(v)
		end
	else
		for i, v in ipairs(t) do
			self:pushRight(v)
		end
	end
end

--- Pushes all arguments onto the right side of the deque (end)
function List:pushAllRightVarargs(...)
	for i, v in ipairs({...}) do
		self:pushRight(v)
	end
end

--- Removes and returns an element from the left side of the deque (start)
function List:popLeft()
	local first = self.first
	if first > self.last then error("list is empty") end
	local value = self[first]
	self[first] = nil -- to allow garbage collection
	self.first = first + 1
	return value
end

--- Removes and returns an element from the right side of the deque (end)
function List:popRight()
	local last = self.last
	if self.first > last then error("list is empty") end
	local value = self[last]
	self[last] = nil -- to allow garbage collection
	self.last = last - 1
	return value
end

--- Returns an element from the left side of the deque (start) without removing it
function List:peekLeft(index)
	if self.first > self.last then error("list is empty") end
	if not index then index = 1 end
	return self[self.first + index - 1]
end

--- Returns an element from the right side of the deque (end) without removing it
function List:peekRight(index)
	if self.first > self.last then error("list is empty") end
	if not index then index = 1 end
	return self[self.last - index + 1]
end

--- Returns true if this deque is empty
function List:isEmpty()
	return self.first > self.last
end

--- Returns size of the deque
function List:size()
	if self:isEmpty() then
		return 0
	else
		return self.last - self.first + 1
	end
end

--- Iterates over elements of the deque from start to end (left to right)
function List:ipairsLeft()
	local index = self.first - 1
	return function()
		if index < self.last then
			index = index + 1
			return index, self[index]
		end
	end
end

--- Iterates over elements of the deque from end to start (right to left)
function List:ipairsRight()
	local index = self.last + 1
	return function()
		if index > self.first then
			index = index - 1
			return index, self[index]
		end
	end
end

--- Iterates over elements of the deque from start to end (left to right)
List.__ipairs = List.ipairsLeft

return List

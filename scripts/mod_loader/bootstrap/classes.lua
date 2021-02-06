local function createInstance(cls, ...)
	local selfMetatable = setmetatable({}, cls)
	selfMetatable.__index = cls
	selfMetatable.__call = function()
		error("attempted to call an instance\n", 2)
	end

	local self = setmetatable({}, selfMetatable)
	self:new(...)
	return self
end

Class = {}
function Class.new()
	local o = {}
	o.__index = o
	o.instanceOf = function(self, cls)
		return getmetatable(self).__index:isSubclassOf(cls)
	end
	setmetatable(o, {
		__index = Class,
		__call = createInstance
	})

	return o
end

function Class.instanceOf(object, cls)
	assert(type(object) == "table")
	assert(type(cls) == "table")

	if object.instanceOf then
		return object:instanceOf(cls)
	else
		return false
	end
end

function Class:isSubclassOf(superClass)
	assert(type(self) == "table")
	assert(type(superClass) == "table")

	if self == superClass then
		return true
	elseif self.__super then
		return self.__super:isSubclassOf(superClass)
	end

	return false
end

function Class:isSuperclassOf(subClass)
	assert(subClass ~= nil)

	return subClass:isSubclassOf(self)
end

function Class:extend()
	assert(self ~= nil)

	local o = Class.new()
	o.__super = self
	getmetatable(o).__index = self

	return o
end

function Class.inherit(base)
	return base:extend()
end

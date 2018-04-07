Class = {}
function Class.new()
	local o = {}
	o.__index = o
	setmetatable(o, {
		__call = function (cls, ...)
			local self = setmetatable({}, cls)
			self:new(...)
			return self
		end,
	})
	
	return o
end
function Class.inherit(base)
	local o = {}
	o.__index = o
	setmetatable(o, {
		__index = base,
		__call = function (cls, ...)
			local self = setmetatable({}, cls)
			self:new(...)
			return self
		end,
	})
	
	return o
end

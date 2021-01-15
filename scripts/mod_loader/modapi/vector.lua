
math.vec2 = {}
math.vec3 = {}
math.vec4 = {}

local mt_vec2 = {
	x = 1, y = 2,
	width = 1, height = 2,
	w = 1, h = 2,
	top = 1, bottom = 1, left = 2, right = 2,
	t = 1, b = 1, l = 2, r = 2,
	[1] = 1, [2] = 2
}

local mt_vec3 = {
	x = 1, y = 2, z = 3,
	i = 1, j = 2, k = 3,
	[1] = 1, [2] = 2, [3] = 3
}

local mt_vec4 = {
	north = 1, south = 2, west = 3, east = 4,
	top = 1, bottom = 2, left = 3, right = 4,
	t = 1, b = 2, l = 3, r = 4,
	
	x = 1, y = 2, w = 3, h = 4, width = 3, height = 4,
	[1] = 1, [2] = 2, [3] = 3, [4] = 4
}

local function traceback(level)
	return Assert.Traceback and debug.traceback("\n", level or 2) or ""
end

local function AssertIsVector(name, expected, actual, msg)
	msg = (msg and msg .. ": ") or ""
	msg = msg .. string.format("Expected %s, but was %s%s", name, type(actual), traceback(3))
	assert(getmetatable(actual) == expected, msg)
end

local function AssertIsVector2(actual, msg)
	AssertIsVector("math.vec2", mt_vec2, actual, msg)
end

local function AssertIsVector3(actual, msg)
	AssertIsVector("math.vec3", mt_vec3, actual, msg)
end

local function AssertIsVector4(actual, msg)
	AssertIsVector("math.vec4", mt_vec4, actual, msg)
end

local function addVectors(a, b)
	
	if #a == 4 or #b == 4 then
		return math.vec4(
			a[1] + b[1],
			a[2] + b[2],
			a[3] + b[3],
			a[4] + b[4]
		)
		
	elseif #a == 3 or #b == 3 then
		return math.vec3(
			a[1] + b[1],
			a[2] + b[2],
			a[3] + b[3]
		)
		
	elseif #a == 2 or #b == 2 then
		return math.vec2(
			a[1] + b[1],
			a[2] + b[2]
		)
	end
	
	error(string.format("addVectors - Unexpected error: neither vector had 2, 3 or 4 components%s"), traceback(2))
end

local function subVectors(a, b)
	return addVectors(a, -b)
end


-- metatable for 2-component vector
function mt_vec2:__call(x, y)
	
	if type(x) == 'table' and getmetatable(x) == mt_vec2 then
		y = x[2] or y
		x = x[1] or x
	end
	
	x = type(x) == 'number' and x or 0
	y = type(y) == 'number' and y or 0
	
	local vec2 = {x, y}
	
	setmetatable(vec2, mt_vec2)
	
	return vec2
end

function mt_vec2:__index(key)
	if type(key) == 'number' then
		return 0
	end
	
	local index =  mt_vec2[key]
	
	if type(index) == 'number' then
		return rawget(self, index)
		
	elseif type(index) == 'function' then
		return mt_vec2[key]
	end
	
	return nil
end

function mt_vec2:__newindex(key, value)
	local index = mt_vec2[key]
	
	if type(index) == 'number' and type(value) == 'number' then
		rawset(self, index, value)
	end
end

function mt_vec2:__unm()
	return math.vec2(-self[1], -self[2])
end

function mt_vec2:__add(other)
	return addVectors(self, other)
end

function mt_vec2:__sub(other)
	return subVectors(self, other)
end

function mt_vec2:__mul(other)
	AssertIsVector2(self, "math.vec2 dot product - Argument #1")
	AssertIsVector2(other, "math.vec2 dot product - Argument #2")
	
	return self[1] * other[1] + self[2] * other[2]
end

function mt_vec2:dot(other)
	return self * other
end

-- returns the magnitude of the cross product
function mt_vec2:cross(other)
	AssertIsVector2(self, "math.vec2 cross product - Argument #1")
	AssertIsVector2(other, "math.vec2 cross product - Argument #2")
	
	return self[1] * other[2] - self[2] * other[1]
end

function mt_vec2:GetString()
	return string.format("math.vec2{ %s, %s }", self[1], self[2])
end

function mt_vec2:GetContent()
	return self[1], self[2]
end

function mt_vec4:GetPosition()
	return self[1], self[2]
end

function mt_vec4:GetExtents()
	return self[1], self[2]
end


-- metatable for 3-component vector
function mt_vec3:__call(x, y, z)
	
	if type(x) == 'table' and getmetatable(x) == mt_vec3 then
		z = x[3] or z
		y = x[2] or y
		x = x[1] or x
		
	elseif type(x) == 'table' and getmetatable(x) == mt_vec2 then
		z = y
		y = x[2] or y
		x = x[1] or x
		
	elseif type(y) == 'table' and getmetatable(y) == mt_vec2 then
		z = y[2] or z
		y = y[1] or y
	end
	
	x = type(x) == 'number' and x or 0
	y = type(y) == 'number' and y or 0
	z = type(z) == 'number' and z or 0
	
	local vec3 = {x, y, z}
	
	setmetatable(vec3, mt_vec3)
	
	return vec3
end

function mt_vec3:__index(key)
	if type(key) == 'number' then
		return 0
	end
	
	local index =  mt_vec3[key]
	
	if type(index) == 'number' then
		return rawget(self, index)
		
	elseif type(index) == 'function' then
		return mt_vec3[key]
	end
	
	return nil
end

function mt_vec3:__newindex(key, value)
	local index = mt_vec3[key]
	
	if type(index) == 'number' and type(value) == 'number' then
		rawset(self, index, value)
	end
end

function mt_vec3:__unm()
	return math.vec3(-self[1], -self[2], -self[3])
end

function mt_vec3:__add(other)
	return addVectors(self, other)
end

function mt_vec3:__sub(other)
	return subVectors(self, other)
end

function mt_vec3:__mul(other)
	AssertIsVector3(self, "math.vec3 dot product - Argument #1")
	AssertIsVector3(other, "math.vec3 dot product - Argument #2")
	
	return self[1] * other[1] + self[2] * other[2] + self[3] * other[3]
end

function mt_vec3:dot(other)
	return self * other
end

function mt_vec3:cross(other)
	AssertIsVector3(self, "math.vec3 cross product - Argument #1")
	AssertIsVector3(other, "math.vec3 cross product - Argument #2")
	
	return self(
		self[2] * other[3] - self[3] * other[2],
		self[3] * other[1] - self[1] * other[3],
		self[1] * other[2] - self[2] * other[1]
	)
end

function mt_vec3:GetString()
	return string.format("math.vec3{ %s, %s, %s }", self[1], self[2], self[3])
end

function mt_vec3:GetContent()
	return self[1], self[2], self[3]
end


-- metatable for 4-component vector
function mt_vec4:__call(x,y,w,h)
	
	if type(x) == 'table' and getmetatable(x) == mt_vec4 then
		h = x[4] or h
		w = x[3] or w
		y = x[2] or y
		x = x[1] or x
		
	elseif type(x) == 'table' and getmetatable(x) == mt_vec3 then
		h = y
		w = x[3] or w
		y = x[2] or y
		x = x[1] or x
		
	elseif type(x) == 'table' and getmetatable(x) == mt_vec2 then
		h = w
		w = y
		y = x[2] or y
		x = x[1] or x
		
		if type(w) == 'table' and getmetatable(w) == mt_vec2 then
			h = w[2] or h
			w = w[1] or w
		end
		
	elseif type(y) == 'table' and getmetatable(y) == mt_vec3 then
		h = y[3] or h
		w = y[2] or w
		y = y[1] or y
		
	elseif type(y) == 'table' and getmetatable(y) == mt_vec2 then
		h = w
		w = y[2] or w
		y = y[1] or y
		
	elseif type(w) == 'table' and getmetatable(w) == mt_vec2 then
		h = w[2] or h
		w = w[1] or w
	end
	
	x = type(x) == 'number' and x or 0
	y = type(y) == 'number' and y or 0
	w = type(w) == 'number' and w or 0
	h = type(h) == 'number' and h or 0
	
	local vec4 = {x, y, w, h}
	
	setmetatable(vec4, mt_vec4)
	
	return vec4
end

function mt_vec4:__index(key)
	if type(key) == 'number' then
		return 0
	end
	
	local index =  mt_vec4[key]
	
	if type(index) == 'number' then
		return rawget(self, index)
		
	elseif type(index) == 'function' then
		return mt_vec4[key]
	end
	
	return nil
end

function mt_vec4:__newindex(key, value)
	local index = mt_vec4[key]
	
	if type(index) == 'number' and type(value) == 'number' then
		rawset(self, index, value)
	end
end

function mt_vec4:__unm()
	return math.vec4(-self[1], -self[2], -self[3], -self[4])
end

function mt_vec4:__add(other)
	return addVectors(self, other)
end

function mt_vec4:__sub(other)
	return subVectors(self, other)
end

function mt_vec4:__mul(other)
	AssertIsVector4(self, "math.vec4 dot product - Argument #1")
	AssertIsVector4(other, "math.vec4 dot product - Argument #2")
	
	return self[1] * other[1] + self[2] * other[2] + self[3] * other[3] + self[4] * other[4]
end

function mt_vec4:dot(other)
	return self * other
end

function mt_vec4:GetString()
	return string.format("math.vec4{ %s, %s, %s, %s }", self[1], self[2], self[3], self[4])
end

function mt_vec4:GetContent()
	return self[1], self[2], self[3], self[4]
end

function mt_vec4:GetPosition()
	return self[1], self[2]
end

function mt_vec4:GetExtents()
	return self[3], self[4]
end


setmetatable(math.vec2, mt_vec2)
setmetatable(math.vec3, mt_vec3)
setmetatable(math.vec4, mt_vec4)

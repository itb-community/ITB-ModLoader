
math.vec2 = {}
math.vec3 = {}
math.vec4 = {}

local mt_vec2 = {
	x = 1, y = 2,
	[1] = 1, [2] = 2
}

local mt_vec3 = {
	x = 1, y = 2, z = 3,
	i = 1, j = 2, k = 3,
	[1] = 1, [2] = 2, [3] = 3
}

local mt_vec4 = {
	top = 1, bottom = 2, left = 3, right = 4,
	north = 1, south = 2, west = 3, east = 4,
	n = 1, s = 2, w = 3, e = 4,
	t = 1, b = 2, l = 3, r = 4,
	x = 1, y = 2, z = 3, time = 4,
	i = 1, j = 2, k = 3,
	[1] = 1, [2] = 2, [3] = 3, [4] = 4
}

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
	
	return nil
end

local function subVectors(a, b)
	return addVectors(a, b(-b[1], -b[2], -b[3], -b[4]))
end


-- metatable for 2-component vector
function mt_vec2:__call(x, y)
	
	if type(x) == 'table' and getmetatable(x) == mt_vec2 then
		y = y[2] or y
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

function mt_vec2:__add(other)
	return addVectors(self, other)
end

function mt_vec2:__sub(other)
	return subVectors(self, other)
end

function mt_vec2:__mul(other)
	Assert.True(getmetatable(other) == mt_vec2, "math.vec2.__mul function mismatch")
	
	return self[1] * other[1] + self[2] * other[2]
end

-- returns the magnitude of the cross product
function mt_vec2:cross(other)
	Assert.True(getmetatable(other) == mt_vec2, "math.vec2.cross function mismatch")
	
	return self[1] * other[2] - self[2] * other[1]
end

function mt_vec2:GetString()
	return string.format("math.vec2{ %s, %s }", self[1], self[2])
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

function mt_vec3:__add(other)
	return addVectors(self, other)
end

function mt_vec3:__sub(other)
	return subVectors(self, other)
end

function mt_vec3:__mul(other)
	Assert.True(getmetatable(other) == mt_vec3, "math.vec3.__mul function mismatch")
	
	return self[1] * other[1] + self[2] * other[2] + self[3] * other[3]
end

function mt_vec3:cross(other)
	Assert.True(getmetatable(other) == mt_vec3, "math.vec3.cross function mismatch")
	
	return self(
		self[2] * other[3] - self[3] * other[2],
		self[3] * other[1] - self[1] * other[3],
		self[1] * other[2] - self[2] * other[1]
	)
end

function mt_vec3:GetString()
	return string.format("math.vec3{ %s, %s, %s }", self[1], self[2], self[3])
end


-- metatable for 4-component vector
function mt_vec4:__call(x,y,z,t)
	
	if type(x) == 'table' and getmetatable(x) == mt_vec4 then
		t = x[4] or t
		z = x[3] or z
		y = x[2] or y
		x = x[1] or x
		
	elseif type(x) == 'table' and getmetatable(x) == mt_vec3 then
		t = z
		z = x[3] or z
		y = x[2] or y
		x = x[1] or x
		
	elseif type(x) == 'table' and getmetatable(x) == mt_vec2 then
		t = z
		z = y
		y = x[2] or y
		x = x[1] or x
		
		if type(z) == 'table' and getmetatable(z) == mt_vec2 then
			t = z[2] or t
			z = z[1] or z
		end
		
	elseif type(y) == 'table' and getmetatable(y) == mt_vec3 then
		t = y[3] or t
		z = y[2] or z
		y = y[1] or y
		
	elseif type(y) == 'table' and getmetatable(y) == mt_vec2 then
		t = z
		z = y[2] or z
		y = y[1] or y
	end
	
	x = type(x) == 'number' and x or 0
	y = type(y) == 'number' and y or 0
	z = type(z) == 'number' and z or 0
	t = type(t) == 'number' and t or 0
	
	local vec4 = {x, y, z, t}
	
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

function mt_vec4:__add(other)
	return addVectors(self, other)
end

function mt_vec4:__sub(other)
	return subVectors(self, other)
end

function mt_vec4:__mul(other)
	Assert.True(getmetatable(other) == mt_vec4, "math.vec4.__mul function mismatch")
	
	return self[1] * other[1] + self[2] * other[2] + self[3] * other[3] + self[4] * other[4]
end

function mt_vec4:GetString()
	return string.format("math.vec4{ %s, %s, %s, %s }", self[1], self[2], self[3], self[4])
end


setmetatable(math.vec2, mt_vec2)
setmetatable(math.vec3, mt_vec3)
setmetatable(math.vec4, mt_vec4)

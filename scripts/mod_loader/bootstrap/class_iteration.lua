
--[[
	Allows key-value pair iteration over custom classes created via:
		ITB's vanilla CreateClass
		ModLoader's custom Class.new()

	This function returns an iterator function that traverses all key-value pairs of a class instance,
	including those inherited from parent classes in the class hierarchy,
	but excluding any keys in parent classes that exists in derived classes.


	Example usage 1 - ITB's vanilla CreateClass:
	--------------------------------------------

	local Object = {
		weight = 10,
		color = "Brown",
	}
	CreateClass(Object)

	local LivingBeing = Object:new{
		breathes = true,
		walks = true,
	}

	local Animal = LivingBeing:new{
		name = "Animal",
		sound = "Roar",
	}

	for key, value in iterateInstanceAndParents(Animal:new()) do
		LOG(key, value)
	end


	Example usage 2 - ModLoader's custom Class.new():
	-------------------------------------------------

	local Object = Class.new()
	function Object:new()
		self.weight = 10
		self.color = "Brown"
	end

	local LivingBeing = Class.inherit(Object)
	function LivingBeing:new()
		Object.new(self)
		self.breathes = true
		self.walks = true
	end

	local Animal = Class.inherit(LivingBeing)
	function Animal:new()
		LivingBeing.new(self)
		self.name = "Animal"
		self.sound = "Roar"
	end

	for key, value in iterateInstanceAndParents(Animal()) do
		LOG(key, value)
	end
]]

-- Default exceptions excludes functions, userdata, threads and double-underscore prefixed keys
local function defaultExceptions(key, value)
	local t = type(value)
	return tostring(key):sub(1, 2) == "__"
			or t == "function"
			or t == "userdata"
			or t == "thread"
end

function iterateInstanceAndParents(instance)
	Assert.Equals(type(instance), "table", "Arguemnt #1")
	-- Determine the class implementation based on the presence of the instanceOf function
	local isSecondImplementation = instance.instanceOf and instance:instanceOf(instance.__index)

	-- Use default exceptions if none are specified
	if exceptions == nil then
		exceptions = defaultExceptions
	end

	-- Create a coroutine
	local co = coroutine.create(function()
		-- Track the keys seen in the derived class
		local seenKeys = {}
		-- Iterate through the class and its parents
		while instance do
			-- Iterate over the class's keys
			for k, v in pairs(instance) do
				if not exceptions(k, v) then
					-- Check if the key has already been seen in the derived class
					if not seenKeys[k] then
						-- Add the key to the seen keys
						seenKeys[k] = true
						-- Yield the key-value pair
						coroutine.yield(k, v)
					end
				end
			end

			if isSecondImplementation then
				-- Move to the parent class
				instance = instance.__super
			else
				local mt = getmetatable(instance)
				instance = mt and mt.__index or nil
			end
		end
	end)

	-- Return an iterator function
	return function()
		local ok, key, value = coroutine.resume(co)

		if coroutine.status(co) == "dead" then
			return
		elseif ok then
			return key, value
		else
			error(key)
		end
	end
end


-- Basically the same as hooks, with the exception that they are not reset after loading.
-- Intended for streamlining the modApi's inner workings,
-- so different parts can be grouped in a more meaningful way.
modApi.events = {}

function modApi:newEvent(name)
	local Event = name:gsub("^.", string.upper) .."Event" -- capitalize first char
	local name = name:gsub("^.", string.lower) -- lower case first char
	
	table.insert(self.events, name)
	local events = {}
	self[name .."Events"] = events

	self["add".. Event] = function(self, fn)
		assert(type(fn) == "function")
		table.insert(events, fn)
	end

	self["rem".. Event] = function(self, fn)
		remove_element(fn, events)
	end

	self["trigger".. Event] = function(self, ...)
		for _, fn in ipairs(events) do
			fn(...)
		end
	end
end

function modApi:triggerEvent(name, ...)
	local name = name:gsub("^.", string.upper) -- capitalize first char
	
	self["trigger".. name .."Event"](self, ...)
end

-- Creates pre-, post- and - event triggers for a table function.
-- This pattern is not always applicable, and triggers can be created manually instead.
function modApi:addEventTriggers(parentTable, key, event)

	event = event:gsub("^.", string.upper) -- capitalize first char
	local event_pre = "Pre".. event
	local event_post = "Post".. event
	
	local oldFn = parentTable[key]
	
	assert(type(oldFn) == 'function')
	
	parentTable[key] = function(...)
		self:triggerEvent(event_pre, ...)
		
		local result = oldFn(...)
		
		self:triggerEvent(event, ...) -- if pre/post is not specified, post makes most sense.
		self:triggerEvent(event_post, ...)
		
		return result
	end
end


Subscription = Class.new()

function Subscription:new(event)
	assert(type(event) == "table", "Subscription.new: first argument must be a table\n"..debug.traceback())
	assert(type(event.subscribers), "Subscription.new: first argument must be an Event\n"..debug.traceback())

	self.event = event
	self.teardownFns = {}
end

function Subscription:unsubscribe()
	if self:isClosed() then
		return false
	end

	self.event.subscribers[self] = nil

	for _, teardownFn in ipairs(self.teardownFns) do
		teardownFn()
	end
	self.teardownFns = nil

	return true
end

function Subscription:isClosed()
	return self.event == nil
end

-----------------------------------------
Event = Class.new()

function Event:new()
	self.subscribers = {}
end

function Event:subscribe(fn)
	assert(type(fn) == "function", "Event.subscribe: first argument must be a function\n"..debug.traceback())
	local sub = Subscription(self)
	self.subscribers[sub] = fn

	return sub
end

function Event:unsubscribeAll()
	for sub, _ in pairs(self.subscribers) do
		sub:unsubscribe()
	end
end

local function pack2(...) return {n=select('#', ...), ...} end
local function unpack2(t) return unpack(t, 1, t.n) end
function Event:fire(...)
	local args = pack2(...)
	for _, fn in pairs(self.subscribers) do
		local ok, err = pcall(function() fn(unpack2(args)) end)

		if not ok then
			LOG("An event callback failed: ", err)
		end
	end
end

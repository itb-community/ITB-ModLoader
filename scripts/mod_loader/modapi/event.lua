
Subscription = Class.new()

function Subscription:new(event)
	assert(type(event) == "table", "Subscription.new: first argument must be a table\n"..debug.traceback())
	assert(Class.instanceOf(event, Event), "Subscription.new: first argument must be an Event\n"..debug.traceback())

	self.event = event
	self.teardownFns = {}
end

function Subscription:unsubscribe()
	return self.event:unsubscribe(self)
end

--[[
	Adds a teardown function to this subscription, which will be executed when
	this subscription is unsubscribed from its event.
--]]
function Subscription:addTeardown(fn)
	assert(type(fn) == "function", "Subscription.addTeardown: first argument must be a function\n"..debug.traceback())
	table.insert(self.teardownFns, fn)
end

--[[
	Fires teardown functions, and removes them once completed.
--]]
function Subscription:executeTeardown()
	for _, teardownFn in ipairs(self.teardownFns) do
		teardownFn()
	end
	self.teardownFns = nil
end

--[[
	Returns true if this subscription is closed - ie. no longer valid and no longer notified of events.
--]]
function Subscription:isClosed()
	return self.event == nil
end

-----------------------------------------
--[[
	Event class that allows to easily create events - or 'hooks', as we tend to call them.

	Usage:
		local myEvent = Event()
		local subscription = myEvent:subscribe(function(someArg1, someArg2)
			LOG("myEvent has been fired with args: ", someArg1, someArg2)
		end)

		-- Once you're no longer interested in receiving notifications from this event,
		-- you can unsubscribe using the `subscription` object:
		subscription:unsubscribe()

		-- Unlike hooks, events are not cleaned up by default when loading, so if you define
		-- your own event, you have to take care of removing subscriptions when it makes sense
		-- in your case:
		myEvent:unsubscribeAll()
--]]
Event = Class.new()

function Event:new()
	self.subscribers = {}
end

--[[
	Subscribes a function to this event; this call is analogous to modApi:add__Hook() in old hooks API.
--]]
function Event:subscribe(fn)
	assert(type(fn) == "function", "Event.subscribe: first argument must be a function\n"..debug.traceback())
	local sub = Subscription(self)
	sub.fn = fn

	table.insert(self.subscribers, sub)

	return sub
end

--[[
	Returns true if the specified object is subscribed to this Event. False otherwise.
--]]
function Event:isSubscribed(subscription)
	if type(subscription) ~= "table" then
		return false
	end
	if not Class.instanceOf(subscription, Subscription) then
		return false
	end
	if subscription:isClosed() then
		return false
	end

	return list_contains(self.subscribers, subscription)
end

--[[
	Cancels the specified subscription, making it invalid and no longer notified
	of the event being fired.
--]]
function Event:unsubscribe(subscription)
	assert(type(subscription) == "table", "Event.unsubscribe: first argument must be a table\n"..debug.traceback())
	assert(Class.instanceOf(subscription, Subscription), "Event.unsubscribe: first argument must be a Subscription\n"..debug.traceback())

	if subscription:isClosed() then
		return false
	end
	if not self:isSubscribed(subscription) then
		return false
	end

	subscription:executeTeardown()

	remove_element(subscription, self.subscribers)
	subscription.event = nil

	return true
end

--[[
	Removes all existing subscriptions from this event, preventing them from being
	notified unless registered again.
	Generally, only the code that 'owns' the event should call this function, as
	part of cleanup.
--]]
function Event:unsubscribeAll()
	local snapshot = shallow_copy(self.subscribers)
	for _, sub in ipairs(snapshot) do
		self:unsubscribe(sub)
	end
end

local function isStackOverflowError(err)
	return string.find(err, "C stack overflow")
end

local function pack2(...) return {n=select('#', ...), ...} end
local function unpack2(t) return unpack(t, 1, t.n) end

--[[
	Fires this event, notifying all subscribers and passing all arguments
	that have been passed to this function to them.
	Arguments are passed as-is without any cloning or protection, so if you
	pass a table, and one subscriber modifies it, the changes will propagate
	to subsequent subscribers.
--]]
function Event:fire(...)
	local args = pack2(...)
	local snapshot = shallow_copy(self.subscribers)
	for _, sub in ipairs(snapshot) do
		local ok, err = pcall(function() sub.fn(unpack2(args)) end)

		if not ok then
			if isStackOverflowError(err) then
				error(err)
			else
				LOG("An event callback failed: ", err)
			end
		end
	end
end

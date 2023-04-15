local function pack2(...)
	return { n = select('#', ...), ... }
end
local function unpack2(t)
	return unpack(t, 1, t.n)
end

Subscription = Class.new()

function Subscription:new(event, listenerFn)
	Assert.Equals("table", type(event), "Subscription.new: first argument must be a table")
	Assert.True(Class.instanceOf(event, Event), "Subscription.new: first argument must be an Event")
	Assert.Equals("function", type(listenerFn), "Subscription.new: second argument must be a function")

	self.event = event
	self.listenerFn = listenerFn
	self.creator = debug.traceback("", 3)
end

--- Unsubscribes this Subscription. Returns true if it was successfully unsubscibed,
--- or false if it wasn't open or subscribed in the first place.
function Subscription:unsubscribe()
	return self.event:unsubscribe(self)
end

--- Adds a teardown function to this subscription, which will be executed when
--- this subscription is unsubscribed from its event.
function Subscription:addTeardown(fn)
	Assert.Equals(
			"function", type(fn),
			"Subscription.addTeardown: first argument must be a function"
	)
	self.teardownFns = self.teardownFns or {}
	table.insert(self.teardownFns, fn)

	return self
end

--- Fires teardown functions, and removes them once completed.
function Subscription:executeTeardown()
	if not self.teardownFns then
		return
	end

	for _, teardownFn in ipairs(self.teardownFns) do
		teardownFn()
	end
	self.teardownFns = nil
end

function Subscription:notify(args)
	if not self.listenerFn then
		error("Subscription is closed")
	end

	return pcall(function()
		return self.listenerFn(unpack2(args))
	end)
end

--- Unsubscribes this Subscription the next time the event passed in argument
--- is triggered.
function Subscription:openUntil(event)
	Assert.Equals("table", type(event), "Subscription.openUntil: first argument must be a table")
	Assert.True(Class.instanceOf(event, Event), "Subscription.openUntil: first argument must be an Event")

	local cleanupSubscription
	cleanupSubscription = event:subscribe(function()
		self:unsubscribe()
	end)

	-- Make sure we cleanup the subscription that's supposed to clean *us*
	self:addTeardown(function()
		cleanupSubscription:unsubscribe()
		cleanupSubscription = nil
	end)

	return self
end

--- Returns true if this subscription is closed - ie. no longer valid and no longer notified of events.
function Subscription:isClosed()
	return self.event == nil
end

--- Event class that allows to easily create events - or 'hooks', as we tend to call them.
---
--- Usage:
--- 	local myEvent = Event()
--- 	local subscription = myEvent:subscribe(function(someArg1, someArg2)
--- 		LOG("myEvent has been fired with args: ", someArg1, someArg2)
--- 	end)
---
--- 	-- Once you're no longer interested in receiving notifications from this event,
--- 	-- you can unsubscribe using the `subscription` object:
--- 	subscription:unsubscribe()
---
--- 	-- Unlike hooks, events are not cleaned up by default when loading, so if you define
--- 	-- your own event, you have to take care of removing subscriptions when it makes sense
--- 	-- in your case:
--- 	myEvent:unsubscribeAll()
Event = Class.new()

--- When this event option is true, the event allows its subscribers to shortcircuit
--- processing by returning 'true', preventing subscribers that come after from being notified
--- of that particular event dispatch.
Event.SHORTCIRCUIT = "shortcircuit"

function Event:new(options)
	if options then
		Assert.Equals("table", type(options), "Event.new: first argument must be a table")
	end
	self.subscribers = {}
	self.options = {}

	if options then
		if options[Event.SHORTCIRCUIT] then
			self.options[Event.SHORTCIRCUIT] = true
		end
	end
end

--- Subscribes a function to this event; this call is analogous to modApi:add__Hook() in old hooks API.
function Event:subscribe(fn)
	Assert.Equals("function", type(fn), "Event.subscribe: first argument must be a function")
	local sub = Subscription(self, fn)

	table.insert(self.subscribers, sub)

	return sub
end

--- Returns true if the specified object is subscribed to this Event. False otherwise.
function Event:isSubscribed(subscription)
	Assert.Equals(
			{ "function", "table" }, type(subscription),
			"Event.isSubscribed: first argument must be a function or a table"
	)

	if type(subscription) == "table" and Class.instanceOf(subscription, Subscription) then
		if subscription:isClosed() then
			return false
		end

		return list_contains(self.subscribers, subscription)
	elseif type(subscription) == "function" then
		for _, sub in ipairs(self.subscribers) do
			if sub.listenerFn == subscription then
				return true
			end
		end
	end

	return false
end

--- Cancels the specified subscription, making it invalid and no longer notified
--- of the event being fired.
--- Returns true if successfully unsubscribed, false otherwise.
function Event:unsubscribe(subscription)
	Assert.Equals(
			{ "function", "table" }, type(subscription),
			"Event.isSubscribed: first argument must be a function or a table"
	)

	if not self:isSubscribed(subscription) then
		return false
	end

	if type(subscription) == "function" then
		for _, sub in ipairs(self.subscribers) do
			if sub.listenerFn == subscription then
				subscription = sub
				break
			end
		end

		-- No subscriber found for the function
		if type(subscription) == "function" then
			return false
		end
	end

	Assert.True(
			Class.instanceOf(subscription, Subscription),
			"Event.unsubscribe: first argument must be a Subscription"
	)

	if subscription:isClosed() then
		return false
	end

	subscription:executeTeardown()

	remove_element(subscription, self.subscribers)
	subscription.event = nil

	return true
end

--- Removes all existing subscriptions from this event, preventing them from being
--- notified unless registered again.
--- Generally, only the code that 'owns' the event should call this function, as
--- part of cleanup.
function Event:unsubscribeAll()
	local snapshot = shallow_copy(self.subscribers)
	for _, sub in ipairs(snapshot) do
		self:unsubscribe(sub)
	end
end

local function isStackOverflowError(err)
	return string.find(err, "C stack overflow")
end

local function buildErrorMessage(headerMessage, subscriptionCaller, dispatchCaller)
	return string.format(
			"%s\n- Subscribed at: %s\n- Dispatched at: %s",
			headerMessage,
			string.gsub(subscriptionCaller, "\n", "\n    "),
			string.gsub(dispatchCaller, "\n", "\n    ")
	)
end

--- Fires this event, notifying all subscribers and passing all arguments
---	that have been passed to this function to them.
---	Arguments are passed as-is without any cloning or protection, so if you
---	pass a table, and one subscriber modifies it, the changes will propagate
---	to subsequent subscribers.
function Event:dispatch(...)
	local args = pack2(...)
	local snapshot = shallow_copy(self.subscribers)
	local caller = debug.traceback("")

	for _, sub in ipairs(snapshot) do
		local ok, errorOrResult = sub:notify(args)

		if not ok and errorOrResult then
			local message = buildErrorMessage("An event callback failed: " .. errorOrResult, sub.creator, caller)
			if isStackOverflowError(errorOrResult) then
				error(message)
			else
				LOG(message)
			end
		elseif ok then
			if errorOrResult and self.options[Event.SHORTCIRCUIT] then
				return true
			end
		end
	end

	return false
end
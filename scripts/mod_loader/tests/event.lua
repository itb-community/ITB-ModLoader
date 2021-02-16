local testsuite = Tests.Testsuite()
testsuite.name = "Events system tests"

function testsuite.test_EventFire()
	local event = Event()

	local value = 0
	local sub = event:subscribe(function(argValue)
		value = argValue
	end)

	local expectedValue = 5
	event:dispatch(expectedValue)

	Assert.NotEquals(0, value, "Event:dispatch() did not notify the subscriber")
	Assert.Equals(expectedValue, value, "Event:dispatch() did not pass arguments to the subscriber")
	Assert.False(sub:isClosed(), "Subscriber was marked as closed, even though it did not unsubscribe.")

	return true
end

function testsuite.test_EventNotifyAllSubscribers()
	local event = Event()

	local notified1 = false
	local notified2 = false
	event:subscribe(function()
		notified1 = true
	end)
	event:subscribe(function()
		notified2 = true
	end)

	event:dispatch()

	Assert.True(notified1, "Event:dispatch() did not notify the first subscriber")
	Assert.True(notified2, "Event:dispatch() did not notify the second subscriber")

	return true
end

function testsuite.test_EventUnsubscribe()
	local event = Event()

	local fired = false
	local sub = event:subscribe(function()
		fired = true
	end)

	local unsubResult = sub:unsubscribe()
	event:dispatch()

	Assert.True(unsubResult, "Event:unsubscribe() returned false for valid subscriber")
	Assert.True(sub:isClosed(), "Subscriber was not marked as closed after it unsubscribed.")
	Assert.False(event:isSubscribed(sub), "Event:isSubscribed() did not return false for its subscriber after it unsubscribed.")
	Assert.False(fired, "Subscriber got notified after it unsubscribed from the event.")

	return true
end

function testsuite.test_EventUnsubscribeWithFunction()
	local event = Event()

	local fired = false
	local fn = function()
		fired = true
	end
	event:subscribe(fn)

	local unsubResult = event:unsubscribe(fn)
	event:dispatch()

	Assert.True(unsubResult, "Event:unsubscribe() returned false for valid subscriber")
	Assert.False(fired, "Subscriber got notified after it unsubscribed from the event.")

	return true
end

function testsuite.test_EventUnsubscribeAll()
	local event = Event()

	event:subscribe(function() end)
	event:subscribe(function() end)
	event:subscribe(function() end)

	event:unsubscribeAll()

	Assert.Equals(0, #event.subscribers, "Event:unsubscribeAll() did not remove all subscribers from the event.")

	return true
end

function testsuite.test_EventTeardown()
	local event = Event()

	local fired = false
	local sub = event:subscribe(function() end)

	sub:addTeardown(function()
		fired = true
	end)

	sub:unsubscribe()

	Assert.True(fired, "Subscriber's teardown function was not invoked when it unsubscribed.")
	Assert.True(sub:isClosed(), "Subscriber was not marked as closed after it unsubscribed.")

	return true
end

function testsuite.test_EventIsSubscribed()
	local eventA = Event()
	local eventB = Event()

	local subA = eventA:subscribe(function() end)

	Assert.True(eventA:isSubscribed(subA), "Event:isSubscribed() did not return true for its own subscriber.")
	Assert.False(eventB:isSubscribed(subA), "Event:isSubscribed() did not return false for foreign subscriber.")

	return true
end

function testsuite.test_EventIsSubscribedWithFunction()
	local event = Event()

	local fn = function() end
	event:subscribe(fn)

	Assert.True(event:isSubscribed(fn), "Event:isSubscribed() did not return true for its own subscriber.")

	return true
end

function testsuite.test_EventOptionShortcircuitEnabled()
	local event = Event({ [Event.SHORTCIRCUIT] = true })

	local notified1 = false
	local notified2 = false
	local notified3 = false
	event:subscribe(function()
		notified1 = true
	end)
	event:subscribe(function()
		notified2 = true
		return true
	end)
	event:subscribe(function()
		notified3 = true
	end)

	event:dispatch()

	Assert.True(notified1, "Event:dispatch() did not notify the first subscriber")
	Assert.True(notified2, "Event:dispatch() did not notify the second subscriber")
	Assert.False(notified3, "Event:dispatch() notified the third subscriber, after shortcircuit")

	return true
end

function testsuite.test_EventOptionShortcircuitDisabled()
	local event = Event({ [Event.SHORTCIRCUIT] = false })

	local notified1 = false
	local notified2 = false
	local notified3 = false
	event:subscribe(function()
		notified1 = true
	end)
	event:subscribe(function()
		notified2 = true
		return true
	end)
	event:subscribe(function()
		notified3 = true
	end)

	event:dispatch()

	Assert.True(notified1, "Event:dispatch() did not notify the first subscriber")
	Assert.True(notified2, "Event:dispatch() did not notify the second subscriber")
	Assert.True(notified3, "Event:dispatch() did not notify the third subscriber, after second attempted to shortcircuit")

	return true
end

function testsuite.test_EventOpenUntil_CleanupEvent()
	local event = Event()
	local cleanupEvent = Event()

	local callCount = 0
	event:subscribe(function()
		callCount = callCount + 1
	end):openUntil(cleanupEvent)

	event:dispatch()

	Assert.Equals(1, callCount, "Event:dispatch() did not notify the subscriber")

	cleanupEvent:dispatch()
	event:dispatch()

	Assert.Equals(1, callCount, "Subscriber did not get unsubscribed when cleanup event was dispatched")
	Assert.Equals(0, #cleanupEvent.subscribers, "The cleanup subscription did not get removed")
	Assert.Equals(0, #event.subscribers, "Subscription did not get removed")

	return true
end

function testsuite.test_EventOpenUntil_Unsubscribe()
	local event = Event()
	local cleanupEvent = Event()

	local callCount = 0
	local subscription = event:subscribe(function()
		callCount = callCount + 1
	end):openUntil(cleanupEvent)

	event:dispatch()

	Assert.Equals(1, callCount, "Event:dispatch() did not notify the subscriber")

	subscription:unsubscribe()

	Assert.Equals(0, #cleanupEvent.subscribers, "The cleanup subscription did not get removed")
	Assert.Equals(0, #event.subscribers, "Subscription did not get removed")

	return true
end

return testsuite

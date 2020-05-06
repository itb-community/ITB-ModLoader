local testsuite = Tests.Testsuite()

local assertTrue = Tests.AssertTrue
local assertFalse = Tests.AssertFalse
local assertEquals = Tests.AssertEquals
local assertNotEquals = Tests.AssertNotEquals

function testsuite.test_EventFire()
	local event = Event()

	local value = 0
	local sub = event:subscribe(function(argValue)
		value = argValue
	end)

	local expectedValue = 5
	event:fire(expectedValue)

	assertNotEquals(0, value, "Event:fire() did not notify the subscriber")
	assertEquals(expectedValue, value, "Event:fire() did not pass arguments to the subscriber")
	assertFalse(sub:isClosed(), "Subscriber was marked as closed, even though it did not unsubscribe.")

	return true
end

function testsuite.test_EventUnsubscribe()
	local event = Event()

	local fired = false
	local sub = event:subscribe(function()
		fired = true
	end)

	sub:unsubscribe()
	event:fire()

	assertFalse(fired, "Subscriber got notified after it unsubscribed from the event.")
	assertTrue(sub:isClosed(), "Subscriber was not marked as closed after it unsubscribed.")
	assertFalse(event:isSubscribed(sub), "Event:isSubscribed() did not return false for its subscriber after it unsubscribed.")

	return true
end

function testsuite.test_EventUnsubscribeAll()
	local event = Event()

	event:subscribe(function() end)
	event:subscribe(function() end)
	event:subscribe(function() end)

	event:unsubscribeAll()

	assertEquals(0, #event.subscribers, "Event:unsubscribeAll() did not remove all subscribers from the event.")

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

	assertTrue(fired, "Subscriber's teardown function was not invoked when it unsubscribed.")
	assertTrue(sub:isClosed(), "Subscriber was not marked as closed after it unsubscribed.")

	return true
end

function testsuite.test_EventIsSubscribed()
	local eventA = Event()
	local eventB = Event()

	local subA = eventA:subscribe(function() end)

	assertTrue(eventA:isSubscribed(subA), "Event:isSubscribed() did not return true for its own subscriber.")
	assertFalse(eventB:isSubscribed(subA), "Event:isSubscribed() did not return false for foreign subscriber.")

	return true
end

return testsuite

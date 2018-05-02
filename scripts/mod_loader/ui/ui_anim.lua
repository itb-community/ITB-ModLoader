--[[
	A simple abstraction of a UI animation.
	Has a function that is called every frame with updated progress
	percentage, until the time since the animation has been started
	is greater than its total time.
--]]
UiAnim = Class.new()
function UiAnim:new(widget, msTimeTotal, animFunc)
	self.widget = widget

	if type(msTimeTotal) == "function" then
		-- allow the msTimeTotal argument to be a function;
		-- in this case assume msTimeTotal to be 0, and ignore
		-- last argument.
		self.msTimeTotal = 0
		self.func = msTimeTotal
	else
		self.msTimeTotal = msTimeTotal
		self.func = animFunc
	end

	self.msTimeCurrent = nil
	self.onStarted = nil
	self.onFinished = nil

	-- no side effects, so just verify value types at the end
	-- widget is verified in :start(), to allow for deferred
	-- setting of the animated widget
	assert(type(self.func) == "function")
	assert(type(self.msTimeTotal) == "number")
end

--[[
	Sets the current time of the animation, and calls the anim
	function with the updated progress.
--]]
function UiAnim:setTime(msTime)
	assert(type(msTime) == "number")
	
	msTime = math.min(self.msTimeTotal, math.max(0, msTime))
	self.msTimeCurrent = msTime

	if self.func then
		self:func(self.widget, self.msTimeCurrent / self.msTimeTotal)
	end

	if self:isDone() and not self:isStopped() then
		self:stop()
	end
end

function UiAnim:fireStarted()
	if self.onStarted then
		self:onStarted(self.widget)
	end
end

function UiAnim:fireFinished()
	if self.onFinished then
		self:onFinished(self.widget)
	end
end

--[[
	Sets the starting time of the animation to percentage of its
	total time, making it possible to have the animation start
	playing eg. from halfway through.
--]]
function UiAnim:setInitialPercent(percent)
	assert(type(percent) == "number")
	
	percent = math.min(1, math.max(0, percent))
	self.msTimeCurrent = percent * self.msTimeTotal
end

--[[
	Starts the animation, resetting its progress to 0 or the specified
	amount of time.
--]]
function UiAnim:start(msInitialTime)
	assert(type(self.widget) == "table")
	self.msTimeCurrent = msInitialTime or 0

	self:fireStarted()
end

--[[
	Permanently halts the animation, until start() called again.
	If this animation was started and hasn't been stopped yet,
	this function invokes the onFinished() callback.
--]]
function UiAnim:stop()
	if self:isDone() then
		self:fireFinished()
	end
	
	self.msTimeCurrent = nil
end

--[[
	Updates the animation, advancing its animation by the
	amount of time specified by msDeltaTime argument
--]]
function UiAnim:update(msDeltaTime)
	msDeltaTime = msDeltaTime or 0

	if self:isStarted() and not self:isDone() then
		self:setTime(self.msTimeCurrent + msDeltaTime)
	end
end

--[[
	Returns true if this animation has been started, and its total
	playback time has already elapsed since it was started.
]]--
function UiAnim:isDone()
	return self.msTimeCurrent and self.msTimeCurrent >= self.msTimeTotal
end

--[[
	Returns true if this animation has been started, regardless of
	whether it is done or not.
--]]
function UiAnim:isStarted()
	return self.msTimeCurrent ~= nil
end

--[[
	Returns true if this animation has not been started yet, or has
	been stopped already.
--]]
function UiAnim:isStopped()
	return self.msTimeCurrent == nil
end

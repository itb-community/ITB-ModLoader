local DequeList = require("scripts/mod_loader/deque_list")
local BasicLogger = require("scripts/mod_loader/logger_basic")

-- Forward declaration
local BufferedLogger

-- ///////////////////////////////////////////////////////////////////////
-- BufferedLogger implementation

BufferedLogger = BasicLogger:extend()

local bufferSize = 200
local pageSize = 20
function BufferedLogger:new()
	BasicLogger.new(self)
	self.bufferOffset = 0
	self.buffer = DequeList()
end

local delimiter = "\n"
function BufferedLogger:log(caller, ...)
	local message = self:preprocessInput(...)

	if (self:getLoggingLevel() == Logger.LOG_LEVEL_NONE) then
		return
	end

	if (self:getLoggingLevel() == Logger.LOG_LEVEL_FILE) then
		if (not self.logFileHandle) then
			self.logFileHandle = self:openLogFile(self:getLogFileName())
		end

		local t = ""
		local callerInfo = self:getPrintCallerInfo()
		if (callerInfo == Logger.LOG_LEVEL_FILE or callerInfo == Logger.LOG_LEVEL_CONSOLE) then
			t = caller .. ": "
		end

		t = t .. message .. "\n"

		self.logFileHandle:write(t)
		self.logFileHandle:flush()
	end

	if (self:getPrintCallerInfo() == Logger.LOG_LEVEL_CONSOLE) then
		message = caller .. ": " .. message
	end

	for match in (message..delimiter):gmatch("(.-)"..delimiter) do
		self:pushMessage(match)
	end

	self.bufferOffset = self.buffer:size() - pageSize
	self:output()
end

function BufferedLogger:pushMessage(message)
	if self.buffer:size() >= bufferSize then
		self.buffer:popLeft()
	end

	self.buffer:pushRight(message)
end

function BufferedLogger:scroll(scrollAmount)
	local oldOffset = self.bufferOffset
	self.bufferOffset = math.max(0, math.min(self.buffer:size() - pageSize, self.bufferOffset + scrollAmount))

	if oldOffset ~= self.bufferOffset then
		self:output()
	end
end

function BufferedLogger:scrollToStart()
	self.bufferOffset = 0
	self:output()
end

function BufferedLogger:scrollToEnd()
	self.bufferOffset = self.buffer:size() - pageSize
	self:output()
end

function BufferedLogger:output()
	-- Pad with empty lines in case buffer has too few messages to fill the console
	for i = 0, pageSize - self.buffer:size() do
		ConsolePrint("")
	end

	for i = 0, pageSize do
		local index = self.bufferOffset + i
		local output = self.buffer:peekLeft(index)

		if output then
			ConsolePrint(output)
		end
	end
end

return BufferedLogger

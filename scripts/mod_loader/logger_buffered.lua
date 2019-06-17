local DequeList = require("scripts/mod_loader/deque_list")
local LoggerInterface = require("scripts/mod_loader/logger")
local BasicLogger = require("scripts/mod_loader/logger_basic")

-- Forward declaration
local BufferedLogger
local BufferedLoggerImpl

-- ///////////////////////////////////////////////////////////////////////
-- BufferedLogger interface

BufferedLogger = Class.inherit(LoggerInterface)

function BufferedLogger:new(loggerImplClass)
	assert(loggerImplClass, "Argument #1 must not be nil")
	self:init(loggerImplClass())
end

function BufferedLogger:init(loggerImpl)
	LoggerInterface.init(self, loggerImpl)

	self.scrollToStart = function(self)
		loggerImpl:scrollToStart()
	end

	self.scrollToEnd = function(self)
		loggerImpl:scrollToEnd()
	end

	self.scroll = function(self, scrollAmount)
		loggerImpl:scroll(scrollAmount)
	end
end

-- ///////////////////////////////////////////////////////////////////////
-- BufferedLogger implementation

BufferedLoggerImpl = Class.inherit(BasicLogger)

local bufferSize = 200
local pageSize = 20
function BufferedLoggerImpl:new()
	self.bufferOffset = 0
	self.buffer = DequeList()
end

function BufferedLoggerImpl:log(...)
	local message, caller = self:preprocessInput(...)
	self.bufferOffset = self.buffer:size() - pageSize
	self:output()
end

function BufferedLoggerImpl:pushMessage(message)
	if self.buffer:size() >= bufferSize then
		self.buffer:popLeft()
	end

	self.buffer:pushRight(message)
end

local delimiter = "\n"
function BufferedLoggerImpl:preprocessInput(...)
	local message, caller = self.__super.preprocessInput(self, ...)

    for match in (message..delimiter):gmatch("(.-)"..delimiter) do
        self:pushMessage(match)
	end

	if self:getPrintCallerInfo() then
		self:pushMessage(caller)
	end
end

function BufferedLoggerImpl:scroll(scrollAmount)
	local oldOffset = self.bufferOffset
	self.bufferOffset = math.max(0, math.min(self.buffer:size() - pageSize, self.bufferOffset + scrollAmount))

	if oldOffset ~= self.bufferOffset then
		self:output()
	end
end

function BufferedLoggerImpl:scrollToStart()
	self.bufferOffset = 0
	self:output()
end

function BufferedLoggerImpl:scrollToEnd()
	self.bufferOffset = self.buffer:size() - pageSize
	self:output()
end

function BufferedLoggerImpl:output()
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

return { BufferedLogger, BufferedLoggerImpl }

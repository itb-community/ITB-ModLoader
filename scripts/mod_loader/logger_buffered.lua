local DequeList = require("scripts/mod_loader/deque_list")
local BasicLogger = require("scripts/mod_loader/logger_basic")

-- Forward declaration
local BufferedLogger

-- ///////////////////////////////////////////////////////////////////////
-- BufferedLogger implementation

BufferedLogger = Class.inherit(BasicLogger)

local bufferSize = 200
local pageSize = 20
function BufferedLogger:new()
	self.bufferOffset = 0
	self.buffer = DequeList()
end

function BufferedLogger:log(...)
	local message, caller = self:preprocessInput(...)
	self.bufferOffset = self.buffer:size() - pageSize
	self:output()
end

function BufferedLogger:pushMessage(message)
	if self.buffer:size() >= bufferSize then
		self.buffer:popLeft()
	end

	self.buffer:pushRight(message)
end

local delimiter = "\n"
function BufferedLogger:preprocessInput(...)
	local message, caller = self.__super.preprocessInput(self, ...)

    for match in (message..delimiter):gmatch("(.-)"..delimiter) do
        self:pushMessage(match)
	end

	if self:getPrintCallerInfo() then
		self:pushMessage(caller)
	end
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

-- Forward declaration
local LoggerImpl
local Logger

-- ///////////////////////////////////////////////////////////////////////
-- Logger interface

Logger = Class.new()

Logger.LOG_LEVEL_NONE = 0
Logger.LOG_LEVEL_CONSOLE = 1
Logger.LOG_LEVEL_FILE = 2

function Logger:new()
	local loggerImpl = LoggerImpl()

	self.getLoggingLevel = function(self)
		return loggerImpl:getLoggingLevel()
	end

	self.setLoggingLevel = function(self, level)
		loggerImpl:setLoggingLevel(level)
	end

	self.getLogFileName = function(self)
		return loggerImpl:getLogFileName()
	end

	self.setLogFileName = function(self, fileName)
		loggerImpl:setLogFileName(fileName)
	end

	self.getPrintCallerInfo = function(self)
		return loggerImpl:getPrintCallerInfo()
	end

	self.setPrintCallerInfo = function(self, printCallerInfo)
		loggerImpl:setPrintCallerInfo(printCallerInfo)
	end

	self.log = function(self, ...)
		loggerImpl:log(...)
	end
end

-- ///////////////////////////////////////////////////////////////////////
-- Logger implementation

LoggerImpl = Class.new()

function LoggerImpl:new()
	self.logLevel = Logger.LOG_LEVEL_CONSOLE
	self.logFileName = "modloader.log"
	self.logFileHandle = nil
	self.printCallerInfo = false
end

function LoggerImpl:getLoggingLevel()
	return self.logLevel
end

function LoggerImpl:setLoggingLevel(level)
	assert(type(level) == "number")
	assert(
		level == Logger.LOG_LEVEL_NONE or
		level == Logger.LOG_LEVEL_CONSOLE or
		level == Logger.LOG_LEVEL_FILE
	)

	self.logLevel = level
end

function LoggerImpl:getLogFileName()
	return self.logFileName
end

function LoggerImpl:setLogFileName(fileName)
	assert(type(fileName) == "string")

	if (self.logFileHandle) then
		self.logFileHandle:close()
		self.logFileHandle = nil
	end

	self.logFileName = fileName
end

function LoggerImpl:getPrintCallerInfo()
	return self.printCallerInfo
end

function LoggerImpl:setPrintCallerInfo(printCallerInfo)
	assert(type(printCallerInfo) == "boolean")

	self.printCallerInfo = printCallerInfo
end

local function getCurrentDate()
	return os.date("%Y-%m-%d %H:%M:%S")
end

local function openLogFile(fileName)
	local fileHandle = io.open(fileName, "a+")

	local t = string.format("\n===== Logging started at: %s =====\n", getCurrentDate())

	fileHandle:write(t)
	fileHandle:flush()

	ConsolePrint(t)
	print(t)

	return fileHandle
end

function LoggerImpl:log(...)
	if (self.logLevel == Logger.LOG_LEVEL_NONE) then
		return
	end

	for i = 1, #arg do
		arg[i] = tostring(arg[i])
	end

	local message = table.concat(arg, " ")
	local timestamp = getCurrentDate()
	local info = debug.getinfo(2, "Sl")
	local caller = string.format("%s %s:%d", timestamp, info.short_src, info.currentline)

	if (self.logLevel == Logger.LOG_LEVEL_FILE) then
		if (not self.logFileHandle) then
			self.logFileHandle = openLogFile(self.logFileName)
		end

		local t = ""
		if (self.printCallerInfo) then
			t = caller .. "\n"
		end

		t = t .. message .. "\n"

		self.logFileHandle:write(t)
		self.logFileHandle:flush()
	end

	if (self.printCallerInfo) then
		ConsolePrint(caller)
		print(caller)
	end

	ConsolePrint(message)
	print(message)

	local _, newlines = message:gsub("\n", "")
	for i = 1, newlines do
		ConsolePrint("")
	end
end

return Logger

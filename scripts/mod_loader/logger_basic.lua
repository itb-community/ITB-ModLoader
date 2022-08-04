-- Forward declaration
local BasicLoggerImpl

-- ///////////////////////////////////////////////////////////////////////
-- Logger implementation

BasicLoggerImpl = Class.new()

function BasicLoggerImpl:new()
	self.logLevel = Logger.LOG_LEVEL_CONSOLE
	self.logFileName = "modloader.log"
	self.logFileHandle = nil
	self.printCallerInfo = false
	self.clearLogFileOnStartup = false
end

local function getCurrentDate()
	return os.date("%Y-%m-%d %H:%M:%S")
end

function BasicLoggerImpl:buildCallerMessage(callerOffset)
	callerOffset = callerOffset or 0
	assert(type(callerOffset) == "number")

	local timestamp = getCurrentDate()
	local info = debug.getinfo(3 + callerOffset, "Sl")
	local caller = string.format("[%s] [%s:%d]", timestamp, info.short_src, info.currentline)

	return caller
end

function BasicLoggerImpl:getLoggingLevel()
	return self.logLevel
end

function BasicLoggerImpl:setLoggingLevel(level)
	assert(type(level) == "number")
	assert(
		level == Logger.LOG_LEVEL_NONE or
		level == Logger.LOG_LEVEL_CONSOLE or
		level == Logger.LOG_LEVEL_FILE
	)

	self.logLevel = level
end

function BasicLoggerImpl:getLogFileName()
	return self.logFileName
end

function BasicLoggerImpl:setLogFileName(fileName)
	assert(type(fileName) == "string")

	if (self.logFileHandle) then
		self.logFileHandle:close()
		self.logFileHandle = nil
	end

	self.logFileName = fileName
end

function BasicLoggerImpl:getPrintCallerInfo()
	return self.printCallerInfo
end

function BasicLoggerImpl:setPrintCallerInfo(printCallerInfo)
	local argType = type(printCallerInfo)
	assert(argType == "boolean" or argType == "number")
	if argType == "boolean" then
		self.printCallerInfo = printCallerInfo and 1 or 0
	else
		self.printCallerInfo = printCallerInfo
	end
end

function BasicLoggerImpl:setClearLogFileOnStartup(clearLogFileOnStartup)
	assert(type(clearLogFileOnStartup) == "boolean")

	self.clearLogFileOnStartup = clearLogFileOnStartup
end

function BasicLoggerImpl:openLogFile(fileName)
	-- opening the file in write mode will clear out all contents
	-- we prefer append mode for later work as it causes less issues if the user edits the log file while the game is running
	if self.clearLogFileOnStartup then
		local clearFile = io.open(fileName, "w")
		clearFile:flush()
		clearFile:close()
	end

	local fileHandle = io.open(fileName, "a+")

	local t = string.format("\n===== Logging started at: %s =====\n", getCurrentDate())

	fileHandle:write(t)
	fileHandle:flush()

	ConsolePrint(t)
	print(t)

	return fileHandle
end

function BasicLoggerImpl:log(caller, ...)
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

	self:output(message, caller)
end

local function safeGetString(a)
	local t = type(a)
	if t == "userdata" or t == "table" then
		if type(a.GetLuaString) == "function" then
			return string.format("%s (%s)", a:GetLuaString(), t)
		elseif type(a.GetString) == "function" then
			return string.format("%s (%s)", a:GetString(), t)
		end

		if t == "userdata" then
			local mttype = getmetatable(a).__type
			if mttype then
				if mttype == "rect" then
					return string.format("sdl.rect(%s, %s, %s, %s)", a.x, a.y, a.w, a.h)
				end
			else
				return "<userdata>"
			end
		end
	end

	return tostring(a)
end

function BasicLoggerImpl:preprocessInput(...)
	for i = 1, #arg do
		local ok, result = pcall(function() return safeGetString(arg[i]) end)
		if ok then
			arg[i] = result
		else
			arg[i] = "<userdata>"
		end
	end

	local message = table.concat(arg, " ")

	return message
end

local delimiter = "\n"
function BasicLoggerImpl:output(message, caller)
	local text = message
	if (self:getPrintCallerInfo() == Logger.LOG_LEVEL_CONSOLE) then
		text = caller .. ": " .. text
	end

	for match in (text..delimiter):gmatch("(.-)"..delimiter) do
		ConsolePrint(match)
		print(match)
	end
end

return BasicLoggerImpl

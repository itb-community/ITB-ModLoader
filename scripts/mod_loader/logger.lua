local Logger = {
  LOG_LEVEL_NONE = 0,
  LOG_LEVEL_CONSOLE = 1,
  LOG_LEVEL_FILE = 2,

  logLevel = 0,
  logFile = nil,
  printCallerInfo = true,
}

function Logger.logNothing()
  Logger.logLevel = Logger.LOG_LEVEL_NONE
end

function Logger.logToConsole()
  Logger.logLevel = Logger.LOG_LEVEL_CONSOLE
end

function Logger.logToFile(filename)
  Logger.logLevel = Logger.LOG_LEVEL_FILE
  Logger.logFile = io.open(filename, "a+")

  local message =
      string.format("\n===== Logging started at: %s =====\n", os.date("%Y-%m-%d %H:%M:%S"))

  Logger.logFile:write(message)
  Logger.logFile:flush()

  message = string.format("Logging to file: %s", filename)

  ConsolePrint(message)
  print(message)
end

function Logger.log(...)
  if Logger.logLevel == Logger.LOG_LEVEL_NONE then
    return
  end

  for i, v in ipairs(arg) do
    arg[i] = tostring(v)
  end

  local message = table.concat(arg, " ")
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local info = debug.getinfo(2, "Sl")
  local caller = string.format("%s %s:%d", timestamp, info.short_src , info.currentline)

  if Logger.logLevel == Logger.LOG_LEVEL_FILE and Logger.logFile ~= nil then
    Logger.logFile:write(string.format("%s\n%s\n", caller, message))
    Logger.logFile:flush()
  end

  if Logger.printCallerInfo then
  	-- apply this setting only to console printing
  	-- for logfiles this information is good to have
    ConsolePrint(caller)
    print(caller)
  end

  ConsolePrint(message)
  print(message)
end

-- Override the original LOG(...) function.
LOG = Logger.log

return Logger
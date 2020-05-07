local Logger = require("scripts/mod_loader/logger")

-- Forward declaration
local ScrollableLogger

-- ///////////////////////////////////////////////////////////////////////
-- ScrollableLogger interface

ScrollableLogger = Logger:extend()

function ScrollableLogger:new(loggerImpl)
	assert(type(loggerImpl) == "table", "Argument #1 must be a table")
	self:__init(loggerImpl)
end

function ScrollableLogger:__init(loggerImpl)
	self.__super.__init(self, loggerImpl)

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

return ScrollableLogger

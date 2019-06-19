local Logger = require("scripts/mod_loader/logger")

-- Forward declaration
local ScrollableLogger

-- ///////////////////////////////////////////////////////////////////////
-- ScrollableLogger interface

ScrollableLogger = Class.inherit(Logger)

function ScrollableLogger:new(loggerImplClass)
	assert(loggerImplClass, "Argument #1 must not be nil")
	self:__init(loggerImplClass())
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

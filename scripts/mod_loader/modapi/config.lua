
function CurrentModLoaderConfig()
	local data = {}

	data.scrollableLogger    = mod_loader.scrollableLogger
	data.logLevel            = mod_loader.logger:getLoggingLevel()
	data.debugLogs           = modApi.debugLogs
	data.printCallerInfo     = mod_loader.logger:getPrintCallerInfo()
	data.developmentMode     = modApi.developmentMode

	data.profileConfig       = modApi.profileConfig
	data.floatyTooltips      = modApi.floatyTooltips

	data.showErrorFrame      = modApi.showErrorFrame
	data.showVersionFrame    = modApi.showVersionFrame
	data.showResourceWarning = modApi.showResourceWarning
	data.showGamepadWarning  = modApi.showGamepadWarning
	data.showRestartReminder = modApi.showRestartReminder
	data.showPilotRestartReminder = modApi.showPilotRestartReminder
	data.showProfileSettingsFrame = modApi.showProfileSettingsFrame

	return data
end

function SaveModLoaderConfig(data)
	if data.profileConfig then
		if modApi:isProfilePath() then
			sdlext.config(
				modApi:getCurrentProfilePath().."modcontent.lua",
				function(obj)
					obj.modLoaderConfig = data
				end
			)

			-- Need to update shared modcontent.lua with profile config setting
			sdlext.config(
				"modcontent.lua", 
				function(obj)
					obj.modLoaderConfig.profileConfig = true
				end
			)
		end
	else
		sdlext.config(
			"modcontent.lua", 
			function(obj)
				obj.modLoaderConfig = data
			end
		)
	end
end

function DefaultModLoaderConfig()
	return {
		scrollableLogger    = false,
		logLevel            = 1, -- log to console by default
		debugLogs           = false,
		printCallerInfo     = true,
		developmentMode     = false,

		floatyTooltips      = true,
		profileConfig       = false,

		showErrorFrame      = true,
		showVersionFrame    = true,
		showResourceWarning = true,
		showGamepadWarning  = true,
		showRestartReminder = true,
		showPilotRestartReminder = true,
		showProfileSettingsFrame = true
	}
end

function LoadModLoaderConfig(overrideLoadProfileConfig)
	local data = DefaultModLoaderConfig()

	local copyOptionsFn = function(from, to)
		for option, value in pairs(from) do
			to[option] = value
		end
	end

	local readConfigFn = function(obj)
		if not obj.modLoaderConfig then return end
		copyOptionsFn(obj.modLoaderConfig, data)
	end

	sdlext.config("modcontent.lua", readConfigFn)

	local loadProfile = data.profileConfig
	if overrideLoadProfileConfig ~= nil then
		loadProfile = overrideLoadProfileConfig
	end

	if loadProfile and modApi:isProfilePath() then
		sdlext.config(modApi:getCurrentProfilePath().."modcontent.lua", readConfigFn)
	end

	return data
end

local function updateLogger(config)
	if mod_loader.scrollableLogger ~= config.scrollableLogger then
		Logger = Logger or require("scripts/mod_loader/logger")
		local ScrollableLogger = require("scripts/mod_loader/logger_scrollable")

		local BasicLoggerImpl = require("scripts/mod_loader/logger_basic")
		local BufferedLoggerImpl = require("scripts/mod_loader/logger_buffered")

		mod_loader.scrollableLogger = config.scrollableLogger
		if mod_loader.scrollableLogger then
			mod_loader.logger = ScrollableLogger(BufferedLoggerImpl())
		else
			mod_loader.logger = Logger(BasicLoggerImpl())
		end
	end
end

function ApplyModLoaderConfig(config)
	updateLogger(config)

	mod_loader.logger:setLoggingLevel(config.logLevel)
	mod_loader.logger:setPrintCallerInfo(config.printCallerInfo)
	modApi.debugLogs              = config.debugLogs
	modApi.developmentMode        = config.developmentMode

	modApi.floatyTooltips         = config.floatyTooltips
	modApi.profileConfig          = config.profileConfig

	modApi.showErrorFrame         = config.showErrorFrame
	modApi.showVersionFrame       = config.showVersionFrame
	modApi.showResourceWarning    = config.showResourceWarning
	modApi.showGamepadWarning     = config.showGamepadWarning
	modApi.showRestartReminder    = config.showRestartReminder
	modApi.showPilotRestartReminder = config.showPilotRestartReminder
	modApi.showProfileSettingsFrame = config.showProfileSettingsFrame
end

modApi.events.onSettingsChanged:subscribe(function(old, neu)
	if modApi.profileConfig and old.last_profile ~= neu.last_profile then
		ApplyModLoaderConfig(LoadModLoaderConfig())
	end
end)

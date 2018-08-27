
function SaveModLoaderConfig()
	local data = {}
	data.logLevel            = modApi.logger.logLevel
	data.printCallerInfo     = modApi.logger.printCallerInfo
	data.showErrorFrame      = modApi.showErrorFrame
	data.showVersionFrame    = modApi.showVersionFrame
	data.showResourceWarning = modApi.showResourceWarning
	data.showRestartReminder = modApi.showRestartReminder
	data.floatyTooltips      = modApi.floatyTooltips

	sdlext.config("modcontent.lua",function(obj)
		obj.modLoaderConfig = data
	end)
end

function LoadModLoaderConfig()
	local defaults = {
		logLevel            = 1, -- log to console by default
		printCallerInfo     = true,
		showErrorFrame      = true,
		showVersionFrame    = true,
		showResourceWarning = true,
		showRestartReminder = true,
		floatyTooltips      = true
	}

	local data = {}
	sdlext.config("modcontent.lua", function(obj)
		if not obj.modLoaderConfig then return end

		data = obj.modLoaderConfig
	end)

	local getOrDefault = function(field)
		if data[field] ~= nil then
			return data[field]
		else
			return defaults[field]
		end
	end

	data.logLevel            = getOrDefault("logLevel")
	data.printCallerInfo     = getOrDefault("printCallerInfo")
	data.showErrorFrame      = getOrDefault("showErrorFrame")
	data.showVersionFrame    = getOrDefault("showVersionFrame")
	data.showResourceWarning = getOrDefault("showResourceWarning")
	data.showRestartReminder = getOrDefault("showRestartReminder")
	data.floatyTooltips      = getOrDefault("floatyTooltips")

	return data
end

function ApplyModLoaderConfig(config)
	modApi.logger.logLevel        = config.logLevel
	modApi.logger.printCallerInfo = config.printCallerInfo
	modApi.showErrorFrame         = config.showErrorFrame
	modApi.showVersionFrame       = config.showVersionFrame
	modApi.showResourceWarning    = config.showResourceWarning
	modApi.showRestartReminder    = config.showRestartReminder
	modApi.floatyTooltips         = config.floatyTooltips
end

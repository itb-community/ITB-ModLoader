
function SaveModLoaderConfig()
	local data = {}
	data.profileConfig        = modApi.profileConfig

	local pdata = modApi.profileConfig
		and {}
		or  data

	pdata.logLevel            = modApi.logger.logLevel
	pdata.printCallerInfo     = modApi.logger.printCallerInfo
	pdata.showErrorFrame      = modApi.showErrorFrame
	pdata.showVersionFrame    = modApi.showVersionFrame
	pdata.showResourceWarning = modApi.showResourceWarning
	pdata.showRestartReminder = modApi.showRestartReminder
	pdata.floatyTooltips      = modApi.floatyTooltips

	sdlext.config("modcontent.lua", function(obj)
		obj.modLoaderConfig = data
	end)

	if modApi.profileConfig then
		sdlext.config(
			modApi:getCurrentProfilePath().."modcontent.lua",
			function(obj)
				obj.modLoaderConfig = pdata
			end
		)
	end
end

function LoadModLoaderConfig()
	local defaults = {
		logLevel            = 1, -- log to console by default
		printCallerInfo     = true,
		showErrorFrame      = true,
		showVersionFrame    = true,
		showResourceWarning = true,
		showRestartReminder = true,
		floatyTooltips      = true,
		profileConfig       = false
	}

	local data = {}
	sdlext.config("modcontent.lua", function(obj)
		if not obj.modLoaderConfig then return end
		data = obj.modLoaderConfig
	end)

	local pdata = {}
	sdlext.config(
		modApi:getCurrentProfilePath().."modcontent.lua",
		function(obj)
			if not obj.modLoaderConfig then return end
			pdata = obj.modLoaderConfig
		end
	)

	local getOrDefault = function(field, config)
		config = config or (modApi.profileConfig
			and pdata
			or  data)

		if config[field] ~= nil then
			return config[field]
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
	data.profileConfig       = getOrDefault("profileConfig", data)

	return data
end

function ApplyModLoaderConfig(config)
	modApi.logger.setLogLevel(config.logLevel)

	modApi.logger.printCallerInfo = config.printCallerInfo
	modApi.showErrorFrame         = config.showErrorFrame
	modApi.showVersionFrame       = config.showVersionFrame
	modApi.showResourceWarning    = config.showResourceWarning
	modApi.showRestartReminder    = config.showRestartReminder
	modApi.floatyTooltips         = config.floatyTooltips
	modApi.profileConfig          = config.profileConfig
end

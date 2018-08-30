
function CurrentModLoaderConfig()
	local data = {}

	data.profileConfig       = modApi.profileConfig
	data.logLevel            = modApi.logger.logLevel
	data.printCallerInfo     = modApi.logger.printCallerInfo
	data.showErrorFrame      = modApi.showErrorFrame
	data.showVersionFrame    = modApi.showVersionFrame
	data.showResourceWarning = modApi.showResourceWarning
	data.showRestartReminder = modApi.showRestartReminder
	data.floatyTooltips      = modApi.floatyTooltips

	return data
end

function SaveModLoaderConfig(data)
	if data.profileConfig then
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
		logLevel            = 1, -- log to console by default
		printCallerInfo     = true,
		floatyTooltips      = true,
		profileConfig       = false,

		showErrorFrame      = true,
		showVersionFrame    = true,
		showResourceWarning = true,
		showRestartReminder = true
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

	if loadProfile then
		sdlext.config(modApi:getCurrentProfilePath().."modcontent.lua", readConfigFn)
	end

	return data
end

function ApplyModLoaderConfig(config)
	modApi.logger.setLogLevel(config.logLevel)

	modApi.logger.printCallerInfo = config.printCallerInfo
	modApi.floatyTooltips         = config.floatyTooltips
	modApi.profileConfig          = config.profileConfig

	modApi.showErrorFrame         = config.showErrorFrame
	modApi.showVersionFrame       = config.showVersionFrame
	modApi.showResourceWarning    = config.showResourceWarning
	modApi.showRestartReminder    = config.showRestartReminder
end

sdlext.addSettingsChangedHook(function(old, neu)
	if modApi.profileConfig and old.last_profile ~= neu.last_profile then
		ApplyModLoaderConfig(LoadModLoaderConfig())
	end
end)

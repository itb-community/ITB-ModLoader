
local function isSavedataLocationValid(path)
	return modApi:fileExists(path.."io_test.txt")
end

local cachedSavedata = nil
function GetSavedataLocation()
	if not cachedSavedata then
		local candidates = {
			os.getKnownFolder(5).."/My Games/Into The Breach/",
			-- Linux via Steam's Proton wrapper
			"../../steamapps/compatdata/590380/pfx/",
			-- installation dir fallback
			"./user/"
		}

		for _, candidate in ipairs(candidates) do
			if isSavedataLocationValid(candidate) then
				cachedSavedata = candidate
				break
			end
		end

		if not cachedSavedata then
			error("Could not find a valid savedata location?!")
		end

		-- Normalize path separators
		cachedSavedata = string.gsub(cachedSavedata, "\\", "/")
		LOG("Savedata located at:", cachedSavedata)
	end

	return cachedSavedata
end

function CurrentModLoaderConfig()
	local data = {}

	data.profileConfig       = modApi.profileConfig
	data.logLevel            = modApi.logger.logLevel
	data.printCallerInfo     = modApi.logger.printCallerInfo
	data.floatyTooltips      = modApi.floatyTooltips

	data.showErrorFrame      = modApi.showErrorFrame
	data.showVersionFrame    = modApi.showVersionFrame
	data.showResourceWarning = modApi.showResourceWarning
	data.showRestartReminder = modApi.showRestartReminder
	data.showProfileSettingsFrame = modApi.showProfileSettingsFrame

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
		showRestartReminder = true,
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
	modApi.showProfileSettingsFrame = config.showProfileSettingsFrame
end

sdlext.addSettingsChangedHook(function(old, neu)
	if modApi.profileConfig and old.last_profile ~= neu.last_profile then
		ApplyModLoaderConfig(LoadModLoaderConfig())
	end
end)

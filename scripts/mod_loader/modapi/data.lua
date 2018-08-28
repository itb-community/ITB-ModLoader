
--[[
	Reloads the settings file to have access to selected settings
	from in-game lua scripts.
--]]
function modApi:loadSettings()
	local path = os.getKnownFolder(5).."/My Games/Into The Breach/settings.lua"
	if self:fileExists(path) then
		local result = self:loadIntoEnv(path).Settings

		result.screenwidth = ScreenSizeX()
		result.screenheight = ScreenSizeY()

		return result
	end

	return nil
end

--[[
	Reloads profile data of the currently selected profile.
--]]
function modApi:loadProfile()
	Settings = self:loadSettings()

	local path = os.getKnownFolder(5) ..
	             "/My Games/Into the Breach/profile_" ..
	             Settings.last_profile ..
	             "/profile.lua"

	if self:fileExists(path) then
		local result = self:loadIntoEnv(path).Profile

		-- Gut the stat tracker, cause it takes a boatload
		-- of space, and is fairly useless.
		result.stat_tracker = nil

		return result
	end

	return nil
end

function modApi:getCurrentProfilePath()
	Settings = self:loadSettings()
	return "profile_"..Settings.last_profile.."/"
end

function modApi:writeProfileData(id, obj)
	sdlext.config(
		self:getCurrentProfilePath().."modcontent.lua",
		function(readObj)
			readObj[id] = obj
		end
	)
end

function modApi:readProfileData(id)
	local result = nil

	sdlext.config(
		self:getCurrentProfilePath().."modcontent.lua",
		function(readObj)
			result = readObj[id]
		end
	)

	return result
end

function modApi:writeModData(id, obj)
	sdlext.config(
		"modcontent.lua",
		function(readObj)
			readObj[id] = obj
		end
	)
end

function modApi:readModData(id)
	local result = nil

	sdlext.config(
		"modcontent.lua",
		function(readObj)
			result = readObj[id]
		end
	)

	return result
end

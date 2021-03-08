
function modApi:isProfilePath()
	return Settings.last_profile ~= nil and Settings.last_profile ~= ""
end

--[[
	Reloads the settings file to have access to selected settings
	from in-game lua scripts.
--]]
function modApi:loadSettings()
	local path = GetSavedataLocation() .. "settings.lua"
	if self:fileExists(path) then
		local result = self:loadIntoEnv(path).Settings

		-- This value changes from 0 to 1 during
		-- game init, and changes from 1 to 0 after
		-- closing the options menu. Ignore it
		-- to avoid triggering settings changed event.
		result.launch_failed = 0

		return result
	end

	return nil
end

--[[
	Reloads profile data of the currently selected profile.
--]]
function modApi:loadProfile()
	if not self.isProfilePath() then
		return nil
	end

	local path = GetSavedataLocation() .. "profile_" ..
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
	if not self:isProfilePath() then
		return nil
	end

	return "profile_"..Settings.last_profile.."/"
end

function modApi:writeProfileData(id, obj)
	if not self:isProfilePath() then
		return
	end

	sdlext.config(
		self:getCurrentProfilePath().."modcontent.lua",
		function(readObj)
			readObj[id] = obj
		end
	)
end

function modApi:readProfileData(id)
	local result = nil

	if not self:isProfilePath() then
		return result
	end

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

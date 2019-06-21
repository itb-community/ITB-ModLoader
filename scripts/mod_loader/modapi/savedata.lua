
local function isSavedataLocationValid(path)
	return modApi:fileExists(path.."io_test.txt")
end

local cachedSavedataDir = nil
local function getDirectory()
	if not cachedSavedataDir then
		local candidates = {
			os.getKnownFolder(5).."/My Games/Into The Breach/",
			-- Linux via Steam's Proton wrapper
			"../../steamapps/compatdata/590380/pfx/",
			-- installation dir fallback
			"./user/"
		}

		for _, candidate in ipairs(candidates) do
			if isSavedataLocationValid(candidate) then
				cachedSavedataDir = candidate
				break
			end
		end

		if not cachedSavedataDir then
			error("Could not find a valid savedata location?!")
		end

		-- Normalize path separators
		cachedSavedataDir = string.gsub(cachedSavedataDir, "\\", "/")
		LOG("Savedata located at:", cachedSavedataDir)
	end

	return cachedSavedataDir
end

--[[
	Returns a savedata table holding information about the region the player
	is currently in. Returns nil when not in a mission.
--]]
local function getCurrentRegion(sourceTable)
    if not sourceTable then
        sourceTable = RegionData
    end

	if sourceTable and sourceTable.iBattleRegion then
		if sourceTable.iBattleRegion == 20 then
			return sourceTable["final_region"]
		else
			return sourceTable["region"..sourceTable.iBattleRegion]
		end
	end

	return nil
end

local getPawnTable = nil
getPawnTable = function(pawnId, sourceTable)
	if sourceTable then
		for k, v in pairs(sourceTable) do
			if type(v) == "table" and v.id and modApi:stringStartsWith(k, "pawn") then
				if v.id == pawnId then return v end
			end
		end	
	else
		local region = getCurrentRegion()
		local ptable = getPawnTable(pawnId, SquadData)
		if not ptable and region then
			ptable = getPawnTable(pawnId, region.player.map_data)
		end

		return ptable
	end

	return nil
end

local function getPath(settings)
	settings = settings or Settings

	local path = getDirectory()
	return path.."profile_"..settings.last_profile.."/saveData.lua"
end

local function read(arg)
	local saveFile

	if not arg then
		saveFile = getPath(Settings)
	elseif type(arg) == "table" then
		saveFile = getPath(arg)
	elseif type(arg) == "string" then
		saveFile = arg
	else
		error("Expected table, string, or nil but got: " .. type(arg))
	end
	
	if modApi:fileExists(saveFile) then
		return modApi:loadIntoEnv(saveFile)
	end

	error("Could not read save file because file does not exist: "..saveFile)
end

local function update(fn)
	local saveFile = getPath(Settings)
	local save = read(saveFile)

	fn(save)

	local content = ""
	for k, v in pairs(save) do
		content = content .. string.format("%s = %s\n\n", k, save_table(v))
	end

	modApi:writeFile(saveFile, content)

	RestoreGlobalVariables(Settings)
end

-- Compatibility
UpdateSaveData = update
GetCurrentRegion = getCurrentRegion
GetSavedataLocation = getDirectory
GetPawnTable = getPawnTable

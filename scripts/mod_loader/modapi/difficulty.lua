
-- /////////////////////////////////////////////////////////////////////////////////////
-- Modded difficulty levels

DifficultyLevels = {
	"DIFF_EASY",
	"DIFF_NORMAL",
	"DIFF_HARD"
}

local function validateDifficulty(level, unregistered)
	assert(type(level) == "number", "Difficulty must be an integer, got " .. type(level))
	assert(level >= 0, "Difficulty must not be negative, got " .. level)
	if not unregistered then
		assert(_G[DifficultyLevels[level + 1]] == level, "Unknown difficulty level: " .. level)
	end
end

--[[
	Returns ID of the difficulty level:
		"DIFF_EASY", "DIFF_VERY_HARD"
--]]
function GetDifficultyId(level)
	level = level or GetDifficulty()
	validateDifficulty(level)

	return DifficultyLevels[level + 1]
end

--[[
	Returns ID of the difficulty level, but with "DIFF_" trimmed out:
		"EASY", "VERY_HARD"
--]]
function GetDifficultyString(level)
	level = level or GetDifficulty()
	validateDifficulty(level)

	return string.sub(DifficultyLevels[level + 1], 6)
end

local function toCapitalizedCase(str)
	assert(type(str) == "string")
	return str:sub(1, 1):upper() .. str:sub(2):lower()
end

--[[
	Returns a suffix used to access texts related to the difficulty
	level in the Global_Texts table:
		"Easy", "VeryHard"
--]]
function GetDifficultyTipSuffix(level)
	level = level or GetDifficulty()
	validateDifficulty(level)

	local name = string.sub(DifficultyLevels[level + 1], 6)

	local result = ""
	for str in string.gmatch(name, "([^_]+)") do
		result = result .. toCapitalizedCase(str)
	end

	return result
end

--[[
	Returns name of the difficulty level
--]]
function GetDifficultyFaceName(level)
	level = level or GetDifficulty()
	validateDifficulty(level)

	local suffix = GetDifficultyTipSuffix(level)

	return GetText("Difficulty_Name_"..suffix)
end

local function copySpawner(src)
	local t = {}

	for sectorId, data in ipairs(src) do
		t[sectorId] = Spawner:new(data)
	end

	return t
end

function AddDifficultyLevel(id, level)
	assert(type(id) == "string", "Difficulty level id must be a string, got: " .. type(id))
	assert(id == string.upper(id), "Difficulty level id must use only uppercase letters.")
	assert(modApi:stringStartsWith(id, "DIFF_"), "Difficulty level id must begin with 'DIFF_', got: " .. id)
	validateDifficulty(level, true)
	assert(
		level <= #DifficultyLevels,
		"Level being added must form a contiguous range with existing difficulties"
	)

	local index = level + 1

	-- Rebuild SectorSpawners array, to account for shifting
	-- caused by the new difficulty level.
	local newSectorSpawners = {}
	for i, diffId in ipairs(DifficultyLevels) do
		local lvl = _G[diffId]

		-- We skip one index here, we'll fill it at the end
		if i < index then
			-- No change, copy as-is
			newSectorSpawners[lvl] = SectorSpawners[lvl]
		else
			newSectorSpawners[lvl + 1] = SectorSpawners[lvl]
		end
	end
	SectorSpawners = newSectorSpawners

	_G[id] = level

	for i = index, #DifficultyLevels do
		_G[DifficultyLevels[i]] = i
	end

	table.insert(DifficultyLevels, index, id)

	-- Default to using the same spawner logic as baseline difficulty level
	SectorSpawners[level] = copySpawner(SectorSpawners[GetBaselineDifficulty(level)])
end

--[[
	Returns true if the specified level is a vanilla difficulty level,
	false otherwise.
	This function accounts for level shifting caused by addition of
	custom difficulty levels.
--]]
function IsVanillaDifficultyLevel(level)
	level = level or GetDifficulty()
	validateDifficulty(level)
	return level == DIFF_EASY   or
	       level == DIFF_NORMAL or
	       level == DIFF_HARD
end

--[[
	Returns the baseline difficulty level for the specified level.

	A baseline difficulty level is the vanilla difficulty level that
	is immediately below the one specified. Eg. a custom difficulty of
	level 2 would sit between DIFF_NORMAL and DIFF_HARD, so its
	baseline difficulty level would be DIFF_NORMAL.
--]]
function GetBaselineDifficulty(level)
	level = level or GetDifficulty()
	validateDifficulty(level)

	if level < DIFF_NORMAL then
		return DIFF_EASY
	elseif level < DIFF_HARD then
		return DIFF_NORMAL
	else
		return DIFF_HARD
	end
end

local tempTipTitle, tempTipText, tempToggle
function SetDifficulty(level)
	validateDifficulty(level)

	local oldLevel = GetDifficulty()
	if tempTipTitle or tempTipText or tempToggle then
		local baseSuffix = GetDifficultyTipSuffix(GetBaselineDifficulty(oldLevel))

		if tempTipTitle then
			modApi.dictionary["TipTitle_Hangar"..baseSuffix] = tempTipTitle
		end
		if tempTipText then
			modApi.dictionary["TipText_Hangar"..baseSuffix] = tempTipText
		end
		if tempToggle then
			modApi.dictionary["Toggle_"..baseSuffix] = tempToggle
		end

		tempTipTitle = nil
		tempTipText = nil
		tempToggle = nil
	end

	-- Cleanup the lingering difficulty from profile data
	if modApi:readProfileData("CustomDifficulty") then
		modApi:writeProfileData("CustomDifficulty", nil)
	end

	if Game and GAME then
		GAME.CustomDifficulty = level

		local baseSuffix = GetDifficultyTipSuffix(GetBaselineDifficulty(level))
		tempToggle = modApi.dictionary["Toggle_"..baseSuffix]
		modApi.dictionary["Toggle_"..baseSuffix] = GetDifficultyFaceName(level)
	else
		-- Hangar, before the game
		modApi:writeModData("CustomDifficulty", level)

		local tipSuffix = GetDifficultyTipSuffix(level)
		local baseSuffix = GetDifficultyTipSuffix(GetBaselineDifficulty(level))

		tempTipTitle = modApi.dictionary["TipTitle_Hangar"..baseSuffix]
		tempTipText = modApi.dictionary["TipText_Hangar"..baseSuffix]
		tempToggle = modApi.dictionary["Toggle_"..baseSuffix]

		modApi.dictionary["TipTitle_Hangar"..baseSuffix] = GetText("Difficulty_Title_"..tipSuffix)
		modApi.dictionary["TipText_Hangar"..baseSuffix] = GetText("Difficulty_Description_"..tipSuffix)
		modApi.dictionary["Toggle_"..baseSuffix] = GetDifficultyFaceName(level)

		if not IsVanillaDifficultyLevel(level) then
			modApi.dictionary["TipText_Hangar"..baseSuffix] =
				GetText("TipText_Hangar"..baseSuffix) .. "\n\n" .. GetText("Difficulty_Custom_Note")
		end
	end
end

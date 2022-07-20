-- Legacy: originally GetDifficulty() returned the custom difficulty while GetRealDifficulty() returned vanilla
GetRealDifficulty = GetDifficulty

DifficultyLevels = {
	"DIFF_EASY",
	"DIFF_NORMAL",
	"DIFF_HARD",
  "DIFF_UNFAIR"
}
-- legacy difficulty variables, you should be using DIFF_UNFAIR
DIFF_VERY_HARD = DIFF_UNFAIR
DIFF_IMPOSSIBLE = DIFF_UNFAIR

local function validateDifficulty(level, unregistered)
	assert(type(level) == "number", "Difficulty must be an integer, got " .. type(level))
	assert(level >= 0, "Difficulty must not be negative, got " .. level)
	if not unregistered then
		assert(_G[DifficultyLevels[level + 1]] == level, "Unknown difficulty level: " .. level)
	end
end

--[[
	Returns ID of the difficulty level:
		"DIFF_EASY", "DIFF_UNFAIR"
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
	return string.sub(GetDifficultyId(level), 6)
end

local function capitalizeFirst(str)
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
	return capitalizeFirst(GetDifficultyString(level))
end

--[[
	Returns name of the difficulty level
--]]
function GetDifficultyFaceName(level)
	return GetText("TipTitle_Hangar" .. GetDifficultyTipSuffix(level))
end

--[[
	Returns true if the specified level is a vanilla difficulty level,
	false otherwise.
	This function accounts for level shifting caused by addition of
	custom difficulty levels.
--]]
function IsVanillaDifficultyLevel(level)
	level = level or GetDifficulty()
  -- no validate to make this function useful, as validate would cause it to assert fail on non-vanilla
	return level == DIFF_EASY   or
	       level == DIFF_NORMAL or
	       level == DIFF_HARD   or
         level == DIFF_UNFAIR
end


-- removed functions, but giving a nicer removal error

function GetBaselineDifficultyLevel(level)
  assert(false, "GetBaselineDifficultyLevel is no longer functional, migrate calls to this function to GetDifficulty()")
end

function AddDifficultyLevel(id, level)
  assert(false, "AddDifficultyLevel is no longer functional, migrate calls to this function to config settings")
end

function SetDifficulty(level)
  assert(false, "SetDifficulty is no longer functional, migrate calls to this function to config settings")
end

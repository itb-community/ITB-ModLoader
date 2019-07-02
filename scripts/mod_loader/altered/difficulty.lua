
GetRealDifficulty = GetDifficulty

function GetDifficulty()
	if Game and GAME and GAME.CustomDifficulty then
		return GAME.CustomDifficulty
	else
		local customDiff = modApi:readModData("CustomDifficulty")
		if customDiff then
			return customDiff
		end
	end

	return GetRealDifficulty()
end

-- /////////////////////////////////////////////////////////////////////////////////////
-- Tweak existing code to work with custom difficulty levels
-- Replacing instances of GetDifficulty() with GetRealDifficulty()

local functions = {
	{"Mission_Final", "StartMission"},
	{"getEnvironmentChance"},
	{"Mission_SpiderBoss", "SpawnSpiderlings"},
	{"Mission", "GetKillBonus"},
	{"Mission", "GetStartingPawns"},
	{"Mission", "GetSpawnsPerTurn"},
	{"Mission", "GetMaxEnemy"},
	{"Mission", "GetSpawnCount"}
}

for _, v in ipairs(functions) do
	local fn = _G
	local key = nil
	
	for _, tbl in ipairs(v) do
		if type(fn[tbl]) == 'function' then
			key = tbl
			break
		elseif type(fn[tbl]) == 'table' then
			fn = fn[tbl]
		else
			break
		end
	end
	
	if key ~= nil then
		local oldFn = fn[key]
		fn[key] = function(...)
			local oldGetDiff = GetDifficulty
			GetDifficulty = GetRealDifficulty
			
			local ret = oldFn(...)
			
			GetDifficulty = oldGetDiff
			
			return ret
		end
	end
end

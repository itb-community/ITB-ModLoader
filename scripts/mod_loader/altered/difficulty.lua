
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

local functionsToReplace = {
    _G = { "getEnvironmentChance" },
    Mission_Final = { "StartMission" },
    Mission_SpiderBoss = { "SpawnSpiderlings" },
    Mission = {
        "GetKillBonus",
        "GetStartingPawns",
        "GetSpawnsPerTurn",
        "GetMaxEnemy",
        "GetSpawnCount"
    }
}

local function buildReplacementFunction(sourceFn)
    return function(...)
        local oldGetDiff = GetDifficulty

        -- Only replace if we need to, to account for
        -- nested function calls
        if GetDifficulty ~= GetRealDifficulty then
            GetDifficulty = GetRealDifficulty
        end

        local result = sourceFn(...)

        if GetDifficulty == GetRealDifficulty then
            GetDifficulty = oldGetDiff
        end

        return result
    end
end

for tableName, functionList in pairs(functionsToReplace) do
    local tbl = _G[tableName]

    for _, functionName in ipairs(functionList) do
        local fn = tbl[functionName]
        if type(fn) == "function" then
            tbl[functionName] = buildReplacementFunction(fn)
        end
    end
end

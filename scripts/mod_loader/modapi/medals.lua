
-- use strings to make modcontent.lua easily readable for all users
local ISLANDS = {
	"2islands",
	"3islands",
	"4islands"
}

local DIFFICULTIES = {
	"NONE",
	"EASY",
	"NORMAL",
	"HARD",
	"UNFAIR",
}

local VANILLA_SQUADS = {
	Archive_A = true,
	Rust_A = true,
	Pinnacle_A = true,
	Detritus_A = true,
	Archive_B = true,
	Rust_B = true,
	Pinnacle_B = true,
	Detritus_B = true,
	Secret = true,
	Secret = true,
	Squad_Bomber = true,
	Squad_Spiders = true,
	Squad_Mist = true,
	Squad_Heat = true,
	Squad_Cataclysm = true,
}

function modApi:isVanillaSquad(squad_id)
	return VANILLA_SQUADS[squad_id] == true
end

function modApi:isModdedSquad(squad_id)
	local squad = self.mod_squads_by_id[squad_id]
	return squad ~= nil and not self:isVanillaSquad(squad_id)
end

-- returns the greatest difficulty of diffA and diffB
local function getGreaterDifficulty(diffA, diffB)
	local num_diffA = list_indexof(DIFFICULTIES, diffA)
	local num_diffB = list_indexof(DIFFICULTIES, diffB)

	if num_diffA > num_diffB then
		return diffA
	else
		return diffB
	end
end

local function pruneInvalidSquads(medals)
	local rem = {}
	for invalidSquadId, _ in pairs(medals) do
		if VANILLA_SQUADS[invalidSquadId] ~= nil then
			rem[#rem+1] = invalidSquadId
		end
	end

	for _, invalidSquadId in ipairs(rem) do
		medals[invalidSquadId] = nil
	end
end

local function pruneInvalidMedals(squadMedals)
	local rem = {}
	for invalidIslandsSecured, invalidDifficulty in pairs(squadMedals) do
		if
			not list_contains(ISLANDS, invalidIslandsSecured)  or
			not list_contains(DIFFICULTIES, invalidDifficulty)
		then
			rem[#rem+1] = invalidIslandsSecured
		end
	end

	for _, invalidIslandsSecured in ipairs(rem) do
		squadMedals[invalidIslandsSecured] = nil
	end
end

local function validateAndCacheSaveData(squads_by_id)
	sdlext.config(
		modApi:getCurrentProfilePath().."modcontent.lua",
		function(obj)
			local medals = obj.medals or {}
			obj.medals = medals
			modApi.medals.cachedData = medals
			squads_by_id = squads_by_id or medals
			pruneInvalidSquads(medals)

			for squad_id, _ in pairs(squads_by_id) do
				if modApi:isModdedSquad(squad_id) then
					local squadMedals = medals[squad_id] or {}
					medals[squad_id] = squadMedals
					pruneInvalidMedals(squadMedals)

					for _, islandsSecured in ipairs(ISLANDS) do
						squadMedals[islandsSecured] = squadMedals[islandsSecured] or DIFFICULTIES[1]
					end
				end
			end
		end
	)
end

-- writes medal data to modcontent.lua
local function writeMedalData(self, squad_id, difficulty, islandsSecured)
	if
		not modApi:isProfilePath()         or
		not modApi:isModdedSquad(squad_id) or
		islandsSecured < 2                 or
		difficulty < DIFF_EASY             or
		difficulty > DIFF_UNFAIR
	then
		return
	end

	-- convert numerical island count and difficulty to
	-- strings, in order to write human readable save
	-- data to profile.
	islandsSecured = ISLANDS[islandsSecured - 1]
	difficulty = DIFFICULTIES[difficulty + 2]

	-- validate and cache already saved medal data
	if self.cachedData == nil then
		validateAndCacheSaveData()
	end

	-- validate and cache medal data for new mod squads
	if self.cachedData[squad_id] == nil then
		validateAndCacheSaveData(modApi.mod_squads_by_id)
	end

	sdlext.config(
		modApi:getCurrentProfilePath().."modcontent.lua",
		function(obj)
			local squadMedals = obj.medals[squad_id]

			local currentCompletedDifficulty = squadMedals[islandsSecured]
			squadMedals[islandsSecured] = getGreaterDifficulty(difficulty, currentCompletedDifficulty)
			self.cachedData = obj.medals
		end
	)
end

-- reads medal data.
local function readMedalData(self, squad_id)
	if
		not modApi:isProfilePath()         or
		not modApi:isModdedSquad(squad_id)
	then
		return nil
	end

	-- validate and cache already saved medal data
	if self.cachedData == nil then
		validateAndCacheSaveData()
	end

	-- validate and cache medal data for new mod squads
	if self.cachedData[squad_id] == nil then
		validateAndCacheSaveData(modApi.mod_squads_by_id)
	end

	return self.cachedData[squad_id]
end

modApi.events.onGameVictory:subscribe(function(difficulty, islandsSecured, squad_id)
	modApi.medals:writeData(squad_id, difficulty, islandsSecured)
end)

modApi.events.onProfileChanged:subscribe(function()
	modApi.medals.cachedData = nil
end)

modApi.medals = {
	cachedData = nil,
	writeData = writeMedalData,
	readData = readMedalData,
}

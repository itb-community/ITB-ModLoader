
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
	if modApi:isVanillaSquad(squad_id) then
		return modApi.medals.statsVanilla[squad_id] or {}
	elseif modApi:isProfilePath() ~= true then
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

local function isVanillaSquad(squadIndex, mechs)
	local vanillaSquad = modApi.vanillaSquadsByIndex[squadIndex]

	if vanillaSquad == nil then
		return false
	end

	for i, mech in ipairs(mechs) do
		if vanillaSquad.mechs[i] ~= mech then
			return false
		end
	end

	return true
end

local function updateVanillaRibbons(self)

	local currentProfile = modApi:getCurrentProfile()
	local profileStatistics = modApi:getProfileStatistics(currentProfile)

	if profileStatistics == nil then
		return
	end

	local stat_tracker = profileStatistics.stat_tracker
	local i = 0
	local score = stat_tracker["score"..i]
	local statsVanilla = {}
	local statsPolluted = {}
	local statsVanillaAndPolluted = { statsVanilla, statsPolluted }

	while score do
		if true
			and score.victory == true
			and score.islands ~= nil
			and score.squad ~= modApi.constants.SQUAD_INDEX_RANDOM
			and score.squad ~= modApi.constants.SQUAD_INDEX_CUSTOM
		then
			local squadRibbons
			local islandsSecured = ISLANDS[score.islands - 1]
			local difficulty = DIFFICULTIES[score.difficulty + 2]

			-- Tally up all scores into statsPolluted,
			-- but only tally up scores where the used squad
			-- is a vanilla squad will all the correct mechs
			-- into statsVanilla.
			for _, allRibbons in ipairs(statsVanillaAndPolluted) do
				if false
					or allRibbons == statsPolluted
					or isVanillaSquad(score.squad, score.mechs)
				then
					local squadId = modApi.vanillaSquadsByIndex[score.squad].id
					squadRibbons = allRibbons[squadId]
					if squadRibbons == nil then
						squadRibbons = {}
						allRibbons[squadId] = squadRibbons
					end

					local currentCompletedDifficulty = squadRibbons[islandsSecured] or DIFFICULTIES[1]
					squadRibbons[islandsSecured] = getGreaterDifficulty(difficulty, currentCompletedDifficulty)
				end
			end
		end

		i = i + 1
		score = stat_tracker["score".. i]
	end

	modApi.medals.statsVanilla = statsVanilla
	modApi.medals.statsPolluted = statsPolluted
end

function isRibbonOvervalued(self, squad_id, islands)
	if self.statsVanilla == nil or self.statsPolluted == nil then
		self:updateVanillaRibbons()
	end

	if type(islands) == "number" then
		islands = tostring(islands).."islands"
	end

	-- If this is a modded squad or there is no stat
	-- pollution, then the ribbon cannot be overvalued.
	if false
		or modApi:isModdedSquad(squad_id)
		or modApi.medals.statsPolluted[squad_id] == nil
	then
		return false
	end

	-- If there is vanilla squad stat pollution and no
	-- vanilla stats, then the ribbon must be overvalued.
	if modApi.medals.statsVanilla[squad_id] == nil then
		return true
	end

	local scorePolluted = modApi.medals.statsPolluted[squad_id][islands]
	local scoreVanilla = modApi.medals.statsVanilla[squad_id][islands]

	-- If there is no stat pollution, then the ribbon is
	-- not overvalued.
	if scorePolluted == nil then
		return false
	end

	-- If there is stat pollution, but no vanilla stat,
	-- then the ribbon must be overvalued.
	if scoreVanilla == nil then
		return true
	end

	-- LOGF("5 scorePolluted = %s, scoreVanilla = %s", tostring(scorePolluted), tostring(scoreVanilla))
	return getGreaterDifficulty(scorePolluted, scoreVanilla) ~= scoreVanilla
end

modApi.events.onGameVictory:subscribe(function(difficulty, islandsSecured, squad_id)
	modApi.medals:writeData(squad_id, difficulty, islandsSecured)
	modApi.medals.statsVanilla = nil
	modApi.medals.statsPolluted = nil
end)

modApi.events.onProfileChanged:subscribe(function()
	modApi.medals.cachedData = nil
	modApi.medals.statsVanilla = nil
	modApi.medals.statsPolluted = nil
end)

modApi.medals = {
	cachedData = nil,
	statsVanilla = nil,
	statsPolluted = nil,
	writeData = writeMedalData,
	readData = readMedalData,
	updateVanillaRibbons = updateVanillaRibbons,
	isRibbonOvervalued = isRibbonOvervalued,
}

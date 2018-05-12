----Add API functionality that changes existing content here----

--[[
	Rewrites text.lua so that Global_Texts table inside
	of it becomes globally accessible.
--]]
local function GlobalizeGlobalTexts()
	if not Global_Texts then
		local path = "scripts/text.lua"
		local file = io.open(path, "rb")

		local content = file:read("*all")
		file:close()
		file = nil

		content = string.sub(content, 8)
		file = io.open(path, "w+b")
		file:write(content)
		file:close()

		dofile(path)
		LOG("Globalized Global_Texts")
	end
end
GlobalizeGlobalTexts()

oldGetPopulationTexts = GetPopulationTexts
local oldGetStartingSquad = getStartingSquad
local oldBaseNextTurn = Mission.BaseNextTurn
local oldBaseUpdate = Mission.BaseUpdate
local oldBaseDeployment = Mission.BaseDeployment
local oldBaseStart = Mission.BaseStart
local oldApplyEnvironmentEffect = Mission.ApplyEnvironmentEffect
local oldGetText = GetText
local oldStartNewGame = startNewGame
local oldLoadGame = LoadGame
local oldSaveGame = SaveGame
local oldTriggerVoice = TriggerVoiceEvent
local oldGetDifficulty = GetDifficulty

function getStartingSquad(choice)
	if choice == 0 then
		loadPilotsOrder()
		loadSquadSelection()
	end
	
	if choice >= 0 and choice <= 7 then
		local index = modApi.squadIndices[choice + 1]
		
		modApi:overwriteText(
			"TipTitle_"..modApi.squadKeys[choice + 1],
			modApi.squad_text[2 * (index - 1) + 1]
		)
		modApi:overwriteText(
			"TipText_"..modApi.squadKeys[choice + 1],
			modApi.squad_text[2 * (index - 1) + 2]
		)
		
		return modApi.mod_squads[index]
	else
		return oldGetStartingSquad(choice)
	end
end

function Mission:BaseNextTurn()
	oldBaseNextTurn(self)
	
	for i, hook in ipairs(modApi.nextTurnHooks) do
		hook(self)
	end
end

function Mission:BaseUpdate()
	modApi:processRunLaterQueue(self)

	oldBaseUpdate(self)
	
	for i, hook in ipairs(modApi.missionUpdateHooks) do
		hook(self)
	end
end

function Mission:BaseDeployment()
	oldBaseDeployment(self)

	for i, hook in ipairs(modApi.missionStartHooks) do
		hook(self)
	end	
end

function Mission:MissionEnd()
	local ret = SkillEffect()
	
	CurrentMission = self
	EndingMission = true
	self.delayToAdd = 4
	for i, hook in ipairs(modApi.missionEndHooks) do
		hook(self,ret)
	end
	ret:AddDelay(self:GetEndDelay())
	EndingMission = false
		
	Board:AddEffect(ret)
end

function Mission:SetupDifficulty()
	-- Can be used to setup the difficulty of this mission
	-- with regard to value returned by GetDifficulty()
end

function Mission:BaseStart()
	for i, hook in ipairs(modApi.preMissionAvailableHooks) do
		hook(self)
	end
	
	-- begin oldBaseStart
	self.VoiceEvents = {}
	
	if self.AssetId ~= "" then
		self.AssetLoc = Board:AddUniqueBuilding(_G[self.AssetId].Image)
	end
	
	self.LiveEnvironment = _G[self.Environment]:new()
	self:SetupDifficulty()

	self.LiveEnvironment:Start()
	self:StartMission()
	
	self:SetupDiffMod()
	
	self:SpawnPawns(self:GetStartingPawns())
	-- end oldBaseStart
	
	for i, hook in ipairs(modApi.postMissionAvailableHooks) do
		hook(self)
	end
end

function Mission:GetEndDelay()
	return math.max(0,self.delayToAdd)
end

function Mission:ApplyEnvironmentEffect()
	for i, hook in ipairs(modApi.preEnvironmentHooks) do
		hook(self)
	end
	
	local retValue = false
	if self.LiveEnvironment:IsEffect() then
		retValue = oldApplyEnvironmentEffect(self)
	end
	
	for i, hook in ipairs(modApi.postEnvironmentHooks) do
		hook(self)
	end
	
	return retValue
end

function Mission:IsEnvironmentEffect()
	return true
end

function GetText(id)
	if modApi.textOverrides and modApi.textOverrides[id] then
		return modApi.textOverrides[id]
	end
	
	return oldGetText(id)
end

function GetPopulationTexts(event, count)
	local nullReturn = count == 1 and "" or {}
	
	if modApi.PopEvents[event] == nil then
		return nullReturn
	end
	
	if Game == nil then
        return nullReturn
    end
	
	local list = copy_table(modApi.PopEvents[event])
	local ret = {}
	for i = 1, count do
		if #list == 0 then
			break
		end
		
		ret[#ret+1] = random_removal(list)
		
		
		if modApi.PopEvents[event].Odds ~= nil and random_int(100) > modApi.PopEvents[event].Odds then
			ret[#ret] = nil
		end
	end
	
	if #ret == 0 then
		return nullReturn
	end

	local corp_name = Game:GetCorp().bark_name
	local squad_name = Game:GetSquad()
	for i,v in ipairs(ret) do
		ret[i] = string.gsub(ret[i], "#squad", squad_name)
		ret[i] = string.gsub(ret[i], "#corp", corp_name)
		for j, fn in ipairs(modApi.onGetPopEvent) do
			ret[i] = fn(ret[i],ret,i,event,count)
		end
	end
	
	if count == 1 then
		return ret[1]
	end
	
	return ret
end

function TriggerVoiceEvent(event, custom_odds)
	local suppress = false

	for i, hook in ipairs(modApi.voiceEventHooks) do
		suppress = suppress or hook(event, custom_odds, suppress)
	end

	if not suppress then
		oldTriggerVoice(event, custom_odds)
	end
end

-- ///////////////////////////////////////////////////////////////////

--[[
	Reload data from the save file to obtain up-to-date
	instances of GameData, RegionData, and SquadData
--]]
local function restoreGameVariables(settings)
	-- Grab the last profile from settings. It's updated as soon
	-- as the player switches the profile, so it should be okay.
	local path = os.getKnownFolder(5).."/My Games/Into The Breach/"
	local saveFile = path.."profile_"..settings.last_profile.."/saveData.lua"
	
	if modApi:fileExists(saveFile) then
		-- Load the current save file
		local env = modApi:loadIntoEnv(saveFile)
		
		GameData = env.GameData
		RegionData = env.RegionData
		SquadData = env.SquadData
	end
end

--[[
	GAME's class is GameObject, defined in game.lua
	But that class is local to that file, so we can't access
	it here. We have to override the function on the instance
	of the GAME object. Defer this into a function call, since
	GAME is not available when the modloader is ran.
--]]
local function overrideNextPhase()
	GAME.CreateNextPhase = function(self, mission)
		local prevMission = self:GetMission(mission)
		local nxtId = prevMission.NextPhase

		getmetatable(self).CreateNextPhase(self, mission)

		if nxtId ~= "" then
			-- Set the mission's id, since the game doesn't do it
			local nextMission = _G[nxtId]
			nextMission.ID = nxtId

			for i, hook in ipairs(modApi.missionNextPhaseCreatedHooks) do
				hook(prevMission, nextMission)
			end
		end
	end
end

function startNewGame()
	Settings = modApi:loadSettings()
	
	GameData = nil
	RegionData = nil
	SquadData = nil

	local modOptions = mod_loader:getCurrentModContent()
	local savedOrder = mod_loader:getCurrentModOrder()

	for i, hook in ipairs(modApi.preStartGameHooks) do
		hook()
	end

	oldStartNewGame()

	overrideNextPhase()
	
	GAME.modOptions = modOptions
	GAME.modLoadOrder = savedOrder
	GAME.squadTitles = {}
	
	for i, key in ipairs(modApi.squadKeys) do
		GAME.squadTitles["TipTitle_"..key] = GetText("TipTitle_"..key)
	end

	SetDifficulty(GetDifficulty())

	-- Schedule execution to happen in 50ms
	-- After new game is started, the game saves game state twice,
	-- but the first state saved is still the old one?
	-- So we can't restore game vars there, cause then we'll have
	-- competely wrong data.
	modApi:scheduleHook(50, function()
		restoreGameVariables(Settings)
		-- Execute hook in the deferred callback, since we want
		-- postStartGameHook to have access to the savegame data
		for i, hook in ipairs(modApi.postStartGameHooks) do
			hook()
		end
	end)
end

function LoadGame()
	Settings = modApi:loadSettings()

	GAME.modOptions = GAME.modOptions or mod_loader:getModConfig()
	GAME.modLoadOrder = GAME.modLoadOrder or mod_loader:getSavedModOrder()

	mod_loader:loadModContent(GAME.modOptions, GAME.modLoadOrder)

	if GAME.squadTitles then
		for k, name in pairs(GAME.squadTitles) do
			modApi:overwriteText(k,name)
		end
	end

	for i, hook in ipairs(modApi.preLoadGameHooks) do
		hook()
	end

	GAME.CreateNextPhase = nil

	oldLoadGame()

	restoreGameVariables(Settings)
	overrideNextPhase()

	if GAME.CustomDifficulty then
		SetDifficulty(GAME.CustomDifficulty)
	end

	for i, hook in ipairs(modApi.postLoadGameHooks) do
		hook()
	end
end

function SaveGame()
	for i, hook in ipairs(modApi.saveGameHooks) do
		hook()
	end

	if Game and GameData then
		-- Reload the save, since sometimes the savefile
		-- has more recent data than the global variables (?!)
		-- But only do that if we already have those vars
		-- defined, to prevent grabbing stale data.
		modApi:scheduleHook(50, function()
			Settings = modApi:loadSettings()
			restoreGameVariables(Settings)
			overrideNextPhase()
		end)
	end

	GAME.CreateNextPhase = nil
	return oldSaveGame()
end

-- ///////////////////////////////////////////////////////////////////

local originalGetTargetArea = Move.GetTargetArea
function Move:GetTargetArea(point)
    local moveSkill = _G[Pawn:GetType()].MoveSkill
	
	if moveSkill ~= nil and moveSkill.GetTargetArea ~= nil then
		return moveSkill:GetTargetArea(point)
    end

    return originalGetTargetArea(self, point)
end

local originalGetSkillEffect = Move.GetSkillEffect
function Move:GetSkillEffect(p1, p2)
    local moveSkill = _G[Pawn:GetType()].MoveSkill

    if moveSkill ~= nil and moveSkill.GetSkillEffect ~= nil then
		return moveSkill:GetSkillEffect(p1, p2)
    end
    
    return originalGetSkillEffect(self, p1, p2)
end

function CreatePilot(data)
	_G[data.Id] = Pilot:new(data)

	-- Make sure we don't create duplicates if the PilotList
	-- already contains entry for this pilot
	if data.Rarity ~= 0 and not list_contains(PilotList, data.Id) then
		PilotList[#PilotList + 1] = data.Id
	end
end

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
	Returns name of the difficulty level that will be displayed
	to the user, obtained by replacing all underscores with spaces
	and capitalizing each word in the difficulty string.
		"Easy", "Very Hard"
--]]
function GetDifficultyFaceName(level)
	level = level or GetDifficulty()
	validateDifficulty(level)

	local name = string.sub(DifficultyLevels[level + 1], 6)

	local result = ""
	for str in string.gmatch(name, "([^_]+)") do
		result = result .. " " .. toCapitalizedCase(str)
	end

	return modApi:trimString(result)
end

function AddDifficultyLevel(id, level, tipTitle, tipText)
	assert(type(id) == "string", "Difficulty level id must be a string, got: " .. type(id))
	assert(id == string.upper(id), "Difficulty level id must use only uppercase letters.")
	assert(modApi:stringStartsWith(id, "DIFF_"), "Difficulty level id must begin with 'DIFF_', got: " .. id)
	validateDifficulty(level, true)
	assert(
		level <= #DifficultyLevels,
		"Level being added must form a contiguous range with existing difficulties"
	)
	assert(type(tipTitle) == "string")
	assert(type(tipText) == "string")

	local index = level + 1

	local newSectorSpawners = {}
	for i, id in ipairs(DifficultyLevels) do
		local lvl = _G[id]

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

	local suffix = GetDifficultyTipSuffix(level)
	Global_Texts["TipTitle_Hangar" .. suffix] = tipTitle
	Global_Texts["TipText_Hangar" .. suffix] = tipText

	-- Default to using the same spawner logic as baseline difficulty level
	SectorSpawners[level] = SectorSpawners[GetBaselineDifficulty(level)]
end

function GetDifficulty()
	if Game and GAME and GAME.CustomDifficulty then
		return GAME.CustomDifficulty
	else
		local customDiff = modApi:readModData("CustomDifficulty")
		if customDiff then
			return customDiff
		end
	end

	return oldGetDifficulty()
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
			Global_Texts["TipTitle_Hangar"..baseSuffix] = tempTipTitle
		end
		if tempTipText then
			Global_Texts["TipText_Hangar"..baseSuffix] = tempTipText
		end
		if tempToggle then
			Global_Texts["Toggle_"..baseSuffix] = tempToggle
		end

		tempTipTitle = nil
		tempTipText = nil
		tempToggle = nil
	end

	if Game and GAME then
		GAME.CustomDifficulty = level

		local baseSuffix = GetDifficultyTipSuffix(GetBaselineDifficulty(level))
		tempToggle = Global_Texts["Toggle_"..baseSuffix]
		Global_Texts["Toggle_"..baseSuffix] = GetDifficultyFaceName(level)
	else
		-- Hangar, before the game
		modApi:writeModData("CustomDifficulty", level)

		local tipSuffix = GetDifficultyTipSuffix(level)
		local baseSuffix = GetDifficultyTipSuffix(GetBaselineDifficulty(level))

		tempTipTitle = Global_Texts["TipTitle_Hangar"..baseSuffix]
		tempTipText = Global_Texts["TipText_Hangar"..baseSuffix]
		tempToggle = Global_Texts["Toggle_"..baseSuffix]

		Global_Texts["TipTitle_Hangar"..baseSuffix] = Global_Texts["TipTitle_Hangar"..tipSuffix]
		Global_Texts["TipText_Hangar"..baseSuffix] = Global_Texts["TipText_Hangar"..tipSuffix]
		Global_Texts["Toggle_"..baseSuffix] = GetDifficultyFaceName(level)

		if not IsVanillaDifficultyLevel(level) then
			Global_Texts["TipText_Hangar"..baseSuffix] =
				Global_Texts["TipText_Hangar"..baseSuffix] .. "\n\n" ..
				"Note: this is a modded difficulty level. It won't change "..
				"anything without mods providing content for this difficulty."
		end
	end
end

AddDifficultyLevel(
	"DIFF_VERY_HARD",
	#DifficultyLevels, -- adds as a new highest difficulty
	"Very Hard Mode",
	"Intended for veteran Commanders looking for a challenge."
)
AddDifficultyLevel(
	"DIFF_IMPOSSIBLE",
	#DifficultyLevels, -- adds as a new highest difficulty
	"Impossible Mode",
	"A punishing difficulty allowing no mistakes."
)

-- /////////////////////////////////////////////////////////////////////////////////////
-- Tweak existing code to work with custom difficulty levels
-- Replacing instances of GetDifficulty() with GetBaselineDifficulty()

function Mission_Final:StartMission()
	self:GetSpawner():SetSpawnIsland(5)
	local pylons = extract_table(Board:GetZone("pylons"))
	for i,v in ipairs(pylons) do
		Board:BlockSpawn(v,BLOCKED_PERM)
	end
	
	if GetBaselineDifficulty() == DIFF_HARD then
		Board:SpawnPawn(random_element(self.BossList))
	end
end

function getEnvironmentChance(sectorType, tileType)
	--numbers are just a raw percentage chance
	--example: TERRAIN_FOREST = 10 means 10% chance any plain tile will become Forest
	if sectorType == "lava" or sectorType == "volcano" then
		return 0
	end
	
	if tileType == TERRAIN_ACID then
		if sectorType == "acid" then
			return random_element({0,0,10,20})
		else
			return 0
		end
	end
	
	-- "normal" mode uses the same numbers as "hard"
	
	local data = { 	
		grass = { 
			--easy 
			{[TERRAIN_FOREST] = 10, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 0, },
			--hard
			{[TERRAIN_FOREST] = 16, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 0, },
		},
		sand = {
			--easy
			{ [TERRAIN_FOREST] = 0, [TERRAIN_SAND] = 10, [TERRAIN_ICE] = 0, },
			--hard
			{ [TERRAIN_FOREST] = 0, [TERRAIN_SAND] = 16, [TERRAIN_ICE] = 0, },
		},
		snow = {
			--easy
			{ [TERRAIN_FOREST] = 10, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 75,  },
			--hard
			{ [TERRAIN_FOREST] = 10, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 75,  },
		},
		acid = {
			--easy
			{ [TERRAIN_FOREST] = 0, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 0,},
			--hard
			{ [TERRAIN_FOREST] = 0, [TERRAIN_SAND] = 0, [TERRAIN_ICE] = 0,   },
		}
	}

	--translate easy => 1, normal or hard => 2
	local difficulty = (GetBaselineDifficulty() == DIFF_EASY) and 1 or 2
	
	--haha this is ugly
	if data[sectorType] ~= nil and data[sectorType][difficulty] ~= nil and data[sectorType][difficulty][tileType] ~= nil then
		return data[sectorType][difficulty][tileType]
	else
		LOG("Failed environment chance: terrain = "..sectorType..", tile = "..tileType)
		return 0
	end
end

function Mission_SpiderBoss:SpawnSpiderlings()
	if self:IsBossDead() then
		return
	end
	
	if Board:GetPawn(self.BossID):IsFrozen() then
		return
	end
	
	if self.EggCount == -1 or GetBaselineDifficulty() == DIFF_EASY then
		self.EggCount = 2
	else
		self.EggCount = self.EggCount == 2 and 3 or 2
	end
	
	local proj_info = { image = "effects/shotup_spider.png", launch = "/enemy/spider_boss_1/attack_egg_launch", impact = "/enemy/spider_boss_1/attack_egg_land" }
	return self:FlyingSpawns(Board:GetPawnSpace(self.BossID),self.EggCount,"SpiderlingEgg1",proj_info)
end

function Mission:GetKillBonus()
	if GetBaselineDifficulty() == DIFF_EASY then
		return 5
	else
		return 7
	end
end

function Mission:GetStartingPawns()
	local spawnCount = self.SpawnStart
	
	if GetBaselineDifficulty() == DIFF_EASY and self.SpawnStart_Easy ~= -1 then
		spawnCount = self.SpawnStart_Easy
	end

	local mod = self.GlobalSpawnMod + self.SpawnStartMod
	local count = 0
	if type(spawnCount) == "table" then
		local sector = math.max(1,math.min(GetSector(),#spawnCount))
		count = spawnCount[sector]
	else
		count = spawnCount
	end
	
	local new_count = count + mod
			
	return math.max(0,new_count)
end

function Mission:GetSpawnsPerTurn()
	local spawnCount = copy_table(self.SpawnsPerTurn)
	
	if GetBaselineDifficulty() == DIFF_EASY and self.SpawnsPerTurn_Easy ~= -1 then
		spawnCount = copy_table(self.SpawnsPerTurn_Easy)
    end
	
	if type(spawnCount) ~= "table" then
		spawnCount = {spawnCount, spawnCount}
	end
	
	local mod = self.GlobalSpawnMod + self.SpawnMod
	
	while mod ~= 0 do
		local curr = getMinIndex(spawnCount)
		if subsign(mod) < 0 then
			curr = getMaxIndex(spawnCount)
		end
		
		spawnCount[curr] = math.max(1,spawnCount[curr] + subsign(mod))
		
		mod = mod - subsign(mod)
	end
	
	local spawns = " {"
	for i = 1, #spawnCount do
		spawns = spawns..spawnCount[i]..","
	end
	spawns = spawns.."}"
	--LOG("Modified spawns per turn: "..spawns)
	
	return spawnCount
end

function Mission:GetMaxEnemy()
	if GetBaselineDifficulty() == DIFF_EASY and self.MaxEnemy_Easy ~= -1 then
		return self.MaxEnemy_Easy
	else
		return self.MaxEnemy
	end
end

function Mission:GetSpawnCount()
	if not self.InfiniteSpawn then return 0 end
	
	if self:IsFinalTurn() then return 0 end
	
	--LOG("Turn counter: "..Game:GetTurnCount())
	
	local spawnCount = self:GetSpawnsPerTurn()

--	LOG("Current index: "..(Game:GetTurnCount() % #spawnCount) + 1)
	spawnCount = spawnCount[(Game:GetTurnCount() % #spawnCount) + 1]
	
	local enemies = Board:GetPawnCount(TEAM_ENEMY_MAJOR)
	local all_enemies = Board:GetPawnCount(TEAM_ENEMY)
	
--	LOG("All enemy count = "..all_enemies)
--	LOG("Enemy count = "..enemies)
	--LOG("Enemy max = "..self:GetMaxEnemy())
	--LOG("Spawn goal = "..spawnCount)
	
	if enemies <= 2 and all_enemies <= 3 and spawnCount < 3 and GetBaselineDifficulty() ~= DIFF_EASY then
		LOG("2 or less enemies present. Increasing spawn count")
		spawnCount = spawnCount + 1
	end
	
	spawnCount = math.min(math.max(0,self:GetMaxEnemy() - enemies), spawnCount)
	LOG("Final spawn = "..spawnCount)
	
	return spawnCount
end

-- /////////////////////////////////////////////////////////////////////////////////////

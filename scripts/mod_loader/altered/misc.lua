
local oldSaveTable = save_table
function save_table(target)
	local sStart = target.OnSerializationStart
	local sEnd = target.OnSerializationEnd
	local temp = {}

	if sStart then
		sStart(target, temp)
	end

	target.OnSerializationStart = nil
	target.OnSerializationEnd = nil

	local result = oldSaveTable(target)

	if sEnd then
		sEnd(target, temp)
	end

	target.OnSerializationStart = sStart
	target.OnSerializationEnd = sEnd

	return result
end

local oldTriggerVoice = TriggerVoiceEvent
function TriggerVoiceEvent(event, custom_odds)
	local suppress = false

	for i, hook in ipairs(modApi.voiceEventHooks) do
		suppress = suppress or hook(event, custom_odds, suppress)
	end

	if not suppress then
		oldTriggerVoice(event, custom_odds)
	end
end

local oldCreateIncidents = createIncidents
function createIncidents(corporation, island)
	modApi:firePreIslandSelectionHooks(corporation, island)

	oldCreateIncidents(corporation, island)

	modApi:firePostIslandSelectionHooks(corporation, island)
end

-- ///////////////////////////////////////////////////////////////////

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

			modApi:fireMissionNextPhaseCreatedHooks(prevMission, nextMission)
		end
	end
end

local function updateCurrentMission()
	local region = GetCurrentRegion()
	
	if region then
		modApi.current_mission = GAME:GetMission(region.mission)
	end
end

local oldStartNewGame = startNewGame
function startNewGame()
	Settings = modApi:loadSettings()
	
	GameData = nil
	RegionData = nil
	SquadData = nil

	local modOptions = mod_loader:getCurrentModContent()
	local savedOrder = mod_loader:getCurrentModOrder()

	modApi:firePreStartGameHooks()

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
		RestoreGameVariables(Settings)
		-- Execute hook in the deferred callback, since we want
		-- postStartGameHook to have access to the savegame data
		modApi:firePostStartGameHooks()
	end)
end

local oldLoadGame = LoadGame
function LoadGame()
	Settings = modApi:loadSettings()

	GAME.modOptions = GAME.modOptions or mod_loader:getModConfig()
	GAME.modLoadOrder = GAME.modLoadOrder or mod_loader:getSavedModOrder()

	mod_loader:loadModContent(GAME.modOptions, GAME.modLoadOrder)

	if GAME.squadTitles then
		for k, name in pairs(GAME.squadTitles) do
			modApi:setText(k, name)
		end
	end

	modApi:firePreLoadGameHooks()

	GAME.CreateNextPhase = nil

	oldLoadGame()

	RestoreGameVariables(Settings)
	overrideNextPhase()
	updateCurrentMission()

	if GAME.CustomDifficulty then
		SetDifficulty(GAME.CustomDifficulty)
	end

	modApi:firePostLoadGameHooks()
	
	modApi:runLater(function(mission)
		mission.Board = Board
	end)
end

local oldSaveGame = SaveGame
function SaveGame()
	modApi:fireSaveGameHooks()

	if Game and GameData then
		-- Reload the save, since sometimes the savefile
		-- has more recent data than the global variables (?!)
		-- But only do that if we already have those vars
		-- defined, to prevent grabbing stale data.
		modApi:scheduleHook(50, function()
			Settings = modApi:loadSettings()
			RestoreGameVariables(Settings)
			overrideNextPhase()
		end)
	end

	GAME.CreateNextPhase = nil
	return oldSaveGame()
end

local oldCreateEffect = CreateEffect
function CreateEffect(data)
	local effect = oldCreateEffect(data)

	effect.data = data

	return effect
end

Effect.GetLuaString = function(self)
	return string.format("CreateEffect(%s)", save_table(self.data))
end
Effect.GetString = Effect.GetLuaString

function CreatePointList(pointsTable)
	local result = PointList()

	for _, point in ipairs(pointsTable) do
		result:push_back(point)
	end

	return result
end

PointList.GetLuaString = function(self)
	return string.format("CreatePointList(%s)", save_table(extract_table(self)))
end
PointList.GetString = PointList.GetLuaString

function CreateSpaceDamage(self)
	local result = SpaceDamage()
	
	for i, v in pairs(self) do
		result[i] = v
	end
	
	return result
end

local oldGetSkillInfo = GetSkillInfo
function GetSkillInfo(skill)
	local result = oldGetSkillInfo(skill)
	
	if result == nil then
		return PilotSkill()
	end
	
	return result
end

SpaceDamage.GetLuaString = function(self)
    return string.format("CreateSpaceDamage(%s)", save_table(self:ToTable()))
end
SpaceDamage.GetString = SpaceDamage.GetLuaString

GL_Color.GetLuaString = function(self)
	return string.format("GL_Color(%s, %s, %s, %s)", self.r, self.g, self.b, self.a)
end
GL_Color.GetString = GL_Color.GetLuaString

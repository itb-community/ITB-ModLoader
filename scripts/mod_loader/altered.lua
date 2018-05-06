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

function Mission:BaseStart()
	for i, hook in ipairs(modApi.preMissionAvailableHooks) do
		hook(self)
	end
	
	oldBaseStart(self)
	
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

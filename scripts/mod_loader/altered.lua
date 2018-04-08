----Add API functionality that changes existing content here----

oldGetPopulationTexts = GetPopulationTexts
local oldGetStartingSquad = getStartingSquad
local oldBaseNextTurn = Mission.BaseNextTurn
local oldBaseUpdate = Mission.BaseUpdate
local oldBaseStart = Mission.BaseStart
local oldApplyEnvironmentEffect = Mission.ApplyEnvironmentEffect
local oldGetText = GetText
local oldStartNewGame = startNewGame
local oldLoadGame = LoadGame
local oldSaveGame = SaveGame

function getStartingSquad(choice)
	if choice==0 then
		loadPilotsOrder()
		loadSquadSelection()
		arrangePilotsButton.disabled = true
		arrangePilotsButton.tip = "Pilots can only be arranged before the New Game button is pressed, restart the game to be able to arrange pilots."
	end
	
	if choice >= 0 and choice <= 7 then
		local index = modApi.squadIndices[choice + 1]
		
		modApi:overwriteText("TipTitle_"..modApi.squadKeys[choice+1],modApi.squad_text[2 * (index-1) + 1])
		modApi:overwriteText("TipText_"..modApi.squadKeys[choice+1],modApi.squad_text[2 * (index-1) + 2])
		
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
	oldBaseUpdate(self)

	if not GAME.modApi_MissionStarted then
		GAME.modApi_MissionStarted = true
		for i, hook in ipairs(modApi.missionStartHooks) do
			hook(self)
		end	
	end
	
	for i, hook in ipairs(modApi.missionUpdateHooks) do
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

	LOG("Mission End")
	GAME.modApi_MissionStarted = false
end

function Mission:BaseStart()
	for i, hook in ipairs(modApi.preMissionAvailableHooks) do
		hook(self)
	end
	
	oldBaseStart(self)
	
	for i, hook in ipairs(modApi.missionAvailableHooks) do
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

function startNewGame()
	local modOptions = mod_loader:getCurrentModContent()
	local savedOrder = mod_loader:getCurrentModOrder()

	for i, hook in ipairs(modApi.preStartGameHooks) do
		hook()
	end

	oldStartNewGame()
	
	GAME.modOptions = modOptions
	GAME.modLoadOrder = savedOrder
	GAME.squadTitles = {}
	
	for i, key in ipairs(modApi.squadKeys) do
		GAME.squadTitles["TipTitle_"..key] = GetText("TipTitle_"..key)
	end

	for i, hook in ipairs(modApi.postStartGameHooks) do
		hook()
	end
end

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

function LoadGame()
	GAME.modOptions = GAME.modOptions or mod_loader:getModConfig()
	GAME.modLoadOrder = GAME.modLoadOrder or mod_loader:getSavedModOrder()

	mod_loader:loadModContent(GAME.modOptions,GAME.modLoadOrder)
	
	if GAME.squadTitles then
		for k, name in pairs(GAME.squadTitles) do
			modApi:overwriteText(k,name)
		end
	end

	for i, hook in ipairs(modApi.preLoadGameHooks) do
		hook()
	end

	oldLoadGame()

	for i, hook in ipairs(modApi.postLoadGameHooks) do
		hook()
	end
end

function SaveGame()
	for i, hook in ipairs(modApi.saveGameHooks) do
		hook()
	end

	return oldSaveGame()
end

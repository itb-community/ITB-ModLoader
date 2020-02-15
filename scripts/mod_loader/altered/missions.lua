
-- this file contains modifications to original functions
-- as well as additional useful Mission functions.

local function isSerializable(v)
	local t = type(v)
	
	if t == "table" then
		return true
	elseif t == "userdata" then
		if v.GetLuaString ~= nil then
			return true
		end
	elseif t ~= "function" then
		return true
	end
	
	return false
end

function Mission:OnSerializationStart(t)
	for i, v in pairs(self) do
		if i == "Board" or not isSerializable(v) then
			t[i] = v
		end
	end
	
	for i, _ in pairs(t) do
		self[i] = nil
	end
end

function Mission:OnSerializationEnd(t)
	for i, v in pairs(t) do
		self[i] = v
	end
end

function Mission:UpdateQueuedSpawns()
	local removed = {}

	for i = #self.QueuedSpawns, 1, -1 do
		local spawn = self.QueuedSpawns[i]

		if not Board:IsSpawning(spawn.location) then
			table.remove(self.QueuedSpawns, i)
			table.insert(removed, spawn)
		end
	end

	for i = #removed, 1, -1 do
		local spawn = removed[i]

		modApi:fireVekSpawnRemovedHooks(self, spawn)
	end
end

function Mission:SetupDifficulty()
	-- Can be used to setup the difficulty of this mission
	-- with regard to value returned by GetDifficulty()
end

function Mission:BaseStart()
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
end

function Mission:MissionEnd()
	local ret = SkillEffect()
	local enemy_count = Board:GetEnemyCount()
	
	if enemy_count == 0 then
		ret:AddVoice("MissionEnd_Dead", -1)
	elseif self.RetreatEndingMessage then
		ret:AddVoice("MissionEnd_Retreat", -1)
	end
	
	if self:GetDamage() == 0 then
		ret:AddScript("Board:StartPopEvent(\"Closing_Perfect\")")
	elseif self:GetDamage() > 4 then
		ret:AddScript("Board:StartPopEvent(\"Closing_Bad\")")
	elseif enemy_count > 0 then
		ret:AddScript("Board:StartPopEvent(\"Closing\")")
	else
		ret:AddScript("Board:StartPopEvent(\"Closing_Dead\")")
	end
	
	local effect = SpaceDamage()
	effect.bEvacuate = true
	effect.fDelay = 0.5

	modApi:firePreprocessVekRetreatHooks(self, ret)
	
	local retreated = 0
	local board_size = Board:GetSize()
	for x = 0, board_size.x - 1 do
		for y = 0, board_size.y - 1  do
			local p = Point(x, y)
			if Board:IsPawnTeam(p,TEAM_ENEMY) then
				modApi:fireProcessVekRetreatHooks(self, ret, Board:GetPawn(p))

				effect.loc = p
				ret:AddDamage(effect)
				retreated = retreated + 1
			end
		end
	end

	modApi:firePostprocessVekRetreatHooks(self, ret)
	
	ret:AddDelay(math.max(0,4 - retreated * 0.5))
		
	Board:AddEffect(ret)
end

function BuildIsBoardBusyPredicate(board)
	return function()
		return not Game or not GAME or (board and not board:IsBusy())
	end
end

-- Why have this function been changed to always return true?
--function Mission:IsEnvironmentEffect()
--	return true
--end

-- MissionEnd is not actually called when exiting test mech scenario;
-- we call it manually when we detect the player leaving the test mech scenario.
--[[function Mission_Test:MissionEnd()
	-- DON'T call the default MissionEnd
	-- Mission.MissionEnd(self)

	modApi:fireTestMechExitedHooks(self)
end]]

Mission_Test = CreateMission("Mission")

function Mission_Test:MissionEnd()
	-- DON'T call the default MissionEnd
	-- Mission.MissionEnd(self)

	modApi:fireTestMechExitedHooks(self)
end

sdlext.addGameExitedHook(function()
	modApi.current_mission = nil
end)

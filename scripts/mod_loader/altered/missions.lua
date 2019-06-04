
function Mission:OnSerializationStart(t)
	t.MissionEndImpl = self.MissionEndImpl
	t.MissionEnd = self.MissionEnd
	t.Board = self.Board

	self.MissionEndImpl = nil
	self.MissionEnd = nil
	self.Board = nil
end

function Mission:OnSerializationEnd(t)
	self.MissionEndImpl = t.MissionEndImpl
	self.MissionEnd = t.MissionEnd
	self.Board = t.Board
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

		for _, hook in ipairs(modApi.vekSpawnRemovedHooks) do
			hook(self, spawn)
		end
	end
end

local oldBaseNextTurn = Mission.BaseNextTurn
function Mission:BaseNextTurn()
	oldBaseNextTurn(self)
	self.Board = Board

	if Game:GetTeamTurn() == TEAM_PLAYER then
		self:UpdateQueuedSpawns()

		for i, el in ipairs(self.QueuedSpawns) do
			el.turns = el.turns + 1
		end
	end

	for i, hook in ipairs(modApi.nextTurnHooks) do
		hook(self)
	end
end

local oldBaseUpdate = Mission.BaseUpdate
function Mission:BaseUpdate()
	modApi:processRunLaterQueue(self)

	oldBaseUpdate(self)

	if Board:GetBusyState() == 6 then
		-- BusyState 6 happens when Vek are burrowing out of the ground
		self:UpdateQueuedSpawns()
	end

	for i, hook in ipairs(modApi.missionUpdateHooks) do
		hook(self)
	end
end

local oldBaseDeployment = Mission.BaseDeployment
function Mission:BaseDeployment()
	oldBaseDeployment(self)
	self.Board = Board

	for i, hook in ipairs(modApi.missionStartHooks) do
		hook(self)
	end	
end

local function overrideMissionEnd(self)
	local mlEnd = Mission.MissionEnd
	local mEnd = self.MissionEnd

	if mEnd and mEnd ~= mlEnd then
		self.MissionEndImpl = mEnd
		self.MissionEnd = mlEnd
	end
end

local oldCreateMission = CreateMission
function CreateMission(mission)
	local mObject = oldCreateMission(mission)
	mObject.Initialized = false

	overrideMissionEnd(mObject)

	return mObject
end

local oldReloadMissions = ReloadMissions
function ReloadMissions(missions)
	oldReloadMissions(missions)

	if missions then
		for i, mission in pairs(GAME.Missions) do
			overrideMissionEnd(mission)
		end
	end
end

function Mission:MissionEndImpl()
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

	for i, hook in ipairs(modApi.preprocessVekRetreatHooks) do
		hook(self, ret)
	end
	
	local retreated = 0
	local board_size = Board:GetSize()
	for x = 0, board_size.x - 1 do
		for y = 0, board_size.y - 1  do
			local p = Point(x, y)
			if Board:IsPawnTeam(p,TEAM_ENEMY) then
				for i, hook in ipairs(modApi.processVekRetreatHooks) do
					hook(self, ret, Board:GetPawn(p))
				end

				effect.loc = p
				ret:AddDamage(effect)
				retreated = retreated + 1
			end
		end
	end

	for i, hook in ipairs(modApi.postprocessVekRetreatHooks) do
		hook(self, ret)
	end
	
	ret:AddDelay(math.max(0,4 - retreated * 0.5))
		
	Board:AddEffect(ret)
end

function Mission:MissionEnd()
	local fx = SkillEffect()

	self:MissionEndImpl()

	for i, hook in ipairs(modApi.missionEndHooks) do
		hook(self, fx)
	end
	modApi.runLaterQueue = {}

	Board:AddEffect(fx)
	self.Board = nil
end

function Mission:SetupDifficulty()
	-- Can be used to setup the difficulty of this mission
	-- with regard to value returned by GetDifficulty()
end

local oldBaseStart = Mission.BaseStart
function Mission:BaseStart(suppressHooks)
	suppressHooks = suppressHooks or false

	if not suppressHooks then
		for i, hook in ipairs(modApi.preMissionAvailableHooks) do
			hook(self)
		end
	end

	self.Board = Board
	self.QueuedSpawns = {}

	-- begin oldBaseStart
	-- Copy the code rather than calling the original function, since
	-- we want to insert a new SetupDifficulty() function before
	-- environment start.
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

	-- Clear QueuedSpawns, since the Vek burrow out immediately when entering the mission
	self.QueuedSpawns = {}

	if not suppressHooks then
		for i, hook in ipairs(modApi.postMissionAvailableHooks) do
			hook(self)
		end
	end

	self.Initialized = true
end

local modLoaderHooksFired = false
local oldApplyEnvironmentEffect = Mission.ApplyEnvironmentEffect
function Mission:ApplyEnvironmentEffect()
	if not modLoaderHooksFired then
		for _, hook in ipairs(modApi.preEnvironmentHooks) do
			hook(self)
		end
	end
	
	-- ApplyEnvironmentEffect() is supposed to return true once
	-- it's done applying its effects, but the game's own environments
	-- don't follow this rule...
	local isDone = false
	if self.LiveEnvironment:IsEffect() then
		isDone = oldApplyEnvironmentEffect(self)
	end
	
	if not modLoaderHooksFired then
		-- Schedule the post hooks to fire once the board is no longer busy
		modApi:conditionalHook(
			function()
				return not Game or not GAME or (Board and not Board:IsBusy())
			end,
			function()
				modLoaderHooksFired = false
				if not Game or not GAME or not Board then
					return
				end
				
				for _, hook in ipairs(modApi.postEnvironmentHooks) do
					hook(self)
				end
			end
		)
		
		modLoaderHooksFired = true
	end
	
	return isDone
end

function Mission:IsEnvironmentEffect()
	return true
end

-- ////////////////////////////////////////////////////////////////////

function Mission_Test:BaseStart()
	Mission.BaseStart(self, true)

	for i, hook in ipairs(modApi.testMechEnteredHooks) do
		hook(self)
	end
end

-- MissionEnd is not actually called when exiting test mech scenario;
-- we call it manually when we detect the player leaving the test mech scenario.
function Mission_Test:MissionEnd()
	-- DON'T call the default MissionEnd
	-- Mission.MissionEnd(self)

	for i, hook in ipairs(modApi.testMechExitedHooks) do
		hook(self)
	end
end

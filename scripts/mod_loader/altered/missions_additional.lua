
-- All of this code is extracted from altered/missions.lua
-- With an events based system different parts could be moved around
-- to where their respective subject matter is coded.

--[[
	pros:
		A specific subject matter can have all of
		it's logic grouped together in the same file.
		
	cons:
		You cannot look at any given function and know which
		function are being called and which variables are being set.
]]

modApi:addMissionCreatedEvent(function(self)
	self.Initialized = false
end)

modApi:addMissionBaseNextTurnEvent(function(self)
	self.Board = Board

	if Game:GetTeamTurn() == TEAM_PLAYER then
		self:UpdateQueuedSpawns()

		for i, el in ipairs(self.QueuedSpawns) do
			el.turns = el.turns + 1
		end
	end

	modApi:fireNextTurnHooks(self)
end)

modApi:addPreMissionBaseUpdateEvent(function(self)
	modApi.current_mission = self
	modApi:processRunLaterQueue(self)
end)

modApi:addPostMissionBaseUpdateEvent(function(self)
	if Board:GetBusyState() == 6 then
		-- BusyState 6 happens when Vek are burrowing out of the ground
		self:UpdateQueuedSpawns()
	end

	modApi:fireMissionUpdateHooks(self)
end)

modApi:addPreMissionBaseDeploymentEvent(function(self)
	modApi.current_mission = self
end)

modApi:addPostMissionBaseDeploymentEvent(function(self)
	self.Board = Board

	modApi:fireMissionStartHooks(self)
end)

modApi:addMissionMissionEndEvent(function(self)
	local fx = SkillEffect()

	modApi:fireMissionEndHooks(self, fx)
	fx:AddScript([[
		modApi.runLaterQueue = {}
		
		modApi:conditionalHook(
			BuildIsBoardBusyPredicate(modApi.current_mission.Board),
			function()
				-- BoardBusyPredicate defined above will yield true once we exit to main menu,
				-- but when that happens, current_mission is reset to nil.
				if modApi.current_mission then
					modApi.current_mission.Board = nil
					modApi.current_mission = nil
				end
			end
		)
	]])
	Board:AddEffect(fx)
end)

modApi:addPreMissionBaseStartEvent(function(self)
	if self ~= Mission_Test then
		modApi:firePreMissionAvailableHooks(self)
	end

	self.Board = Board
	self.QueuedSpawns = {}
end)

modApi:addPostMissionBaseStartEvent(function(self)
	-- Clear QueuedSpawns, since the Vek burrow out immediately when entering the mission
	self.QueuedSpawns = {}

	if self ~= Mission_Test then
		modApi:firePostMissionAvailableHooks(self)
	else
		modApi:fireTestMechEnteredHooks(self)
	end

	self.Initialized = true
end)

local modLoaderHooksFired = false
modApi:addPreMissionApplyEnvironmentEffectEvent(function(self)
	if not modLoaderHooksFired then
		modApi:firePreEnvironmentHooks(self)
	end
end)

modApi:addPostMissionApplyEnvironmentEffectEvent(function(self)
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
				
				modApi:firePostEnvironmentHooks(self)
			end
		)
		
		modLoaderHooksFired = true
	end
end)

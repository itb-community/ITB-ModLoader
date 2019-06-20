
-- //////////////////////////////////////////////////////////////////////////////
-- Simple hooks

function modApi:addPreMissionAvailableHook(fn)
	assert(type(fn) == "function")
	table.insert(self.preMissionAvailableHooks,fn)
end

function modApi:addPostMissionAvailableHook(fn)
	assert(type(fn) == "function")
	table.insert(self.postMissionAvailableHooks,fn)
end

function modApi:addMissionAvailableHook(fn)
	self:addPostMissionAvailableHook(fn)
end

function modApi:addPreEnvironmentHook(fn)
	assert(type(fn) == "function")
	table.insert(self.preEnvironmentHooks,fn)
end

function modApi:addPostEnvironmentHook(fn)
	assert(type(fn) == "function")
	table.insert(self.postEnvironmentHooks,fn)
end

function modApi:addNextTurnHook(fn)
	assert(type(fn) == "function")
	table.insert(self.nextTurnHooks,fn)
end

function modApi:addVoiceEventHook(fn)
	assert(type(fn) == "function")
	table.insert(self.voiceEventHooks,fn)
end

function modApi:addPreIslandSelectionHook(fn)
	assert(type(fn) == "function")
	table.insert(self.preIslandSelectionHooks,fn)
end

function modApi:addPostIslandSelectionHook(fn)
	assert(type(fn) == "function")
	table.insert(self.postIslandSelectionHooks,fn)
end

function modApi:addMissionUpdateHook(fn)
	assert(type(fn) == "function")
	table.insert(self.missionUpdateHooks,fn)
end

function modApi:addMissionStartHook(fn)
	assert(type(fn) == "function")
	table.insert(self.missionStartHooks,fn)
end

function modApi:addMissionEndHook(fn)
	assert(type(fn) == "function")
	table.insert(self.missionEndHooks,fn)
end

function modApi:addMissionNextPhaseCreatedHook(fn)
	assert(type(fn) == "function")
	table.insert(self.missionNextPhaseCreatedHooks,fn)
end

function modApi:addPreStartGameHook(fn)
	assert(type(fn) == "function")
	table.insert(self.preStartGameHooks,fn)
end

function modApi:addPostStartGameHook(fn)
	assert(type(fn) == "function")
	table.insert(self.postStartGameHooks,fn)
end

function modApi:addPreLoadGameHook(fn)
	assert(type(fn) == "function")
	table.insert(self.preLoadGameHooks,fn)
end

function modApi:addPostLoadGameHook(fn)
	assert(type(fn) == "function")
	table.insert(self.postLoadGameHooks,fn)
end

function modApi:addSaveGameHook(fn)
	assert(type(fn) == "function")
	table.insert(self.saveGameHooks,fn)
end

function modApi:addVekSpawnAddedHook(fn)
	assert(type(fn) == "function")
	table.insert(self.vekSpawnAddedHooks,fn)
end

function modApi:addVekSpawnRemovedHook(fn)
	assert(type(fn) == "function")
	table.insert(self.vekSpawnRemovedHooks,fn)
end

function modApi:addPreprocessVekRetreatHook(fn)
	assert(type(fn) == "function")
	table.insert(self.preprocessVekRetreatHooks,fn)
end

function modApi:addProcessVekRetreatHook(fn)
	assert(type(fn) == "function")
	table.insert(self.processVekRetreatHooks,fn)
end

function modApi:addPostprocessVekRetreatHook(fn)
	assert(type(fn) == "function")
	table.insert(self.postprocessVekRetreatHooks,fn)
end

function modApi:addModsLoadedHook(fn)
	assert(type(fn) == "function")
	table.insert(self.modsLoadedHooks,fn)
end

function modApi:addModsInitializedHook(fn)
	assert(type(fn) == "function")
	table.insert(self.modsInitializedHooks,fn)
end

function modApi:addTestMechEnteredHook(fn)
	assert(type(fn) == "function")
	table.insert(self.testMechEnteredHooks,fn)
end

function modApi:addTestMechExitedHook(fn)
	assert(type(fn) == "function")
	table.insert(self.testMechExitedHooks,fn)
end

function modApi:addSaveDataUpdatedHook(fn)
	assert(type(fn) == "function")
	table.insert(self.saveDataUpdatedHooks,fn)
end

-- //////////////////////////////////////////////////////////////////////////////

--[[
	Executes the function on the game's next update step. Only works during missions.
	
	Calling this while during game loop (either in a function called from missionUpdate,
	or as a result of previous runLater) will correctly schedule the function to be
	invoked during the next update step (not the current one).
--]]
function modApi:runLater(fn)
	assert(type(fn) == "function")

	if not self.runLaterQueue then
		self.runLaterQueue = {}
	end

	table.insert(self.runLaterQueue, fn)
end

function modApi:processRunLaterQueue(mission)
	if self.runLaterQueue then
		local q = self.runLaterQueue
		local n = #q
		for i = 1, n do
			q[i](mission)
			q[i] = nil
		end

		-- compact the table, if processed hooks also scheduled
		-- their own runLater functions (but we will process those
		-- on the next update step)
		local i = n + 1
		local j = 0
		while q[i] do
			j = j + 1
			q[j] = q[i]
			q[i] = nil
			i = i + 1
		end
	end
end

--[[
	Registers a conditional hook which will be
	executed once the condition function associated
	with it returns true.
--]]
function modApi:conditionalHook(conditionFn, fn, remove)
	assert(type(conditionFn) == "function")
	assert(type(fn) == "function")
	remove = remove == nil and true or remove
	assert(type(remove) == "boolean")

	table.insert(self.conditionalHooks, {
		condition = conditionFn,
		hook = fn,
		remove = remove
	})
end

function modApi:evaluateConditionalHooks()
	for i, tbl in ipairs(self.conditionalHooks) do
		if tbl.condition() then
			if tbl.remove then
				table.remove(self.conditionalHooks, i)
			end
			tbl.hook()
		end
	end
end

--[[
	Schedules an argumentless function to be executed
	in msTime milliseconds.
--]]
function modApi:scheduleHook(msTime, fn)
	assert(type(msTime) == "number")
	assert(type(fn) == "function")

	table.insert(self.scheduledHooks, {
		triggerTime = self:elapsedTime() + msTime,
		hook = fn
	})

	-- sort the table according to triggerTime field, so hooks
	-- that are scheduled sooner are executed first, even if
	-- both hooks are processed during the same update step.
	table.sort(self.scheduledHooks, self.compareScheduledHooks)
end

function modApi:updateScheduledHooks()
	local t = self:elapsedTime()

	for i, tbl in ipairs(self.scheduledHooks) do
		if tbl.triggerTime <= t then
			table.remove(self.scheduledHooks, i)
			tbl.hook()
		end
	end
end

sdlext.addGameExitedHook(function()
	modApi.runLaterQueue = {}
end)

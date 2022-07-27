
-- EVENTS
---------

modApi.events.onFrameDrawStart:subscribe(function()
	if modApi.current_mission ~= nil and Board == nil then
		modApi.events.onMissionDismissed:dispatch(modApi.current_mission)
	end
end)


-- GetCurrentMission
--------------------

function modApi:setMission(mission)
	local oldMission = self.current_mission

	if self.current_mission ~= mission then
		self.current_mission = mission

		modApi.events.onMissionChanged:dispatch(mission, oldMission)
	end
end

modApi.events.onMissionStart:subscribe(function(mission)
	modApi:setMission(mission)
end)

modApi.events.onMissionNextPhaseCreated:subscribe(function(prevMission, nextMission)
	modApi:setMission(nextMission)
end)

modApi.events.onMissionEnd:subscribe(function(mission)
	-- When entering a saved game from the main menu,
	-- this is the first function being called for the current mission
	modApi:setMission(mission)
end)

modApi.events.onMissionUpdate:subscribe(function(mission)
	if currentMission ~= mission then
		modApi:setMission(mission)
	end
end)

modApi.events.onMissionDismissed:subscribe(function(mission)
	modApi:setMission(nil)
end)

modApi.events.onGameExited:subscribe(function()
	modApi:setMission(nil)
end)

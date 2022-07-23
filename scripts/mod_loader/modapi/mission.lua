
-- EVENTS
---------

modApi.events.onFrameDrawStart:subscribe(function()
	if modApi.current_mission ~= nil and Board == nil then
		modApi.events.onMissionDismissed:dispatch(modApi.current_mission)
	end
end)


-- TESTS
--------

-- Logout when mission changes.
modApi.events.onMissionChanged:subscribe(function(currentMission, oldCurrentMission)
	local oldId = oldCurrentMission and oldCurrentMission.ID or nil
	local newId = currentMission and currentMission.ID or nil

	LOGF("-> Current mission changed from %s w/table [%s] to %s w/table [%s]",
		tostring(oldId),
		tostring(oldCurrentMission),
		tostring(newId),
		tostring(currentMission)
	)
end)

modApi.events.onMissionDismissed:subscribe(function(mission)
	local id = mission and mission.ID or nil

	LOGF("-> Current mission %s w/table [%s] was dismissed", tostring(id), tostring(mission))
end)

-- Test if GetCurrentMission() is equal to 'self' in every Mission method.
for i, fn in pairs(Mission) do
	if type(fn) == 'function' then
		local oldfn = fn
		fn = function(mission, ...)
			if GetCurrentMission() ~= mission then
				LOGF("-> Mission:%s: GetCurrentMission() (%s) differs from 'self' (%s)",
					tostring(i),
					tostring(GetCurrentMission()),
					tostring(mission)
				)
			end

			return oldfn(mission, ...)
		end
	end
end


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

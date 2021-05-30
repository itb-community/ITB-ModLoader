
function modApi:setMission(mission)
	local oldMission = self.current_mission

	if self.current_mission ~= mission then
		self.current_mission = mission

		modApi.events.onMissionChanged:dispatch(mission, oldMission)
	end
end

local currentRegionData
modApi.events.onSaveDataUpdated:subscribe(function()
	local oldRegionData = currentRegionData

	if currentRegionData ~= RegionData then
		currentRegionData = RegionData

		local region = GetCurrentRegion(RegionData)
		local mission = nil

		if region then
			mission = GAME:GetMission(region.mission)
		end

		if not IsTestMechScenario() then
			modApi:setMission(mission)
		end
	end
end)

modApi.events.onMissionNextPhaseCreated:subscribe(function(prevMission, nextMission)
	modApi:setMission(nextMission)
end)

modApi.events.onGameExited:subscribe(function()
	modApi:setMission(nil)
end)

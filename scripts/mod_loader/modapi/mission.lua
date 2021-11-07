
function modApi:setMission(mission)
	local oldMission = self.current_mission

	if self.current_mission ~= mission then
		self.current_mission = mission

		modApi.events.onMissionChanged:dispatch(mission, oldMission)
	end
end

local currentRegionData
modApi.events.onSaveDataUpdated:subscribe(function()
	if currentRegionData ~= RegionData then
		currentRegionData = RegionData

		local region = GetCurrentRegion(RegionData)
		local mission = nil

		if region then
			mission = GAME:GetMission(region.mission)
		end

		if not region and modApi.current_mission and not modApi.current_mission.Deployed then
			-- When updating the save file in MissionStart event listener (ie, from
			-- Mission:BaseDeployment context), RegionData doesn't have `iBattleRegion` entry yet,
			-- so we have no way of finding the current region/mission, and end up setting current
			-- mission to nil.
			-- To fix this, keep track of missions that are past the deployment phase with `Deployed`
			-- flag, and check if the mission we have saved currently is already past that phase.
			-- This way we know that we've been called from within BaseDeployment context, and don't
			-- execute this block eg. when leaving a mission, which would be incorrect behaviour.
			mission = modApi.current_mission
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

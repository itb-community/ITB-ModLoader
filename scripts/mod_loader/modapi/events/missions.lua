
modApi:newEvent("MissionReloaded")
modApi:newEvent("PreMissionReloaded")
modApi:newEvent("PostMissionReloaded")
modApi:newEvent("MissionCreated")
modApi:newEvent("PreMissionCreated")
modApi:newEvent("PostMissionCreated")

local exclusions = {
	"Initialize"
}

-- Create event listeners for every function in Mission class
local missionKeys = {}
for key, fn in pairs(Mission) do
	
	if type(fn) == 'function' then
		
		if not list_contains(exclusions, key) then
			
			local event = "Mission".. key:gsub("^.", string.upper) -- capitalize first letter
			local event_pre = "Pre".. event
			local event_post = "Post".. event
			
			modApi:newEvent(event)
			modApi:newEvent(event_pre)
			modApi:newEvent(event_post)
			
			missionKeys[#missionKeys + 1] = key
		end
	end
end

-- We keep all functions in Mission intact,
-- and add event triggers to mission instances as they are created.
-- This way, events will only trigger once,
-- even if an overriding function calls back it's overridden base function.
modApi:addMissionCreatedEvent(function(mission)
	for _, key in ipairs(missionKeys) do
		modApi:addEventTriggers(mission, key, "Mission".. key)
	end
end)

local oldCreateMission = CreateMission
function CreateMission(mission_base)
	modApi:triggerEvent("PreMissionCreated", mission_base)
	
	local mission = oldCreateMission(mission_base)
	
	modApi:triggerEvent("MissionCreated", mission)
	modApi:triggerEvent("PostMissionCreated", mission)
	
	return mission
end

-- full override so we can add triggers to CreateSpawner before calling it.
function ReloadMissions(missions)
    if missions == nil then
        return
    end
	
	for _, mission in pairs(missions) do
		local baseMission = mission.ID
		modApi:triggerEvent("PreMissionReloaded", baseMission)
		
		mission = _G[baseMission]:new(mission)
		
		for _, key in ipairs(missionKeys) do
			modApi:addEventTriggers(mission, key, "Mission".. key)
		end
		
		mission:CreateSpawner(mission.Spawner)
		mission.LiveEnvironment = _G[mission.Environment]:new(mission.LiveEnvironment)
		
		modApi:triggerEvent("MissionReloaded", mission)
		modApi:triggerEvent("PostMissionReloaded", mission)
	end
end

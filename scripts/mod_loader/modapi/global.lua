
local PilotPersonality = nil
function CreatePilotPersonality(label, name)
	-- PilotPersonality is local to personality.lua
	-- We can't access it directly, so we have to grab it via
	-- the metatable of one of the existing PilotPersonality instances.
	-- 'Artificial' happens to be the most generic one.
	PilotPersonality = PilotPersonality or getmetatable(Personality["Artificial"])
	local t = PilotPersonality:new()

	-- Name of the pilot, leave nil for random name
	t.Name = name
	-- Pilot label, used in debug messages
	t.Label = label or "NULL"

	return t
end

function CreatePilot(data)
	_G[data.Id] = Pilot:new(data)

	-- Make sure we don't create duplicates if the PilotList
	-- already contains entry for this pilot
	if data.Rarity ~= 0 and not list_contains(PilotList, data.Id) then
		PilotList[#PilotList + 1] = data.Id
	end
end

function IsTestMechScenario()
	if not Game then return false end

	local p0 = Game:GetPawn(0)
	local p1 = Game:GetPawn(1)
	local p2 = Game:GetPawn(2)

	-- In test mech scenario, only one of the three
	-- player mechs will not be nil.
	return (    p0 and not p1 and not p2) or
	       (not p0 and     p1 and not p2) or
	       (not p0 and not p1 and     p2)
end

--[[
	Returns a savedata table holding information about the region the player
	is currently in. Returns nil when not in a mission.
--]]
function GetCurrentRegion()
	if RegionData and RegionData.iBattleRegion then
		if RegionData.iBattleRegion == 20 then
			return RegionData["final_region"]
		else
			return RegionData["region"..RegionData.iBattleRegion]
		end
	end

	return nil
end

--[[
	Returns the table instance of the current mission. Returns nil when not in a mission.
--]]
function GetCurrentMission()
	local region = GetCurrentRegion()

	if region then
		return GAME:GetMission(region.mission)
	end

	if IsTestMechScenario() then
		return Mission_Test
	end

	return nil
end

function list_indexof(list, value)
	for k, v in ipairs(list) do
		if value == v then
			return k
		end
	end
	return nil
end

-- Returns true if tables are equal, false otherwise
function compare_tables(tbl1, tbl2)
	local r = true
	for k, v in pairs(tbl1) do
		if type(v) == "table" then
			if not compare_tables(tbl1[k], tbl2[k]) then
				return false
			end
		elseif type(v) == "userdata" then
			-- can't compare userdata, ignore
		else
			if tbl1[k] ~= tbl2[k] then
				return false
			end
		end
	end

	return true
end
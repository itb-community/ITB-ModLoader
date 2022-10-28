
Placeholder_Mech = PunchMech:new{Image = "placeholder_mech"}
Placeholder_Pilot = Pilot:new{}
Placeholder_Weapon = Skill:new{Icon = "weapons/placeholder_weapon.png"}
Placeholder_Enemy = Hornet1:new{Name = "Missing Mod", Image = "placeholder_enemy"}
Placeholder_Personality = CreatePilotPersonality("NULL", "placeholder")

local ProfileDataAffirmed = false

function modApi:getProfileStatistics(profileId)
	local profile = Directory.savedata()
		:directory("profile_"..profileId)
		:file("profile.lua")

	if profile:exists() then
		return self:loadIntoEnv(profile:path()).Profile
	end
end

function modApi:getProfileList()
	local result = {}

	local savedataDir = Directory.savedata()
	for _, profileDir in ipairs(savedataDir:directories()) do
		if profileDir:name():match("^profile_") then
			local profileId = profileDir:name():sub(9,-1)
			local profileStatistics = self:getProfileStatistics(profileId)

			if profileStatistics then
				result[profileId] = profileStatistics
			end
		end
	end

	return result
end

function modApi:affirmProfileData()
	
	if ProfileDataAffirmed then
		return
	end
	
	ProfileDataAffirmed = true
	
	local function affirmPersonality(id)
		if id == "" then
			return
		end
		
		Personality[id] = Personality[id] or Placeholder_Personality
	end
	
	local function affirmUnit(id, placeholder)
		if id == "" then
			return
		end
		
		_G[id] = _G[id] or placeholder:new()
	end
	
	local profile_list = self:getProfileList()
	for profileId, profile in pairs(profile_list) do
		
		local i = 0
		local stat_tracker = profile.stat_tracker
		local score = stat_tracker["current"]
		
		if not score then
			score = stat_tracker["score".. i]
			i = i + 1
		end
		
		while score do
			for _, mech in ipairs(score.mechs) do
				affirmUnit(mech, Placeholder_Mech)
			end
			
			for _, weapon in ipairs(score.weapons) do
				affirmUnit(weapon, Placeholder_Weapon)
			end
			
			local j = 0
			while true do
				local pilot = score["pilot".. j]
				
				if pilot == nil then
					break
				end
				
				affirmUnit(pilot.id, Placeholder_Pilot)
				affirmPersonality(pilot.id, Placeholder_Personality)
				
				j = j + 1
			end
			
			score = stat_tracker["score".. i]
			
			i = i + 1
		end
		
		for _, pilot in ipairs(profile.pilots) do
			affirmUnit(pilot, Placeholder_Pilot)
			affirmPersonality(pilot, Placeholder_Personality)
		end
		
		for pilot, _ in pairs(stat_tracker.pilots) do
			affirmUnit(pilot, Placeholder_Pilot)
			affirmPersonality(pilot, Placeholder_Personality)
		end
		
		for enemy, _ in pairs(stat_tracker.enemies) do
			affirmUnit(enemy, Placeholder_Enemy)
		end
	end
end

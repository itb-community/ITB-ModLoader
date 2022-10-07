
Placeholder_Mech = PunchMech:new{Image = "placeholder_mech"}
Placeholder_Pilot = Pilot:new{}
Placeholder_Weapon = Skill:new{Icon = "weapons/placeholder_weapon.png"}
Placeholder_Enemy = Hornet1:new{Name = "Missing Mod", Image = "placeholder_enemy"}
Placeholder_Personality = CreatePilotPersonality("NULL", "placeholder")

local ProfileDataAffirmed = false

function modApi:getProfileStatistics(profileName)
	local path_savedata = GetSavedataLocation()
	local dir_profile = "profile_"..profileName
	local path_profile = string.format("%s%s/profile.lua", path_savedata, dir_profile)

	if self:fileExists(path_profile) then
		return self:loadIntoEnv(path_profile).Profile
	end
end

function modApi:getProfileList()
	
	local result = {}
	local path_savedata = GetSavedataLocation()
	local directory = io.popen(string.format("dir %q /B /AD", path_savedata))
	
	for dir_profile in directory:lines() do
		if dir_profile:match("^profile_") then
			local profileName = dir_profile:sub(9,-1)
			local profileStatistics = self:getProfileStatistics(profileName)

			if profileStatistics then
				result[profileName] = profileStatistics
			end
		end
	end
	
	directory:close()
	
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


Placeholder_Mech = PunchMech:new{Image = "placeholder_mech"}
Placeholder_Pilot = Pilot:new{}
Placeholder_Weapon = Skill:new{Icon = "weapons/placeholder_weapon.png"}
Placeholder_Enemy = Hornet1:new{Image = "placeholder_enemy"}
Placeholder_Personality = CreatePilotPersonality("NULL", "placeholder")

local ProfileDataAffirmed = false

function modApi:affirmProfileData()
	local profile = modApi:loadProfile()
	
	-- TODO: do for all profiles
	
	if profile == nil then
		return
	end
	
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
		
		_G[id] = _G[id] or placeholder
	end
	
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
	
	for pilot, _ in ipairs(stat_tracker.pilots) do
		affirmUnit(pilot, Placeholder_Pilot)
		affirmPersonality(pilot, Placeholder_Personality)
	end
	
	for enemy, _ in ipairs(stat_tracker.enemies) do
		affirmUnit(enemy, Placeholder_Enemy)
	end
end

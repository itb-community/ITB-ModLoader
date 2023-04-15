-- a pilot must be in PilotList to be unlocked, however we cannot have more than 19 pilots in the list for the UI
-- fix that by using PilotListExtended in game, and the smaller pilot list in the hangar
local hangarPilotList = nil
modApi.events.onGameEntered:subscribe(function()
	-- prevent overwriting the list twice accidently
	if hangarPilotList == nil then
		hangarPilotList = PilotList
		PilotList = PilotListExtended
	end
end)
modApi.events.onGameExited:subscribe(function()
	-- only update if we have an old list
	if hangarPilotList ~= nil then
		PilotList = hangarPilotList
		hangarPilotList = nil
	end
end)

-- returns all weapons
function getWeaponList()
	return modApi:getFullWeaponDeck()
end

-- update the weapon deck when requested
function checkWeaponDeck()
	if #GAME.WeaponDeck == 0 then
		if IsNewEquipment() then
			LOG("Mod Loader: Including advanced weapons!")
			GAME.WeaponDeck = modApi:getWeaponDeck(true)
		else
			LOG("Mod Loader: Using normal weapons!")
			GAME.WeaponDeck = modApi:getWeaponDeck(false)
		end
	end

	if #GAME.PodWeaponDeck == 0 then
		if IsNewEquipment() then
			LOG("Mod Loader: Including advanced weapons!")
			GAME.PodWeaponDeck = modApi:getPodWeaponDeck(true)
		else
			LOG("Mod Loader: Using normal weapons!")
			GAME.PodWeaponDeck = modApi:getPodWeaponDeck(false)
		end
	end
end

-- replace default to use the full list instead of the partial one
function checkPilotDeck()
	if #GAME.PilotDeck == 0 then
		if IsNewEquipment() then
			LOG("Mod Loader: Including advanced pilots!")
			GAME.PilotDeck = modApi:getPilotDeck(true)
		else
			LOG("Mod Loader: Using normal pilots!")
			GAME.PilotDeck = modApi:getPilotDeck(false)
		end
	end
end

-- modloader lets you add recruits to the pilot deck, but they have a 0 rarity
-- however, the user's intention might be to include recruits in the drop table
-- for simplicty, just ignore rarity
function getPilotDrop()
	checkPilotDeck()

	local drop = random_element(GAME.PilotDeck)
	removePilot(drop)

	return drop
end

-- simply redirect to the modApi function
function GetFTLPilots()
	return modApi:getFTLPilots()
end

-- Determines if a skill is available in the shop
function Skill:GetUnlocked()
  if self.Unlocked == nil then
    return true
  end
  return self.Unlocked
end

-- Determines if a pilot is available in time pods, the hangar, and mod UIs
function Pilot:IsEnabled()
  return self.Enabled == nil or self.Enabled
end

-- allow defining a custom rarity for skills
local oldSkillGetRarity = Skill.GetRarity
function Skill:GetRarity()
	if self.CustomRarity ~= nil then
		assert(type(self.CustomRarity) == 'number')
		return math.max(0, math.min(4, self.CustomRarity))
	end
	return oldSkillGetRarity(self)
end

-- add final override after mods have loaded, to ensure the import had time to run
-- note this runs after the hook in drops.lua
modApi.events.onModsFirstLoaded:subscribe(function()
	-- revert to vanilla behavior in case a shop lib overrode it
	function initializeDecks()
		checkWeaponDeck()
		checkPilotDeck()
	end
end)

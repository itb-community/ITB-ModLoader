-- initializeDecks is called before the game entered hook, so we still need this override
local oldInitializeDecks = initializeDecks
function initializeDecks()
	local oldPilotList = PilotList
	PilotList = PilotListExtended
	oldInitializeDecks()
	PilotList = oldPilotList
end

-- a pilot must be in PilotList to be unlocked, however we cannot have more than 13 pilots in the list for the UI
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

-- override get weapon drop to pull from our list during reshuffling
local oldGetWeaponDrop = getWeaponDrop
function getWeaponDrop(...)
	-- catch an empty deck before vanilla does
	if #GAME.WeaponDeck == 0 then
		GAME.WeaponDeck = modApi:getWeaponDeck()
		LOG("Reshuffling Weapon Deck!\n")
	end
	-- deck will never be empty, so call remainder of vanilla logic
	return oldGetWeaponDrop(...)
end

-- Determines if a skill is available in the shop
function Skill:GetUnlocked()
  if self.Unlocked == nil then
    return true
  end
  return self.Unlocked
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
modApi:addModsFirstLoadedHook(function()
	-- override inititlize decks to pull from the mod api list
	local oldInitializeDecks = initializeDecks
	function initializeDecks(...)
		oldInitializeDecks(...)
		GAME.WeaponDeck = modApi:getWeaponDeck()
	end
end)

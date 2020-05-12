modApi.weaponDeck = {}
local DEFAULT_WEAPONS = {}

--- Adds a weapon to the deck
function modApi:addWeaponDrop(id, enabled)
	assert(type(id) == "string", "ID must be a string")
	assert(enabled == nil or type(enabled) == "boolean", "Enabled must be a boolean")

	-- nil enabled means add if missing
	-- set means force enabled value
	if modApi.weaponDeck[id] == nil or enabled ~= nil then
		modApi.weaponDeck[id] = enabled == nil or enabled
	end
end

--- Gets the full list of weapons
function modApi:getWeaponDeck()
	local deck = {}
	for id, enabled in pairs(modApi.weaponDeck) do
		if enabled then
			local weapon = _G[id]
			if type(weapon) == "table" and (weapon.GetUnlocked == nil or weapon:GetUnlocked()) then
				table.insert(deck, id)
			end
		end
	end
	return deck
end

--- Checks if the given ID is available as a default store weapon
function modApi:isDefaultWeapon(id)
	return DEFAULT_WEAPONS[id] or false
end

--- load in vanilla weapons before other mods override initializeDecks
local oldGame = GAME
GAME = {}
initializeDecks()
for _, id in ipairs(GAME.WeaponDeck) do
	-- both add to library and mark as default weapon
	modApi.weaponDeck[id] = true
	DEFAULT_WEAPONS[id] = true
end
GAME = oldGame

-- load in the config based on what should be enabled
modApi:addModsFirstLoadedHook(function()
	-- import weapons as second time to catch those added by overriding initializeDecks
	local oldGame = GAME
	GAME = {}
	initializeDecks()
	for _, id in ipairs(GAME.WeaponDeck) do
		modApi:addWeaponDrop(id)
	end
	GAME = oldGame

	-- load weapon enable values from the config
	loadWeaponDeck()
end)

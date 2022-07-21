modApi.weaponDeck = {}
-- all weapon defaults as defined by mods
local DEFAULT_WEAPONS
-- weapons available in vanilla
local VANILLA_WEAPONS = {}

-- constants for enabling binary
local NONE = modApi.constants.WEAPON_CONFIG_NONE
local SHOP_NORMAL = modApi.constants.WEAPON_CONFIG_SHOP_NORMAL
local SHOP_ADVANCED = modApi.constants.WEAPON_CONFIG_SHOP_ADVANCED
local POD_NORMAL = modApi.constants.WEAPON_CONFIG_POD_NORMAL
local POD_ADVANCED = modApi.constants.WEAPON_CONFIG_POD_ADVANCED
local ALL = modApi.constants.WEAPON_CONFIG_ALL

-- compacts a config table into a compact integer, to prevent bloating the save file
function modApi:compactWeaponConfig(config)
	local compact = 0
	-- true means both, string to filter
	if config.shop == true then
		compact = compact + SHOP_NORMAL + SHOP_ADVANCED
	elseif config.shop == "normal" then
		compact = compact + SHOP_NORMAL
	elseif config.shop == "advanced" then
		compact = compact + SHOP_ADVANCED
	end
	if config.pod == true then
		compact = compact + POD_NORMAL + POD_ADVANCED
	elseif config.pod == "normal" then
		compact = compact + POD_NORMAL
	elseif config.pod == "advanced" then
		compact = compact + POD_ADVANCED
	end

	return compact
end

--- Adds a weapon to the deck
function modApi:addWeaponDrop(config, enabled)
	local id
	local tableConfig = type(config) == "table"
	if tableConfig then
		id = config.id
	else
		id = config
		assert(enabled == nil or type(enabled) == "boolean", "Enabled must be a boolean or a config table")
	end
	assert(type(id) == "string", "id must be a string")

	-- if set to a table, compact into the proper bits to say what is enabled
	local value = nil
	if tableConfig then
		value = self:compactWeaponConfig(config)
		-- false is disabled but available to select
	elseif enabled == false then
		value = NONE
	-- true means enable all, nil means enable all if not set already
	elseif enabled == true or (enabled == nil and DEFAULT_WEAPONS[id] == nil) then
		value = ALL
	end

	-- if any of the above passed, set the value into both defaults and the deck
	if value ~= nil then
		modApi.weaponDeck[id] = value
		DEFAULT_WEAPONS[id] = value
	end
end

-- checks if the given bit is set in the value
local function hasBit(value, bit)
	return value % (bit + bit) >= bit
end

-- gets a list of all weapons with the given bit set
local function getWeaponList(firstBit, secondBit)
	local deck = {}
	for id, enabled in pairs(modApi.weaponDeck) do
		if hasBit(enabled, firstBit) or (secondBit ~= nil and hasBit(enabled, secondBit)) then
			local weapon = _G[id]
			if type(weapon) == "table" and (weapon.GetUnlocked == nil or weapon:GetUnlocked()) then
				table.insert(deck, id)
			end
		end
	end
	return deck
end

--- gets a list of all possible shop weapons
function modApi:getFullWeaponDeck()
	return getWeaponList(SHOP_NORMAL, SHOP_ADVANCED)
end

--- Gets the list of weapons for the shop
function modApi:getWeaponDeck(advanced)
	-- nil: return all weapons
	if advanced == nil then
		advanced = IsNewEquipment()
	end
	-- true: anything enabled in advanced
	if advanced then
		return getWeaponList(SHOP_ADVANCED)
	end
	-- false: anything enabled when not advanced
	return getWeaponList(SHOP_NORMAL)
end

--- Gets the list of weapons for the shop
function modApi:getPodWeaponDeck(advanced)
	-- nil: return all weapons
	if advanced == nil then
		advanced = IsNewEquipment()
	end
	-- true: anything enabled in advanced
	if advanced then
		return getWeaponList(POD_ADVANCED)
	end
	-- false: anything enabled when not advanced
	return getWeaponList(POD_NORMAL)
end

--- gets the default value for the given weapon, as a compact integer
function modApi:getDefaultWeaponConfig(id)
	return DEFAULT_WEAPONS[id] or 0
end

--- gets the vanilla value for the given weapon, as a compact integer
function modApi:getVanillaWeaponConfig(id)
	return VANILLA_WEAPONS[id] or 0
end

--- Checks if the given ID is available as a vanilla store or pod weapon
function modApi:isDefaultWeapon(id)
	return self:getVanillaWeaponConfig(id) > 0
end
--------------------
-- initialization --
--------------------

--- load in vanilla weapons before other mods override initializeDecks
local oldGame = GAME
local oldIsNewEquipment = IsNewEquipment

-- helper to populate the vanilla tables
local function populateVanillaWeapons(list, value)
	for _, id in ipairs(list) do
		VANILLA_WEAPONS[id] = (VANILLA_WEAPONS[id] or 0) + value
	end
end

-- first, find all non-advanced weapons
function IsNewEquipment()
	return false
end
GAME = GameObject:new{}
checkWeaponDeck()
populateVanillaWeapons(GAME.WeaponDeck, SHOP_NORMAL)
populateVanillaWeapons(GAME.PodWeaponDeck, POD_NORMAL)

-- next, advanced weapons
function IsNewEquipment()
	return true
end
GAME = GameObject:new{}
checkWeaponDeck()
populateVanillaWeapons(GAME.WeaponDeck, SHOP_ADVANCED)
populateVanillaWeapons(GAME.PodWeaponDeck, POD_ADVANCED)

-- defaults start as a copy of vanilla, but will be populated with mods later
DEFAULT_WEAPONS = copy_table(VANILLA_WEAPONS)
modApi.weaponDeck = copy_table(VANILLA_WEAPONS)

-- restore values we overwrote
GAME = oldGame
IsNewEquipment = oldIsNewEquipment

-- load in the config based on what should be enabled
modApi.events.onModsFirstLoaded:subscribe(function()
	-- import weapons as second time to catch those added by overriding initializeDecks
	-- since this is legacy support, we will assume they are adding to both
	local oldGame = GAME
	GAME = GameObject:new{}
	initializeDecks()
	for _, id in ipairs(GAME.WeaponDeck) do
		modApi:addWeaponDrop(id)
	end
	GAME = oldGame

	-- load weapon enable values from the config
	loadWeaponDeck()
end)

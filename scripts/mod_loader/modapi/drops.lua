modApi.weaponDeck = {}
modApi.pilotDeck = {}
-- all weapon defaults as defined by mods
local DEFAULT_WEAPONS
-- all pilots defaults as defined by mods
local DEFAULT_PILOTS
-- weapons available in vanilla
local VANILLA_WEAPONS
-- pilots available in vanilla
local VANILLA_PILOTS

-----------
-- utils --
-----------

-- filters the deck by the given bit
local function filterDeck(enabledFunction, deckConfig, firstBit, secondBit)
	local deck = {}
	for id, enabled in pairs(deckConfig) do
		if (is_bit_set(enabled, firstBit) or (secondBit ~= nil and is_bit_set(enabled, secondBit))) and enabledFunction(id) then
			table.insert(deck, id)
		end
	end
	return deck
end


-------------
-- weapons --
-------------

-- compacts a config table into a compact integer, to prevent bloating the save file
function modApi:compactWeaponConfig(config)
	local compact = 0
	-- true means both, string to filter
	if config.shop == true then
		compact = compact + modApi.constants.WEAPON_CONFIG_SHOP_NORMAL + modApi.constants.WEAPON_CONFIG_SHOP_ADVANCED
	elseif config.shop == "normal" then
		compact = compact + modApi.constants.WEAPON_CONFIG_SHOP_NORMAL
	elseif config.shop == "advanced" then
		compact = compact + modApi.constants.WEAPON_CONFIG_SHOP_ADVANCED
	end
	if config.pod == true then
		compact = compact + modApi.constants.WEAPON_CONFIG_POD_NORMAL + modApi.constants.WEAPON_CONFIG_POD_ADVANCED
	elseif config.pod == "normal" then
		compact = compact + modApi.constants.WEAPON_CONFIG_POD_NORMAL
	elseif config.pod == "advanced" then
		compact = compact + modApi.constants.WEAPON_CONFIG_POD_ADVANCED
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
		value = modApi.constants.WEAPON_CONFIG_NONE
	-- true means enable all, nil means enable all if not set already
	elseif enabled == true or (enabled == nil and DEFAULT_WEAPONS[id] == nil) then
		value = modApi.constants.WEAPON_CONFIG_ALL
	end

	-- if any of the above passed, set the value into both defaults and the deck
	if value ~= nil then
		modApi.weaponDeck[id] = value
		DEFAULT_WEAPONS[id] = value
	end
end

-- checks if a weapon ID should show in time pods
local function isWeaponUnlocked(id)
	local weapon = _G[id]
	return type(weapon) == "table" and (weapon.GetUnlocked == nil or weapon:GetUnlocked())
end

--- gets a list of all possible shop weapons
function modApi:getFullWeaponDeck()
	return filterDeck(isWeaponUnlocked, modApi.weaponDeck, modApi.constants.WEAPON_CONFIG_SHOP_NORMAL, modApi.constants.WEAPON_CONFIG_SHOP_ADVANCED)
end

--- Gets the list of weapons for the shop
function modApi:getWeaponDeck(advanced)
	-- nil: return all weapons
	if advanced == nil then
		advanced = IsNewEquipment()
	end
	-- true: anything enabled in advanced
	if advanced then
		return filterDeck(isWeaponUnlocked, modApi.weaponDeck, modApi.constants.WEAPON_CONFIG_SHOP_ADVANCED)
	end
	-- false: anything enabled when not advanced
	return filterDeck(isWeaponUnlocked, modApi.weaponDeck, modApi.constants.WEAPON_CONFIG_SHOP_NORMAL)
end

--- Gets the list of weapons for the shop
function modApi:getPodWeaponDeck(advanced)
	-- nil: return all weapons
	if advanced == nil then
		advanced = IsNewEquipment()
	end
	-- true: anything enabled in advanced
	if advanced then
		return filterDeck(isWeaponUnlocked, modApi.weaponDeck, modApi.constants.WEAPON_CONFIG_POD_ADVANCED)
	end
	-- false: anything enabled when not advanced
	return filterDeck(isWeaponUnlocked, modApi.weaponDeck, modApi.constants.WEAPON_CONFIG_POD_NORMAL)
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

------------
-- pilots --
------------

-- compacts a config table into a compact integer, to prevent bloating the save file
function modApi:compactPilotConfig(config)
	local compact = 0
	-- true means both, string to filter
	if config.pod == true then
		compact = compact + modApi.constants.PILOT_CONFIG_POD_NORMAL + modApi.constants.PILOT_CONFIG_POD_ADVANCED
	elseif config.pod == "normal" then
		compact = compact + modApi.constants.PILOT_CONFIG_POD_NORMAL
	elseif config.pod == "advanced" then
		compact = compact + modApi.constants.PILOT_CONFIG_POD_ADVANCED
	end
	-- true means both, string to filter
	if config.recruit == true then
		compact = compact + modApi.constants.PILOT_CONFIG_RECRUIT
	end
	-- true means both, string to filter
	if config.ftl == true then
		compact = compact + modApi.constants.PILOT_CONFIG_POD_FTL
	end

	return compact
end

--- Adds a pilot to the deck, or overrides their config if already present
-- Note that CreatePilot will automatically add the pilot to the deck
function modApi:addPilotDrop(config)
	assert(type(config) == "table", "argument must be a table")
	assert(type(config.id) == "string", "id must be a string")

	-- if set to a table, compact into the proper bits to say what is enabled
	local value = self:compactPilotConfig(config)
	modApi.pilotDeck[config.id] = value
	DEFAULT_PILOTS[config.id] = value
end

-- checks if a pilot ID should show in time pods
local function isPilotEnabled(id)
	local pilot = _G[id]
	return type(pilot) == "table" and (pilot.IsEnabled == nil or pilot:IsEnabled())
end

--- gets a list of all possible pilots
function modApi:getFullPilotDeck()
	return filterDeck(isPilotEnabled, modApi.pilotDeck, modApi.constants.PILOT_CONFIG_POD_NORMAL, modApi.constants.PILOT_CONFIG_POD_ADVANCED)
end

--- gets a list of all recruit pilots
function modApi:getStarterPilotDeck()
	local deck = filterDeck(isPilotEnabled, modApi.pilotDeck, modApi.constants.PILOT_CONFIG_RECRUIT)
	-- bad config?
	if #deck == 0 then
		return {"Pilot_Archive", "Pilot_Rust", "Pilot_Detritus", "Pilot_Pinnacle"}
	end
	return deck
end

--- gets a list of all secret pod pilots
local oldGetFTLPilots = GetFTLPilots
function GetFTLPilots()
	local deck = filterDeck(isPilotEnabled, modApi.pilotDeck, modApi.constants.PILOT_CONFIG_POD_FTL)
	-- bad config?
	if #deck == 0 then
		return { "Pilot_Mantis", "Pilot_Rock", "Pilot_Zoltan" }
	end
	return deck
end

--- Gets the list of pilots
function modApi:getPilotDeck(advanced)
	-- nil: return all pilots
	if advanced == nil then
		advanced = IsNewEquipment()
	end
	-- true: anything enabled in advanced
	if advanced then
		return filterDeck(isPilotEnabled, modApi.pilotDeck, modApi.constants.PILOT_CONFIG_POD_ADVANCED)
	end
	-- false: anything enabled when not advanced
	return filterDeck(isPilotEnabled, modApi.pilotDeck, modApi.constants.PILOT_CONFIG_POD_NORMAL)
end

--- gets the default value for the given pilot, as a compact integer
function modApi:getDefaultPilotConfig(id)
	return DEFAULT_PILOTS[id] or 0
end

--- gets the vanilla value for the given pilot, as a compact integer
function modApi:getVanillaPilotConfig(id)
	return VANILLA_PILOTS[id] or 0
end

--- gets the vanilla value for the given pilot, as a compact integer
function modApi:isVanillaPilot(id)
	return VANILLA_PILOTS[id] ~= nil
end


--------------------
-- initialization --
--------------------

--- load in vanilla weapons before other mods override initializeDecks
local oldGame = GAME
local oldIsNewEquipment = IsNewEquipment

-- helper to populate the vanilla tables
VANILLA_WEAPONS = {}
local function populateVanilla(dest, src, value)
	for _, id in ipairs(src) do
		dest[id] = (dest[id] or 0) + value
	end
end

-- first, find all non-advanced weapons
function IsNewEquipment()
	return false
end
GAME = GameObject:new{}
checkWeaponDeck()
populateVanilla(VANILLA_WEAPONS, GAME.WeaponDeck,    modApi.constants.WEAPON_CONFIG_SHOP_NORMAL)
populateVanilla(VANILLA_WEAPONS, GAME.PodWeaponDeck, modApi.constants.WEAPON_CONFIG_POD_NORMAL)

-- next, advanced weapons
function IsNewEquipment()
	return true
end
GAME = GameObject:new{}
checkWeaponDeck()
populateVanilla(VANILLA_WEAPONS, GAME.WeaponDeck,    modApi.constants.WEAPON_CONFIG_SHOP_ADVANCED)
populateVanilla(VANILLA_WEAPONS, GAME.PodWeaponDeck, modApi.constants.WEAPON_CONFIG_POD_ADVANCED)

-- defaults start as a copy of vanilla, but will be populated with mods later
DEFAULT_WEAPONS = copy_table(VANILLA_WEAPONS)
modApi.weaponDeck = copy_table(VANILLA_WEAPONS)

-- restore values we overwrote
GAME = oldGame
IsNewEquipment = oldIsNewEquipment


-- next, get pilots from the vanilla list
VANILLA_PILOTS = {}
populateVanilla(VANILLA_PILOTS, PilotList, modApi.constants.PILOT_CONFIG_POD_NORMAL + modApi.constants.PILOT_CONFIG_POD_ADVANCED)
for _, id in ipairs(New_PilotList) do
	VANILLA_PILOTS[id] = modApi.constants.PILOT_CONFIG_POD_ADVANCED
end
populateVanilla(VANILLA_PILOTS, Pilot_Recruits, modApi.constants.PILOT_CONFIG_RECRUIT)
populateVanilla(VANILLA_PILOTS, {"Pilot_Mantis", "Pilot_Rock", "Pilot_Zoltan"}, modApi.constants.PILOT_CONFIG_POD_FTL)
DEFAULT_PILOTS = copy_table(VANILLA_PILOTS)
modApi.pilotDeck = copy_table(VANILLA_PILOTS)


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

	-- copy in modded pilots
	for _, id in ipairs(PilotListExtended) do
		if DEFAULT_PILOTS[id] == nil and _G[id] ~= nil and _G[id].Rarity ~= 0 then
			modApi:addPilotDrop{
				id = id,
				pod = list_contains(New_PilotList, id) and "advanced" or true,
				recruit = list_contains(Pilot_Recruits, id),
				ftl = false,
			}
		end
	end
	-- copy in mod starters
	for _, id in ipairs(Pilot_Recruits) do
		if DEFAULT_PILOTS[id] == nil then
			modApi:addPilotDrop{
				id = id,
				recruit = true,
			}
		end
	end

	-- load weapons and pilots enable values from the config
	loadWeaponDeck()
	loadPilotDeck()
end)

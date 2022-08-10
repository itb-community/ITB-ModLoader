local rootpath = GetParentPath(...)
local deck_selector = require(rootpath.."_deck_selector")

-- add a few colors to vanilla things to make certain features stand out
local NORMAL_COLOR    = sdl.rgb( 50,  50, 150)
local ADVANCED_COLOR  = sdl.rgb(150,  50,  50)
local MOD_COLOR       = sdl.rgb( 50, 150,  50)

--[[--
	Gets the name for a weapon
	@param id	Weapon ID
	@return Weapon name
]]
local function getWeaponKey(id, key)
	Assert.Equals("string", type(id), "ID must be a string")
	Assert.Equals("string", type(key), "Key must be a string")
	local textId = id .. "_" .. key
	if IsLocalizedText(textId) then
		return GetLocalizedText(textId)
	end
	return _G[id] and _G[id][key] or id
end

-- packs a config table with 4 keys into a single int
local function packConfig(table)
	local packed = 0
	if table.shop_normal   then packed = packed + modApi.constants.WEAPON_CONFIG_SHOP_NORMAL   end
	if table.shop_advanced then packed = packed + modApi.constants.WEAPON_CONFIG_SHOP_ADVANCED end
	if table.pod_normal    then packed = packed + modApi.constants.WEAPON_CONFIG_POD_NORMAL    end
	if table.pod_advanced  then packed = packed + modApi.constants.WEAPON_CONFIG_POD_ADVANCED  end
	return packed
end

-- unpacks the config int from the 4 keys
local function unpackConfig(value)
	if value == nil then
		value = 0
	end
	return {
		shop_normal   = is_bit_set(value, modApi.constants.WEAPON_CONFIG_SHOP_NORMAL),
		shop_advanced = is_bit_set(value, modApi.constants.WEAPON_CONFIG_SHOP_ADVANCED),
		pod_normal    = is_bit_set(value, modApi.constants.WEAPON_CONFIG_POD_NORMAL),
		pod_advanced  = is_bit_set(value, modApi.constants.WEAPON_CONFIG_POD_ADVANCED)
	}
end

local function getDeckColor(id)
	local vanillaConfig = modApi:getVanillaWeaponConfig(id)
	if vanillaConfig > 0 then
		-- advanced contains all the normal things
		if is_bit_set(vanillaConfig, modApi.constants.WEAPON_CONFIG_POD_NORMAL) or is_bit_set(vanillaConfig, modApi.constants.WEAPON_CONFIG_SHOP_NORMAL) then
			return NORMAL_COLOR
		end
		return ADVANCED_COLOR
	end
	return MOD_COLOR
end

--[[--
  Gets a sorted list of weapon classes, each containing a sorted list of weapons
]]
local function getClassList(oldConfig)
	local classes = {}
	for id, enabled in pairs(modApi.weaponDeck) do
		local weapon = _G[id]
		if type(weapon) == "table" and (not weapon.GetUnlocked or weapon:GetUnlocked()) then
			-- first, determine the weapon class
			local class
			if oldConfig[id] == nil then
				class = "new"
			elseif weapon.Passive ~= "" then
				class = "Passive"
			else
				class = weapon:GetClass()
				if class == "" then class = "Any" end
			end
			-- if this is the first we have seen the class, make a class group
			if classes[class] == nil then
				-- new sorts first, and uses a special text
				if class == "new" then
					classes[class] = {contents = {}, name = GetLocalizedText("Upgrade_New"), sortName = "1"}
				else
					local key = "Skill_Class" .. class
					classes[class] = {contents = {}, name = IsLocalizedText(key) and GetLocalizedText(key) or class}
				end
			end
			table.insert(classes[class].contents, {id = id, name = getWeaponKey(id, "Name"), enabled = enabled})
		end
	end
	--- convert the map into a list and sort, plus sort the weapons
	local sortName = function(a, b) return (a.sortName or a.name) < (b.sortName or b.name) end
	local classList = {}
	for id, data in pairs(classes) do
		table.sort(data.contents, sortName)
		table.insert(classList, data)
	end
	table.sort(classList, sortName)
	return classList
end

--[[--
	Gets the image for the given weapon, or creates one if missing
	@param id	weapon ID
	@return	Surface for this palette button
]]
local function getSurface(id)
	Assert.Equals("string", type(id), "ID must be a string")

	local weapon = _G[id]
	Assert.Equals("table", type(weapon), "Missing weapon from shop")
	return sdlext.getSurface({
		path = "img/" .. weapon.Icon,
		scale = 2
	})
end

local function buildDropdowns(dropdownLayout, updateButtons, currentFilter)
	local dropdownDeck = sdlext.buildDropDownButton(
		GetText("ConfigureWeaponDeck_Deck_Title"),
		GetText("ConfigureWeaponDeck_Deck_Tooltip"),
		{
			choices = {"All", "Shop", "Pod"},
			tooltips = {
				GetText("ConfigureWeaponDeck_Deck_Tip_All"),
				GetText("ConfigureWeaponDeck_Deck_Tip_Shop"),
				GetText("ConfigureWeaponDeck_Deck_Tip_Pod")
			}
		}
	):addTo(dropdownLayout)
	local dropdownMode = sdlext.buildDropDownButton(
		GetText("ConfigureDeck_Mode_Title"),
		GetText("ConfigureDeck_Mode_Tooltip"),
		{
			choices = {"All", "Normal", "Advanced"},
			tooltips = {
				GetText("ConfigureDeck_Mode_Tip_All"),
				GetText("ConfigureDeck_Mode_Tip_Normal"),
				GetText("ConfigureDeck_Mode_Tip_Advanced")
			}
		}
	):addTo(dropdownLayout)

	local function updateModeDropdowns()
		-- first, determine the new mask
		local shop     = dropdownDeck.value ~= 3
		local pod      = dropdownDeck.value ~= 2
		local normal   = dropdownMode.value ~= 3
		local advanced = dropdownMode.value ~= 2
		currentFilter.shop_normal   = shop and normal
		currentFilter.shop_advanced = shop and advanced
		currentFilter.pod_normal    = pod  and normal
		currentFilter.pod_advanced  = pod  and advanced
		-- next, update checked status on all dropdowns
		updateButtons()
	end
	dropdownMode.optionSelected:subscribe(updateModeDropdowns)
	dropdownDeck.optionSelected:subscribe(updateModeDropdowns)
end

local function validateEnabled(enabledMap)
	local shop_normal = true
	local shop_advanced = true
	local pod_normal = true
	local need_pod_advanced = true
	for id, enabled in pairs(enabledMap) do
		-- need at least one weapon in each deck
		if is_bit_set(enabled, modApi.constants.WEAPON_CONFIG_SHOP_NORMAL)   then shop_normal   = false end
		if is_bit_set(enabled, modApi.constants.WEAPON_CONFIG_SHOP_ADVANCED) then shop_advanced = false end
		if is_bit_set(enabled, modApi.constants.WEAPON_CONFIG_POD_NORMAL)    then pod_normal    = false end
		if is_bit_set(enabled, modApi.constants.WEAPON_CONFIG_POD_ADVANCED)  then pod_advanced  = false end
	end

	-- copy a bit if the boolean is set
	local function copyBit(condition, value, default, bit)
		if condition and is_bit_set(default, bit) then
			return value + bit
		end
		return value
	end

	-- no weapons selected will fallback to default deck logic, so replace with vanilla weapons
	if shop_normal or shop_advanced or pod_normal or pod_advanced then
		for id, enabled in pairs(enabledMap) do
			local default = modApi:getVanillaWeaponConfig(id)
			enabledMap[id] = copyBit(need_shop_normal,   enabledMap[id], default, modApi.constants.WEAPON_CONFIG_SHOP_NORMAL)
			enabledMap[id] = copyBit(need_shop_advanced, enabledMap[id], default, modApi.constants.WEAPON_CONFIG_SHOP_ADVANCED)
			enabledMap[id] = copyBit(need_pod_normal,    enabledMap[id], default, modApi.constants.WEAPON_CONFIG_POD_NORMAL)
			enabledMap[id] = copyBit(need_pod_advanced,  enabledMap[id], default, modApi.constants.WEAPON_CONFIG_POD_ADVANCED)
		end
	end
end

-- config for the selector to work for pilots
local WEAPON_DECK_CONFIG = {
  deckWidth = 120,
	deckHeight = 80,
	showTitleOnButton = true,
	apiKey = "weaponDeck",
	configKey = "shopWeaponsEnabled",
	presetKey = "shopWeaponPresets",
	enabledValue = 15,
	disabledValue = 0,

  packConfig = packConfig,
  unpackConfig = unpackConfig,
	getVanillaConfig = function(id) return modApi:getVanillaWeaponConfig(id) end,
	getDefaultConfig = function(id) return modApi:getDefaultWeaponConfig(id) end,
	buildDropdowns = buildDropdowns,
	getSurface = getSurface,
	getClassList = getClassList,
	getDeckColor = getDeckColor,
	validateEnabled = validateEnabled,
	onExit = function(id) end,
	default_filter = {shop_normal = true, shop_advanced = true, pod_normal = true, pod_advanced = true},
}

function loadWeaponDeck()
	deck_selector:loadConfigIntoApi(WEAPON_DECK_CONFIG)
end

function ConfigureWeaponDeck()
	loadWeaponDeck()
	deck_selector:createUi("ModContent_Button_ConfigureWeaponDeck", WEAPON_DECK_CONFIG)
end

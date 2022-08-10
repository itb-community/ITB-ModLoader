local rootpath = GetParentPath(...)
local deck_selector = require(rootpath.."_deck_selector")

-- add a few colors to vanilla things to make certain features stand out
local NORMAL_COLOR    = sdl.rgb( 50,  50, 150)
local FTL_COLOR       = sdl.rgb(200, 200, 200)
local ADVANCED_COLOR  = sdl.rgb(150,  50,  50)
local RECRUIT_COLOR   = sdl.rgb(150, 150,  50)
local MOD_COLOR       = sdl.rgb( 50, 150,  50)

--- Extra UI components
local BLACK_MASK = sdl.rgb(0, 0, 0)
local pilotLock = nil
-- TODO: is there a proper way to check if their portrait is in the new folder?
local ADVANCED_PILOTS = {"Pilot_Arrogant", "Pilot_Caretaker", "Pilot_Chemical", "Pilot_Delusional"}
local SECRET_PILOTS = {"Pilot_Mantis","Pilot_Rock","Pilot_Zoltan"}

--[[--
	Checks if the advanced AI pilot was unlocked
	@return True if the advanced AI was unlocked, false otherwise
]]
local function isPilotUnlocked(id)
	-- any pilots that are not available in the hangar just show as unlocked. This is mostly for recruits
	-- not checking the recruit list as some mods add recruits that can be selected in the hangar
	return (not list_contains(PilotListExtended, id) and not list_contains(SECRET_PILOTS, id))
		or (type(Profile) == "table" and type(Profile.pilots) == "table" and list_contains(Profile.pilots, id))
end

-- packs a config table with 2 keys into a single int
local function packConfig(table)
	local packed = 0
	if table.pod_normal   then packed = packed + modApi.constants.PILOT_CONFIG_POD_NORMAL   end
	if table.pod_advanced then packed = packed + modApi.constants.PILOT_CONFIG_POD_ADVANCED end
	if table.recruit      then packed = packed + modApi.constants.PILOT_CONFIG_RECRUIT      end
	return packed
end

-- unpacks the config int from the 2 keys
local function unpackConfig(value)
	if value == nil then
		value = 0
	end
	return {
		pod_normal   = is_bit_set(value, modApi.constants.PILOT_CONFIG_POD_NORMAL),
		pod_advanced = is_bit_set(value, modApi.constants.PILOT_CONFIG_POD_ADVANCED),
		recruit      = is_bit_set(value, modApi.constants.PILOT_CONFIG_RECRUIT),
	}
end

-- gets a pilot surface, or if not unlocked a black surface
local function getSurface(pilotId)
	-- unlocked calls directly
	local unlocked = isPilotUnlocked(pilotId)
	local path
	local portrait = _G[pilotId].Portrait
	if portrait == "" then
		local advanced = list_contains(ADVANCED_PILOTS, pilotId)
		local prefix = advanced and "img/advanced/portraits/pilots/" or "img/portraits/pilots/"
		path = prefix .. pilotId .. ".png"
	else
		path = "img/portraits/" .. portrait .. ".png"
	end
	if unlocked then
		return sdlext.getSurface({
			path = path,
			scale = 2
		})
	else
		return sdlext.getSurface({
			path = path,
			transformations = {
				{ scale = 2 },
				{ multiply = BLACK_MASK }
			}
		})
	end
end

-- builds the selector dropdowns for the pilot list
local function buildDropdowns(dropdownLayout, updateButtons, currentFilter)
	local dropdownDeck = sdlext.buildDropDownButton(
		GetText("ConfigurePilotDeck_Deck_Title"),
		GetText("ConfigurePilotDeck_Deck_Tooltip"),
		{
			choices = {"Pod", "Recruit"},
			tooltips = {
				GetText("ConfigurePilotDeck_Deck_Tip_Pod"),
				GetText("ConfigurePilotDeck_Deck_Tip_Recruit")
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
				GetText("ConfigureDeck_Mode_Tip_Advanced"),
				GetText("ConfigurePilotDeck_Mode_Tip_Recruit"),
			}
		}
	):addTo(dropdownLayout)

	local updateDropdown = function()
		-- if recruit is selected, hide normal/advanced dropdown
		if dropdownDeck.value == 2 then
			currentFilter.pod_normal = false
			currentFilter.pod_advanced = false
			currentFilter.recruit = true
			dropdownMode.visible = false
		else
			currentFilter.pod_normal    = dropdownMode.value ~= 3
			currentFilter.pod_advanced  = dropdownMode.value ~= 2
			currentFilter.recruit       = false
			dropdownMode.visible = true
		end
		updateButtons()
	end
	dropdownDeck.optionSelected:subscribe(updateDropdown)
	dropdownMode.optionSelected:subscribe(updateDropdown)
end

local function getDeckColor(id)
	if modApi:isVanillaPilot(id) then
		local vanillaConfig = modApi:getVanillaPilotConfig(id)
		if vanillaConfig == 0 then
			return FTL_COLOR
		end
		-- recruits shouldn't be another type
		if is_bit_set(vanillaConfig, modApi.constants.PILOT_CONFIG_RECRUIT) then
			return RECRUIT_COLOR
		end
		-- advanced contains all the normal things
		if is_bit_set(vanillaConfig, modApi.constants.PILOT_CONFIG_POD_NORMAL) then
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
	local singleList = {}
	for id, enabled in pairs(modApi.pilotDeck) do
		local pilot = _G[id]
		if type(pilot) == "table" and (not pilot.GetUnlocked or pilot:GetUnlocked()) then
			local desc = nil
			local unlocked = isPilotUnlocked(id)
			if unlocked then
				local key = GetSkillInfo(pilot.Skill).desc
				if not key or key == "" then
					key = "Hangar_NoAbility"
				end
				desc = GetText(key)
			end
			table.insert(singleList, {
				id = id,
				name = GetText(pilot.Name),
				description = desc,
				enabled = enabled,
				locked = not unlocked
			})
		end
	end
	table.sort(singleList, function(a, b)
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.id < b.id
	end)
	return {
		{contents = singleList}
	}
end

local function validateEnabled(enabledMap)
	local pod_normal = true
	local pod_advanced = true
	local recruits = 0
	for id, enabled in pairs(enabledMap) do
		-- need at least one pilot in either deck
		if is_bit_set(enabled, modApi.constants.PILOT_CONFIG_POD_NORMAL)   then pod_normal   = false end
		if is_bit_set(enabled, modApi.constants.PILOT_CONFIG_POD_ADVANCED) then pod_advanced = false end
		-- must have at least 2 recruits or the game crashes
		if is_bit_set(enabled, modApi.constants.PILOT_CONFIG_RECRUIT)      then recruits = recruits + 1 end
	end

	-- copy a bit if the boolean is set
	local function copyBit(condition, value, default, bit)
		if condition and is_bit_set(default, bit) and not is_bit_set(value, bit) then
			return value + bit
		end
		return value
	end

	-- not enough pilots? just fill with default
	local need_recuits = recruits < 2
	LOG(recruits)
	if pod_normal or pod_advanced or need_recuits then
		for id, enabled in pairs(enabledMap) do
			local default = modApi:getVanillaPilotConfig(id)
			enabledMap[id] = copyBit(pod_normal,   enabledMap[id], default, modApi.constants.PILOT_CONFIG_POD_NORMAL)
			enabledMap[id] = copyBit(pod_advanced, enabledMap[id], default, modApi.constants.PILOT_CONFIG_POD_ADVANCED)
			enabledMap[id] = copyBit(need_recuits, enabledMap[id], default, modApi.constants.PILOT_CONFIG_RECRUIT)
		end
	end
end

-- config for the selector to work for pilots
local PILOT_DECK_CONFIG = {
  deckWidth = 122,
	deckHeight = 122,
	showTitleOnButton = false,
	apiKey = "pilotDeck",
	configKey = "pilotDeck",
	presetKey = "pilotDeckPresets",
	enabledValue = 7,
	disabledValue = 0,

  packConfig = packConfig,
  unpackConfig = unpackConfig,
	getVanillaConfig = function(id) return modApi:getVanillaPilotConfig(id) end,
	getDefaultConfig = function(id) return modApi:getDefaultPilotConfig(id) end,
	buildDropdowns = buildDropdowns,
	getSurface = getSurface,
	getClassList = getClassList,
	getDeckColor = getDeckColor,
	validateEnabled = validateEnabled,
	onExit = function(id)
		Pilot_Recruits = modApi:getStarterPilotDeck()
	end,
	default_filter = { pod_normal = true, pod_advanced = true },
}

function loadPilotDeck()
	deck_selector:loadConfigIntoApi(PILOT_DECK_CONFIG)
	Pilot_Recruits = modApi:getStarterPilotDeck()
end

function ConfigurePilotDeck()
	loadPilotDeck()
	deck_selector:createUi("ModContent_Button_ConfigurePilotDeck", PILOT_DECK_CONFIG)
end

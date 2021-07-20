-- dimensions of a button
local CHECKBOX = 25
local TEXT_PADDING = 18
local WEAPON_WIDTH = 120 + 8
local WEAPON_HEIGHT = 80 + 8 + TEXT_PADDING
-- button spacing
local WEAPON_GAP = 16
local PADDING = 12

--- Cache of recolored images for each palette ID
local surfaces = {}

--- Extra UI components
local WEAPON_FONT = nil
local MOD_COLOR = sdl.rgb(50, 125, 75)

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
			if oldConfig[id] == nil and not modApi:isDefaultWeapon(id) then
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
					classes[class] = {weapons = {}, name = GetLocalizedText("Upgrade_New"), sortName = "1"}
				else
					local key = "Skill_Class" .. class
					classes[class] = {weapons = {}, name = IsLocalizedText(key) and GetLocalizedText(key) or class}
				end
			end
			table.insert(classes[class].weapons, {id = id, name = getWeaponKey(id, "Name"), enabled = enabled})
		end
	end
	--- convert the map into a list and sort, plus sort the weapons
	local sortName = function(a, b) return (a.sortName or a.name) < (b.sortName or b.name) end
	local classList = {}
	for id, data in pairs(classes) do
		table.sort(data.weapons, sortName)
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
local function getOrCreateWeaponSurface(id)
	Assert.Equals("string", type(id), "ID must be a string")

	local surface = surfaces[id]
	if not surface then
		local weapon = _G[id]
		Assert.Equals("table", type(weapon), "Missing weapon from shop")
		surface = sdlext.getSurface({
			path = "img/" .. weapon.Icon,
			scale = 2
		})
		surfaces[id] = surface
	end
	return surface
end

--- Special values for the preset dropdown
local PRESET_DEFAULT = "Default"
local PRESET_RANDOM = "Random"
local PRESET_NEW = "New"
-- default presets for all letters
local ALL_PRESETS = {}
for i = 1, 26 do ALL_PRESETS[i] = string.char(64+i) end

function loadWeaponDeck()
	-- load weapon enable values from the config
	sdlext.config(modApi:getCurrentModcontentPath(), function(config)
		if config.shopWeaponsEnabled ~= nil then
			for id, enabled in pairs(config.shopWeaponsEnabled) do
				if modApi.weaponDeck[id] ~= nil then
					modApi.weaponDeck[id] = enabled
				end
			end
		end
	end)
end

local function loadConfig()
	local presets = {}
	local oldConfig

	sdlext.config(modApi:getCurrentModcontentPath(), function(config)
		oldConfig = config.shopWeaponsEnabled or {}
		if config.shopWeaponPresets ~= nil then
			for key in pairs(config.shopWeaponPresets) do
				table.insert(presets, key)
			end
		end
	end)

	-- if not up to Z, support new presets
	table.sort(presets)
	if #presets < #ALL_PRESETS then
		table.insert(presets, PRESET_NEW)
	end
	table.insert(presets, 1, PRESET_DEFAULT)
	table.insert(presets, 2, PRESET_RANDOM)

	return presets, oldConfig
end

--- saves a preset to the config file
local changePresets = Event()
local presets
local buttons
local function savePreset(presetId)
	Assert.Equals("string", type(presetId))

	-- no saving vanilla/random
	if presetId == PRESET_DEFAULT or presetId == PRESET_RANDOM then
		return
	end

	-- if new, get a new preset identifier
	if presetId == PRESET_NEW then
		-- its just the first unset preset, luckily they are in alphabetical order
		for _, presetCheck in ipairs(ALL_PRESETS) do
			if not list_contains(presets, presetCheck) then
				presetId = presetCheck
				break
			end
		end

		Assert.NotEquals(PRESET_NEW, presetId)

		-- add to the dropdown
		table.insert(presets, #presets, presetId)
		-- if full, remove new
		if #presets == #ALL_PRESETS + 2 then
			remove_element(PRESET_NEW, presets)
		end
		changePresets:dispatch(presetId)
	end

	-- build data to save as an array
	local enabled = {}
	local any = false
	for _, button in ipairs(buttons) do
		if button.checked then
			enabled[button.id] = true
			any = true
		end
	end

	-- if nothing, clear the preset
	if not any then
		enabled = nil
		-- bring back new if missing (too many presets)
		if presets[#presets] ~= PRESET_NEW then
			table.insert(presets, PRESET_NEW)
		end
		-- remove preset from dropdown
		remove_element(presetId, presets)
		changePresets:dispatch(PRESET_NEW)
	end

	-- update the preset in config
	sdlext.config(modApi:getCurrentModcontentPath(), function(config)
		if enabled ~= nil and config.shopWeaponPresets == nil then
			config.shopWeaponPresets = {}
		end
		config.shopWeaponPresets[presetId] = enabled
	end)
end

--- loads a preset from the config file
local function loadPreset(presetId)
	if presetId == PRESET_NEW then
		return
	end
	-- randomly enable preset
	if presetId == PRESET_RANDOM then
		for _, button in ipairs(buttons) do
			button.checked = math.random() > 0.5
		end
		return
	end

	-- load preset from config
	local enabled
	-- default is a preset
	if presetId == PRESET_DEFAULT then
		enabled = function(id) return modApi:isDefaultWeapon(id) end
	else
		-- load preset from config
		local preset = {}
		sdlext.config(modApi:getCurrentModcontentPath(), function(config)
			if config.shopWeaponPresets ~= nil then
				preset = config.shopWeaponPresets[presetId] or {}
			end
		end)
		enabled = function(id) return preset[id] or false end
	end

	-- update buttons based on the preset
	for _, button in ipairs(buttons) do
		button.checked = enabled(button.id) or false
	end

	return
end

local weaponButtonClicked = Event()

-- adds a single weapon button to the class area
local function buildWeaponButton(weapon)
	local id = weapon.id
	local decoName = DecoText(weapon.name, WEAPON_FONT)

	local button = UiCheckbox()
		:widthpx(WEAPON_WIDTH):heightpx(WEAPON_HEIGHT)
		:settooltip(getWeaponKey(id, "Description"))
		:decorate({
			DecoButton(nil, not modApi:isDefaultWeapon(id) and MOD_COLOR),
			DecoAlign(-4, (TEXT_PADDING / 2)),
			DecoSurface(getOrCreateWeaponSurface(weapon.id)),
			DecoFixedCAlign(CHECKBOX, WEAPON_HEIGHT / 2),
			DecoCheckbox(),
			DecoFixedCAlign(sdlext.totalWidth(decoName.surface), (decoName.surface:h() - WEAPON_HEIGHT) / 2 + 4),
			decoName,
		})

	button.id = id
	button.checked = weapon.enabled

	--- enable the save and load buttons when we make a change
	function button:onclicked(mouseBtn)
		if mouseBtn == 1 then
			weaponButtonClicked:dispatch(button)
			return true
		end

		return false
	end

	return button
end

local function buildClassHolder(classHeaderText)
	local entryBoxHolder = UiBoxLayout()
		:vgap(5)
		:width(1)

	-- Add a collapse button for the class.
	-- This is just a checkbox, but skinned differently.
	local collapseButton = UiCheckbox()
		:width(1):heightpx(41)
		:decorate({
			DecoButton(),
			DecoCheckbox(
				deco.surfaces.dropdownOpenRight,
				deco.surfaces.dropdownClosed,
				deco.surfaces.dropdownOpenRightHovered,
				deco.surfaces.dropdownClosedHovered
			),
			DecoAlign(4, 2),
			DecoText(classHeaderText)
		})
		:addTo(entryBoxHolder)

	local weaponsHolder = UiFlowLayout()
		:width(1)
		:vgap(WEAPON_GAP):hgap(WEAPON_GAP)
		:padding(PADDING)
		:addTo(entryBoxHolder)
	weaponsHolder.padl = 41

	entryBoxHolder.weaponsHolder = weaponsHolder

	sdlext.addButtonSoundHandlers(collapseButton, function()
		weaponsHolder.visible = not collapseButton.checked
	end)

	return entryBoxHolder
end

local function buildContent(scroll)
	local oldConfig
	presets, oldConfig = loadConfig()
	buttons = {}

	local classesHolder = UiBoxLayout()
		:width(1)
		:vgap(PADDING)
		:padding(PADDING)
		:addTo(scroll)

	for _, class in ipairs(getClassList(oldConfig)) do
		local classHolder = buildClassHolder(class.name)
		classHolder:addTo(classesHolder)

		for _, weapon in pairs(class.weapons) do
			local button = buildWeaponButton(weapon)
			button:addTo(classHolder.weaponsHolder)
			table.insert(buttons, button)
		end
	end
end

local function buildButtons(buttonLayout)
	-- Forward declaration
	local enableSaveLoadPresetButtonsFn

	local buttonHolder = UiWeightLayout()
		:padding(18)
		:width(1):heightpx(buttonLayout.parent.h)

	local buttonLayoutLeft = UiBoxLayout()
		:hgap(20)
		:height(1)
		:addTo(buttonHolder)

	-- Space filler
	Ui():width(1):addTo(buttonHolder):setTranslucent(true)

	-- Enable all button
	sdlext.buildButton(
		GetText("ConfigureWeaponDeck_EnableAll_Title"),
		GetText("ConfigureWeaponDeck_EnableAll_Tooltip"),
		function()
			for _, button in ipairs(buttons) do
				button.checked = true
			end
			enableSaveLoadPresetButtonsFn(true)
		end
	):addTo(buttonLayoutLeft)

	-- Disable all button
	sdlext.buildButton(
		GetText("ConfigureWeaponDeck_DisableAll_Title"),
		GetText("ConfigureWeaponDeck_DisableAll_Tooltip"),
		function()
			for _, button in ipairs(buttons) do
				button.checked = false
			end
			enableSaveLoadPresetButtonsFn(true)
		end
	):addTo(buttonLayoutLeft)

	local buttonLayoutRight = UiBoxLayout()
		:hgap(20)
		:height(1)
		:addTo(buttonHolder)

	local presetDropdown = sdlext.buildDropDownButton(
		GetText("ConfigureWeaponDeck_Preset_Title"),
		GetText("ConfigureWeaponDeck_Preset_Tooltip"),
		presets
	):addTo(buttonLayoutRight)
	presetDropdown.optionSelected:subscribe(function()
		enableSaveLoadPresetButtonsFn(true)
	end)

	-- Load preset button
	local btnLoadPreset = sdlext.buildButton(
		GetText("ConfigureWeaponDeck_PresetLoad_Title"),
		GetText("ConfigureWeaponDeck_PresetLoad_Tooltip"),
		function()
			local presetId = presets[presetDropdown.value]
			loadPreset(presetId)
			enableSaveLoadPresetButtonsFn(false)
 		end
	):addTo(buttonLayoutRight)

	-- Save preset button
	local btnSavePreset = sdlext.buildButton(
		GetText("ConfigureWeaponDeck_PresetSave_Title"),
		GetText("ConfigureWeaponDeck_PresetSave_Tooltip"),
		function()
			local presetId = presets[presetDropdown.value]
			if presetId ~= PRESET_DEFAULT then
				savePreset(presetId)
			end
			enableSaveLoadPresetButtonsFn(false)
		end
	):addTo(buttonLayoutRight)
	btnSavePreset.disabled = true

	enableSaveLoadPresetButtonsFn = function(enable)
		local presetId = presets[presetDropdown.value]

		if enable then
			-- vanilla and random cannot save, new cannot load
			btnSavePreset.disabled = presetId == PRESET_DEFAULT or presetId == PRESET_RANDOM
			btnLoadPreset.disabled = presetId == PRESET_NEW
		else
			-- random can always load
			btnSavePreset.disabled = true
			btnLoadPreset.disabled = presetId ~= PRESET_RANDOM
		end
	end

	-- Register event handlers
	changePresets:subscribe(function(presetId)
		-- Regenerate dropdown options
		local values = {}
		for i = 1, #presets do
			values[#values+1] = i
		end
		presetDropdown:updateOptions(values, presets)

		-- Update selection
		presetDropdown.value = list_indexof(presets, presetId)
		enableSaveLoadPresetButtonsFn(true)
	end)

	weaponButtonClicked:subscribe(function(weaponButton)
		enableSaveLoadPresetButtonsFn(true)
	end)

	-- Return a parent-less ui element - doing so signals to the dialog builder function
	-- that we want to use a custom layout.
	return buttonHolder
end

--- Called on exit to save the weapon order
local function onExit(self)
	-- update in library
	local enabledMap = {}
	local any = false
	for _, button in ipairs(buttons) do
		enabledMap[button.id] = button.checked
		if button.checked then any = true end
	end

	-- no weapons selected will fallback to vanilla logic, so replace with vanilla weapons
	if not any then
		for id, enabled in pairs(enabledMap) do
			enabledMap[id] = modApi:isDefaultWeapon(id)
		end
	end

	-- update in game
	for id, enabled in pairs(enabledMap) do
		modApi.weaponDeck[id] = enabled
	end

	-- update in config
	sdlext.config(modApi:getCurrentModcontentPath(), function(config)
		config.shopWeaponsEnabled = enabledMap
	end)

	buttons = nil
	presets = nil
	weaponButtonClicked:unsubscribeAll()
	changePresets:unsubscribeAll()
end

--[[
	Logic to create the actual weapon UI
--]]
local function createUi()
	WEAPON_FONT = sdlext.font("fonts/NunitoSans_Regular.ttf", 10)

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frame = sdlext.buildButtonDialog(
			GetText("ModContent_Button_ConfigureWeaponDeck"),
			buildContent,
			buildButtons,
			{
				maxW = 0.8 * ScreenSizeX(),
				maxH = 0.8 * ScreenSizeY(),
				compactW = true,
				compactH = true
			}
		)

		frame:addTo(ui)
			 :pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
	end)
end

function ConfigureWeaponDeck()
	loadWeaponDeck()

	createUi()
end

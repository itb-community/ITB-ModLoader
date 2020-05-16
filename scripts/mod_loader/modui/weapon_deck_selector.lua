-- dimensions of a button
local CHECKBOX = 25
local TEXT_PADDING = 18
local WEAPON_WIDTH = 120 + 8
local WEAPON_HEIGHT = 80 + 8 + TEXT_PADDING
-- button spacing
local WEAPON_GAP = 16
local CELL_WIDTH = WEAPON_WIDTH + WEAPON_GAP
local PADDING = 12
local BUTTON_HEIGHT = 40

--- Cache of recolored images for each palette ID
local surfaces = {}

--- Extra UI components
local WEAPON_FONT = sdlext.font("fonts/NunitoSans_Regular.ttf", 10)
local MOD_COLOR = sdl.rgb(50, 125, 75)

--[[--
	Gets the name for a weapon
	@param id	Weapon ID
	@return Weapon name
]]
local function getWeaponKey(id, key)
	assert(type(id) == "string", "ID must be a string")
	assert(type(key) == "string", "Key must be a string")
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
	assert(type(id) == "string", "ID must be a string")
	local surface = surfaces[id]
	if not surface then
		local weapon = _G[id]
		assert(type(weapon) == "table", "Missing weapon from shop")
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
local PRESET_WIDTH = 2
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

--[[--
	Logic to create the actual weapon UI
]]
local function createUi()
	-- load old config and available presets, used for the new item display
	local oldConfig = {}
	local presets = {}
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

	--- list of all weapon buttons in the UI
	local buttons = {}

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
	end

	--- saves a preset to the config file
	local setPreset --- function will be defined later
	local function savePreset(presetId)
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
			assert(presetId ~= PRESET_NEW)
			-- add to the dropdown
			table.insert(presets, #presets, presetId)
			setPreset(presetId)
			-- if full, remove new
			if #presets == #ALL_PRESETS + 2 then
				remove_element(PRESET_NEW, presets)
			end
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
			setPreset(PRESET_NEW)
			remove_element(presetId, presets)
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
			return false
		end
		-- randomly enable preset
		if presetId == PRESET_RANDOM then
			for _, button in ipairs(buttons) do
				button.checked = math.random() > 0.5
			end
			return true
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
		return true
	end

	-- main UI logic
	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		-- main frame
		local frametop = Ui()
			:width(0.8):height(0.8)
			:posCentered()
			:caption(GetText("ModContent_Button_ConfigureWeaponDeck"))
			:decorate({ DecoFrameHeader(), DecoFrame() })
			:addTo(ui)
		-- scrollable content
		local scrollArea = UiScrollArea()
			:width(1):height(1)
			:addTo(frametop)
		-- subelement to ensure classes automatically are aligned to the right heights
		local allClassArea = UiBoxLayout()
			:width(1)
			:vgap(PADDING)
			:addTo(scrollArea)
		-- define the window size to fit as many weapons as possible, comes out to about 5
		local weaponsPerRow = math.floor(ui.w * frametop.wPercent / CELL_WIDTH)
		frametop
			:width((weaponsPerRow * CELL_WIDTH + (2 * PADDING)) / ui.w)
			:posCentered()
		ui:relayout()

		-- line separating button area
		local line = Ui()
			:width(1):heightpx(frametop.decorations[1].bordersize)
			:decorate({ DecoSolid(frametop.decorations[1].bordercolor) })
			:addTo(frametop)
		-- vertical layout for left and right aligned buttons
		local buttonLayout = UiBoxLayout()
			:vgap(-BUTTON_HEIGHT) -- negative padding will make both elements go at the same height
			:padding(24)
			:width(1)
			:addTo(frametop)
		scrollArea:heightpx(scrollArea.h - (BUTTON_HEIGHT + buttonLayout.padt + buttonLayout.padb + line.h))
		line:pospx(0, scrollArea.y + scrollArea.h)
		buttonLayout:pospx(0, line.y + line.h)

		--- function defined in addPresetButtons that enables the save and load buttons
		local enableSaveLoad
		local size = weaponsPerRow > 6 and 1.5 or 1

		-- adds buttons for enabling and disabling
		local function addEnableDisableButtons()
			-- Button to enable all weapons
			local buttonLayoutLeft = UiBoxLayout()
				:hgap(20)
				:heightpx(BUTTON_HEIGHT)
				:addTo(buttonLayout)
			buttonLayoutLeft.alignH = "left"
			local enableAllButton = Ui()
				:widthpx(WEAPON_WIDTH * size):heightpx(BUTTON_HEIGHT)
				:settooltip(GetText("ConfigureWeaponDeck_EnableAll_Tooltip"))
				:decorate({
					DecoButton(),
					DecoAlign(0, 2),
					DecoText(GetText("ConfigureWeaponDeck_EnableAll_Title")),
				})
				:addTo(buttonLayoutLeft)
			function enableAllButton.onclicked()
				for _, button in ipairs(buttons) do
					button.checked = true
				end
				enableSaveLoad(true)
				return true
			end
			--- Button to disable all weapons
			local disableAllButton = Ui()
				:widthpx(WEAPON_WIDTH * size):heightpx(BUTTON_HEIGHT)
				:settooltip(GetText("ConfigureWeaponDeck_DisableAll_Tooltip"))
				:decorate({
					DecoButton(),
					DecoAlign(0, 2),
					DecoText(GetText("ConfigureWeaponDeck_DisableAll_Title")),
				})
				:addTo(buttonLayoutLeft)
			function disableAllButton.onclicked()
				for _, button in ipairs(buttons) do
					button.checked = false
				end
				enableSaveLoad(true)
				return true
			end
		end

		--- adds buttons to control presets
		local function addPresetButtons()
			-- dropdown to choose a preset
			local buttonLayoutRight = UiBoxLayout()
				:hgap(20)
				:heightpx(BUTTON_HEIGHT)
				:addTo(buttonLayout)
			buttonLayoutRight.alignH = "right"
			local presetDropdown = UiDropDown(presets)
				:widthpx(WEAPON_WIDTH * PRESET_WIDTH):heightpx(BUTTON_HEIGHT)
				:settooltip(GetText("ConfigureWeaponDeck_Preset_Tooltip"))
				:decorate({
					DecoButton(),
					DecoAlign(0, 2),
					DecoText(GetText("ConfigureWeaponDeck_Preset_Title")),
					DecoDropDownText(nil, nil, nil, 33),
					DecoAlign(0, -2),
					DecoDropDown(),
				})
				:addTo(buttonLayoutRight)
			function presetDropdown:destroyDropDown()
				UiDropDown.destroyDropDown(self)
				enableSaveLoad(true)
			end
			--- localized earlier before savePreset
			function setPreset(id)
				presetDropdown.value = id
			end
			--- loads the current preset
			size = size / 2
			local loadPresetButton = Ui()
				:widthpx(WEAPON_WIDTH * size):heightpx(BUTTON_HEIGHT)
				:settooltip(GetText("ConfigureWeaponDeck_PresetLoad_Tooltip"))
				:decorate({
					DecoButton(),
					DecoAlign(0, 2),
					DecoText(GetText("ConfigureWeaponDeck_PresetLoad_Title")),
				})
				:addTo(buttonLayoutRight)
			function loadPresetButton.onclicked()
				loadPreset(presetDropdown.value)
				enableSaveLoad(false)
				return true
			end
			--- Saves the current preset
			local savePresetButton = Ui()
				:widthpx(WEAPON_WIDTH * size):heightpx(BUTTON_HEIGHT)
				:settooltip(GetText("ConfigureWeaponDeck_PresetSave_Tooltip"))
				:decorate({
					DecoButton(),
					DecoAlign(0, 2),
					DecoText(GetText("ConfigureWeaponDeck_PresetSave_Title")),
				})
				:addTo(buttonLayoutRight)
			savePresetButton.disabled = true
			function savePresetButton.onclicked()
				local value = presetDropdown.value
				if value ~= PRESET_DEFAULT then
					savePreset(value)
				end
				enableSaveLoad(false)
				return true
			end
			--- Define function to enable/disable the buttons, localized earlier
			function enableSaveLoad(enable)
				local value = presetDropdown.value
				if enable then
					-- vanilla and random cannot save, new cannot load
					savePresetButton.disabled = value == PRESET_DEFAULT or value == PRESET_RANDOM
					loadPresetButton.disabled = value == PRESET_NEW
				else
					-- random can always load
					savePresetButton.disabled = true
					loadPresetButton.disabled = value ~= PRESET_RANDOM
				end
			end
		end

		-- adds a single weapon button to the class area
		local function addWeaponButton(classArea, weapon)
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
					DecoFixedCAlign(decoName.surface:w(), (decoName.surface:h() - WEAPON_HEIGHT) / 2 + 4),
					decoName,
				})
				:addTo(classArea)
			button.id = id
			button.checked = weapon.enabled
			--- enable the save and load buttons when we make a change
			function button:onclicked()
				enableSaveLoad(true)
				return true
			end
			table.insert(buttons, button)
		end

		-- add in buttons from each class
		addEnableDisableButtons()
		addPresetButtons()
		for _, class in ipairs(getClassList(oldConfig)) do
			-- Header with a smaller font size
			local classHeader = DecoFrameHeader()
			classHeader.font = deco.uifont.default.font
			classHeader.height = 20

			-- local frame for each class, will automatically assign rows and columns
			local classArea = UiFlowLayout()
				:width(1)
				:vgap(WEAPON_GAP):hgap(WEAPON_GAP)
				:padding(PADDING)
				:caption(class.name)
				:decorate({ classHeader, DecoFrame() })
				:addTo(allClassArea)
			classArea.padb = classArea.padb + PADDING
			--- Create a button for each weapon
			for _, weapon in pairs(class.weapons) do
				addWeaponButton(classArea, weapon)
			end
		end
		-- final relayout
		ui:relayout()
	end)
end

function ConfigureWeaponDeck()
	loadWeaponDeck()

	createUi()
end

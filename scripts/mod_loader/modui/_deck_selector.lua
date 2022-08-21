-- shared logic for weapon and pilot decks

local deck_selector = {
  cfg = {
    -- dimensions
    deckWidth = nil,
    deckHeight = nil,
    -- if true, the button includes the title
    showTitleOnButton = false,

    -- key for updating this deck in game
    apiKey = nil,
    -- key for saving this deck to config
    configKey = nil,
    -- key for presets for this deck in config
    presetKey = nil,

    -- value for a fully enabled button
    enabledValue = nil,
    -- value for a fully disabled button
    disabledValue = nil,

    -- function to pack a config table into an integer
    packConfig = nil,
    -- function to unpack a config int into a table
    unpackConfig = nil,

    -- maps the ID to its vanilla config int
    getVanillaConfig = nil,
    -- maps the ID to its default config int
    getDefaultConfig = nil,
    -- maps the ID to a sdl color
    getDeckColor = nil,

    -- maps an ID to a surface component
    getSurface = nil,
    -- function to get text for a deck item
    getText = nil,
    -- function to get the list of classes to display
    getClassList = nil,
    -- default filter to use on load
    default_filter = {},
  },
}

-- constant dimensions of a button
local CHECKBOX = 25
local TEXT_PADDING = 18
-- button spacing
local GAP = 16
local PADDING = 12

local FONT = nil

-- preset names
local PRESET_VANILLA = "Vanilla"
local PRESET_DEFAULT = "Default"
local PRESET_RANDOM  = "Random"
local PRESET_ENABLE_ALL = "Enable All"
local PRESET_DISABLE_ALL = "Disable All"
local PRESET_NEW = "New"
local FIXED_PRESETS = {
	[PRESET_VANILLA] = true,
	[PRESET_DEFAULT] = true,
	[PRESET_RANDOM] = true,
	[PRESET_ENABLE_ALL] = true,
	[PRESET_DISABLE_ALL] = true
}

-- default presets for all letters
local ALL_PRESETS = {}
for i = 1, 26 do ALL_PRESETS[i] = string.char(64+i) end

--- saves a preset to the config file
local changePresets = Event()
local buttonClicked = Event()
local presets
local buttons
-- this represents the packed version of all the checkboxes checked right now
local currentFilter

-- loads the config for the given deck into the mod API
function deck_selector:loadConfigIntoApi(cfg)
  sdlext.config(modApi:getCurrentModcontentPath(), function(config)
		if config[cfg.configKey] ~= nil then
			for id, enabled in pairs(config[cfg.configKey]) do
				if modApi[cfg.apiKey][id] ~= nil then
					modApi[cfg.apiKey][id] = enabled
				end
			end
      cfg.validateEnabled(modApi[cfg.apiKey])
		end
	end)
end

-- loads presets and old values from config
local function loadConfig()
	local presets = {}
	local oldConfig

	sdlext.config(modApi:getCurrentModcontentPath(), function(config)
		oldConfig = config[deck_selector.cfg.configKey] or {}
		if deck_selector.cfg.presetKey ~= nil and config[deck_selector.cfg.presetKey] ~= nil then
			for key in pairs(config[deck_selector.cfg.presetKey]) do
				table.insert(presets, key)
			end
		end
	end)

	-- if not up to Z, support new presets
  if deck_selector.cfg.presetKey ~= nil then
  	table.sort(presets)
  	if #presets < #ALL_PRESETS then
  		table.insert(presets, PRESET_NEW)
  	end
  end
	table.insert(presets, 1, PRESET_DEFAULT)
	table.insert(presets, 2, PRESET_VANILLA)
	table.insert(presets, 3, PRESET_RANDOM)
	table.insert(presets, 4, PRESET_ENABLE_ALL)
	table.insert(presets, 5, PRESET_DISABLE_ALL)

	return presets, oldConfig
end

-- saves a preset
local function savePreset(presetId)
  if deck_selector.cfg.presetKey == nil then return end
	Assert.Equals("string", type(presetId))

	-- no saving vanilla/random
	if FIXED_PRESETS[presetId] then
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
		if #presets == #ALL_PRESETS + 5 then
			remove_element(PRESET_NEW, presets)
		end
		changePresets:dispatch(presetId)
	end

	-- build data to save as an array
	local enabled = {}
	local any = false
	for _, button in ipairs(buttons) do
		local value = deck_selector.cfg.packConfig(button.value)
		if value > 0 then
			enabled[button.id] = value
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
		if enabled ~= nil and config[deck_selector.cfg.presetKey] == nil then
			config[deck_selector.cfg.presetKey] = {}
		end
		config[deck_selector.cfg.presetKey][presetId] = enabled
	end)
end

-- updates the button's checked state and value
local function checkButton(button, newValue)
	for key, update in pairs(currentFilter) do
		if update then
			button.value[key] = newValue
		end
	end
	button.checked = newValue
end

-- updates the button's display to be consistent with the current filter
local function updateButton(button)
	-- if all bits from the mask are set, full
	local all = true
	local any = false
	for key, require in pairs(currentFilter) do
		if require then
			if button.value[key] then
				any = true
			else
				all = false
			end
		end
	end
	-- update based on the discovery
	if all then
		button.checked = true
	elseif any then
		button.checked = "mixed"
	else
		button.checked = false
	end
end

-- updates a button's checked status based on a change in the currentFilter
local function updateButtons()
	for _, button in ipairs(buttons) do
		updateButton(button)
	end
end

--- loads a preset from the config file
local function loadPreset(presetId)
	if presetId == PRESET_NEW then
		return
	end
	-- randomly enable preset
	if presetId == PRESET_RANDOM then
		for _, button in ipairs(buttons) do
			checkButton(button, math.random() > 0.5)
		end
		return
	end
	-- enable all
	if presetId == PRESET_ENABLE_ALL then
		for _, button in ipairs(buttons) do
			checkButton(button, true)
		end
		return
	end
	-- disable all
	if presetId == PRESET_DISABLE_ALL then
		for _, button in ipairs(buttons) do
			checkButton(button, false)
		end
		return
	end

	-- load preset from config
	local getPackedValue
	-- default is a preset
	if presetId == PRESET_VANILLA then
		getPackedValue = function(id) return deck_selector.cfg.getVanillaConfig(id) end
	elseif presetId == PRESET_DEFAULT then
		getPackedValue = function(id) return deck_selector.cfg.getDefaultConfig(id) end
	elseif deck_selector.cfg.presetKey ~= nil then
		-- load preset from config
		local preset = {}
		sdlext.config(modApi:getCurrentModcontentPath(), function(config)
			if config[deck_selector.cfg.presetKey] ~= nil then
				preset = config[deck_selector.cfg.presetKey][presetId] or {}
			end
		end)
		getPackedValue = function(id)
			local value = preset[id]
			if value == true  then return deck_selector.cfg.enabledValue  end
			if value == false then return deck_selector.cfg.disabledValue end
			return value
		end
  else
    getPackedValue = function(id)
      return deck_selector.cfg.disabledValue
    end
	end

	-- update buttons based on the preset
	for _, button in ipairs(buttons) do
		button.value = deck_selector.cfg.unpackConfig(getPackedValue(button.id))
		updateButton(button)
	end

	return
end

-- adds a single weapon button to the class area
local function buildDeckButton(thing)
	local id = thing.id

	-- set color based on where it is found
  local color = deck_selector.cfg.getDeckColor(id)

  local height = deck_selector.cfg.deckHeight + 8
  local surface = deck_selector.cfg.getSurface(thing.id)
  local deco = {
    DecoButton(nil, color),
    DecoAlign(-4, 0),
    DecoSurface(surface)
  }
  if thing.locked then
  	table.insert(deco, DecoAlign(-(PILOT_LOCK:w()+surface:w())/2))
  	table.insert(deco, DecoSurface(PILOT_LOCK))
  end
  table.insert(deco, DecoFixedCAlign(CHECKBOX, height / 2))
  table.insert(deco, DecoTriCheckbox())
  if deck_selector.cfg.showTitleOnButton then
	  local decoName = DecoText(thing.name, FONT)
    height = height + TEXT_PADDING
    deco[2].tSpace = TEXT_PADDING / 2
    deco[4].tOffset = height / 2
    table.insert(deco, DecoFixedCAlign(sdlext.totalWidth(decoName.surface), (decoName.surface:h() - height) / 2 + 4))
    table.insert(deco, decoName)
  end
	local button = UiTriCheckbox()
		:widthpx(deck_selector.cfg.deckWidth + 8)
    :heightpx(height)
		:decorate(deco)
  if thing.description then
		button:settooltip(thing.description, thing.name)
  end

	button.id = id
	button.value = deck_selector.cfg.unpackConfig(thing.enabled)
	updateButton(button)

	--- enable the save and load buttons when we make a change
	button.onToggled:subscribe(function(checked)
		checkButton(button, checked)
		buttonClicked:dispatch(button)
	end)

	return button
end

local function buildClassHolder(classHeaderText)
	local entryBoxHolder = UiBoxLayout()
		:vgap(5)
		:width(1)

	-- Add a collapse button for the class.
	-- This is just a checkbox, but skinned differently.
  local collapseButton = nil
  if classHeaderText then
  	collapseButton = UiCheckbox()
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
  end

	local deckHolder = UiFlowLayout()
		:width(1)
		:vgap(GAP):hgap(GAP)
		:padding(PADDING)
		:addTo(entryBoxHolder)
  if collapseButton then
  	deckHolder.padl = 41
  	sdlext.addButtonSoundHandlers(collapseButton, function()
  		deckHolder.visible = not collapseButton.checked
  	end)
  end

	entryBoxHolder.deckHolder = deckHolder
	return entryBoxHolder
end

-- builds the contents for the selector
local function buildContent(scroll)
	local oldConfig
	presets, oldConfig = loadConfig()
	buttons = {}

	local classesHolder = UiBoxLayout()
		:width(1)
		:vgap(PADDING)
		:padding(PADDING)
		:addTo(scroll)

  -- if only one list, skip class dropdowns
	for _, class in ipairs(deck_selector.cfg.getClassList(oldConfig)) do
		local classHolder = buildClassHolder(class.name)
		classHolder:addTo(classesHolder)

		for _, thing in pairs(class.contents) do
			local button = buildDeckButton(thing)
			button:addTo(classHolder.deckHolder)
			table.insert(buttons, button)
		end
	end
end

-- builds the button area
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

	-- checkboxes
  deck_selector.cfg.buildDropdowns(buttonLayoutLeft, updateButtons, currentFilter)

	local buttonLayoutRight = UiBoxLayout()
		:hgap(20)
		:height(1)
		:addTo(buttonHolder)

	local presetDropdown = sdlext.buildDropDownButton(
		GetText("ConfigureDeck_Preset_Title"),
		GetText("ConfigureDeck_Preset_Tooltip"),
		{
			choices = presets,
			tooltips = {
				GetText("ConfigureDeck_Preset_Tip_Default"),
				GetText("ConfigureDeck_Preset_Tip_Vanilla"),
				GetText("ConfigureDeck_Preset_Tip_Random"),
				GetText("ConfigureDeck_Preset_Tip_EnableAll"),
				GetText("ConfigureDeck_Preset_Tip_DisableAll")
			}
		}
	):addTo(buttonLayoutRight)
	presetDropdown.optionSelected:subscribe(function()
		enableSaveLoadPresetButtonsFn(true)
	end)
	-- TODO I really have no clue the proper way to make the dropdown scroll, all I know is this worked
	presetDropdown.dropdown:heightpx(122)
	presetDropdown.dropdown.children[1].children[1]:dynamicResize(true)

	-- Load preset button
	local btnLoadPreset = sdlext.buildButton(
		GetText("ConfigureDeck_PresetLoad_Title"),
		GetText("ConfigureDeck_PresetLoad_Tooltip"),
		function()
			local presetId = presets[presetDropdown.value]
			loadPreset(presetId)
			enableSaveLoadPresetButtonsFn(false)
 		end
	):addTo(buttonLayoutRight)

	-- Save preset button
	-- TODO: this whole save/load preset thing is quite messy, does not update the dropdown size
	local btnSavePreset = sdlext.buildButton(
		GetText("ConfigureDeck_PresetSave_Title"),
		GetText("ConfigureDeck_PresetSave_Tooltip"),
		function()
			local presetId = presets[presetDropdown.value]
			if not FIXED_PRESETS[presetId] then
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
			btnSavePreset.disabled = FIXED_PRESETS[presetId] == true
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

	buttonClicked:subscribe(function(weaponButton)
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
	for _, button in ipairs(buttons) do
		enabledMap[button.id] = deck_selector.cfg.packConfig(button.value)
	end

  deck_selector.cfg.validateEnabled(enabledMap)

	-- update in game
	for id, enabled in pairs(enabledMap) do
		modApi[deck_selector.cfg.apiKey][id] = enabled
	end

	-- update in config
	sdlext.config(modApi:getCurrentModcontentPath(), function(config)
		config[deck_selector.cfg.configKey] = enabledMap
	end)

	buttons = nil
	presets = nil
	buttonClicked:unsubscribeAll()
	changePresets:unsubscribeAll()
  deck_selector.cfg.onExit()
end

--[[
	Logic to create the actual weapon UI
--]]
function deck_selector:createUi(titleKey, cfg)
	deck_selector.cfg = cfg
	FONT = sdlext.font("fonts/NunitoSans_Regular.ttf", 10)
  PILOT_LOCK = sdlext.getSurface({ path = "img/main_menus/lock.png" })


  -- reset the filter
  currentFilter = {}
  for key, value in pairs(cfg.default_filter) do
    currentFilter[key] = value
  end

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frame = sdlext.buildButtonDialog(
			GetText(titleKey),
			buildContent,
			buildButtons,
			{
				maxW = 0.8 * ScreenSizeX(),
				maxH = 0.7 * ScreenSizeY(),
				compactW = true,
				compactH = true
			}
		)

		frame:addTo(ui):pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2 - 0.05 * ScreenSizeY())
	end)
end

return deck_selector

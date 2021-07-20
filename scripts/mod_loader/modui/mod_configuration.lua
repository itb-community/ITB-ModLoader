--[[
	Adds a new entry to the "Mod Content" menu, allowing to view a
	list of all available mods, as well as inspect and modify any
	options they have defined.
--]]

deco.surfaces.config_checked = sdlext.getSurface({ path = "resources/mods/ui/config-checked.png" })
deco.surfaces.config_unchecked = sdlext.getSurface({ path = "resources/mods/ui/config-unchecked.png" })

local currentSelectedOptions = nil
local scrollContent = nil
local openDropdowns = nil
local sortMods = nil

local SORT_BY_NAME = 1
local SORT_BY_ID = 2
local SORT_ENABLED_FIRST = 1
local SORT_ENABLED_LAST = 2

local function saveModConfig()
	local saveConfig = function(obj)
		obj.modOptions = mod_loader:getCurrentModContent()
		obj.modOrder = mod_loader:getCurrentModOrder()
	end

	local modcontent = modApi:getCurrentModcontentPath()

	sdlext.config(modcontent, saveConfig)
end

-- builds a lightweight mirror of mod options,
-- with only the values we want to be able to edit.
local function buildLightModOptions()
	local config_current = mod_loader:getModConfig()
	local lightModOptions = {}
	
	for id, entry in pairs(mod_loader.mod_options) do
		entry_current = config_current[id]
		local options = {}
		lightModOptions[id] = {
			enabled = entry_current.enabled,
			options = options,
			version = entry.version
		}
		
		for i, opt in ipairs(entry.options) do
			local opt_current = entry_current.options[opt.id]
			if opt.check then
				options[i] = { enabled = opt_current.enabled }
			else
				options[i] = { value = opt_current.value }
			end
		end
	end
	
	return lightModOptions
end

-- builds a new mod content object with
-- our newly configured mod options.
local function buildNewModContent()
	local modContent = {}
	
	for id, entry in pairs(mod_loader.mod_options) do
		local entry_editable = currentSelectedOptions[id]
		local options = {}
		modContent[id] = {
			enabled = entry_editable.enabled,
			options = options,
			version = entry.version
		}
		
		if modContent[id].enabled then
			for i, opt in ipairs(entry.options) do
				local opt_editable = entry_editable.options[i]
				if opt.check then
					options[opt.id] = { enabled = opt_editable.enabled }
				else
					options[opt.id] = { value = opt_editable.value }
				end
			end
		end
	end
	
	return modContent
end

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showRestartReminder = false
		SaveModLoaderConfig(CurrentModLoaderConfig())
	end
end

local function getDisplayName(mod)
	return mod.name
end

local function getDisplayDescription(mod)
	local r = mod.description
	if mod.version then
		if r == nil then
			r = ""
		else
			r = r .."\n"
		end
		r = r .."v".. mod.version
	end
	return r
end

local function isDescendantOf(child, parent)
	while child.parent do
		child = child.parent
		
		if child == parent then
			return true
		end
	end
	
	return false
end

local function closeDropdown(self)
	if not list_contains(openDropdowns, self) then
		return
	end
	
	remove_element(openDropdowns, self)

	self.dropdownHolder:hide()
	self.checked = false
end

local function openDropdown(self)
	if not list_contains(openDropdowns, self) then
		table.insert(openDropdowns, self)
	end

	self.dropdownHolder:show()
end

local function sortChildren(self, sortBy, sortOrder)
	if sortBy == SORT_BY_NAME then
		stablesort(self.children, function(a, b)
			return alphanum(a.mod.name:lower(), b.mod.name:lower())
		end)
	elseif sortBy == SORT_BY_ID then
		stablesort(self.children, function(a, b)
			return alphanum(a.mod.id:lower(), b.mod.id:lower())
		end)
	end
	
	if sortOrder == SORT_ENABLED_FIRST then
		stablesort(self.children, function(a,b)
			return a.modEntry.checked and not b.modEntry.checked
		end)
	elseif sortOrder == SORT_ENABLED_LAST then
		stablesort(self.children, function(a,b)
			return not a.modEntry.checked and b.modEntry.checked
		end)
	end
	
	for _, child in ipairs(self.children) do
		if child.nestedEntriesHolder then
			child.nestedEntriesHolder:sortChildren(sortBy, sortOrder)
		end
	end
end

local function clickConfiguration(self, button)
	if button == 1 then
		if #openDropdowns > 0 then
			for _, dropdown in ipairs(openDropdowns) do
				if dropdown ~= self then
					if isDescendantOf(dropdown.owner, self.owner) then
						closeDropdown(dropdown)
					end
				end
			end
		end
		
		if self.checked then
			openDropdown(self)
		else
			closeDropdown(self)
		end
		
		return true
	end
	
	return false
end

local function buildOptionCheckbox(mod)

	local optionBox = UiCheckbox()
		:widthpx(41):heightpx(41)
		:decorate({
			DecoButton(),
			DecoCheckbox(
				deco.surfaces.config_checked,
				deco.surfaces.config_unchecked,
				deco.surfaces.config_checked,
				deco.surfaces.config_unchecked
			)
		})

	optionBox.onclicked = clickConfiguration

	return optionBox
end

local function buildOptionEntries(mod)
	local entry = mod_loader.mod_options[mod.id]
	local entry_editable = currentSelectedOptions[mod.id]
	
	local optionsHolder = UiBoxLayout()
		:vgap(5)
		:width(0.965)
	optionsHolder.alignH = "right"
	
	for i, opt in ipairs(entry.options) do
		local opt_editable = entry_editable.options[i]
		local optionEntry
		
		if opt.check then
			optionEntry = UiCheckbox()
				:width(1):heightpx(41)
				:settooltip(opt.tip)
				:decorate({
					DecoButton(),
					DecoAlign(0, 2),
					DecoText(opt.name),
					DecoAlign(0, -2),
					DecoRAlign(33),
					DecoCheckbox()
				})
			
			optionEntry.checked = opt_editable.enabled
			
			optionEntry.onclicked = function(self, button)
				if button == 1 then
					opt_editable.enabled = self.checked
					
					return true
				end
				
				return false
			end
		else
			optionEntry = UiDropDown(opt.values, opt.strings, opt_editable.value)
				:width(1):heightpx(41)
				:settooltip(opt.tip)
				:decorate({
					DecoButton(),
					DecoAlign(0, 2),
					DecoText(opt.name),
					DecoDropDownText(nil, nil, nil, 33),
					DecoAlign(0, -2),
					DecoDropDown()
				})
				
			optionEntry.optionSelected:subscribe(function(_, _, choice, value)
				opt_editable.value = value
			end)
		end
		
		optionEntry
			:addTo(optionsHolder)
	end
	
	return optionsHolder
end

local function buildModEntry(mod, parentModEntry)
	local entry = mod_loader.mod_options[mod.id]
	local entry_editable = currentSelectedOptions[mod.id]
	
	local modHasChildren = mod.children ~= nil and #mod.children > 0
	local modHasParent = mod.parent ~= nil
	
	local uiTriCheckbox = UiCheckbox
	local decoTriCheckbox = DecoCheckbox
	local nestedEntriesHolder = nil
	
	local entryBoxHolder = UiBoxLayout()
		:vgap(5)
		:width(1)
		
	local entryHeaderHolder = UiWeightLayout()
		:width(1):heightpx(41)
		:addTo(entryBoxHolder)
		
	if modHasChildren then
		uiTriCheckbox = UiTriCheckbox
		decoTriCheckbox = DecoTriCheckbox
		
		-- Add a collapse button for nested mods.
		-- This is just a checkbox, but skinned differently.
		local collapse = UiCheckbox()
			:widthpx(41):heightpx(41)
			:decorate({
				DecoButton(),
				DecoCheckbox(
					deco.surfaces.dropdownOpenRight,
					deco.surfaces.dropdownClosed,
					deco.surfaces.dropdownOpenRightHovered,
					deco.surfaces.dropdownClosedHovered
				)
			})
			:addTo(entryHeaderHolder)
		
		nestedEntriesHolder = UiBoxLayout()
			:vgap(5)
			:width(1)
			:hide()
		
		collapse.onclicked = clickConfiguration
		collapse.dropdownHolder = nestedEntriesHolder
		collapse.owner = entryBoxHolder
		
		entryBoxHolder.nestedEntriesHolder = nestedEntriesHolder
		nestedEntriesHolder.sortChildren = sortChildren
	end
	
	local modEntry = uiTriCheckbox()
		:width(1):heightpx(41)
		:settooltip(getDisplayDescription(mod))
		:decorate({
			DecoButton(),
			decoTriCheckbox(),
			DecoSurfaceOutlined(
				sdlext.getSurface({ path = mod.icon or "resources/mods/squads/unknown.png" }),
				nil,
				nil,
				nil,
				1
			),
			DecoAlign(0, 2),
			DecoText(getDisplayName(mod))
		})
		:addTo(entryHeaderHolder)
	
	entryBoxHolder.mod = mod
	entryBoxHolder.modEntry = modEntry
	modEntry.checked = entry_editable.enabled
	
	modEntry.updateChildrenCheckedState = function(self)
		if not modHasChildren then return end
		
		for _, entryBoxHolder in ipairs(nestedEntriesHolder.children) do
			entryBoxHolder.modEntry.checked = self.checked
			entryBoxHolder.modEntry:updateCheckedState()
			entryBoxHolder.modEntry:updateChildrenCheckedState()
		end
	end
	
	modEntry.updateParentCheckedState = function(self)
		if not modHasChildren then return end
		
		local count = 0
		for i, entryBoxHolder in ipairs(nestedEntriesHolder.children) do
			local entry = entryBoxHolder.modEntry
			
			if entry.checked == true then
				count = count + 1
			elseif entry.checked == false or entry.checked == nil then
				count = count - 1
			end
			
			if math.abs(count) ~= i then
				break
			end
		end
		
		if count == #nestedEntriesHolder.children then
			self.checked = true
		elseif count == -#nestedEntriesHolder.children then
			self.checked = false
		else
			self.checked = "mixed"
		end
		
		self:updateCheckedState()
		
		if modHasParent then
			parentModEntry:updateParentCheckedState()
		end
	end
	
	modEntry.updateCheckedState = function(self)
		entry_editable.enabled = self.checked ~= false and self.checked ~= nil
	end
	
	modEntry.onclicked = function(self, button)
		if button == 1 then
			self:updateCheckedState()
			self:updateChildrenCheckedState()
			
			if modHasParent then
				parentModEntry:updateParentCheckedState()
			end
		end
		
		return false
	end
	
	if #entry.options > 0 then
		local optionBox = buildOptionCheckbox(mod)
			:addTo(entryHeaderHolder)
		local optionEntries = buildOptionEntries(mod)
			:hide()
			:addTo(entryBoxHolder)
		
		optionBox.dropdownHolder = optionEntries
		optionBox.owner = entryBoxHolder
	end
	
	if modHasParent then
		entryBoxHolder.padl = 46
	end
	
	-- Recursively build ui elements for nested mods in this modpack
	if modHasChildren then
		
		nestedEntriesHolder:addTo(entryBoxHolder)
		
		for _, submod_id in ipairs(mod.children) do
			local submod = mod_loader.mods[submod_id]
			local uiSubmod = buildModEntry(submod, modEntry)
				:addTo(nestedEntriesHolder)
		end
		
		modEntry:updateParentCheckedState()
	end
	
	return entryBoxHolder
end

local function buildModConfigContent(scroll)
	
	if currentSelectedOptions == nil then
		currentSelectedOptions = buildLightModOptions()
	end
	
	openDropdowns = {}
	
	scrollContent = UiBoxLayout()
		:vgap(5)
		:width(1)
		:height(1)
		:addTo(scroll)
	
	for id, option in pairs(mod_loader.mod_options) do
		if mod_loader:hasMod(id) then
			local mod = mod_loader.mods[id]
			if mod.parent == nil then
				buildModEntry(mod)
					:addTo(scrollContent)
			end
		end
	end
	
	scrollContent.sortChildren = sortChildren
end

local function buildModConfigButtons(buttonLayout)
	local sortBy = 1
	local sortOrder = 1
	
	local btnSortBy = sdlext.buildDropDownButton(
		GetText("ModConfig_Button_Sort_Title"),
		GetText("ModConfig_Button_Sort_Tooltip"),
		{
			GetText("ModConfig_Button_Sort_Choice_1"),
			GetText("ModConfig_Button_Sort_Choice_2")
		},
		function(choice)
			sortBy = choice
			scrollContent:sortChildren(sortBy, sortOrder)
		end
	)
	
	btnSortBy
		:addTo(buttonLayout)
		
	local btnSortOrder = sdlext.buildDropDownButton(
		GetText("ModConfig_Button_Sort_Enabled_Mods_Title"),
		GetText("ModConfig_Button_Sort_Enabled_Mods_Tooltip"),
		{
			GetText("ModConfig_Button_Sort_Enabled_Mods_Choice_1"),
			GetText("ModConfig_Button_Sort_Enabled_Mods_Choice_2"),
			GetText("ModConfig_Button_Sort_Enabled_Mods_Choice_3")
		},
		function(choice)
			sortOrder = choice
			scrollContent:sortChildren(sortBy, sortOrder)
		end
	)
	
	btnSortOrder
		:addTo(buttonLayout)
	
	scrollContent:sortChildren(sortBy, sortOrder)
end

local function showModConfig()

	local onExit = function(self)
		
		local mod_content_new = buildNewModContent()
		
		local savedOrder = mod_loader:getSavedModOrder()
		local orderedMods = mod_loader:orderMods(mod_content_new, savedOrder)
		
		local initializedCount = 0
		for i, id in ipairs(orderedMods) do
			if not mod_loader.mods[id].initialized then
				initializedCount = initializedCount + 1
			end
		end

		mod_loader:loadModContent(mod_content_new, savedOrder)

		saveModConfig()

		-- If we have any new mods that weren't previously initialized,
		-- then we need to restart the game to apply them correctly.
		-- Otherwise they're not gonna work (will be loaded without
		-- being initialized first)
		-- We can't initialize mods here, because some required vars
		-- are gone by this point (eg. Pawn), or the game has already
		-- compiled cached lists which we can't modify anyway.
		if modApi.showRestartReminder and initializedCount > 0 then
			sdlext.showButtonDialog(
				GetText("RestartRequired_FrameTitle"),
				GetText("RestartRequired_FrameText"),
				responseFn,
				{ GetText("Button_Ok"), GetText("Button_DisablePopup") },
				{ "", GetText("ButtonTooltip_DisablePopup") }
			)
		end
	end
	
	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frame = sdlext.buildButtonDialog(
			GetText("ModConfig_FrameTitle"),
			buildModConfigContent,
			buildModConfigButtons,
			{
				maxW = 0.6 * ScreenSizeX(),
				maxH = 0.8 * ScreenSizeY(),
				compactH = false
			}
		)
		
		frame:addTo(ui)
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
	end)
end

function ConfigureMods()
	loadSquadSelection()
	
	showModConfig()
end

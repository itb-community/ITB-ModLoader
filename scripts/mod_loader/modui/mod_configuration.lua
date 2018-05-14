--[[
	Adds a new entry to the "Mod Content" menu, allowing to view a
	list of all available mods, as well as inspect and modify any
	options they have defined.
--]]

local function saveModConfig()
	sdlext.config("modcontent.lua", function(obj)
		obj.modOptions = mod_loader:getCurrentModContent()
		obj.modOrder = mod_loader:getCurrentModOrder()
	end)
end

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showRestartReminder = false
		saveModLoaderConfig()
	end
end

local function createUi()
	local checkboxes = {}
	local configboxes = {}
	local optionboxes = {}
	local mod_options = mod_loader.mod_options
	local modSelection = mod_loader:getModConfig()

	local onExit = function(self)
		modSelection = {}
		
		for i, checkbox in ipairs(checkboxes) do
			local options = {}
			modSelection[checkbox.modId] = {
				enabled = checkbox.checked,
				options = options,
				version = mod_options[checkbox.modId].version,
			}
			
			if optionboxes[i] and checkbox.checked then
				for j, option in ipairs(optionboxes[i]) do
					if option.data.check then
						options[option.data.id] = {enabled = option.checked}
					else
						options[option.data.id] = {value = option.value}
					end
				end
			end
		end
		
		local savedOrder = mod_loader:getSavedModOrder()
		local orderedMods = mod_loader:orderMods(modSelection, savedOrder)

		local initializedCount = 0
		for i, id in ipairs(orderedMods) do
			if not mod_loader.mods[id].initialized then
				initializedCount = initializedCount + 1
			end
		end

		mod_loader:loadModContent(modSelection, savedOrder)

		saveModConfig()

		-- If we have any new mods that weren't previously initialized,
		-- then we need to restart the game to apply them correctly.
		-- Otherwise they're not gonna work (will be loaded without
		-- being initialized first)
		-- We can't initialize mods here, because some required vars
		-- are gone by this point (eg. Pawn), or the game has already
		-- compiled cached lists which we can't modify anyway.
		if modApi.showRestartReminder and initializedCount > 0 then
			sdlext.showAlertDialog(
				"Information",
				"You have enabled one or more mods. In order to apply them, game restart is required.",
				responseFn, nil, nil,
				"OK", "GOT IT, DON'T TELL ME AGAIN"
			)
		end
	end

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frametop = Ui()
			:width(0.6):height(0.575)
			:posCentered()
			:caption("Mod Configuration")
			:decorate({
				DecoFrameHeader(),
				DecoFrame()
			})
			:addTo(ui)

		local scrollarea = UiScrollArea()
			:width(1):height(1)
			:padding(12)
			:addTo(frametop)

		local entryHolder = UiBoxLayout()
			:vgap(5)
			:width(1)
			:addTo(scrollarea)

		ui:relayout()
		
		local configuringMod = nil
		
		local function clickConfiguration(self, button)
			if button == 1 then
				if configuringMod then
					local numOptions = #optionboxes[configuringMod]
					
					for i, optionbox in pairs(optionboxes[configuringMod]) do
						optionbox:hide()
					end
					
					configboxes[configuringMod].decorations[2].surface = sdl.surface("resources/mods/ui/config-unchecked.png")
				end
				
				if self.configi == configuringMod then
					configuringMod = nil
				else
					configuringMod = self.configi
					local numOptions = #optionboxes[configuringMod]
					
					configboxes[configuringMod].decorations[2].surface = sdl.surface("resources/mods/ui/config-checked.png")
					
					for i, optionbox in pairs(optionboxes[configuringMod]) do
						optionbox:show()
					end
				end
				
				scrollarea:relayout()
				return true
			end
			return false
		end

		local getDisplayName = function(mod)
			local r = mod.name
			if mod.version then
				r = r .. "  v".. mod.version
			end
			return r
		end
		
		for id, option in pairs(mod_options) do
			if mod_loader:hasMod(id) then
				local mod = mod_loader.mods[id]
				
				if #option.options > 0 then
					local entryBox = UiBoxLayout()
						:vgap(0)
						:width(1)
						:addTo(entryHolder)

					local entryHeader = UiBoxLayout()
						:hgap(5)
						:heightpx(41)
						:addTo(entryBox)

					local checkbox = UiCheckbox()
						:widthpx((scrollarea.w - scrollarea.padl - scrollarea.padr) - 46)
						:heightpx(41)
						:decorate({
							DecoButton(),
							DecoCheckbox(),
							DecoSurfaceOutlined(
								sdlext.surface(mod.icon or "resources/mods/squads/unknown.png"),
								nil,
								nil,
								nil,
								1
							),
							DecoText(getDisplayName(mod))
						})
						:addTo(entryHeader)
					
					checkbox.modId = id
					checkbox.checked = modSelection[id].enabled
					table.insert(checkboxes, checkbox)
					
					local configbox = UiCheckbox()
						:widthpx(41):heightpx(41)
						:decorate({
							DecoButton(),
							DecoSurface(sdl.surface("resources/mods/ui/config-unchecked.png"))
						})
						:addTo(entryHeader)
					
					configbox.configi = #checkboxes
					configbox.onclicked = clickConfiguration
					configboxes[configbox.configi] = configbox
					optionboxes[configbox.configi] = {}

					local optionsHolder = UiBoxLayout()
						:vgap(5)
						:width(0.965)
						:addTo(entryBox)
					optionsHolder.padt = 5
					optionsHolder.alignH = "right"

					for i, opt in ipairs(option.options) do
						local optionbox
						
						if opt.check then
							optionbox = UiCheckbox()
								:width(1):heightpx(41)
								:settooltip(opt.tip)
								:decorate({
									DecoButton(),
									DecoText(opt.name),
									DecoRAlign(33),
									DecoCheckbox()
								})
							
							optionbox.checked = modSelection[id].options[opt.id].enabled
						else
							local value = modSelection[id].options[opt.id].value
							optionbox = UiDropDown(opt.values, opt.strings, value)
								:width(1):heightpx(41)
								:settooltip(opt.tip)
								:decorate({
									DecoButton(),
									DecoText(opt.name),
									DecoDropDownText(nil, nil, nil, 33),
									DecoDropDown()
								})
						end
						
						optionbox.data = opt
						
						optionbox:hide()
						optionsHolder:add( optionbox )
						table.insert(optionboxes[configbox.configi], optionbox)
					end
				else
					local checkbox = UiCheckbox()
						:width(1):heightpx(41)
						:decorate({
							DecoButton(),
							DecoCheckbox(),
							DecoSurfaceOutlined(
								sdlext.surface(mod.icon or "resources/mods/squads/unknown.png"),
								nil,
								nil,
								nil,
								1
							),
							DecoText(getDisplayName(mod))
						})
						:addTo(entryHolder)
					
					checkbox.checked = modSelection[id].enabled
					checkbox.modId = id
					table.insert(checkboxes, checkbox)
				end
			end
		end
	end)
end

function configureMods()
	loadSquadSelection()
	
	createUi()
end

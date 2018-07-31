--[[
	Adds a new entry to the "Mod Content" menu, allowing to configure
	some features of the mod loader itself.
--]]

local function createUi()
	local uiScale = GetUiScale()
	local font = sdlext.font("fonts/NunitoSans_Regular.ttf", 12 * uiScale)

	local ddLogLevel = nil
	local cboxCaller = nil
	local cboxErrorFrame = nil
	local cboxResourceError = nil
	local cboxRestartReminder = nil
	local cboxFloatyTooltips = nil

	local onExit = function(self)
		modApi.logger.logLevel        = ddLogLevel.value
		modApi.logger.printCallerInfo = cboxCaller.checked
		modApi.showErrorFrame         = cboxErrorFrame.checked
		modApi.showResourceWarning    = cboxResourceError.checked
		modApi.showRestartReminder    = cboxRestartReminder.checked
		modApi.floatyTooltips         = cboxFloatyTooltips.checked

		saveModLoaderConfig()
	end

	local srfChecked = sdl.scaled(uiScale, deco.surfaces.checkboxChecked)
	local srfUnchecked = sdl.scaled(uiScale, deco.surfaces.checkboxUnchecked)
	local srfHovChecked = sdl.scaled(uiScale, deco.surfaces.checkboxHoveredChecked)
	local srfHovUnchecked = sdl.scaled(uiScale, deco.surfaces.checkboxHoveredUnchecked)

	local srfOpen = sdl.scaled(uiScale, deco.surfaces.dropdownOpen)
	local srfClosed = sdl.scaled(uiScale, deco.surfaces.dropdownClosed)
	local srfHovOpen = sdl.scaled(uiScale, deco.surfaces.dropdownOpenHovered)
	local srfHovClosed = sdl.scaled(uiScale, deco.surfaces.dropdownClosedHovered)

	local createCheckboxOption = function(text, tooltipOn, tooltipOff)
		local cbox = UiCheckbox()
			:width(1):heightpx(41 * uiScale)
			:settooltip(tooltipOn)
			:decorate({
				DecoButton(),
				DecoText(text, font),
				DecoRAlign(8 + srfChecked:w()),
				DecoCheckbox(srfChecked, srfUnchecked, srfHovChecked, srfHovUnchecked)
			})

		cbox.updateTooltip = function(self)
			if tooltipOff then
				self:settooltip(self.checked and tooltipOn or tooltipOff)
				self.root.tooltip = self.tooltip
			end
		end

		cbox.clicked = function(self, button)
			local result = UiCheckbox.clicked(self, button)
			self:updateTooltip()
			return result
		end

		return cbox
	end

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frame = Ui()
			:width(0.5):height(0.4)
			:posCentered()
			:caption("Mod Loader Configuration")
			:decorate({
				DecoFrameHeader(),
				DecoFrame()
			})
			:addTo(ui)

		local scrollarea = UiScrollArea()
			:width(1):height(1)
			:padding(12 * uiScale)
			:addTo(frame)

		local layout = UiBoxLayout()
			:vgap(5 * uiScale)
			:width(1)
			:addTo(scrollarea)

		ddLogLevel = UiDropDown(
				{ 0, 1, 2 },
				{ "None", "Only console", "File and console" },
				modApi.logger.logLevel
			)
			:width(1):heightpx(41 * uiScale)
			:decorate({
				DecoButton(),
				DecoText("Logging Level", font),
				DecoDropDownText(nil, font, nil, 16 * uiScale + srfOpen:w()),
				DecoAlign(10 * uiScale),
				DecoDropDown(srfOpen, srfClosed, srfHovOpen, srfHovClosed)
			})
			:settooltip("Controls where the game's logging messages are printed.")
			:addTo(layout)
		ddLogLevel.dropdownFont = font

		cboxCaller = createCheckboxOption(
			"Print Caller Information",
			"Include timestamp and stacktrace in LOG messages."
		)

		cboxCaller.checked = modApi.logger.printCallerInfo
		cboxCaller:addTo(layout)

		cboxFloatyTooltips = createCheckboxOption(
			"Attach Tooltips To Mouse Cursor",
			"Tooltips follow the mouse cursor around.",
			"Tooltips show to the side of the UI element that spawned them, similar to the game's own tooltips."
		)

		local oldClicked = cboxFloatyTooltips.clicked
		cboxFloatyTooltips.clicked = function(self, button)
			local result = oldClicked(self, button)
			modApi.floatyTooltips = self.checked
			return result
		end
		cboxFloatyTooltips.checked = modApi.floatyTooltips
		cboxFloatyTooltips:updateTooltip()
		cboxFloatyTooltips:addTo(layout)

		cboxErrorFrame = createCheckboxOption(
			"Show Script Error Popup",
			"Show an error popup at startup if a mod fails to mount, init, or load."
		)

		cboxErrorFrame.checked = modApi.showErrorFrame
		cboxErrorFrame:addTo(layout)

		cboxResourceError = createCheckboxOption(
			"Show Resource Error Popup",
			"Show an error popup at startup if the modloader fails to load the game's resources."
		)

		cboxResourceError.checked = modApi.showResourceWarning
		cboxResourceError:addTo(layout)

		cboxRestartReminder = createCheckboxOption(
			"Show Restart Reminder Popup",
			"Show a popup reminding to restart the game when enabling mods."
		)

		cboxRestartReminder.checked = modApi.showRestartReminder
		cboxRestartReminder:addTo(layout)
	end)
end

function configureModLoader()
	applyModLoaderConfig(loadModLoaderConfig())

	createUi()
end

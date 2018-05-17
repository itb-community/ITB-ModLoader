--[[
	Adds a new entry to the "Mod Content" menu, allowing to configure
	some features of the mod loader itself.
--]]

local function createUi()
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

	local createCheckboxOption = function(text, tooltipOn, tooltipOff)
		local cbox = UiCheckbox()
			:width(1):heightpx(41)
			:settooltip(tooltipOn)
			:decorate({
				DecoButton(),
				DecoAlign(0, 2),
				DecoText(text),
				DecoAlign(0, -2),
				DecoRAlign(33),
				DecoCheckbox()
			})

		cbox.clicked = function(self, button)
			local result = UiCheckbox.clicked(self, button)

			if tooltipOff then
				cbox:settooltip(cbox.checked and tooltipOn or tooltipOff)
				cbox.root.tooltip = cbox.tooltip
			end

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
			:padding(12)
			:addTo(frame)

		local layout = UiBoxLayout()
			:vgap(5)
			:width(1)
			:addTo(scrollarea)

		ddLogLevel = UiDropDown(
				{ 0, 1, 2 },
				{ "None", "Only console", "File and console" },
				modApi.logger.logLevel
			)
			:width(1):heightpx(41)
			:decorate({
				DecoButton(),
				DecoAlign(0, 2),
				DecoText("Logging Level"),
				DecoDropDownText(nil, nil, nil, 33),
				DecoAlign(0, -2),
				DecoDropDown()
			})
			:addTo(layout)

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

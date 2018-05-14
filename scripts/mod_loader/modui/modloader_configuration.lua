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

	local onExit = function(self)
		modApi.logger.logLevel        = ddLogLevel.value
		modApi.logger.printCallerInfo = cboxCaller.checked
		modApi.showErrorFrame         = cboxErrorFrame.checked
		modApi.showResourceWarning    = cboxResourceError.checked
		modApi.showRestartReminder    = cboxRestartReminder.checked

		saveModLoaderConfig()
	end

	local createCheckboxOption = function(text, tooltip)
		return UiCheckbox()
			:width(1):heightpx(41)
			:settooltip(tooltip)
			:decorate({
				DecoButton(),
				DecoText(text),
				DecoRAlign(33),
				DecoCheckbox()
			})
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
				DecoText("Logging level"),
				DecoDropDownText(nil, nil, nil, 41),
				DecoDropDown()
			})
			:addTo(layout)

		cboxCaller = createCheckboxOption(
			"Print caller information",
			"Include timestamp and stacktrace in LOG messages."
		)

		cboxCaller.checked = modApi.logger.printCallerInfo
		cboxCaller:addTo(layout)

		cboxErrorFrame = createCheckboxOption(
			"Show script error popup",
			"Show an error popup at startup if a mod fails to mount, init, or load."
		)

		cboxErrorFrame.checked = modApi.showErrorFrame
		cboxErrorFrame:addTo(layout)

		cboxResourceError = createCheckboxOption(
			"Show resource error popup",
			"Show an error popup at startup if the modloader fails to load the game's resources."
		)

		cboxResourceError.checked = modApi.showResourceWarning
		cboxResourceError:addTo(layout)

		cboxRestartReminder = createCheckboxOption(
			"Show restart reminder popup",
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

--[[
	Adds a new entry to the "Mod Content" menu, allowing to configure
	some features of the mod loader itself.
--]]

local function createUi()
	local ddLogLevel = nil
	local cboxCaller = nil
	local cboxFloatyTooltips = nil
	local cboxProfileConfig = nil
	local cboxErrorFrame = nil
	local cboxVersionFrame = nil
	local cboxResourceError = nil
	local cboxRestartReminder = nil

	local onExit = function(self)
		local data = {
			logLevel            = ddLogLevel.value,
			printCallerInfo     = cboxCaller.checked,
			floatyTooltips      = cboxFloatyTooltips.checked,
			profileConfig       = cboxProfileConfig.checked,

			showErrorFrame      = cboxErrorFrame.checked,
			showVersionFrame    = cboxVersionFrame.checked,
			showResourceWarning = cboxResourceError.checked,
			showRestartReminder = cboxRestartReminder.checked
		}

		ApplyModLoaderConfig(data)
		SaveModLoaderConfig(data)
	end

	local uiSetSettings = function(config)
		ddLogLevel.value            = config.logLevel
		ddLogLevel.choice           = ddLogLevel.value + 1
		cboxCaller.checked          = config.printCallerInfo
		cboxFloatyTooltips.checked  = config.floatyTooltips
		cboxProfileConfig.checked   = config.profileConfig

		cboxErrorFrame.checked      = config.showErrorFrame
		cboxVersionFrame.checked    = config.showVersionFrame
		cboxResourceError.checked   = config.showResourceWarning
		cboxRestartReminder.checked = config.showRestartReminder

		local t = cboxFloatyTooltips.root.tooltip
		modApi.floatyTooltips = config.floatyTooltips
		cboxFloatyTooltips:updateTooltip()
		cboxFloatyTooltips.root.tooltip = t
	end

	local checkboxClickFn = function(self, button)
		local result = UiCheckbox.clicked(self, button)
		if self.updateTooltip then self:updateTooltip() end
		return result
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

		cbox.updateTooltip = function(self)
			if tooltipOff then
				self:settooltip(self.checked and tooltipOn or tooltipOff)
				self.root.tooltip = self.tooltip
			end
		end

		cbox.clicked = checkboxClickFn

		return cbox
	end

	local createSeparator = function(h)
		return Ui()
			:width(1):heightpx(h)
	end

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frame = Ui()
			:width(0.6):height(0.575)
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

		-- ////////////////////////////////////////////////////////////////////////
		-- Logging level
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
			:settooltip("Controls where the game's logging messages are printed.")
			:addTo(layout)

		-- ////////////////////////////////////////////////////////////////////////
		-- Caller information
		cboxCaller = createCheckboxOption(
			"Print Caller Information",
			"Include timestamp and stacktrace in LOG messages."
		):addTo(layout)

		-- ////////////////////////////////////////////////////////////////////////
		-- Floaty tooltips
		cboxFloatyTooltips = createCheckboxOption(
			"Attach Tooltips To Mouse Cursor",
			"Tooltips follow the mouse cursor around.",
			"Tooltips show to the side of the UI element that spawned them, similar to the game's own tooltips."
		):addTo(layout)

		cboxFloatyTooltips.clicked = function(self, button)
			local result = checkboxClickFn(self, button)

			modApi.floatyTooltips = self.checked

			return result
		end

		-- ////////////////////////////////////////////////////////////////////////
		-- Profile-specific config
		cboxProfileConfig = createCheckboxOption(
			"Profile-Specific Configuration",
			"Configuration for the mod loader and individual mods will be remembered per profile, instead of globally.\n\nNote: with this option enabled, switching profiles will require you to restart the game to apply the different mod configurations."
		):addTo(layout)

		cboxProfileConfig.clicked = function(self, button)
			local result = checkboxClickFn(self, button)

			local checked = self.checked
			uiSetSettings(LoadModLoaderConfig(checked))
			self.checked = checked

			return result
		end

		-- ////////////////////////////////////////////////////////////////////////
		-- Warning dialogs
		createSeparator(10):addTo(layout)

		cboxErrorFrame = createCheckboxOption(
			"Show Script Error Popup",
			"Show an error popup at startup if a mod fails to mount, init, or load."
		):addTo(layout)

		cboxVersionFrame = createCheckboxOption(
			"Show Mod Loader Outdated Popup",
			"Show a popup if the mod loader is out-of-date for installed mods."
		):addTo(layout)

		cboxResourceError = createCheckboxOption(
			"Show Resource Error Popup",
			"Show an error popup at startup if the mod loader fails to load the game's resources."
		):addTo(layout)

		cboxRestartReminder = createCheckboxOption(
			"Show Restart Reminder Popup",
			"Show a popup reminding to restart the game when enabling mods."
		):addTo(layout)

		uiSetSettings(LoadModLoaderConfig())
	end)
end

function ConfigureModLoader()
	createUi()
end

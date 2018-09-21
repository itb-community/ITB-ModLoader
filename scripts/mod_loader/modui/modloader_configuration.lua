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
	local cboxProfileFrame = nil

	local onExit = function(self)
		local data = {
			logLevel            = ddLogLevel.value,
			printCallerInfo     = cboxCaller.checked,
			floatyTooltips      = cboxFloatyTooltips.checked,
			profileConfig       = cboxProfileConfig.checked,

			showErrorFrame      = cboxErrorFrame.checked,
			showVersionFrame    = cboxVersionFrame.checked,
			showResourceWarning = cboxResourceError.checked,
			showRestartReminder = cboxRestartReminder.checked,
			showProfileSettingsFrame = cboxProfileFrame.checked
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
		cboxProfileFrame.checked    = config.showProfileSettingsFrame

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
			:caption(modApi:getText("FrameTitle_ModLoaderConfig"))
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
				{
					modApi:getText("ModLoaderConfig_LogLevel_DD0"),
					modApi:getText("ModLoaderConfig_LogLevel_DD1"),
					modApi:getText("ModLoaderConfig_LogLevel_DD2")
				},
				modApi.logger.logLevel
			)
			:width(1):heightpx(41)
			:decorate({
				DecoButton(),
				DecoAlign(0, 2),
				DecoText(modApi:getText("ModLoaderConfig_LogLevel_Text")),
				DecoDropDownText(nil, nil, nil, 33),
				DecoAlign(0, -2),
				DecoDropDown()
			})
			:settooltip(modApi:getText("ModLoaderConfig_LogLevel_Tooltip"))
			:addTo(layout)

		-- ////////////////////////////////////////////////////////////////////////
		-- Caller information
		cboxCaller = createCheckboxOption(
			modApi:getText("ModLoaderConfig_Caller_Text"),
			modApi:getText("ModLoaderConfig_Caller_Tooltip")
		):addTo(layout)

		-- ////////////////////////////////////////////////////////////////////////
		-- Floaty tooltips
		cboxFloatyTooltips = createCheckboxOption(
			modApi:getText("ModLoaderConfig_FloatyTooltips_Text"),
			modApi:getText("ModLoaderConfig_FloatyTooltips_Tooltip_On"),
			modApi:getText("ModLoaderConfig_FloatyTooltips_Tooltip_Off")
		):addTo(layout)

		cboxFloatyTooltips.clicked = function(self, button)
			local result = checkboxClickFn(self, button)

			modApi.floatyTooltips = self.checked

			return result
		end

		-- ////////////////////////////////////////////////////////////////////////
		-- Profile-specific config
		cboxProfileConfig = createCheckboxOption(
			modApi:getText("ModLoaderConfig_ProfileConfig_Text"),
			modApi:getText("ModLoaderConfig_ProfileConfig_Tooltip")
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
			modApi:getText("ModLoaderConfig_ScriptError_Text"),
			modApi:getText("ModLoaderConfig_ScriptError_Tooltip")
		):addTo(layout)

		cboxVersionFrame = createCheckboxOption(
			modApi:getText("ModLoaderConfig_OldVersion_Text"),
			modApi:getText("ModLoaderConfig_OldVersion_Tooltip")
		):addTo(layout)

		cboxResourceError = createCheckboxOption(
			modApi:getText("ModLoaderConfig_ResourceError_Text"),
			modApi:getText("ModLoaderConfig_ResourceError_Tooltip")
		):addTo(layout)

		cboxRestartReminder = createCheckboxOption(
			modApi:getText("ModLoaderConfig_RestartReminder_Text"),
			modApi:getText("ModLoaderConfig_RestartReminder_Tooltip")
		):addTo(layout)

		cboxProfileFrame = createCheckboxOption(
			modApi:getText("ModLoaderConfig_ProfileFrame_Text"),
			modApi:getText("ModLoaderConfig_ProfileFrame_Tooltip")
		):addTo(layout)

		uiSetSettings(LoadModLoaderConfig())
	end)
end

function ConfigureModLoader()
	createUi()
end

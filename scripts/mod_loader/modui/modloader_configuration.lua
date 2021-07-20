--[[
	Adds a new entry to the "Mod Content" menu, allowing to configure
	some features of the mod loader itself.
--]]

local subscriptions = {}
local function cleanup()
	for _, sub in ipairs(subscriptions) do
		sub:unsubscribe()
	end
	subscriptions = {}
end

local function createUi()
	local cboxScrollableLogger = nil
	local ddLogLevel = nil
	local cboxDebugLogs = nil
	local cboxCaller = nil
	local cboxDevelopmentMode = nil
	local cboxFloatyTooltips = nil
	local cboxProfileConfig = nil
	local cboxErrorFrame = nil
	local cboxVersionFrame = nil
	local cboxResourceError = nil
	local cboxGamepadWarning = nil
	local cboxRestartReminder = nil
	local cboxPilotRestartReminder = nil
	local cboxProfileFrame = nil

	local onExit = function(self)
		local data = {
			scrollableLogger    = cboxScrollableLogger.checked,
			logLevel            = ddLogLevel.value,
			debugLogs           = cboxDebugLogs.checked,
			printCallerInfo     = cboxCaller.checked,
			developmentMode     = cboxDevelopmentMode.checked,
			floatyTooltips      = cboxFloatyTooltips.checked,
			profileConfig       = cboxProfileConfig.checked,

			showErrorFrame      = cboxErrorFrame.checked,
			showVersionFrame    = cboxVersionFrame.checked,
			showResourceWarning = cboxResourceError.checked,
			showGamepadWarning  = cboxGamepadWarning.checked,
			showRestartReminder = cboxRestartReminder.checked,
			showPilotRestartReminder = cboxPilotRestartReminder.checked,
			showProfileSettingsFrame = cboxProfileFrame.checked
		}

		ApplyModLoaderConfig(data)
		SaveModLoaderConfig(data)

		cleanup()
	end

	local uiSetSettings = function(config)
		cboxScrollableLogger.checked     = config.scrollableLogger
		ddLogLevel.value                 = config.logLevel
		ddLogLevel.choice                = ddLogLevel.value + 1
		cboxDebugLogs.checked            = config.debugLogs
		cboxCaller.checked               = config.printCallerInfo
		cboxDevelopmentMode.checked      = config.developmentMode
		cboxFloatyTooltips.checked       = config.floatyTooltips
		cboxProfileConfig.checked        = config.profileConfig

		cboxErrorFrame.checked           = config.showErrorFrame
		cboxVersionFrame.checked         = config.showVersionFrame
		cboxResourceError.checked        = config.showResourceWarning
		cboxGamepadWarning.checked       = config.showGamepadWarning
		cboxRestartReminder.checked      = config.showRestartReminder
		cboxPilotRestartReminder.checked = config.showPilotRestartReminder
		cboxProfileFrame.checked         = config.showProfileSettingsFrame

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

	local createCollapseGroup = function(text, tooltip, defaultCollapsed)
		defaultCollapsed = defaultCollapsed or false
		local entryBoxHolder = UiBoxLayout()
			:vgap(5)
			:width(1)

		local collapse = UiCheckbox()
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
				DecoText(text)
			})
			:settooltip(tooltip)
			:addTo(entryBoxHolder)
		collapse.onclicked = function(self, button)
			if button == 1 then
				entryBoxHolder.content.visible = not self.checked
			end

			return true
		end
		collapse.checked = defaultCollapsed

		local entryContentHolder = UiBoxLayout()
			:vgap(5)
			:width(1)
			:addTo(entryBoxHolder)
		entryContentHolder.padl = 46
		entryContentHolder.visible = not defaultCollapsed

		entryBoxHolder.content = entryContentHolder
		entryBoxHolder.collapse = collapse

		return entryBoxHolder
	end

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frame = Ui()
			:width(0.6):height(0.575)
			:posCentered()
			:caption(GetText("ModLoaderConfig_FrameTitle"))
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
		-- Scrollable logger
		cboxScrollableLogger = createCheckboxOption(
				GetText("ModLoaderConfig_Text_ScrollableLogger"),
				GetText("ModLoaderConfig_Tooltip_ScrollableLogger")
		):addTo(layout)

		-- ////////////////////////////////////////////////////////////////////////
		-- Logging level
		ddLogLevel = UiDropDown(
			{
				Logger.LOG_LEVEL_NONE,
				Logger.LOG_LEVEL_CONSOLE,
				Logger.LOG_LEVEL_FILE
			},
			{
				GetText("ModLoaderConfig_DD_LogLevel_0"),
				GetText("ModLoaderConfig_DD_LogLevel_1"),
				GetText("ModLoaderConfig_DD_LogLevel_2")
			},
			mod_loader.logger:getLoggingLevel(),
			{
				GetText("ModLoaderConfig_DD_Tip_LogLevel_0"),
				GetText("ModLoaderConfig_DD_Tip_LogLevel_1"),
				GetText("ModLoaderConfig_DD_Tip_LogLevel_2")
			}
		)
		:width(1):heightpx(41)
		:decorate({
			DecoButton(),
			DecoAlign(0, 2),
			DecoText(GetText("ModLoaderConfig_Text_LogLevel")),
			DecoDropDownText(nil, nil, nil, 33),
			DecoAlign(0, -2),
			DecoDropDown()
		})
		:settooltip(GetText("ModLoaderConfig_Tooltip_LogLevel"))
		:addTo(layout)

		-- ////////////////////////////////////////////////////////////////////////
		-- Debug logs
		cboxDebugLogs = createCheckboxOption(
				GetText("ModLoaderConfig_Text_DebugLogs"),
				GetText("ModLoaderConfig_Tooltip_DebugLogs")
		):addTo(layout)

		-- ////////////////////////////////////////////////////////////////////////
		-- Caller information
		cboxCaller = createCheckboxOption(
			GetText("ModLoaderConfig_Text_Caller"),
			GetText("ModLoaderConfig_Tooltip_Caller")
		):addTo(layout)

		-- ////////////////////////////////////////////////////////////////////////
		-- Development Mode
		cboxDevelopmentMode = createCheckboxOption(
			GetText("ModLoaderConfig_Text_DevMode"),
			GetText("ModLoaderConfig_Tooltip_DevMode")
		):addTo(layout)

		-- ////////////////////////////////////////////////////////////////////////
		-- Floaty tooltips
		cboxFloatyTooltips = createCheckboxOption(
			GetText("ModLoaderConfig_Text_FloatyTooltips"),
			GetText("ModLoaderConfig_Tooltip_FloatyTooltips_On"),
			GetText("ModLoaderConfig_Tooltip_FloatyTooltips_Off")
		):addTo(layout)

		cboxFloatyTooltips.clicked = function(self, button)
			local result = checkboxClickFn(self, button)

			modApi.floatyTooltips = self.checked

			return result
		end

		-- ////////////////////////////////////////////////////////////////////////
		-- Profile-specific config
		cboxProfileConfig = createCheckboxOption(
			GetText("ModLoaderConfig_Text_ProfileConfig"),
			GetText("ModLoaderConfig_Tooltip_ProfileConfig")
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

		local popupsGroup = createCollapseGroup(
				GetText("ModLoaderConfig_Text_PopupsGroup"),
				GetText("ModLoaderConfig_Tooltips_PopupsGroup"),
				true
		):addTo(layout)

		cboxErrorFrame = createCheckboxOption(
			GetText("ModLoaderConfig_Text_ScriptError"),
			GetText("ModLoaderConfig_Tooltip_ScriptError")
		):addTo(popupsGroup.content)

		cboxVersionFrame = createCheckboxOption(
			GetText("ModLoaderConfig_Text_OldVersion"),
			GetText("ModLoaderConfig_Tooltip_OldVersion")
		):addTo(popupsGroup.content)

		cboxResourceError = createCheckboxOption(
			GetText("ModLoaderConfig_Text_ResourceError"),
			GetText("ModLoaderConfig_Tooltip_ResourceError")
		):addTo(popupsGroup.content)

		cboxGamepadWarning = createCheckboxOption(
			GetText("ModLoaderConfig_Text_GamepadWarning"),
			GetText("ModLoaderConfig_Tooltip_GamepadWarning")
		):addTo(popupsGroup.content)

		cboxRestartReminder = createCheckboxOption(
			GetText("ModLoaderConfig_Text_RestartReminder"),
			GetText("ModLoaderConfig_Tooltip_RestartReminder")
		):addTo(popupsGroup.content)

		cboxPilotRestartReminder = createCheckboxOption(
			GetText("ModLoaderConfig_Text_PilotRestartReminder"),
			GetText("ModLoaderConfig_Tooltip_PilotRestartReminder")
		):addTo(popupsGroup.content)

		cboxProfileFrame = createCheckboxOption(
			GetText("ModLoaderConfig_Text_ProfileFrame"),
			GetText("ModLoaderConfig_Tooltip_ProfileFrame")
		):addTo(popupsGroup.content)

		uiSetSettings(LoadModLoaderConfig())
	end)
end

function ConfigureModLoader()
	createUi()
end

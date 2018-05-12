--[[
	Adds a new entry to the "Mod Content" menu, allowing to configure
	some features of the mod loader itself.
--]]

local function saveModLoaderConfig()
	local data = {}
	data.logLevel = modApi.logger.logLevel
	data.printCallerInfo = modApi.logger.printCallerInfo
	data.showErrorFrame = modApi.showErrorFrame

	sdlext.config("modcontent.lua",function(obj)
		obj.modLoaderConfig = data
	end)
end

local function createUi()
	local ddLogLevel = nil
	local cboxCaller = nil
	local cboxErrorFrame = nil

	local onExit = function(self)
		modApi.logger.logLevel = ddLogLevel.value
		modApi.logger.printCallerInfo = cboxCaller.checked
		modApi.showErrorFrame = cboxErrorFrame.checked

		saveModLoaderConfig()
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

		cboxCaller = UiCheckbox()
			:width(1):heightpx(41)
			:settooltip(
				"Include timestamp and stacktrace in LOG messages."
			)
			:decorate({
				DecoButton(),
				DecoText("Print caller information"),
				DecoRAlign(41),
				DecoCheckbox()
			})

		cboxCaller.checked = modApi.logger.printCallerInfo
		cboxCaller:addTo(layout)

		cboxErrorFrame = UiCheckbox()
			:width(1):heightpx(41)
			:settooltip(
				"Show an error popup at startup when a mod fails to mount, init, or load."
			)
			:decorate({
				DecoButton(),
				DecoText("Show error popup"),
				DecoRAlign(41),
				DecoCheckbox()
			})

		cboxErrorFrame.checked = modApi.showErrorFrame
		cboxErrorFrame:addTo(layout)
	end)
end

function configureModLoader()
	applyModLoaderConfig(loadModLoaderConfig())

	createUi()
end

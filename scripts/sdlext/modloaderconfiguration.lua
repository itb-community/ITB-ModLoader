local function saveModLoaderConfig()
	local data = {}
	data.logLevel = modApi.logger.logLevel
	data.printCallerInfo = modApi.logger.printCallerInfo
	data.showErrorFrame = modApi.showErrorFrame

	sdlext.config("modcontent.lua",function(obj)
		obj.modLoaderConfig = data
	end)
end

function loadModLoaderConfig()
	local data = {
		logLevel = 1, -- log to console by default
		printCallerInfo = true,
		showErrorFrame = true
	}

	sdlext.config("modcontent.lua", function(obj)
		if not obj.modLoaderConfig then return end

		data = obj.modLoaderConfig
	end)

	return data
end

function applyModLoaderConfig(config)
	modApi.logger.logLevel = config.logLevel
	modApi.logger.printCallerInfo = config.printCallerInfo
	modApi.showErrorFrame = config.showErrorFrame
end

function configureModLoader()
	applyModLoaderConfig(loadModLoaderConfig())

	local ddLogLevel = nil
	local cboxCaller = nil
	local cboxErrorFrame = nil

	sdlext.uiEventLoop(function(ui, quit)
		ui.onclicked = function()
			quit()
			return true
		end

		local frame = Ui()
			:width(0.5):height(0.4)
			:pos(0.25, 0.3)
			:caption("Mod Loader Configuration")
			:decorate({
				DecoFrame(),
				DecoSolid(deco.colors.buttonbordercolor),
				DecoFrameCaption()
			})
			:addTo(ui)

		local scrollarea = UiScrollArea()
			:width(1):height(1)
			:padding(12)
			:decorate({ DecoSolid(deco.colors.buttoncolor) })
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

	modApi.logger.logLevel = ddLogLevel.value
	modApi.logger.printCallerInfo = cboxCaller.checked
	modApi.showErrorFrame = cboxErrorFrame.checked

	saveModLoaderConfig()
end

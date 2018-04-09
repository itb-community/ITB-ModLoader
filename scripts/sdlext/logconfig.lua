local function saveLogConfig()
	local data = {}
	data.logLevel = modApi.logger.logLevel
	data.outputFile = modApi.logger.logFile
	data.printCallerInfo = modApi.logger.printCallerInfo

	sdlext.config("modcontent.lua",function(obj)
		obj.loggerConfig = data
	end)
end

function loadLogConfig()
	local data = {
		logLevel = 1, -- log to console by default
		outputFile = "log.txt",
		printCallerInfo = true
	}

	sdlext.config("modcontent.lua", function(obj)
		if not obj.loggerConfig then return end

		data = obj.loggerConfig
	end)

	return data
end

function applyLogConfig(config)
	modApi.logger.logLevel = config.logLevel
	modApi.logger.logFile = config.outputFile
	modApi.logger.printCallerInfo = config.printCallerInfo
end

function configureLogger()
	applyLogConfig(loadLogConfig())

	local ddLogLevel = nil
	local cboxCaller = nil

	sdlext.uiEventLoop(function(ui, quit)
		ui.onclicked = function()
			quit()
			return true
		end

		local frame = Ui()
			:width(0.5):height(0.4)
			:pos(0.25, 0.3)
			:caption("Logger Configuration")
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
				"Include timestamp and stacktrace when printing to console."
			)
			:decorate({
				DecoButton(),
				DecoText("Print caller information"),
				DecoRAlign(41),
				DecoCheckbox()
			})

		cboxCaller.checked = modApi.logger.printCallerInfo
		cboxCaller:addTo(layout)
	end)

	modApi.logger.logLevel = ddLogLevel.value
	--modApi.logger.logFile = ... -- TODO
	modApi.logger.printCallerInfo = cboxCaller.checked

	saveLogConfig()
end

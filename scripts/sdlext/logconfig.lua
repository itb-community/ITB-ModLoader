local function saveLogConfig()
	local data = {}
	data.logLevel = modApi.logger.logLevel
	data.outputFile = modApi.logger.logFile

	sdlext.config("modcontent.lua",function(obj)
		obj.loggerConfig = data
	end)
end

function loadLogConfig()
	local data = {
		logLevel = 1, -- log to console by default
		outputFile = "log.txt"
	}

	sdlext.config("modcontent.lua", function(obj)
		if not obj.loggerConfig then return end

		data = obj.loggerConfig
	end)

	return data
end

function configureLogger()
	local logConfig = loadLogConfig()
	modApi.logger.logLevel = logConfig.logLevel
	modApi.logger.logFile = logConfig.outputFile

	local dropdown = nil

	sdlext.uiEventLoop(function(ui, quit)
		ui.onclicked = function()
			quit()
			return true
		end

		local frame = Ui()
			:width(0.5):height(0.2)
			:pos(0.25, 0.4)
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

		dropdown = UiDropDown(
				{ 0, 1, 2 },
				{ "None", "Only Console", "File and console" },
				modApi.logger.logLevel
			)
			:width(1):heightpx(41)
			:decorate({
				DecoButton(),
				DecoText("Logging Level"),
				DecoDropDownText(nil, nil, nil, 43),
				DecoDropDown()
			})
			:addTo(layout)
	end)

	modApi.logger.logLevel = dropdown.value

	saveLogConfig()
end

TestConsole = {}

TestConsole.colors = {}
TestConsole.colors.border_ok = sdl.rgb(64, 196, 64)
TestConsole.colors.border_running = sdl.rgb(192, 192, 64)
TestConsole.colors.border_fail = sdl.rgb(192, 32, 32)

deco.surfaces.markTick = sdlext.getSurface({
	path = "resources/mods/ui/mark-tick.png",
	colormap = {
		sdl.rgb(255, 255, 255),
		TestConsole.colors.border_ok
	}
})
deco.surfaces.markCross = sdlext.getSurface({
	path = "resources/mods/ui/mark-cross.png",
	colormap = {
		sdl.rgb(255, 255, 255),
		TestConsole.colors.border_fail
	}
})

local resetEvent = nil

local subscriptions = {}
local function cleanup()
	for _, sub in ipairs(subscriptions) do
		sub:unsubscribe()
	end
	subscriptions = {}
end

local function buildTestUi(testEntry)
	local entryHolder = UiWeightLayout()
		:width(1):heightpx(41)
		:addTo(entryBoxHolder)

	local checkbox = UiCheckbox()
		:width(1):heightpx(41)
		:decorate({
			DecoButton(),
			DecoCheckbox(),
			DecoAlign(4, 2),
			DecoText(testEntry.name)
		})
		:addTo(entryHolder)
	checkbox.checked = true

	sdlext.addButtonSoundHandlers(checkbox)

	local statusBox = Ui()
		:widthpx(41):heightpx(41)
		:decorate({
			DecoButton(),
			DecoSurface()
		})
		:addTo(entryHolder)
	statusBox.disabled = true

	-- Add child ui elements as fields in the parent object,
	-- for convenient access
	entryHolder.checkbox = checkbox
	entryHolder.statusBox = statusBox

	entryHolder.entry = testEntry

	-- Add event handlers as fields in the ui object, that way
	-- it's not our responsibility to register them correctly,
	-- and we can reduce the scope of this function.
	entryHolder.onReset = function()
		statusBox.decorations[1].bordercolor = deco.colors.buttonborder
		statusBox.decorations[2].surface = nil
		statusBox.disabled = true
		statusBox:settooltip("")

		statusBox.onMouseEnter = Ui.onMouseEnter
		statusBox.onclicked = Ui.onMouseEnter
	end
	entryHolder.onTestStarted = function(entry)
		if entry.parent == testEntry.parent and entry.name == testEntry.name then
			statusBox.decorations[1].bordercolor = TestConsole.colors.border_running
		end
	end
	entryHolder.onTestSuccess = function(entry, resultTable)
		if entry.parent == testEntry.parent and entry.name == testEntry.name then
			statusBox.decorations[1].bordercolor = deco.colors.buttonborder
			statusBox.decorations[2].surface = deco.surfaces.markTick
		end
	end
	entryHolder.onTestFailed = function(entry, resultTable)
		if entry.parent == testEntry.parent and entry.name == testEntry.name then
			statusBox.decorations[1].bordercolor = deco.colors.buttonborder
			statusBox.decorations[2].surface = deco.surfaces.markCross
			statusBox.disabled = false
			statusBox:settooltip(GetText("TestingConsole_FailSummary_Tooltip"))

			sdlext.addButtonSoundHandlers(statusBox, function ()
				sdlext.showTextDialog(
						GetText("TestingConsole_FailSummary_FrameTitle"),
						resultTable.result
				)
			end)
		end
	end
	entryHolder.onParentToggled = function(checked)
		checkbox.checked = checked
	end

	return entryHolder
end

local function buildTestsuiteUi(testsuiteEntry, isNestedTestsuite)
	indentLevel = indentLevel or 0
	local tests, testsuites = testsuiteEntry.suite:EnumerateTestsAndTestsuites()

	local entryBoxHolder = UiBoxLayout()
		:vgap(5)
		:width(1)

	-- Use UiWeightLayout so that we don't have to manually decide each element's size,
	-- just tell it to take up the remainder of horizontal space.
	local entryHeaderHolder = UiWeightLayout()
		:width(1):heightpx(41)
		:addTo(entryBoxHolder)

	local entryContentHolder = UiBoxLayout()
		:vgap(5)
		:width(1)
		:addTo(entryBoxHolder)

	if isNestedTestsuite then
		-- Have child elements be indented one level to the right, for visual clarity,
		-- except for the root element, since its children are supposed to be only other
		-- testsuites, which already have a collapse button that effectively indents them.
		entryContentHolder.padl = 46
	end

	-- Add a collapse button for nested testsuites.
	-- This is just a checkbox, but skinned differently.
	local collapse = UiCheckbox()
		:widthpx(41):heightpx(41)
		:decorate({
			DecoButton(),
			DecoCheckbox(
				deco.surfaces.dropdownOpenRight,
				deco.surfaces.dropdownClosed,
				deco.surfaces.dropdownOpenRightHovered,
				deco.surfaces.dropdownClosedHovered
			)
		})
		:addTo(entryHeaderHolder)
	if not isNestedTestsuite then
		collapse.visible = false
	end

	sdlext.addButtonSoundHandlers(collapse, function()
		entryContentHolder.visible = not collapse.checked
		entryBoxHolder:relayout()
	end)

	local checkbox = UiCheckbox()
		:width(1):heightpx(41)
		:decorate({
			DecoButton(),
			DecoCheckbox(),
			DecoAlign(4, 2),
			DecoText(testsuiteEntry.suite.name or testsuiteEntry.name)
		})
		:addTo(entryHeaderHolder)
	checkbox.checked = true

	sdlext.addButtonSoundHandlers(checkbox)

	local statusBox = Ui()
		:widthpx(400):heightpx(41)
		:decorate({
			DecoButton(),
			DecoAlign(0, 2),
			DecoText()
		})
		:addTo(entryHeaderHolder)
	statusBox.disabled = true
	statusBox.text = statusBox.decorations[3]

	local testsCounter = {}
	statusBox.onStatusChanged = Event()
	statusBox.updateStatus = function()
		local message = nil
		if testsCounter.failed > 0 then
			message = string.format(
					"Failed %s, passed %s of %s tests",
					testsCounter.failed,
					testsCounter.success,
					testsCounter.total
			)
			statusBox.text:setcolor(TestConsole.colors.border_fail)
		else
			message = string.format(
					"Passed %s of %s tests",
					testsCounter.success,
					testsCounter.total
			)
			statusBox.text:setcolor(TestConsole.colors.border_ok)
		end
		statusBox.text:setsurface(message)
	end
	table.insert(subscriptions, resetEvent:subscribe(function()
		testsCounter = {}
		testsCounter.ignored = 0
		testsCounter.failed = 0
		testsCounter.success = 0
		testsCounter.total = 0
		statusBox.updateStatus()
	end))

	local onTestSubmitted = function(entry)
		if testsuiteEntry.suite == entry.parent then
			local old = testsCounter.total
			testsCounter.total = testsCounter.total + 1
			statusBox.updateStatus()

			statusBox.onStatusChanged:dispatch("total", old, testsCounter.total)
		end
	end
	local onTestSuccess = function(entry)
		if testsuiteEntry.suite == entry.parent then
			local old = testsCounter.success
			testsCounter.success = testsCounter.success + 1
			statusBox.updateStatus()

			statusBox.onStatusChanged:dispatch("success", old, testsCounter.success)
		end
	end
	local onTestFailed = function(entry)
		if testsuiteEntry.suite == entry.parent then
			local old = testsCounter.failed
			testsCounter.failed = testsCounter.failed + 1
			statusBox.updateStatus()

			statusBox.onStatusChanged:dispatch("failed", old, testsCounter.failed)
		end
	end

	table.insert(subscriptions, TestConsole.runner.onTestSubmitted:subscribe(onTestSubmitted))
	table.insert(subscriptions, TestConsole.runner.onTestSuccess:subscribe(onTestSuccess))
	table.insert(subscriptions, TestConsole.runner.onTestFailed:subscribe(onTestFailed))

	-- Add child ui elements as fields in the parent object,
	-- for convenient access
	entryHeaderHolder.collapse = collapse
	entryHeaderHolder.checkbox = checkbox
	entryHeaderHolder.statusBox = statusBox

	-- Build ui elements for tests in this testsuite
	for _, entry in ipairs(tests) do
		local testUi = buildTestUi(entry)
			:addTo(entryContentHolder)

		table.insert(subscriptions, resetEvent:subscribe(testUi.onReset))
		table.insert(subscriptions, TestConsole.runner.onTestStarted:subscribe(testUi.onTestStarted))
		table.insert(subscriptions, TestConsole.runner.onTestSuccess:subscribe(testUi.onTestSuccess))
		table.insert(subscriptions, TestConsole.runner.onTestFailed:subscribe(testUi.onTestFailed))
		table.insert(subscriptions, checkbox.onToggled:subscribe(testUi.onParentToggled))
	end

	-- Recursively build ui elements for nested testsuites in this testsuite
	for _, entry in ipairs(testsuites) do
		local testsuiteUi = buildTestsuiteUi(entry, true)
			:addTo(entryContentHolder)

		table.insert(subscriptions, checkbox.onToggled:subscribe(testsuiteUi.onParentToggled))
		table.insert(subscriptions, testsuiteUi.header.statusBox.onStatusChanged:subscribe(function(status, childOld, childNew)
			local old = testsCounter[status]
			testsCounter[status] = testsCounter[status] + (childNew - childOld)
			statusBox.updateStatus()

			statusBox.onStatusChanged:dispatch(status, old, testsCounter[status])
		end))
	end

	entryBoxHolder.header = entryHeaderHolder
	entryBoxHolder.content = entryContentHolder

	entryBoxHolder.entry = testsuiteEntry

	entryBoxHolder.onParentToggled = function(checked)
		checkbox.checked = checked
		checkbox.onToggled:dispatch(checked)
	end

	return entryBoxHolder
end

---------------------------------------------------------

rootTestsuiteHolder = nil
local function findHolderForTestsuite(testsuite, holder)
	holder = holder or rootTestsuiteHolder
	if testsuite == Testsuites then
		return rootTestsuiteHolder
	end

	if holder.entry.suite == testsuite then
		return holder
	elseif not holder.content then
		return nil
	else
		for _, child in ipairs(holder.content.children) do
			local result = findHolderForTestsuite(testsuite, child)
			if result then
				return result
			end
		end
	end

	return nil
end

local function isSelected(holder, testFunc)
	for _, child in ipairs(holder.content.children) do
		if child.entry.func == testFunc then
			return child.checkbox.checked
		end
	end

	return false
end

local function enumerateAllTests()
	return Testsuites:EnumerateTests(true)
end

local function enumerateSelectedTests()
	return Testsuites:EnumerateTests(true, function(testsuiteInner, testName, testFn)
		local holder = findHolderForTestsuite(testsuiteInner)
		return isSelected(holder, testFn)
	end)
end

local function buildTestingConsoleContent(scroll)
	local entry = {
		name = GetText("TestingConsole_RootTestsuite"),
		suite = Testsuites
	}

	rootTestsuiteHolder = buildTestsuiteUi(entry)
		:addTo(scroll)
end

local function buildTestingConsoleButtons(buttonLayout)
	local btnRunAll = sdlext.buildButton(
		GetText("TestingConsole_RunAll"),
		nil,
		function()
			resetEvent:dispatch()
			TestConsole.runner:Start(enumerateAllTests)
		end
	)
	btnRunAll:heightpx(40)
	btnRunAll:addTo(buttonLayout)

	local btnRunSelected = sdlext.buildButton(
		GetText("TestingConsole_RunSelected"),
		nil,
		function()
			resetEvent:dispatch()
			TestConsole.runner:Start(enumerateSelectedTests)
		end
	)
	btnRunSelected:heightpx(40)
	btnRunSelected:addTo(buttonLayout)

	btnRunAll.disabled = TestConsole.runner.status ~= Tests.Runner.STATUS_COMPLETED
	btnRunSelected.disabled = TestConsole.runner.status ~= Tests.Runner.STATUS_COMPLETED

	table.insert(subscriptions, TestConsole.runner.onStatusChanged:subscribe(function(suite, oldStatus, newStatus)
		if newStatus == Tests.Runner.STATUS_COMPLETED then
			btnRunAll.disabled = false
			btnRunSelected.disabled = false
		else
			btnRunAll.disabled = true
			btnRunSelected.disabled = true
		end
	end))
end

local function showTestingConsole()
	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = function()
			cleanup()
		end

		local frame = sdlext.buildButtonDialog(
			GetText("TestingConsole_FrameTitle"),
			buildTestingConsoleContent,
			buildTestingConsoleButtons,
			{
				maxW = 0.6 * ScreenSizeX(),
				maxH = 0.8 * ScreenSizeY(),
				compact = false
			}
		)

		frame:addTo(ui)
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
	end)
end

local function calculateOpenTestingConsoleButtonPosition()
	-- Use the Buttons element maintained by the game itself.
	-- This way we don't have to worry about calculating locations
	-- for our UI, we can just offset based on the game's own UI
	-- whenever the screen is resized.
	local btnEndTurn = Buttons["action_end"]
	return btnEndTurn.pos.x, btnEndTurn.pos.y
end

local function createOpenTestingConsoleButton(root)
	TestConsole.runner = Tests.Runner()

	local button = sdlext.buildButton(
		GetText("TestingConsole_ToggleButton_Text"),
		GetText("TestingConsole_ToggleButton_Tooltip"),
		function()
			showTestingConsole()
		end
	)
	:widthpx(302):heightpx(40)
	:pospx(calculateOpenTestingConsoleButtonPosition())
	:addTo(root)

	button.draw = function(self, screen)
		self.visible = not sdlext.isConsoleOpen() and modApi.developmentMode and IsTestMechScenario()

		Ui.draw(self, screen)
	end

	modApi.events.onSettingsChanged:subscribe(function()
		button:pospx(calculateOpenTestingConsoleButtonPosition())
	end)

	modApi.events.onGameWindowResized:subscribe(function()
		button:pospx(calculateOpenTestingConsoleButtonPosition())
	end)
end

modApi.events.onUiRootCreated:subscribe(function(screen, root)
	if resetEvent then
		resetEvent:unsubscribeAll()
	end
	resetEvent = Event()
	createOpenTestingConsoleButton(root)
end)

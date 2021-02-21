local dialogStack = {}
local function popDialog()
	local ui = table.remove(dialogStack, #dialogStack)
	local root = ui.root

	if ui.onDialogExit then
		ui:onDialogExit()
	end

	ui:detach()

	if #dialogStack == 0 then
		root:setfocus(nil)
	else
		ui = dialogStack[#dialogStack]
		ui:show()
		ui:bringToTop()
		ui:setfocus()
	end
end

local function pushDialog(ui)
	Assert.Equals("table", type(ui))

	local root = sdlext.getUiRoot()

	if #dialogStack > 0 then
		dialogStack[#dialogStack]:hide()
	end

	ui:addTo(root):bringToTop()
	ui:setfocus()
	ui:show()
	table.insert(dialogStack, ui)

	if #dialogStack == 1 then
		ui.animations.fadeIn:start()
	end
end

local function buildBackgroundPane()
	local pane = Ui()
		:width(1):height(1)
		:decorate({ DecoSolid(deco.colors.dialogbg) })
	pane.dismissible = true

	pane.onclicked = function(self, button)
		if self.dismissible then
			popDialog()
		end
		return true
	end

	pane.wheel = function(self, mx, my, y)
		Ui.wheel(self, mx, my, y)
		return true
	end
	pane.mousedown = function(self, mx, my, button)
		Ui.mousedown(self, mx, my, button)
		return true
	end
	pane.mouseup = function(self, mx, my, button)
		Ui.mouseup(self, mx, my, button)
		return true
	end
	pane.mousemove = function(self, mx, my)
		Ui.mousemove(self, mx, my)
		return true
	end
	pane.keydown = function(self, keycode)
		if self.dismissible and keycode == SDLKeycodes.ESCAPE then
			popDialog()
		end
		return true
	end
	pane.keyup = function(self, keycode)
		return true
	end

	pane.hide = function(self)
		self.decorations[1].color = nil
	end

	pane.show = function(self)
		self.decorations[1].color = deco.colors.dialogbg
	end

	pane.animations.fadeIn = UiAnim(pane, 100, function(anim, widget, percent)
		widget.decorations[1].color = InterpolateColor(
			deco.colors.transparent,
			deco.colors.dialogbg,
			percent
		)
	end)

	return pane
end

modApi.events.onGameWindowResized:subscribe(function(screen)
	for i, pane in ipairs(dialogStack) do
		pane:widthpx(screen:w()):heightpx(screen:h())
		pane:relayout()
	end
end)

-- //////////////////////////////////////////////////////////////////////

function sdlext.dialogVisible()
	return #dialogStack > 0
end

function sdlext.showDialog(init)
	Assert.Equals("function", type(init))

	local ui = buildBackgroundPane()

	ui.onDialogExit = function(self)
	end

	pushDialog(ui)
	-- Relayout the parent, so that the container ui element
	-- has its size set to px values, instead of percentage values
	-- Prevents issues when building ui in client code
	ui.parent:relayout()

	init(ui, function()
		popDialog()
	end)
end

-- For backwards compatibility
function sdlext.uiEventLoop(init)
	LOG("sdlext.uiEventLoop() has been deprecated in mod loader version 2.2.0. Use sdlext.showDialog() instead.")
	sdlext.showDialog(init)
end

-- //////////////////////////////////////////////////////////////////////

function sdlext.buildSimpleDialog(title, options)
	Assert.Equals("string", type(title))
	if options then
		Assert.Equals("table", type(options))
	else
		options = {}
	end

	local maxW = options.maxW or 0.5 * ScreenSizeX()
	local maxH = options.maxH or 0.5 * ScreenSizeY()

	local frame = UiWeightLayout()
		:widthpx(maxW):heightpx(maxH)
		:vgap(0)
		:orientation(false)
		:decorate({ DecoFrameHeader(), DecoFrame() })
		:caption(title)

	frame.scroll = UiScrollArea()
		:width(1):height(1)
		:padding(10)
		:addTo(frame)

	frame:relayout()

	return frame
end

function sdlext.buildTextDialog(title, text, options)
	Assert.Equals("string", type(title))
	Assert.Equals("string", type(text))

	local contentFn = function(scroll)
		local font = deco.uifont.tooltipTextLarge.font
		local textset = deco.uifont.tooltipTextLarge.set
		local wrap = UiWrappedText(text, font, textset)
				:widthpx(scroll.w)
				:addTo(scroll)

		wrap.pixelWrap = true
		wrap:rebuild()
	end

	return sdlext.buildScrollDialog(title, contentFn, options)
end

function sdlext.buildScrollDialog(title, contentBuilderFn, options)
	Assert.Equals("string", type(title))
	Assert.Equals("function", type(contentBuilderFn))
	if options then
		Assert.Equals("table", type(options))
	else
		options = {}
	end

	local maxW = options.maxW or 0.5 * ScreenSizeX()
	local maxH = options.maxH or 0.5 * ScreenSizeY()
	local minW = options.minW or 700
	local minH = options.minH or 100
	local compactW = options.compactW or false
	local compactH = (options.compactH == nil and true) or options.compactH

	Assert.Equals("number", type(maxW))
	Assert.Equals("number", type(maxH))
	Assert.Equals("number", type(minW))
	Assert.Equals("number", type(minH))
	Assert.Equals("boolean", type(compactW))
	Assert.Equals("boolean", type(compactH))

	local frame = sdlext.buildSimpleDialog(title, options)
	local scroll = frame.scroll

	contentBuilderFn(scroll)

	frame:relayout()

	local contentW = compactW and (scroll.innerWidth + scroll.padl + scroll.padr) or scroll.w
	local w = math.max(minW, contentW + frame.padl + frame.padr)
	w = math.min(w, maxW)
	local contentH = compactH and (scroll.innerHeight + scroll.padt + scroll.padb) or scroll.h
	local h = math.max(minH, contentH + frame.padt + frame.padb)
	h = math.min(h, maxH)

	frame:widthpx(w)
	frame:heightpx(h)
	frame:relayout()

	return frame
end

function sdlext.buildButtonDialog(title, contentBuilderFn, buttonsBuilderFn, options)
	Assert.Equals("string", type(title))
	Assert.Equals("function", type(contentBuilderFn))
	Assert.Equals("function", type(buttonsBuilderFn))
	if options then
		Assert.Equals("table", type(options))
	else
		options = {}
	end

	local maxW = options.maxW or 0.5 * ScreenSizeX()
	local maxH = options.maxH or 0.5 * ScreenSizeY()
	local minW = options.minW or 700
	local minH = options.minH or 100
	local compactW = options.compactW or false
	local compactH = (options.compactH == nil and true) or options.compactH

	Assert.Equals("number", type(maxW))
	Assert.Equals("number", type(maxH))
	Assert.Equals("number", type(minW))
	Assert.Equals("number", type(minH))
	Assert.Equals("boolean", type(compactW))
	Assert.Equals("boolean", type(compactH))

	local frame = sdlext.buildSimpleDialog(title, options)
	local scroll = frame.scroll

	local line = Ui()
		:width(1):heightpx(frame.decorations[1].bordersize)
		:decorate({ DecoSolid(frame.decorations[1].bordercolor) })
		:addTo(frame)
	frame.line = line

	local buttonHolder = UiBoxLayout()
		:width(1)
		:vgap(0)
		:addTo(frame)

	local buttonLayout = UiBoxLayout()
		:height(1)
		:hgap(50)
		:padding(18)
	buttonLayout.alignH = "center"

	buttonHolder:heightpx(45 + buttonLayout.padt + buttonLayout.padb)
	buttonLayout:addTo(buttonHolder)

	frame.buttonLayout = buttonLayout

	contentBuilderFn(scroll)
	buttonsBuilderFn(buttonLayout)

	frame:relayout()

	local contentW = compactW and (scroll.innerWidth + scroll.padl + scroll.padr) or scroll.w
	local w = math.max(minW, contentW + frame.padl + frame.padr)
	w = math.min(w, maxW)
	local contentH = compactH and (scroll.innerHeight + scroll.padt + scroll.padb) or scroll.h
	local h = math.max(minH, contentH + frame.padt + frame.padb + buttonHolder.h + line.h)
	h = math.min(h, maxH)

	frame:widthpx(w)
	frame:heightpx(h)
	frame:relayout()

	return frame
end

--[[
	Registers sound effects to be played when the button is
	hovered over and clicked. Sound effects cannot be played
	in the main menu / hangar.

	This function overwrites the onclicked property of the UI
	element; use the second argument (clickHandler) to pass
	your own function that should perform actions when the
	element is clicked.
--]]
function sdlext.addButtonSoundHandlers(uiElement, clickHandler)
	uiElement.onMouseEnter = function(self)
		if Game and not self.disabled then
			Game:TriggerSound("/ui/general/highlight_button")
		end
	end

	uiElement.onclicked = function(self, button)
		if button == 1 then
			if Game and not self.disabled then
				Game:TriggerSound("/ui/general/button_confirm")
			end

			if clickHandler then
				clickHandler()
			end
		end

		return true
	end
end

function sdlext.buildButton(text, tooltip, clickHandler)
	local decoText = DecoCAlignedText(text)
	-- JustinFont has some weird issues causing the sdl.surface to report
	-- slightly bigger width than it should have. Correct for this.
	-- Calculate the excess width (0.0375), and then halve it twice;
	-- once to get the centering offset, twice to get the correction offset
	local offset = math.floor(0.0375 * decoText.surface:w() / 4)

	local btn = Ui()
		:widthpx(math.max(95, decoText.surface:w() + 30))
		:heightpx(40)
		:decorate({ DecoButton(), DecoAlign(-6 + offset, 2), decoText })

	if tooltip and tooltip ~= "" then
		btn:settooltip(tooltip)
	end

	sdlext.addButtonSoundHandlers(btn, clickHandler)

	return btn
end

function sdlext.buildDropDownButton(text, tooltip, choices, choiceHandler)
	local decoText = DecoText(text)
	local maxChoiceWidth = 0

	local values = {}
	for i = 1, #choices do
		values[#values+1] = i

		local decoChoice = DecoRAlignedText(choices[i])
		maxChoiceWidth = math.max(maxChoiceWidth, decoChoice.surface:w())
	end

	local btn = UiDropDown(values, choices, choices[1])
			:widthpx(math.max(95, decoText.surface:w() + maxChoiceWidth + 33))
			:heightpx(40)
			:decorate({
				DecoButton(),
				DecoAlign(0, 2),
				decoText,
				DecoDropDownText(nil, nil, nil, 33),
				DecoAlign(0, -2),
				DecoDropDown()
			})

	btn.destroyDropDown = function(self)
		UiDropDown.destroyDropDown(self)

		if choiceHandler then
			choiceHandler(self.value)
		end
	end

	if tooltip and tooltip ~= "" then
		btn:settooltip(tooltip)
	end

	-- No sound is currently added to hovering or clicking dropdown choices
	sdlext.addButtonSoundHandlers(btn)

	return btn
end

function sdlext.showTextDialog(title, text, options)
	sdlext.showDialog(function(ui, quit)
		local frame = sdlext.buildTextDialog(title, text, options)

		frame
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
			:addTo(ui)
	end)
end

function sdlext.showButtonDialog(title, text, responseFn, buttons, tooltips, options)
	if (responseFn) then
		Assert.Equals("function", type(responseFn))
	end
	Assert.Equals("table", type(buttons))
	Assert.True(#buttons > 0, "sdlext.showButtonDialog: argument #4 must have at least one button")
	if (tooltips) then
		Assert.Equals("table", type(tooltips))
		Assert.True(#tooltips == #buttons, "sdlext.showButtonDialog: argument #5 - number of tooltips must be equal to number of buttons. Use empty string (\"\") for no tooltip.")
	end

	sdlext.showDialog(function(ui, quit)
		ui.dismissible = false

		ui.onDialogExit = function(self)
			if responseFn then
				responseFn(self.response)
			end
		end

		local frame = sdlext.buildButtonDialog(
				title,
				function(scroll)
					local font = deco.uifont.tooltipTextLarge.font
					local textset = deco.uifont.tooltipTextLarge.set
					local wrap = UiWrappedText(text, font, textset)
						:widthpx(scroll.w)
						:addTo(scroll)

					wrap.pixelWrap = true
					wrap:rebuild()
				end,
				function(buttonLayout)
					for i, text in ipairs(buttons) do
						local tooltip = tooltips and tooltips[i]
						local btn = sdlext.buildButton(text, tooltip, function()
							ui.response = i
							quit()
						end)

						btn:addTo(buttonLayout)
					end
				end,
				options
		)

		frame
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
			:addTo(ui)
	end)
end

function sdlext.showAlertDialog(title, text, responseFn, options, ...)
	local buttons = {...}
	if type(buttons[1]) == "table" then
		buttons = buttons[1]
	end

	sdlext.showButtonDialog(title, text, responseFn, buttons, nil, options)
end

function sdlext.showInfoDialog(title, text, responseFn, options)
	sdlext.showAlertDialog(title, text, responseFn, options, GetText("Button_Ok"))
end

function sdlext.showConfirmDialog(title, text, responseFn, options)
	sdlext.showAlertDialog(title, text, responseFn, options, GetText("Button_Yes"), GetText("Button_No"))
end

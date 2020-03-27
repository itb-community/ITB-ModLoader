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
	assert(type(ui) == "table", "Expected table, got " .. type(ui))

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

sdlext.addGameWindowResizedHook(function(screen)
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
	assert(type(init) == "function", "Expected function, got " .. type(init))

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

function sdlext.buildSimpleDialog(title, w, h)
	local frame = Ui()
			:widthpx(w):heightpx(h)
			:decorate({ DecoFrameHeader(), DecoFrame() })
			:caption(title)

	frame.scroll = UiScrollArea()
			:width(1):height(1)
			:padding(10)
			:addTo(frame)

	frame:relayout()

	return frame
end

function sdlext.buildTextDialog(title, text, w, h)
	local frame = sdlext.buildSimpleDialog(title, w, h)
	local scroll = frame.children[1]

	local font = deco.uifont.tooltipTextLarge.font
	local textset = deco.uifont.tooltipTextLarge.set
	local wrap = UiWrappedText(text, font, textset)
		:widthpx(scroll.w)
		:addTo(scroll)

	wrap.pixelWrap = true
	wrap:rebuild()

	return frame
end

function sdlext.buildButtonDialog(title, w, h, contentBuilderFn, buttonsBuilderFn)
	w = w or 700
	h = h or 400

	local frame = sdlext.buildSimpleDialog(title, w, h)
	local scroll = frame.scroll

	if contentBuilderFn then
		contentBuilderFn(scroll)
		frame:relayout()
	end

	local line = Ui()
			:width(1):heightpx(frame.decorations[1].bordersize)
			:decorate({ DecoSolid(frame.decorations[1].bordercolor) })
			:addTo(frame)
	frame.line = line

	local buttonLayout = UiBoxLayout()
			:hgap(50)
			:padding(18)
			:addTo(frame)
	buttonLayout:heightpx(45 + buttonLayout.padt + buttonLayout.padb)
	frame.buttonLayout = buttonLayout

	if buttonsBuilderFn then
		buttonsBuilderFn(buttonLayout)
	end

	frame:relayout()

	if scroll.innerHeight < h - frame.padt - frame.padb then
		scroll:heightpx(scroll.innerHeight)
	end

	line:pospx(0, scroll.y + scroll.h)

	w = math.max(w, buttonLayout.w + frame.padl + frame.padr)
	frame:widthpx(w)
	buttonLayout:pospx((frame.w - frame.padl - frame.padr - buttonLayout.w) / 2, line.y + line.h)

	h = math.min(h, scroll.innerHeight + frame.padt + frame.padb)
	h = math.max(h, buttonLayout.y + buttonLayout.h + frame.padt + frame.padb)

	frame:heightpx(h)

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

function sdlext.showTextDialog(title, text, w, h)
	w = w or 700
	h = h or 400

	sdlext.showDialog(function(ui, quit)
		local frame = sdlext.buildTextDialog(title, text, w, h)
		local scroll = frame.children[1]

		frame:relayout()

		if scroll.innerHeight < h - frame.padt - frame.padb then
			scroll:heightpx(scroll.innerHeight)
		end

		h = math.min(h, scroll.innerHeight + frame.padt + frame.padb)

		frame
			:heightpx(h)
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
			:addTo(ui)
	end)
end

function sdlext.showButtonDialog(title, text, responseFn, maxW, maxH, buttons, tooltips)
	assert(#buttons > 0, "ButtonDialog must have at least one button!")
	assert(not tooltips or #tooltips == #buttons, "Number of tooltips must be equal to number of buttons. Use empty string (\"\") for no tooltip.")

	maxW = maxW or 700
	maxH = maxH or 400

	sdlext.showDialog(function(ui, quit)
		ui.dismissible = false

		ui.onDialogExit = function(self)
			if responseFn then
				responseFn(self.response)
			end
		end

		local frame = sdlext.buildButtonDialog(
			title, maxW, maxH,
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
			end
		)

		frame
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
			:addTo(ui)
	end)
end

function sdlext.showAlertDialog(title, text, responseFn, w, h, ...)
	local buttons = {...}
	if type(buttons[1]) == "table" then
		buttons = buttons[1]
	end
	assert(#buttons > 0, "AlertDialog must have at least one button!")

	sdlext.showButtonDialog(title, text, responseFn, nil, nil, buttons, nil)
end

function sdlext.showInfoDialog(title, text, fn, w, h)
	sdlext.showAlertDialog(title, text, fn, w, h, GetText("Button_Ok"))
end

function sdlext.showConfirmDialog(title, text, fn, w, h)
	sdlext.showAlertDialog(title, text, fn, w, h, GetText("Button_Yes"), GetText("Button_No"))
end

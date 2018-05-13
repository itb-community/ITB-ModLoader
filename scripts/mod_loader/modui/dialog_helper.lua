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
	pane.mousedown = function(self, mx, my)
		Ui.mousedown(self, mx, my)
		return true
	end
	pane.mouseup = function(self, mx, my)
		Ui.mouseup(self, mx, my)
		return true
	end
	pane.mousemove = function(self, mx, my)
		Ui.mousemove(self, mx, my)
		return true
	end
	pane.keydown = function(self, keycode)
		if self.dismissible and keycode == 27 then -- Escape
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

local function buildSimpleDialog(title, text, w, h)
	local frame = Ui()
		:widthpx(w):heightpx(h)
		:decorate({ DecoFrameHeader(), DecoFrame() })
		:caption(title)

	local scroll = UiScrollArea()
		:width(1):height(1)
		:padding(10)
		:addTo(frame)

	local font = deco.uifont.tooltipTextLarge.font
	local textset = deco.uifont.tooltipTextLarge.set
	local wrap = UiWrappedText(text, font, textset)
		:width(1)
		:addTo(scroll)

	return frame
end

function sdlext.showTextDialog(title, text, w, h)
	w = w or 700
	h = h or 400

	sdlext.showDialog(function(ui, quit)
		local frame = buildSimpleDialog(title, text, w, h)
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

local align = DecoAlign(-8, 1)
local align2 = DecoAlign(-5, 0)
function sdlext.showAlertDialog(title, text, w, h, ...)
	buttons = {...}
	assert(#buttons > 0, "AlertDialog must have at least one button!")
	w = w or 700
	h = h or 400

	sdlext.showDialog(function(ui, quit)
		ui.dismissible = false

		local frame = buildSimpleDialog(title, text, w, h)
		local scroll = frame.children[1]

		local line = Ui()
			:width(1):heightpx(frame.decorations[1].bordersize)
			:decorate({ DecoSolid(frame.decorations[1].bordercolor) })
			:addTo(frame)

		local buttonLayout = UiBoxLayout()
			:hgap(50)
			:padding(18)
			:addTo(frame)
		buttonLayout:heightpx(45 + buttonLayout.padt + buttonLayout.padb)

		for i, text in ipairs(buttons) do
			local decoText = DecoCAlignedText(text)

			local btn = Ui()
				:widthpx(95):height(1)
				:addTo(buttonLayout)

			-- Not entirely sure why buttons with longer text need
			-- different alignment offset (in both X and Y to boot)
			local btnw = math.max(btn.w, decoText.surface:w() + 30)
			if btnw > btn.w then
				btn:decorate({ DecoButton(), align2, decoText })
					:widthpx(btnw)
			else
				btn:decorate({ DecoButton(), align, decoText })
			end

			btn.onclicked = function()
				ui.dialogButton = text
				quit()
				return true
			end
		end

		frame:relayout()

		if scroll.innerHeight < h - frame.padt - frame.padb then
			scroll:heightpx(scroll.innerHeight)
		end

		line:pospx(0, scroll.y + scroll.h)

		w = math.max(w, buttonLayout.w + frame.padl + frame.padr)
		line:widthpx(w - frame.padl - frame.padr)
		frame:widthpx(w)
		buttonLayout:pospx((frame.w - frame.padl - frame.padr - buttonLayout.w) / 2, line.y + line.h)

		h = math.min(h, scroll.innerHeight + frame.padt + frame.padb)
		h = math.max(h, buttonLayout.y + buttonLayout.h + frame.padt + frame.padb)

		frame
			:heightpx(h)
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
			:addTo(ui)
	end)
end

function sdlext.showInfoDialog(title, text, w, h)
	sdlext.showAlertDialog(title, text, w, h, "OK")
end

function sdlext.showConfirmDialog(title, text, w, h)
	sdlext.showAlertDialog(title, text, w, h, "YES", "NO")
end

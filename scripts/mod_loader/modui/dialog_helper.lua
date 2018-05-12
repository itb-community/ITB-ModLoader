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
	table.insert(dialogStack, ui)
end

local function buildBackgroundPane()
	local pane = Ui()
		:width(1):height(1)
		:decorate({ DecoSolid(deco.colors.dialogbg) })

	pane.onclicked = function(self, button)
		popDialog()
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
		if keycode == 27 then -- Escape
			popDialog()
		end
		return true
	end
	pane.keyup = function(self, keycode)
		return true
	end

	pane.hide = function(self)
		pane.decorations[1].color = nil
	end

	pane.show = function(self)
		pane.decorations[1].color = deco.colors.dialogbg
	end

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

function sdlext.showTextDialog(title, text, w, h)
	local padding = 10
	w = w or 700
	h = h or 400

	sdlext.showDialog(function(ui, quit)
		local wrap = UiWrappedText(text)
			:width(w - padding * 2)
		wrap:relayout()

		h = math.min(h, wrap.h + padding * 2 + 45)

		local frame = Ui()
			:widthpx(w):heightpx(h)
			:pospx((ui.w - w) / 2, (ui.h - h) / 2)
			:caption(title)
			:decorate({ DecoFrame(), DecoFrameCaption() })
			:addTo(ui)

		local scroll = UiScrollArea()
			:width(1):height(1)
			:padding(padding)
			:decorate({ DecoSolid() })
			:addTo(frame)

		wrap:addTo(scroll)
	end)
end

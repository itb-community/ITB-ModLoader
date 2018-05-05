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
		:decorate({ DecoSolid(deco.colors.halfblack) })

	pane.onclicked = function()
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
		pane.decorations[1].color = deco.colors.halfblack
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
	sdlext.showDialog(init)
end

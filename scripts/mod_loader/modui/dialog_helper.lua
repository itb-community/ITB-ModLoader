local bg = Ui()
	:width(1):height(1)
	:decorate({ DecoSolid(sdl.rgba(0, 0, 0, 128)) })

local dialogStack = {}
local function popDialog()
	local ui = table.remove(dialogStack, #dialogStack)

	if ui.onDialogExit then
		ui:onDialogExit()
	end

	ui:detach()

	if #dialogStack == 0 then
		bg:detach()
	else
		dialogStack[#dialogStack]:bringToTop()
	end
end

local function pushDialog(ui)
	assert(type(ui) == "table", "Expected table, got " .. type(ui))

	local root = sdlext.getUiRoot()

	if not bg.parent then
		bg:addTo(root)
	end
	bg:bringToTop()

	ui:addTo(root):bringToTop()
	table.insert(dialogStack, ui)
end

-- Make sure the background intercepts all leftover events
bg.onclicked = function()
	popDialog()
	return true
end
bg.wheel = function(self, mx, my, y)
	Ui.wheel(self, mx, my, y)
	return true
end
bg.mousedown = function(self, mx, my)
	Ui.mousedown(self, mx, my)
	return true
end
bg.mouseup = function(self, mx, my)
	Ui.mouseup(self, mx, my)
	return true
end
bg.mousemove = function(self, mx, my)
	Ui.mousemove(self, mx, my)
	return true
end

-- //////////////////////////////////////////////////////////////////////

function sdlext.dialogVisible()
	return #dialogStack > 0
end

function sdlext.showDialog(init)
	assert(type(init) == "function", "Expected function, got " .. type(init))

	local ui = Ui():width(1):height(1)
	ui.translucent = true

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

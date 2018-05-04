local bg = Ui()
	:width(1):height(1)
	:decorate({ DecoSolid(sdl.rgba(0, 0, 0, 128)) })

local dialogStack = {}
local function popDialog()
	local ui = table.remove(dialogStack, #dialogStack)
	ui:detach()

	if #dialogStack == 0 then
		bg:detach()
	else
		dialogStack[#dialogStack]:bringToTop()
	end
end

local function pushDialog(ui)
	assert(type(ui) == "table")

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
	assert(type(init) == "function")

	local ui = Ui():width(1):height(1)
	ui.translucent = true
	pushDialog(ui)

	init(ui, function()
		popDialog()
	end)
end

-- For backwards compatibility
function sdlext.uiEventLoop(init)
	sdlext.showDialog(init)
end

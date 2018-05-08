--[[
	Click handler for hangar buttons
--]]

local hangarLeavingHooks = {}
function sdlext.addHangarLeavingHook(fn)
	assert(type(fn) == "function")
	table.insert(hangarLeavingHooks, fn)
end

local leaving = false
local function fireHangarLeavingHooks(startGame)
	leaving = true
	for i, hook in ipairs(hangarLeavingHooks) do
		hook(startGame)
	end
end

local function isPopupless()
	-- check that there are no frames with shadow currently visible,
	-- other than the squad frame which is always drawn in the hangar
	local r = sdlext.CurrentWindowRect
	return r.w == 420 and r.h == 480
end

local squadBox = Boxes.hangar_select
local achBox   = Boxes.hangar_ach_display
-- couldn't find the box for pilot selection window
local pilotBox = Rect2D(0, 0, squadBox.w - 150, squadBox.h)
local function isHangarWindow(w, h)
	if not w and not h then
		w = sdlext.CurrentWindowRect.w
		h = sdlext.CurrentWindowRect.h
	end

	return (w == squadBox.w and h == squadBox.h) or
	       (w == pilotBox.w and h == pilotBox.h) or
	       (w == achBox.w   and h == achBox.h)
end

local function createUi(root)
	local holder = Ui()
		:width(1):height(1)
		:addTo(root)
	holder.translucent = true

	local btnBack = Ui()
		:widthpx(120):heightpx(65)
		:addTo(holder)
	btnBack.translucent = true
	btnBack.mousedown = function(self, x, y, button)
		if button == 1 and isPopupless() and not leaving then
			fireHangarLeavingHooks(false)
		end
		return Ui.mousedown(self, x, y, button)
	end

	local btnStart = Ui()
		:widthpx(120):heightpx(65)
		:addTo(holder)
	btnStart.translucent = true
	btnStart.mousedown = function(self, x, y, button)
		if button == 1 and isPopupless() and not leaving then
			fireHangarLeavingHooks(true)
		end
		return Ui.mousedown(self, x, y, button)
	end

	sdlext.addPreKeyDownHook(function(keycode)
		if
			holder.visible             and
			keycode == 27              and
			not sdlext.isConsoleOpen() and
			not leaving                and
			not isHangarWindow()
		then
			fireHangarLeavingHooks(false)
		end

		return false
	end)

	holder.draw = function(self, screen)
		local center = GetScreenCenter()
		btnBack:pospx(center.x + 135, center.y - 275)
		btnStart:pospx(center.x + 415, center.y - 275)

		self.visible = sdlext.isHangar()

		Ui.draw(self, screen)
	end

	sdlext.addHangarEnteredHook(function(screen)
		leaving = false
		holder.visible = true
		holder:setfocus()
	end)
end

sdlext.addUiRootCreatedHook(function(screen, root)
	createUi(root)
end)

--[[
	Click handler for main menu buttons
--]]

local leaving = false
local pendingConfirm = false
local function fireMainMenuLeavingHooks()
	leaving = true
	modApi.events.onMainMenuLeaving:dispatch()
end

local function isWindowVisible()
	-- only works while in main menu, since there's no tooltip or other
	-- ui elements casting shadow
	local r = sdlext.CurrentWindowRect
	return not (r.x == 0 and r.y == 0 and r.w == 0 and r.h == 0)
end

local function createUi(root)
	local holder = Ui()
		:width(1):height(1)
		:addTo(root)
	holder.translucent = true

	local btnContinue = Ui()
		:widthpx(345):heightpx(40)
		:addTo(holder)
	btnContinue.translucent = true
	btnContinue.mousedown = function(self, x, y, button)
		if button == 1 and not isWindowVisible() and not leaving then
			modApi.events.onContinueClicked:dispatch()
		end
		return Ui.mousedown(self, x, y, button)
	end

	local btnNewGame = Ui()
		:widthpx(345):heightpx(40)
		:addTo(holder)
	btnNewGame.translucent = true
	btnNewGame.mousedown = function(self, x, y, button)
		if button == 1 and not isWindowVisible() and not leaving then
			modApi.events.onNewGameClicked:dispatch()
		end
		return Ui.mousedown(self, x, y, button)
	end

	holder.mousedown = function(self, x, y, button)
		if pendingConfirm and button == 1 then
			-- box for the "Yes" button
			local r = sdlext.CurrentWindowRect
			local rect = sdl.rect(r.x + 75, r.y + 154, 95, 45)
			if rect_contains(rect, x, y) then
				pendingConfirm = false
				fireMainMenuLeavingHooks()
			elseif not rect_contains(r, x, y) then
				pendingConfirm = false
			end
		end

		return Ui.mousedown(self, x, y, button)
	end

	modApi.events.onKeyPressing:subscribe(function(keycode)
		if
			holder.visible and
			(keycode == SDLKeycodes.RETURN or keycode == SDLKeycodes.RETURN2) and
			not sdlext.isConsoleOpen()
		then
			if pendingConfirm then
				pendingConfirm = false
				fireMainMenuLeavingHooks()
			end
		end

		return false
	end)

	holder.draw = function(self, screen)
		local yOffset = 0
		if ScreenSizeX() < 1500 or ScreenSizeY() < 800 then
			yOffset = -75
		end

		btnContinue:pospx(0, yOffset + 285)
		btnNewGame:pospx(0, yOffset + 285 + 40 + 10)

		self.visible = sdlext.isMainMenu()

		Ui.draw(self, screen)
	end
end

modApi.events.onNewGameClicked:subscribe(function()
	modApi:scheduleHook(10, function()
		local r = sdlext.CurrentWindowRect

		if r.w == 390 and r.h == 219 then -- confirmation box
			pendingConfirm = true
		else
			fireMainMenuLeavingHooks()
		end
	end)
end)

modApi.events.onContinueClicked:subscribe(function()
	fireMainMenuLeavingHooks()
end)

modApi.events.onMainMenuEntered:subscribe(function(screen, wasHangar, wasGame)
	leaving = false
	Profile = modApi:loadProfile()
end)

modApi.events.onUiRootCreated:subscribe(function(screen, root)
	createUi(root)
end)

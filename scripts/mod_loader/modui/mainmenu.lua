--[[
	Click handler for main menu buttons
--]]

--[[
	Fired when the Continue button is clicked.
--]]
local continueClickHooks = {}
function sdlext.addContinueClickHook(fn)
	assert(type(fn) == "function")
	table.insert(continueClickHooks, fn)
end

--[[
	Fired when the New Game button is clicked.
	This does NOT account for the confirmation box
	that pops up when you have a game in progress.
--]]
local newGameClickHooks = {}
function sdlext.addNewGameClickHook(fn)
	assert(type(fn) == "function")
	table.insert(newGameClickHooks, fn)
end

--[[
	Fired when the leaves the Main Menu for the Hangar
--]]
local mainMenuLeavingHooks = {}
function sdlext.addMainMenuLeavingHook(fn)
	assert(type(fn) == "function")
	table.insert(mainMenuLeavingHooks, fn)
end

local leaving = false
local pendingConfirm = false
local function fireMainMenuLeavingHooks()
	leaving = true
	for i, hook in ipairs(mainMenuLeavingHooks) do
		hook()
	end
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
			for i, hook in ipairs(continueClickHooks) do
				hook()
			end
		end
		return Ui.mousedown(self, x, y, button)
	end

	local btnNewGame = Ui()
		:widthpx(345):heightpx(40)
		:addTo(holder)
	btnNewGame.translucent = true
	btnNewGame.mousedown = function(self, x, y, button)
		if button == 1 and not isWindowVisible() and not leaving then
			for i, hook in ipairs(newGameClickHooks) do
				hook()
			end
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

	sdlext.addPreKeyDownHook(function(keycode)
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

sdlext.addNewGameClickHook(function()
	modApi:scheduleHook(10, function()
		local r = sdlext.CurrentWindowRect

		if r.w == 390 and r.h == 219 then -- confirmation box
			pendingConfirm = true
		else
			fireMainMenuLeavingHooks()
		end
	end)
end)

sdlext.addContinueClickHook(function()
	fireMainMenuLeavingHooks()
end)

sdlext.addMainMenuEnteredHook(function(screen, wasHangar, wasGame)
	leaving = false
	Profile = modApi:loadProfile()
end)

sdlext.addUiRootCreatedHook(function(screen, root)
	createUi(root)
end)

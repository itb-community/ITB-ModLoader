--[[
	Root UI object provided by the modloader. 
--]]

local bgRobot = sdlext.surface("img/main_menus/bg3.png")
local bgHangar = sdlext.surface("img/strategy/hangar_main.png")
local loading = sdlext.surface("img/main_menus/Loading_main.png")
local cursor = sdl.surface("resources/mods/ui/pointer-large.png")

-- //////////////////////////////////////////////////////////////////////

local isInMainMenu = false
function sdlext.isMainMenu()
	return isInMainMenu
end

local isInHangar = false
function sdlext.isHangar()
	return isInHangar
end

local isInGame = false
function sdlext.isGame()
	return isInGame
end

local consoleOpen = false
function sdlext.isConsoleOpen()
	return consoleOpen
end

function GetScreenCenter()
	return Point(ScreenSizeX() / 2, ScreenSizeY() / 2)
end

-- //////////////////////////////////////////////////////////////////////
-- UI hooks

local uiRootCreatedHooks = {}
function sdlext.addUiRootCreatedHook(fn)
	assert(type(fn) == "function")
	table.insert(uiRootCreatedHooks, fn)
end

local gameWindowResizedHooks = {}
function sdlext.addGameWindowResizedHook(fn)
	assert(type(fn) == "function")
	table.insert(gameWindowResizedHooks, fn)
end

local mainMenuEnteredHooks = {}
function sdlext.addMainMenuEnteredHook(fn)
	assert(type(fn) == "function")
	table.insert(mainMenuEnteredHooks, fn)
end

local mainMenuExitedHooks = {}
function sdlext.addMainMenuExitedHook(fn)
	assert(type(fn) == "function")
	table.insert(mainMenuExitedHooks, fn)
end

local hangarEnteredHooks = {}
function sdlext.addHangarEnteredHook(fn)
	assert(type(fn) == "function")
	table.insert(hangarEnteredHooks, fn)
end

local hangarExitedHooks = {}
function sdlext.addHangarExitedHook(fn)
	assert(type(fn) == "function")
	table.insert(hangarExitedHooks, fn)
end

local gameEnteredHooks = {}
function sdlext.addGameEnteredHook(fn)
	assert(type(fn) == "function")
	table.insert(gameEnteredHooks, fn)
end

local gameExitedHooks = {}
function sdlext.addGameExitedHook(fn)
	assert(type(fn) == "function")
	table.insert(gameExitedHooks, fn)
end

local consoleToggledHooks = {}
function sdlext.addFrameToggledHook(fn)
	assert(type(fn) == "function")
	table.insert(consoleToggledHooks, fn)
end

local frameDrawnHooks = {}
function sdlext.addFrameDrawnHook(fn)
	assert(type(fn) == "function")
	table.insert(frameDrawnHooks, fn)
end

local windowVisibleHooks = {}
function sdlext.addWindowVisibleHook(fn)
	assert(type(fn) == "function")
	table.insert(windowVisibleHooks, fn)
end

local settingsChangedHooks = {}
function sdlext.addSettingsChangedHook(fn)
	assert(type(fn) == "function")
	table.insert(settingsChangedHooks, fn)
end

-- Key hooks are fired WHEREVER in the game you are, whenever
-- you press a key. So your hooks will need to have a lot of
-- additional restrictions on when they're supposed to fire.

-- Pre key hooks are fired BEFORE the uiRoot handles the key events.
-- These hooks can be used to completely hijack input and bypass the
-- normal focus-based key event handling.
local preKeyDownHooks = {}
function sdlext.addPreKeyDownHook(fn)
	assert(type(fn) == "function")
	table.insert(preKeyDownHooks, fn)
end

local preKeyUpHooks = {}
function sdlext.addPreKeyUpHook(fn)
	assert(type(fn) == "function")
	table.insert(preKeyUpHooks, fn)
end

-- Post key hooks are fired AFTER the uiRoot has handled the key
-- events. These hooks can be used to process leftover key events
-- which haven't been handled via the normal focus-based key event
-- handling.
local postKeyDownHooks = {}
function sdlext.addPostKeyDownHook(fn)
	assert(type(fn) == "function")
	table.insert(postKeyDownHooks, fn)
end

local postKeyUpHooks = {}
function sdlext.addPostKeyUpHook(fn)
	assert(type(fn) == "function")
	table.insert(postKeyUpHooks, fn)
end

local wasOptionsWindow = false
local isOptionsWindow = false
sdlext.addFrameDrawnHook(function(screen)
	if wasOptionsWindow and not isOptionsWindow then
		-- Settings window was visible, but isn't anymore.
		-- This also triggers when the player hovers over
		-- an option in the options box, but this heuristic
		-- is good enough (at least we're not reloading
		-- the settings file every damn frame)
		local oldSettings = Settings
		Settings = modApi:loadSettings()

		if not compare_tables(oldSettings, Settings) then
			for i, hook in ipairs(settingsChangedHooks) do
				hook(oldSettings, Settings)
			end
		end
	end

	wasOptionsWindow = isOptionsWindow
	isOptionsWindow = false
end)

local optionsBox = Boxes.escape_options_box
local profileBox = Boxes.profile_window
sdlext.addWindowVisibleHook(function(screen, x, y, w, h)
	if
		(w == optionsBox.w and h == optionsBox.h) or
		(w == profileBox.w and h == profileBox.h)
	then
		isOptionsWindow = true
	end
end)

sdlext.addPreKeyDownHook(function(keycode)
	if keycode == 96 then -- tilde/backtick
		consoleOpen = not consoleOpen

		for _, hook in ipairs(consoleToggledHooks) do
			hook(consoleOpen)
		end
	end

	-- don't process other keypresses while the console is open
	if sdlext.isConsoleOpen() then
		return false
	end

	if keycode == Settings.hotkeys[23] then -- fullscreen hotkey
		Settings.fullscreen = 1 - Settings.fullscreen

		-- Game doesn't update settings.lua with new fullscreen status...
		-- Only writes to the file once the options menu is dismissed.
		modApi:writeFile(
			os.getKnownFolder(5).."/My Games/Into The Breach/settings.lua",
			"Settings = " .. save_table(Settings)
		)
		isOptionsWindow = true
	end

	return false
end)

sdlext.addSettingsChangedHook(function(old, new)
	if old.last_profile ~= new.last_profile then
		Profile = modApi:loadProfile()
	end
end)

sdlext.addGameWindowResizedHook(function(screen, oldSize)
	sdlext.getUiRoot():widthpx(screen:w()):heightpx(screen:h())
end)

-- //////////////////////////////////////////////////////////////////////

local uiRoot = nil
function sdlext.getUiRoot()
	return uiRoot
end

local srfBotLeft, srfTopRight
local function buildUiRoot(screen)
	uiRoot = UiRoot():widthpx(screen:w()):heightpx(screen:h())

	srfBotLeft = sdlext.surface("img/ui/tooltipshadow_0.png")
	srfTopRight = sdlext.surface("img/ui/tooltipshadow_4.png")

	for i, hook in ipairs(uiRootCreatedHooks) do
		hook(screen, uiRoot)
	end

	-- clear the list of hooks since we're not gonna call it again
	uiRootCreatedHooks = nil
end

local lastScreenSize = { x = ScreenSizeX(), y = ScreenSizeY() }
sdlext.CurrentWindowRect = sdl.rect(0, 0, 0, 0)
sdlext.LastWindowRect = sdl.rect(0, 0, 0, 0)
MOD_API_DRAW_HOOK = sdl.drawHook(function(screen)
	local wasMainMenu = isInMainMenu
	local wasHangar = isInHangar
	local wasGame = isInGame

	isInMainMenu = bgRobot:wasDrawn() and bgRobot.x < screen:w() and not bgHangar:wasDrawn()
	isInHangar = bgHangar:wasDrawn()
	isInGame = Game ~= nil

	if not uiRoot then
		buildUiRoot(screen)
	end

	if
		lastScreenSize.x ~= screen:w() or
		lastScreenSize.y ~= screen:h()
	then
		local oldSize = copy_table(lastScreenSize)
		for i, hook in ipairs(gameWindowResizedHooks) do
			hook(screen, oldSize)
		end

		lastScreenSize.x = screen:w()
		lastScreenSize.y = screen:h()
	end

	if wasMainMenu and not isInMainMenu then
		for i, hook in ipairs(mainMenuExitedHooks) do
			hook(screen)
		end
	elseif wasHangar and not isInHangar then
		for i, hook in ipairs(hangarExitedHooks) do
			hook(screen)
		end
	elseif wasGame and not isInGame then
		for i, hook in ipairs(gameExitedHooks) do
			hook(screen)
		end
	end

	if not wasMainMenu and isInMainMenu then
		for i, hook in ipairs(mainMenuEnteredHooks) do
			hook(screen, wasHangar, wasGame)
		end
	elseif not wasHangar and isInHangar then
		for i, hook in ipairs(hangarEnteredHooks) do
			hook(screen)
		end
	elseif not wasGame and isInGame then
		for i, hook in ipairs(gameEnteredHooks) do
			hook(screen)
		end
	end

	local wx, wy, ww, wh
	if srfBotLeft:wasDrawn() and srfTopRight:wasDrawn() then
		wx = srfBotLeft.x
		wy = srfTopRight.y - 4
		ww = srfTopRight.x - wx
		wh = srfBotLeft.y  - wy
	end

	if not rect_equals(sdlext.CurrentWindowRect, wx, wy, ww, wh) then
		rect_set(sdlext.LastWindowRect, sdlext.CurrentWindowRect)
	end

	rect_set(sdlext.CurrentWindowRect, wx, wy, ww, wh)
	if wx ~= nil then
		for i, hook in ipairs(windowVisibleHooks) do
			hook(screen, wx, wy, ww, wh)
		end
	end

	uiRoot:draw(screen)

	for i, hook in ipairs(frameDrawnHooks) do
		hook(screen)
	end

	if not loading:wasDrawn() then
		screen:blit(cursor, nil, sdl.mouse.x(), sdl.mouse.y())
	end
end)

MOD_API_EVENT_HOOK = sdl.eventHook(function(event)
	local type = event:type()
	local keycode = event:keycode()

	if type == sdl.events.keydown then
		for i, hook in ipairs(preKeyDownHooks) do
			if hook(keycode) then
				return true
			end
		end
	elseif type == sdl.events.keyup then
		for i, hook in ipairs(preKeyUpHooks) do
			if hook(keycode) then
				return true
			end
		end
	end

	local result = uiRoot:event(event)

	if not result then
		if type == sdl.events.keydown then
			for i, hook in ipairs(postKeyDownHooks) do
				if hook(keycode) then
					return true
				end
			end
		elseif type == sdl.events.keyup then
			for i, hook in ipairs(postKeyUpHooks) do
				if hook(keycode) then
					return true
				end
			end
		end
	end

	return result
end)

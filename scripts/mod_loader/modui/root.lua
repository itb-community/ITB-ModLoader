
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
	return wasGame
end

-- //////////////////////////////////////////////////////////////////////
-- UI hooks

local uiRootCreatedHooks = {}
function sdlext.addUiRootCreatedHook(fn)
	assert(type(fn) == "function")
	table.insert(uiRootCreatedHooks, fn)
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

-- //////////////////////////////////////////////////////////////////////

local uiRoot = nil
function sdlext.getUiRoot()
	return uiRoot
end

local srfBotLeft, srfTopRight
local function buildUiRoot(screen)
	uiRoot = UiRoot():widthpx(screen:w()):heightpx(screen:h())

	uiRoot.keydown = function(self, keycode)
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

		return Ui.keydown(self, keycode)
	end

	srfBotLeft = sdlext.surface("img/ui/tooltipshadow_0.png")
	srfTopRight = sdlext.surface("img/ui/tooltipshadow_4.png")

	for i, hook in ipairs(uiRootCreatedHooks) do
		hook(screen, uiRoot)
	end

	-- clear the list of hooks since we're not gonna call it again
	uiRootCreatedHooks = nil
end

sdlext.CurrentWindowRect = sdl.rect(0, 0, 0, 0)
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
	uiRoot:widthpx(screen:w()):heightpx(screen:h())

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

	uiRoot:draw(screen)

	sdlext.CurrentWindowRect.x = 0
	sdlext.CurrentWindowRect.y = 0
	sdlext.CurrentWindowRect.w = 0
	sdlext.CurrentWindowRect.h = 0

	if srfBotLeft:wasDrawn() and srfTopRight:wasDrawn() then
		sdlext.CurrentWindowRect.x = srfBotLeft.x
		sdlext.CurrentWindowRect.y = srfTopRight.y - 4
		sdlext.CurrentWindowRect.w = srfTopRight.x - sdlext.CurrentWindowRect.x
		sdlext.CurrentWindowRect.h = srfBotLeft.y  - sdlext.CurrentWindowRect.y

		for i, hook in ipairs(windowVisibleHooks) do
			hook(
				screen,
				sdlext.CurrentWindowRect.x,
				sdlext.CurrentWindowRect.y,
				sdlext.CurrentWindowRect.w,
				sdlext.CurrentWindowRect.h
			)
		end
	end

	for i, hook in ipairs(frameDrawnHooks) do
		hook(screen)
	end

	if not loading:wasDrawn() then
		screen:blit(cursor, nil, sdl.mouse.x(), sdl.mouse.y())
	end
end)

MOD_API_EVENT_HOOK = sdl.eventHook(function(event)
	return uiRoot:event(event)
end)

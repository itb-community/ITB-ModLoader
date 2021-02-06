--[[
	Root UI object provided by the modloader. 
--]]

local bgRobot = nil
local bgHangar = nil

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

local initialLoadingFinishedEventFired = false

local isShiftHeld = false
function sdlext.isShiftDown()
	return isShiftHeld
end

local isAltHeld = false
function sdlext.isAltDown()
	return isAltHeld
end

local isCtrlHeld = false
function sdlext.isCtrlDown()
	return isCtrlHeld
end

local wasOptionsWindow = false
local isOptionsWindow = false
modApi.events.onFrameDrawn:subscribe(function(screen)
	if wasOptionsWindow and not isOptionsWindow then
		-- Settings window was visible, but isn't anymore.
		-- This also triggers when the player hovers over
		-- an option in the options box, but this heuristic
		-- is good enough (at least we're not reloading
		-- the settings file every damn frame)
		local oldSettings = Settings
		Settings = modApi:loadSettings()

		if not compare_tables(oldSettings, Settings) then
			modApi.events.onSettingsChanged:dispatch(oldSettings, Settings)
		end
	end

	wasOptionsWindow = isOptionsWindow
	isOptionsWindow = false
end)

local optionsBox = Boxes.escape_options_box
local profileBox = Boxes.profile_window
local function adjustForGameVersion()
	if modApi:isVersion("1.2.20", modApi:getGameVersion()) then
		--
	end
	if modApi:isVersion("1.1.22", modApi:getGameVersion()) then
		optionsBox = Rect2D(optionsBox)
		optionsBox.w = optionsBox.w + 300
	end
end

modApi.events.onWindowVisible:subscribe(function(screen, x, y, w, h)
	if
		(w == optionsBox.w and h == optionsBox.h) or
		(w == profileBox.w and h == profileBox.h)
	then
		isOptionsWindow = true
	end
end)

modApi.events.onKeyPressing:subscribe(function(keycode)
	if keycode == SDLKeycodes.SHIFT_LEFT or keycode == SDLKeycodes.SHIFT_RIGHT then
		isShiftHeld = true
		modApi.events.onShiftToggled:dispatch(isShiftHeld)
	elseif keycode == SDLKeycodes.ALT_LEFT or keycode == SDLKeycodes.ALT_RIGHT then
		isAltHeld = true
		modApi.events.onAltToggled:dispatch(isAltHeld)
	elseif keycode == SDLKeycodes.CTRL_LEFT or keycode == SDLKeycodes.CTRL_RIGHT then
		isCtrlHeld = true
		modApi.events.onCtrlToggled:dispatch(isCtrlHeld)
	end

	-- don't process other keypresses while the console is open
	if sdlext.isConsoleOpen() then
		return false
	end

	if keycode == Settings.hotkeys[HOTKEY.TOGGLE_FULLSCREEN] then
		Settings.fullscreen = 1 - Settings.fullscreen

		-- Game doesn't update settings.lua with new fullscreen status...
		-- Only writes to the file once the options menu is dismissed.
		modApi:writeFile(
			GetSavedataLocation() .. "settings.lua",
			"Settings = " .. save_table(Settings)
		)
		isOptionsWindow = true
	end

	return false
end)

modApi.events.onKeyReleasing:subscribe(function(keycode)
	if keycode == SDLKeycodes.SHIFT_LEFT or keycode == SDLKeycodes.SHIFT_RIGHT then
		isShiftHeld = false
		modApi.events.onShiftToggled:dispatch(isShiftHeld)
	elseif keycode == SDLKeycodes.ALT_LEFT or keycode == SDLKeycodes.ALT_RIGHT then
		isAltHeld = false
		modApi.events.onAltToggled:dispatch(isAltHeld)
	elseif keycode == SDLKeycodes.CTRL_LEFT or keycode == SDLKeycodes.CTRL_RIGHT then
		isCtrlHeld = false
		modApi.events.onCtrlToggled:dispatch(isCtrlHeld)
	end
	
	-- don't process other keypresses while the console is open
	if sdlext.isConsoleOpen() then
		return false
	end

	return false
end)

modApi.events.onSettingsChanged:subscribe(function(old, new)
	-- When deleting the currently active profile, last_profile is nil
	-- Just copy it over from the previous table, since it holds the correct value
	if not new.last_profile or new.last_profile == "" then
		new.last_profile = old.last_profile
	end

	if old.last_profile ~= new.last_profile then
		Hangar_lastProfileHadSecretPilots = IsSecretPilotsUnlocked()
		Profile = modApi:loadProfile()
	end
end)

modApi.events.onGameWindowResized:subscribe(function(screen, oldSize)
	sdlext.getUiRoot():widthpx(screen:w()):heightpx(screen:h())
end)

-- //////////////////////////////////////////////////////////////////////

local uiRoot = nil
function sdlext.getUiRoot()
	return uiRoot
end

local srfBotLeft, srfTopRight
local function buildUiRoot(screen)
	adjustForGameVersion()

	uiRoot = UiRoot():widthpx(screen:w()):heightpx(screen:h())

	uiRoot.wheel = function(self, mx, my, scroll)
		if sdlext.isConsoleOpen() and mod_loader.logger.scroll then
			if isShiftHeld then
				scroll = scroll * 20
			end

			mod_loader.logger:scroll(-scroll)
			
			return true
		end

		return Ui.wheel(self, mx, my, scroll)
	end

	uiRoot.keydown = function(self, keycode)
		if sdlext.isConsoleOpen() and mod_loader.logger.scroll then
			if keycode == SDLKeycodes.PAGEUP then
				if isShiftHeld then
					mod_loader.logger:scrollToStart()
				else
					mod_loader.logger:scroll(-20)
				end

				return true
			elseif keycode == SDLKeycodes.PAGEDOWN then
				if isShiftHeld then
					mod_loader.logger:scrollToEnd()
				else
					mod_loader.logger:scroll(20)
				end

				return true
			end
		end

		return Ui.keydown(self, keycode)
	end

	srfBotLeft = sdlext.getSurface({ path = "img/ui/tooltipshadow_0.png" })
	srfTopRight = sdlext.getSurface({ path = "img/ui/tooltipshadow_4.png" })
end

local isTestMech = false
local lastScreenSize = { x = ScreenSizeX(), y = ScreenSizeY() }
sdlext.CurrentWindowRect = sdl.rect(0, 0, 0, 0)
sdlext.LastWindowRect = sdl.rect(0, 0, 0, 0)
MOD_API_DRAW_HOOK = sdl.drawHook(function(screen)
	if not modApi or not modApi.initialized then
		return
	end

	local wasMainMenu = isInMainMenu
	local wasHangar = isInHangar
	local wasGame = isInGame
	local wasTestMech = isTestMech

	if not bgRobot then
		bgRobot = sdlext.getSurface({ path = "img/main_menus/bg3.png" })
		bgHangar = sdlext.getSurface({ path = "img/strategy/hangar_main.png" })
	end

	isInMainMenu = bgRobot:wasDrawn() and bgRobot.x < screen:w() and not bgHangar:wasDrawn()
	isInHangar = bgHangar:wasDrawn()
	isInGame = Game ~= nil
	isTestMech = IsTestMechScenario()

	-- ////////////////////////////////////////////////////////
	-- Hooks
	if not initialLoadingFinishedEventFired and bgRobot:wasDrawn() then
		initialLoadingFinishedEventFired = true
		modApi.events.onInitialLoadingFinished:dispatch()
		modApi.events.onInitialLoadingFinished:unsubscribeAll()
	end

	if not uiRoot then
		modApi.events.onUiRootCreating:dispatch(screen)
		modApi.events.onUiRootCreating:unsubscribeAll()

		buildUiRoot(screen)

		modApi.events.onUiRootCreated:dispatch(screen, uiRoot)
		modApi.events.onUiRootCreated:unsubscribeAll()
	end

	if
		lastScreenSize.x ~= screen:w() or
		lastScreenSize.y ~= screen:h()
	then
		local oldSize = copy_table(lastScreenSize)
		modApi.events.onGameWindowResized:dispatch(screen, oldSize)

		lastScreenSize.x = screen:w()
		lastScreenSize.y = screen:h()
	end

	if wasMainMenu and not isInMainMenu then
		modApi.events.onMainMenuExited:dispatch(screen)
	elseif wasHangar and not isInHangar then
		modApi.events.onHangarExited:dispatch(screen)
	elseif wasGame and not isInGame then
		modApi.events.onGameExited:dispatch(screen)
	end

	if not wasMainMenu and isInMainMenu then
		modApi.events.onMainMenuEntered:dispatch(screen, wasHangar, wasGame)
	elseif not wasHangar and isInHangar then
		modApi.events.onHangarEntered:dispatch(screen)
	elseif not wasGame and isInGame then
		modApi.events.onGameEntered:dispatch(screen)
	end

	if wasTestMech and not isTestMech then
		Mission_Test:MissionEnd()
	end

	-- ////////////////////////////////////////////////////////

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
		modApi.events.onWindowVisible:dispatch(screen, wx, wy, ww, wh)
	end

	uiRoot:draw(screen)

	modApi.events.onFrameDrawn:dispatch(screen)
end)

local function evaluateConsoleToggled(keycode)
	if keycode == SDLKeycodes.BACKQUOTE then
		consoleOpen = not consoleOpen

		modApi.events.onConsoleToggled:dispatch(consoleOpen)
	elseif consoleOpen and sdlext.isShiftDown() and (keycode == SDLKeycodes.RETURN or keycode == SDLKeycodes.RETURN2) then
		consoleOpen = false

		modApi.events.onConsoleToggled:dispatch(consoleOpen)
	end
end

MOD_API_EVENT_HOOK = sdl.eventHook(function(event)
	local type = event:type()
	local keycode = event:keycode()

	if type == sdl.events.keydown then
		if modApi.events.onKeyPressing:dispatch(keycode) then
			return true
		end
	elseif type == sdl.events.keyup then
		if modApi.events.onKeyReleasing:dispatch(keycode) then
			return true
		end
	end

	local result = uiRoot:event(event)

	if not result then
		if type == sdl.events.keydown then
			if modApi.events.onKeyPressed:dispatch(keycode) then
				return true
			end

			evaluateConsoleToggled(keycode)
		elseif type == sdl.events.keyup then
			if modApi.events.onKeyReleased:dispatch(keycode) then
				return true
			end
		end
	end

	return result
end)

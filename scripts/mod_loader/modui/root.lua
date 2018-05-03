
local bgRobot = sdlext.surface("img/main_menus/bg3.png")
local bgHangar = sdlext.surface("img/strategy/hangar_main.png")
local loading = sdlext.surface("img/main_menus/Loading_main.png")
local cursor = sdl.surface("resources/mods/ui/pointer-noshadow.png")

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

-- //////////////////////////////////////////////////////////////////////

local uiRoot = nil
MOD_API_DRAW_HOOK = sdl.drawHook(function(screen)
	if not sdlext.isEventLoop() then
		local wasMainMenu = isInMainMenu
		local wasHangar = isInHangar
		local wasGame = isGame

		isInMainMenu = bgRobot:wasDrawn() and bgRobot.x < screen:w() and not bgHangar:wasDrawn()
		isInHangar = bgHangar:wasDrawn()
		isInGame = Game ~= nil

		if not uiRoot then
			uiRoot = UiRoot()
			for i, hook in ipairs(uiRootCreatedHooks) do
				hook(screen, uiRoot)
			end
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
		end

		if not wasMainMenu and isInMainMenu then
			for i, hook in ipairs(mainMenuEnteredHooks) do
				hook(screen, wasHangar, wasGame)
			end
		elseif not wasHangar and isInHangar then
			for i, hook in ipairs(hangarEnteredHooks) do
				hook(screen)
			end
		end

		uiRoot:draw(screen)
	end

	if not loading:wasDrawn() then
		screen:blit(cursor, nil, sdl.mouse.x(), sdl.mouse.y())
	end
end)

MOD_API_EVENT_HOOK = sdl.eventHook(function(event)
	if not sdlext.isEventLoop() then
		return uiRoot:event(event)
	end

	return false
end)

function sdlext.addSettingsChangedHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onSettingsChanged:subscribe(fn)
end

function sdlext.addFrameDrawnHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onFrameDrawn:subscribe(fn)
end

function sdlext.addConsoleToggledHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onConsoleToggled:subscribe(fn)
end

function sdlext.addMainMenuExitedHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onMainMenuExited:subscribe(fn)
end

function sdlext.addHangarExitedHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onHangarExited:subscribe(fn)
end

function sdlext.addGameExitedHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onGameExited:subscribe(fn)
end

function sdlext.addMainMenuEnteredHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onMainMenuEntered:subscribe(fn)
end

function sdlext.addHangarEnteredHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onHangarEntered:subscribe(fn)
end

function sdlext.addGameEnteredHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onGameEntered:subscribe(fn)
end

function sdlext.addGameWindowResizedHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onGameWindowResized:subscribe(fn)
end

function sdlext.addInitialLoadingFinishedHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onInitialLoadingFinished:subscribe(fn)
end

function sdlext.addUiRootCreatedHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onUiRootCreated:subscribe(fn)
end

function sdlext.addWindowVisibleHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onWindowVisible:subscribe(fn)
end

function sdlext.addShiftToggledHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onShiftToggled:subscribe(fn)
end

function sdlext.addAltToggledHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onAltToggled:subscribe(fn)
end

function sdlext.addCtrlToggledHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onCtrlToggled:subscribe(fn)
end

-- Key hooks are fired WHEREVER in the game you are, whenever
-- you press a key. So your hooks will need to have a lot of
-- additional restrictions on when they're supposed to fire.

-- Pre key hooks are fired BEFORE the uiRoot handles the key events.
-- These hooks can be used to completely hijack input and bypass the
-- normal focus-based key event handling.
function sdlext.addPreKeyDownHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onKeyPressing:subscribe(fn)
end

function sdlext.addPreKeyUpHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onKeyReleasing:subscribe(fn)
end

-- Post key hooks are fired AFTER the uiRoot has handled the key
-- events. These hooks can be used to process leftover key events
-- which haven't been handled via the normal focus-based key event
-- handling.
function sdlext.addPostKeyDownHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onKeyPressed:subscribe(fn)
end

function sdlext.addPostKeyUpHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onKeyReleased:subscribe(fn)
end

function sdlext.addHangarLeavingHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onHangarLeaving:subscribe(fn)
end

function sdlext.addMainMenuLeavingHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onMainMenuLeaving:subscribe(fn)
end

function sdlext.addContinueClickHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onContinueClicked:subscribe(fn)
end

function sdlext.addNewGameClickHook(fn)
	assert(type(fn) == "function")
	return modApi.events.onNewGameClicked:subscribe(fn)
end
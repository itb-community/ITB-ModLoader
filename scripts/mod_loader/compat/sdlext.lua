function sdlext.addSettingsChangedHook(fn)
	return modApi.events.onSettingsChanged:subscribe(fn)
end

function sdlext.addFrameDrawnHook(fn)
	return modApi.events.onFrameDrawn:subscribe(fn)
end

function sdlext.addConsoleToggledHook(fn)
	return modApi.events.onConsoleToggled:subscribe(fn)
end

function sdlext.addMainMenuExitedHook(fn)
	return modApi.events.onMainMenuExited:subscribe(fn)
end

function sdlext.addHangarExitedHook(fn)
	return modApi.events.onHangarExited:subscribe(fn)
end

function sdlext.addGameExitedHook(fn)
	return modApi.events.onGameExited:subscribe(fn)
end

function sdlext.addMainMenuEnteredHook(fn)
	return modApi.events.onMainMenuEntered:subscribe(fn)
end

function sdlext.addHangarEnteredHook(fn)
	return modApi.events.onHangarEntered:subscribe(fn)
end

function sdlext.addGameEnteredHook(fn)
	return modApi.events.onGameEntered:subscribe(fn)
end

function sdlext.addGameWindowResizedHook(fn)
	return modApi.events.onGameWindowResized:subscribe(fn)
end

function sdlext.addInitialLoadingFinishedHook(fn)
	return modApi.events.onInitialLoadingFinished:subscribe(fn)
end

function sdlext.addUiRootCreatedHook(fn)
	return modApi.events.onUiRootCreated:subscribe(fn)
end

function sdlext.addWindowVisibleHook(fn)
	return modApi.events.onWindowVisible:subscribe(fn)
end

function sdlext.addShiftToggledHook(fn)
	return modApi.events.onShiftToggled:subscribe(fn)
end

function sdlext.addAltToggledHook(fn)
	return modApi.events.onAltToggled:subscribe(fn)
end

function sdlext.addCtrlToggledHook(fn)
	return modApi.events.onCtrlToggled:subscribe(fn)
end

-- Key hooks are fired WHEREVER in the game you are, whenever
-- you press a key. So your hooks will need to have a lot of
-- additional restrictions on when they're supposed to fire.

-- Pre key hooks are fired BEFORE the uiRoot handles the key events.
-- These hooks can be used to completely hijack input and bypass the
-- normal focus-based key event handling.
function sdlext.addPreKeyDownHook(fn)
	return modApi.events.onKeyPressing:subscribe(fn)
end

function sdlext.addPreKeyUpHook(fn)
	return modApi.events.onKeyReleasing:subscribe(fn)
end

-- Post key hooks are fired AFTER the uiRoot has handled the key
-- events. These hooks can be used to process leftover key events
-- which haven't been handled via the normal focus-based key event
-- handling.
function sdlext.addPostKeyDownHook(fn)
	return modApi.events.onKeyPressed:subscribe(fn)
end

function sdlext.addPostKeyUpHook(fn)
	return modApi.events.onKeyReleased:subscribe(fn)
end

function sdlext.addHangarLeavingHook(fn)
	return modApi.events.onHangarLeaving:subscribe(fn)
end

function sdlext.addMainMenuLeavingHook(fn)
	return modApi.events.onMainMenuLeaving:subscribe(fn)
end

function sdlext.addContinueClickHook(fn)
	return modApi.events.onContinueClicked:subscribe(fn)
end

function sdlext.addNewGameClickHook(fn)
	return modApi.events.onNewGameClicked:subscribe(fn)
end
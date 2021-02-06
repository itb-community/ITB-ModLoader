local rootpath = GetParentPath(...)

modApi = {}

modApi.events = {}

local t = modApi.events
t.onModsInitialized = Event()
t.onModsLoaded = Event()
t.onModsFirstLoaded = Event()
t.onInitialLoadingFinished = Event()

t.onUiRootCreating = Event()
t.onUiRootCreated = Event()
t.onGameWindowResized = Event()
t.onConsoleToggled = Event()
t.onFrameDrawn = Event()
t.onWindowVisible = Event()

t.onMainMenuEntered = Event()
t.onMainMenuExited = Event()
t.onMainMenuLeaving = Event()
t.onHangarEntered = Event()
t.onHangarExited = Event()
t.onHangarLeaving = Event()
t.onGameEntered = Event()
t.onGameExited = Event()
t.onNewGameClicked = Event()
t.onContinueClicked = Event()
t.onSettingsChanged = Event()

t.onShiftToggled = Event()
t.onAltToggled = Event()
t.onCtrlToggled = Event()
t.onKeyPressing = Event({ [Event.SHORTCIRCUIT] = true })
t.onKeyPressed = Event({ [Event.SHORTCIRCUIT] = true })
t.onKeyReleasing = Event({ [Event.SHORTCIRCUIT] = true })
t.onKeyReleased = Event({ [Event.SHORTCIRCUIT] = true })

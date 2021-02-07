modApi = {}

-- //////////////////////////////////////////////////////////////////////////////
-- Events

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

-- //////////////////////////////////////////////////////////////////////////////
-- Hooks

modApi.hooks = {}

function modApi:AddHook(name)
	local Name = name:gsub("^.", string.upper) -- capitalize first letter
	local name = name:gsub("^.", string.lower) -- lower case first letter

	table.insert(self.hooks, name)
	self[name .."Hooks"] = {}
	self.events["on".. Name] = Event()

	self["add".. Name .."Hook"] = function(self, fn)
		assert(type(fn) == "function")
		table.insert(self[name .."Hooks"], fn)
	end

	self["rem".. Name .."Hook"] = function(self, fn)
		remove_element(fn, self[name .."Hooks"])
	end

	self["fire".. Name .."Hooks"] = function(self, ...)
		self.events["on".. Name]:dispatch(...)
	end

	self.events["on".. Name]:subscribe(function(...)
		for _, fn in ipairs(self[name .."Hooks"]) do
			fn(...)
		end
	end)
end

function modApi:ResetHooks()
	for _, name in ipairs(self.hooks) do
		self[name .."Hooks"] = {}
	end

	self.hotkey:resetHooks()
end

local hooks = {
	"PreMissionAvailable",
	"PostMissionAvailable",
	"PreEnvironment",
	"PostEnvironment",
	"NextTurn",
	"VoiceEvent",
	"PreIslandSelection",
	"PostIslandSelection",
	"MissionUpdate",
	"MissionStart",
	"MissionEnd",
	"MissionNextPhaseCreated",
	"PreStartGame",
	"PostStartGame",
	"PreLoadGame",
	"PostLoadGame",
	"SaveGame",
	"VekSpawnAdded",
	"VekSpawnRemoved",
	"PreprocessVekRetreat",
	"ProcessVekRetreat",
	"PostprocessVekRetreat",
	"ModsLoaded",
	"TestMechEntered",
	"TestMechExited",
	"SaveDataUpdated",
	"TipImageShown",
	"TipImageHidden",
	"PawnFocused",
	"PawnUnfocused",
}

for _, name in ipairs(hooks) do
	modApi:AddHook(name)
end

modApi = modApi or {}

-- //////////////////////////////////////////////////////////////////////////////
-- Events

eventCreationLog = {}

local events_mt = {
	__newindex = function(self, key, value)
		local trace = debug.traceback()
		eventCreationLog[key] = trace
		rawset(self, key, value)
	end
}
modApi.events = {}
setmetatable(modApi.events, events_mt)

local t = modApi.events
t.onModMetadataDone = Event()
t.onModsMetadataDone = Event()
t.onModInitialized = Event()
t.onModsInitialized = Event()
t.onModLoaded = Event()
t.onModsLoaded = Event()
t.onModsFirstLoaded = Event()
t.onInitialLoadingFinished = Event()
t.onFtldatFinalized = Event()
t.onModContentReset = Event()

t.onUiRootCreating = Event()
t.onUiRootCreated = Event()
t.onGameWindowResized = Event()
t.onConsoleToggled = Event()
t.onFrameDrawStart = Event()
t.onFrameDrawn = Event()
t.onWindowVisible = Event()

t.onMainMenuEntered = Event()
t.onMainMenuExited = Event()
t.onMainMenuLeaving = Event()
t.onHangarEntered = Event()
t.onHangarExited = Event()
t.onHangarLeaving = Event()
t.onHangarMechsSelected = Event()
t.onHangarMechsCleared = Event()
t.onHangarSquadSelected = Event()
t.onHangarSquadCleared = Event()
t.onGameEntered = Event()
t.onGameExited = Event()
t.onNewGameClicked = Event()
t.onContinueClicked = Event()
t.onSettingsChanged = Event()
t.onSettingsInitialized = Event()
t.onProfileChanged = Event()
t.onProfileCreated = Event()
t.onProfileDeleted = Event()
t.onDifficultyChanged = Event()

t.onHangarUiShown = Event()
t.onHangarUiHidden = Event()
t.onEscapeMenuWindowShown = Event()
t.onEscapeMenuWindowHidden = Event()
t.onSquadSelectionWindowShown = Event()
-- arguments: newPage, lastPage, wasOpen
t.onSquadSelectionPageChanged = Event()
t.onSquadSelectionWindowHidden = Event()
t.onCustomizeSquadWindowShown = Event()
t.onCustomizeSquadWindowHidden = Event()
t.onPilotSelectionWindowShown = Event()
t.onPilotSelectionWindowHidden = Event()
t.onDifficultySettingsWindowShown = Event()
t.onDifficultySettingsWindowHidden = Event()
t.onMechColorWindowShown = Event()
t.onMechColorWindowHidden = Event()
t.onAchievementsWindowShown = Event()
t.onAchievementsWindowHidden = Event()
t.onOptionsWindowShown = Event()
t.onOptionsWindowHidden = Event()
t.onLanguageSelectionWindowShown = Event()
t.onLanguageSelectionWindowHidden = Event()
t.onHotkeyConfigurationWindowShown = Event()
t.onHotkeyConfigurationWindowHidden = Event()
t.onProfileSelectionWindowShown = Event()
t.onProfileSelectionWindowHidden = Event()
t.onCreateProfileConfirmationWindowShown = Event()
t.onCreateProfileConfirmationWindowHidden = Event()
t.onDeleteProfileConfirmationWindowShown = Event()
t.onDeleteProfileConfirmationWindowHidden = Event()
t.onStatisticsWindowShown = Event()
t.onStatisticsWindowHidden = Event()
t.onNewGameWindowShown = Event()
t.onNewGameWindowHidden = Event()
t.onAbandonTimelineWindowShown = Event()
t.onAbandonTimelineWindowHidden = Event()
t.onStatusTooltipWindowShown = Event()
t.onStatusTooltipWindowHidden = Event()
t.onMapEditorTestEntered = Event()
t.onMapEditorTestExited = Event()
t.onWindowShown = Event()
t.onWindowHidden = Event()

t.onMissionChanged = Event()
t.onMissionDismissed = Event()
t.onIslandLeft = Event()
t.onGameStateChanged = Event()
t.onGameVictory = Event()
t.onSquadEnteredGame = Event()
t.onSquadExitedGame = Event()

t.onDeploymentPhaseStart = Event()
t.onLandingPhaseStart = Event()
t.onDeploymentPhaseEnd = Event()
t.onPawnUnselectedForDeployment = Event()
t.onPawnSelectedForDeployment = Event()
t.onPawnDeployed = Event()
t.onPawnUndeployed = Event()
t.onPawnLanding = Event()
t.onPawnLanded = Event()

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
	"PawnSelected",
	"PawnDeselected",
}

for _, name in ipairs(hooks) do
	modApi:AddHook(name)
end

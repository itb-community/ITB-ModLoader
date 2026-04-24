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
modApi.eventNames = {
	"onModMetadataDone",
	"onModsMetadataDone",
	"onModInitialized",
	"onModsInitialized",
	"onModLoaded",
	"onModsLoaded",
	"onModsFirstLoaded",
	"onInitialLoadingFinished",
	"onFtldatFinalized",
	"onModContentReset",
	"onTestsuitesCreated",
	
	"onBoardClassInitialized",
	"onPawnClassInitialized",
	"onGameClassInitialized",
	
	"onUiRootCreating",
	"onUiRootCreated",
	"onGameWindowResized",
	"onConsoleToggled",
	"onFrameDrawStart",
	"onFrameDrawn",
	"onWindowVisible",
	
	"onMainMenuEntered",
	"onMainMenuExited",
	"onMainMenuLeaving",
	"onHangarEntered",
	"onHangarExited",
	"onHangarLeaving",
	"onHangarMechsSelected",
	"onHangarMechsCleared",
	"onHangarSquadSelected",
	"onHangarSquadCleared",
	"onGameEntered",
	"onGameExited",
	"onNewGameClicked",
	"onContinueClicked",
	"onSettingsChanged",
	"onSettingsInitialized",
	"onProfileChanged",
	"onProfileCreated",
	"onProfileDeleted",
	"onDifficultyChanged",
	"onLanguageChanged",
	
	"onHangarUiShown",
	"onHangarUiHidden",
	"onEscapeMenuWindowShown",
	"onEscapeMenuWindowHidden",
	"onSquadSelectionWindowShown",
-- arguments: newPage, lastPage, wasOpen
	"onSquadSelectionPageChanged",
	"onSquadSelectionWindowHidden",
	"onCustomizeSquadWindowShown",
	"onCustomizeSquadWindowHidden",
	"onPilotSelectionWindowShown",
	"onPilotSelectionWindowHidden",
	"onDifficultySettingsWindowShown",
	"onDifficultySettingsWindowHidden",
	"onMechColorWindowShown",
	"onMechColorWindowHidden",
	"onAchievementsWindowShown",
	"onAchievementsWindowHidden",
	"onOptionsWindowShown",
	"onOptionsWindowHidden",
	"onLanguageSelectionWindowShown",
	"onLanguageSelectionWindowHidden",
	"onHotkeyConfigurationWindowShown",
	"onHotkeyConfigurationWindowHidden",
	"onProfileSelectionWindowShown",
	"onProfileSelectionWindowHidden",
	"onCreateProfileConfirmationWindowShown",
	"onCreateProfileConfirmationWindowHidden",
	"onDeleteProfileConfirmationWindowShown",
	"onDeleteProfileConfirmationWindowHidden",
	"onStatisticsWindowShown",
	"onStatisticsWindowHidden",
	"onNewGameWindowShown",
	"onNewGameWindowHidden",
	"onAbandonTimelineWindowShown",
	"onAbandonTimelineWindowHidden",
	"onStatusTooltipWindowShown",
	"onStatusTooltipWindowHidden",
	"onMapEditorTestEntered",
	"onMapEditorTestExited",
	"onPodWindowShown",
	"onPodWindowHidden",
	"onPerfectIslandWindowShown",
	"onPerfectIslandWindowHidden",
	"onWindowShown",
	"onWindowHidden",
	
	"onMissionChanged",
	"onMissionDismissed",
	"onIslandLeft",
	"onGameStateChanged",
	"onGameVictory",
	"onSquadEnteredGame",
	"onSquadExitedGame",
	"onTilesetChanged",
	"onFinalIslandHighlighted",
	"onFinalIslandUnhighlighted",
	"onFinalIslandSelected",
	"onFinalIslandDeselected",
	
	"onDeploymentPhaseStart",
	"onLandingPhaseStart",
	"onDeploymentPhaseEnd",
	"onPawnUnselectedForDeployment",
	"onPawnSelectedForDeployment",
	"onPawnDeployed",
	"onPawnUndeployed",
	"onPawnLanding",
	"onPawnLanded",
	
	"onBoardAddEffect",
	"onBoardDamageSpace",
	
	"onShiftToggled",
	"onAltToggled",
	"onCtrlToggled",
}

for _, event in ipairs(modApi.eventNames) do
	t[event] = Event({ eventName = event })
end

modApi.shortcutEventNames = {
	"onKeyPressing",
	"onKeyPressed",
	"onKeyReleasing",
	"onKeyReleased",
}

for _, event in ipairs(modApi.shortcutEventNames) do
	t[event] = Event({ eventName = event, [Event.SHORTCIRCUIT] = true })
end

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

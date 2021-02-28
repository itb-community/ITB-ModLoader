
local showWindows = {}
local visibleWindows = {}

local Window = {}
CreateClass(Window)

function Window:show(id)
	self.visible = true
	visibleWindows[id] = self
	self.event_show:dispatch()
end

function Window:hide(id)
	self.visible = false
	visibleWindows[id] = nil
	self.event_hide:dispatch()
end

function Window:isVisible()
	return self.visible == true
end

local function buildIsWindowVisibleFunction(window)
	return function()
		return window:isVisible()
	end
end

local windows = {
	Escape_Title = Window:new{
		event_show = modApi.events.onEscapeMenuWindowShown,
		event_hide = modApi.events.onEscapeMenuWindowHidden
	},
	Hangar_Select = Window:new{
		event_show = modApi.events.onSquadSelectionWindowShown,
		event_hide = modApi.events.onSquadSelectionWindowHidden
	},
	Hangar_Achievements_Title = Window:new{
		event_show = modApi.events.onAchievementsWindowShown,
		event_hide = modApi.events.onAchievementsWindowHidden
	},
	Hangar_Pilot = Window:new{
		event_show = modApi.events.onPilotSelectionWindowShown,
		event_hide = modApi.events.onPilotSelectionWindowHidden
	},
	Options_Title = Window:new{
		event_show = modApi.events.onOptionsWindowShown,
		event_hide = modApi.events.onOptionsWindowHidden
	},
	Language_Title = Window:new{
		event_show = modApi.events.onLanguageSelectionWindowShown,
		event_hide = modApi.events.onLanguageSelectionWindowHidden
	},
	Hotkeys_Title = Window:new{
		event_show = modApi.events.onHotkeyConfigurationWindowShown,
		event_hide = modApi.events.onHotkeyConfigurationWindowHidden
	},
	Profile_Title = Window:new{
		event_show = modApi.events.onProfileSelectionWindowShown,
		event_hide = modApi.events.onProfileSelectionWindowHidden
	},
	New_Profile_Title = Window:new{
		event_show = modApi.events.onCreateProfileConfirmationWindowShown,
		event_hide = modApi.events.onCreateProfileConfirmationWindowHidden
	},
	Delete_Confirm_Title = Window:new{
		event_show = modApi.events.onDeleteProfileConfirmationWindowShown,
		event_hide = modApi.events.onDeleteProfileConfirmationWindowHidden
	},
	Stats_Header = Window:new{
		event_show = modApi.events.onStatisticsWindowShown,
		event_hide = modApi.events.onStatisticsWindowHidden
	},
	NewGame_Confirm_Title = Window:new{
		event_show = modApi.events.onNewGameWindowShown,
		event_hide = modApi.events.onNewGameWindowHidden
	},
	Abandon_Confirm_Title = Window:new{
		event_show = modApi.events.onAbandonTimelineWindowShown,
		event_hide = modApi.events.onAbandonTimelineWindowHidden
	},
}

sdlext.isEscapeMenuWindowShown = buildIsWindowVisibleFunction(windows.Escape_Title)
sdlext.isSquadSelectionWindowShown = buildIsWindowVisibleFunction(windows.Hangar_Select)
sdlext.isAchievementsWindowShown = buildIsWindowVisibleFunction(windows.Hangar_Achievements_Title)
sdlext.isPilotSelectionWindowShown = buildIsWindowVisibleFunction(windows.Hangar_Pilot)
sdlext.isOptionsWindowShown = buildIsWindowVisibleFunction(windows.Options_Title)
sdlext.isLanguageSelectionWindowShown = buildIsWindowVisibleFunction(windows.Language_Title)
sdlext.isHotkeyConfigurationWindowShown = buildIsWindowVisibleFunction(windows.Hotkeys_Title)
sdlext.isProfileSelectionWindowShown = buildIsWindowVisibleFunction(windows.Profile_Title)
sdlext.isCreateProfileConfirmationWindowShown = buildIsWindowVisibleFunction(windows.New_Profile_Title)
sdlext.isDeleteProfileConfirmationWindowShown = buildIsWindowVisibleFunction(windows.Delete_Confirm_Title)
sdlext.isStatisticsWindowShown = buildIsWindowVisibleFunction(windows.Stats_Header)
sdlext.isNewGameWindowShown = buildIsWindowVisibleFunction(windows.NewGame_Confirm_Title)
sdlext.isAbandonTimelineWindowShown = buildIsWindowVisibleFunction(windows.Abandon_Confirm_Title)

local oldGetText = GetText
function GetText(id, ...)
	if windows[id] ~= nil then
		showWindows[id] = windows[id]
	end

	return oldGetText(id, ...)
end

modApi.events.onFrameDrawn:subscribe(function()

	for id, window in pairs(visibleWindows) do
		if not showWindows[id] then
			window:hide(id)
		end
	end

	if next(showWindows) ~= nil then
		for id, window in pairs(showWindows) do
			if not window.visible then
				window:show(id)
			end
		end

		showWindows = {}
	end
end)

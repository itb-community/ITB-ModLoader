
local showWindows = {}
local visibleWindows = {}

local Window = {}
CreateClass(Window)

function Window:show(id)
	showWindows[id] = true

	if self.visible then return end

	self.visible = true
	visibleWindows[id] = self
	self.event_show:dispatch(id)
end

function Window:hide(id)
	if not self.visible then return end

	self.visible = false
	visibleWindows[id] = nil
	self.event_hide:dispatch(id)
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
	Button_Hangar_Start = Window:new{
		event_show = modApi.events.onHangarUiShown,
		event_hide = modApi.events.onHangarUiHidden
	},
	Hangar_Select = Window:new{
		event_show = modApi.events.onSquadSelectionWindowShown,
		event_hide = modApi.events.onSquadSelectionWindowHidden
	},
	Customize_Instructions = Window:new{
		event_show = modApi.events.onCustomizeSquadWindowShown,
		event_hide = modApi.events.onCustomizeSquadWindowHidden
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

sdlext.isEscapeMenuWindowVisible = buildIsWindowVisibleFunction(windows.Escape_Title)
sdlext.isHangarUiVisible = buildIsWindowVisibleFunction(windows.Button_Hangar_Start)
sdlext.isSquadSelectionWindowVisible = buildIsWindowVisibleFunction(windows.Hangar_Select)
sdlext.isCustomizeSquadWindowVisible = buildIsWindowVisibleFunction(windows.Customize_Instructions)
sdlext.isAchievementsWindowVisible = buildIsWindowVisibleFunction(windows.Hangar_Achievements_Title)
sdlext.isPilotSelectionWindowVisible = buildIsWindowVisibleFunction(windows.Hangar_Pilot)
sdlext.isOptionsWindowVisible = buildIsWindowVisibleFunction(windows.Options_Title)
sdlext.isLanguageSelectionWindowVisible = buildIsWindowVisibleFunction(windows.Language_Title)
sdlext.isHotkeyConfigurationWindowVisible = buildIsWindowVisibleFunction(windows.Hotkeys_Title)
sdlext.isProfileSelectionWindowVisible = buildIsWindowVisibleFunction(windows.Profile_Title)
sdlext.isCreateProfileConfirmationWindowVisible = buildIsWindowVisibleFunction(windows.New_Profile_Title)
sdlext.isDeleteProfileConfirmationWindowVisible = buildIsWindowVisibleFunction(windows.Delete_Confirm_Title)
sdlext.isStatisticsWindowVisible = buildIsWindowVisibleFunction(windows.Stats_Header)
sdlext.isNewGameWindowVisible = buildIsWindowVisibleFunction(windows.NewGame_Confirm_Title)
sdlext.isAbandonTimelineWindowVisible = buildIsWindowVisibleFunction(windows.Abandon_Confirm_Title)

local oldGetText = GetText
function GetText(id, ...)
	local window = windows[id]
	if window ~= nil then
		window:show(id)
	end

	return oldGetText(id, ...)
end

modApi.events.onFrameDrawStart:subscribe(function()

	for id, window in pairs(visibleWindows) do
		if not showWindows[id] then
			window:hide(id)
		end
	end

	if next(showWindows) ~= nil then
		showWindows = {}
	end
end)


local showWindows = {}
local visibleWindows = {}

local Window = {}
CreateClass(Window)

function Window:show(id)
	if self.visible then return end

	self.visible = true
	self.rect = self:findRect()
	modApi.events.onWindowShown:dispatch(id, self.rect)
	self.event_show:dispatch(id, self.rect)
end

function Window:hide(id)
	if not self.visible then return end

	self.visible = false
	self.rect = nil
	modApi.events.onWindowHidden:dispatch(id)
	self.event_hide:dispatch(id)
end

function Window:isVisible()
	return self.visible == true
end

function Window:findRect()
	if not self.visible then return nil end

	return self.find_rect and self.find_rect() or nil
end

local function buildIsWindowVisibleFunction(window)
	return function()
		return window:isVisible()
	end
end

local function getRectFromShadowSurfaces()
	local wx, wy, ww, wh = sdlext.getShadowSurfaceRect()
	if wx ~= nil then
		return sdl.rect(wx, wy, ww, wh)
	end
end

local function buildGetRectFromBox(box)
	-- See images.lua for Boxes
	return function()
		if box == nil then return nil end

		return sdl.rect(box.x, box.y, box.w, box.h)
	end
end

local windows = {
	Escape_Title = Window:new{
		event_show = modApi.events.onEscapeMenuWindowShown,
		event_hide = modApi.events.onEscapeMenuWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Button_Hangar_Start = Window:new{
		event_show = modApi.events.onHangarUiShown,
		event_hide = modApi.events.onHangarUiHidden,
		-- Not a window, but rather a screen.
		-- Might want a separate Screens table?
		find_rect = nil
	},
	Hangar_Select = Window:new{
		event_show = modApi.events.onSquadSelectionWindowShown,
		event_hide = modApi.events.onSquadSelectionWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Customize_Instructions = Window:new{
		event_show = modApi.events.onCustomizeSquadWindowShown,
		event_hide = modApi.events.onCustomizeSquadWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Hangar_Achievements_Title = Window:new{
		event_show = modApi.events.onAchievementsWindowShown,
		event_hide = modApi.events.onAchievementsWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Hangar_Pilot = Window:new{
		event_show = modApi.events.onPilotSelectionWindowShown,
		event_hide = modApi.events.onPilotSelectionWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Options_Title = Window:new{
		event_show = modApi.events.onOptionsWindowShown,
		event_hide = modApi.events.onOptionsWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Language_Title = Window:new{
		event_show = modApi.events.onLanguageSelectionWindowShown,
		event_hide = modApi.events.onLanguageSelectionWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Hotkeys_Title = Window:new{
		event_show = modApi.events.onHotkeyConfigurationWindowShown,
		event_hide = modApi.events.onHotkeyConfigurationWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Profile_Title = Window:new{
		event_show = modApi.events.onProfileSelectionWindowShown,
		event_hide = modApi.events.onProfileSelectionWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	New_Profile_Title = Window:new{
		event_show = modApi.events.onCreateProfileConfirmationWindowShown,
		event_hide = modApi.events.onCreateProfileConfirmationWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Delete_Confirm_Title = Window:new{
		event_show = modApi.events.onDeleteProfileConfirmationWindowShown,
		event_hide = modApi.events.onDeleteProfileConfirmationWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Stats_Header = Window:new{
		event_show = modApi.events.onStatisticsWindowShown,
		event_hide = modApi.events.onStatisticsWindowHidden,
		find_rect = buildGetRectFromBox(Boxes["stat_screen"])
	},
	NewGame_Confirm_Title = Window:new{
		event_show = modApi.events.onNewGameWindowShown,
		event_hide = modApi.events.onNewGameWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Abandon_Confirm_Title = Window:new{
		event_show = modApi.events.onAbandonTimelineWindowShown,
		event_hide = modApi.events.onAbandonTimelineWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Unit_Status_Title = Window:new{
		event_show = modApi.events.onStatusTooltipWindowShown,
		event_hide = modApi.events.onStatusTooltipWindowHidden,
		find_rect = getRectFromShadowSurfaces
	},
	Button_Editor_Exit = Window:new{
		event_show = modApi.events.onMapEditorTestEntered,
		event_hide = modApi.events.onMapEditorTestExited,
		find_rect = nil
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
sdlext.isStatusTooltipWindowVisible = buildIsWindowVisibleFunction(windows.Unit_Status_Title)
sdlext.isMapEditor = buildIsWindowVisibleFunction(windows.Button_Editor_Exit)

local oldGetText = GetText
function GetText(id, ...)
	local window = windows[id]
	if window ~= nil then
		showWindows[id] = true
		visibleWindows[id] = window
	end

	return oldGetText(id, ...)
end

modApi.events.onFrameDrawStart:subscribe(function()
	for id, window in pairs(visibleWindows) do
		if showWindows[id] then
			window:show(id)
		end
		if not showWindows[id] then
			visibleWindows[id] = nil
			window:hide(id)
		end
	end

	if next(showWindows) ~= nil then
		showWindows = {}
	end
end)


local openWindows = {}

local Window = {}
CreateClass(Window)

function Window:open()
	self.opened = true
	table.insert(openWindows, self)
	modApi.events[string.format("on%sEntered", self.event_id)]:dispatch()
end

function Window:close()
	self.opened = false
	remove_element(self, openWindows)
	modApi.events[string.format("on%sExited", self.event_id)]:dispatch()
end

function Window:isOpen()
	return self.opened
end

local windows = {
	Hangar_Select = Window:new{
		event_id = "SquadSelection"
	},
	Hangar_Achievements_Title = Window:new{
		event_id = "AchievementWindow"
	},
	Hangar_Pilot = Window:new{
		event_id = "PilotSelection"
	},
	Options_Title = Window:new{
		event_id = "OptionWindow"
	},
	Language_Title = Window:new{
		event_id = "LanguageSelection"
	},
	Hotkeys_Title = Window:new{
		event_id = "HotkeyConfiguration"
	},
	Profile_Title = Window:new{
		event_id = "ProfileSelection"
	},
	New_Profile_Title = Window:new{
		event_id = "ProfileConfirm"
	},
	Stats_Header = Window:new{
		event_id = "StatisticsWindow"
	},
	NewGame_Confirm_Title = Window:new{
		event_id = "NewGameWindow"
	},
	Abandon_Confirm_Title = Window:new{
		event_id = "AbandonTimelineWindow"
	},
}

for _, window in pairs(windows) do
	sdlext["is".. window.event_id] = function()
		return window.isOpen()
	end
end

local oldGetText = GetText
function GetText(id, ...)
	if windows[id] ~= nil then
		windows[id].request_opened = true
	end

	return oldGetText(id, ...)
end

modApi.events.onFrameDrawn:subscribe(function()

	for _, window in ipairs(openWindows) do
		if not window.request_opened then
			window:close()
		end
	end

	for _, window in pairs(windows) do
		if not window.opened and window.request_opened then
			window:open()
		end

		window.request_opened = false
	end
end)

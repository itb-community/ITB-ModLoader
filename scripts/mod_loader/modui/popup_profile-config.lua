--[[
	Adds a dialog which appears when profile-specific config is enabled, and
	the player switches profiles.
--]]

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showProfileSettingsFrame = false
		SaveModLoaderConfig(CurrentModLoaderConfig())
	end
end

local function onProfileChanged()
	if
		modApi.showProfileSettingsFrame and modApi.profileConfig
	then
		modApi:scheduleHook(50, function()
			sdlext.showButtonDialog(
				GetText("ProfileSettings_FrameTitle"),
				GetText("ProfileSettings_FrameText"),
				responseFn,
				{ GetText("Button_Ok"), GetText("Button_DisablePopup") },
				{ "", GetText("ButtonTooltip_DisablePopup") }
			)
		end)
	end
end

local profile
modApi.events.onProfileSelectionWindowShown:subscribe(function()
	profile = Settings.last_profile
end)

local function onProfileSelected()
	local newProfile = Settings.last_profile
	if newProfile ~= nil and newProfile ~= "" and newProfile ~= profile then
		onProfileChanged()
	end

	profile = newProfile
end

modApi.events.onCreateProfileConfirmationWindowHidden:subscribe(onProfileSelected)
modApi.events.onProfileSelectionWindowHidden:subscribe(onProfileSelected)

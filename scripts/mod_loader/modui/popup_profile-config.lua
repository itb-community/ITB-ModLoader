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

sdlext.addSettingsChangedHook(function(old, new)
	if
		modApi.showProfileSettingsFrame and modApi.profileConfig
	then
		modApi:scheduleHook(50, function()
			sdlext.showButtonDialog(
				GetText("ProfileSettings_FrameTitle"),
				GetText("ProfileSettings_FrameText"),
				responseFn, nil, nil,
				{ GetText("Button_Ok"), GetText("Button_DisablePopup") },
				{ "", GetText("ButtonTooltip_DisablePopup") }
			)
		end)
	end
end)
